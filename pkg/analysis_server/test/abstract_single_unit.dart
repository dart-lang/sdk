// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:test/test.dart';

import 'abstract_context.dart';

class AbstractSingleUnitTest extends AbstractContextTest {
  bool verifyNoTestUnitErrors = true;

  /// Whether to rewrite line endings in test code based on platform.
  bool useLineEndingsForPlatform = false;

  String testCode;
  String testFile;
  ResolvedUnitResult testAnalysisResult;
  CompilationUnit testUnit;
  CompilationUnitElement testUnitElement;
  LibraryElement testLibraryElement;
  FindNode findNode;

  @override
  void addSource(String path, String content) {
    if (useLineEndingsForPlatform) {
      content = normalizeNewlinesForPlatform(content);
    }
    super.addSource(path, content);
  }

  void addTestSource(String code) {
    if (useLineEndingsForPlatform) {
      code = normalizeNewlinesForPlatform(code);
    }
    testCode = code;
    addSource(testFile, code);
  }

  Element findElement(String name, [ElementKind kind]) {
    return findChildElement(testUnitElement, name, kind);
  }

  int findEnd(String search) {
    return findOffset(search) + search.length;
  }

  /// Returns the [SimpleIdentifier] at the given search pattern.
  SimpleIdentifier findIdentifier(String search) {
    return findNodeAtString(search, (node) => node is SimpleIdentifier);
  }

  /// Search the [testUnit] for the [LocalVariableElement] with the given
  /// [name]. Fail if there is not exactly one such variable.
  LocalVariableElement findLocalVariable(String name) {
    var finder = _ElementsByNameFinder(name);
    testUnit.accept(finder);
    var localVariables = finder.elements.whereType<LocalVariableElement>();
    expect(localVariables, hasLength(1));
    return localVariables.single;
  }

  AstNode findNodeAtOffset(int offset, [Predicate<AstNode> predicate]) {
    var result = NodeLocator(offset).searchWithin(testUnit);
    if (result != null && predicate != null) {
      result = result.thisOrAncestorMatching(predicate);
    }
    return result;
  }

  AstNode findNodeAtString(String search, [Predicate<AstNode> predicate]) {
    var offset = findOffset(search);
    return findNodeAtOffset(offset, predicate);
  }

  Element findNodeElementAtString(String search,
      [Predicate<AstNode> predicate]) {
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

  @override
  File newFile(String path, {String content = ''}) {
    if (useLineEndingsForPlatform) {
      content = normalizeNewlinesForPlatform(content);
    }
    return super.newFile(path, content: content);
  }

  Future<void> resolveTestCode(String code) async {
    addTestSource(code);
    await resolveTestFile();
  }

  Future<void> resolveTestFile() async {
    testAnalysisResult = await session.getResolvedUnit(testFile);
    testUnit = testAnalysisResult.unit;
    if (verifyNoTestUnitErrors) {
      expect(testAnalysisResult.errors.where((AnalysisError error) {
        return error.errorCode != HintCode.DEAD_CODE &&
            error.errorCode != HintCode.UNUSED_CATCH_CLAUSE &&
            error.errorCode != HintCode.UNUSED_CATCH_STACK &&
            error.errorCode != HintCode.UNUSED_ELEMENT &&
            error.errorCode != HintCode.UNUSED_FIELD &&
            error.errorCode != HintCode.UNUSED_IMPORT &&
            error.errorCode != HintCode.UNUSED_LOCAL_VARIABLE;
      }), isEmpty);
    }
    testUnitElement = testUnit.declaredElement;
    testLibraryElement = testUnitElement.library;
    findNode = FindNode(testCode, testUnit);
  }

  @override
  void setUp() {
    super.setUp();
    testFile = convertPath('/home/test/lib/test.dart');
  }
}

class _ElementsByNameFinder extends RecursiveAstVisitor<void> {
  final String name;
  final List<Element> elements = [];

  _ElementsByNameFinder(this.name);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name && node.inDeclarationContext()) {
      elements.add(node.staticElement);
    }
  }
}
