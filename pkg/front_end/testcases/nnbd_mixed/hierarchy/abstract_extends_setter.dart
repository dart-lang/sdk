// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class AbstractSuper {
  void set extendedConcreteSetter(int value) {}

  void set extendedAbstractSetter(int value);

  void set declaredConcreteExtendsConcreteSetter(int value) {}

  void set declaredAbstractExtendsConcreteSetter(int value) {}

  void set declaredConcreteExtendsAbstractSetter(int value);

  void set declaredAbstractExtendsAbstractSetter(int value);
}

abstract class AbstractClass extends AbstractSuper {
  void set declaredConcreteSetter(int value) {}

  void set declaredAbstractSetter(int value);

  void set declaredConcreteExtendsConcreteSetter(int value) {}

  void set declaredAbstractExtendsConcreteSetter(int value);

  void set declaredConcreteExtendsAbstractSetter(int value) {}

  void set declaredAbstractExtendsAbstractSetter(int value);
}

main() {}
