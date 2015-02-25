part of dart._internal;

class Symbol implements core.Symbol {
  final String _name;
  static const String reservedWordRE =
      r'(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|' r'e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|' r'ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|' r'v(?:ar|oid)|w(?:hile|ith))';
  static const String publicIdentifierRE =
      r'(?!' '$reservedWordRE' r'\b(?!\$))[a-zA-Z$][\w$]*';
  static const String identifierRE =
      r'(?!' '$reservedWordRE' r'\b(?!\$))[a-zA-Z$_][\w$]*';
  static const String operatorRE =
      r'(?:[\-+*/%&|^]|\[\]=?|==|~/?|<[<=]?|>[>=]?|unary-)';
  static final RegExp publicSymbolPattern = new RegExp(
      '^(?:$operatorRE\$|$publicIdentifierRE(?:=?\$|[.](?!\$)))+?\$');
  static final RegExp symbolPattern =
      new RegExp('^(?:$operatorRE\$|$identifierRE(?:=?\$|[.](?!\$)))+?\$');
  const Symbol(String name) : this._name = name;
  const Symbol.unvalidated(this._name);
  Symbol.validated(String name) : this._name = validatePublicSymbol(name);
  bool operator ==(other) => other is Symbol && _name == other._name;
  int get hashCode {
    const arbitraryPrime = 664597;
    return 0x1fffffff & (arbitraryPrime * _name.hashCode);
  }
  toString() => 'Symbol("$_name")';
  static String getName(Symbol symbol) => symbol._name;
  static String validatePublicSymbol(String name) {
    if (name.isEmpty || publicSymbolPattern.hasMatch(name)) return name;
    if (name.startsWith('_')) {
      throw new ArgumentError('"$name" is a private identifier');
    }
    throw new ArgumentError('"$name" is not a valid (qualified) symbol name');
  }
  static bool isValidSymbol(String name) {
    return (name.isEmpty || symbolPattern.hasMatch(name));
  }
}
