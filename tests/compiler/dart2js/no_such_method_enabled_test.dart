// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

dummyImplTest() {
  String source = """
class A {
  foo() => 3;
  noSuchMethod(x) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isFalse(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.defaultImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest2() {
  String source = """
class A extends B {
  foo() => 3;
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B {}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isFalse(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.defaultImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest3() {
  String source = """
class A extends B {
  foo() => 3;
  noSuchMethod(x) {
    return super.noSuchMethod(x);
  }
}
class B {}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isFalse(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.defaultImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest4() {
  String source = """
class A extends B {
  foo() => 3;
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B {
  noSuchMethod(x) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isFalse(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.defaultImpls.contains(
            clsA.lookupMember('noSuchMethod')));
    ClassElement clsB = findElement(compiler, 'B');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.defaultImpls.contains(
            clsB.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest5() {
  String source = """
class A extends B {
  foo() => 3;
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B {
  noSuchMethod(x) => throw 'foo';
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isTrue(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.throwingImpls.contains(
            clsA.lookupMember('noSuchMethod')));
    ClassElement clsB = findElement(compiler, 'B');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.throwingImpls.contains(
            clsB.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest6() {
  String source = """
class A {
  noSuchMethod(x) => 3;
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isTrue(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.otherImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest7() {
  String source = """
class A {
  noSuchMethod(x, [y]) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isFalse(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.defaultImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest8() {
  String source = """
class A {
  noSuchMethod(x, [y]) => super.noSuchMethod(x, y);
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isTrue(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.otherImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest9() {
  String source = """
class A {
  noSuchMethod(x, y) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isTrue(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.otherImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest10() {
  String source = """
class A {
  noSuchMethod(Invocation x) {
    throw new UnsupportedException();
  }
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isTrue(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.throwingImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest11() {
  String source = """
class A {
  noSuchMethod(Invocation x) {
    print('foo');
    throw 'foo';
  }
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isTrue(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.otherImpls.contains(
            clsA.lookupMember('noSuchMethod')));
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.complexNoReturnImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

dummyImplTest12() {
  String source = """
class A {
  noSuchMethod(Invocation x) {
    return toString();
  }
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    Expect.isTrue(compiler.backend.enabledNoSuchMethod);
    ClassElement clsA = findElement(compiler, 'A');
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.otherImpls.contains(
            clsA.lookupMember('noSuchMethod')));
    Expect.isTrue(
        compiler.backend.noSuchMethodRegistry.complexReturningImpls.contains(
            clsA.lookupMember('noSuchMethod')));
  }));
}

main() {
  dummyImplTest();
  dummyImplTest2();
  dummyImplTest3();
  dummyImplTest4();
  dummyImplTest5();
  dummyImplTest6();
  dummyImplTest7();
  dummyImplTest8();
  dummyImplTest9();
  dummyImplTest10();
  dummyImplTest11();
  dummyImplTest12();
}
