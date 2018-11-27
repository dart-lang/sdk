// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../context/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionImplTest);
  });
}

@reflectiveTest
class AnalysisSessionImplTest with ResourceProviderMixin {
  AnalysisContextCollection contextCollection;
  AnalysisContext context;
  AnalysisSessionImpl session;

  String testContextPath;
  String aaaContextPath;
  String bbbContextPath;

  String testPath;

  void setUp() {
    MockSdk(resourceProvider: resourceProvider);

    testContextPath = newFolder('/home/test').path;
    aaaContextPath = newFolder('/home/aaa').path;
    bbbContextPath = newFolder('/home/bbb').path;

    newFile('/home/test/.packages', content: r'''
test:lib/
''');

    contextCollection = AnalysisContextCollectionImpl(
      includedPaths: [testContextPath, aaaContextPath, bbbContextPath],
      resourceProvider: resourceProvider,
      sdkPath: convertPath(sdkRoot),
    );
    context = contextCollection.contextFor(testContextPath);
    session = context.currentSession;

    testPath = convertPath('/home/test/lib/test.dart');
  }

  test_getErrors() async {
    newFile(testPath, content: 'class C {');
    var errorsResult = await session.getErrors(testPath);
    expect(errorsResult.session, session);
    expect(errorsResult.path, testPath);
    expect(errorsResult.errors, isNotEmpty);
  }

