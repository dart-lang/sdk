// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_unicode_tests;

import 'unicode_tests.dart';

const _quote = 0x22; // "
const _colon = 0x3a; // :
const _comma = 0x2c; // ,
const _braceOpen = 0x7b; // {
const _braceClose = 0x7d; // }
const _bracketOpen = 0x5b; // [
const _bracketClose = 0x5d; // ]

_expandUnicodeTests() {
  return UNICODE_TESTS.expand((test) {
    // The unicode test will be a string (possibly) containing unicode
    // characters. It also contains the empty string.
    // It must not contain a double-quote '"'.
    assert(!test.contains('"'));

    var bytes = test[0];
    var string = test[1];

    // expanded will hold all tests that are generated from the unicode test.
    var expanded = [];

    // Put the string into quotes.
    // For example: 'abcd' -> '"abcd"'.
    var inQuotesBytes = <int>[];
    inQuotesBytes.add(_quote);
    inQuotesBytes.addAll(bytes);
    inQuotesBytes.add(_quote);
    expanded.add([inQuotesBytes, string]);

    // Put the quoted string into a triple nested list.
    // For example: 'abcd' -> '[[["abcd"]]]'.
    var listExpected = [
      [
        [string]
      ]
    ];
    var inListBytes = <int>[];
    inListBytes.addAll([_bracketOpen, _bracketOpen, _bracketOpen]);
    inListBytes.addAll(inQuotesBytes);
    inListBytes.addAll([_bracketClose, _bracketClose, _bracketClose]);
    expanded.add([inListBytes, listExpected]);

    // Put the quoted string into a triple nested list and duplicate that
    // list three times.
    // For example: 'abcd' -> '[[[["abcd"]]],[[["abcd"]]],[[["abcd"]]]]'.
    var listLongerExpected = [listExpected, listExpected, listExpected];
    var listLongerBytes = <int>[];
    listLongerBytes.add(_bracketOpen);
    listLongerBytes.addAll(inListBytes);
    listLongerBytes.add(_comma);
    listLongerBytes.addAll(inListBytes);
    listLongerBytes.add(_comma);
    listLongerBytes.addAll(inListBytes);
    listLongerBytes.add(_bracketClose);
    expanded.add([listLongerBytes, listLongerExpected]);

    // Put the previous strings/lists into a map.
    // For example:
    //    'abcd' -> '{"abcd":[[[["abcd"]]],[[["abcd"]]],[[["abcd"]]]]}'.
    var mapExpected = new Map();
    mapExpected[string] = listLongerExpected;
    var mapBytes = <int>[];
    mapBytes.add(_braceOpen);
    mapBytes.addAll(inQuotesBytes);
    mapBytes.add(_colon);
    mapBytes.addAll(listLongerBytes);
    mapBytes.add(_braceClose);
    expanded.add([mapBytes, mapExpected]);

    return expanded;
  }).toList();
}

final JSON_UNICODE_TESTS = _expandUnicodeTests();
