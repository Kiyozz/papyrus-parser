package parser

import (
    "strings"
    "testing"
)

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

func TestIfInFunctionAndFunctionCallOk(t *testing.T) {
    parser := setup(`Scriptname test

Int Function test2()
    if active()

    endif
EndFunction`)

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
    } else {
        wantedErr := "if is not closed (missing endif)"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestIfMissingCloseParenthesisNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true

endif`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    } else {
        wantedErr := "if error: missing close parenthesis"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestIfMissingOpenParenthesisNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if true)

endif`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    } else {
        wantedErr := "if error: missing open parenthesis"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestIfMissingEndInCommentNonOk(t *testing.T) {
    parser := setup(`Scriptname test

if (true)

;endif`)

    err := parser.checkIf()

    if err == nil {
        t.Error("wanted: parse error if statement not closed, got: ok")
    } else {
        wantedErr := "if is not closed (missing endif)"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}
