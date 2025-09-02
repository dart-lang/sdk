// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';

String codePointToUnicode(int codePoint) {
  // Write unicode value using at least four (but otherwise no more than
  // necessary) hex digits, using uppercase letters.
  // http://www.unicode.org/versions/Unicode10.0.0/appA.pdf
  return "U+${codePoint.toRadixString(16).toUpperCase().padLeft(4, '0')}";
}

String formatNumber(
  num num, {
  int? fractionDigits,
  int padWidth = 0,
  bool padWithZeros = false,
}) {
  String s = fractionDigits == null
      ? '$num'
      : num.toStringAsFixed(fractionDigits);
  return s.padLeft(padWidth, padWithZeros ? '0' : ' ');
}

String nameOrUnnamed(String name) => name.isEmpty ? '(unnamed)' : name;

String stringOrEmpty(String string) => string.isEmpty ? '(empty)' : string;

String tokenToLexeme(Token token) => token.lexeme;

String validateAndDemangleName(String name) {
  if (name.isEmpty) throw 'No name provided';
  return demangleMixinApplicationName(name);
}

String validateAndItemizeNames(List<String> names) {
  if (names.isEmpty) throw 'No names provided';
  return itemizeNames(names);
}

String validateCharacter(String character) {
  if (character.runes.length != 1) throw "Not a character '${character}'";
  return character;
}

String validateString(String string) {
  if (string.isEmpty) throw 'No string provided';
  return string;
}
