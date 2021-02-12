package main

import (
    "fmt"
    "log"
    "papyrus-parser/parser"
)

func main() {
    pscParser, err := parser.New("parser/example.psc")

    if err != nil {
        log.Fatal(fmt.Sprintf("create parser error: %s", err.Error()))
    }

    err = pscParser.Parse()

    if err != nil {
        log.Fatal(fmt.Sprintf("parse error: %s", err.Error()))
    }
}
