package parser

import (
    "strings"
    "testing"
)

func TestCheckFunctionsOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test()
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckFunctionsArgsOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test(string name)
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckFunctionsNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test()
EndFunctio`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    }
}

func TestCheckFunctionsParenthesesNotClosedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test(
EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    }
}

func TestCheckFunctionsParenthesesNotOpenedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test)
EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    }
}

func TestCheckFunctionsMultipleOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test()
EndFunction

String Function test2()

EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckFunctionsMultipleNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test()
EndFunction

String Function test2()

EndFunctio`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
        return
    }

    message := err.Error()

    if !strings.Contains(message, "String test2") {
        t.Errorf("wanted: String test2, got: %s", message)
    }
}
