package parser

import (
    "strings"
    "testing"
)

func TestTrailingWhitespaceLeftOk(t *testing.T) {
    parser := setup("Scriptname test")

    err := parser.checkTrailingWhitespaces()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestTrailingWhitespaceRightOk(t *testing.T) {
    parser := setup("Scriptname test")

    err := parser.checkTrailingWhitespaces()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestTrailingWhitespaceInStatementOk(t *testing.T) {
    parser := setup(`Scriptname test

Function toto()
    if active()

    endif
EndFunction`)

    err := parser.checkTrailingWhitespaces()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestTrailingWhitespaceLeftNonOk(t *testing.T) {
    parser := setup("  Scriptname test")

    err := parser.checkTrailingWhitespaces()

    if err == nil {
        t.Error("wanted: parse error trailing whitespaces, got: ok")
    } else {
        wantedErr := "trailing whitespace error: at the beginning of the line"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestTrailingWhitespaceLeftWithFunctionNonOk(t *testing.T) {
    parser := setup(`Scriptname test

  Function test()

EndFunction`)

    err := parser.checkTrailingWhitespaces()

    if err == nil {
        t.Error("wanted: parse error trailing whitespaces, got: ok")
    } else {
        wantedErr := "trailing whitespace error: at the beginning of the line"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestTrailingWhitespaceRightNonOk(t *testing.T) {
    parser := setup("Scriptname test  ")

    err := parser.checkTrailingWhitespaces()

    if err == nil {
        t.Error("wanted: parse error trailing whitespaces, got: ok")
    } else {
        wantedErr := "trailing whitespace error: at the end of the line"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestTrailingWhitespaceInEmptyLineNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function toto()
    if active()
    
    endif
EndFunction`)

    err := parser.checkTrailingWhitespaces()

    if err == nil {
        t.Error("wanted: parse error trailing whitespaces, got: ok")
    } else {
        wantedErr := "trailing whitespace error: on empty line"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}
