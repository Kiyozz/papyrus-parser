package parser

import "testing"

func TestCheckEventsArgOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEvent(string name)

EndEvent`)

    err := parser.checkEvents()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckEventsArgsOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEvent(string name, string test)

EndEvent`)

    err := parser.checkEvents()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckEventsArgsMissingEndNonOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEve

Event OnCustomEvent(string name, string test)

EndEven`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    }
}

func TestCheckEventsArgsMissingParenthesesNonOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEventstring name, string test)

EndEvent`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    }
}

func TestCheckEventsArgsMissingParenthesesEndNonOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEvent(string name, string test

EndEvent`)

    err := parser.checkEvents()

    if err == nil {
        t.Error("wanted: parse error event test, got: ok")
    }
}
