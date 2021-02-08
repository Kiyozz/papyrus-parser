package parser

import "testing"

func TestCheckScriptNameOk(t *testing.T) {
    parser := setup("Scriptname test")

    err := parser.checkScriptName()

    if err != nil {
        t.Errorf(`wanted: no error, got: %s`, err.Error())
    }
}

func TestCheckScriptNameOkWithExtends(t *testing.T) {
    parser := setup("Scriptname test extends Quest")

    err := parser.checkScriptName()

    if err != nil {
        t.Errorf(`wanted: no error, got: %s`, err.Error())
    }
}

func TestCheckScriptNameNonOk(t *testing.T) {
    parser := setup("Scriptname testfail")

    err := parser.checkScriptName()

    if err == nil {
        t.Error("wanted: parse error Scriptname, got: ok")
    }
}
