package parser

import "testing"

func TestWhileParenthesesWithSpaceOk(t *testing.T) {
    parser := setup(`Scriptname test

while (true )

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestWhileWithFunctionCallOk(t *testing.T) {
    parser := setup(`Scriptname test

while toto()

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestWhileWithFunctionCallAndParenthesisOk(t *testing.T) {
    parser := setup(`Scriptname test

while (toto())

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestWhileNoParenthesesOk(t *testing.T) {
    parser := setup(`Scriptname test

while true

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestWhileParenthesesNoSpacesOk(t *testing.T) {
    parser := setup(`Scriptname test

while(true)

endwhile`)

    err := parser.checkWhile()

    if err != nil {
        t.Errorf("wanted: no error, got: %s", err.Error())
    }
}

func TestWhileNotClosedNonOk(t *testing.T) {
    parser := setup(`Scriptname test

while (true)

endwh`)

    err := parser.checkWhile()

    if err == nil {
        t.Error("wanted: parse error while statement not closed, got: ok")
    }
}

func TestWhileMissingCloseParenthesisNonOk(t *testing.T) {
    parser := setup(`Scriptname test

while (true

endwhile`)

    err := parser.checkWhile()

    if err == nil {
        t.Error("wanted: parse error while statement not closed, got: ok")
    }
}

func TestWhileMissingOpenParenthesisNonOk(t *testing.T) {
    parser := setup(`Scriptname test

while true)

endwhile`)

    err := parser.checkWhile()

    if err == nil {
        t.Error("wanted: parse error while statement not closed, got: ok")
    }
}
