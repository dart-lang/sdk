// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

Future dummyImplTest() async {
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
  await compiler.run(uri);
  Expect.isFalse(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.defaultImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest2() async {
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
  await compiler.run(uri);
  Expect.isFalse(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.defaultImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest3() async {
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
  await compiler.run(uri);
  Expect.isFalse(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.defaultImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest4() async {
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
  await compiler.run(uri);
  Expect.isFalse(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.defaultImpls
      .contains(clsA.lookupMember('noSuchMethod')));
  ClassElement clsB = findElement(compiler, 'B');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.defaultImpls
      .contains(clsB.lookupMember('noSuchMethod')));
}

Future dummyImplTest5() async {
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
  await compiler.run(uri);
  Expect.isTrue(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.throwingImpls
      .contains(clsA.lookupMember('noSuchMethod')));
  ClassElement clsB = findElement(compiler, 'B');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.throwingImpls
      .contains(clsB.lookupMember('noSuchMethod')));
}

Future dummyImplTest6() async {
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
  await compiler.run(uri);
  Expect.isTrue(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.otherImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest7() async {
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
  await compiler.run(uri);
  Expect.isFalse(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.defaultImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest8() async {
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
  await compiler.run(uri);
  Expect.isTrue(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.otherImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest9() async {
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
  await compiler.run(uri);
  Expect.isFalse(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.notApplicableImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest10() async {
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
  await compiler.run(uri);
  Expect.isTrue(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.throwingImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest11() async {
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
  await compiler.run(uri);
  Expect.isTrue(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.otherImpls
      .contains(clsA.lookupMember('noSuchMethod')));
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.complexNoReturnImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest12() async {
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
  await compiler.run(uri);
  Expect.isTrue(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.otherImpls
      .contains(clsA.lookupMember('noSuchMethod')));
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.complexReturningImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

Future dummyImplTest13() async {
  String source = """
class A {
  noSuchMethod(x) => super.noSuchMethod(x) as dynamic;
}
main() {
  print(new A().foo());
}
""";
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(source, uri);
  await compiler.run(uri);
  Expect.isFalse(compiler.backend.enabledNoSuchMethod);
  ClassElement clsA = findElement(compiler, 'A');
  Expect.isTrue(compiler.backend.noSuchMethodRegistry.defaultImpls
      .contains(clsA.lookupMember('noSuchMethod')));
}

main() {
  asyncTest(() async {
    await dummyImplTest();
    await dummyImplTest2();
    await dummyImplTest3();
    await dummyImplTest4();
    await dummyImplTest5();
    await dummyImplTest6();
    await dummyImplTest7();
    await dummyImplTest8();
    await dummyImplTest9();
    await dummyImplTest10();
    await dummyImplTest11();
    await dummyImplTest12();
    await dummyImplTest13();
  });
}
