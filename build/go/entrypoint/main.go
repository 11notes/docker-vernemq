package main

import (
	"os"
	"fmt"
	"os/exec"
	"os/signal"
	"regexp"
	"syscall"
	"time"
  "github.com/11notes/go-eleven"
)

const (
	APP_CONFIG_ENV string = "VERNEMQ_CONFIG"
	APP_CONFIG string = "/vernemq/etc/vernemq.conf"
	APP_ROOT string = "/opt/vernemq"
	APP_VM_ARGS string = "/vernemq/etc/vm.args"
)

var (
	reName     = regexp.MustCompile(`-name VerneMQ@.+`)
	reCookie   = regexp.MustCompile(`-setcookie .+`)
	reEval     = regexp.MustCompile(`-eval.+`)
	reEvalLine = regexp.MustCompile(`(?m)^-eval.*\n?`)
)

func main(){
	if(len(os.Args) > 1){
		args := os.Args[1:]
		switch args[0] {
			case "--pvc-copy":
				eleven.Log("INF", "copy /vernemq/etc to PVC ...")
				eleven.Container.CopyMissingSourceFiles("/vernemq/etc", "/pvc/etc")

			default:
				server()
		}
	}else{
		server()
	}
}

func editVMArgs(fn func(string) string){
	info, err := os.Stat(APP_VM_ARGS)
	if err != nil {
		eleven.Log("WRN", "vm.args: %v", err)
		return
	}
	b, err := os.ReadFile(APP_VM_ARGS)
	if err != nil {
		eleven.Log("WRN", "vm.args: %v", err)
		return
	}
	if err := os.WriteFile(APP_VM_ARGS, []byte(fn(string(b))), info.Mode()); err != nil {
		eleven.Log("WRN", "vm.args: %v", err)
	}
}

func shutdown(sigErr <-chan error) {
	node := os.Getenv("DOCKER_VERNEMQ_NODENAME")
	_ = exec.Command(APP_ROOT + "/bin/vmq-admin", "cluster", "leave", "node=VerneMQ@" + node, "-k", "-i", "5", "-t", "60").Run()
	_ = exec.Command(APP_ROOT + "/bin/vmq-admin", "node", "stop").Run()
	select {
		case <-sigErr:
		case <-time.After(30 * time.Second):
	}
}

func server(){
	// setup signal handler
	signalChannel := make(chan os.Signal, 1)
	signalError := make(chan error, 1)
	signal.Notify(signalChannel, os.Interrupt, syscall.SIGTERM, syscall.SIGSTOP, syscall.SIGINT, syscall.SIGUSR1)
	go func(){
		sig := <-signalChannel
		switch sig {
			case syscall.SIGINT:
			case syscall.SIGTERM:
				shutdown(signalError)
			default:
				eleven.Log("info", "got unexpected signal: %v", sig)
		}

		os.Exit(0)
	}()

	// write env to file if set
	eleven.Container.EnvToFile(APP_CONFIG_ENV, APP_CONFIG)

	// replace all environment variables present in the file ${VAR} or $VAR
	eleven.Container.FileContentReplaceEnv(APP_CONFIG)

	// change directory to app root
	if err := os.Chdir(APP_ROOT); err != nil {
		eleven.LogFatal("can't change directory", err)
	}

	// check environment variables
	if v, ok := os.LookupEnv("DOCKER_VERNEMQ_NODENAME"); ok {
		editVMArgs(func(s string) string {
			return reName.ReplaceAllLiteralString(s, "-name VerneMQ@"+v)
		})
	}

	if v, ok := os.LookupEnv("DOCKER_VERNEMQ_DISTRIBUTED_COOKIE"); ok {
		editVMArgs(func(s string) string {
			return reCookie.ReplaceAllLiteralString(s, "-setcookie "+v)
		})
	}

	if v, ok := os.LookupEnv("DOCKER_VERNEMQ_DISCOVERY_NODE"); ok {
		editVMArgs(func(s string) string {
			return reEval.ReplaceAllLiteralString(s,
				fmt.Sprintf(`-eval "vmq_server_cmd:node_join('VerneMQ@%s')"`, v))
		})
	} else {
		editVMArgs(func(s string) string {
			return reEvalLine.ReplaceAllString(s, "")
		})
	}

	// create config
	_ = exec.Command(APP_ROOT + "/bin/vernemq", "config", "generate").Run()

	// start vernemq
	eleven.Container.Run(APP_ROOT + "/bin", "vernemq", []string{"console", "-noshell", "-noinput"}, []string{})
}