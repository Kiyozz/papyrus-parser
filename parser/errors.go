package parser

import (
    "fmt"
)

type RuntimeError struct {
    message string
}

type ParseError struct {
    Line    int
    Col     int
    File    string
    Message string
}

type FilenameError struct {
    file    string
    message string
}

func (e RuntimeError) Error() string {
    return fmt.Sprintf("runtime error: %s", e.message)
}

func (e FilenameError) Error() string {
    return fmt.Sprintf("%s: cannot find Filename", e.file)
}

func (e ParseError) Error() string {
    return fmt.Sprintf("[line %d: col %d]; script %s; %s", e.Line, e.Col, e.File, e.Message)
}
