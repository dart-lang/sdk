// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisSessionImplTest);
  });
}

@reflectiveTest
class AnalysisSessionImplTest {
  MockAnalysisDriver driver;
  AnalysisSessionImpl session;

  void setUp() {
    driver = new MockAnalysisDriver();
    session = new AnalysisSessionImpl(driver);
    driver.currentSession = session;
  }

  test_getErrors() async {
    ErrorsResultImpl result =
        new ErrorsResultImpl(null, null, null, null, null, null);
    driver.errorsResult = result;
    expect(await session.getErrors('path'), result);
  }

  test_getLibraryByUri() async {
    String uri = 'uri';

    var source = new _SourceMock(Uri.parse(uri));
    var unit = new CompilationUnitElementImpl()
      ..librarySource = source
      ..source = source;
    var library = new LibraryElementImpl(null, session, null, null, null)
      ..definingCompilationUnit = unit;

    driver.libraryMap[uri] = library;
    expect(await session.getLibraryByUri(uri), library);
  }

  test_getParsedAst() async {
    ParsedUnitResultImpl result = new ParsedUnitResultImpl(
        null, null, null, null, null, null, null, null);
    driver.parseResult = result;
    expect(session.getParsedUnit('path'), result);
  }

  test_getResolvedUnit() async {
    ResolvedUnitResult result = new ResolvedUnitResultImpl(
        session, null, null, null, null, null, null, null, null);
    driver.result = result;
    expect(await session.getResolvedUnit('path'), result);
  }

  test_getSourceKind() async {
    SourceKind kind = SourceKind.LIBRARY;
    driver.sourceKind = kind;
    expect(await session.getSourceKind('path'), kind);
  }

  test_getTopLevelDeclarations() async {
    List<TopLevelDeclarationInSource> declarations = [];
    driver.topLevelDeclarations = declarations;
    expect(await session.getTopLevelDeclarations('path'), declarations);
  }

  test_getUnitElement() async {
    UnitElementResultImpl result =
        new UnitElementResultImpl(null, null, null, null, null);
    driver.unitElementResult = result;
    expect(await session.getUnitElement('path'), result);
  }

  test_getUnitElementSignature() async {
    String signature = 'xyzzy';
    driver.unitElementSignature = signature;
    expect(await session.getUnitElementSignature('path'), signature);
  }

  test_resourceProvider() {
    ResourceProvider resourceProvider = new MemoryResourceProvider();
    driver.resourceProvider = resourceProvider;
    expect(session.resourceProvider, resourceProvider);
  }

  test_sourceFactory() {
    SourceFactory sourceFactory = new SourceFactory([]);
    driver.sourceFactory = sourceFactory;
    expect(session.sourceFactory, sourceFactory);
  }

  test_typeProvider() async {
    _initializeSDK();
    expect(await session.typeProvider, isNotNull);
  }

  test_typeSystem() async {
    _initializeSDK();
    expect(await session.typeSystem, isNotNull);
  }

  void _initializeSDK() {
    CompilationUnitElementImpl newUnit(String name) {
      CompilationUnitElementImpl unit = new CompilationUnitElementImpl();
      unit.accessors = [];
      unit.enums = [];
      unit.functions = [];
      unit.typeAliases = [];
      return unit;
    }

    ClassElementImpl newClass(String name) {
      TypeParameterElementImpl param = new TypeParameterElementImpl('E', 0);
      param.type = new TypeParameterTypeImpl(param);
      ClassElementImpl element = new ClassElementImpl(name, 0);
      element.typeParameters = [param];
      return element;
    }

    {
      CompilationUnitElementImpl coreUnit = newUnit('dart.core');
      coreUnit.types = <ClassElement>[newClass('Iterable')];
      LibraryElementImpl core =
          new LibraryElementImpl(null, session, null, null, null);
      core.definingCompilationUnit = coreUnit;
      driver.libraryMap['dart:core'] = core;
    }
    {
      CompilationUnitElementImpl asyncUnit = newUnit('dart.async');
      asyncUnit.types = <ClassElement>[
        newClass('Future'),
        newClass('FutureOr'),
        newClass('Stream')
      ];
      LibraryElementImpl async =
          new LibraryElementImpl(null, session, null, null, null);
      async.definingCompilationUnit = asyncUnit;
      driver.libraryMap['dart:async'] = async;
    }
  }
}

class MockAnalysisDriver implements AnalysisDriver {
  @override
  AnalysisSession currentSession;

  ErrorsResultImpl errorsResult;
  Map<String, LibraryElement> libraryMap = <String, LibraryElement>{};
  ParsedUnitResultImpl parseResult;
  ResourceProvider resourceProvider;
  ResolvedUnitResult result;
  SourceFactory sourceFactory;
  SourceKind sourceKind;
  List<TopLevelDeclarationInSource> topLevelDeclarations;
  UnitElementResultImpl unitElementResult;
  String unitElementSignature;

  AnalysisOptions get analysisOptions => new AnalysisOptionsImpl();

  @override
  Future<ErrorsResult> getErrors(String path) async {
    return errorsResult;
  }

  @override
  Future<LibraryElement> getLibraryByUri(String uri) async {
    return libraryMap[uri];
  }

  @override
  Future<ResolvedUnitResult> getResult(String path,
      {bool sendCachedToStream: false}) async {
    return result;
  }

  @override
  Future<SourceKind> getSourceKind(String path) async {
    return sourceKind;
  }

  @override
  Future<List<TopLevelDeclarationInSource>> getTopLevelNameDeclarations(
      String name) async {
    return topLevelDeclarations;
  }

  @override
  Future<UnitElementResult> getUnitElement(String path) async {
    return unitElementResult;
  }

  @override
  Future<String> getUnitElementSignature(String path) async {
    return unitElementSignature;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    fail('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  Future<ParsedUnitResult> parseFile(String path) async {
    return parseResult;
  }

  @override
  ParsedUnitResult parseFileSync(String path) {
    return parseResult;
  }
}

class _SourceMock implements Source {
  @override
  final Uri uri;

  _SourceMock(this.uri);

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
