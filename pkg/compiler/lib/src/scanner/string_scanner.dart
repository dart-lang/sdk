// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

/**
 * Scanner that reads from a String and creates tokens that points to
 * substrings.
 */
class StringScanner extends ArrayBasedScanner {
  /** The file content. */
  String string;

  /** The current offset in [string]. */
  int scanOffset = -1;

  StringScanner(SourceFile file, {bool includeComments: false})
      : string = file.slowText(),
        super(file, includeComments) {
    ensureZeroTermination();
  }

  StringScanner.fromString(this.string, {bool includeComments: false})
      : super(null, includeComments) {
    ensureZeroTermination();
  }

  void ensureZeroTermination() {
    if (string.isEmpty || string.codeUnitAt(string.length - 1) != 0) {
      // TODO(lry): abort instead of copying the array, or warn?
      string = string + '\x00';
    }
  }

  int advance() => string.codeUnitAt(++scanOffset);
  int peek() => string.codeUnitAt(scanOffset + 1);

  int get stringOffset => scanOffset;

  int currentAsUnicode(int next) => next;

  void handleUnicode(int startScanOffset) { }

  Token firstToken() => tokens.next;
  Token previousToken() => tail;

  void appendSubstringToken(PrecedenceInfo info, int start,
                            bool asciiOnly, [int extraOffset = 0]) {
    tail.next = new StringToken.fromSubstring(info, string, start,
        scanOffset + extraOffset, tokenStart, canonicalize: true);
    tail = tail.next;
  }

  bool atEndOfFile() => scanOffset >= string.length - 1;
}
