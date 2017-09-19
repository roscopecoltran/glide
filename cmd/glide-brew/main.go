package main

import (
	"fmt"
	"github.com/heewa/glide-brew/brew"
	"github.com/roscopecoltran/glide/core/msg"
)

func main() {
	lock, err := brew.LoadLockFile()
	if err != nil {
		msg.Die(err.Error())
	}

	resources, err := brew.ConvertLock(lock)
	if err != nil {
		msg.Die(err.Error())
	}

	if len(resources) == 0 {
		fmt.Println("No Go dependencies found to convert")
	}

	for _, res := range resources {
		fmt.Printf("%s\n\n", res)
	}

}
