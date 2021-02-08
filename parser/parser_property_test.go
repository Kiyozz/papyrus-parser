package parser

import "testing"

func TestPropertyAutoOk(t *testing.T) {
	parser := setup(`Scriptname test

int Property MyProp Auto`)

	err := parser.checkProperty()

	if err != nil {
		t.Errorf("wanted: ok, got: %s", err.Error())
	}
}

func TestPropertyAutoReadOnlyOk(t *testing.T) {
	parser := setup(`Scriptname test

int Property MyProp = 0 AutoReadOnly`)

	err := parser.checkProperty()

	if err != nil {
		t.Errorf("wanted: ok, got: %s", err.Error())
	}
}

func TestPropertyAutoDefaultValueOk(t *testing.T) {
	parser := setup(`Scriptname test

int Property MyProp = 0 Auto`)

	err := parser.checkProperty()

	if err != nil {
		t.Errorf("wanted: ok, got: %s", err.Error())
	}
}

func TestPropertyAutoNonOk(t *testing.T) {
	parser := setup(`Scriptname test

int Property MyProp Aut`)

	err := parser.checkProperty()

	if err == nil {
		t.Error("wanted parse error property, got: ok")
	}
}

func TestPropertyMissingPropNameNonOk(t *testing.T) {
	parser := setup(`Scriptname test

int Property`)

	err := parser.checkProperty()

	if err == nil {
		t.Error("wanted parse error property, got: ok")
	}
}

func TestPropertyWrongGetterSetterNonOk(t *testing.T) {
	parser := setup(`Scriptname test

int Property MyProp AutoMissing`)

	err := parser.checkProperty()

	if err == nil {
		t.Error("wanted parse error property, got: ok")
	}
}

func TestPropertyAutoReadOnlyNoDefaultValueNonOk(t *testing.T) {
	parser := setup(`Scriptname test

int Property MyProp AutoReadOnly`)

	err := parser.checkProperty()

	if err == nil {
		t.Error("wanted parse error property, got: ok")
	}
}