  test_getLibraryByUri() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var library = await session.getLibraryByUri('package:test/test.dart');
    expect(library.getType('A'), isNotNull);
    expect(library.getType('B'), isNotNull);
    expect(library.getType('C'), isNull);
  }

  test_getParsedAstSync() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var unitResult = session.getParsedAstSync(testPath);
    expect(unitResult.session, session);
    expect(unitResult.path, testPath);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
  }

  test_getResolvedAst() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var unitResult = await session.getResolvedAst(testPath);
    expect(unitResult.session, session);
    expect(unitResult.path, testPath);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
    expect(unitResult.typeProvider, isNotNull);
    expect(unitResult.libraryElement, isNotNull);
  }

  test_getResolvedLibrary() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');

    var aContent = r'''
part 'b.dart';

class A /*a*/ {}
''';
    newFile(a, content: aContent);

    var bContent = r'''
part of 'a.dart';

class B /*b*/ {}
class B2 extends X {}
''';
    newFile(b, content: bContent);

    var resolvedLibrary = await session.getResolvedLibrary(a);
    expect(resolvedLibrary.session, session);
    expect(resolvedLibrary.path, a);
    expect(resolvedLibrary.uri, Uri.parse('package:test/a.dart'));

    var typeProvider = resolvedLibrary.typeProvider;
    expect(typeProvider.intType.element.name, 'int');

    var libraryElement = resolvedLibrary.element;
    expect(libraryElement, isNotNull);

    var aClass = libraryElement.getType('A');
    expect(aClass, isNotNull);

    var bClass = libraryElement.getType('B');
    expect(bClass, isNotNull);

    var aUnitResult = resolvedLibrary.units[0];
    expect(aUnitResult.path, a);
    expect(aUnitResult.uri, Uri.parse('package:test/a.dart'));
    expect(aUnitResult.content, aContent);
    expect(aUnitResult.unit, isNotNull);
    expect(aUnitResult.unit.directives, hasLength(1));
    expect(aUnitResult.unit.declarations, hasLength(1));
    expect(aUnitResult.errors, isEmpty);

    var bUnitResult = resolvedLibrary.units[1];
    expect(bUnitResult.path, b);
    expect(bUnitResult.uri, Uri.parse('package:test/b.dart'));
    expect(bUnitResult.content, bContent);
    expect(bUnitResult.unit, isNotNull);
    expect(bUnitResult.unit.directives, hasLength(1));
    expect(bUnitResult.unit.declarations, hasLength(2));
    expect(bUnitResult.errors, isNotEmpty);

    var aDeclaration = resolvedLibrary.getElementDeclaration(aClass);
    ClassDeclaration aNode = aDeclaration.node;
    expect(aNode.name.name, 'A');
    expect(aNode.offset, 16);
    expect(aNode.length, 16);
    expect(aNode.name.staticElement.name, 'A');

    var bDeclaration = resolvedLibrary.getElementDeclaration(bClass);
    ClassDeclaration bNode = bDeclaration.node;
    expect(bNode.name.name, 'B');
    expect(bNode.offset, 19);
    expect(bNode.length, 16);
    expect(bNode.name.staticElement.name, 'B');
  }

  test_getResolvedLibrary_getElementDeclaration_notThisLibrary() async {
    newFile(testPath, content: '');

    var resolvedLibrary = await session.getResolvedLibrary(testPath);

    expect(() {
      var intClass = resolvedLibrary.typeProvider.intType.element;
      resolvedLibrary.getElementDeclaration(intClass);
    }, throwsArgumentError);
  }

  test_getResolvedLibrary_getElementDeclaration_synthetic() async {
    newFile(testPath, content: r'''
int foo = 0;
''');

    var resolvedLibrary = await session.getResolvedLibrary(testPath);
    var unitElement = resolvedLibrary.element.definingCompilationUnit;

    var fooElement = unitElement.topLevelVariables[0];
    expect(fooElement.name, 'foo');

    // We can get the variable element declaration.
    var fooDeclaration = resolvedLibrary.getElementDeclaration(fooElement);
    VariableDeclaration fooNode = fooDeclaration.node;
    expect(fooNode.name.name, 'foo');
    expect(fooNode.offset, 4);
    expect(fooNode.length, 7);
    expect(fooNode.name.staticElement.name, 'foo');

    // Synthetic elements don't have nodes.
    expect(resolvedLibrary.getElementDeclaration(fooElement.getter), isNull);
    expect(resolvedLibrary.getElementDeclaration(fooElement.setter), isNull);
  }

  test_getResolvedLibrary_invalidPartUri() async {
    newFile(testPath, content: r'''
part 'a.dart';
part ':[invalid uri].dart';
part 'c.dart';
''');

    var resolvedLibrary = await session.getResolvedLibrary(testPath);

    expect(resolvedLibrary.units, hasLength(3));
    expect(
      resolvedLibrary.units[0].path,
      convertPath('/home/test/lib/test.dart'),
    );
    expect(
      resolvedLibrary.units[1].path,
      convertPath('/home/test/lib/a.dart'),
    );
    expect(
      resolvedLibrary.units[2].path,
      convertPath('/home/test/lib/c.dart'),
    );
  }

  test_getResolvedLibrary_notLibrary() async {
    newFile(testPath, content: 'part of "a.dart";');

    expect(() {
      session.getResolvedLibrary(testPath);
    }, throwsArgumentError);
  }

  test_getResolvedLibraryByElement() async {
    newFile(testPath, content: '');

    var element = await session.getLibraryByUri('package:test/test.dart');

    var resolvedLibrary = await session.getResolvedLibraryByElement(element);
    expect(resolvedLibrary.session, session);
    expect(resolvedLibrary.path, testPath);
    expect(resolvedLibrary.uri, Uri.parse('package:test/test.dart'));
    expect(resolvedLibrary.units, hasLength(1));
    expect(resolvedLibrary.units[0].unit.declaredElement, isNotNull);
  }

  test_getSourceKind() async {
    newFile(testPath, content: 'class C {}');

    var kind = await session.getSourceKind(testPath);
    expect(kind, SourceKind.LIBRARY);
  }

  test_getSourceKind_part() async {
    newFile(testPath, content: 'part of "a.dart";');

    var kind = await session.getSourceKind(testPath);
    expect(kind, SourceKind.PART);
  }

  test_getUnitElement() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var unitResult = await session.getUnitElement(testPath);
    expect(unitResult.session, session);
    expect(unitResult.path, testPath);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.element.types, hasLength(2));

    var signature = await session.getUnitElementSignature(testPath);
    expect(unitResult.signature, signature);
  }

  test_resourceProvider() async {
    expect(session.resourceProvider, resourceProvider);
  }

  test_typeProvider() async {
    var typeProvider = await session.typeProvider;
    expect(typeProvider.intType.element.name, 'int');
  }

  test_typeSystem() async {
    var typeSystem = await session.typeSystem;
    var typeProvider = typeSystem.typeProvider;
    expect(
      typeSystem.isSubtypeOf(typeProvider.intType, typeProvider.numType),
      isTrue,
    );
  }
}
