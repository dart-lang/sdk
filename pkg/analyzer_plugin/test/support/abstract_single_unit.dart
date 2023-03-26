// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';

import 'abstract_context.dart';

class AbstractSingleUnitTest extends AbstractContextTest {
  bool verifyNoTestUnitErrors = true;

  late String testCode;
  late String testFile;
  late CompilationUnit testUnit;
  late FindNode findNode;
  late FindElement findElement;

  void addTestSource(String code) {
    testCode = code;
    addSource(testFile, code);
  }

  int findEnd(String search) {
    return findOffset(search) + search.length;
  }

  /// Returns the [SimpleIdentifier] at the given search pattern.
  SimpleIdentifier findIdentifier(String search) {
    return findNodeAtString(search, (node) => node is SimpleIdentifier)
        as SimpleIdentifier;
  }

  AstNode? findNodeAtOffset(
    int offset, [
    bool Function(AstNode)? predicate,
  ]) {
    var result = NodeLocator(offset).searchWithin(testUnit);
    if (result != null && predicate != null) {
      result = result.thisOrAncestorMatching(predicate);
    }
    return result;
  }

  AstNode? findNodeAtString(
    String search, [
    bool Function(AstNode)? predicate,
  ]) {
    var offset = findOffset(search);
    return findNodeAtOffset(offset, predicate);
  }

  Element? findNodeElementAtString(
    String search, [
    bool Function(AstNode)? predicate,
  ]) {
    var node = findNodeAtString(search, predicate);
    if (node == null) {
      return null;
    }
    return ElementLocator.locate(node);
  }

  int findOffset(String search) {
    var offset = testCode.indexOf(search);
    expect(offset, isNonNegative, reason: "Not found '$search' in\n$testCode");
    return offset;
  }

  int getLeadingIdentifierLength(String search) {
    var length = 0;
    while (length < search.length) {
      var c = search.codeUnitAt(length);
      if (c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
        length++;
        continue;
      }
      break;
    }
    return length;
  }

  Future<void> resolveTestCode(String code) async {
    addTestSource(code);
    await resolveTestFile();
  }

  Future<void> resolveTestFile() async {
    var result = await resolveFile(testFile);
    testCode = result.content;
    testUnit = result.unit;
    if (verifyNoTestUnitErrors) {
      expect(result.errors.where((AnalysisError error) {
        return error.errorCode != WarningCode.DEAD_CODE &&
            error.errorCode != WarningCode.UNUSED_CATCH_CLAUSE &&
            error.errorCode != WarningCode.UNUSED_CATCH_STACK &&
            error.errorCode != HintCode.UNUSED_ELEMENT &&
            error.errorCode != HintCode.UNUSED_FIELD &&
            error.errorCode != HintCode.UNUSED_IMPORT &&
            error.errorCode != HintCode.UNUSED_LOCAL_VARIABLE;
      }), isEmpty);
    }
    findNode = FindNode(testCode, testUnit);
    findElement = FindElement(testUnit);
  }

  @override
  void setUp() {
    super.setUp();
    testFile = convertPath('$testPackageRootPath/test.dart');
  }
}
