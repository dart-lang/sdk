// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'spell_checking_utils.dart';

void main() {
  _expectList(splitStringIntoWords("Hello world"), ["Hello", "world"]);
  _expectList(splitStringIntoWords("Hello\nworld"), ["Hello", "world"]);
  _expectList(splitStringIntoWords("Hello 'world'"), ["Hello", "world"]);
  _expectList(splitStringIntoWords("It's fun"), ["It's", "fun"]);
  _expectList(splitStringIntoWords("It's 'fun'"), ["It's", "fun"]);
  _expectList(splitStringIntoWords("exit-code"), ["exit", "code"]);
  _expectList(splitStringIntoWords("fatal=warning"), ["fatal", "warning"]);
  _expectList(splitStringIntoWords("vm|none"), ["vm", "none"]);
  _expectList(splitStringIntoWords("vm/none"), ["vm", "none"]);
  _expectList(splitStringIntoWords("vm,none"), ["vm", "none"]);
  _expectList(splitStringIntoWords("One or more word(s)"),
      ["One", "or", "more", "word(s)"]);
  _expectList(splitStringIntoWords("One or more words)"),
      ["One", "or", "more", "words"]);
  _expectList(
      splitStringIntoWords("It's 'fun' times 100"), ["It's", "fun", "times"]);

  _expectList(splitStringIntoWords("splitCamelCase", splitAsCode: false),
      ["splitCamelCase"]);
  _expectList(splitStringIntoWords("splitCamelCase", splitAsCode: true),
      ["split", "Camel", "Case"]);
  _expectList(splitStringIntoWords("logicalAnd_end", splitAsCode: true),
      ["logical", "And", "end"]);
  _expectList(splitStringIntoWords("TheCNNAlso", splitAsCode: true),
      ["The", "CNN", "Also"]);
  _expectList(splitStringIntoWords("LOGICAL_OR_PRECEDENCE", splitAsCode: true),
      ["LOGICAL", "OR", "PRECEDENCE"]);

  _expectList(splitStringIntoWords("ThisIsTheCNN", splitAsCode: true),
      ["This", "Is", "The", "CNN"]);

  // Special-case "A".
  _expectList(splitStringIntoWords("notAConstant", splitAsCode: true),
      ["not", "A", "Constant"]);
  _expectList(
      splitStringIntoWords("notAC", splitAsCode: true), ["not", "A", "C"]);
  _expectList(
      splitStringIntoWords("split_etc", splitAsCode: false), ["split_etc"]);
  _expectList(
      splitStringIntoWords("split_etc", splitAsCode: true), ["split", "etc"]);
  _expectList(
      splitStringIntoWords("split:etc", splitAsCode: false), ["split:etc"]);
  _expectList(
      splitStringIntoWords("split:etc", splitAsCode: true), ["split", "etc"]);

  _expectList(splitStringIntoWords("vm.none", splitAsCode: false), ["vm.none"]);
  _expectList(
      splitStringIntoWords("vm.none", splitAsCode: true), ["vm", "none"]);

  _expectList(splitStringIntoWords("ActualData(foo, bar)", splitAsCode: false),
      ["ActualData(foo", "bar"]);
  _expectList(splitStringIntoWords("ActualData(foo, bar)", splitAsCode: true),
      ["Actual", "Data", "foo", "bar"]);

  _expectList(
      splitStringIntoWords("List<int>", splitAsCode: false), ["List<int"]);
  _expectList(
      splitStringIntoWords("List<int>", splitAsCode: true), ["List", "int"]);

  _expectList(
      splitStringIntoWords("Platform.environment['TERM']", splitAsCode: false),
      ["Platform.environment['TERM"]);
  _expectList(
      splitStringIntoWords("Platform.environment['TERM']", splitAsCode: true),
      ["Platform", "environment", "TERM"]);

  _expectList(splitStringIntoWords("DART2JS_PLATFORM", splitAsCode: false),
      ["DART2JS_PLATFORM"]);
  _expectList(splitStringIntoWords("DART2JS_PLATFORM", splitAsCode: true),
      ["DART2JS", "PLATFORM"]);

  _expectList(splitStringIntoWords("Foo\\n", splitAsCode: false), ["Foo\\n"]);
  _expectList(splitStringIntoWords("Foo\\n", splitAsCode: true), ["Foo"]);

  _expectList(
      splitStringIntoWords("foo({bar})", splitAsCode: false), ["foo({bar"]);
  _expectList(
      splitStringIntoWords("foo({bar})", splitAsCode: true), ["foo", "bar"]);

  _expectList(splitStringIntoWords("foo@bar", splitAsCode: false), ["foo@bar"]);
  _expectList(
      splitStringIntoWords("foo@bar", splitAsCode: true), ["foo", "bar"]);

  _expectList(splitStringIntoWords("foo#bar", splitAsCode: false), ["foo#bar"]);
  _expectList(
      splitStringIntoWords("foo#bar", splitAsCode: true), ["foo", "bar"]);

  _expectList(splitStringIntoWords("foo&bar", splitAsCode: false), ["foo&bar"]);
  _expectList(
      splitStringIntoWords("foo&bar", splitAsCode: true), ["foo", "bar"]);

  _expectList(splitStringIntoWords("foo?bar", splitAsCode: false), ["foo?bar"]);
  _expectList(
      splitStringIntoWords("foo?bar", splitAsCode: true), ["foo", "bar"]);

  print("OK");
}

void _expectList(List<String> actual, List<String> expected) {
  if (actual.length != expected.length) {
    throw "Not the same ($actual vs $expected)";
  }
  for (int i = 0; i < actual.length; i++) {
    if (actual[i] != expected[i]) throw "Not the same ($actual vs $expected)";
  }
}
