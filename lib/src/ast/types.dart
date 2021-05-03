enum ScriptNameFlag {
  conditional,
  hidden,
}

enum PropertyFlag { conditional, hidden, auto, autoReadonly }

enum NodeType {
  eof,
  name,
  asKw,
  autoKw,
  autoReadOnlyKw,
  elseKw,
  elseIfKw,
  endEventKw,
  endFunctionKw,
  endIfKw,
  endPropertyKw,
  endStateKw,
  endWhileKw,
  eventKw,
  extendsKw,
  falseKw,
  functionKw,
  globalKw,
  ifKw,
  importKw,
  nativeKw,
  newKw,
  noneKw,
  parentKw,
  propertyKw,
  returnKw,
  scriptNameKw,
  flagKw,
  selfKw,
  stateKw,
  trueKw,
  whileKw,
  parenL,
  parenR,
  comma,
  bracketL,
  bracketR,
  braceL,
  braceR,
  colon,
  equality,
  equal,
  assign,
  num,
  slash,
  string,
  binary,
  logical,
  logicalOr,
  logicalAnd,
  incrementDecrement,
  plusMinus,
  relational,
  char,
  star,
  starstar,
  modulo,
  dot,
  id,
  literal,
  block,
  member,
  variable,
  variableDeclaration,
  program,
  lineTerminator,
  expressionStatement,
  conditionalKw,
  hiddenKw,
  prefix,
  callExpression
}

const keywordsMap = {
  'as': NodeType.asKw,
  'auto': NodeType.autoKw,
  'autoreadonly': NodeType.autoReadOnlyKw,
  'else': NodeType.elseKw,
  'elseif': NodeType.elseIfKw,
  'endevent': NodeType.endEventKw,
  'endfunction': NodeType.endFunctionKw,
  'endif': NodeType.endIfKw,
  'endproperty': NodeType.endPropertyKw,
  'endstate': NodeType.endStateKw,
  'endwhile': NodeType.endWhileKw,
  'event': NodeType.eventKw,
  'extends': NodeType.extendsKw,
  'false': NodeType.falseKw,
  'function': NodeType.functionKw,
  'global': NodeType.globalKw,
  'if': NodeType.ifKw,
  'import': NodeType.importKw,
  'native': NodeType.nativeKw,
  'new': NodeType.newKw,
  'none': NodeType.noneKw,
  'parent': NodeType.parentKw,
  'property': NodeType.propertyKw,
  'return': NodeType.returnKw,
  'scriptname': NodeType.scriptNameKw,
  'self': NodeType.selfKw,
  'state': NodeType.stateKw,
  'true': NodeType.trueKw,
  'while': NodeType.whileKw,
  'conditional': NodeType.conditionalKw,
  'hidden': NodeType.hiddenKw,
};

extension NodeTypeString on NodeType {
  String get name {
    switch (this) {
      case NodeType.asKw:
        return 'As';
      case NodeType.assign:
        return 'Assign';
      case NodeType.autoKw:
        return 'Auto';
      case NodeType.autoReadOnlyKw:
        return 'AutoReadOnly';
      case NodeType.binary:
        return 'Binary';
      case NodeType.block:
        return 'Block';
      case NodeType.braceL:
        return 'Open Brace';
      case NodeType.braceR:
        return 'Close Brace';
      case NodeType.bracketL:
        return 'Open Bracket';
      case NodeType.bracketR:
        return 'Close Bracket';
      case NodeType.callExpression:
        return 'Call Expression';
      case NodeType.char:
        return 'Char';
      case NodeType.colon:
        return 'Colon';
      case NodeType.comma:
        return 'Comma';
      case NodeType.conditionalKw:
        return 'Conditional';
      case NodeType.dot:
        return 'Dot';
      case NodeType.elseIfKw:
        return 'ElseIf';
      case NodeType.elseKw:
        return 'Else';
      case NodeType.endEventKw:
        return 'EndEvent';
      case NodeType.endFunctionKw:
        return 'EndFunction';
      case NodeType.endIfKw:
        return 'EndIf';
      case NodeType.endPropertyKw:
        return 'EndProperty';
      case NodeType.endStateKw:
        return 'EndState';
      case NodeType.endWhileKw:
        return 'EndWhile';
      case NodeType.eof:
        return 'End of file';
      case NodeType.equal:
        return 'Equal';
      case NodeType.equality:
        return 'Equality';
      case NodeType.eventKw:
        return 'Event';
      case NodeType.expressionStatement:
        return 'Expression Statement';
      case NodeType.extendsKw:
        return 'Extends';
      case NodeType.falseKw:
        return 'false';
      case NodeType.flagKw:
        return 'Flag';
      case NodeType.functionKw:
        return 'Function';
      case NodeType.globalKw:
        return 'Global';
      case NodeType.hiddenKw:
        return 'Hidden';
      case NodeType.id:
        return 'Identifier';
      case NodeType.ifKw:
        return 'If';
      case NodeType.importKw:
        return 'Import';
      case NodeType.incrementDecrement:
        return '--++';
      case NodeType.lineTerminator:
        return '\\';
      case NodeType.literal:
        return 'Literal';
      case NodeType.logical:
        return 'Logical';
      case NodeType.logicalAnd:
        return 'Logical And';
      case NodeType.logicalOr:
        return 'Logical Or';
      case NodeType.member:
        return 'MemberExpression';
      case NodeType.modulo:
        return '%';
      case NodeType.name:
        return 'Name';
      case NodeType.nativeKw:
        return 'Literal';
      case NodeType.newKw:
        return 'Literal';
      case NodeType.noneKw:
        return 'Literal';
      case NodeType.num:
        return 'Literal';
      case NodeType.parenL:
        return 'Literal';
      case NodeType.parenR:
        return 'Literal';
      case NodeType.parentKw:
        return 'Literal';
      case NodeType.plusMinus:
        return 'Literal';
      case NodeType.prefix:
        return '~';
      case NodeType.program:
        return 'Program';
      case NodeType.propertyKw:
        return 'Property';
      case NodeType.relational:
        return 'Relational';
      case NodeType.returnKw:
        return 'Return';
      case NodeType.scriptNameKw:
        return 'ScriptName';
      case NodeType.selfKw:
        return 'Self';
      case NodeType.slash:
        return '/';
      case NodeType.star:
        return '*';
      case NodeType.starstar:
        return '**';
      case NodeType.stateKw:
        return 'State';
      case NodeType.string:
        return 'String';
      case NodeType.trueKw:
        return 'true';
      case NodeType.variable:
        return 'Variable';
      case NodeType.variableDeclaration:
        return 'VariableDeclaration';
      case NodeType.whileKw:
        return 'While';
    }
  }
}
