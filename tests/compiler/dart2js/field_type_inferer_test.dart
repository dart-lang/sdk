// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:uri';

import '../../../sdk/lib/_internal/compiler/implementation/js_backend/js_backend.dart';
import '../../../sdk/lib/_internal/compiler/implementation/ssa/ssa.dart';
import '../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart';

import 'compiler_helper.dart';
import 'parser_helper.dart';

void compileAndFind(String code,
                    String className,
                    String memberName,
                    bool disableInlining,
                    check(compiler, element)) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(code, uri);
  compiler.runCompiler(uri);
  compiler.disableInlining = disableInlining;
  var cls = findElement(compiler, className);
  var member = cls.lookupMember(buildSourceString(memberName));
  return check(compiler.backend, member);
}

const String TEST_1 = r"""
  class A {
    int f;
  }
  main() { new A(); }
""";

const String TEST_2 = r"""
  class A {
    int f1;
    int f2 = 1;
  }
  main() { new A(); }
""";

const String TEST_3 = r"""
  class A {
    int f1;
    int f2;
    A() : f1 = 1;
  }
  main() { new A().f2 = 2; }
""";

const String TEST_4 = r"""
  class A {
    int f1;
    int f2;
    A() : f1 = 1;
  }
  main() {
    A a = new A();
    a.f1 = "a";
    a.f2 = "a";
  }
""";

const String TEST_5 = r"""
  class A {
    int f1 = 1;
    int f2 = 1;
    A(x) {
      f1 = "1";
      if (x) {
        f2 = "1";
      } else {
        f2 = "2";
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_6 = r"""
  class A {
    int f1 = 1;
    int f2 = 1;
    A(x) {
      f1 = "1";
      if (x) {
        f2 = "1";
      } else {
        f2 = "2";
      }
      if (x) {
        f2 = new List();
      } else {
        f2 = new List();
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_7 = r"""
  class A {
    int f1 = 1;
    int f2 = 1;
    A(x) {
      f1 = "1";
      if (x) {
        f2 = "1";
      } else {
        f2 = "2";
      }
      if (x) {
        f1 = new List();
        f2 = new List();
      } else {
        f2 = new List();
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_8 = r"""
  class A {
    int f;
    A(x) {
      if (x) {
        f = "1";
      } else {
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_9 = r"""
  class A {
    int f;
    A(x) {
      if (x) {
      } else {
        f = "1";
      }
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

const String TEST_10 = r"""
  class A {
    int f;
    A() {
      f = 1;
    }
    m() => f + 1;
  }
  void f(x) { x.f = "2"; }
  main() {
    A a;
    f(a);
    a = new A();
    a.m();
  }
""";


const String TEST_11 = r"""
  class S {
    int fs = 1;
    ms() { fs = 1; }
  }

  class A extends S {
    m() { ms(); }
  }

  main() {
    A a = new A();
    a.m();
  }
""";

const String TEST_12 = r"""
  class S {
    int fs = 1;
    S() { fs = "2"; }
  }

  class A extends S {
  }

  main() {
    A a = new A();
  }
""";

const String TEST_13 = r"""
  class S {
    int fs;
    S() { fs = 1; }
  }

  class A extends S {
    A() { fs = 1; }
  }

  main() {
    A a = new A();
  }
""";

const String TEST_14 = r"""
  class A {
    var f;
    A() { f = 1; }
    A.other() { f = 2; }
  }

  main() {
    A a = new A();
    a = new A.other();
  }
""";

const String TEST_15 = r"""
  class A {
    var f;
    A() { f = "1"; }
    A.other() { f = new List(); }
  }

  main() {
    A a = new A();
    a = new A.other();
  }
""";

const String TEST_16 = r"""
  class A {
    var f;
    A() { f = "1"; }
    A.other() : f = 1 { }
  }

  main() {
    A a = new A();
    a = new A.other();
  }
""";

const String TEST_17 = r"""
  g([p]) => p.f = 1;
  class A {
    var f;
    A(x) {
      var a;
      if (x) {
        a = this;
      } else {
        a = g;
      }
      a();
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

// In this test this is only used in a field set (f3 = a) and therefore we infer
// types for f1, f2 and f3.
const String TEST_18 = r"""
  class A {
    var f1;
    var f2;
    var f3;
    A(x) {
      f1 = 1;
      var a;
      if (x) {
        f2 = "1";
        a = this;
      } else {
        a = 1;
        f2 = "1";
      }
      f3 = a;
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

// In this test this is exposed through a(), and therefore we don't infer
// any types.
const String TEST_19 = r"""
  class A {
    var f1;
    var f2;
    var f3;
    A(x) {
      f1 = 1;
      var a;
      if (x) {
        f2 = "1";
        a = this;
      } else {
        a = 1;
        f2 = "1";
      }
      f3 = a;
      a();
    }
  }
  main() {
    new A(true);
    new A(false);
  }
""";

void doTest(String test, bool disableInlining, Map<String, HType> fields) {
  fields.forEach((String name, HType type) {
    compileAndFind(
      test,
      'A',
      name,
      disableInlining,
      (backend, field) {
        HType inferredType = backend.optimisticFieldType(field);
        Expect.equals(type, inferredType);
    });
  });
}

void runTest(String test, Map<String, HType> fields) {
  doTest(test, false, fields);
  doTest(test, true, fields);
}

void test() {
  runTest(TEST_1, {'f': HType.NULL});
  runTest(TEST_2, {'f1': HType.NULL, 'f2': HType.INTEGER});
  runTest(TEST_3, {'f1': HType.INTEGER, 'f2': HType.INTEGER_OR_NULL});
  runTest(TEST_4, {'f1': HType.UNKNOWN, 'f2': HType.STRING_OR_NULL});
  runTest(TEST_5, {'f1': HType.STRING, 'f2': HType.STRING});
  runTest(TEST_6, {'f1': HType.STRING, 'f2': HType.EXTENDABLE_ARRAY});
  runTest(TEST_7, {'f1': HType.INDEXABLE_PRIMITIVE,
                   'f2': HType.EXTENDABLE_ARRAY});
  runTest(TEST_8, {'f': HType.UNKNOWN});
  runTest(TEST_9, {'f': HType.UNKNOWN});
  runTest(TEST_10, {'f': HType.UNKNOWN});
  runTest(TEST_11, {'fs': HType.INTEGER});
  runTest(TEST_12, {'fs': HType.STRING});
  // TODO(sgjesse): We should actually infer int.
  runTest(TEST_13, {'fs': HType.UNKNOWN});
  // TODO(sgjesse): We should actually infer int.
  runTest(TEST_14, {'f': HType.UNKNOWN});
  runTest(TEST_15, {'f': HType.UNKNOWN});
  runTest(TEST_16, {'f': HType.UNKNOWN});
  runTest(TEST_17, {'f': HType.UNKNOWN});
  runTest(TEST_18, {'f1': HType.INTEGER,
                    'f2': HType.STRING,
                    'f3': HType.UNKNOWN});
  runTest(TEST_19, {'f1': HType.UNKNOWN,
                    'f2': HType.UNKNOWN,
                    'f3': HType.UNKNOWN});
}

void main() {
  test();
}
