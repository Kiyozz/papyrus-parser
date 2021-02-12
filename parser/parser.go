package parser

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"strings"
)

type Parser struct {
	File       string
	Filename   string
	Content    string
	Extends    string
	Flag       string
	ScriptName string

	lineIgnore []uint16
}

func New(file string) (*Parser, error) {
	absolutePath, err := getAbsolutePath(file)

	if err != nil {
		return nil, err
	}

	contentByte, err := readFile(absolutePath)

	if err != nil {
		return nil, err
	}

	content := string(contentByte)
	filename, scriptName, err := getFilenameAndScriptName(absolutePath)

	if err != nil {
		return nil, err
	}

	return &Parser{
		File:       file,
		Filename:   filename,
		Content:    content,
		ScriptName: scriptName,
		lineIgnore: []uint16{},
	}, nil
}

func getAbsolutePath(file string) (string, error) {
	if path.IsAbs(file) {
		return file, nil
	}

	wd, err := os.Getwd()

	if err != nil {
		return "", CreateParserError{message: "cannot get current directory"}
	}

	return path.Join(wd, file), nil
}

func getFilenameAndScriptName(file string) (string, string, error) {
	base := path.Base(file)

	if path.Ext(file) != ".psc" {
		return "", "", CreateParserError{message: fmt.Sprintf("cannot use file %s, file does not have .psc extension", base)}
	}

	return base, strings.Replace(base, ".psc", "", 1), nil
}

func readFile(file string) ([]byte, error) {
	if !path.IsAbs(file) {
		return nil, CreateParserError{message: fmt.Sprintf("cannot read file %s, not an absolute path", file)}
	}

	stat, err := os.Stat(file)

	if err != nil {
		return nil, CreateParserError{message: fmt.Sprintf("cannot read file %s, no such file or directory", file)}
	}

	if stat.IsDir() {
		return nil, CreateParserError{message: fmt.Sprintf("cannot use %s, path is directory", file)}
	}

	bytes, err := ioutil.ReadFile(file)

	return bytes, nil
}

func contains(slice []uint16, item uint16) bool {
	for _, a := range slice {
		if a == item {
			return true
		}
	}

	return false
}

func filter(s []string, v string) []string {
	var f []string

	for _, sv := range s {
		if sv != v {
			f = append(f, sv)
		}
	}

	return f
}

func filterFunc(s []string, v func(_ string) bool) []string {
	var f []string

	for _, sv := range s {
		if v(sv) {
			f = append(f, sv)
		}
	}

	return f
}

func mapFunc(s []string, c func(_ string) string) []string {
	f := s

	for i, v := range s {
		f[i] = c(v)
	}

	return f
}
