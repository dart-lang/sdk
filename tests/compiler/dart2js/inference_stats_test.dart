// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Dsend_stats=true

/// Tests that we compute send metrics correctly in many simple scenarios.
library dart2js.test.send_measurements_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:dart2js_info/info.dart';
import 'memory_compiler.dart';
import 'dart:io';

main() {
  test('nothing is reachable, nothing to count', () {
    return _check('''
      main() {}
      test() { int x = 3; }
      ''');
  });

  test('local variable read', () {
    return _check('''
      main() => test();
      test() { int x = 3; int y = x; }
      ''',
      localSend: 1); // from `int y = x`;
  });

  test('generative constructor call', () {
    return _check('''
      class A {
        get f => 1;
      }
      main() => test();
      test() { new A(); }
      ''',
      constructorSend: 1);  // from new A()
  });

  group('instance call', () {
    test('monomorphic only one implementor', () {
      return _check('''
        class A {
          get f => 1;
        }
        main() => test();
        test() { new A().f; }
        ''',
        constructorSend: 1, // new A()
        instanceSend: 1);   // f resolved to A.f
    });

    test('monomorphic only one type possible from types', () {
      return _check('''
        class A {
          get f => 1;
        }
        class B extends A {
          get f => 1;
        }
        main() => test();
        test() { new B().f; }
        ''',
        constructorSend: 1,
        instanceSend: 1); // f resolved to B.f
    });

    test('monomorphic only one type possible from liveness', () {
      return _check('''
        class A {
          get f => 1;
        }
        class B extends A {
          get f => 1;
        }
        main() => test();
        test() { A x = new B(); x.f; }
        ''',
        constructorSend: 1, // new B()
        localSend: 1,       // x in x.f
        instanceSend: 1);  // x.f known to resolve to B.f
    });

    test('monomorphic one possible, more than one live', () {
      return _check('''
        class A {
          get f => 1;
        }
        class B extends A {
          get f => 1;
        }
        main() { new A(); test(); }
        test() { B x = new B(); x.f; }
        ''',
        constructorSend: 1, // new B()
        localSend: 1,       // x in x.f
        instanceSend: 1);   // x.f resolves to B.f
    });

    test('polymorphic-virtual couple possible types from liveness', () {
        // Note: this would be an instanceSend if we used the inferrer.
      return _check('''
        class A {
          get f => 1;
        }
        class B extends A {
          get f => 1;
        }
        main() { new A(); test(); }
        test() { A x = new B(); x.f; }
        ''',
        constructorSend: 1, // new B()
        localSend: 1,       // x in x.f
        virtualSend: 1);    // x.f may be A.f or B.f (types alone is not enough)
    });

    test("polymorphic-dynamic: type annotations don't help", () {
      return _check('''
        class A {
          get f => 1;
        }
        class B extends A {
          get f => 1;
        }
        main() { new A(); test(); }
        test() { var x = new B(); x.f; }
        ''',
        constructorSend: 1, // new B()
        localSend: 1,       // x in x.f
        dynamicSend: 1);    // x.f could be any `f` or no `f`
    });
  });

  group('instance this call', () {
    test('monomorphic only one implementor', () {
      return _check('''
        class A {
          get f => 1;
          test() => this.f;
        }
        main() => new A().test();
        ''',
        instanceSend: 1);   // this.f resolved to A.f
    });

    test('monomorphic only one type possible from types & liveness', () {
      return _check('''
        class A {
          get f => 1;
          test() => this.f;
        }
        class B extends A {
          get f => 1;
        }
        main() => new B().test();
        ''',
        instanceSend: 1); // this.f resolved to B.f
    });

    test('polymorphic-virtual couple possible types from liveness', () {
        // Note: this would be an instanceSend if we used the inferrer.
      return _check('''
        class A {
          get f => 1;
          test() => this.f;
        }
        class B extends A {
          get f => 1;
        }
        main() { new A(); new B().test(); }
        ''',
        virtualSend: 1);    // this.f may be A.f or B.f
    });
  });

  group('noSuchMethod', () {
    test('error will be thrown', () {
      return _check('''
        class A {
        }
        main() { test(); }
        test() { new A().f; }
        ''',
        constructorSend: 1, // new B()
        nsmErrorSend: 1);   // f not there, A has no nSM
    });

    test('nSM will be called - one option', () {
      return _check('''
        class A {
          noSuchMethod(i) => null;
        }
        main() { test(); }
        test() { new A().f; }
        ''',
        constructorSend: 1,    // new B()
        singleNsmCallSend: 1); // f not there, A has nSM
    });

    // TODO(sigmund): is it worth splitting multiNSMvirtual?
    test('nSM will be called - multiple options', () {
      return _check('''
        class A {
          noSuchMethod(i) => null;
        }
        class B extends A {
          noSuchMethod(i) => null;
        }
        main() { new A(); test(); }
        test() { A x = new B(); x.f; }
        ''',
        constructorSend: 1,   // new B()
        localSend: 1,         // x in x.f
        multiNsmCallSend: 1); // f not there, A has nSM
    });

    // TODO(sigmund): is it worth splitting multiNSMvirtual?
    test('nSM will be called - multiple options', () {
      return _check('''
        class A {
          noSuchMethod(i) => null;
        }
        class B extends A {
          // don't count A's nsm as distinct
        }
        main() { new A(); test(); }
        test() { A x = new B(); x.f; }
        ''',
        constructorSend: 1,    // new B()
        localSend: 1,          // x in x.f
        singleNsmCallSend: 1); // f not there, A has nSM
    });

    test('nSM will be called - multiple options', () {
      return _check('''
        class A {
          noSuchMethod(i) => null;
        }
        class B extends A {
          get f => null;
        }
        main() { new A(); test(); }
        test() { A x = new B(); x.f; }
        ''',
        constructorSend: 1,   // new B()
        localSend: 1,         // x in x.f
        dynamicSend: 1);      // f not known to be there there, A has nSM
    });

    test('nSM in super', () {
      return _check('''
        class A {
          noSuchMethod(i) => null;
        }
        class B extends A {
          get f => super.f;
        }
        main() { new A(); test(); }
        test() { A x = new B(); x.f; }
        ''',
        singleNsmCallSend: 1, //   super.f
        testMethod: 'f');
    });
  });
}


