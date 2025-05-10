// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'characters.dart';
import 'token.dart';

extension type KeywordState._(int _offset) {
  static const int blockSize = 59;

  @pragma("vm:prefer-inline")
  bool get isNull => _offset == 0;

  @pragma("vm:prefer-inline")
  Keyword? get keyword {
    // The 0'th index at the offset.
    int keywordIndexPlusOne = KeywordStateHelper._table![_offset];
    if (keywordIndexPlusOne == 0) return null;
    return Keyword.values[keywordIndexPlusOne - 1];
  }

  @pragma("vm:prefer-inline")
  KeywordState next(int next) {
    // The entry for next starts with A at index offset + 1 because offset + 0
    // is the (possible) keyword.
    return new KeywordState._(
      KeywordStateHelper._table![_offset + next - $A + 1],
    );
  }
}

final class KeywordStateHelper {
  static Uint16List? _table;
  static KeywordState get table {
    if (_table == null) {
      // This is a fixed calculation, though if creating more keywords this
      // number of (double) bytes might have to change.
      Uint16List table = _table = new Uint16List(297 * KeywordState.blockSize);
      int nextEmpty = 2 * KeywordState.blockSize;
      for (int i = 0; i < Keyword.values.length; i++) {
        Keyword keyword = Keyword.values[i];
        String lexeme = keyword.lexeme;
        // At this point we're looking at the $blockSize bytes
        // $blockSize->(2 * $blockSize + 1).
        // The first blockSize bytes (0->($blockSize-1)) are all 0s,
        // being the "null leaf".
        int offset = KeywordState.blockSize;
        // For an offset, the 0'th byte is a link to the keyword
        // (+1, so 0 means no keyword) and the remaining 58 spots are table
        // entries for codeUnit - $A.
        for (int j = 0; j < lexeme.length; j++) {
          int charOffset = lexeme.codeUnitAt(j) - $A;
          int link = table[offset + 1 + charOffset];
          if (link == 0) {
            // New one
            table[offset + 1 + charOffset] = nextEmpty;
            offset = nextEmpty;
            nextEmpty += KeywordState.blockSize;
          } else {
            // Existing one.
            offset = link;
          }
        }
        // this offsets position 0 points to the i+1'th keyword.
        table[offset + 0] = i + 1;
      }
      assert(nextEmpty == table.length);
    }
    return new KeywordState._(KeywordState.blockSize);
  }
}
