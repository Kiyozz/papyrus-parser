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
    Trim:  strings.TrimRight,
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
    File       string
    Filename   string
    Content    string
    Extends    string
    Flag       string
    ScriptName string
}

type Statement struct {
    Start string
    End   string
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

    if err != nil {
        return err
    }

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

    reg := regexp.MustCompile(`(Scriptname)(\s)?([\w\d]+)?(\s*)(extends)?(\s*)([\w\d]+)?(\s*)([\w\d]+)?`)

    match := reg.FindStringSubmatch(scriptNameLine)

    parseError := ParseError{
        Line: 1,
        Col:  1,
        File: p.Filename,
    }

    if match == nil {
        parseError.Message = "Scriptname error: no Scriptname specified"

        return parseError
    }

    scriptName := match[1]
    spaceBetweenScriptNameAndName := match[2]
    scriptNameValue := match[3]
    spaceBeforeExtends := match[4]
    extends := match[5]
    spaceAfterExtends := match[6]
    extendedScript := match[7]
    spaceAfterExtended := match[8]
    scriptNameFlag := match[9]

    if spaceBetweenScriptNameAndName == "" {
        parseError.Col = len(scriptName)
        parseError.Message = "Scriptname error: missing space after Scriptname"

        return parseError
    }

    if scriptNameValue != p.ScriptName {
        parseError.Col = len(fmt.Sprintf("%s ", scriptName))

        if scriptNameValue == "" {
            parseError.Message = "Scriptname error: missing name"
        } else {
            parseError.Message = fmt.Sprintf("Scriptname error: Scriptname must match filename, %s expected, got %s", p.ScriptName, scriptNameValue)
        }

        return parseError
    }

    if scriptNameFlag != "" && scriptNameFlag != "Conditional" && scriptNameFlag != "Hidden" {
        parseError.Col = len(fmt.Sprintf("%s %s%s%s%s%s%s", scriptName, scriptNameValue, spaceBeforeExtends, extends, spaceAfterExtends, extendedScript, spaceAfterExtended))
        parseError.Message = fmt.Sprintf("Scriptname error: unknown flag %s", scriptNameFlag)

        return parseError
    }

    p.Extends = extendedScript
    p.Flag = scriptNameFlag

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

func (p *Parser) checkBlock(statement *Statement) error {
    split := strings.Split(strings.Trim(p.Content, "\n "), "\n")
    splitLen := len(split)
    regStart := regexp.MustCompile(fmt.Sprintf(`(([\w\d]+)?(\[])?)?\s*%s(\s*)?([\d\w]+)?(\()?([^)]+)?(\))?`, statement.Start))

    for i, lineContent := range split {
        // FIXME: if user set two EndStatement without opening two, the error is not caught
        // TO BE REMOVED: lineContent == statement.End
        if lineContent == "" || strings.HasPrefix(lineContent, ";") || lineContent == statement.End {
            continue
        }

        startMatch := regStart.FindStringSubmatch(lineContent)

        if startMatch == nil {
            continue
        }

        returnType := startMatch[1]
        name := startMatch[5]
        openParenthesis := startMatch[6]
        args := startMatch[7]
        closeParenthesis := startMatch[8]

        parseError := ParseError{
            Line: i + 1,
            Col:  1,
            File: p.Filename,
        }

        if name == "" {
            parseError.Message = strings.Trim(fmt.Sprintf("%s %s error: missing name", returnType, statement.Start), " ")

            return parseError
        }

        if openParenthesis == "" {
            parseError.Message = strings.Trim(fmt.Sprintf("%s %s %s error: missing open parenthesis", returnType, name, statement.Start), " ")

            return parseError
        }

        if closeParenthesis == "" {
            parseError.Message = strings.Trim(fmt.Sprintf("%s %s %s error: missing close parenthesis", returnType, name, statement.Start), " ")

            return parseError
        }

        if strings.HasSuffix(args, ",") {
            parseError.Message = strings.Trim(fmt.Sprintf("%s %s %s error: trailing comma", returnType, name, statement.Start), " ")

            return parseError
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
            parseError.Message = strings.Trim(fmt.Sprintf("%s %s %s error: %s is not closed", returnType, name, statement.Start, statement.Start), " ")

            return parseError
        }
    }

    return nil
}

func (p *Parser) checkFunctions() error {
    return p.checkBlock(statementFunction)
}

func (p *Parser) checkEvents() error {
    return p.checkBlock(statementEvent)
}

func (p *Parser) checkIf() error {
    return p.checkStatement(statementIf)
}

func (p *Parser) checkWhile() error {
    return p.checkStatement(statementWhile)
}

func (p Parser) checkProperty() error {
    split := strings.Split(strings.Trim(p.Content, "\n "), "\n")
    reg := regexp.MustCompile(`^([\w\d]+(\[])?)\s+Property(\s+([\w\d]+)?\s*(=\s*([\w\d]+))?\s*((\w+)?\s*(\w+)?$)?)?`)

    for i, lineContent := range split {
        if lineContent == "" && strings.HasPrefix(lineContent, ";") {
            continue
        }

        match := reg.FindStringSubmatch(lineContent)

        if match == nil {
            continue
        }

        propType := match[1]      // variable type
        propName := match[4]      // variable name
        defaultValue := match[6]  // = XX
        propFlag := match[8]      // Auto/AutoReadOnly
        propExtraFlag := match[9] // Hidden/Conditional

        parseError := ParseError{
            Line: i + 1,
            Col:  len(lineContent), // FIXME: not the same everywhere
            File: p.Filename,
        }

        if propName == "" {
            parseError.Message = fmt.Sprintf("%s property error: missing name", propType)

            return parseError
        }

        if propFlag == "" {
            parseError.Message = fmt.Sprintf("%s %s property error: missing flag", propType, propName)

            return parseError
        } else {
            if propFlag != "AutoReadOnly" && propFlag != "Auto" {
                parseError.Message = fmt.Sprintf("%s %s property error: unknown flag %s", propType, propName, propFlag)

                return parseError
            }

            if propFlag == "AutoReadOnly" && defaultValue == "" {
                parseError.Message = fmt.Sprintf("%s %s property error: an AutoReadOnly property must have a default value", propType, propName)

                return parseError
            }
        }

        if propExtraFlag != "" {
            if propExtraFlag != "Conditional" && propExtraFlag != "Hidden" {
                parseError.Message = fmt.Sprintf("%s %s property error: unknown flag %s", propType, propName, propExtraFlag)

                return parseError
            }

            if propFlag != "Auto" && propExtraFlag == "Conditional" {
                parseError.Message = fmt.Sprintf("%s %s property error: Conditional is only applicable on property flagged Auto", propType, propName)

                return parseError
            }
        }
    }

    return nil
}
