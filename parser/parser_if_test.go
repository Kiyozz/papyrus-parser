package parser

import "testing"

func TestCheckIfOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true)

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckIfWithFunctionCallOk(t *testing.T) {
    parser := setup(`Scriptname test

if toto()

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckIfNoParenthesesOk(t *testing.T) {
    parser := setup(`Scriptname test

if true

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckIfParenthesesNoSpacesOk(t *testing.T) {
    parser := setup(`Scriptname test

if(true)

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckIfEndNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true)

endi`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    }
}

func TestCheckIfParenthesesNotClosedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true

endif`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    }
}

func TestCheckIfParenthesesNotOpenedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if true)

endif`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    }
}