/// Checks that the `test` function in [code] produces the given distribution of
/// sends.
_check(String code, {int staticSend: 0, int superSend: 0, int localSend: 0,
    int constructorSend: 0, int typeVariableSend: 0, int nsmErrorSend: 0,
    int singleNsmCallSend: 0, int instanceSend: 0, int interceptorSend: 0,
    int multiNsmCallSend: 0, int virtualSend: 0, int multiInterceptorSend: 0,
    int dynamicSend: 0, String testMethod: 'test'}) async {

  // Set up the expectation.
  var expected = new Measurements();
  int monomorphic = staticSend + superSend + localSend + constructorSend +
    typeVariableSend + nsmErrorSend + singleNsmCallSend + instanceSend +
    interceptorSend;
  int polymorphic = multiNsmCallSend + virtualSend + multiInterceptorSend +
    dynamicSend;

  expected.counters[Metric.monomorphicSend] = monomorphic;
  expected.counters[Metric.staticSend] = staticSend;
  expected.counters[Metric.superSend] = superSend;
  expected.counters[Metric.localSend] = localSend;
  expected.counters[Metric.constructorSend] = constructorSend;
  expected.counters[Metric.typeVariableSend] = typeVariableSend;
  expected.counters[Metric.nsmErrorSend] = nsmErrorSend;
  expected.counters[Metric.singleNsmCallSend] = singleNsmCallSend;
  expected.counters[Metric.instanceSend] = instanceSend;
  expected.counters[Metric.interceptorSend] = interceptorSend;

  expected.counters[Metric.polymorphicSend] = polymorphic;
  expected.counters[Metric.multiNsmCallSend] = multiNsmCallSend;
  expected.counters[Metric.virtualSend] = virtualSend;
  expected.counters[Metric.multiInterceptorSend] = multiInterceptorSend;
  expected.counters[Metric.dynamicSend] = dynamicSend;

  expected.counters[Metric.send] = monomorphic + polymorphic;

  // Run the compiler to get the results.
  var all = await _compileAndGetStats(code);
  var function = all.functions.firstWhere((f) => f.name == testMethod,
      orElse: () => null);
  var result = function?.measurements;
  if (function == null) {
    expect(expected.counters[Metric.send], 0);
    return;
  }

  expect(result, isNotNull);

  _compareMetric(Metric key) {
    var expectedValue = expected.counters[key];
    var value = result.counters[key];
    if (value == null) value = 0;
    if (value == expectedValue) return;
    expect(expectedValue, value,
        reason: "count for `$key` didn't match:\n"
        "expected measurements:\n${recursiveDiagnosticString(expected, key)}\n"
        "actual measurements:\n${recursiveDiagnosticString(result, key)}");
  }

  _compareMetric(Metric.send);
  expected.counters.keys.forEach(_compareMetric);
}

/// Helper that runs the compiler and returns the [GlobalResult] computed for
/// it.
Future<AllInfo> _compileAndGetStats(String program) async {
  var result = await runCompiler(
      memorySourceFiles: {'main.dart': program}, options: ['--dump-info']);
  expect(result.compiler.compilationFailed, isFalse);
  return result.compiler.dumpInfoTask.infoCollector.result;
}
