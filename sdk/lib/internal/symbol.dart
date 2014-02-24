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

  // Reserved words are not allowed as identifiers.
  static const String reservedWordRE =
      r'(?:assert|break|c(?:a(?:se|tch)|lass|on(?:st|tinue))|d(?:efault|o)|'
      r'e(?:lse|num|xtends)|f(?:alse|inal(?:ly)?|or)|i[fns]|n(?:ew|ull)|'
      r'ret(?:hrow|urn)|s(?:uper|witch)|t(?:h(?:is|row)|r(?:ue|y))|'
      r'v(?:ar|oid)|w(?:hile|ith))';
  // Mathces a public identifier (identifier not starting with '_').
  static const String publicIdentifierRE =
      r'(?!' '$reservedWordRE' r'\b(?!\$))[a-zA-Z$][\w$]*';
  // Matches the names of declarable operators.
  static const String operatorRE =
      r'(?:[\-+*/%&|^]|\[\]=?|==|~/?|<[<=]?|>[>=]?|unary-)';

  // Grammar:
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

  // Validates non-empty symbol (empty symbol is handled before using this).
  static final RegExp validationPattern = new RegExp(
      '^(?:$operatorRE\$|$publicIdentifierRE(?:=?\$|[.](?!\$)))+?\$');

  external const Symbol(String name);

  /**
   * Platform-private method used by the mirror system to create
   * otherwise invalid names.
   */
  const Symbol.unvalidated(this._name);

  // This is called by dart2js.
  Symbol.validated(String name)
      : this._name = validate(name);

  bool operator ==(other) => other is Symbol && _name == other._name;

  int get hashCode {
    const arbitraryPrime = 664597;
    return 0x1fffffff & (arbitraryPrime * _name.hashCode);
  }

  toString() => 'Symbol("$_name")';

  /// Platform-private accessor which cannot be called from user libraries.
  static String getName(Symbol symbol) => symbol._name;

  static String validate(String name) {
    if (name.isEmpty || validationPattern.hasMatch(name)) return name;
    if (name.startsWith('_')) {
      // There may be other private parts in a qualified name than the first
      // one, but this is a common case that deserves a specific error
      // message.
      throw new ArgumentError('"$name" is a private identifier');
    }
    throw new ArgumentError(
        '"$name" is not a valid (qualified) symbol name');
  }
}
