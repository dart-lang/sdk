// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/**
 * Implementation of [core.Symbol].  This class uses the same name as
 * a core class so a user can't tell the difference.
 *
 * The purpose of this class is to hide [_name] from user code, but
 * make it accessible to Dart platform code via the static method
 * [getName].
 */
class Symbol implements core.Symbol {
  final String _name;

  /**
   * Source of RegExp matching Dart reserved words.
   *
   * Reserved words are not allowed as identifiers.
   */
  static const String reservedWordRE =
      r'(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|'
      r'e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|'
      r'ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|'
      r'v(?:ar|oid)|w(?:hile|ith))';
  /**
   * Source of RegExp matching any public identifier.
   *
   * A public identifier is a valid identifier (not a reserved word)
   * that doesn't start with '_'.
   */
  static const String publicIdentifierRE =
      r'(?!' '$reservedWordRE' r'\b(?!\$))[a-zA-Z$][\w$]*';
  /**
   * Source of RegExp matching any identifier.
   *
   * It matches identifiers but not reserved words. The identifiers
   * may start with '_'.
   */
  static const String identifierRE =
      r'(?!' '$reservedWordRE' r'\b(?!\$))[a-zA-Z$_][\w$]*';
  /**
   * Source of RegExp matching a declarable operator names.
   *
   * The operators that can be declared using `operator` declarations are
   * also the only ones allowed as symbols. The name of the oeprators is
   * the same as the operator itself except for unary minus, where the name
   * is "unary-".
   */
  static const String operatorRE =
      r'(?:[\-+*/%&|^]|\[\]=?|==|~/?|<[<=]?|>[>=]?|unary-)';

  // Grammar if symbols:
  //    symbol ::= qualifiedName | <empty>
  //    qualifiedName ::= publicIdentifier '.' qualifiedName | name
  //    name ::= publicIdentifier
  //           | publicIdentifier '='
  //           | operator
  // where publicIdentifier is any valid identifier (not a reserved word)
  // that isn't private (doesn't start with '_').
  //
  // Railroad diagram of the accepted grammar:
  //
  //    /----------------\
  //    |                |
  //    |          /-[.]-/     /-[=]-\
  //    \         /           /       \
  //  -------[id]------------------------->
  //       \                     /
  //        \------[operator]---/
  //            \              /
  //             \------------/
  //

  /**
   * RegExp that validates a non-empty non-private symbol.
   *
   * The empty symbol is handled before this regexp is used, and is not
   * accepted.
   */
  static final RegExp publicSymbolPattern = new RegExp(
      '^(?:$operatorRE\$|$publicIdentifierRE(?:=?\$|[.](?!\$)))+?\$');

  // The grammar of symbols that may be private is the same as for public
  // symbols, except that "publicIdentifier" is replaced by "identifier",
  // which matches any identifier.

  /**
   * RegExp that validates a non-empty symbol.
   *
   * Private symbols are accepted.
   *
   * The empty symbol is handled before this regexp is used, and is not
   * accepted.
   */
  static final RegExp symbolPattern = new RegExp(
      '^(?:$operatorRE\$|$identifierRE(?:=?\$|[.](?!\$)))+?\$');

  external const Symbol(String name);

  /**
   * Platform-private method used by the mirror system to create
   * otherwise invalid names.
   */
  const Symbol.unvalidated(this._name);

  // This is called by dart2js.
  Symbol.validated(String name)
      : this._name = validatePublicSymbol(name);

  bool operator ==(other) => other is Symbol && _name == other._name;

  int get hashCode {
    const arbitraryPrime = 664597;
    return 0x1fffffff & (arbitraryPrime * _name.hashCode);
  }

  toString() => 'Symbol("$_name")';

  /// Platform-private accessor which cannot be called from user libraries.
  static String getName(Symbol symbol) => symbol._name;

  static String validatePublicSymbol(String name) {
    if (name.isEmpty || publicSymbolPattern.hasMatch(name)) return name;
    if (name.startsWith('_')) {
      // There may be other private parts in a qualified name than the first
      // one, but this is a common case that deserves a specific error
      // message.
      throw new ArgumentError('"$name" is a private identifier');
    }
    throw new ArgumentError(
        '"$name" is not a valid (qualified) symbol name');
  }

  /**
   * Checks whether name is a valid symbol name.
   *
   * This test allows both private and non-private symbols.
   */
  static bool isValidSymbol(String name) {
    return (name.isEmpty || symbolPattern.hasMatch(name));
  }
}
