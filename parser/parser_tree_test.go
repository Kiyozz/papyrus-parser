package parser

import "testing"

func TestTreeScriptNameOk(t *testing.T) {
	parser := setup("Scriptname test extends Quest Hidden Conditional")
	s, err := parser.getScriptNameStatement()

	if err != nil {
		t.Errorf("wanted: no error, got: %s", err.Error())
		return
	}

	if s == nil {
		t.Error("wanted: ScriptNameStatement, got: nil")
		return
	}

	if s.ScriptName != "test" {
		t.Errorf("wanted: test, got: %s", s.ScriptName)
	}

	if s.Extends != "Quest" {
		t.Errorf("wanted: Quest, got: %s", s.Extends)
	}

	n := len(s.Flags)

	if n != 2 {
		t.Errorf("wanted: 2, got: %d", n)
	}

	firstFlag := s.Flags[0]
	secondFlag := s.Flags[1]

	if firstFlag.Name != "Hidden" {
		t.Errorf("wanted: Hidden, got: %s", firstFlag.Name)
	}

	if secondFlag.Name != "Conditional" {
		t.Errorf("wanted: Conditional, got: %s", secondFlag.Name)
	}
}

func TestTreeScriptNameNonOk(t *testing.T) {
	parser := setup("Scriptname test extends ")
	_, err := parser.getScriptNameStatement()

	if err == nil {
		t.Error("wanted: scriptname error, got: ok")
	}
}
