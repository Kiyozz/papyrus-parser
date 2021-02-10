package parser

import (
    "fmt"
    "os"
    "path"
    "strings"
    "testing"
)

var currentDirectory, _ = os.Getwd()

func TestFilenameErrorNotPscNonOk(t *testing.T) {
    _, err := New("filename.sh")

    if err == nil {
        t.Error("wanted: cannot create parser: cannot use parser on filename.sh file, file must have .psc extension")
    } else {
        wantedErr := fmt.Sprintf("cannot create parser: cannot read file %s, no such file or directory", path.Join(currentDirectory, "filename.sh"))

        if !strings.HasSuffix(err.Error(), wantedErr) {
            t.Errorf("wanted error: %s, got: %s", wantedErr, err.Error())
        }
    }
}
