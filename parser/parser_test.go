package parser

func setup(content string) *Parser {
    return &Parser{
        File:       "test.psc",
        Filename:   "test.psc",
        Content:    content,
        ScriptName: "test",
    }
}
