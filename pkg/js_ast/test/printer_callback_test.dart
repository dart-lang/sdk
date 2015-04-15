// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that JS printer callbacks occur when expected.

library js_ast.printer.callback_test;

import 'package:js_ast/js_ast.dart';
import 'package:unittest/unittest.dart';

enum TestMode {
  NONE,
  ENTER,
  DELIMITER,
  EXIT,
}

const DATA = const [
  const {
    TestMode.NONE: """
function(a, b) {
  return null;
}""",
    TestMode.ENTER: """
@0function(@1a, @2b) @3{
  @4return @5null;
}""",
    TestMode.DELIMITER: """
function(a, b) {
  return null;
@0}""",
   TestMode.EXIT: """
function(a@1, b@2) {
  return null@5;
@4}@3@0"""
  },

  const {
    TestMode.NONE: """
function() {
  if (true) {
    foo1();
    foo2();
  } else {
    bar1();
    bar2();
  }
  while (false) {
    baz3();
    baz4();
  }
}""",
    TestMode.ENTER: """
@0function() @1{
  @2if (@3true) @4{
    @5@6@7foo1();
    @8@9@10foo2();
  } else @11{
    @12@13@14bar1();
    @15@16@17bar2();
  }
  @18while (@19false) @20{
    @21@22@23baz3();
    @24@25@26baz4();
  }
}""",
    TestMode.DELIMITER: """
function() {
  if (true) {
    foo1();
    foo2();
  } else {
    bar1();
    bar2();
  }
  while (false) {
    baz3();
    baz4();
  }
@0}""",
    TestMode.EXIT: """
function() {
  if (true@3) {
    foo1@7()@6;
@5    foo2@10()@9;
@8  }@4 else {
    bar1@14()@13;
@12    bar2@17()@16;
@15  }@11
@2  while (false@19) {
    baz3@23()@22;
@21    baz4@26()@25;
@24  }@20
@18}@1@0""",
  },
];

void check(Map<TestMode, String> map) {
  String code = map[TestMode.NONE];
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions();
  Node node = js.parseForeignJS(code).instantiate({});
  map.forEach((TestMode mode, String expectedOutput) {
    Context context = new Context(mode);
    new Printer(options, context).visit(node);
    expect(context.getText(), equals(expectedOutput),
        reason: "Unexpected output for $code in $mode");
  });
}

class Context extends SimpleJavaScriptPrintingContext {
  final TestMode mode;
  final Map<Node, int> idMap = {};
  final Map<int, List<String>> tagMap = {};

  Context(this.mode);

  int id(Node node) => idMap.putIfAbsent(node, () => idMap.length);

  String tag(int value) => '@$value';

  void enterNode(Node node, int startPosition) {
    int value = id(node);
    if (mode == TestMode.ENTER) {
      tagMap.putIfAbsent(startPosition, () => []).add(tag(value));
    }
  }

  void exitNode(Node node,
                int startPosition,
                int endPosition,
                int delimiterPosition) {
    int value = id(node);
    if (mode == TestMode.DELIMITER && delimiterPosition != null) {
      tagMap.putIfAbsent(delimiterPosition, () => []).add(tag(value));
    } else if (mode == TestMode.EXIT) {
      tagMap.putIfAbsent(endPosition, () => []).add(tag(value));
    }
  }

  String getText() {
    String text = super.getText();
    int offset = 0;
    StringBuffer sb = new StringBuffer();
    for (int position in tagMap.keys.toList()..sort()) {
      if (offset < position) {
        sb.write(text.substring(offset, position));
      }
      tagMap[position].forEach((String tag) => sb.write(tag));
      offset = position;
    }
    if (offset < text.length) {
      sb.write(text.substring(offset));
    }
    return sb.toString();
  }
}

void main() {
  DATA.forEach(check);
}
