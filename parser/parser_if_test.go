package parser

import "testing"

func TestIfParenthesesWithSpaceOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true )

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestIfWithFunctionCallOk(t *testing.T) {
    parser := setup(`Scriptname test

if toto()

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestIfWithFunctionCallAndParenthesisOk(t *testing.T) {
    parser := setup(`Scriptname test

if (toto())

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestIfNoParenthesesOk(t *testing.T) {
    parser := setup(`Scriptname test

if true

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestIfParenthesesNoSpacesOk(t *testing.T) {
    parser := setup(`Scriptname test

if(true)

endif`)

    err := parser.checkIf()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestIfNotClosedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true)

endi`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    }
}

func TestIfMissingCloseParenthesisNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true

endif`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    }
}

func TestIfMissingOpenParenthesisNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if true)

endif`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    }
}
