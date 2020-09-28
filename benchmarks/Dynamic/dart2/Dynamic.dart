// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This benchmark suite measures the overhead of dynamically calling functions
// and closures by calling a set of functions and closures, testing non-dynamic
// calls, calls after casting the function tearoff or closure to dynamic, and
// similarly defined functions and closures except that the parameters and
// return types are all dynamic.

import 'package:benchmark_harness/benchmark_harness.dart';

const int kRepeat = 100;

void main() {
  const NonDynamicFunction().report();
  const NonDynamicFunctionOptSkipped().report();
  const NonDynamicFunctionOptProvided().report();
  const NonDynamicFunctionNamedSkipped().report();
  const NonDynamicFunctionNamedProvided().report();
  const NonDynamicClosure().report();
  const NonDynamicClosureOptSkipped().report();
  const NonDynamicClosureOptProvided().report();
  const NonDynamicClosureNamedSkipped().report();
  const NonDynamicClosureNamedProvided().report();
  const DynamicCastFunction().report();
  const DynamicCastFunctionOptSkipped().report();
  const DynamicCastFunctionOptProvided().report();
  const DynamicCastFunctionNamedSkipped().report();
  const DynamicCastFunctionNamedProvided().report();
  const DynamicCastClosure().report();
  const DynamicCastClosureOptSkipped().report();
  const DynamicCastClosureOptProvided().report();
  const DynamicCastClosureNamedSkipped().report();
  const DynamicCastClosureNamedProvided().report();
  const DynamicDefFunction().report();
  const DynamicDefFunctionOptSkipped().report();
  const DynamicDefFunctionOptProvided().report();
  const DynamicDefFunctionNamedSkipped().report();
  const DynamicDefFunctionNamedProvided().report();
  const DynamicDefClosure().report();
  const DynamicDefClosureOptSkipped().report();
  const DynamicDefClosureOptProvided().report();
  const DynamicDefClosureNamedSkipped().report();
  const DynamicDefClosureNamedProvided().report();
  const DynamicClassASingleton().report();
  const DynamicClassBSingleton().report();
  const DynamicClassCFresh().report();
  const DynamicClassDFresh().report();
}

@pragma('vm:never-inline')
void f1(String s) {}
@pragma('vm:never-inline')
Function(String) c1 = (String s) => {};
@pragma('vm:never-inline')
void f2(String s, [String t = 'default']) {}
@pragma('vm:never-inline')
Function(String, [String]) c2 = (String s, [String t = 'default']) => {};
@pragma('vm:never-inline')
void f3(String s, {String t = 'default'}) {}
@pragma('vm:never-inline')
Function(String, {String t}) c3 = (String s, {String t = 'default'}) => {};
@pragma('vm:never-inline')
dynamic df1 = f1 as dynamic;
@pragma('vm:never-inline')
dynamic dc1 = c1 as dynamic;
@pragma('vm:never-inline')
dynamic df2 = f2 as dynamic;
@pragma('vm:never-inline')
dynamic dc2 = c2 as dynamic;
@pragma('vm:never-inline')
dynamic df3 = f3 as dynamic;
@pragma('vm:never-inline')
dynamic dc3 = c3 as dynamic;
@pragma('vm:never-inline')
dynamic df1NonCast(dynamic s) {}
@pragma('vm:never-inline')
Function dc1NonCast = (dynamic s) => {};
@pragma('vm:never-inline')
dynamic df2NonCast(dynamic s, [dynamic t = 'default']) {}
@pragma('vm:never-inline')
Function dc2NonCast = (dynamic s, [dynamic t = 'default']) => {};
@pragma('vm:never-inline')
dynamic df3NonCast(dynamic s, {dynamic t = 'default'}) {}
@pragma('vm:never-inline')
Function dc3NonCast = (dynamic s, {dynamic t = 'default'}) => {};

class A {
  const A();
}

class B extends A {
  const B();
}

@pragma('vm:never-inline')
dynamic k = (A a) {};

class C {
  C();
}

class D extends C {
  D();
}

@pragma('vm:never-inline')
dynamic j = (C c) {};

class NonDynamicFunction extends BenchmarkBase {
  const NonDynamicFunction() : super('Dynamic.NonDynamicFunction');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      f1('');
    }
  }
}

class NonDynamicClosure extends BenchmarkBase {
  const NonDynamicClosure() : super('Dynamic.NonDynamicClosure');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      c1('');
    }
  }
}

class NonDynamicFunctionOptSkipped extends BenchmarkBase {
  const NonDynamicFunctionOptSkipped()
      : super('Dynamic.NonDynamicFunctionOptSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      f2('');
    }
  }
}

class NonDynamicFunctionOptProvided extends BenchmarkBase {
  const NonDynamicFunctionOptProvided()
      : super('Dynamic.NonDynamicFunctionOptProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      f2('', '');
    }
  }
}

class NonDynamicFunctionNamedSkipped extends BenchmarkBase {
  const NonDynamicFunctionNamedSkipped()
      : super('Dynamic.NonDynamicFunctionNamedSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      f3('');
    }
  }
}

class NonDynamicFunctionNamedProvided extends BenchmarkBase {
  const NonDynamicFunctionNamedProvided()
      : super('Dynamic.NonDynamicFunctionNamedProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      f3('', t: '');
    }
  }
}

class NonDynamicClosureOptSkipped extends BenchmarkBase {
  const NonDynamicClosureOptSkipped()
      : super('Dynamic.NonDynamicClosureOptSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      c2('');
    }
  }
}

class NonDynamicClosureOptProvided extends BenchmarkBase {
  const NonDynamicClosureOptProvided()
      : super('Dynamic.NonDynamicClosureOptProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      c2('', '');
    }
  }
}

