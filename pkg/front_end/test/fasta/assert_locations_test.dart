// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.assert_locations_test;

import 'package:async_helper/async_helper.dart' show asyncTest;

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/ast.dart'
    show Component, RecursiveVisitor, Procedure, AssertStatement;

import "package:front_end/src/api_prototype/compiler_options.dart"
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/testing/compiler_common.dart' show compileScript;

/// Span of the condition expression in the assert statement.
class ConditionSpan {
  final startOffset;
  final endOffset;
  ConditionSpan(this.startOffset, this.endOffset);
}

/// Generated test with multiple functions each containing a single
/// assertion statement inside. [spans] specifies the mapping
/// between function name and [ConditionSpan] for an [AssertionStatement]
/// inside that function.
class Test {
  final String source;
  final Map<String, ConditionSpan> spans;

  Test(this.source, this.spans);
}

Test generateTest() {
  final sb = new StringBuffer();
  final spans = new Map<String, ConditionSpan>();

  // Create a test case for assert statement with the given [condition] and
  // [message]. Argument list would contain a trailing comma if [trailingComma]
  // is [true].
  // [additionalOffset] specifies an offset in characters from the opening
  // parenthesis of the assert statement to the first character of the
  // condition.
  void makeAssertWithMessage(String condition,
      {String message, bool trailingComma: false, int additionalOffset: 0}) {
    final name = 'testCase${spans.length}';
    sb.writeln('void $name(x) {');
    sb.write('assert(');
    final startOffset = sb.length + additionalOffset;
    sb.write(condition);
    final endOffset = sb.length;
    if (message != null) {
      sb.write(', "${message}"');
    }
    if (trailingComma) {
      sb.write(',');
    }
    sb.writeln(');');
    sb.writeln('}');
    spans[name] = new ConditionSpan(startOffset, endOffset);
  }

  // Create test cases for various variants of the assert statement with
  // the given condition.
  void makeAssert(String condition, {int additionalOffset: 0}) {
    makeAssertWithMessage(condition, additionalOffset: additionalOffset);
    makeAssertWithMessage(condition,
        trailingComma: true, additionalOffset: additionalOffset);
    makeAssertWithMessage(condition,
        message: 'message message', additionalOffset: additionalOffset);
    makeAssertWithMessage(condition,
        message: 'message message',
        trailingComma: true,
        additionalOffset: additionalOffset);
  }

  // Create all test cases.
  makeAssert('''

  (
    x != null
  )''', additionalOffset: 3);
  makeAssert('''(x != null)''');
  makeAssert('''x''');
  makeAssert('''((x))''');
  makeAssert('''!x''');
  makeAssert('''((!x))''');
  makeAssert('''x.method("a", "b")''');

  // Add a dummy main to avoid compilation errors.
  sb.writeln('''
void main() {}
''');

  return new Test(sb.toString(), spans);
}

/// Visitor that verifies that all [AssertStatement]s in the Kernel AST
/// have expected spans for their conditions.
class VerifyingVisitor extends RecursiveVisitor<Null> {
  final Test test;

  /// Set of names of verified [Procedure]s.
  final Set<String> verified = new Set<String>();

  /// When [AssertStatement] is reached it is checked against this
  /// span.
  ConditionSpan expectedSpan;

  VerifyingVisitor(this.test);

  @override
  visitProcedure(Procedure node) {
    expectedSpan = test.spans[node.name.text];
    if (expectedSpan != null) {
      super.visitProcedure(node);
      verified.add(node.name.text);
      expectedSpan = null;
    }
  }

  @override
  visitAssertStatement(AssertStatement node) {
    Expect.equals(expectedSpan.startOffset, node.conditionStartOffset);
    Expect.equals(expectedSpan.endOffset, node.conditionEndOffset);
  }
}

void main() {
  asyncTest(() async {
    Test test = generateTest();
    CompilerOptions options = new CompilerOptions()
      ..onDiagnostic = (DiagnosticMessage message) {
        Expect.fail(
            "Unexpected message: ${message.plainTextFormatted.join('\n')}");
      };
    Component p = (await compileScript(test.source,
            options: options, fileName: 'synthetic-test.dart'))
        ?.component;
    Expect.isNotNull(p);
    VerifyingVisitor visitor = new VerifyingVisitor(test);
    p.mainMethod.enclosingLibrary.accept(visitor);
    Expect.setEquals(test.spans.keys, visitor.verified);
  });
}
