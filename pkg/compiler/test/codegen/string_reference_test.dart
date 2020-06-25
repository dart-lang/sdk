// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

import 'package:compiler/src/constants/values.dart' show StringConstantValue;
import 'package:compiler/src/js_backend/string_reference.dart'
    show StringReference, StringReferenceResource, StringReferenceFinalizerImpl;

import 'package:compiler/src/js/js.dart' show prettyPrint;

void test(List<String> strings, String expected, {bool minified: false}) {
  var finalizer =
      StringReferenceFinalizerImpl(minified, shortestSharedLength: 5);

  for (var string in strings) {
    finalizer.addCode(StringReference(StringConstantValue(string)));
  }

  StringReferenceResource resource = StringReferenceResource();
  finalizer.registerStringReferenceResource(resource);
  finalizer.finalize();

  Expect.equals(expected.trim(), prettyPrint(resource).trim());
}

extension on List<String> {
  // TODO(42122): Remove when analyzer doesn't think `*` is unused.
  // ignore: unused_element
  List<String> operator *(int count) {
    return List.filled(count, this).expand((list) => list).toList();
  }
}

void main() {
  // No strings yields an empty pool.
  test([], '0');

  // Single occurrence strings are not pooled.
  test(
    ['Yellow', 'Blue', 'Crimson'],
    '0',
  );

  // Repeated strings that are long enough are pooled.
  test(
    ['Yellow', 'Blue', 'Blue', 'Crimson', 'Crimson'],
    r'''
var string$ = {
  Crimso: "Crimson"
}''',
  );

  // Readable property names have identical stretches compressed-out.
  var greets = [
    'Greetings Bob Smith',
    'Great work!',
    'Greetings Alice',
    'Greetings Bob Henry'
  ];

  test(
    greets * 2,
    r'''
var string$ = {
  Great_: "Great work!",
  GreetiA: "Greetings Alice",
  GreetiBH: "Greetings Bob Henry",
  GreetiBS: "Greetings Bob Smith"
}''',
  );

  // Non-identifiers are replaced with '_' if that is unambiguous.
  test(
    ['xylograph', '!pingpong'] * 2,
    r'''
var string$ = {
  _pingp: "!pingpong",
  xylogr: "xylograph"
}''',
  );

  final strings1 = [
    ...['a xylograph'] * 2,
    ...['a !pingpong'] * 4,
    ...['a %percent'] * 6,
  ];

  // Multiple discriminating non-identifier characters are replaced with an
  // escape, which causes a potentially ambiguous non-escape to be escaped.
  test(
    strings1,
    r'''
var string$ = {
  a_x21pin: "a !pingpong",
  a_x25per: "a %percent",
  a_x78ylo: "a xylograph"
}''',
  );

  // Minified version keeps the strings in the same order as unminified, and
  // tries to allocate the same minified name.
  const minified1 = r'''
var string$ = {
  l: "a !pingpong",
  o: "a %percent",
  n: "a xylograph"
}''';

  final strings2 = [
    ...['a xylograph'] * 20, // now most frequent.
    ...strings1
  ];
  test(strings1, minified1, minified: true);
  test(strings2, minified1, minified: true);
}
