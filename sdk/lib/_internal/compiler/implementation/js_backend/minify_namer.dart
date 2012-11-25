// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Assigns JavaScript identifiers to Dart variables, class-names and members.
 */
class MinifyNamer extends Namer {
  MinifyNamer(Compiler compiler) : super(compiler);

  String get ISOLATE => 'I';
  String get ISOLATE_PROPERTIES => 'p';
  bool get shouldMinify => true;

  const ALPHABET_CHARACTERS = 52;  // a-zA-Z.
  const ALPHANUMERIC_CHARACTERS = 62;  // a-zA-Z0-9.

  // You can pass an invalid identifier to this and unlike its non-minifying
  // counterpart it will never return the proposedName as the new fresh name.
  String getFreshName(String proposedName, Set<String> usedNames) {
    var freshName = _getUnusedName(proposedName, usedNames);
    usedNames.add(freshName);
    return freshName;
  }

  // This gets a minified name based on a hash of the proposed name.  This
  // is slightly less efficient than just getting the next name in a series,
  // but it means that small changes in the input program will give smallish
  // changes in the output, which can be useful for diffing etc.
  String _getUnusedName(String proposedName, Set<String> usedNames) {
    // Try single-character names with characters that occur in the
    // input.
    for (int i = 0; i < proposedName.length; i++) {
      String candidate = proposedName[i];
      int code = candidate.charCodeAt(0);
      if (code < $A) continue;
      if (code > $z) continue;
      if (code > $Z && code < $a) continue;
      if (!usedNames.contains(candidate)) return candidate;
    }

    int hash = _calculateHash(proposedName);
    // Avoid very small hashes that won't try many names.
    hash = hash < 1000 ? hash * 314159 : hash;  // Yes, it's prime.

    // Try other n-character names based on the hash.  We try one to three
    // character identifiers.  For each length we try around 10 different names
    // in a predictable order determined by the proposed name.  This is in order
    // to make the renamer stable: small changes in the input should nornally
    // result in relatively small changes in the output.
    for (var n = 1; n <= 3; n++) {
      int h = hash;
      while (h > 10) {
        var codes = <int>[_letterNumber(h)];
        int h2 = h ~/ ALPHABET_CHARACTERS;
        for (var i = 1; i < n; i++) {
          codes.add(_alphaNumericNumber(h2));
          h2 ~/= ALPHANUMERIC_CHARACTERS;
        }
        final candidate = new String.fromCharCodes(codes);
        if (!usedNames.contains(candidate) && !jsReserved.contains(candidate)) {
          return candidate;
        }
        // Try again with a slightly different hash.  After around 10 turns
        // around this loop h is zero and we try a longer name.
        h ~/= 7;
      }
    }

    // If we can't find a hash based name in the three-letter space, then base
    // the name on a letter and a counter.
    var startLetter = new String.fromCharCodes([_letterNumber(hash)]);
    var i = 0;
    while (usedNames.contains("$startLetter$i")) {
      i++;
    }
    return "$startLetter$i";
  }

  int _calculateHash(String name) {
    int h = 0;
    for (int i = 0; i < name.length; i++) {
      h += name.charCodeAt(i);
      h &= 0xffffffff;
      h += h << 10;
      h &= 0xffffffff;
      h ^= h >> 6;
      h &= 0xffffffff;
    }
    return h;
  }

  int _letterNumber(int x) {
    if (x >= ALPHABET_CHARACTERS) x %= ALPHABET_CHARACTERS;
    if (x < 26) return $a + x;
    return $A + x - 26;
  }

  int _alphaNumericNumber(int x) {
    if (x >= ALPHANUMERIC_CHARACTERS) x %= ALPHANUMERIC_CHARACTERS;
    if (x < 26) return $a + x;
    if (x < 52) return $A + x - 26;
    return $0 + x - 52;
  }

}
