// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/kernel/module_symbols.dart';
import 'package:test/test.dart';

const source = '''
import 'dart:core';                  // pos:1
import 'package:lib2/lib2.dart;      // pos:2
MyClass g;                           // pos:10
class MyClass<T>                     // pos:20
  implements MyInterface
  extends Object {

  static final int f;                // pos:30
  int foo(int x, [int m], {int n}) { // pos:40
    int y = 0;                       // pos:50
    {                                // pos:60
      int z = 0;                     // pos:70
    }                                // pos:80
  }                                  // pos:90
}                                    // pos:100
''';

void main() {
  var intType = ClassSymbol(
      name: 'int',
      localId: 'int',
      scopeId: 'dart:core',
      location: SourceLocation(
          scriptId: 'sdkIdForTest', tokenPos: 42, endTokenPos: 42));

  var libraryId = 'lib1';
  var main = Script(
      uri: 'package:example/hello_world.dart',
      localId: '1',
      libraryId: libraryId);
  var myClassId = 'MyClass<T>';
  var fooId = 'foo';
  var scopeId = '1';

  var g = VariableSymbol(
    name: 'g',
    kind: VariableSymbolKind.global,
    localId: '_g',
    scopeId: libraryId,
    typeId: myClassId,
    location: SourceLocation(scriptId: main.id, tokenPos: 10, endTokenPos: 15),
  );

  var x = VariableSymbol(
    name: 'x',
    kind: VariableSymbolKind.formal,
    localId: '_x',
    scopeId: fooId,
    typeId: intType.id,
    location: SourceLocation(scriptId: main.id, tokenPos: 40, endTokenPos: 42),
  );

  var n = VariableSymbol(
    name: 'n',
    kind: VariableSymbolKind.formal,
    localId: '_n',
    scopeId: fooId,
    typeId: intType.id,
    location: SourceLocation(scriptId: main.id, tokenPos: 43, endTokenPos: 45),
  );

  var m = VariableSymbol(
    name: 'm',
    kind: VariableSymbolKind.formal,
    localId: '_m',
    scopeId: fooId,
    typeId: intType.id,
    location: SourceLocation(scriptId: main.id, tokenPos: 45, endTokenPos: 47),
  );

  var y = VariableSymbol(
    name: 'y',
    kind: VariableSymbolKind.local,
    localId: '_y',
    scopeId: fooId,
    typeId: intType.id,
    location: SourceLocation(scriptId: main.id, tokenPos: 50, endTokenPos: 55),
  );

  var z = VariableSymbol(
    name: 'z',
    kind: VariableSymbolKind.local,
    localId: '_z',
    scopeId: scopeId,
    typeId: intType.id,
    location: SourceLocation(scriptId: main.id, tokenPos: 70, endTokenPos: 75),
  );

  var f = VariableSymbol(
    name: 'f',
    kind: VariableSymbolKind.field,
    localId: '_f',
    scopeId: fooId,
    typeId: intType.id,
    isStatic: true,
    isFinal: true,
    isConst: true,
    location: SourceLocation(scriptId: main.id, tokenPos: 30, endTokenPos: 35),
  );

  var scope = ScopeSymbol(
    localId: scopeId,
    scopeId: fooId,
    variableIds: [z.id],
    scopeIds: [],
    location: SourceLocation(scriptId: main.id, tokenPos: 60, endTokenPos: 80),
  );

  var funType = FunctionTypeSymbol(
    localId: '($myClassId, int) => int',
    scopeId: libraryId,
    typeParameters: {'T': 'A'},
    parameterTypeIds: [intType.id],
    optionalParameterTypeIds: [m.id],
    namedParameterTypeIds: {n.name: n.id},
    returnTypeId: intType.id,
    location: SourceLocation(scriptId: main.id, tokenPos: 40, endTokenPos: 45),
  );

  var foo = FunctionSymbol(
    name: 'foo',
    localId: fooId,
    scopeId: myClassId,
    typeId: funType.id,
    isStatic: false,
    isConst: false,
    variableIds: [x.id, n.id, y.id],
    scopeIds: [scope.id],
    location: SourceLocation(scriptId: main.id, tokenPos: 40, endTokenPos: 90),
  );

  var myClass = ClassSymbol(
    name: 'MyClass',
    localId: myClassId,
    scopeId: libraryId,
    isAbstract: false,
    isConst: false,
    superClassId: 'dart:core|Object',
    interfaceIds: ['lib2|MyInterface'],
    variableIds: [f.id],
    scopeIds: [foo.id],
    typeParameters: {'T': 'B'},
    location: SourceLocation(scriptId: main.id, tokenPos: 20, endTokenPos: 100),
  );

  var library = LibrarySymbol(
    name: 'package:example/hello_world.dart',
    uri: 'package:example/hello_world.dart',
    dependencies: [
      LibrarySymbolDependency(isImport: true, targetId: 'dart:core'),
      LibrarySymbolDependency(isImport: true, targetId: 'lib2'),
    ],
    scriptIds: [main.id],
    variableIds: [g.id], // global variables
    scopeIds: [myClass.id], // global functions and classes
  );

  var info = ModuleSymbols(
    version: ModuleSymbols.current.version,
    moduleName: 'package:example/hello_world.dart',
    libraries: [library],
    scripts: [main],
    classes: [myClass],
    functionTypes: [funType],
    functions: [foo],
    scopes: [scope],
    variables: [x, y, z, n, g, f],
  );

  test('Read and write symbols', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);
    var write = read.toJson();

    expect(json, equals(write));
  });

  test('Write and read libraries', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);

    expect(read.libraries.length, 1);
    expect(read.libraries[0], matchesLibrary(library));
  });

  test('Write and read classes', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);

    expect(read.classes.length, 1);
    expect(read.classes[0], matchesClass(myClass));
  });

  test('Write and read function types', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);

    expect(read.functionTypes.length, 1);
    expect(read.functionTypes[0], matchesFunctionType(funType));
  });

  test('Write and read functions', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);

    expect(read.functions.length, 1);
    expect(read.functions[0], matchesFunction(foo));
  });

  test('Write and read scripts', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);

    expect(read.scripts.length, 1);
    expect(read.scripts[0], matchesScript(main));
  });

  test('Write and read scopes', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);

    expect(read.scopes.length, 1);
    expect(read.scopes[0], matchesScope(scope));
  });

  test('Write and read variables', () {
    var json = info.toJson();
    var read = ModuleSymbols.fromJson(json);

    expect(read.variables.length, 6);
    expect(read.variables[0], matchesVariable(x));
    expect(read.variables[1], matchesVariable(y));
    expect(read.variables[2], matchesVariable(z));
    expect(read.variables[3], matchesVariable(n));
    expect(read.variables[4], matchesVariable(g));
    expect(read.variables[5], matchesVariable(f));
  });

  test('Read supported version', () {
    var version = SemanticVersion(0, 2, 3).version;
    var json = ModuleSymbols(version: version, moduleName: 'moduleNameForTest')
        .toJson();

    expect(ModuleSymbols.fromJson(json).version, equals(version));
  });

  test('Read unsupported version', () {
    var version = SemanticVersion(1, 2, 3).version;
    var json = ModuleSymbols(version: version, moduleName: 'moduleNameForTest')
        .toJson();

    expect(() => ModuleSymbols.fromJson(json), throwsException);
  });
}

