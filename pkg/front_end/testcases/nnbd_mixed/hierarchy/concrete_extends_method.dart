// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ConcreteSuper {
  void extendedConcreteMethod() {}

  void extendedAbstractMethod();

  void declaredConcreteExtendsConcreteMethod() {}

  void declaredAbstractExtendsConcreteMethod() {}

  void declaredConcreteExtendsAbstractMethod();

  void declaredAbstractExtendsAbstractMethod();
}

class ConcreteClass extends ConcreteSuper {
  void declaredConcreteMethod() {}

  void declaredAbstractMethod();

  void declaredConcreteExtendsConcreteMethod() {}

  void declaredAbstractExtendsConcreteMethod();

  void declaredConcreteExtendsAbstractMethod() {}

  void declaredAbstractExtendsAbstractMethod();
}

main() {}
