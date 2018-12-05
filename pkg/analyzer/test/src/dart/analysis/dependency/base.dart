// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/dependency/library_builder.dart';
import 'package:analyzer/src/dart/analysis/dependency/node.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../resolution/driver_resolution.dart';

class BaseDependencyTest extends DriverResolutionTest {
//  DependencyTracker tracker;
  String a;
  String b;
  String c;
  Uri aUri;
  Uri bUri;
  Uri cUri;

  bool hasDartCore = false;

  void assertNodes(
    List<DependencyNode> actualNodes,
    List<ExpectedNode> expectedNodes,
  ) {
    expect(actualNodes, hasLength(expectedNodes.length));
    for (var expectedNode in expectedNodes) {
      var topNode = _getNode(
        actualNodes,
        uri: expectedNode.uri,
        name: expectedNode.name,
        kind: expectedNode.kind,
      );

      if (expectedNode.classMembers != null) {
        assertNodes(topNode.classMembers, expectedNode.classMembers);
      } else {
        expect(topNode.classMembers, isNull);
      }

      if (expectedNode.classTypeParameters != null) {
        assertNodes(
          topNode.classTypeParameters,
          expectedNode.classTypeParameters,
        );
      } else {
        expect(topNode.classTypeParameters, isNull);
      }
    }
  }

  Future<Library> buildTestLibrary(String path, String content) async {
//    if (!hasDartCore) {
//      hasDartCore = true;
//      await _addLibraryByUri('dart:core');
//      await _addLibraryByUri('dart:async');
//      await _addLibraryByUri('dart:math');
//      await _addLibraryByUri('dart:_internal');
//    }

    newFile(path, content: content);
    driver.changeFile(path);

    var units = await _resolveLibrary(path);
    var uri = units.first.declaredElement.source.uri;

    return buildLibrary(uri, units, _ReferenceCollector());

//    tracker.addLibrary(uri, units);
//
//    var library = tracker.libraries[uri];
//    expect(library, isNotNull);
//
//    return library;
  }

  DependencyNode getNode(Library library,
      {@required String name,
      DependencyNodeKind kind,
      String memberOf,
      String typeParameterOf}) {
    var uri = library.uri;
    var nodes = library.declaredNodes;
    if (memberOf != null) {
      var class_ = _getNode(nodes, uri: uri, name: memberOf);
      expect(
        class_.kind,
        anyOf(
          DependencyNodeKind.CLASS,
          DependencyNodeKind.ENUM,
          DependencyNodeKind.MIXIN,
        ),
      );
      nodes = class_.classMembers;
    } else if (typeParameterOf != null) {
      var class_ = _getNode(nodes, uri: uri, name: typeParameterOf);
      expect(class_.kind,
          anyOf(DependencyNodeKind.CLASS, DependencyNodeKind.MIXIN));
      nodes = class_.classTypeParameters;
    }
    return _getNode(nodes, uri: uri, name: name, kind: kind);
  }

  @override
  void setUp() {
    super.setUp();
//    var logger = PerformanceLog(null);
//    tracker = DependencyTracker(logger);
    a = convertPath('/test/lib/a.dart');
    b = convertPath('/test/lib/b.dart');
    c = convertPath('/test/lib/c.dart');
    aUri = Uri.parse('package:test/a.dart');
    bUri = Uri.parse('package:test/b.dart');
    cUri = Uri.parse('package:test/c.dart');
  }

//  Future _addLibraryByUri(String uri) async {
//    var path = driver.sourceFactory.forUri(uri).fullName;
//    var unitResult = await driver.getUnitElement(path);
//
//    var signature = ApiSignature();
//    signature.addString(unitResult.signature);
//    var signatureBytes = signature.toByteList();
//
//    tracker.addLibraryElement(unitResult.element.library, signatureBytes);
//  }

  DependencyNode _getNode(List<DependencyNode> nodes,
      {@required Uri uri, @required String name, DependencyNodeKind kind}) {
    var nameObj = DependencyName(uri, name);
    for (var node in nodes) {
      if (node.name == nameObj) {
        if (kind != null && node.kind != kind) {
          fail('Expected $kind "$name", found ${node.kind}');
        }
        return node;
      }
    }
    fail('Expected to find $uri::$name in:\n    ${nodes.join('\n    ')}');
  }

  Future<List<CompilationUnit>> _resolveLibrary(String libraryPath) async {
    var resolvedLibrary = await driver.getResolvedLibrary(libraryPath);
    return resolvedLibrary.units.map((ru) => ru.unit).toList();
  }
}

class ExpectedNode {
  final Uri uri;
  final String name;
  final DependencyNodeKind kind;
  final List<ExpectedNode> classMembers;
  final List<ExpectedNode> classTypeParameters;

  ExpectedNode(
    this.uri,
    this.name,
    this.kind, {
    this.classMembers,
    this.classTypeParameters,
  });
}

/// TODO(scheglov) remove it once we get actual implementation
class _ReferenceCollector implements ReferenceCollector {
  @override
  Uri get libraryUri => null;

  @override
  void addImportPrefix(String name) {}

  @override
  void appendExpression(Expression node) {}

  @override
  void appendFormalParameters(FormalParameterList formalParameterList) {}

  @override
  void appendFunctionBody(FunctionBody node) {}

  @override
  void appendTypeAnnotation(TypeAnnotation node) {}

  @override
  DependencyNodeDependencies finish(List<int> tokenSignature) {
    return DependencyNodeDependencies(tokenSignature, [], [], [], []);
  }
}
