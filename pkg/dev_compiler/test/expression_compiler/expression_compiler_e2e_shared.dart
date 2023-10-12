// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

const simpleClassSource = '''
extension NumberParsing on String {
  int parseInt() {
    return int.parse(this) + 1;
  }
}

class C {
  static int staticField = 1;
  static int _staticField = 2;
  static int _unusedStaticField = 3;
  int field;
  int _field;
  int _unusedField = 4;
  final list = <String>[];

  C(this.field, this._field) {
    int y = 1;
    // Breakpoint: constructorBP
    var nop;
  }

  C.named(this.field): _field = 42;

  C.redirecting(int x) : this(x, 99);

  factory C.factory() => C(42, 0);

  int methodFieldAccess(int x) {
    // Breakpoint: methodBP
    var inScope = 1;
    {
      var innerInScope = global + staticField + field;
      // Breakpoint: innerScopeBP
      var innerNotInScope = 2;
    }
    var notInScope = 3;
    return x + _field + _staticField;
  }

  Future<int> asyncMethod(int x) async {
    return x + _field + _staticField;
  }
}

int global = 42;

main() {
  int x = 15;
  var c = C(5, 6);
  // Breakpoint: globalFunctionBP
  c.methodFieldAccess(10);
}

class B {
  int field;
  int _field;

  B(this.field, this._field) {}
}
''';

