// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:test/test.dart';

main() {
  setUp(() {
    clearStringCanonicalizationCache();
  });

  /// Returns a new instance of a string equal to [value].
  String fresh(String value) => String.fromCharCodes(value.codeUnits);

  /// Canonicalizes new instances of [value] [count] times, and returns the
  /// canonical instance.
  String use(String value, int count) {
    String result = canonicalizeString(fresh(value));
    for (int i = 1; i < count; i++) {
      expect(canonicalizeString(fresh(value)), same(result));
    }
    return result;
  }

  /// Returns whether [canonical] is still the canonical instance.
  bool isCached(String canonical) {
    return identical(canonicalizeString(fresh(canonical)), canonical);
  }

  test('prune within limit does nothing', () {
    String once = use('once', 1);
    pruneStringCanonicalizationCache(1024);
    expect(isCached(once), isTrue);
  });

  test('prune keeps repeatedly used strings', () {
    String repeated = use('repeated', 3);
    List<String> once = [for (int i = 0; i < 100; i++) use('once$i', 1)];

    pruneStringCanonicalizationCache(1024);
    expect(isCached(repeated), isTrue);
    for (String value in once) {
      expect(isCached(value), isFalse);
    }
  });

  test('prune repeats until within half of limit', () {
    // Each string is estimated as 48 + 200 bytes.
    String less = use('a' * 200, 3);
    String more = use('b' * 200, 9);
    use('c' * 200, 1);

    // The first pass keeps both [less] and [more], which is still more than
    // half of the limit, so the second pass removes [less].
    pruneStringCanonicalizationCache(600);
    expect(isCached(more), isTrue);
    expect(isCached(less), isFalse);
  });

  test('prune removes UTF-8 strings', () {
    String repeated = use('repeated', 2);
    var bytes = utf8.encode('bytes');
    String fromBytes = canonicalizeUtf8SubString(bytes, 0, bytes.length, true);
    expect(
      canonicalizeUtf8SubString(bytes, 0, bytes.length, true),
      same(fromBytes),
    );

    pruneStringCanonicalizationCache(1024);
    expect(isCached(repeated), isTrue);
    expect(
      canonicalizeUtf8SubString(bytes, 0, bytes.length, true),
      isNot(same(fromBytes)),
    );
  });
}
