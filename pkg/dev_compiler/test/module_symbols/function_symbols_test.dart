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
      group('top level function debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionSymbol;
        LibrarySymbol librarySymbol;
        final source = '''
          ${options.dartLangComment}

          void topLevelFunction() {
            return;
          }
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          librarySymbol = result.symbols.libraries.single;
          functionSymbol = result.symbols.functions.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('has name', () async {
          expect(functionSymbol.name, equals('topLevelFunction'));
        });
        // TODO(nshahan) Test for typeId.
        test('is static', () async {
          expect(functionSymbol.isStatic, isTrue);
        });
        test('is not const', () async {
          expect(functionSymbol.isConst, isFalse);
        });
        test('has localId', () async {
          expect(functionSymbol.localId, 'topLevelFunction');
        });
        test('has library scopeId', () async {
          expect(functionSymbol.scopeId, endsWith('package:foo/foo.dart'));
          expect(functionSymbol.scopeId, librarySymbol.id);
        });
        test('no local variables', () async {
          expect(functionSymbol.variableIds, isEmpty);
        });
        test('no scopes', () async {
          expect(functionSymbol.scopeIds, isEmpty);
        });
        group('location', () {
          test('has scriptId', () async {
            expect(functionSymbol.location.scriptId, endsWith('/foo.dart'));
          });
          test('has start token', () async {
            expect(functionSymbol.location.tokenPos,
                source.indexOf('topLevelFunction'));
          });
          test('has end token', () async {
            expect(
                functionSymbol.location.endTokenPos, source.lastIndexOf('}'));
          });
        });
        test('id in LibrarySymbol scopes', () async {
          expect(functionSymbol.id, endsWith('foo.dart|topLevelFunction'));
          expect(functionSymbol.id, librarySymbol.scopeIds.single);
        });
      });
      group('top level private function debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionSymbol;
        LibrarySymbol librarySymbol;
        final source = '''
          ${options.dartLangComment}

          void _topLevelFunction() {
            return;
          }
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          functionSymbol = result.symbols.functions.single;
          librarySymbol = result.symbols.libraries.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('id in LibrarySymbol scopes', () async {
          expect(functionSymbol.id, endsWith('foo.dart|_topLevelFunction'));
          expect(functionSymbol.id, librarySymbol.scopeIds.single);
        });
        test('scopeId is LibrarySymbol id', () async {
          expect(functionSymbol.scopeId, endsWith('package:foo/foo.dart'));
          expect(functionSymbol.scopeId, librarySymbol.id);
        });
      });
      group('top level public getter debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionSymbol;
        LibrarySymbol librarySymbol;
        final source = '''
          ${options.dartLangComment}

          String get topLevelGetter => 'Cello';
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          functionSymbol = result.symbols.functions.single;
          librarySymbol = result.symbols.libraries.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('id in LibrarySymbol scopes', () async {
          expect(functionSymbol.id, endsWith('foo.dart|topLevelGetter'));
          expect(functionSymbol.id, librarySymbol.scopeIds.single);
        });
        test('scopeId is LibrarySymbol id', () async {
          expect(functionSymbol.scopeId, endsWith('package:foo/foo.dart'));
          expect(functionSymbol.scopeId, librarySymbol.id);
        });
        test('is static', () async {
          expect(functionSymbol.isStatic, isTrue);
        });
      });
      group('top level private getter debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionSymbol;
        LibrarySymbol librarySymbol;
        final source = '''
          ${options.dartLangComment}

          String get _topLevelGetter => 'Cello';
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          functionSymbol = result.symbols.functions.single;
          librarySymbol = result.symbols.libraries.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('id in LibrarySymbol scopes', () async {
          expect(functionSymbol.id, endsWith('foo.dart|_topLevelGetter'));
          expect(functionSymbol.id, librarySymbol.scopeIds.single);
        });
        test('scopeId is LibrarySymbol id', () async {
          expect(functionSymbol.scopeId, endsWith('package:foo/foo.dart'));
          expect(functionSymbol.scopeId, librarySymbol.id);
        });
        test('is static', () async {
          expect(functionSymbol.isStatic, isTrue);
        });
      });
      group('top level public setter debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionSymbol;
        LibrarySymbol librarySymbol;
        final source = '''
          ${options.dartLangComment}
          var _value;
          set topLevelSetter(String v) => _value = v;
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          functionSymbol = result.symbols.functions.single;
          librarySymbol = result.symbols.libraries.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('id in LibrarySymbol scopes', () async {
          expect(functionSymbol.id, endsWith('foo.dart|topLevelSetter'));
          expect(functionSymbol.id, librarySymbol.scopeIds.single);
        });
        test('scopeId is LibrarySymbol id', () async {
          expect(functionSymbol.scopeId, endsWith('package:foo/foo.dart'));
          expect(functionSymbol.scopeId, librarySymbol.id);
        });
        test('is static', () async {
          expect(functionSymbol.isStatic, isTrue);
        });
      });
      group('top level private setter debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionSymbol;
        LibrarySymbol librarySymbol;
        final source = '''
          ${options.dartLangComment}

          var _value;
          set _topLevelSetter(String v) => _value = v;
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          functionSymbol = result.symbols.functions.single;
          librarySymbol = result.symbols.libraries.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('id in LibrarySymbol scopes', () async {
          expect(functionSymbol.id, endsWith('foo.dart|_topLevelSetter'));
          expect(functionSymbol.id, librarySymbol.scopeIds.single);
        });
        test('scopeId is LibrarySymbol id', () async {
          expect(functionSymbol.scopeId, endsWith('package:foo/foo.dart'));
          expect(functionSymbol.scopeId, librarySymbol.id);
        });
        test('is static', () async {
          expect(functionSymbol.isStatic, isTrue);
        });
      });
      group('function arguments debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionWithPositionalArgSymbol;
        FunctionSymbol functionWithOptionalArgSymbol;
        FunctionSymbol functionWithNamedArgSymbol;
        VariableSymbol xSymbol;
        VariableSymbol ySymbol;
        VariableSymbol zSymbol;
        final source = '''
          ${options.dartLangComment}

          class A {
            const A();
          }
          const a = A();
          void functionWithPositionalArg(A x) {}
          void functionWithOptionalArg([A y = a]) {}
          void functionWithNamedArg({A z = a}) {}
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          functionWithPositionalArgSymbol = result.symbols.functions
              .singleWhere((f) => f.name == 'functionWithPositionalArg');
          functionWithOptionalArgSymbol = result.symbols.functions
              .singleWhere((f) => f.name == 'functionWithOptionalArg');
          functionWithNamedArgSymbol = result.symbols.functions
              .singleWhere((f) => f.name == 'functionWithNamedArg');
          xSymbol = result.symbols.variables.singleWhere((v) => v.name == 'x');
          ySymbol = result.symbols.variables.singleWhere((v) => v.name == 'y');
          zSymbol = result.symbols.variables.singleWhere((v) => v.name == 'z');
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('function has a variable id for positional argument', () async {
          var argumentId = functionWithPositionalArgSymbol.variableIds.single;
          expect(argumentId, endsWith('|x'));
          expect(argumentId, xSymbol.id);
        });
        test('positional argument symbol has a function scope', () async {
          expect(xSymbol.scopeId, endsWith('|functionWithPositionalArg'));
          expect(xSymbol.scopeId, functionWithPositionalArgSymbol.id);
        });
        test('function has a variable id for optional argument', () async {
          var argumentId = functionWithOptionalArgSymbol.variableIds.single;
          expect(argumentId, endsWith('|y'));
          expect(argumentId, ySymbol.id);
        });
        test('optional argument symbol has a function scope', () async {
          expect(ySymbol.scopeId, endsWith('|functionWithOptionalArg'));
          expect(ySymbol.scopeId, functionWithOptionalArgSymbol.id);
        });
        test('function has a variable id for named argument', () async {
          var argumentId = functionWithNamedArgSymbol.variableIds.single;
          expect(argumentId, endsWith('|z'));
          expect(argumentId, zSymbol.id);
        });
        test('named argument symbol has a function scope', () async {
          expect(zSymbol.scopeId, endsWith('|functionWithNamedArg'));
          expect(zSymbol.scopeId, functionWithNamedArgSymbol.id);
        });
      });
      group('function local variable debug symbols', () {
        TestDriver driver;
        FunctionSymbol functionSymbol;
        VariableSymbol variableSymbol;
        final source = '''
          ${options.dartLangComment}

          int topLevelFunction() {
            int i = 42;
            return i;
          }
          ''';
        setUpAll(() async {
          driver = TestDriver(options, source);
          var result = await driver.compile();
          variableSymbol = result.symbols.variables.single;
          functionSymbol = result.symbols.functions.single;
        });
        tearDownAll(() {
          driver.cleanUp();
        });
        test('local variableId in FunctionSymbol', () async {
          expect(variableSymbol.id, endsWith('|i'));
          expect(variableSymbol.id, functionSymbol.variableIds.single);
        });
        test('scopeId is FunctionSymbol id', () async {
          expect(variableSymbol.scopeId, endsWith('|topLevelFunction'));
          expect(variableSymbol.scopeId, functionSymbol.id);
        });
      });
    });
  }
}
