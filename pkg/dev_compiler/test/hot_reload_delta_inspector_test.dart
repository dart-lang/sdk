// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/kernel/hot_reload_delta_inspector.dart';
import 'package:kernel/ast.dart';
import 'package:test/test.dart';

import 'memory_compiler.dart';

Future<void> main() async {
  group('const classes', () {
    final deltaInspector = HotReloadDeltaInspector();
    test('rejection when removing only const constructor', () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s;
            const A(this.s);
          }

          main() {
            globalVariable = const A('hello');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s;
            A(this.s);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) =
          await compileComponents(initialSource, deltaSource);
      expect(
          deltaInspector.compareGenerations(initial, delta),
          unorderedEquals([
            'Const class cannot become non-const: '
                "Library:'memory:///main.dart' "
                'Class: A'
          ]));
    });
    test('multiple rejections when removing only const constructors', () async {
      final initialSource = '''
          var globalA, globalB, globalC, globalD;

          class A {
            final String s;
            const A(this.s);
          }

          class B {
            final String s;
            const B(this.s);
          }

          class C {
            final String s;
            C(this.s);
          }

          class D {
            final String s;
            const D(this.s);
          }

          main() {
            globalA = const A('hello');
            globalB = const B('world');
            globalC = C('hello');
            globalD = const D('world');
            print(globalA.s);
            print(globalB.s);
            print(globalC.s);
            print(globalD.s);
          }
          ''';
      final deltaSource = '''
          var globalA, globalB, globalC, globalD;

          class A {
            final String s;
            A(this.s);
          }

          class B {
            final String s;
            const B(this.s);
          }

          class C {
            final String s;
            C(this.s);
          }

          class D {
            final String s;
            D(this.s);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) =
          await compileComponents(initialSource, deltaSource);
      expect(
          deltaInspector.compareGenerations(initial, delta),
          unorderedEquals([
            'Const class cannot become non-const: '
                "Library:'memory:///main.dart' "
                'Class: A',
            'Const class cannot become non-const: '
                "Library:'memory:///main.dart' "
                'Class: D'
          ]));
    });

    test('no error when removing const constructor while adding another',
        () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s;
            const A(this.s);
          }

          main() {
            globalVariable = const A('hello');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s;
            A(this.s);
            const A.named(this.s);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) =
          await compileComponents(initialSource, deltaSource);
      expect(deltaInspector.compareGenerations(initial, delta), isEmpty);
    });
    test('rejection when removing a field', () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s, t, w;
            const A(this.s, this.t, this.w);
          }

          main() {
            globalVariable = const A('hello', 'world', '!');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s, t;
            const A(this.s, this.t);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) =
          await compileComponents(initialSource, deltaSource);
      expect(
          deltaInspector.compareGenerations(initial, delta),
          unorderedEquals([
            'Const class cannot remove fields: '
                "Library:'memory:///main.dart' Class: A"
          ]));
    });
    test('rejection when removing a field while adding another', () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s, t, w;
            const A(this.s, this.t, this.w);
          }

          main() {
            globalVariable = const A('hello', 'world', '!');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s, t, x;
            const A(this.s, this.t, this.x);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) =
          await compileComponents(initialSource, deltaSource);
      expect(
          deltaInspector.compareGenerations(initial, delta),
          unorderedEquals([
            'Const class cannot remove fields: '
                "Library:'memory:///main.dart' Class: A"
          ]));
    });
    test('no error when removing field while also making class const',
        () async {
      final initialSource = '''
          var globalVariable;

          class A {
            final String s, t, w;
            A(this.s, this.t, this.w);
          }

          main() {
            globalVariable = A('hello', 'world', '!');
            print(globalVariable.s);
          }
          ''';
      final deltaSource = '''
          var globalVariable;

          class A {
            final String s, t;
            const A(this.s, this.t);
          }

          main() {
            print('hello world');
          }
          ''';
      final (:initial, :delta) =
          await compileComponents(initialSource, deltaSource);
      expect(() => deltaInspector.compareGenerations(initial, delta),
          returnsNormally);
    });
  });
}

/// Test only helper compiles [initialSource] and [deltaSource] and returns two
/// kernel components.
Future<({Component initial, Component delta})> compileComponents(
    String initialSource, String deltaSource) async {
  final fileName = 'main.dart';
  final fileUri = Uri(scheme: 'memory', host: '', path: fileName);
  final memoryFileMap = {fileName: initialSource};
  final initialResult = await componentFromMemory(memoryFileMap, fileUri);
  expect(initialResult.errors, isEmpty,
      reason: 'Initial source produced compile time errors.');
  memoryFileMap[fileName] = deltaSource;
  final deltaResult = await componentFromMemory(memoryFileMap, fileUri);
  expect(deltaResult.errors, isEmpty,
      reason: 'Delta source produced compile time errors.');
  return (
    initial: initialResult.ddcResult.component,
    delta: deltaResult.ddcResult.component
  );
}
