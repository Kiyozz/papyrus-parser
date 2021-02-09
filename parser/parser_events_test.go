package parser

import (
    "strings"
    "testing"
)

func TestMultipleEventsWithOneArgOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEvent(string name)

EndEvent`)

    err := parser.checkEvents()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestMultipleEventsWithArgsOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEvent(string name, string test)

EndEvent`)

    err := parser.checkEvents()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestEventsMultipleEventsNotClosedNonOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEve

Event OnCustomEvent(string name, string test)

EndEven`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    } else {
        wantedErr := "OnUpdate Event error: Event is not closed"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestEventsMultipleEventsParenthesisNotOpenedNonOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEventstring name, string test)

EndEvent`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    } else {
        wantedErr := "OnCustomEventstring Event error: missing open parenthesis"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestEventsMultipleEventsParenthesisNotClosedNonOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEvent(string name, string test

EndEvent`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    } else {
        wantedErr := "OnCustomEvent Event error: missing close parenthesis"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestEventsMissingNameNonOk(t *testing.T) {
    parser := setup(`Event

EndEvent`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    } else {
        wantedErr := "Event error: missing name"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}

func TestEventsMissingNameEvenWithParenthesisNonOk(t *testing.T) {
    parser := setup(`Event()

EndEvent`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    } else {
        wantedErr := "Event error: missing name"

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}
