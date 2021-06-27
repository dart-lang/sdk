// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  num extendedMethod() => 0;
}

class Mixin {
  num mixedInMethod() => 0;
}

abstract class Interface1 {
  int extendedMethod();
  int mixedInMethod();
}

abstract class Interface2 extends Super with Mixin {
  int extendedMethod();
  int mixedInMethod();
}

class ClassExtends extends Super with Mixin implements Interface1 {}

class ClassExtendsWithNoSuchMethod extends Super
    with Mixin
    implements Interface1 {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class ClassImplements implements Interface2 {}

class ClassImplementsWithNoSuchMethod implements Interface2 {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class ClassDeclaresExtends extends Super with Mixin {
  int extendedMethod();
  int mixedInMethod();
}

class ClassDeclaresExtendsWithNoSuchMethod extends Super with Mixin {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  int extendedMethod();
  int mixedInMethod();
}

class ClassDeclaresImplementsWithNoSuchMethod implements Super, Mixin {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  int extendedMethod();
  int mixedInMethod();
}

main() {}
