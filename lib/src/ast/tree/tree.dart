class TreeOptions {
  final bool throwWhenMissingScriptname;
  final bool throwWhenReturnOutsideOfFunctionOrEvent;

  const TreeOptions({
    this.throwWhenMissingScriptname = true,
    this.throwWhenReturnOutsideOfFunctionOrEvent = true,
  });
}
