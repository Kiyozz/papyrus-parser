package parser

import "testing"

func TestCheckTrailingLeftWhitespaceOk(t *testing.T) {
    parser := setup("Scriptname test")

    err := parser.checkTrailingWhitespaces()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckTrailingLeftWhitespaceNonOk(t *testing.T) {
    parser := setup("  Scriptname test")

    err := parser.checkTrailingWhitespaces()

    if err == nil {
        t.Error("wanted: parse error trailing whitespaces, got: ok")
    }
}

func TestCheckTrailingRightWhitespaceOk(t *testing.T) {
    parser := setup("Scriptname test")

    err := parser.checkTrailingWhitespaces()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckTrailingRightWhitespaceNonOk(t *testing.T) {
    parser := setup("Scriptname test  ")

    err := parser.checkTrailingWhitespaces()

    if err == nil {
        t.Error("wanted: parse error trailing whitespaces, got: ok")
    }
}

func TestCheckTrailingWhitespaceInStatementOk(t *testing.T) {
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

func TestCheckTrailingWhitespaceInEmptyLineNonOk(t *testing.T) {
    parser := setup(`Scriptname test

Function toto()
    if active()
    
    endif
EndFunction`)

    err := parser.checkTrailingWhitespaces()

    if err == nil {
        t.Error("wanted: parse error trailing whitespaces, got: ok")
    }
}
