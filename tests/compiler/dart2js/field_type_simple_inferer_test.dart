// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../sdk/lib/_internal/compiler/implementation/types/types.dart'
    show TypeMask;

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
  return check(compiler.typesTask.typesInferrer, member);
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

void doTest(String test, bool disableInlining, Map<String, Function> fields) {
  fields.forEach((String name, Function f) {
    compileAndFind(
      test,
      'A',
      name,
      disableInlining,
      (inferrer, field) {
        TypeMask type = f(inferrer);
        TypeMask inferredType = inferrer.typeOf[field];
        Expect.equals(type, inferredType);
    });
  });
}

void runTest(String test, Map<String, Function> fields) {
  doTest(test, false, fields);
  doTest(test, true, fields);
}

void test() {
  runTest(TEST_1, {'f': (inferrer) => inferrer.nullType});
  runTest(TEST_2, {'f1': (inferrer) => inferrer.nullType,
                   'f2': (inferrer) => inferrer.intType});
  runTest(TEST_3, {'f1': (inferrer) => inferrer.intType,
                   'f2': (inferrer) => inferrer.intType.nullable()});
  runTest(TEST_4, {'f1': (inferrer) => inferrer.giveUpType,
                   'f2': (inferrer) => inferrer.stringType.nullable()});

  // TODO(ngeoffray): We should try to infer that the initialization
  // code at the declaration site of the fields does not matter.
  runTest(TEST_5, {'f1': (inferrer) => inferrer.giveUpType,
                   'f2': (inferrer) => inferrer.giveUpType});
  runTest(TEST_6, {'f1': (inferrer) => inferrer.giveUpType,
                   'f2': (inferrer) => inferrer.giveUpType});
  runTest(TEST_7, {'f1': (inferrer) => inferrer.giveUpType,
                   'f2': (inferrer) => inferrer.giveUpType});

  runTest(TEST_8, {'f': (inferrer) => inferrer.stringType.nullable()});
  runTest(TEST_9, {'f': (inferrer) => inferrer.stringType.nullable()});
  runTest(TEST_10, {'f': (inferrer) => inferrer.giveUpType});
  runTest(TEST_11, {'fs': (inferrer) => inferrer.intType});

  // TODO(ngeoffray): We should try to infer that the initialization
  // code at the declaration site of the fields does not matter.
  runTest(TEST_12, {'fs': (inferrer) => inferrer.giveUpType});

  runTest(TEST_13, {'fs': (inferrer) => inferrer.intType});
  runTest(TEST_14, {'f': (inferrer) => inferrer.intType});
  runTest(TEST_15, {'f': (inferrer) {
                            ClassElement cls =
                                inferrer.compiler.backend.jsIndexableClass;
                            return new TypeMask.nonNullSubtype(cls.rawType);
                         }});
  runTest(TEST_16, {'f': (inferrer) => inferrer.giveUpType});
  runTest(TEST_17, {'f': (inferrer) => inferrer.intType.nullable()});
  runTest(TEST_18, {'f1': (inferrer) => inferrer.intType,
                    'f2': (inferrer) => inferrer.stringType,
                    'f3': (inferrer) => inferrer.dynamicType});
  runTest(TEST_19, {'f1': (inferrer) => inferrer.intType,
                    'f2': (inferrer) => inferrer.stringType,
                    'f3': (inferrer) => inferrer.dynamicType});
}

void main() {
  test();
}
