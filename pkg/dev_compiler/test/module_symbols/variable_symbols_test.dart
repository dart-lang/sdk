// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/kernel/module_symbols.dart';
import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'module_symbols_test_shared.dart';

void main() async {
  var options = SetupCompilerOptions(soundNullSafety: true);
  group('global variable debug symbols', () {
    late final TestDriver driver;
    late final VariableSymbol variableSymbol;
    final source = '''
          class A {}
          var globalVariable = A();
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      variableSymbol = symbols.variables.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('has name', () async {
      expect(variableSymbol.name, equals('globalVariable'));
    });
    test('is global', () async {
      expect(variableSymbol.kind, VariableSymbolKind.global);
    });
    test('is not const', () async {
      expect(variableSymbol.isConst, false);
    });
    test('is not final', () async {
      expect(variableSymbol.isFinal, false);
    });
    test('is static', () async {
      expect(variableSymbol.isStatic, true);
    });
    test('has interface type id', () async {
      expect(variableSymbol.typeId, 'A');
    });
    test('has localId', () async {
      expect(variableSymbol.localId, 'globalVariable');
    });
    test('has library scopeId', () async {
      expect(variableSymbol.scopeId, endsWith('package:foo/foo.dart'));
    });
    group('location', () {
      test('has scriptId', () async {
        expect(variableSymbol.location!.scriptId, endsWith('/foo.dart'));
      });
      test('start token position', () async {
        expect(variableSymbol.location!.tokenPos,
            source.indexOf('globalVariable'));
      });
      test('end token position', () async {
        expect(variableSymbol.location!.endTokenPos, source.lastIndexOf(';'));
      });
    });
  });
  group('global final variable debug symbols', () {
    late final TestDriver driver;
    late final VariableSymbol variableSymbol;
    final source = '''
          class A {}
          final localVariable = A();
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      variableSymbol = symbols.variables.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('is final', () async {
      expect(variableSymbol.isFinal, true);
    });
  });
  group('global const variable debug symbols', () {
    late final TestDriver driver;
    late final VariableSymbol variableSymbol;
    final source = '''
          class A {
            const A();
          }
          const localVariable = A();
          ''';
    setUpAll(() async {
      driver = TestDriver(options, source);
      var symbols = await driver.compileAndGetSymbols();
      variableSymbol = symbols.variables.single;
    });
    tearDownAll(() {
      driver.cleanUp();
    });
    test('is const', () async {
      expect(variableSymbol.isConst, true);
    });
  });
}
