class ParserOptions {
  final bool throwScriptnameMissing;
  final bool throwScriptnameMismatch;
  final bool throwReturnOutside;
  final bool throwIfOutside;
  final bool throwCallOutside;
  final bool throwCastOutside;
  final bool throwWhileOutside;
  final bool throwBinaryOutside;
  final bool throwNewOutside;

  const ParserOptions({
    this.throwScriptnameMissing = true,
    this.throwScriptnameMismatch = true,
    this.throwReturnOutside = true,
    this.throwIfOutside = true,
    this.throwCallOutside = true,
    this.throwCastOutside = true,
    this.throwWhileOutside = true,
    this.throwBinaryOutside = true,
    this.throwNewOutside = true,
  });
}
