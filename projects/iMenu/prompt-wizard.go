package main

import (
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Wizard step types
type StepType string

const (
	StepInput      StepType = "input"
	StepSelect     StepType = "select"
	StepConfirm    StepType = "confirm"
	StepMultiSelect StepType = "multiselect"
)

// Step definition
type Step struct {
	Type        StepType `json:"type"`
	Title       string   `json:"title"`
	Description string   `json:"description,omitempty"`
	Placeholder string   `json:"placeholder,omitempty"`
	Default     string   `json:"default,omitempty"`
	Options     []string `json:"options,omitempty"`
	Key         string   `json:"key"` // Key to store result in results map
}

// Wizard model
type wizardModel struct {
	steps      []Step
	current    int
	results    map[string]interface{}
	inputValue string
	selectIdx  int
	confirmVal bool
	multiSel   map[int]bool
	err        error
	resultFile string
}

func initialWizardModel(steps []Step, resultFile string) wizardModel {
	multiSel := make(map[int]bool)
	return wizardModel{
		steps:      steps,
		current:    0,
		results:    make(map[string]interface{}),
		inputValue: "",
		selectIdx:  0,
		confirmVal: false,
		multiSel:   multiSel,
		resultFile: resultFile,
	}
}

func (m wizardModel) Init() tea.Cmd {
	return nil
}

func (m wizardModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	if m.err != nil {
		return m, tea.Quit
	}

	currentStep := m.steps[m.current]

	switch msg := msg.(type) {
	case tea.KeyMsg:
		// Handle text input first (before other key commands)
		if currentStep.Type == StepInput {
			switch msg.Type {
			case tea.KeyBackspace, tea.KeyDelete:
				if len(m.inputValue) > 0 {
					m.inputValue = m.inputValue[:len(m.inputValue)-1]
				}
				return m, nil
			case tea.KeyRunes:
				// Regular character input
				m.inputValue += string(msg.Runes)
				return m, nil
			case tea.KeySpace:
				m.inputValue += " "
				return m, nil
			}
		}
		
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit

		case "b", "B": // Back
			if m.current > 0 {
				m.current--
				// Restore previous value if exists
				if val, ok := m.results[m.steps[m.current].Key]; ok {
					switch currentStep.Type {
					case StepInput:
						m.inputValue = fmt.Sprintf("%v", val)
					case StepSelect:
						if opts := m.steps[m.current].Options; len(opts) > 0 {
							for i, opt := range opts {
								if opt == fmt.Sprintf("%v", val) {
									m.selectIdx = i
									break
								}
							}
						}
					case StepConfirm:
						m.confirmVal = val.(bool)
					}
				}
				return m, nil
			}

		case "enter":
			// Save current result and move forward
			switch currentStep.Type {
			case StepInput:
				result := m.inputValue
				if result == "" && currentStep.Default != "" {
					result = currentStep.Default
				}
				m.results[currentStep.Key] = result
			case StepSelect:
				if len(currentStep.Options) > 0 {
					m.results[currentStep.Key] = currentStep.Options[m.selectIdx]
				}
			case StepConfirm:
				m.results[currentStep.Key] = m.confirmVal
			case StepMultiSelect:
				selected := []string{}
				for i, opt := range currentStep.Options {
					if m.multiSel[i] {
						selected = append(selected, opt)
					}
				}
				m.results[currentStep.Key] = selected
			}

			// Move to next step
			if m.current < len(m.steps)-1 {
				m.current++
				// Clear screen when changing steps
				fmt.Print("\033[2J\033[H")
				// Initialize next step
				nextStep := m.steps[m.current]
				if val, ok := m.results[nextStep.Key]; ok {
					switch nextStep.Type {
					case StepInput:
						m.inputValue = fmt.Sprintf("%v", val)
					case StepSelect:
						if opts := nextStep.Options; len(opts) > 0 {
							for i, opt := range opts {
								if opt == fmt.Sprintf("%v", val) {
									m.selectIdx = i
									break
								}
							}
						}
					case StepConfirm:
						m.confirmVal = val.(bool)
					case StepMultiSelect:
						m.multiSel = make(map[int]bool)
						if selected, ok := val.([]string); ok {
							for i, opt := range nextStep.Options {
								for _, sel := range selected {
									if opt == sel {
										m.multiSel[i] = true
										break
									}
								}
							}
						}
					}
				} else {
					// Initialize defaults
					if nextStep.Type == StepInput && nextStep.Default != "" {
						m.inputValue = nextStep.Default
					}
					if nextStep.Type == StepConfirm {
						m.confirmVal = false
					}
					if nextStep.Type == StepMultiSelect {
						m.multiSel = make(map[int]bool)
					}
				}
				return m, nil
			} else {
				// Wizard complete - write results and quit
				return m, tea.Quit
			}

		case "up", "k":
			switch currentStep.Type {
			case StepSelect, StepMultiSelect:
				if m.selectIdx > 0 {
					m.selectIdx--
				}
			}

		case "down", "j":
			switch currentStep.Type {
			case StepSelect:
				if m.selectIdx < len(currentStep.Options)-1 {
					m.selectIdx++
				}
			case StepMultiSelect:
				if m.selectIdx < len(currentStep.Options)-1 {
					m.selectIdx++
				}
			}

		case "left", "h":
			if currentStep.Type == StepConfirm {
				m.confirmVal = true
			}

		case "right", "l":
			if currentStep.Type == StepConfirm {
				m.confirmVal = false
			}

		case " ":
			if currentStep.Type == StepMultiSelect {
				m.multiSel[m.selectIdx] = !m.multiSel[m.selectIdx]
			}

		case "a", "A":
			if currentStep.Type == StepMultiSelect {
				// Check if all items are selected
				allSelected := true
				for i := range currentStep.Options {
					if !m.multiSel[i] {
						allSelected = false
						break
					}
				}
				// Toggle: if all selected, deselect all; otherwise select all
				for i := range currentStep.Options {
					m.multiSel[i] = !allSelected
				}
			}
		}
	}

	return m, nil
}

