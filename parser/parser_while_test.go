package parser

import "testing"

func TestCheckWhileOk(t *testing.T) {
    parser := setup(`Scriptname test

while (true)

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckWhileNoParenthesesOk(t *testing.T) {
    parser := setup(`Scriptname test

while true

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckWhileParenthesesNoSpacesOk(t *testing.T) {
    parser := setup(`Scriptname test

while(true)

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestCheckWhileEndNonOk(t *testing.T) {
    parser := setup(`Scriptname test

while (true)

endwhil`)

    err := parser.checkWhile()

    if err == nil {
        t.Error("wanted: parse error while statement not closed, got: ok")
    }
}

func TestCheckWhileParenthesesNotClosedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

while (true

endwhile`)

    err := parser.checkWhile()

    if err == nil {
        t.Error("wanted: parse error while statement not closed, got: ok")
    }
}

func TestCheckWhileParenthesesNotOpenedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

while true)

endwhile`)

    err := parser.checkWhile()

    if err == nil {
        t.Error("wanted: parse error while statement not closed, got: ok")
    }
}