class NonDynamicClosureNamedSkipped extends BenchmarkBase {
  const NonDynamicClosureNamedSkipped()
      : super('Dynamic.NonDynamicClosureNamedSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      c3('');
    }
  }
}

class NonDynamicClosureNamedProvided extends BenchmarkBase {
  const NonDynamicClosureNamedProvided()
      : super('Dynamic.NonDynamicClosureNamedProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      c3('', t: '');
    }
  }
}

class DynamicCastFunction extends BenchmarkBase {
  const DynamicCastFunction() : super('Dynamic.DynamicCastFunction');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df1('');
    }
  }
}

class DynamicCastClosure extends BenchmarkBase {
  const DynamicCastClosure() : super('Dynamic.DynamicCastClosure');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc1('');
    }
  }
}

class DynamicCastFunctionOptSkipped extends BenchmarkBase {
  const DynamicCastFunctionOptSkipped()
      : super('Dynamic.DynamicCastFunctionOptSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df2('');
    }
  }
}

class DynamicCastFunctionOptProvided extends BenchmarkBase {
  const DynamicCastFunctionOptProvided()
      : super('Dynamic.DynamicCastFunctionOptProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df2('', '');
    }
  }
}

class DynamicCastFunctionNamedSkipped extends BenchmarkBase {
  const DynamicCastFunctionNamedSkipped()
      : super('Dynamic.DynamicCastFunctionNamedSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df3('');
    }
  }
}

class DynamicCastFunctionNamedProvided extends BenchmarkBase {
  const DynamicCastFunctionNamedProvided()
      : super('Dynamic.DynamicCastFunctionNamedProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df3('', t: '');
    }
  }
}

class DynamicCastClosureOptSkipped extends BenchmarkBase {
  const DynamicCastClosureOptSkipped()
      : super('Dynamic.DynamicCastClosureOptSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc2('');
    }
  }
}

class DynamicCastClosureOptProvided extends BenchmarkBase {
  const DynamicCastClosureOptProvided()
      : super('Dynamic.DynamicCastClosureOptProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc2('', '');
    }
  }
}

class DynamicCastClosureNamedSkipped extends BenchmarkBase {
  const DynamicCastClosureNamedSkipped()
      : super('Dynamic.DynamicCastClosureNamedSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc3('');
    }
  }
}

class DynamicCastClosureNamedProvided extends BenchmarkBase {
  const DynamicCastClosureNamedProvided()
      : super('Dynamic.DynamicCastClosureNamedProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc3('', t: '');
    }
  }
}

class DynamicDefFunction extends BenchmarkBase {
  const DynamicDefFunction() : super('Dynamic.DynamicDefFunction');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df1NonCast('');
    }
  }
}

class DynamicDefClosure extends BenchmarkBase {
  const DynamicDefClosure() : super('Dynamic.DynamicDefClosure');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc1NonCast('');
    }
  }
}

class DynamicDefFunctionOptSkipped extends BenchmarkBase {
  const DynamicDefFunctionOptSkipped()
      : super('Dynamic.DynamicDefFunctionOptSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df2NonCast('');
    }
  }
}

class DynamicDefFunctionOptProvided extends BenchmarkBase {
  const DynamicDefFunctionOptProvided()
      : super('Dynamic.DynamicDefFunctionOptProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df2NonCast('', '');
    }
  }
}

class DynamicDefFunctionNamedSkipped extends BenchmarkBase {
  const DynamicDefFunctionNamedSkipped()
      : super('Dynamic.DynamicDefFunctionNamedSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df3NonCast('');
    }
  }
}

class DynamicDefFunctionNamedProvided extends BenchmarkBase {
  const DynamicDefFunctionNamedProvided()
      : super('Dynamic.DynamicDefFunctionNamedProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      df3NonCast('', t: '');
    }
  }
}

class DynamicDefClosureOptSkipped extends BenchmarkBase {
  const DynamicDefClosureOptSkipped()
      : super('Dynamic.DynamicDefClosureOptSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc2NonCast('');
    }
  }
}

class DynamicDefClosureOptProvided extends BenchmarkBase {
  const DynamicDefClosureOptProvided()
      : super('Dynamic.DynamicDefClosureOptProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc2NonCast('', '');
    }
  }
}

class DynamicDefClosureNamedSkipped extends BenchmarkBase {
  const DynamicDefClosureNamedSkipped()
      : super('Dynamic.DynamicDefClosureNamedSkipped');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc3NonCast('');
    }
  }
}

class DynamicDefClosureNamedProvided extends BenchmarkBase {
  const DynamicDefClosureNamedProvided()
      : super('Dynamic.DynamicDefClosureNamedProvided');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      dc3NonCast('', t: '');
    }
  }
}

class DynamicClassASingleton extends BenchmarkBase {
  final A a;
  const DynamicClassASingleton()
      : a = const A(),
        super('Dynamic.DynamicClassASingleton');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      k(a);
    }
  }
}

class DynamicClassBSingleton extends BenchmarkBase {
  final B b;
  const DynamicClassBSingleton()
      : b = const B(),
        super('Dynamic.DynamicClassBSingleton');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      k(b);
    }
  }
}

class DynamicClassCFresh extends BenchmarkBase {
  const DynamicClassCFresh() : super('Dynamic.DynamicClassCFresh');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      j(C());
    }
  }
}

class DynamicClassDFresh extends BenchmarkBase {
  const DynamicClassDFresh() : super('Dynamic.DynamicClassDFresh');

  @override
  void run() {
    for (int i = 0; i < kRepeat; i++) {
      j(D());
    }
  }
}
