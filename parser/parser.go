package parser

import (
    "fmt"
    "io/ioutil"
    "os"
    "path"
    "regexp"
    "strings"
)

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

    lineIgnore []uint16
}

type Statement struct {
    Start string
    End   string
}

func New(file string) (*Parser, error) {
    absolutePath, err := getAbsolutePath(file)

    if err != nil {
        return nil, err
    }

    contentByte, err := readFile(absolutePath)

    if err != nil {
        return nil, err
    }

    content := string(contentByte)
    filename, scriptName, err := getFilenameAndScriptName(absolutePath)

    if err != nil {
        return nil, err
    }

    return &Parser{
        File:       file,
        Filename:   filename,
        Content:    content,
        ScriptName: scriptName,
        lineIgnore: []uint16{},
    }, nil
}

func getAbsolutePath(file string) (string, error) {
    if path.IsAbs(file) {
        return file, nil
    }

    wd, err := os.Getwd()

    if err != nil {
        return "", CreateParserError{message: "cannot get current directory"}
    }

    return path.Join(wd, file), nil
}

func getFilenameAndScriptName(file string) (string, string, error) {
    base := path.Base(file)

    if path.Ext(file) != ".psc" {
        return "", "", CreateParserError{message: fmt.Sprintf("cannot use file %s, file does not have .psc extension", base)}
    }

    return base, strings.Replace(base, ".psc", "", 1), nil
}

func readFile(file string) ([]byte, error) {
    if !path.IsAbs(file) {
        return nil, CreateParserError{message: fmt.Sprintf("cannot read file %s, not an absolute path", file)}
    }

    stat, err := os.Stat(file)

    if err != nil {
        return nil, CreateParserError{message: fmt.Sprintf("cannot read file %s, no such file or directory", file)}
    }

    if stat.IsDir() {
        return nil, CreateParserError{message: fmt.Sprintf("cannot use %s, path is directory", file)}
    }

    bytes, err := ioutil.ReadFile(file)

    return bytes, nil
}

func (p *Parser) Parse() error {
    checks := []func() error{p.checkTrailingWhitespaces, p.checkScriptName, p.checkFunctions, p.checkIf, p.checkWhile}

    for _, check := range checks {
        err := check()

        if err != nil {
            return err
        }
    }

    return nil
}

func (p *Parser) lines(trim bool) []string {
    content := p.Content

    if trim {
        content = strings.Trim(content, " ")
    }

    s := strings.Split(content, "\n")

    if trim {
        s = mapFunc(s, func(v string) string {
            return strings.Trim(v, " ")
        })

        s = filterFunc(s, func(v string) bool {
            return !strings.HasPrefix(v, ";")
        })
    }

    return filter(s, "")
}

func (p *Parser) checkTrailingWhitespaces() error {
    for i, line := range p.lines(false) {
        trimmedLine := strings.Trim(line, " ")

        if trimmedLine != "" && !strings.HasPrefix(trimmedLine, "Function") && !strings.HasPrefix(trimmedLine, "Event") && !strings.HasPrefix(trimmedLine, "Scriptname") {
            continue
        }

        err := ParseError{
            Line: i + 1,
            Col:  1,
            File: p.Filename,
        }

        if strings.TrimLeft(line, " ") != line {
            numberOfSpaces := len(line) - len(trimmedLine)

            err.Col = numberOfSpaces + 1

            if trimmedLine == "" {
                err.Message = "trailing whitespace error: on empty line"
            } else {
                err.Message = "trailing whitespace error: at the beginning of the line"
            }

            return err
        }

        if strings.TrimRight(line, " ") != line {
            numberOfSpaces := len(line) - len(trimmedLine)
            repeated := strings.Repeat(" ", numberOfSpaces)
            col := strings.LastIndex(line, repeated)

            err.Col = col + 1
            err.Message = "trailing whitespace error: at the end of the line"

            return err
        }
    }

    return nil
}

