class TreeOptions {
  final bool throwWhenMissingScriptname;
  final bool throwWhenReturnOutsideOfFunctionOrEvent;
  final bool throwWhenIfOutsideOfFunctionOrEvent;
  final bool throwWhenCallExpressionOutsideOfFunctionOrEvent;
  final bool throwWhenCastExpressionOutsideOfFunctionOrEvent;
  final bool throwWhenWhileStatementOutsideOfFunctionOrEvent;

  const TreeOptions({
    this.throwWhenMissingScriptname = true,
    this.throwWhenReturnOutsideOfFunctionOrEvent = true,
    this.throwWhenIfOutsideOfFunctionOrEvent = true,
    this.throwWhenCallExpressionOutsideOfFunctionOrEvent = true,
    this.throwWhenCastExpressionOutsideOfFunctionOrEvent = true,
    this.throwWhenWhileStatementOutsideOfFunctionOrEvent = true,
  });
}
