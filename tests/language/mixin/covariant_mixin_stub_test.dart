// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that implicit covariant type checks in super calls from generic mixin
// forwarding stubs behave properly when type parameters are shuffled.

import "package:expect/expect.dart";

abstract class ClassWithGenericMix<TypeArgA1, TypeArgA2, TypeArgA3>
    extends ClassWithCovariantSuperCall
    with GenericMixWithCovariantOverride<TypeArgA1, TypeArgA3, TypeArgA2> {
  const ClassWithGenericMix({super.key});
}

mixin Mix<TypeArgB1, TypeArgB2, TypeArgB3> on Object {}

class ClassWithCovariantSuperCall extends ConstWrapper {
  const ClassWithCovariantSuperCall({super.key});

  void update(covariant Object obj) {
    print('updated!');
  }
}

mixin GenericMixWithCovariantOverride<TypeArgC1, TypeArgC2, TypeArgC3>
    on ClassWithCovariantSuperCall {
  @override
  void update(Mix<TypeArgC3, TypeArgC1, TypeArgC2> obj);
}

class ConstWrapper {
  final dynamic key;
  const ConstWrapper({this.key});
}

class ClassWithGenericMixImpl extends ClassWithGenericMix<int, String, bool> {
  final ConstWrapper element;

  const ClassWithGenericMixImpl({
    required this.element,
  });
}

class ClassWithMix extends Object with Mix<String, int, bool> {}

void main() {
  var wrapper = const ConstWrapper();
  var impl = ClassWithGenericMixImpl(element: wrapper);
  var mixedIn = ClassWithMix();
  impl.update(mixedIn);

  Expect.equals(impl.element, wrapper);
}
