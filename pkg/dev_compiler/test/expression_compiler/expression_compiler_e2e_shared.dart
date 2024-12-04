// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../shared_test_options.dart';
import 'expression_compiler_e2e_suite.dart';

/// Common code used by many of the tests.
///
/// While having a small source file with a small test case side-by-side
/// is a lot more readable, we've found that switching test files adds a big
/// overhead for the test harness. It requires loading a new page in chrome each
/// time, which can easily add seconds to each test, especially on the try bots.
/// Instead, it's cheaper to combine many test cases in a single test file and
/// call `initSource` only once for a large group of tests.
const sharedSource = '''
extension NumberParsing on String {
  int parseIntPlusOne() {
    var ret = int.parse(this);
    // Breakpoint: parseIntPlusOneBP
    return ret + 1;
  }
}

class C {
  static int staticField = 1;
  static int staticFieldB = 1;
  static int staticFieldC = 1;
  static int staticFieldD = 1;
  static int _staticField = 2;
  static int _staticFieldB = 2;
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
late int lateGlobal;
late String lateGlobal2;

const soundNullSafety = !(<Null>[] is List<int>);
soundNullSafetyTest() {
  // Breakpoint: soundNullSafetyBP
  print('hello world');
}

class B {
  int field;
  int _field;

  B(this.field, this._field) {}
}

enum E {id1, id2, id3}

enum E2 {id1, id2, id3}

enumTest() {
  var e = E.id2;
  // Breakpoint: enumBP
  print('hello world');
}

dynamic couldReturnNull() => null;
couldReturnNullTest() {
  var i = couldReturnNull() ?? 10;
  // Breakpoint: couldReturnNullBP
  print(i);
}

extensionsSymbolTest() {
  List<int> list = [];
  list.add(0);
  // Breakpoint: extensionSymbolsBP
  print(list);
}

lateLocalVariableTest() {
  late int lateLocal;
  late int lateLocal2;
  if (42.isEven) {
    lateLocal = 42;
  }
  // Breakpoint: lateLocalVariableBP
  print(lateLocal);
}

lateGlobalVariableTest() {
  if (42.isEven) {
    lateGlobal = 42;
  }
  // Breakpoint: lateGlobalVariableBP
  print(lateGlobal);
}

int foo(int x, {int y = 0}) {
  int z = 3;
  // Breakpoint: fooBP
  return x + y + z;
}

callFooTest() => foo(1, y: 2);

class D {
  static int staticField = 1;
  static int _staticField = 2;
  int _field;
  int field;

  D(this.field, this._field);
  Future<int> asyncMethod(int x) async {
    // Breakpoint: asyncTestBP1
    return x + global + _field + field + staticField + _staticField;
  }
}

Future<int> asyncTest() async {
  var d = D(5, 7);
  // Breakpoint: asyncTestBP2
  return await d.asyncMethod(1);
}

void closuresTest() {
  int x = 15;

  var outerClosure = (int y) {
    var closureCaptureInner = (int z) {
      // Breakpoint: closuresTestBP
      var temp = x + y + z;
      return;
    };
    closureCaptureInner(0);
  };

  outerClosure(3);
  return;
}

// Caution: this test function should not be reused across multiple test cases
// to prevent data races. See http://github.com/dart-lang/sdk/issues/55299 for
// details.
void forLoopTest() {
  int x = 15;
  for(int i = 0; i < 10; i++) {
    // Breakpoint: forLoopTestBP
    var calculation = '\$i+\$x';
  };
}

// Caution: this test function should not be reused across multiple test cases
// to prevent data races. See http://github.com/dart-lang/sdk/issues/55299 for
// details.
int iteratorLoopTest() {
  var l = <String>['1', '2', '3'];

  for (var e in l) {
    // Breakpoint: iteratorLoopTestBP
    var calculation = '\$e';
  };
  return 0;
}

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

missingTypesTest() {
  var k = Key('t');
  MyClass c = MyClass(0);
  int p = 1;
  const t = 1;

  // Breakpoint: missingTypesTestBP
  return '\$c, \$k, \$t';
}

int conditionalHelper(int x) {
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

void conditionalTest() {
  conditionalHelper(1);
  conditionalHelper(2);
}

class G<T1> {
  void generic<T2>(T1 a, T2 b) {
    // Breakpoint: genericBP
    print(a);
    print(b);
  }
}

class M1 {
  const M1();
}
class M2 {
  const M2();
}
void moduleContainersTest() {
  const a = M1();
  var check = a is int;
  // Breakpoint: moduleContainersBP
  return;
}

void exceptionTest() {
  try {
    throw Exception('meow!');
  } catch (e, s) {
    // Breakpoint: exceptionBP
    print('Cat says: \$e:\$s');
  }
}

main() {
  int x = 15;
  var c = C(5, 6);
  // Breakpoint: globalFunctionBP
  c.methodFieldAccess(10);

  enumTest();
  soundNullSafetyTest();
  couldReturnNullTest();
  extensionsSymbolTest();
  lateLocalVariableTest();
  lateGlobalVariableTest();

  "1234".parseIntPlusOne();
  callFooTest();
  asyncTest();
  closuresTest();
  forLoopTest();
  iteratorLoopTest();
  missingTypesTest();
  conditionalTest();
  G<int>().generic<String>(0, 'hi');
  moduleContainersTest();
  exceptionTest();
}
''';

