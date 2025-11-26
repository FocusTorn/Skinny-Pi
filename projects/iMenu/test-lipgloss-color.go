package main

import (
	"fmt"
	"github.com/charmbracelet/lipgloss"
)

func main() {
	// Test different color formats
	style1 := lipgloss.NewStyle().Background(lipgloss.Color("#2E0000")).Foreground(lipgloss.Color("#FF0000"))
	style2 := lipgloss.NewStyle().Background(lipgloss.Color("2E0000")).Foreground(lipgloss.Color("FF0000"))
	style3 := lipgloss.NewStyle().Background(lipgloss.Color("rgb(46,0,0)")).Foreground(lipgloss.Color("rgb(255,0,0)"))
	
	fmt.Println("Test 1 (with #):", style1.Render("Test"))
	fmt.Println("Test 2 (without #):", style2.Render("Test"))
	fmt.Println("Test 3 (rgb format):", style3.Render("Test"))
}
