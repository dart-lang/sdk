// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';

import 'package:front_end/src/fasta/kernel/internal_ast.dart';

void runTests() {
  checkExpected(
      makeSimpleComponentWithPatternVariableDeclaration(
          new PatternVariableDeclaration(
              new ListBinder(const DynamicType(),
                  [new WildcardBinder(null, offset: TreeNode.noOffset)],
                  offset: TreeNode.noOffset),
              new IntLiteral(0),
              offset: TreeNode.noOffset)),
      makeExpectationOfSimpleComponentWithPatternVariableDeclaration(
          "PatternVariableDeclaration"));
}

Component makeSimpleComponentWithPatternVariableDeclaration(
    PatternVariableDeclaration patternVariableDeclaration) {
  Uri fileUri = Uri.parse("test:///test.dart");
  Uri importUri = Uri.parse("test.dart");

  Block body = new Block([patternVariableDeclaration]);
  FunctionNode functionNode = new FunctionNode(body);
  Procedure procedure = new Procedure(
      new Name("test"), ProcedureKind.Method, functionNode,
      fileUri: fileUri);
  Library library =
      new Library(importUri, procedures: [procedure], fileUri: fileUri);
  Component component = new Component(libraries: [library]);
  return component;
}

String makeExpectationOfSimpleComponentWithPatternVariableDeclaration(
    String patternVariableDeclarationExpectation) {
  return """
main = <No Member>;
library from "test.dart" as test {

  method test() → dynamic {
    ${patternVariableDeclarationExpectation}
  }
}
""";
}

void checkExpected(Component component, String expected) {
  String actual = componentToString(component);
  if (actual != expected) {
    // This is a very primitive substitute for the diff output of the actual
    // expectation tests.
    List<String> actualLines = actual.split("\n");
    List<String> expectedLines = expected.split("\n");
    StringBuffer output = new StringBuffer();
    if (actualLines.length < expectedLines.length) {
      output.writeln("Actual output is shorter than the expected.");
    } else if (actualLines.length > expectedLines.length) {
      output.writeln("Actual output is longer than the expected.");
    }
    int minLines = actualLines.length < expectedLines.length
        ? actualLines.length
        : expectedLines.length;
    for (int i = 0; i < minLines; i++) {
      // Include one line of the difference.
      if (actualLines[i] != expectedLines[i]) {
        output.writeln(
            "Line $i is different in the actual output and the expected.\n"
            "Actual  : ${actualLines[i]}\n"
            "Expected: ${expectedLines[i]}");
        break;
      }
    }
    output.writeln("Full actual output:\n${'=' * 72}\n${actual}\n${'=' * 72}");
    output.writeln(
        "Full expected output:\n${'=' * 72}\n${expected}\n${'=' * 72}");
    throw new StateError("${output}");
  }
}

void main(List<String> args) {
  runTests();
}
