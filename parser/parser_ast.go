package parser

type Position struct {
	Line int
	Col  int
}

type SourceLocation struct {
	Source string
	Start  Position
	End    Position
}

type Node struct {
	NodeType string
	Location SourceLocation
}

type Expression struct {
	Node
}

type SelfExpression struct {
	Expression
}

type ArrayExpression struct {
	Expression
	Elements []Expression
}

type FunctionExpression struct {
	Function
	Expression
}

// ++, --
type UpdateExpression struct {
	Expression
	Operator string
}

type BinaryExpression struct {
	Expression
	Operator string
	Left     Expression
	Right    Expression
}

type AssignmentExpression struct {
	Expression
	Operator string
	Left     Node
	Right    Expression
}

type LogicalExpression struct {
	Expression
	Operator string
	Left     Expression
	Right    Expression
}

type MemberExpression struct {
	Expression
	Pattern
	Object   Expression
	Property Expression // | Identifier, Computed true -> Expression, false -> Identifier
	Computed bool       // true -> a[b], false -> a.b
}

type CastExpression struct {
	Expression
	CastType string
}

type CallExpression struct {
	Callee    Expression
	Arguments []Expression
}

type Property struct {
	Node
	Key        Identifier
	Expression Expression
	Flag       []Flag
	Get        FunctionExpression
	Set        FunctionExpression
}

type Pattern struct {
	Node
}

type Literal struct {
	Expression
	Value string
}

type Identifier struct {
	Expression
	Pattern
	Name string
}

type Flag struct {
	Name string
}

// Program
type Program struct {
	ScriptName *ScriptNameStatement
	Body       []Node
}

// Functions
type Function struct {
	Id     Identifier
	Params []Pattern
	Body   FunctionBody
}

type Event struct {
	Id     Identifier
	Params []Pattern
	Body   EventBody
}

// Statements
type StatementB struct {
	Node
}

// ExpressionStatement
type ExpressionStatement struct {
	StatementB
	Expression Expression
}

type ScriptNameStatement struct {
	StatementB
	ScriptName string
	Extends    string
	Flags      []Flag
}

// Directive
type Directive struct {
	Node
	Directive  string
	Expression Literal
}

// Block Statement
type BlockStatement struct {
	Statement
	Body []StatementB
}

// Body
type FunctionBody struct {
	BlockStatement
	Body []Node
}

type EventBody struct {
	BlockStatement
	Body []Node
}

// Statements
type EmptyStatement struct {
	StatementB
}

type ReturnStatement struct {
	StatementB
	Argument Expression
}

type BreakStatement struct {
	StatementB
	Label Identifier
}

type ContinueStatement struct {
	StatementB
	Label Identifier
}

// Choices
type IfStatement struct {
	StatementB
	Test       Expression
	Consequent StatementB
	Alternate  StatementB
}

type SwitchStatement struct {
	Discriminant Expression
	Cases        []SwitchCase
}

type SwitchCase struct {
	Node
	Test       Expression
	Consequent []StatementB
}

// Loops
type WhileStatement struct {
	StatementB
	Test Expression
	Body StatementB
}

type DoWhileStatement struct {
	StatementB
	Test Expression
	Body StatementB
}

type ForStatement struct {
	StatementB
	Init   Expression
	Test   Expression
	Update Expression
	Body   StatementB
}

// Declaration
type Declaration struct {
	StatementB
}

// Variable Declaration
type VariableDeclaration struct {
	Id   Pattern
	Init Expression
}

// Function Declaration
type FunctionDeclaration struct {
	Function
	Declaration
}
