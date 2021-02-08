package parser

import (
    "fmt"
    "io/ioutil"
    "os"
    "regexp"
    "strings"
)

var mapFuncs = []mapTrimFuncs{{
    Trim:  strings.TrimLeft,
    Index: strings.Index,
}, {
    Trim: strings.TrimRight,
    Index: strings.LastIndex,
}}

var statementIf = &Statement{
    Start: "if",
    End:   "endif",
}

var statementWhile = &Statement{
    Start: "while",
    End:   "endwhile",
}

var statementFunction = &Statement{
    Start: "Function",
    End:   "EndFunction",
}

var statementEvent = &Statement{
    Start: "Event",
    End:   "EndEvent",
}

type Parser struct {
    File     string
    Filename string
    Content  string
    Extends  string
    ScriptName string
}

type Statement struct {
    Start string
    End string
}

type StatementBlock struct {
    Statement
}

func New(file string) (*Parser, error) {
    reg := regexp.MustCompile(`/(.*\.psc)`)
    s := reg.FindStringSubmatch(file)

    if len(s) == 1 {
        fmt.Print("cannot find Filename in " + file)

        return nil, FilenameError{file: file}
    }

    wd, err := os.Getwd()

    if err != nil {
        return nil, RuntimeError{message: "cannot get current directory"}
    }

    contentByte, err := ioutil.ReadFile(wd + "/" + file)

    if err != nil {
        return nil, RuntimeError{message: "cannot find File " + err.Error()}
    }

    content := string(contentByte)
    scriptName := strings.Replace(s[1], ".psc", "", 1)

    return &Parser{
        File:       file,
        Filename:   s[1],
        Content:    content,
        ScriptName: scriptName,
    }, nil
}

func (p *Parser) Parse() error {
    err := p.checkScriptName()
    checks := []func() error{p.checkTrailingWhitespaces, p.checkFunctions, p.checkIf, p.checkWhile}

    for _, check := range checks {
        err = check()

        if err != nil {
            return err
        }
    }

    return nil
}

func (p *Parser) checkTrailingWhitespaces() error {
    for i, line := range strings.Split(p.Content, "\n") {
        trimmedLine := strings.Trim(line, " ")

        if trimmedLine != "" && !strings.HasPrefix(trimmedLine, "Function") && !strings.HasPrefix(trimmedLine, "Event") && !strings.HasPrefix(trimmedLine, "Scriptname") {
            continue
        }

        for _, useFunc := range mapFuncs {
            if useFunc.Trim(line, " ") != line {
                col := useFunc.Index(line, " ")

                return ParseError{
                    Line:    i + 1,
                    Col:     col + 1,
                    File:    p.Filename,
                    Message: "trailing whitespace",
                }
            }
        }
    }

    return nil
}

func (p *Parser) checkScriptName() error {
    scriptNameLine := strings.Trim(strings.Split(p.Content, "\n")[0], "\n ")

    reg := regexp.MustCompile(fmt.Sprintf(`Scriptname %s([^a-z]|\s*$)(extends?\s*(\w*))?`, p.ScriptName))

    match := reg.FindStringSubmatch(scriptNameLine)

    if len(match) != 4 {
        scriptNameIndex := strings.Index(scriptNameLine, p.ScriptName)

        if scriptNameIndex < 0 {
            scriptNameIndex = 0
        }

        return ParseError{
            Line:    1,
            Col:     scriptNameIndex + 1,
            File:    p.Filename,
            Message: fmt.Sprintf(`Scriptname statement is invalid, "Scriptname" must match Filename: "Scriptname %s"`, p.ScriptName),
        }
    }

    p.Extends = match[2]

    return nil
}

func (p *Parser) checkStatement(statement *Statement) error {
    split := strings.Split(strings.Trim(p.Content, "\n "), "\n")
    splitLen := len(split)
    reg := regexp.MustCompile(fmt.Sprintf(`%s(\s\w+|\s*\(\w+)`, statement.Start))
    regCheckParentheses := regexp.MustCompile(fmt.Sprintf(`%s\s*(\([\w\d]+\)?|\(?[\w\d]*\))`, statement.Start))

    for i, lineContent := range split {
        if len(lineContent) == 0 || strings.HasPrefix(lineContent, ";") || strings.HasPrefix(lineContent, ";/") {
            continue
        }

        startMatch := reg.FindStringSubmatch(lineContent)

        if startMatch == nil {
            continue
        }

        checkParentheses := regCheckParentheses.FindStringSubmatch(lineContent)

        if checkParentheses != nil && (!strings.HasPrefix(checkParentheses[1], "(") || !strings.HasSuffix(checkParentheses[1], ")")) {
            return ParseError{
                Line:    i + 1,
                Col:     len(lineContent),
                File:    p.Filename,
                Message: fmt.Sprintf("invalid %s syntax", statement.Start),
            }
        }

        hasEnd := true

        for j := i + 1; j < splitLen; j++ {
            jLineContent := split[j]
            hasEnd = strings.Contains(jLineContent, statement.End)

            if hasEnd {
                break
            }
        }

        if !hasEnd {
            return ParseError{
                Line:    i + 1,
                Col:     1,
                File:    p.Filename,
                Message: fmt.Sprintf("%s is not closed (missing %s)", statement.Start, statement.End),
            }
        }
    }

    return nil
}

func (p Parser) checkBlock(statement *Statement, createErrorMessage func(returnType string, name string) string) error {
    split := strings.Split(strings.Trim(p.Content, "\n "), "\n")
    splitLen := len(split)
    regStart := regexp.MustCompile(fmt.Sprintf(`(\w*)\s*%s\s(\w+)\(?`, statement.Start))
    regCheckParentheses := regexp.MustCompile(fmt.Sprintf(`%s\s+\w+(\(?\)?)`, statement.Start))

    for i, lineContent := range split {
        if strings.HasPrefix(lineContent, ";") {
            continue
        }

        startMatch := regStart.FindStringSubmatch(lineContent)

        if startMatch == nil {
            continue
        }

        checkParentheses := regCheckParentheses.FindStringSubmatch(lineContent)

        if checkParentheses != nil && (!strings.HasPrefix(checkParentheses[1], "(") || !strings.HasSuffix(checkParentheses[1], ")")) {
            return ParseError{
                Line:    i + 1,
                Col:     len(lineContent),
                File:    p.Filename,
                Message: fmt.Sprintf("invalid %s syntax", statement.Start),
            }
        }

        returnType := startMatch[1]
        functionName := startMatch[2]

        if returnType == "" {
            returnType = "None"
        }

        hasEnd := true

        for j := i + 1; j < splitLen; j++ {
            jLineContent := split[j]
            hasEnd = strings.Contains(jLineContent, statement.End)

            if hasEnd {
                break
            }
        }

        if !hasEnd {


            return ParseError{
                Line:    i + 1,
                Col:     1,
                File:    p.Filename,
                Message: fmt.Sprintf("%s%s is not closed", createErrorMessage(returnType, functionName), statement.Start),
            }
        }
    }

    return nil
}

func (p *Parser) checkFunctions() error {
    return p.checkBlock(statementFunction, func(returnType string, name string) string {
        if returnType == "" {
            returnType = "None"
        }

        return fmt.Sprintf(" %s %s", returnType, name)
    })
}

func (p *Parser) checkEvents() error {
    return p.checkBlock(statementEvent, func(_ string, name string) string {
        return fmt.Sprintf(" %s", name)
    })
}

func (p *Parser) checkIf() error {
    return p.checkStatement(statementIf)
}

func (p *Parser) checkWhile() error {
    return p.checkStatement(statementWhile)
}
