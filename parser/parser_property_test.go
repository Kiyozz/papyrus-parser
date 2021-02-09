package parser

import (
    "strings"
    "testing"
)

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

func TestPropertyAutoHiddenOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp Auto Hidden`)

    err := parser.checkProperty()

    if err != nil {
        t.Errorf("wanted: ok, got: %s", err.Error())
    }
}

func TestPropertyAutoConditionalOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp Auto Conditional`)

    err := parser.checkProperty()

    if err != nil {
        t.Errorf("wanted: ok, got: %s", err.Error())
    }
}

func TestPropertyAutoDefaultValueHiddenOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp = 0 Auto Hidden`)

    err := parser.checkProperty()

    if err != nil {
        t.Errorf("wanted: ok, got: %s", err.Error())
    }
}

func TestPropertyNoSpaceBetweenNameAndDefaultValueOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp=0 Auto`)

    err := parser.checkProperty()

    if err != nil {
        t.Errorf("wanted: ok, got: %s", err.Error())
    }
}

func TestPropertyArrayTypeOk(t *testing.T) {
    parser := setup(`Scriptname test

int[] Property MyProp Auto`)

    err := parser.checkProperty()

    if err != nil {
        t.Errorf("wanted: ok, got: %s", err.Error())
    }
}

func TestPropertyMissingNameNonOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property`)

    err := parser.checkProperty()

    if err == nil {
        t.Error("wanted parse error property, got: ok")
    } else {
        wantedErr := "int property error: missing name"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestPropertyMissingFlagNonOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp`)

    err := parser.checkProperty()

    if err == nil {
        t.Error("wanted parse error property, got: ok")
    } else {
        wantedErr := "int MyProp property error: missing flag"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestPropertyUnknownFlagAutNonOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp Aut`)

    err := parser.checkProperty()

    if err == nil {
        t.Error("wanted parse error property, got: ok")
    } else {
        wantedErr := "int MyProp property error: unknown flag Aut"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestPropertyUnknownExtraFlagHiddNonOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp Auto Hidd`)

    err := parser.checkProperty()

    if err == nil {
        t.Error("wanted parse error property, got: ok")
    } else {
        wantedErr := "int MyProp property error: unknown flag Hidd"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestPropertyUnknownFlagAutoMissingNonOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp AutoMissing`)

    err := parser.checkProperty()

    if err == nil {
        t.Error("wanted parse error property, got: ok")
    } else {
        wantedErr := "int MyProp property error: unknown flag AutoMissing"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestPropertyAutoReadOnlyMissingDefaultValueNonOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp AutoReadOnly`)

    err := parser.checkProperty()

    if err == nil {
        t.Error("wanted parse error property, got: ok")
    } else {
        wantedErr := "int MyProp property error: an AutoReadOnly property must have a default value"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestPropertyNonAutoConditionalNonOk(t *testing.T) {
    parser := setup(`Scriptname test

int Property MyProp = 0 AutoReadOnly Conditional`)

    err := parser.checkProperty()

    if err == nil {
        t.Error("wanted parse error property, got: ok")
    }
}