TypeMatcher<SourceLocation> matchesLocation(SourceLocation other) =>
    isA<SourceLocation>()
        .having((loc) => loc.scriptId, 'scriptId', other.scriptId)
        .having((loc) => loc.tokenPos, 'tokenPos', other.tokenPos)
        .having((loc) => loc.endTokenPos, 'endTokenPos', other.endTokenPos);

TypeMatcher<LibrarySymbolDependency> matchesDependency(
        LibrarySymbolDependency other) =>
    isA<LibrarySymbolDependency>()
        .having((dep) => dep.isDeferred, 'isDeferred', other.isDeferred)
        .having((dep) => dep.isImport, 'isImport', other.isImport)
        .having((dep) => dep.prefix, 'prefix', other.prefix)
        .having((dep) => dep.targetId, 'targetId', other.targetId);

Iterable<Matcher> matchDependencies(List<LibrarySymbolDependency> list) =>
    [for (var e in list) matchesDependency(e)];

TypeMatcher<LibrarySymbol> matchesLibrary(LibrarySymbol other) =>
    isA<LibrarySymbol>()
        .having((lib) => lib.name, 'name', other.name)
        .having((lib) => lib.uri, 'uri', other.uri)
        .having((lib) => lib.id, 'id', other.id)
        .having((lib) => lib.scriptIds, 'scriptIds', other.scriptIds)
        .having((lib) => lib.scopeIds, 'scopeIds', other.scopeIds)
        .having((lib) => lib.scopeIds, 'scopeIds', other.scopeIds)
        .having((lib) => lib.variableIds, 'variableIds', other.variableIds)
        .having((lib) => lib.location, 'location', isNull)
        .having((lib) => lib.dependencies, 'dependencies',
            matchDependencies(other.dependencies));

