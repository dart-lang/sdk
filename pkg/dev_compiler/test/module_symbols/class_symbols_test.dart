// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/kernel/module_symbols.dart';
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'module_symbols_test_shared.dart';

/// Returns the [FunctionSymbol] from [ModuleSymbols] with the [name] in the
/// original Dart source code or throws an error if there isn't exactly one.
FunctionSymbol _symbolForDartFunction(ModuleSymbols symbols, String name) =>
    symbols.functions
        .where((functionSymbol) => functionSymbol.name == name)
        .single;

void main() async {
  var options = SetupCompilerOptions(soundNullSafety: true);
  group('simple class debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol functionSymbol;
    final source = '''
          class A {}
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      functionSymbol = symbols.functions.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('has name', () async {
      expect(classSymbol.name, equals('A'));
    });
    test('is not abstract', () async {
      expect(classSymbol.isAbstract, isFalse);
    });
    test('is not const', () async {
      expect(classSymbol.isConst, isFalse);
    });
    test('has no superclassId', () async {
      expect(classSymbol.superClassId, isNull);
    });
    test('empty interfacesIds', () async {
      expect(classSymbol.interfaceIds, isEmpty);
    });
    test('empty typeParameters', () async {
      expect(classSymbol.typeParameters, isEmpty);
    });
    test('has localId', () async {
      expect(classSymbol.localId, equals('A'));
    });
    test('has library scopeId', () async {
      expect(classSymbol.scopeId, endsWith('package:foo/foo.dart'));
    });
    group('location', () {
      test('has scriptId', () async {
        expect(classSymbol.location!.scriptId, endsWith('/foo.dart'));
      });
      test('has start token', () async {
        expect(classSymbol.location!.tokenPos, source.indexOf('class A'));
      });
      test('has end token', () async {
        expect(classSymbol.location!.endTokenPos, source.lastIndexOf('}'));
      });
    });
    test('no fields', () async {
      expect(classSymbol.variableIds, isEmpty);
    });
    test('only default constructor in functionIds', () {
      var constructorId = classSymbol.functionIds.single;
      expect(constructorId, functionSymbol.id);
      // Default constructor has no name in Dart Kernel AST.
      expect(functionSymbol.name, isEmpty);
      // Default constructor is named 'new' in JavaScript.
      expect(functionSymbol.id, endsWith('A|new'));
    });
  });
  group('abstract class debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    final source = '''
          abstract class A {}
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('is abstract', () async {
      expect(classSymbol.isAbstract, isTrue);
    });
  });
  group('class extends debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    final source = '''
          class A extends B {}

          class B {}
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.where((c) => c.localId == 'A').single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('has superclass', () async {
      expect(classSymbol.superClassId, 'B');
    });
  });
  group('class implements debug symbols', () {
    late final TestDriver driver;
    late final List<ClassSymbol> classSymbols;
    final source = '''
          class A implements B, C {}

          class B implements C {}

          class C {}
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbols = symbols.classes;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('single implements', () async {
      var classSymbol = classSymbols.singleWhere((c) => c.localId == 'B');
      expect(classSymbol.interfaceIds, orderedEquals(['C']));
    });
    test('multiple implements', () async {
      var classSymbol = classSymbols.singleWhere((c) => c.localId == 'A');
      expect(classSymbol.interfaceIds, orderedEquals(['B', 'C']));
    });
  });
  group('class public static field debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final String fieldId;
    late final VariableSymbol fieldSymbol;
    final source = '''
          class A {
            static String publicStaticField = 'Cello';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      fieldId = classSymbol.fieldIds.single;
      fieldSymbol = symbols.variables.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('fieldId in classSymbol', () async {
      expect(fieldId, endsWith('A|publicStaticField'));
      expect(fieldId, fieldSymbol.id);
    });
    test('has class scopeId', () async {
      expect(fieldSymbol.scopeId, endsWith('|A'));
      expect(fieldSymbol.scopeId, classSymbol.id);
    });
    test('is field', () async {
      expect(fieldSymbol.kind, VariableSymbolKind.field);
    });
    test('is static', () async {
      expect(fieldSymbol.isStatic, isTrue);
    });
  });
  group('class private static field debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final String fieldId;
    late final VariableSymbol fieldSymbol;
    final source = '''
          class A {
            static String _privateStaticField = 'Fosse';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      fieldId = classSymbol.fieldIds.single;
      fieldSymbol = symbols.variables.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('fieldId in classSymbol', () async {
      expect(fieldId, endsWith('A|_privateStaticField'));
      expect(fieldId, fieldSymbol.id);
    });
    test('has class scopeId', () async {
      expect(fieldSymbol.scopeId, endsWith('|A'));
      expect(fieldSymbol.scopeId, classSymbol.id);
    });
    test('is field', () async {
      expect(fieldSymbol.kind, VariableSymbolKind.field);
    });
    test('is static', () async {
      expect(fieldSymbol.isStatic, isTrue);
    });
  });
  group('class public instance field debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final String fieldId;
    late final VariableSymbol fieldSymbol;
    final source = '''
          class A {
            String publicInstanceField = 'Cello';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      fieldId = classSymbol.fieldIds.single;
      fieldSymbol = symbols.variables.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('fieldId in classSymbol', () async {
      expect(fieldId, endsWith('A|publicInstanceField'));
      expect(fieldId, fieldSymbol.id);
    });
    test('has class scopeId', () async {
      expect(fieldSymbol.scopeId, endsWith('|A'));
      expect(fieldSymbol.scopeId, classSymbol.id);
    });
    test('is field', () async {
      expect(fieldSymbol.kind, VariableSymbolKind.field);
    });
    test('is not static', () async {
      expect(fieldSymbol.isStatic, isFalse);
    });
  });
  group('class private instance field debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final String fieldId;
    late final VariableSymbol fieldSymbol;
    final source = '''
          class A {
            String _privateInstanceField = 'Cello';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      fieldId = classSymbol.fieldIds.single;
      fieldSymbol = symbols.variables.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('fieldId in classSymbol', () async {
      expect(fieldId, endsWith('A|Symbol(_privateInstanceField)'));
      expect(fieldId, fieldSymbol.id);
    });
    test('has class scopeId', () async {
      expect(fieldSymbol.scopeId, endsWith('|A'));
      expect(fieldSymbol.scopeId, classSymbol.id);
    });
    test('is field', () async {
      expect(fieldSymbol.kind, VariableSymbolKind.field);
    });
    test('is not static', () async {
      expect(fieldSymbol.isStatic, isFalse);
    });
  });
  group('class public instance method debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            String publicInstanceMethod() => 'Cello';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicInstanceMethod');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicInstanceMethod'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is not static', () async {
      expect(methodSymbol.isStatic, isFalse);
    });
  });
  group('class private instance method debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            String _privateInstanceMethod() => 'Cello';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateInstanceMethod');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|Symbol(_privateInstanceMethod)'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is not static', () async {
      expect(methodSymbol.isStatic, isFalse);
    });
  });
  group('class public static method debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            static String publicStaticMethod() => 'Cello';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicStaticMethod');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicStaticMethod'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is static', () async {
      expect(methodSymbol.isStatic, isTrue);
    });
  });
  group('class private static method debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            static String _privateStaticMethod() => 'Fosse';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateStaticMethod');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|_privateStaticMethod'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is static', () async {
      expect(methodSymbol.isStatic, isTrue);
    });
  });
  group('class public instance getter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            String get publicInstanceGetter => 'Fosse';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicInstanceGetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicInstanceGetter'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is not static', () async {
      expect(methodSymbol.isStatic, isFalse);
    });
  });
  group('class private instance getter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            String get _privateInstanceGetter => 'Fosse';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateInstanceGetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|Symbol(_privateInstanceGetter)'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is not static', () async {
      expect(methodSymbol.isStatic, isFalse);
    });
  });
  group('class public instance setter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A(this._value);
            set publicInstanceSetter(String v) => _value = v;
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicInstanceSetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicInstanceSetter'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is not static', () async {
      expect(methodSymbol.isStatic, isFalse);
    });
  });
  group('class private instance setter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A(this._value);
            set _privateInstanceSetter(String v) => _value = v;
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateInstanceSetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|Symbol(_privateInstanceSetter)'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is not static', () async {
      expect(methodSymbol.isStatic, isFalse);
    });
  });
  group('class public static getter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            static String get publicStaticGetter => 'Fosse';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicStaticGetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicStaticGetter'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is static', () async {
      expect(methodSymbol.isStatic, isTrue);
    });
  });
  group('class private static getter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            static String get _privateStaticGetter => 'Fosse';
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateStaticGetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|_privateStaticGetter'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is static', () async {
      expect(methodSymbol.isStatic, isTrue);
    });
  });
  group('class public static setter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            static String _value = 'Cello';
            static set publicStaticSetter(String v) => _value = v;
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicStaticSetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicStaticSetter'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is static', () async {
      expect(methodSymbol.isStatic, isTrue);
    });
  });
  group('class private static setter debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            static String _value = 'Cello';
            static set _privateStaticSetter(String v) => _value = v;
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateStaticSetter');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|_privateStaticSetter'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is static', () async {
      expect(methodSymbol.isStatic, isTrue);
    });
  });
  group('class public const constructor debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            const A();
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|new'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
    test('is const', () async {
      expect(methodSymbol.isConst, isTrue);
      expect(classSymbol.isConst, isTrue);
    });
  });
  group('class public named constructor debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            A.named();
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'named');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|named'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
  });
  group('class private named constructor debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A._(this._value);
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|__'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
  });
  group('class unnamed factory debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A._(this._value);
            factory A() => A._(10);
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|new'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
  });
  group('class public named factory debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A._(this._value);
            factory A.publicFactory() => A._(10);
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicFactory');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicFactory'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
  });
  group('class private named factory debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A._(this._value);
            factory A._privateFactory() => A._(10);
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateFactory');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|_privateFactory'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
  });
  group('class public redirecting constructor debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A(this._value);
            A.publicRedirecting() : this(10);
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, 'publicRedirecting');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|publicRedirecting'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
  });
  group('class private redirecting constructor debug symbols', () {
    late final TestDriver driver;
    late final ClassSymbol classSymbol;
    late final FunctionSymbol methodSymbol;
    final source = '''
          class A {
            var _value;
            A(this._value);
            A._privateRedirecting() : this(10);
          }
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      classSymbol = symbols.classes.single;
      methodSymbol = _symbolForDartFunction(symbols, '_privateRedirecting');
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('functionId in classSymbol', () async {
      expect(methodSymbol.id, endsWith('A|_privateRedirecting'));
      expect(classSymbol.functionIds, contains(methodSymbol.id));
    });
    test('has class scopeId', () async {
      expect(methodSymbol.scopeId, endsWith('|A'));
      expect(methodSymbol.scopeId, classSymbol.id);
    });
  });
}
