package parser

import "testing"

func TestCheckEventsArgsOk(t *testing.T) {
    parser := setup(`Event OnUpdate()

EndEvent

Event OnCustomEvent(string name)

EndEvent`)

    err := parser.checkEvents()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}