TypeMatcher<ClassSymbol> matchesClass(ClassSymbol other) => isA<ClassSymbol>()
    .having((cls) => cls.name, 'name', other.name)
    .having((cls) => cls.id, 'id', other.id)
    .having((fun) => fun.localId, 'localId', other.localId)
    .having((fun) => fun.scopeId, 'scopeId', other.scopeId)
    .having((cls) => cls.superClassId, 'superClassId', other.superClassId)
    .having((cls) => cls.typeParameters, 'typeParameters', other.typeParameters)
    .having((cls) => cls.functionIds, 'functionIds', other.functionIds)
    .having((cls) => cls.interfaceIds, 'interfaceIds', other.interfaceIds)
    .having((cls) => cls.isAbstract, 'isAbstract', other.isAbstract)
    .having((cls) => cls.isConst, 'isConst', other.isConst)
    .having((cls) => cls.libraryId, 'libraryId', other.libraryId)
    .having((cls) => cls.scopeIds, 'scopeIds', other.scopeIds)
    .having((cls) => cls.variableIds, 'variableIds', other.variableIds)
    .having(
        (cls) => cls.location, 'location', matchesLocation(other.location!));

TypeMatcher<FunctionTypeSymbol> matchesFunctionType(FunctionTypeSymbol other) =>
    isA<FunctionTypeSymbol>()
        .having((fun) => fun.id, 'id', other.id)
        .having((fun) => fun.localId, 'localId', other.localId)
        .having((fun) => fun.scopeId, 'scopeId', other.scopeId)
        .having(
            (fun) => fun.typeParameters, 'typeParameters', other.typeParameters)
        .having((fun) => fun.parameterTypeIds, 'parameterTypeIds',
            other.parameterTypeIds)
        .having((fun) => fun.optionalParameterTypeIds,
            'optionalParameterTypeIds', other.optionalParameterTypeIds)
        .having((fun) => fun.namedParameterTypeIds, 'namedParameterTypeIds',
            other.namedParameterTypeIds)
        .having((fun) => fun.location, 'location',
            matchesLocation(other.location!));

TypeMatcher<FunctionSymbol> matchesFunction(FunctionSymbol other) =>
    isA<FunctionSymbol>()
        .having((fun) => fun.name, 'name', other.name)
        .having((fun) => fun.localId, 'localId', other.localId)
        .having((fun) => fun.scopeId, 'scopeId', other.scopeId)
        .having((fun) => fun.id, 'id', other.id)
        .having((fun) => fun.isConst, 'isConst', other.isConst)
        .having((fun) => fun.isStatic, 'isStatic', other.isStatic)
        .having((fun) => fun.typeId, 'typeId', other.typeId)
        .having((fun) => fun.scopeIds, 'scopeIds', other.scopeIds)
        .having((fun) => fun.variableIds, 'variableIds', other.variableIds)
        .having((fun) => fun.location, 'location',
            matchesLocation(other.location!));

TypeMatcher<ScopeSymbol> matchesScope(ScopeSymbol other) => isA<ScopeSymbol>()
    .having((scope) => scope.localId, 'localId', other.localId)
    .having((scope) => scope.scopeId, 'scopeId', other.scopeId)
    .having((scope) => scope.id, 'id', other.id)
    .having((scope) => scope.scopeIds, 'scopeIds', other.scopeIds)
    .having((scope) => scope.variableIds, 'variableIds', other.variableIds)
    .having((scope) => scope.location, 'location',
        matchesLocation(other.location!));

TypeMatcher<VariableSymbol> matchesVariable(VariableSymbol other) =>
    isA<VariableSymbol>()
        .having((variable) => variable.name, 'name', other.name)
        .having((variable) => variable.localId, 'localId', other.localId)
        .having((variable) => variable.scopeId, 'scopeId', other.scopeId)
        .having((variable) => variable.id, 'id', other.id)
        .having((variable) => variable.isConst, 'isConst', other.isConst)
        .having((variable) => variable.isStatic, 'isStatic', other.isStatic)
        .having((variable) => variable.isFinal, 'isFinal', other.isFinal)
        .having((variable) => variable.location, 'location',
            matchesLocation(other.location!));

TypeMatcher<Script> matchesScript(Script other) => isA<Script>()
    .having((script) => script.uri, 'uri', other.uri)
    .having((script) => script.id, 'id', other.id);
