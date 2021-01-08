// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  void method();
  int get getter;
  void set setter(int value);
  int field;
  final int finalField;
}

class SuperAbstract {
  noSuchMethod(Invocation invocation);
}

class FromSuperAbstract extends SuperAbstract implements Interface {}

class SuperConcrete {
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

class FromSuperConcrete extends SuperConcrete implements Interface {}

class FromSuperConcreteAbstract extends SuperConcrete
    implements SuperAbstract, Interface {}

class MixinAbstract {
  noSuchMethod(Invocation invocation);
}

class FromMixinAbstract extends MixinAbstract implements Interface {}

class MixinConcrete {
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

class FromMixinConcrete with MixinConcrete implements Interface {}

class FromMixinConcreteAbstract
    with MixinConcrete, MixinAbstract
    implements Interface {}

class InterfaceAbstract {
  noSuchMethod(Invocation invocation);
}

class FromInterfaceAbstract implements InterfaceAbstract, Interface {}

class InterfaceConcrete {
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

class FromInterfaceConcrete implements InterfaceConcrete, Interface {}

class DeclaredAbstract implements Interface {
  noSuchMethod(Invocation invocation);
}

class DeclaredConcrete implements Interface {
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

main() {}
