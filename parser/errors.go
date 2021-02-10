package parser

import (
    "fmt"
)

type CreateParserError struct {
    message string
}

type ParseError struct {
    Line    int
    Col     int
    File    string
    Message string
}

func (e CreateParserError) Error() string {
    return fmt.Sprintf("cannot create parser: %s", e.message)
}

func (e ParseError) Error() string {
    return fmt.Sprintf("[line %d: col %d]; script %s; %s", e.Line, e.Col, e.File, e.Message)
}