func (m wizardModel) View() string {
	if m.err != nil {
		return fmt.Sprintf("Error: %v\n", m.err)
	}

	if m.current >= len(m.steps) {
		return "Wizard complete!\n"
	}

	// Build output
	var s strings.Builder
	// Don't manually clear - bubbletea's alt screen handles it
	// Just ensure we render everything fresh

	currentStep := m.steps[m.current]
	stepNum := m.current + 1
	totalSteps := len(m.steps)

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("205"))
	s.WriteString(headerStyle.Render(fmt.Sprintf("Step %d of %d", stepNum, totalSteps)))
	s.WriteString("\n\n")

	// Show previous answers (limit to last 2 to ensure current options are visible)
	if m.current > 0 {
		prevStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("240"))
		s.WriteString(prevStyle.Render("Previous:"))
		s.WriteString("\n")
		
		startIdx := 0
		if m.current > 2 {
			startIdx = m.current - 2
		}
		
		for i := startIdx; i < m.current; i++ {
			prevStep := m.steps[i]
			if val, ok := m.results[prevStep.Key]; ok {
				var answerStr string
				switch v := val.(type) {
				case []string:
					if len(v) > 0 {
						answerStr = strings.Join(v, ", ")
					} else {
						answerStr = "(none)"
					}
				case bool:
					if v {
						answerStr = "Yes"
					} else {
						answerStr = "No"
					}
				default:
					answerStr = fmt.Sprintf("%v", v)
				}
				
				questionStyle := lipgloss.NewStyle().
					Foreground(lipgloss.Color("250"))
				answerStyle := lipgloss.NewStyle().
					Foreground(lipgloss.Color("245"))
				
				s.WriteString(fmt.Sprintf("%s: %s\n",
					questionStyle.Render(prevStep.Title),
					answerStyle.Render(answerStr)))
			}
		}
		s.WriteString("\n")
	}

	// Title (with description in parentheses if provided)
	titleStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("230"))
	
	descStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("240"))
	
	var titleText string
	if currentStep.Description != "" {
		// Combine title and description on same line
		titleText = titleStyle.Render(currentStep.Title) + " " + descStyle.Render(fmt.Sprintf("(%s)", currentStep.Description))
	} else {
		titleText = titleStyle.Render(currentStep.Title)
	}
	
	s.WriteString(titleText)
	s.WriteString("\n\n")

	// Render based on step type
	switch currentStep.Type {
	case StepInput:
		inputStyle := lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("205")).
			Padding(0, 1).
			Width(50)
		value := m.inputValue
		if value == "" {
			value = currentStep.Placeholder
			inputStyle = inputStyle.Foreground(lipgloss.Color("240"))
		}
		s.WriteString(inputStyle.Render(value))
		s.WriteString("\n")

	case StepSelect:
		if len(currentStep.Options) == 0 {
			s.WriteString("  (no options)\n")
		} else {
			for i, opt := range currentStep.Options {
				cursor := " "
				style := lipgloss.NewStyle()
				if i == m.selectIdx {
					cursor = ">"
					style = style.
						Foreground(lipgloss.Color("205")).
						Bold(true)
				} else {
					style = style.Foreground(lipgloss.Color("240"))
				}
				s.WriteString(fmt.Sprintf("%s %s\n", cursor, style.Render(opt)))
			}
		}

	case StepConfirm:
		yesStyle := lipgloss.NewStyle().Padding(0, 1)
		noStyle := lipgloss.NewStyle().Padding(0, 1)

		if m.confirmVal {
			// Yes selected: dim green background, bright green foreground
			yesStyle = yesStyle.
				Background(lipgloss.Color("22")).   // Dim green background
				Foreground(lipgloss.Color("46"))    // Bright green
			noStyle = noStyle.Foreground(lipgloss.Color("240"))
		} else {
			// No selected: bg52 at -3% intensity (RGB 49,0,0 = #310000), fg196 (RGB 255,0,0 = #FF0000)
			yesStyle = yesStyle.Foreground(lipgloss.Color("240"))
			noStyle = noStyle.
				Background(lipgloss.Color("#310000")).  // BG 52 at -3% intensity (RGB 49,0,0)
				Foreground(lipgloss.Color("#FF0000"))   // FG 196 (bright red, RGB 255,0,0)
		}

		s.WriteString(fmt.Sprintf("[%s] [%s]\n",
			yesStyle.Render("Yes"),
			noStyle.Render("No")))

	case StepMultiSelect:
		for i, opt := range currentStep.Options {
			cursor := "  "
			marker := "•"
			style := lipgloss.NewStyle()

			if i == m.selectIdx {
				cursor = "> "
			}

			if m.multiSel[i] {
				marker = "✓"
				if i == m.selectIdx {
					style = style.
						Foreground(lipgloss.Color("205")).
						Bold(true)
				} else {
					style = style.Foreground(lipgloss.Color("205"))
				}
			} else {
				if i == m.selectIdx {
					style = style.
						Foreground(lipgloss.Color("230")).
						Bold(true)
				} else {
					style = style.Foreground(lipgloss.Color("240"))
				}
			}

			s.WriteString(fmt.Sprintf("%s %s %s\n",
				cursor, marker, style.Render(opt)))
		}
	}

	// Footer with instructions
	s.WriteString("\n")
	footerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("240"))
	
	instructions := ""
	switch currentStep.Type {
	case StepInput:
		instructions = "Type your answer, Enter to continue"
	case StepSelect:
		instructions = "↑↓ to navigate, Enter to select"
	case StepConfirm:
		instructions = "←→ to switch, Enter to confirm"
	case StepMultiSelect:
		instructions = "↑↓ to navigate, Space to toggle, A to select all/none, Enter when done"
	}

	if m.current > 0 {
		instructions += ", B to go back"
	}

	s.WriteString(footerStyle.Render(instructions))
	s.WriteString("\n")

	return s.String()
}