/// Shared tests that require a language version >=2.12.0 <2.17.0.
void runNullSafeSharedTests(
    SetupCompilerOptions setup, ExpressionEvaluationTestDriver driver) {
  group('JS interop', () {
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

      void staticInteropTest() {
        var dartCounter = Counter();
        var jsCounter =
            createDartExport<Counter>(dartCounter) as JSCounter;

        dartCounter.renamedIncrement();
        jsCounter.increment();

        // Breakpoint: staticInteropBP
        print('jsCounter: ${jsCounter.value}'); // prints '2'
      }

      extension type JSCounter2(JSObject _) {
        external int get value;
        external void increment();
      }

      void extensionTypesTest() {
        var dartCounter = Counter();
        var jsCounter = createDartExport<Counter>(dartCounter) as JSCounter2;

        jsCounter.increment();
        dartCounter.renamedIncrement();

        // Breakpoint: extensionTypesBP
        print('JS: ${jsCounter.value}'); // prints '2'
      }

      main() {
        staticInteropTest();
        extensionTypesTest();
      }
    ''';

    setUpAll(() async {
      await driver.initSource(setup, interopSource, experiments: {});
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    group('static interop', () {
      test('call extension methods of existing JS object', () async {
        await driver.checkInFrame(
            breakpointId: 'staticInteropBP',
            expression: 'dartCounter.value',
            expectedResult: '2');

        await driver.checkInFrame(
            breakpointId: 'staticInteropBP',
            expression: 'jsCounter.value',
            expectedResult: '2');
      });

      test('call extension methods of a new JS object', () async {
        await driver.checkInFrame(
            breakpointId: 'staticInteropBP',
            expression:
                '(createDartExport<Counter>(dartCounter) as JSCounter).value',
            expectedResult: '2');
      });
    });

    group('extension types', () {
      test('call extension getters on existing JS object', () async {
        await driver.checkInFrame(
            breakpointId: 'extensionTypesBP',
            expression: 'dartCounter.value',
            expectedResult: '2');

        await driver.checkInFrame(
            breakpointId: 'extensionTypesBP',
            expression: 'jsCounter.value',
            expectedResult: '2');
      });

      test('call extension getters on a new JS object', () async {
        await driver.checkInFrame(
            breakpointId: 'extensionTypesBP',
            expression:
                'JSCounter2(createDartExport<Counter>(dartCounter) as JSObject)'
                '.value',
            expectedResult: '2');
      });
    });
  });

  group('shared sources', () {
    setUpAll(() async {
      await driver.initSource(setup, sharedSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    group('Exceptions', () {
      test('error', () async {
        await driver.checkInFrame(
            breakpointId: 'exceptionBP',
            expression: 'e.toString()',
            expectedResult: 'meow!');
      });

      test('stack trace', () async {
        await driver.checkInFrame(
            breakpointId: 'exceptionBP',
            expression: 's.toString()',
            expectedResult: '');
      });

      test('scope', () async {
        await driver.checkScope(breakpointId: 'exceptionBP', expectedScope: {
          'e': 'e',
          's': 's',
        });
      });
    });

    group('Correct null safety mode used', () {
      test('in original source compilation', () async {
        await driver.checkInFrame(
            breakpointId: 'soundNullSafetyBP',
            expression: 'soundNullSafety',
            expectedResult: setup.soundNullSafety.toString());
      });

      test('in expression compilation', () async {
        await driver.checkInFrame(
            breakpointId: 'soundNullSafetyBP',
            expression: '!(<Null>[] is List<int>)',
            expectedResult: setup.soundNullSafety.toString());
      });
    });

    group('library level', () {
      test('generic instantiation', () async {
        await driver.check(
            expression: '[B(1,1).toString(), B(2,2).toString()]',
            expectedResult: allOf(
                contains('Array(2)'),
                contains('0: Instance of \'B\''),
                contains('1: Instance of \'B\''),
                contains('length: 2')));
      });

      test('invoke an SDK method', () async {
        await driver.check(
            expression: 'Flow.begin(id: 0) is Flow',
            libraryUri: Uri.parse('dart:developer'),
            expectedResult: 'true');
      },
          // The new module format requires a per-library compiler. Since we
          // loaded the SDK from a summary/dill, we've never actually created a
          // compiler for it, and therefore can't execute library-level
          // expression evaluation in the SDK. Currently, no real workflow can
          // meaningfully use this anyways. See
          // https://github.com/flutter/devtools/issues/7766 for the initial
          // motivation.
          skip: setup.emitLibraryBundle);

      test('tearoff an SDK method', () async {
        await driver.check(
            expression: 'postEvent',
            libraryUri: Uri.parse('dart:developer'),
            expectedResult: contains('function postEvent(eventKind'));
      },
          // The new module format requires a per-library compiler. Since we
          // loaded the SDK from a summary/dill, we've never actually created a
          // compiler for it, and therefore can't execute library-level
          // expression evaluation in the SDK. Currently, no real workflow can
          // meaningfully use this anyways. See
          // https://github.com/flutter/devtools/issues/7766 for the initial
          // motivation.
          skip: setup.emitLibraryBundle);
    });

    group('method level', () {
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

    group('top-level method', () {
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

    group('constructors', () {
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

    group('enums', () {
      test('evaluate to the correct string', () async {
        await driver.checkInFrame(
            breakpointId: 'enumBP',
            expression: 'E.id2.toString()',
            expectedResult: 'E.id2');
      });
      test('evaluate to the correct index', () async {
        await driver.checkInFrame(
            breakpointId: 'enumBP',
            expression: 'E.id3.index',
            expectedResult: '2');
      });
      test('compare properly against themselves', () async {
        await driver.checkInFrame(
            breakpointId: 'enumBP',
            expression: 'e == E.id2 && E.id2 == E.id2',
            expectedResult: 'true');
      });
      test('compare properly against other enums', () async {
        await driver.checkInFrame(
            breakpointId: 'enumBP',
            expression: 'e != E2.id2 && E.id2 != E2.id2',
            expectedResult: 'true');
      });
      test('scope', () async {
        await driver.checkScope(breakpointId: 'enumBP', expectedScope: {
          'e': 'e',
        });
      });
    });

    group('late', () {
      group('local', () {
        test(
          'can be evaluated when initialized',
          () async {
            await driver.checkInFrame(
                breakpointId: 'lateLocalVariableBP',
                expression: 'lateLocal',
                expectedResult: '42');
          },
        );
        test('does not throw when evaluated and not initialized', () async {
          // It isn't clear if this is expected to work or not, the behavior is
          // somewhat undefined for the debugger. At this time we expose the
          // backing storage variable that can be displayed or might be null if
          // uninitialized.
          // See https://github.com/dart-lang/sdk/issues/55918
          await driver.checkInFrame(
              breakpointId: 'lateLocalVariableBP',
              expression: 'lateLocal2',
              expectedResult: 'null');
        });
        test('throws when not initialized and used in method call', () async {
          // It isn't clear if this is expected to work or not, the behavior is
          // somewhat undefined for the debugger. At this time we expose the
          // backing storage variable that can be displayed or might be null if
          // uninitialized.
          // See https://github.com/dart-lang/sdk/issues/55918
          await driver.checkInFrame(
              breakpointId: 'lateLocalVariableBP',
              expression: 'lateLocal2.isEven',
              expectedError: "Error: Property 'isEven' cannot be accessed on "
                  "'int?' because it is potentially null.");
        });
      });
      group('global', () {
        test('can be evaluated when initialized', () async {
          await driver.checkInFrame(
              breakpointId: 'lateGlobalVariableBP',
              expression: 'lateGlobal',
              expectedResult: '42');
        });
        test('throws when not initialized', () async {
          await driver.checkInFrame(
              breakpointId: 'lateGlobalVariableBP',
              expression: 'lateGlobal2',
              expectedError: 'Error: LateInitializationError: '
                  "Field 'lateGlobal2' has not been initialized.");
        });
      });
    });

    group('regression', () {
      test('don\'t crash on implicit null checks', () async {
        // Compiling an expression that contains a method with a non-nullable
        // parameter was causing a compiler crash due to the lack of a source
        // location and the use of the wrong null literal value. This verifies
        // the expression compiler can safely compile this pattern.
        await driver.checkInFrame(
            breakpointId: 'globalFunctionBP',
            expression: '((){bool fn(bool b) {return b;} return fn(true);})()',
            expectedResult: 'true');
      });

      test('don\'t crash on synthetic variables', () async {
        // The null aware code in the test source causes the compiler to
        // introduce a let statement that includes a synthetic variable
        // declaration.  That variable has no name and was causing a crash in
        // the expression compiler
        // https://github.com/dart-lang/sdk/issues/49373.
        await driver.checkInFrame(
            breakpointId: 'couldReturnNullBP',
            expression: 'true',
            expectedResult: 'true');
      });
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
  group('shared source', () {
    setUpAll(() async {
      await driver.initSource(setup, sharedSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    group('Correct null safety mode used', () {
      test('in original source compilation', () async {
        await driver.checkInFrame(
            breakpointId: 'soundNullSafetyBP',
            expression: 'soundNullSafety',
            expectedResult: setup.soundNullSafety.toString());
      });

      test('in expression compilation', () async {
        await driver.checkInFrame(
            breakpointId: 'soundNullSafetyBP',
            expression: '!(<Null>[] is List<int>)',
            expectedResult: setup.soundNullSafety.toString());
      });
    });

    group('scope collection', () {
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
            breakpointId: 'innerScopeBP',
            expression: 'x',
            expectedResult: '10');
      });

      test('local not in scope', () async {
        await driver.checkInFrame(
            breakpointId: 'innerScopeBP',
            expression: 'notInScope',
            expectedError:
                "Error: The getter 'notInScope' isn't defined for the"
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

    group('ddc-extension symbols', () {
      test('extension symbol used only in expression compilation', () async {
        await driver.checkInFrame(
            breakpointId: 'extensionSymbolsBP',
            expression: 'list.first',
            expectedResult: '0');
      });

      test('extension symbol used in original compilation', () async {
        await driver.checkInFrame(
            breakpointId: 'extensionSymbolsBP',
            expression: '() { list.add(1); return list.last; }()',
            expectedResult: '1');
      });
    });

    group('Expression compiler tests in extension method:', () {
      test('compilation error', () async {
        await driver.checkInFrame(
            breakpointId: 'parseIntPlusOneBP',
            expression: 'typo',
            expectedError: "Error: The getter 'typo' isn't defined");
      });

      test('local (trimmed scope)', () async {
        await driver.checkInFrame(
            breakpointId: 'parseIntPlusOneBP',
            expression: 'ret',
            expectedResult: '1234');
      });

      test('this (full scope)', () async {
        await driver.checkInFrame(
            breakpointId: 'parseIntPlusOneBP',
            expression: 'this',
            expectedResult: '1234');
      });

      test('scope', () async {
        await driver
            .checkScope(breakpointId: 'parseIntPlusOneBP', expectedScope: {
          r'$this': '\'1234\'',
          'ret': '1234',
        });
      });
    });

    group('Expression compiler tests in static function:', () {
      test('compilation error', () async {
        await driver.checkInFrame(
            breakpointId: 'fooBP',
            expression: 'typo',
            expectedError: "Undefined name 'typo'");
      });

      test('local', () async {
        await driver.checkInFrame(
            breakpointId: 'fooBP', expression: 'x', expectedResult: '1');
      });

      test('formal', () async {
        await driver.checkInFrame(
            breakpointId: 'fooBP', expression: 'y', expectedResult: '2');
      });

      test('named formal', () async {
        await driver.checkInFrame(
            breakpointId: 'fooBP', expression: 'z', expectedResult: '3');
      });

      test('function', () async {
        await driver.checkInFrame(
            breakpointId: 'fooBP',
            expression: 'callFooTest',
            expectedResult: '''
              function callFooTest() {
                return test.foo(1, {y: 2});
              }''');
      });
    });

    group('method level', () {
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
            breakpointId: 'methodBP',
            expression: 'x + 1',
            expectedResult: '11');
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
            expression: '_staticFieldB = 4',
            expectedResult: '4');
      });

      test('static field modification', () async {
        await driver.checkInFrame(
            breakpointId: 'methodBP',
            expression: 'staticFieldB = 5',
            expectedResult: '5');
      });
    });

    group('global function', () {
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
            expression: '"1234".parseIntPlusOne()',
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
            expression: 'C.staticFieldC = 20',
            expectedResult: '20');
      });

      test('call global function from core library', () async {
        await driver.checkInFrame(
            breakpointId: 'globalFunctionBP',
            expression: 'identical(1, 1)',
            expectedResult: 'true');
      });
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
  group('shared source', () {
    setUpAll(() async {
      await driver.initSource(setup, sharedSource);
    });

    tearDownAll(() async {
      await driver.cleanupTest();
    });

    group('constructor', () {
      test('compilation error', () async {
        await driver.checkInFrame(
            breakpointId: 'constructorBP',
            expression: 'typo',
            expectedError: "The getter 'typo' isn't defined for the class 'C'");
      });

      test('local', () async {
        await driver.checkInFrame(
            breakpointId: 'constructorBP',
            expression: 'y',
            expectedResult: '1');
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
            expression: '"1234".parseIntPlusOne()',
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
            expression: 'staticFieldD = 2',
            expectedResult: '2');
      });
    });

    group('async methods', () {
      test('compilation error', () async {
        await driver.checkInFrame(
            breakpointId: 'asyncTestBP1',
            expression: 'typo',
            expectedError: "The getter 'typo' isn't defined for the class 'D'");
      });

      test('local', () async {
        await driver.checkInFrame(
            breakpointId: 'asyncTestBP1', expression: 'x', expectedResult: '1');
      });

      test('this', () async {
        await driver.checkInFrame(
            breakpointId: 'asyncTestBP1',
            expression: 'this',
            expectedResult: allOf(contains('test.D.new'),
                contains('Symbol(D.field): 5'), contains('Symbol(_field): 7')));
      });

      test('awaited method call', () async {
        await driver.checkInFrame(
            breakpointId: 'asyncTestBP2',
            expression: 'd.asyncMethod(1).runtimeType.toString()',
            expectedResult: '_Future<int>');
      }, skip: "'await' is not yet supported in expression evaluation.");

      test('awaited method call', () async {
        await driver.checkInFrame(
            breakpointId: 'asyncTestBP2',
            expression: 'await d.asyncMethod(1)',
            expectedResult: '58');
      }, skip: "'await' is not yet supported in expression evaluation.");
    });

    group('closures', () {
      test('compilation error', () async {
        await driver.checkInFrame(
            breakpointId: 'closuresTestBP',
            expression: 'typo',
            expectedError: "Undefined name 'typo'.");
      });

      test('expression using captured variables', () async {
        await driver.checkInFrame(
            breakpointId: 'closuresTestBP',
            expression: r"'$y+$z'",
            expectedResult: '3+0');
      });

      test('expression using uncaptured variables', () async {
        await driver.checkInFrame(
            breakpointId: 'closuresTestBP',
            expression: r"'$x+$y+$z'",
            expectedResult: '15+3+0');
      });
    });

    group('method not already loading the types needed', () {
      test('call function not using type', () async {
        await driver.checkInFrame(
            breakpointId: 'missingTypesTestBP',
            expression: 'bar(p)',
            expectedResult: '1');
      });

      test('call function using type', () async {
        await driver.checkInFrame(
            breakpointId: 'missingTypesTestBP',
            expression: "baz('\$p')",
            expectedResult: '1');
      });

      test('evaluate new const expression', () async {
        await driver.checkInFrame(
            breakpointId: 'missingTypesTestBP',
            expression: 'const MyClass(1)',
            expectedResult: 'MyClass {Symbol(MyClass._t): 1}');
      });

      test('evaluate optimized const expression', () async {
        await driver.checkInFrame(
            breakpointId: 'missingTypesTestBP',
            expression: 't',
            expectedResult: '1');
      },
          skip: 'Cannot compile constants optimized away by the frontend. '
              'Issue: https://github.com/dart-lang/sdk/issues/41999');

      test('evaluate factory constructor call', () async {
        await driver.checkInFrame(
            breakpointId: 'missingTypesTestBP',
            expression: "Key('t')",
            expectedResult: 'test.ValueKey.new {Symbol(ValueKey.value): t}');
      });

      test('evaluate const factory constructor call', () async {
        await driver.checkInFrame(
            breakpointId: 'missingTypesTestBP',
            expression: "const Key('t')",
            expectedResult: 'ValueKey {Symbol(ValueKey.value): t}');
      });
    });

    group('simple loops', () {
      // Caution: this breakpoint should not be reused across multiple test
      // cases to prevent data races. See
      // http://github.com/dart-lang/sdk/issues/55299 for details.
      test('expression using local & loop var', () async {
        await driver.checkInFrame(
            breakpointId: 'forLoopTestBP',
            expression: r'"$x + $i"',
            expectedResult: '15 + 0');
      });
    });

    group('conditional:', () {
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

    group('iterator loops', () {
      // Caution: this breakpoint should not be reused across multiple test
      // cases to prevent data races. See
      // http://github.com/dart-lang/sdk/issues/55299 for details.
      test('expression loop variable', () async {
        await driver.checkInFrame(
            breakpointId: 'iteratorLoopTestBP',
            expression: 'e',
            expectedResult: '1');
      });
    });

    group('generic method', () {
      test('evaluate formals', () async {
        await driver.checkInFrame(
            breakpointId: 'genericBP',
            expression: "'\${a} \$b'",
            expectedResult: '0 hi');
      });

      test('evaluate class type parameters', () async {
        await driver.checkInFrame(
            breakpointId: 'genericBP',
            expression: "'\$T1'",
            expectedResult: 'int');
      });

      test('evaluate method type parameters', () async {
        await driver.checkInFrame(
            breakpointId: 'genericBP',
            expression: "'\$T2'",
            expectedResult: 'String');
      });
    });

    group('interactions with module containers', () {
      test('evaluation that non-destructively appends to the type container',
          () async {
        await driver.checkInFrame(
            breakpointId: 'moduleContainersBP',
            expression: 'a is String',
            expectedResult: 'false');
      });

      test('evaluation that reuses the type container', () async {
        await driver.checkInFrame(
            breakpointId: 'moduleContainersBP',
            expression: 'a is int',
            expectedResult: 'false');
      });

      test(
          'evaluation that non-destructively appends to the constant container',
          () async {
        await driver.checkInFrame(
            breakpointId: 'moduleContainersBP',
            expression: 'const M2() == const M2()',
            expectedResult: 'true');
      });

      test('evaluation that properly canonicalizes constants', () async {
        await driver.checkInFrame(
            breakpointId: 'moduleContainersBP',
            expression: 'a == const M1()',
            expectedResult: 'true');
      });
    });
  });
}
