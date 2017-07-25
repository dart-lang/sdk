// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
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
    ErrorsResult result = new ErrorsResult(null, null, null, null, null);
    driver.errorsResult = result;
    expect(await session.getErrors('path'), result);
  }

  test_getLibraryByUri() async {
    String uri = 'uri';
    LibraryElement element = new LibraryElementImpl(null, null, null, null);
    driver.libraryMap[uri] = element;
    expect(await session.getLibraryByUri(uri), element);
  }

  test_getParsedAst() async {
    ParseResult result =
        new ParseResult(null, null, null, null, null, null, null);
    driver.parseResult = result;
    expect(await session.getParsedAst('path'), result);
  }

  test_getResolvedAst() async {
    AnalysisResult result = new AnalysisResult(
        driver, null, null, null, null, null, null, null, null, null, null);
    driver.result = result;
    expect(await session.getResolvedAst('path'), result);
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
    UnitElementResult result =
        new UnitElementResult(null, null, null, null, null);
    driver.unitElementResult = result;
    expect(await session.getUnitElement('path'), result);
  }

  test_getUnitElementSignature() async {
    String signature = 'xyzzy';
    driver.unitElementSignature = signature;
    expect(await session.getUnitElementSignature('path'), signature);
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
      CompilationUnitElementImpl unit = new CompilationUnitElementImpl(name);
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
      LibraryElementImpl core = new LibraryElementImpl(null, null, null, null);
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
      LibraryElementImpl async = new LibraryElementImpl(null, null, null, null);
      async.definingCompilationUnit = asyncUnit;
      driver.libraryMap['dart:async'] = async;
    }
  }
}

class MockAnalysisDriver implements AnalysisDriver {
  @override
  AnalysisSession currentSession;

  ErrorsResult errorsResult;
  Map<String, LibraryElement> libraryMap = <String, LibraryElement>{};
  ParseResult parseResult;
  AnalysisResult result;
  SourceKind sourceKind;
  List<TopLevelDeclarationInSource> topLevelDeclarations;
  UnitElementResult unitElementResult;
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
  Future<AnalysisResult> getResult(String path,
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
    return null;
  }

  @override
  Future<ParseResult> parseFile(String path) async {
    return parseResult;
  }
}
