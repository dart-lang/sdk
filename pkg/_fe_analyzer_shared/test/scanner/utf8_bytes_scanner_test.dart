// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart';
import 'package:test/test.dart';

class CountingUtf8BytesScanner extends Utf8BytesScanner {
  int advanceCount = 0;
  new(super.bytes);

  @override
  int advance() {
    advanceCount++;
    return super.advance();
  }
}

void main() {
  test('scanUntilLineEnd at EOF for ASCII comment', () {
    // Issue found and test created by AI.
    Uint8List bytes = utf8.encode('// hello');
    Utf8BytesScanner scanner = Utf8BytesScanner(bytes);
    scanner.advance(); // '/'
    scanner.advance(); // '/'
    // $EOF (-1) should not make it look like non-ascii.
    expect(scanner.scanUntilLineEnd(), isTrue);
  });

  test('passIdentifierCharAllowDollar does not re-scan on loop exit', () {
    // Issue found and test created by AI.
    // 11 identifier chars + trailing spaces
    Uint8List bytes = utf8.encode('abcdefghijk ');
    CountingUtf8BytesScanner scanner = CountingUtf8BytesScanner(bytes);
    scanner.advance(); // reads 'a'
    int next = scanner.passIdentifierCharAllowDollar();
    expect(next, 0x20);
    expect(scanner.byteOffset, 11);
    // 1 initial advance() + 1 advance() for the trailing space.
    expect(scanner.advanceCount, 2);
  });

  test(r'current() before advance() returns $EOF', () {
    // While we don't expect current() to ever be called before advance()
    // it shouldn't crash. We return $EOF.
    Uint8List bytes = utf8.encode('hello');
    Utf8BytesScanner utf8Scanner = Utf8BytesScanner(bytes);
    expect(utf8Scanner.current(), $EOF);
  });

  test('initial stringOffset is -1', () {
    // While asking for the string offset before doing anything doesn't make
    // a whole lot of sense -1 makes more sense than other answers.
    Uint8List bytes = utf8.encode('hello');
    Utf8BytesScanner scanner = Utf8BytesScanner(bytes);
    expect(scanner.stringOffset, -1);
  });

  test(r'current() and stringOffset on empty input', () {
    Utf8BytesScanner utf8Scanner = Utf8BytesScanner(Uint8List(0));
    expect(utf8Scanner.current(), $EOF);
    expect(utf8Scanner.stringOffset, -1);
    utf8Scanner.advance();
    expect(utf8Scanner.current(), $EOF);
    expect(utf8Scanner.stringOffset, 0);
  });
}
