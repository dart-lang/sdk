// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionImplTest);
  });
}

@reflectiveTest
class AnalysisSessionImplTest with ResourceProviderMixin {
  /*late final*/ AnalysisContextCollection contextCollection;
  /*late final*/ AnalysisContext context;
  /*late final*/ AnalysisSessionImpl session;

  /*late final*/ String testContextPath;
  /*late final*/ String aaaContextPath;
  /*late final*/ String bbbContextPath;

  /*late final*/ String testPath;

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

  test_getLibraryByUri_unresolvedUri() async {
    expect(() async {
      await session.getLibraryByUri('package:foo/foo.dart');
    }, throwsArgumentError);
  }

  test_getParsedLibrary() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var parsedLibrary = session.getParsedLibrary(testPath);
    expect(parsedLibrary.session, session);
    expect(parsedLibrary.path, testPath);
    expect(parsedLibrary.uri, Uri.parse('package:test/test.dart'));

    expect(parsedLibrary.units, hasLength(1));
    {
      var parsedUnit = parsedLibrary.units[0];
      expect(parsedUnit.session, session);
      expect(parsedUnit.path, testPath);
      expect(parsedUnit.uri, Uri.parse('package:test/test.dart'));
      expect(parsedUnit.unit.declarations, hasLength(2));
    }
  }

  test_getParsedLibrary_getElementDeclaration_class() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var library = await session.getLibraryByUri('package:test/test.dart');
    var parsedLibrary = session.getParsedLibrary(testPath);

    var element = library.getType('A');
    var declaration = parsedLibrary.getElementDeclaration(element);
    ClassDeclaration node = declaration.node;
    expect(node.name.name, 'A');
    expect(node.offset, 0);
    expect(node.length, 10);
  }

  test_getParsedLibrary_getElementDeclaration_notThisLibrary() async {
    newFile(testPath, content: '');

    var resolvedUnit = await session.getResolvedUnit(testPath);
    var typeProvider = resolvedUnit.typeProvider;
    var intClass = typeProvider.intType.element;

    var parsedLibrary = session.getParsedLibrary(testPath);

    expect(() {
      parsedLibrary.getElementDeclaration(intClass);
    }, throwsArgumentError);
  }

  test_getParsedLibrary_getElementDeclaration_synthetic() async {
    newFile(testPath, content: r'''
int foo = 0;
''');

    var parsedLibrary = session.getParsedLibrary(testPath);

    var unitElement = (await session.getUnitElement(testPath)).element;
    var fooElement = unitElement.topLevelVariables[0];
    expect(fooElement.name, 'foo');

    // We can get the variable element declaration.
    var fooDeclaration = parsedLibrary.getElementDeclaration(fooElement);
    VariableDeclaration fooNode = fooDeclaration.node;
    expect(fooNode.name.name, 'foo');
    expect(fooNode.offset, 4);
    expect(fooNode.length, 7);
    expect(fooNode.name.staticElement, isNull);

    // Synthetic elements don't have nodes.
    expect(parsedLibrary.getElementDeclaration(fooElement.getter), isNull);
    expect(parsedLibrary.getElementDeclaration(fooElement.setter), isNull);
  }

  test_getParsedLibrary_invalidPartUri() async {
    newFile(testPath, content: r'''
part 'a.dart';
part ':[invalid uri].dart';
part 'c.dart';
''');

    var parsedLibrary = session.getParsedLibrary(testPath);

    expect(parsedLibrary.units, hasLength(3));
    expect(
      parsedLibrary.units[0].path,
      convertPath('/home/test/lib/test.dart'),
    );
    expect(
      parsedLibrary.units[1].path,
      convertPath('/home/test/lib/a.dart'),
    );
    expect(
      parsedLibrary.units[2].path,
      convertPath('/home/test/lib/c.dart'),
    );
  }

  test_getParsedLibrary_notLibrary() async {
    newFile(testPath, content: 'part of "a.dart";');

    expect(() {
      session.getParsedLibrary(testPath);
    }, throwsArgumentError);
  }

  test_getParsedLibrary_parts() async {
    var a = convertPath('/home/test/lib/a.dart');
    var b = convertPath('/home/test/lib/b.dart');
    var c = convertPath('/home/test/lib/c.dart');

    var aContent = r'''
part 'b.dart';
part 'c.dart';

class A {}
''';

    var bContent = r'''
part of 'a.dart';

class B1 {}
class B2 {}
''';

    var cContent = r'''
part of 'a.dart';

class C1 {}
class C2 {}
class C3 {}
''';

    newFile(a, content: aContent);
    newFile(b, content: bContent);
    newFile(c, content: cContent);

    var parsedLibrary = session.getParsedLibrary(a);
    expect(parsedLibrary.path, a);
    expect(parsedLibrary.uri, Uri.parse('package:test/a.dart'));
    expect(parsedLibrary.units, hasLength(3));

    {
      var aUnit = parsedLibrary.units[0];
      expect(aUnit.path, a);
      expect(aUnit.uri, Uri.parse('package:test/a.dart'));
      expect(aUnit.unit.declarations, hasLength(1));
    }

    {
      var bUnit = parsedLibrary.units[1];
      expect(bUnit.path, b);
      expect(bUnit.uri, Uri.parse('package:test/b.dart'));
      expect(bUnit.unit.declarations, hasLength(2));
    }

    {
      var cUnit = parsedLibrary.units[2];
      expect(cUnit.path, c);
      expect(cUnit.uri, Uri.parse('package:test/c.dart'));
      expect(cUnit.unit.declarations, hasLength(3));
    }
  }

  test_getParsedLibraryByElement() async {
    newFile(testPath, content: '');

    var element = await session.getLibraryByUri('package:test/test.dart');

    var parsedLibrary = session.getParsedLibraryByElement(element);
    expect(parsedLibrary.session, session);
    expect(parsedLibrary.path, testPath);
    expect(parsedLibrary.uri, Uri.parse('package:test/test.dart'));
    expect(parsedLibrary.units, hasLength(1));
  }

  test_getParsedLibraryByElement_differentSession() async {
    newFile(testPath, content: '');

    var element = await session.getLibraryByUri('package:test/test.dart');

    var aaaSession =
        contextCollection.contextFor(aaaContextPath).currentSession;

    expect(() {
      aaaSession.getParsedLibraryByElement(element);
    }, throwsArgumentError);
  }

  test_getParsedUnit() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var unitResult = session.getParsedUnit(testPath);
    expect(unitResult.session, session);
    expect(unitResult.path, testPath);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
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

  test_getResolvedLibraryByElement_differentSession() async {
    newFile(testPath, content: '');

    var element = await session.getLibraryByUri('package:test/test.dart');

    var aaaSession =
        contextCollection.contextFor(aaaContextPath).currentSession;

    expect(() async {
      await aaaSession.getResolvedLibraryByElement(element);
    }, throwsArgumentError);
  }

  test_getResolvedUnit() async {
    newFile(testPath, content: r'''
class A {}
class B {}
''');

    var unitResult = await session.getResolvedUnit(testPath);
    expect(unitResult.session, session);
    expect(unitResult.path, testPath);
    expect(unitResult.uri, Uri.parse('package:test/test.dart'));
    expect(unitResult.unit.declarations, hasLength(2));
    expect(unitResult.typeProvider, isNotNull);
    expect(unitResult.libraryElement, isNotNull);
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
}
