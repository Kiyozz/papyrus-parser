package parser

import (
	"strings"
	"testing"
)

func TestScriptNameWithoutExtendsOk(t *testing.T) {
	parser := setup("Scriptname test")

	err := parser.lintScriptName()

	if err != nil {
		t.Errorf(`wanted: no error, got: %s`, err.Error())
	}
}

func TestScriptNameWithExtendsOk(t *testing.T) {
	parser := setup("Scriptname test extends Quest")

	err := parser.lintScriptName()

	if err != nil {
		t.Errorf(`wanted: no error, got: %s`, err.Error())
	}
}

func TestScriptNameWithConditionalOk(t *testing.T) {
	parser := setup("Scriptname test extends Quest Conditional")

	err := parser.lintScriptName()

	if err != nil {
		t.Errorf(`wanted: no error, got: %s`, err.Error())
	}
}

func TestScriptNameWithHiddenOk(t *testing.T) {
	parser := setup("Scriptname test extends Quest Hidden")

	err := parser.lintScriptName()

	if err != nil {
		t.Errorf(`wanted: no error, got: %s`, err.Error())
	}
}

func TestScriptNameNotMatchFilenameNonOk(t *testing.T) {
	parser := setup("Scriptname testfail")

	err := parser.lintScriptName()

	if err == nil {
		t.Error("wanted: parse error Scriptname, got: ok")
	} else {
		wantedErr := "Scriptname error: Scriptname must match filename, test expected, got testfail"

		if !strings.HasSuffix(err.Error(), wantedErr) {
			t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
		}
	}
}

func TestScriptNameNoSpaceNonOk(t *testing.T) {
	parser := setup("Scriptnametest")

	err := parser.lintScriptName()

	if err == nil {
		t.Error("wanted: parse error Scriptname, got: ok")
	} else {
		wantedErr := "Scriptname error: missing space after Scriptname"

		if !strings.HasSuffix(err.Error(), wantedErr) {
			t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
		}
	}
}

func TestScriptNameFlagNonOk(t *testing.T) {
	parser := setup("Scriptname test extends ObjectReference Condition")

	err := parser.lintScriptName()

	if err == nil {
		t.Error("wanted: parse error Scriptname, got: ok")
	} else {
		wantedErr := "Scriptname error: unknown flag Condition"

		if !strings.HasSuffix(err.Error(), wantedErr) {
			t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
		}
	}
}
