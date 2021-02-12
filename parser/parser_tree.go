package parser

import (
	"regexp"
)

func (p *Parser) GetTree() (*Program, error) {
	scriptName, err := p.getScriptNameStatement()

	if err != nil {
		return nil, err
	}

	program := Program{
		ScriptName: scriptName,
		Body:       []Node{},
	}

	return &program, nil
}

func (p *Parser) getScriptNameStatement() (*ScriptNameStatement, error) {
	lines := p.lines(true)

	if len(lines) == 0 {
		return nil, ParseError{
			Line:    0,
			Col:     0,
			File:    p.File,
			Message: "file empty",
		}
	}

	line := lines[0]
	r := regexp.MustCompile(`Scriptname\s+([\w\d]+)?(\s+)?(extends)?(\s+)?([\w\d]+)?(\s+)?([\w\d]+)?(\s+)?([\w\d]+)?`)
	m := r.FindStringSubmatch(line)

	scriptName := m[1]
	extending := m[3] != ""
	extended := m[5]
	flag := m[7]
	extraFlag := m[9]

	if scriptName == "" {
		return nil, ParseError{}
	}

	if extending && extended == "" {
		return nil, ParseError{}
	}

	var flags []Flag

	if flag != "" {
		flags = append(flags, Flag{Name: flag})
	}

	if extraFlag != "" {
		flags = append(flags, Flag{Name: extraFlag})
	}

	s := ScriptNameStatement{
		StatementB: StatementB{
			Node{
				NodeType: "ScriptName",
				Location: SourceLocation{
					Start: Position{
						Line: 1,
						Col:  1,
					},
					End: Position{
						Line: 1,
						Col:  len(line),
					},
				},
			},
		},
		ScriptName: scriptName,
		Extends:    extended,
		Flags:      flags,
	}

	return &s, nil
}