func (p *Parser) checkScriptName() error {
    scriptNameLine := p.lines(true)[0]
    reg := regexp.MustCompile(`(Scriptname)(\s)?([\w\d]+)?(\s*)(extends)?(\s*)([\w\d]+)?(\s*)([\w\d]+)?`)
    match := reg.FindStringSubmatch(scriptNameLine)

    err := ParseError{
        Line: 1,
        Col:  1,
        File: p.Filename,
    }

    if match == nil {
        err.Message = "Scriptname error: no Scriptname specified"

        return err
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
        err.Col = len(scriptName)
        err.Message = "Scriptname error: missing space after Scriptname"

        return err
    }

    if scriptNameValue != p.ScriptName {
        err.Col = len(fmt.Sprintf("%s ", scriptName))

        if scriptNameValue == "" {
            err.Message = "Scriptname error: missing name"
        } else {
            err.Message = fmt.Sprintf("Scriptname error: Scriptname must match filename, %s expected, got %s", p.ScriptName, scriptNameValue)
        }

        return err
    }

    if scriptNameFlag != "" && scriptNameFlag != "Conditional" && scriptNameFlag != "Hidden" {
        err.Col = len(fmt.Sprintf("%s %s%s%s%s%s%s", scriptName, scriptNameValue, spaceBeforeExtends, extends, spaceAfterExtends, extendedScript, spaceAfterExtended))
        err.Message = fmt.Sprintf("Scriptname error: unknown flag %s", scriptNameFlag)

        return err
    }

    p.Extends = extendedScript
    p.Flag = scriptNameFlag
    p.lineIgnore = append(p.lineIgnore, 1)

    return nil
}

func (p *Parser) checkStatement(s *Statement) error {
    split := p.lines(true)
    splitLen := len(split)
    reg := regexp.MustCompile(fmt.Sprintf(`^%s(\s*)(\()?([^)|&=!"'@#\-*+]+)?([|&=!"'@#\-*+/(]+)?(\))?`, s.Start))

    for i, lineContent := range split {
        if contains(p.lineIgnore, uint16(i)) || lineContent == s.End {
            continue
        }

        match := reg.FindStringSubmatch(lineContent)

        if match == nil {
            continue
        }

        spaceBeforeOpenParenthesis := match[1]
        openParenthesis := match[2]
        args := match[3]
        extraCharacters := match[4]
        closeParenthesis := match[5]

        if openParenthesis == "" && strings.HasSuffix(args, "(") && closeParenthesis == ")" {
            args = fmt.Sprintf("%s%s", args, ")")
            closeParenthesis = ""
        }

        err := ParseError{
            Line: i + 1,
            Col:  1,
            File: p.Filename,
        }

        if openParenthesis != "" || closeParenthesis != "" {
            if openParenthesis != "(" {
                err.Col = len(fmt.Sprintf("%s%s", s.Start, spaceBeforeOpenParenthesis))
                err.Message = fmt.Sprintf("%s error: missing open parenthesis", s.Start)

                return err
            }

            if closeParenthesis != ")" {
                err.Col = len(fmt.Sprintf("%s%s%s", s.Start, spaceBeforeOpenParenthesis, args))
                err.Message = fmt.Sprintf("%s error: missing close parenthesis", s.Start)

                return err
            }
        }

        if extraCharacters != "" {
            err.Col = len(lineContent)
            err.Message = fmt.Sprintf("%s error: extraneous %s", s.Start, extraCharacters)

            return err
        }

        hasEnd := i + 1 < splitLen

        for j := i + 1; j < splitLen; j++ {
            jLineContent := split[j]

            if contains(p.lineIgnore, uint16(j)) {
                hasEnd = false

                continue
            }

            hasEnd = strings.HasPrefix(jLineContent, s.End)

            if hasEnd {
                p.lineIgnore = append(p.lineIgnore, uint16(j))
                break
            }
        }

        if !hasEnd {
            return ParseError{
                Line:    i + 1,
                Col:     1,
                File:    p.Filename,
                Message: fmt.Sprintf("%s is not closed (missing %s)", s.Start, s.End),
            }
        }
    }

    return nil
}

