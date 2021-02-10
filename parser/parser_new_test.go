package parser

import "testing"

func TestFilenameErrorNotPscNonOk(t *testing.T) {
    _, err := New("filename.sh")

    if err == nil {
        t.Error("wanted: cannot create parser: cannot use parser on filename.sh file, file must have .psc extension")
    }
}
