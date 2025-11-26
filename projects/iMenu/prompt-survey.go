package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/AlecAivazis/survey/v2"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <type> [options]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Types: input, select, confirm, password\n")
		os.Exit(1)
	}

	promptType := os.Args[1]

	switch promptType {
	case "input":
		var result string
		message := "Enter value:"
		if len(os.Args) > 2 {
			message = os.Args[2]
		}
		prompt := &survey.Input{
			Message: message,
		}
		if err := survey.AskOne(prompt, &result); err != nil {
			os.Exit(1)
		}
		fmt.Println(result)

	case "select":
		if len(os.Args) < 3 {
			fmt.Fprintf(os.Stderr, "Usage: %s select <message> <option1> [option2] ...\n", os.Args[0])
			os.Exit(1)
		}
		var result string
		message := os.Args[2]
		options := os.Args[3:]
		prompt := &survey.Select{
			Message: message,
			Options: options,
		}
		if err := survey.AskOne(prompt, &result); err != nil {
			os.Exit(1)
		}
		fmt.Println(result)

	case "confirm":
		var result bool
		message := "Continue?"
		if len(os.Args) > 2 {
			message = strings.Join(os.Args[2:], " ")
		}
		prompt := &survey.Confirm{
			Message: message,
		}
		if err := survey.AskOne(prompt, &result); err != nil {
			os.Exit(1)
		}
		if result {
			fmt.Println("yes")
			os.Exit(0)
		} else {
			fmt.Println("no")
			os.Exit(1)
		}

	case "password":
		var result string
		message := "Enter password:"
		if len(os.Args) > 2 {
			message = os.Args[2]
		}
		prompt := &survey.Password{
			Message: message,
		}
		if err := survey.AskOne(prompt, &result); err != nil {
			os.Exit(1)
		}
		fmt.Println(result)

	default:
		fmt.Fprintf(os.Stderr, "Unknown prompt type: %s\n", promptType)
		os.Exit(1)
	}
}