/// Shared tests that require a language version >=2.12.0 <2.17.0.
// TODO(nshahan) Merge with [runAgnosticSharedTests] after we no longer need to
// test support for evaluation in legacy (pre-null safety) code.
void runNullSafeSharedTests(
    SetupCompilerOptions setup, ExpressionEvaluationTestDriver driver) {
  group('JS interop with static interop', () {
    const interopSource = r'''
      @JS()
      library debug_static_interop;

      import 'dart:html';

      import 'dart:_js_annotations' show staticInterop;
      import 'dart:js_util';
      import 'dart:js_interop';

      @JSExport()
      class Counter {
        int value = 0;
        @JSExport('increment')
        void renamedIncrement() {
          value++;
        }
      }

      @JS()
      @staticInterop
      class JSCounter {}

      extension on JSCounter {
        external int get value;
        external void increment();
      }

      void main() {
        var dartCounter = Counter();
        var jsCounter =
            createDartExport<Counter>(dartCounter) as JSCounter;

        dartCounter.renamedIncrement();
        jsCounter.increment();

        // Breakpoint: bp
        print('jsCounter: ${jsCounter.value}');
      }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, interopSource,
          experiments: {'inline-class': true});
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('call extension methods of existing JS object', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'dartCounter.value',
          expectedResult: '2');

      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'jsCounter.value',
          expectedResult: '2');
    });

    test('call extension methods of a new JS object', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression:
              '(createDartExport<Counter>(dartCounter) as JSCounter).value',
          expectedResult: '2');
    });
  });

  group('JS interop with extension types', () {
    const interopSource = r'''
      @JS()
      library debug_static_interop;

      import 'dart:_js_annotations' show staticInterop;
      import 'dart:js_util';
      import 'dart:js_interop';

      @JSExport()
      class Counter {
        int value = 0;
        @JSExport('increment')
        void renamedIncrement() {
          value++;
        }
      }

      extension type JSCounter(JSObject _) {
        external int get value;
        external void increment();
      }

      void main() {
        var dartCounter = Counter();
        var jsCounter = createDartExport<Counter>(dartCounter) as JSCounter;

        jsCounter.increment();
        dartCounter.renamedIncrement();

        // Breakpoint: bp
        print('JS: ${jsCounter.value}'); // prints '2'
      }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, interopSource,
          experiments: {'inline-class': true});
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('call extension getters on existing JS object', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'dartCounter.value',
          expectedResult: '2');

      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'jsCounter.value',
          expectedResult: '2');
    });

    test('call extension getters on a new JS object', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression:
              'JSCounter(createDartExport<Counter>(dartCounter) as JSObject)'
              '.value',
          expectedResult: '2');
    });
  });

  group('Exceptions', () {
    const exceptionSource = r'''
    void main() {
      try {
        throw Exception('meow!');
      } catch (e, s) {
        // Breakpoint: bp
        print('Cat says: \$e:\$s');
      }
    }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, exceptionSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('error', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'e.toString()',
          expectedResult: 'meow!');
    });

    test('stack trace', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 's.toString()', expectedResult: '');
    });

    test('scope', () async {
      await driver.checkScope(breakpointId: 'bp', expectedScope: {
        'e': 'e',
        's': 's',
      });
    });
  });

  group('Correct null safety mode used', () {
    var source = '''
        const soundNullSafety = !(<Null>[] is List<int>);
        main() {
          // Breakpoint: bp
          print('hello world');
        }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('in original source compilation', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'soundNullSafety',
          expectedResult: setup.soundNullSafety.toString());
    });

    test('in expression compilation', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: '!(<Null>[] is List<int>)',
          expectedResult: setup.soundNullSafety.toString());
    });
  });

  group('Expression compiler tests in a library', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('generic instantiation', () async {
      await driver.check(
          expression: '[B(1,1).toString(), B(2,2).toString()]',
          expectedResult: allOf(
              contains('Array(2)'),
              contains('0: Instance of \'B\''),
              contains('1: Instance of \'B\''),
              contains('length: 2')));
    });
  });

  group('Expression compiler tests in method:', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('tear off default constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'C.new.runtimeType.toString()',
          expectedResult: '(int, int) => C');
    });

    test('call default constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '(C.new)(0, 0)',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 0')));
    });

    test('tear off named constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'C.named.runtimeType.toString()',
          expectedResult: '(int) => C');
    });

    test('call named constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '(C.named)(0)',
          expectedResult: allOf(
              contains('test.C.named'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 42')));
    });

    test('tear off redirecting constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'C.redirecting.runtimeType.toString()',
          expectedResult: '(int) => C');
    });

    test('call redirecting constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '(C.redirecting)(0)',
          expectedResult: allOf(
              contains('test.C.redirecting'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 99')));
    });

    test('tear off factory constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'C.factory.runtimeType.toString()',
          expectedResult: '() => C');
    });

    test('call factory constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '(C.factory)()',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 42'),
              contains('Symbol(_field): 0')));
    });

    test('map access', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '''
            (Map<String, String> params) {
              return params["a"];
            }({"a":"b"})
          ''',
          expectedResult: 'b');
    });
  });

  group('Expression compiler tests in global function:', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('tear off default constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C.new.runtimeType.toString()',
          expectedResult: '(int, int) => C');
    });

    test('call default constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: '(C.new)(0, 0)',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 0')));
    });

    test('tear off named constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C.named.runtimeType.toString()',
          expectedResult: '(int) => C');
    });

    test('call named constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: '(C.named)(0)',
          expectedResult: allOf(
              contains('test.C.named'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 42')));
    });

    test('tear off redirecting constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C.redirecting.runtimeType.toString()',
          expectedResult: '(int) => C');
    });

    test('call redirecting constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: '(C.redirecting)(0)',
          expectedResult: allOf(
              contains('test.C.redirecting'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 99')));
    });

    test('tear off factory constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C.factory.runtimeType.toString()',
          expectedResult: '() => C');
    });

    test('call factory constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: '(C.factory)()',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 42'),
              contains('Symbol(_field): 0')));
    });
  });

  group('Expression compiler tests in constructor:', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('tear off default constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'C.new.runtimeType.toString()',
          expectedResult: '(int, int) => C');
    });

    test('call default constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: '(C.new)(0, 0)',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 0')));
    });

    test('tear off named constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'C.named.runtimeType.toString()',
          expectedResult: '(int) => C');
    });

    test('call named constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: '(C.named)(0)',
          expectedResult: allOf(
              contains('test.C.named'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 42')));
    });

    test('tear off redirecting constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'C.redirecting.runtimeType.toString()',
          expectedResult: '(int) => C');
    });

    test('call redirecting constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: '(C.redirecting)(0)',
          expectedResult: allOf(
              contains('test.C.redirecting'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 0'),
              contains('Symbol(_field): 99')));
    });

    test('tear off factory constructor', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'C.factory.runtimeType.toString()',
          expectedResult: '() => C');
    });

    test('call factory constructor tear off', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: '(C.factory)()',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.list): Array(0)'),
              contains('Symbol(C.field): 42'),
              contains('Symbol(_field): 0')));
    });
  });

  group('Enums', () {
    var source = r'''
      enum E {id1, id2, id3}

      enum E2 {id1, id2, id3}

      main() {
        var e = E.id2;
        // Breakpoint: bp
        print('hello world');
      }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('evaluate to the correct string', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'E.id2.toString()',
          expectedResult: 'E.id2');
    });
    test('evaluate to the correct index', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'E.id3.index', expectedResult: '2');
    });
    test('compare properly against themselves', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'e == E.id2 && E.id2 == E.id2',
          expectedResult: 'true');
    });
    test('compare properly against other enums', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'e != E2.id2 && E.id2 != E2.id2',
          expectedResult: 'true');
    });
    test('scope', () async {
      await driver.checkScope(breakpointId: 'bp', expectedScope: {
        'e': 'e',
      });
    });
  });

  group('Automatically inserted argument null checks', () {
    var source = r'''
      main() {
        // Breakpoint: bp
        print('hello world');
      }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('do not cause a crash in the expression compiler', () async {
      // Compiling an expression that contains a method with a non-nullable
      // parameter was causing a compiler crash due to the lack of a source
      // location and the use of the wrong null literal value. This verifies
      // the expression compiler can safely compile this pattern.
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: '((){bool fn(bool b) {return b;} return fn(true);})()',
          expectedResult: 'true');
    });
  });

  group('Synthetic variables', () {
    var source = r'''
      dynamic couldReturnNull() => null;

      main() {
        var i = couldReturnNull() ?? 10;
        // Breakpoint: bp
        print(i);
      }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('do not cause a crash in the expression compiler', () async {
      // The null aware code in the test source causes the compiler to introduce
      // a let statement that includes a synthetic variable declaration.
      // That variable has no name and was causing a crash in the expression
      // compiler https://github.com/dart-lang/sdk/issues/49373.
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'true', expectedResult: 'true');
    });
  });
}

/// Shared tests that are valid in legacy (before 2.12) and are agnostic to
/// changes in modern versions of Dart.
///
/// Tests that exercise language features introduced strictly before 2.12 are
/// valid here.
///
/// This group of tests has been sharded manually. The others are in
/// [runAgnosticSharedTestsShard2].
void runAgnosticSharedTestsShard1(
    SetupCompilerOptions setup, ExpressionEvaluationTestDriver driver) {
  group('Correct null safety mode used', () {
    var source = '''
        const soundNullSafety = !(<Null>[] is List<int>);
        main() {
          // Breakpoint: bp
          print('hello world');
        }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('in original source compilation', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'soundNullSafety',
          expectedResult: setup.soundNullSafety.toString());
    });

    test('in expression compilation', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: '!(<Null>[] is List<int>)',
          expectedResult: setup.soundNullSafety.toString());
    });
  });

  group('Expression compiler scope collection tests', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('local in scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP',
          expression: 'inScope',
          expectedResult: '1');
    });

    test('local in inner scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP',
          expression: 'innerInScope',
          expectedResult: '48');
    });

    test('global in scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP',
          expression: 'global',
          expectedResult: '42');
    });

    test('static field in scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP',
          expression: 'staticField',
          expectedResult: '1');
    });

    test('field in scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP',
          expression: 'field',
          expectedResult: '5');
    });

    test('parameter in scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP', expression: 'x', expectedResult: '10');
    });

    test('local not in scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP',
          expression: 'notInScope',
          expectedError: "Error: The getter 'notInScope' isn't defined for the"
              " class 'C'.");
    });

    test('local not in inner scope', () async {
      await driver.checkInFrame(
          breakpointId: 'innerScopeBP',
          expression: 'innerNotInScope',
          expectedError:
              "Error: The getter 'innerNotInScope' isn't defined for the"
              " class 'C'.");
    });
  });

  group('Expression compiler extension symbols tests', () {
    var source = '''
        main() {
          List<int> list = [];
          list.add(0);
          // Breakpoint: bp
        }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('extension symbol used only in expression compilation', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'list.first', expectedResult: '0');
    });

    test('extension symbol used in original compilation', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: '() { list.add(1); return list.last; }()',
          expectedResult: '1');
    });
  });

  group('Expression compiler tests in extension method:', () {
    var source = '''
        extension NumberParsing on String {
          int parseInt() {
            var ret = int.parse(this);
            // Breakpoint: bp
            return ret;
          }
        }
        main() => "1234".parseInt();
      ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('compilation error', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'typo',
          expectedError: "Error: Undefined name 'typo'");
    });

    test('local (trimmed scope)', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'ret', expectedResult: '1234');
    });

    test('this (full scope)', () async {
      // Note: this currently fails due to
      // - incremental compiler not mapping 'this' from user input to '#this'
      // - incremental compiler not allowing #this as a parameter name
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'this',
          expectedError: "Error: Expected identifier, but got 'this'");
    });

    test('scope', () async {
      await driver.checkScope(breakpointId: 'bp', expectedScope: {
        r'$this': '\'1234\'',
        'ret': '1234',
      });
    });
  });

  group('Expression compiler tests in static function:', () {
    var source = '''
        int foo(int x, {int y = 0}) {
          int z = 3;
          // Breakpoint: bp
          return x + y + z;
        }

        main() => foo(1, y: 2);
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('compilation error', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'typo',
          expectedError: "Undefined name 'typo'");
    });

    test('local', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'x', expectedResult: '1');
    });

    test('formal', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'y', expectedResult: '2');
    });

    test('named formal', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'z', expectedResult: '3');
    });

    test('function', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'main', expectedResult: '''
              function main() {
                return test.foo(1, {y: 2});
              }''');
    });
  });

  group('Expression compiler tests in method:', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('compilation error', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'typo',
          expectedError: "The getter 'typo' isn't defined for the class 'C'");
    });

    test('local', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP', expression: 'x', expectedResult: '10');
    });

    test('this', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'this',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.field): 5'),
              contains('Symbol(_field): 6')));
    });

    test('expression using locals', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP', expression: 'x + 1', expectedResult: '11');
    });

    test('expression using static fields', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'x + staticField',
          expectedResult: '11');
    });

    test('expression using private static fields', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'x + _staticField',
          expectedResult: '12');
    });

    test('expression using fields', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'x + field',
          expectedResult: '15');
    });

    test('expression using private fields', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'x + _field',
          expectedResult: '16');
    });

    test('expression using globals', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'x + global',
          expectedResult: '52');
    });

    test('expression using fields not referred to in the original code',
        () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '_unusedField + _unusedStaticField',
          expectedResult: '7');
    });

    test('private field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '_field = 2',
          expectedResult: '2');
    });

    test('field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'field = 3',
          expectedResult: '3');
    });

    test('private static field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: '_staticField = 4',
          expectedResult: '4');
    });

    test('static field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'methodBP',
          expression: 'staticField = 5',
          expectedResult: '5');
    });
  });

  group('Expression compiler tests in global function:', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('compilation error', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'typo',
          expectedError: "Undefined name 'typo'.");
    });

    test('local with primitive type', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'x',
          expectedResult: '15');
    });

    test('local object', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'c',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.field): 5'),
              contains('Symbol(_field): 6')));
    });

    test('create new object', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C(3, 4)',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.field): 3'),
              contains('Symbol(_field): 4')));
    });

    test('access field of new object', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C(3, 4)._field',
          expectedResult: '4');
    });

    test('access static field', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C.staticField',
          expectedResult: '1');
    });

    test('expression using private static fields', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C._staticField',
          expectedResult: '2');
    });

    test('access field', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'c.field',
          expectedResult: '5');
    });

    test('access private field', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'c._field',
          expectedResult: '6');
    });

    test('method call', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'c.methodFieldAccess(2)',
          expectedResult: '10');
    });

    test('async method call', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'c.asyncMethod(2).runtimeType.toString()',
          expectedResult: '_Future<int>');
    });

    test('extension method call', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: '"1234".parseInt()',
          expectedResult: '1235');
    });

    test('private field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'c._field = 10',
          expectedResult: '10');
    });

    test('field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'c._field = 11',
          expectedResult: '11');
    });

    test('private static field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C._staticField = 2',
          expectedResult: '2');
    });

    test('static field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'C.staticField = 20',
          expectedResult: '20');
    });

    test('call global function from core library', () async {
      await driver.checkInFrame(
          breakpointId: 'globalFunctionBP',
          expression: 'identical(1, 1)',
          expectedResult: 'true');
    });
  });
}

/// Shared tests that are valid in legacy (before 2.12) and are agnostic to
/// changes in modern versions of Dart.
///
/// Tests that exercise language features introduced strictly before 2.12 are
/// valid here.
///
/// This group of tests has been sharded manually. The others are in
/// [runAgnosticSharedTestsShard1].
void runAgnosticSharedTestsShard2(
    SetupCompilerOptions setup, ExpressionEvaluationTestDriver driver) {
  group('Expression compiler tests in constructor:', () {
    var source = simpleClassSource;

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('compilation error', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'typo',
          expectedError: "The getter 'typo' isn't defined for the class 'C'");
    });

    test('local', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP', expression: 'y', expectedResult: '1');
    });

    test('this', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'this',
          expectedResult: allOf(
              contains('test.C.new'),
              contains('Symbol(_unusedField): 4'),
              contains('Symbol(C.field): 5'),
              contains('Symbol(_field): 6')));
    });

    test('expression using locals', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'y + 1',
          expectedResult: '2');
    });

    test('expression using static fields', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'y + staticField',
          expectedResult: '2');
    });

    test('expression using private static fields', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'y + _staticField',
          expectedResult: '3');
    });

    test('expression using fields', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'y + field',
          expectedResult: '6');
    });

    test('expression using private fields', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'y + _field',
          expectedResult: '7');
    });

    test('expression using globals', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'y + global',
          expectedResult: '43');
    });

    test('method call', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'methodFieldAccess(2)',
          expectedResult: '10');
    });

    test('async method call', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'asyncMethod(2).runtimeType.toString()',
          expectedResult: '_Future<int>');
    });

    test('extension method call', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: '"1234".parseInt()',
          expectedResult: '1235');
    });

    test('private field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: '_field = 2',
          expectedResult: '2');
    });

    test('field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'field = 2',
          expectedResult: '2');
    });

    test('private static field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: '_staticField = 2',
          expectedResult: '2');
    });

    test('static field modification', () async {
      await driver.checkInFrame(
          breakpointId: 'constructorBP',
          expression: 'staticField = 2',
          expectedResult: '2');
    });
  });

  group('Expression compiler tests in async method:', () {
    var source = '''
        class C {
          static int staticField = 1;
          static int _staticField = 2;
          int _field;
          int field;

          C(this.field, this._field);
          Future<int> asyncMethod(int x) async {
            // Breakpoint: bp
            return x + global + _field + field + staticField + _staticField;
          }
        }

        Future<int> entrypoint() async {
          var c = C(5, 7);
          // Breakpoint: bp1
          return await c.asyncMethod(1);
        }

        int global = 42;
        void main() async {
          await entrypoint();
        }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('compilation error', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'typo',
          expectedError: "The getter 'typo' isn't defined for the class 'C'");
    });

    test('local', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'x', expectedResult: '1');
    });

    test('this', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'this',
          expectedResult: allOf(contains('test.C.new'),
              contains('Symbol(C.field): 5'), contains('Symbol(_field): 7')));
    });

    test('awaited method call', () async {
      await driver.checkInFrame(
          breakpointId: 'bp1',
          expression: 'c.asyncMethod(1).runtimeType.toString()',
          expectedResult: '_Future<int>');
    }, skip: "'await' is not yet supported in expression evaluation.");

    test('awaited method call', () async {
      await driver.checkInFrame(
          breakpointId: 'bp1',
          expression: 'await c.asyncMethod(1)',
          expectedResult: '58');
    }, skip: "'await' is not yet supported in expression evaluation.");
  });

  group('Expression compiler tests in closures:', () {
    var source = '''
        void globalFunction() {
        int x = 15;

        var outerClosure = (int y) {
          var closureCaptureInner = (int z) {
            // Breakpoint: bp
            var temp = x + y + z;
            return;
          };
          closureCaptureInner(0);
        };

        outerClosure(3);
        return;
      }

      main() => globalFunction();
      ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('compilation error', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'typo',
          expectedError: "Undefined name 'typo'.");
    });

    test('expression using captured variables', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: r"'$y+$z'", expectedResult: '3+0');
    });

    test('expression using uncaptured variables', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: r"'$x+$y+$z'",
          expectedResult: '15+3+0');
    });
  });

  group('Expression compiler tests in method with no type use:', () {
    var source = '''
        abstract class Key {
          const factory Key(String value) = ValueKey;
          const Key.empty();
        }

        abstract class LocalKey extends Key {
          const LocalKey() : super.empty();
        }

        class ValueKey implements LocalKey {
          const ValueKey(this.value);
          final String value;
        }

        class MyClass {
          const MyClass(this._t);
          final int _t;
        }

        int bar(int p) {
          return p;
        }

        String baz(String t) {
          return t;
        }

        String main() {
          var k = Key('t');
          MyClass c = MyClass(0);
          int p = 1;
          const t = 1;

          // Breakpoint: bp
          return '\$c, \$k, \$t';
        }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('call function not using type', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'bar(p)', expectedResult: '1');
    });

    test('call function using type', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: "baz('\$p')", expectedResult: '1');
    });

    test('evaluate new const expression', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'const MyClass(1)',
          expectedResult: 'MyClass {Symbol(MyClass._t): 1}');
    });

    test('evaluate optimized const expression', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 't', expectedResult: '1');
    },
        skip: 'Cannot compile constants optimized away by the frontend. '
            'Issue: https://github.com/dart-lang/sdk/issues/41999');

    test('evaluate factory constructor call', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: "Key('t')",
          expectedResult: 'test.ValueKey.new {Symbol(ValueKey.value): t}');
    });

    test('evaluate const factory constructor call', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: "const Key('t')",
          expectedResult: 'ValueKey {Symbol(ValueKey.value): t}');
    });
  });

  group('Expression compiler tests in simple loops:', () {
    var source = '''
        void globalFunction() {
          int x = 15;
          for(int i = 0; i < 10; i++) {
            // Breakpoint: bp
            var calculation = '\$i+\$x';
          };
        }

        main() => globalFunction();
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('expression using local', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'x', expectedResult: '15');
    });

    test('expression using loop variable', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'i', expectedResult: '0');
    });
  });

  group('Expression compiler tests in conditional:', () {
    var source = '''
        int globalFunction(int x) {
          if (x == 1) {
            int y = 3;
            // Breakpoint: thenBP
            var calculation = '\$y+\$x';
          } else {
            int z = 4;
            // Breakpoint: elseBP
            var calculation = '\$z+\$x';
          }
          // Breakpoint: postBP
          return 0;
        }

        void main() {
          globalFunction(1);
          globalFunction(2);
        }
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('(then) expression using local', () async {
      await driver.checkInFrame(
          breakpointId: 'thenBP', expression: 'y', expectedResult: '3');
    });

    test('(then) expression using local out of scope', () async {
      await driver.checkInFrame(
          breakpointId: 'thenBP',
          expression: 'z',
          expectedError: "Error: Undefined name 'z'");
    });

    test('(else) expression using local', () async {
      await driver.checkInFrame(
          breakpointId: 'elseBP', expression: 'z', expectedResult: '4');
    });

    test('(else) expression using local out of scope', () async {
      await driver.checkInFrame(
          breakpointId: 'elseBP',
          expression: 'y',
          expectedError: "Error: Undefined name 'y'");
    });

    test('(post) expression using local', () async {
      await driver.checkInFrame(
          breakpointId: 'postBP', expression: 'x', expectedResult: '1');
    });

    test('(post) expression using local out of scope', () async {
      await driver.checkInFrame(
          breakpointId: 'postBP',
          expression: 'z',
          expectedError: "Error: Undefined name 'z'");
    });

    test('(post) expression using local out of scope', () async {
      await driver.checkInFrame(
          breakpointId: 'postBP',
          expression: 'y',
          expectedError: "Error: Undefined name 'y'");
    });
  });

  group('Expression compiler tests in iterator loops:', () {
    var source = '''
        int globalFunction() {
          var l = <String>['1', '2', '3'];

          for (var e in l) {
            // Breakpoint: bp
            var calculation = '\$e';
          };
          return 0;
        }

        main() => globalFunction();
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('expression loop variable', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'e', expectedResult: '1');
    });
  });

  group('Expression compiler tests in generic method:', () {
    var source = '''
        class C<T1> {
          void generic<T2>(T1 a, T2 b) {
            // Breakpoint: bp
            print(a);
            print(b);
          }
        }

        void main() => C<int>().generic<String>(0, 'hi');
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('evaluate formals', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: "'\${a} \$b'",
          expectedResult: '0 hi');
    });

    test('evaluate class type parameters', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: "'\$T1'", expectedResult: 'int');
    });

    test('evaluate method type parameters', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: "'\$T2'", expectedResult: 'String');
    });
  });

  group('Expression compiler tests for interactions with module containers:',
      () {
    var source = '''
        class A {
          const A();
        }
        class B {
          const B();
        }
        void foo() {
          const a = A();
          var check = a is int;
          // Breakpoint: bp
          return;
        }

        void main() => foo();
        ''';

    setUpAll(() async {
      await driver.initSource(setup, source);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    test('evaluation that non-destructively appends to the type container',
        () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'a is String',
          expectedResult: 'false');
    });

    test('evaluation that reuses the type container', () async {
      await driver.checkInFrame(
          breakpointId: 'bp', expression: 'a is int', expectedResult: 'false');
    });

    test('evaluation that non-destructively appends to the constant container',
        () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'const B() == const B()',
          expectedResult: 'true');
    });

    test('evaluation that properly canonicalizes constants', () async {
      await driver.checkInFrame(
          breakpointId: 'bp',
          expression: 'a == const A()',
          expectedResult: 'true');
    });
  });
}