func (p *Parser) checkBlock(s *Statement) error {
    split := p.lines(true)
    splitLen := len(split)
    regStart := regexp.MustCompile(fmt.Sprintf(`(([\w\d]+)?(\[])?)?\s*%s(\s*)?([\d\w]+)?(\()?([^)]+)?(\))?`, s.Start))

    for i, lineContent := range split {
        // FIXME: if user set two EndStatement without opening two, the error is not caught
        // TO BE REMOVED: lineContent == s.End
        if contains(p.lineIgnore, uint16(i)) || lineContent == s.End {
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

        err := ParseError{
            Line: i + 1,
            Col:  1,
            File: p.Filename,
        }

        if name == "" {
            err.Message = strings.Trim(fmt.Sprintf("%s %s error: missing name", returnType, s.Start), " ")

            return err
        }

        if openParenthesis == "" {
            err.Message = strings.Trim(fmt.Sprintf("%s %s %s error: missing open parenthesis", returnType, name, s.Start), " ")

            return err
        }

        if closeParenthesis == "" {
            err.Message = strings.Trim(fmt.Sprintf("%s %s %s error: missing close parenthesis", returnType, name, s.Start), " ")

            return err
        }

        if strings.HasSuffix(args, ",") {
            err.Message = strings.Trim(fmt.Sprintf("%s %s %s error: trailing comma", returnType, name, s.Start), " ")

            return err
        }

        hasEnd := i + 1 < splitLen

        for j := i + 1; j < splitLen; j++ {
            jLineContent := split[j]

            if jLineContent == "" || contains(p.lineIgnore, uint16(j)) {
                hasEnd = false

                continue
            }

            hasEnd = strings.HasPrefix(jLineContent, s.End)

            if hasEnd {
                p.lineIgnore = append(p.lineIgnore, uint16(j))

                break
            }
        }

        if !hasEnd {
            err.Message = strings.Trim(fmt.Sprintf("%s %s %s error: %s is not closed", returnType, name, s.Start, s.Start), " ")

            return err
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
    split := p.lines(true)
    reg := regexp.MustCompile(`^([\w\d]+(\[])?)\s+Property(\s+([\w\d]+)?\s*(=\s*([\w\d]+))?\s*((\w+)?\s*(\w+)?$)?)?`)

    for i, lineContent := range split {
        match := reg.FindStringSubmatch(lineContent)

        if match == nil {
            continue
        }

        propType := match[1]      // variable type
        propName := match[4]      // variable name
        defaultValue := match[6]  // = XX
        propFlag := match[8]      // Auto/AutoReadOnly
        propExtraFlag := match[9] // Hidden/Conditional

        err := ParseError{
            Line: i + 1,
            Col:  len(lineContent), // FIXME: not the same everywhere
            File: p.Filename,
        }

        if propName == "" {
            err.Message = fmt.Sprintf("%s property error: missing name", propType)

            return err
        }

        if propFlag == "" {
            err.Message = fmt.Sprintf("%s %s property error: missing flag", propType, propName)

            return err
        } else {
            if propFlag != "AutoReadOnly" && propFlag != "Auto" {
                err.Message = fmt.Sprintf("%s %s property error: unknown flag %s", propType, propName, propFlag)

                return err
            }

            if propFlag == "AutoReadOnly" && defaultValue == "" {
                err.Message = fmt.Sprintf("%s %s property error: an AutoReadOnly property must have a default value", propType, propName)

                return err
            }
        }

        if propExtraFlag != "" {
            if propExtraFlag != "Conditional" && propExtraFlag != "Hidden" {
                err.Message = fmt.Sprintf("%s %s property error: unknown flag %s", propType, propName, propExtraFlag)

                return err
            }

            if propFlag != "Auto" && propExtraFlag == "Conditional" {
                err.Message = fmt.Sprintf("%s %s property error: Conditional is only applicable on property flagged Auto", propType, propName)

                return err
            }
        }
    }

    return nil
}

func isComment(line string) bool {
    return strings.HasPrefix(strings.Trim(line, " "), ";")
}

func contains(slice []uint16, item uint16) bool {
    for _, a := range slice {
        if a == item {
            return true
        }
    }

    return false
}

func filter(s []string, v string) []string {
    var f []string

    for _, sv := range s {
        if sv != v {
            f = append(f, sv)
        }
    }

    return f
}

func filterFunc(s []string, v func(_ string) bool) []string {
    var f []string

    for _, sv := range s {
        if v(sv) {
            f = append(f, sv)
        }
    }

    return f
}

func mapFunc(s []string, c func(_ string) string) []string {
    f := s

    for i, v := range s {
        f[i] = c(v)
    }

    return f
}