// stripJSONComments removes both single-line (//) and multi-line (/* */) comments from JSON
func stripJSONComments(jsonStr string) string {
	// Remove single-line comments (// ...)
	singleLineComment := regexp.MustCompile(`//.*`)
	jsonStr = singleLineComment.ReplaceAllString(jsonStr, "")
	
	// Remove multi-line comments (/* ... */)
	multiLineComment := regexp.MustCompile(`/\*[\s\S]*?\*/`)
	jsonStr = multiLineComment.ReplaceAllString(jsonStr, "")
	
	return jsonStr
}

// readJSONInput reads JSON from file or returns the string if it's not a valid file path
func readJSONInput(input string) (string, error) {
	// Check if input looks like a file path (contains / or . and exists as file)
	if strings.Contains(input, "/") || (strings.Contains(input, ".") && !strings.HasPrefix(input, "{")) {
		// Try to read as file
		if _, err := os.Stat(input); err == nil {
			// File exists, read it
			data, err := os.ReadFile(input)
			if err != nil {
				return "", fmt.Errorf("error reading file %s: %v", input, err)
			}
			return string(data), nil
		}
	}
	
	// Not a file, treat as JSON string
	return input, nil
}

func main() {
	// Check for help flag
	if len(os.Args) > 1 && (os.Args[1] == "-h" || os.Args[1] == "--help") {
		fmt.Fprintf(os.Stderr, "Usage: %s <steps-json> [--result-file FILE]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "   Or: echo '<steps-json>' | %s [--result-file FILE]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Steps JSON format:\n")
		fmt.Fprintf(os.Stderr, `[
  {"type": "input", "title": "Name", "key": "name", "placeholder": "Enter name"},
  {"type": "select", "title": "Color", "key": "color", "options": ["Red", "Blue"]},
  {"type": "confirm", "title": "Continue?", "key": "continue"}
]`+"\n")
		os.Exit(1)
	}

	// Parse result file
	resultFile := ""
	args := os.Args[1:]
	for i, arg := range args {
		if arg == "--result-file" && i+1 < len(args) {
			resultFile = args[i+1]
			args = append(args[:i], args[i+2:]...)
			break
		}
	}

	// Parse steps JSON - can be from args (file or string), stdin, or piped
	var stepsJSON string
	var err error
	
	if len(args) > 0 {
		// JSON provided as argument - could be file path or JSON string
		stepsJSON, err = readJSONInput(args[0])
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	} else {
		// Read from stdin
		stat, _ := os.Stdin.Stat()
		if (stat.Mode() & os.ModeCharDevice) == 0 {
			// Data is being piped
			var stdinData []byte
			stdinData, err := os.ReadFile("/dev/stdin")
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error reading from stdin: %v\n", err)
				os.Exit(1)
			}
			stepsJSON = string(stdinData)
		} else {
			// No input provided
			fmt.Fprintf(os.Stderr, "Error: No steps JSON provided\n")
			fmt.Fprintf(os.Stderr, "Usage: %s <steps-json-or-file> [--result-file FILE]\n", os.Args[0])
			fmt.Fprintf(os.Stderr, "   Or: echo '<steps-json>' | %s [--result-file FILE]\n", os.Args[0])
			fmt.Fprintf(os.Stderr, "\nSupports:\n")
			fmt.Fprintf(os.Stderr, "  - JSON string: %s '{\"type\":\"select\",...}'\n", os.Args[0])
			fmt.Fprintf(os.Stderr, "  - File path: %s /path/to/wizard.json\n", os.Args[0])
			fmt.Fprintf(os.Stderr, "  - Piped input: echo '...' | %s\n", os.Args[0])
			fmt.Fprintf(os.Stderr, "  - JSON with comments (// and /* */) are supported\n")
			os.Exit(1)
		}
	}
	
	// Strip comments from JSON
	stepsJSON = stripJSONComments(stepsJSON)
	
	// Parse JSON
	var steps []Step
	if err := json.Unmarshal([]byte(stepsJSON), &steps); err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing steps JSON: %v\n", err)
		fmt.Fprintf(os.Stderr, "Note: JSON with comments (// and /* */) are supported\n")
		os.Exit(1)
	}

	if len(steps) == 0 {
		fmt.Fprintf(os.Stderr, "Error: No steps defined\n")
		os.Exit(1)
	}

	// Run wizard
	p := tea.NewProgram(initialWizardModel(steps, resultFile), tea.WithAltScreen())
	m, err := p.Run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Write results
	wizard := m.(wizardModel)
	resultsJSON, _ := json.Marshal(wizard.results)
	
	if resultFile != "" {
		os.WriteFile(resultFile, resultsJSON, 0644)
	} else {
		fmt.Println(string(resultsJSON))
	}
}

