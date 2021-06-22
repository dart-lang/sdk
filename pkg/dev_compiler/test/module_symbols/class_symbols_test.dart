// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dev_compiler/src/kernel/module_symbols.dart';
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'module_symbols_test_shared.dart';

void main() async {
  for (var mode in [
    NullSafetyTestOption('Sound Mode:', true),
    NullSafetyTestOption('Weak Mode:', false)
  ]) {
    group(mode.description, () {
      var options = SetupCompilerOptions(soundNullSafety: mode.soundNullSafety);
      group('simple class debug symbols', () {
        TestDriver driver;
        ClassSymbol classSymbol;
        final source = '''
          ${options.dartLangComment}

          class A {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
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
        // TODO test isConst
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
            expect(classSymbol.location.scriptId, endsWith('/foo.dart'));
          });
          test('has start token', () async {
            expect(classSymbol.location.tokenPos,
                22 + options.dartLangComment.length);
          });
          test('has end token', () async {
            expect(classSymbol.location.endTokenPos,
                31 + options.dartLangComment.length);
          });
        });
        test('no fields', () async {
          expect(classSymbol.variableIds, isEmpty);
        });
        // TODO only has the implicit constructor in scopeIds.
      });
      group('abstract class debug symbols', () {
        TestDriver driver;
        ClassSymbol classSymbol;
        final source = '''
          ${options.dartLangComment}

          abstract class A {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('is abstract', () async {
          expect(classSymbol.isAbstract, isTrue);
        });
      });
      group('class extends debug symbols', () {
        TestDriver driver;
        ClassSymbol classSymbol;
        final source = '''
          ${options.dartLangComment}

          class A extends B {}

          class B {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol =
              result.symbols.classes.where((c) => c.localId == 'A').single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('has superclass', () async {
          expect(classSymbol.superClassId, 'B');
        });
      });
      group('class implements debug symbols', () {
        TestDriver driver;
        List<ClassSymbol> classSymbols;
        final source = '''
          ${options.dartLangComment}

          class A implements B, C {}

          class B implements C {}

          class C {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbols = result.symbols.classes;
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
        TestDriver driver;
        ClassSymbol classSymbol;
        String fieldId;
        VariableSymbol fieldSymbol;
        final source = '''
          ${options.dartLangComment}

          class A {
            static String publicStaticField = 'Cello';
          }
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
          fieldId = classSymbol.fieldIds.single;
          fieldSymbol = result.symbols.variables.single;
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
        TestDriver driver;
        ClassSymbol classSymbol;
        String fieldId;
        VariableSymbol fieldSymbol;
        final source = '''
          ${options.dartLangComment}

          class A {
            static String _privateStaticField = 'Fosse';
          }
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
          fieldId = classSymbol.fieldIds.single;
          fieldSymbol = result.symbols.variables.single;
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
        TestDriver driver;
        ClassSymbol classSymbol;
        String fieldId;
        VariableSymbol fieldSymbol;
        final source = '''
          ${options.dartLangComment}

          class A {
            String publicInstanceField = 'Cello';
          }
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
          fieldId = classSymbol.fieldIds.single;
          fieldSymbol = result.symbols.variables.single;
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
        TestDriver driver;
        ClassSymbol classSymbol;
        String fieldId;
        VariableSymbol fieldSymbol;
        final source = '''
          ${options.dartLangComment}

          class A {
            String privateInstanceField = 'Cello';
          }
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          classSymbol = result.symbols.classes.single;
          fieldId = classSymbol.fieldIds.single;
          fieldSymbol = result.symbols.variables.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('fieldId in classSymbol', () async {
          expect(fieldId, endsWith('A|privateInstanceField'));
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
    });
  }
}
