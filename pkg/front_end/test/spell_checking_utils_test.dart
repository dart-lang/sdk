// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'spell_checking_utils.dart';

void main() {
  expectSplit("Hello world", false, ["Hello", "world"], [0, 6]);
  expectSplit("Hello  world", false, ["Hello", "world"], [0, 7]);
  expectSplit("Hello\nworld", false, ["Hello", "world"], [0, 6]);
  expectSplit("Hello 'world'", false, ["Hello", "world"], [0, 7]);
  expectSplit("It's fun", false, ["It's", "fun"], [0, 5]);
  expectSplit("It's 'fun'", false, ["It's", "fun"], [0, 6]);
  expectSplit("exit-code", false, ["exit", "code"], [0, 5]);
  expectSplit("fatal=warning", false, ["fatal", "warning"], [0, 6]);
  expectSplit("vm|none", false, ["vm", "none"], [0, 3]);
  expectSplit("vm/none", false, ["vm", "none"], [0, 3]);
  expectSplit("vm,none", false, ["vm", "none"], [0, 3]);
  expectSplit("One or more word(s)", false, ["One", "or", "more", "word(s)"],
      [0, 4, 7, 12]);
  expectSplit("One or more words)", false, ["One", "or", "more", "words"],
      [0, 4, 7, 12]);
  expectSplit(
      "It's 'fun' times 100", false, ["It's", "fun", "times"], [0, 6, 11]);

  expectSplit("splitCamelCase", false, ["splitCamelCase"], [0]);
  expectSplit("splitCamelCase", true, ["split", "Camel", "Case"], [0, 5, 10]);
  expectSplit("logicalAnd_end", true, ["logical", "And", "end"], [0, 7, 11]);
  expectSplit("TheCNNAlso", true, ["The", "CNN", "Also"], [0, 3, 6]);
  expectSplit("LOGICAL_OR_PRECEDENCE", true, ["LOGICAL", "OR", "PRECEDENCE"],
      [0, 8, 11]);

  expectSplit("ThisIsTheCNN", true, ["This", "Is", "The", "CNN"], [0, 4, 6, 9]);

  // Special-case "A".
  expectSplit("notAConstant", true, ["not", "A", "Constant"], [0, 3, 4]);
  expectSplit("notAC", true, ["not", "A", "C"], [0, 3, 4]);
  expectSplit("split_etc", false, ["split_etc"], [0]);
  expectSplit("split_etc", true, ["split", "etc"], [0, 6]);
  expectSplit("split:etc", false, ["split:etc"], [0]);
  expectSplit("split:etc", true, ["split", "etc"], [0, 6]);

  expectSplit("vm.none", false, ["vm.none"], [0]);
  expectSplit("vm.none", true, ["vm", "none"], [0, 3]);

  expectSplit(
      "ActualData(foo, bar)", false, ["ActualData(foo", "bar"], [0, 16]);
  expectSplit("ActualData(foo, bar)", true, ["Actual", "Data", "foo", "bar"],
      [0, 6, 11, 16]);

  expectSplit("List<int>", false, ["List<int"], [0]);
  expectSplit("List<int>", true, ["List", "int"], [0, 5]);

  expectSplit("Platform.environment['TERM']", false,
      ["Platform.environment['TERM"], [0]);
  expectSplit("Platform.environment['TERM']", true,
      ["Platform", "environment", "TERM"], [0, 9, 22]);

  expectSplit("DART2JS_PLATFORM", false, ["DART2JS_PLATFORM"], [0]);
  expectSplit("DART2JS_PLATFORM", true, ["DART2JS", "PLATFORM"], [0, 8]);

  expectSplit("Foo\\n", false, ["Foo\\n"], [0]);
  expectSplit("Foo\\n", true, ["Foo"], [0]);

  expectSplit("foo({bar})", false, ["foo({bar"], [0]);
  expectSplit("foo({bar})", true, ["foo", "bar"], [0, 5]);

  expectSplit("foo@bar", false, ["foo@bar"], [0]);
  expectSplit("foo@bar", true, ["foo", "bar"], [0, 4]);

  expectSplit("foo#bar", false, ["foo#bar"], [0]);
  expectSplit("foo#bar", true, ["foo", "bar"], [0, 4]);

  expectSplit("foo&bar", false, ["foo&bar"], [0]);
  expectSplit("foo&bar", true, ["foo", "bar"], [0, 4]);

  expectSplit("foo?bar", false, ["foo?bar"], [0]);
  expectSplit("foo?bar", true, ["foo", "bar"], [0, 4]);

  expectSplit("foo%bar", false, ["foo%bar"], [0]);
  expectSplit("foo%bar", true, ["foo", "bar"], [0, 4]);

  expectAlternative(
      "explicitley", ["explicitly"], {"foo", "explicitly", "bar"});
  expectAlternative("explicitlqqqqy", null, {"foo", "explicitly", "bar"});

  print("OK");
}

void expectSplit(String s, bool splitAsCode, List<String> expectedWords,
    List<int> expectedOffsets) {
  List<int> actualOffsets = <int>[];
  List<String> actualWords =
      splitStringIntoWords(s, actualOffsets, splitAsCode: splitAsCode);
  compareLists(actualWords, expectedWords);
  compareLists(actualOffsets, expectedOffsets);
}

void compareLists(List<dynamic> actual, List<dynamic> expected) {
  if (actual == null && expected == null) return;
  if (actual == null) throw "Got null, expected $expected";
  if (expected == null) throw "Expected null, got $actual";
  if (actual.length != expected.length) {
    throw "Not the same ($actual vs $expected)";
  }
  for (int i = 0; i < actual.length; i++) {
    if (actual[i] != expected[i]) {
      throw "Not the same ($actual vs $expected)";
    }
  }
}

void expectAlternative(
    String word, List<String> expected, Set<String> dictionary) {
  List<String> alternatives = findAlternatives(word, [dictionary]);
  compareLists(alternatives, expected);
}
