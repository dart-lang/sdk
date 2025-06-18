// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:kernel/ast.dart';

class Symbols {
  final bool minify;
  Symbols(this.minify);

  SymbolConstant methodSymbolFromName(Name name) {
    return SymbolConstant(name.text, name.libraryReference);
  }

  SymbolConstant getterSymbolFromName(Name name) {
    return SymbolConstant(name.text, name.libraryReference);
  }

  SymbolConstant setterSymbolFromName(Name name) {
    return SymbolConstant('${name.text}=', name.libraryReference);
  }

  SymbolConstant symbolForNamedParameter(String name) {
    // Named parameters cannot be private.
    assert(!name.startsWith('_'));
    return SymbolConstant(name, null);
  }

  final Map<SymbolConstant, int> symbolOrdinals = {};
  String getMangledSymbolName(SymbolConstant symbol) {
    if (minify) {
      return _intToBase64(
          symbolOrdinals.putIfAbsent(symbol, () => symbolOrdinals.length));
    }

    if (symbol.libraryReference == null) {
      return symbol.name;
    }

    // We have a private symbol. The symbol must have been constructed using
    // the `#...` syntax (as all `new Symbol()` or `const Symbol()` are not
    // considered private - even if they start with "_").
    //
    // The symbol must be a private identifier (library symbols like `#a.b.c` do
    // not have private parts in them).
    assert(!symbol.name.contains('.') && symbol.name.startsWith('_'));
    return '${symbol.name}@${symbol.libraryReference!.canonicalName.hashCode}';
  }
}

List<int> _intToLittleEndianBytes(int i) {
  List<int> bytes = [];
  bytes.add(i & 0xFF);
  i >>>= 8;
  while (i != 0) {
    bytes.add(i & 0xFF);
    i >>>= 8;
  }
  return bytes;
}

String _intToBase64(int i) => base64.encode(_intToLittleEndianBytes(i));
