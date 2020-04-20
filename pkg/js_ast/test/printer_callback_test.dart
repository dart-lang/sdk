// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: This test relies on LF line endings in the source file.

// Test that JS printer callbacks occur when expected.

library js_ast.printer.callback_test;

import 'package:js_ast/js_ast.dart';
import 'package:test/test.dart';

enum TestMode {
  INPUT,
  NONE,
  ENTER,
  DELIMITER,
  EXIT,
}

class TestCase {
  final Map<TestMode, String> data;

  /// Map from template names to the inserted values.
  final Map<String, String> environment;

  const TestCase(this.data, [this.environment = const {}]);
}

const List<TestCase> DATA = const <TestCase>[
  const TestCase(const {
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
  return null@4;
@0}""",
    TestMode.EXIT: """
function(a@1, b@2) {
  return null@5;
@4}@3@0"""
  }),
  const TestCase(const {
    TestMode.NONE: """
function() {
  if (true) {
    foo1();
    foo2();
  } else if (false) {
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
  } else @11if (@12false) @13{
    @14@15@16bar1();
    @17@18@19bar2();
  }
  @20while (@21false) @22{
    @23@24@25baz3();
    @26@27@28baz4();
  }
}""",
    TestMode.DELIMITER: """
function() {
  if (true) {
    foo1();
    foo2();
  } else if (false) {
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
@8  }@4 else if (false@12) {
    bar1@16()@15;
@14    bar2@19()@18;
@17  }@13
@11@2  while (false@21) {
    baz3@25()@24;
@23    baz4@28()@27;
@26  }@22
@20}@1@0""",
  }),
  const TestCase(const {
    TestMode.NONE: """
function() {
  function foo() {
  }
}""",
    TestMode.ENTER: """
@0function() @1{
  @2@3function @4foo() @5{
  }
}""",
    TestMode.DELIMITER: """
function() {
  function foo() {
  @3}
@0}""",
    TestMode.EXIT: """
function() {
  function foo@4() {
  }@5@3
@2}@1@0"""
  }),
  const TestCase(const {
    TestMode.INPUT: """
function() {
  a['b'];
  [1,, 2];
}""",
    TestMode.NONE: """
function() {
  a.b;
  [1,, 2];
}""",
    TestMode.ENTER: """
@0function() @1{
  @2@3@4a.@5b;
  @6@7[@81,@9, @102];
}""",
    TestMode.DELIMITER: """
function() {
  a.b;
  [1,, 2];
@0}""",
    TestMode.EXIT: """
function() {
  a@4.b@5@3;
@2  [1@8,,@9 2@10]@7;
@6}@1@0""",
  }),
  const TestCase(const {
    TestMode.INPUT: "a.#nameTemplate = #nameTemplate",
    TestMode.NONE: "a.nameValue = nameValue",
    TestMode.ENTER: "@0@1@2a.@3nameValue = @3nameValue",
    TestMode.DELIMITER: "a.nameValue = nameValue",
    TestMode.EXIT: "a@2.nameValue@3@1 = nameValue@3@0",
  }, const {
    'nameTemplate': 'nameValue'
  }),
];

class FixedName extends Name {
  final String name;
  String get key => name;

  FixedName(this.name);

  @override
  int compareTo(other) => 0;
}

void check(TestCase testCase) {
  Map<TestMode, String> map = testCase.data;
  String code = map[TestMode.INPUT];
  if (code == null) {
    // Input is the same as output.
    code = map[TestMode.NONE];
  }
  JavaScriptPrintingOptions options = new JavaScriptPrintingOptions();
  Map arguments = {};
  testCase.environment.forEach((String name, String value) {
    arguments[name] = new FixedName(value);
  });
  Node node = js.parseForeignJS(code).instantiate(arguments);
  map.forEach((TestMode mode, String expectedOutput) {
    if (mode == TestMode.INPUT) return;
    Context context = new Context(mode);
    new Printer(options, context).visit(node);
    // TODO(johnniwinther): Remove `replaceAll(...)` when dart2js behaves as the
    // VM on newline in multiline strings.
    expect(context.getText(), equals(expectedOutput.replaceAll('\r\n', '\n')),
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

  void exitNode(
      Node node, int startPosition, int endPosition, int delimiterPosition) {
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
  test('printer callback test', () {
    DATA.forEach(check);
  });
}
