package parser

import (
    "strings"
    "testing"
)

func TestFunctionBasicOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test()
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestFunctionWithOneArgOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test(string name)
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestFunctionWithArgsOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test(string name, int test)
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestFunctionWithArgsArrayOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test(string[] name, int test)
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestFunctionReturnTypeArrayOk(t *testing.T) {
    parser := setup(`Scriptname test

int[] Function test(string[] name, int test)
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestFunctionReturnTypeNonArrayOk(t *testing.T) {
    parser := setup(`Scriptname test

int Function test(string[] name, int test)
EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestFunctionMultipleFunctionOk(t *testing.T) {
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

func TestFunctionLineCommentTrailingCommaOk(t *testing.T) {
    parser := setup(`Scriptname test

;int Function test(string name,)

;EndFunction`)

    err := parser.checkFunctions()

    if err != nil {
        t.Errorf("wanted: ok, got: %s", err.Error())
    }
}

func TestFunctionNotClosedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test()
EndFunctio`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "test Function error: Function is not closed"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionParenthesisNotClosedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test(
EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "test Function error: missing close parenthesis"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionParenthesisNotOpenedWithCloseParenthesisNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test)
EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "test Function error: missing open parenthesis"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionParenthesisNotOpenedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test
EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "test Function error: missing open parenthesis"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionMissingNameNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function
EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "Function error: missing name"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionNotClosedMultipleNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function test()
EndFunction

String Function test2()

EndFunctio`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "String test2 Function error: Function is not closed"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionTrailingCommaNonOk(t *testing.T) {
    parser := setup(`Scriptname test

String Function test(string name,)
EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "String test Function error: trailing comma"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionMissingEndInCommentNonOk(t *testing.T) {
    parser := setup(`Scriptname test

String Function test(string name)
;EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "String test Function error: Function is not closed"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestFunctionMultipleMissingEndInCommentNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Int Function test()

;EndFunction

Function test3()

EndFunction`)

    err := parser.checkFunctions()

    if err == nil {
        t.Error("wanted: parse error Function test, got: ok")
    } else {
        wantedErr := "test3 Function error: Function is not closed"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}
