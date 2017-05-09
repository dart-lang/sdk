// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';

import 'abstract_context.dart';

class AbstractSingleUnitTest extends AbstractContextTest {
  bool verifyNoTestUnitErrors = true;

  String testCode;
  String testFile;
  Source testSource;
  CompilationUnit testUnit;
  CompilationUnitElement testUnitElement;
  LibraryElement testLibraryElement;

  void addTestSource(String code, [Uri uri]) {
    testCode = code;
    testSource = addSource(testFile, code, uri);
  }

  Element findElement(String name, [ElementKind kind]) {
    return findChildElement(testUnitElement, name, kind);
  }

  int findEnd(String search) {
    return findOffset(search) + search.length;
  }

  /**
   * Returns the [SimpleIdentifier] at the given search pattern.
   */
  SimpleIdentifier findIdentifier(String search) {
    return findNodeAtString(search, (node) => node is SimpleIdentifier);
  }

  AstNode findNodeAtOffset(int offset, [Predicate<AstNode> predicate]) {
    AstNode result = new NodeLocator(offset).searchWithin(testUnit);
    if (result != null && predicate != null) {
      result = result.getAncestor(predicate);
    }
    return result;
  }

  AstNode findNodeAtString(String search, [Predicate<AstNode> predicate]) {
    int offset = findOffset(search);
    return findNodeAtOffset(offset, predicate);
  }

  Element findNodeElementAtString(String search,
      [Predicate<AstNode> predicate]) {
    AstNode node = findNodeAtString(search, predicate);
    if (node == null) {
      return null;
    }
    return ElementLocator.locate(node);
  }

  int findOffset(String search) {
    int offset = testCode.indexOf(search);
    expect(offset, isNonNegative, reason: "Not found '$search' in\n$testCode");
    return offset;
  }

  int getLeadingIdentifierLength(String search) {
    int length = 0;
    while (length < search.length) {
      int c = search.codeUnitAt(length);
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

  Future<Null> resolveTestUnit(String code) async {
    addTestSource(code);
    var result = await driver.getResult(testFile);
    testUnit = (result).unit;
    if (verifyNoTestUnitErrors) {
      expect(result.errors.where((AnalysisError error) {
        return error.errorCode != HintCode.DEAD_CODE &&
            error.errorCode != HintCode.UNUSED_CATCH_CLAUSE &&
            error.errorCode != HintCode.UNUSED_CATCH_STACK &&
            error.errorCode != HintCode.UNUSED_ELEMENT &&
            error.errorCode != HintCode.UNUSED_FIELD &&
            error.errorCode != HintCode.UNUSED_IMPORT &&
            error.errorCode != HintCode.UNUSED_LOCAL_VARIABLE;
      }), isEmpty);
    }
    testUnitElement = testUnit.element;
    testLibraryElement = testUnitElement.library;
  }

  @override
  void setUp() {
    super.setUp();
    testFile = provider.convertPath('/test.dart');
  }
}
