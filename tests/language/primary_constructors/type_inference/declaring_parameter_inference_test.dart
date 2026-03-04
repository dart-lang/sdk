// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for type inference of declaring parameters in primary constructors,
// including override inference and inference from default values.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';
import "package:expect/static_type_helper.dart";

class A {
  int x = 0;
  String y = '';
}

class InitializingExtends(this.x, this.y) extends A {
  // `x` infers `int` from `A.x`.
  final x;

  // `y` infers `String` from `A.y`.
  var y;

  set x(num _) {}
}

class DeclaringExtends(final x, var y) extends A {
  // `x` infers `int` from `A.x`.
  // `y` infers `String` from `A.y`.
  set x(num _) {}
}

// Infer from default values.
class DefaultValues(
  [
    final x = 1, // int
    var y = 'string', // String
    final z = null, // Object?
  ]
);

// `Object?` is the default when no default value is provided.
class NoDefaultValue(final x, var y);

abstract class SimpleInterface {
  int get x;
  String get y;
  set y(String value);
}

// Inference from `implements`.
class Implements(final x, var y) implements SimpleInterface;

// Inference from `implements` of a mixin with `on` clause.
mixin MixinOn on SimpleInterface {}
class ImplementsMixinOn(final x, var y) implements MixinOn;

mixin SimpleMixin {
  int get x;
  String get y;
  set y(String value);
}

// Inference from `with`.
class With(final x, var y) with SimpleMixin;

X expectContextType<X>(Type type, {required dynamic value}) {
  Expect.equals(X, type);
  return value;
}

void main() {
  var initializingExtends = InitializingExtends(1, 's');
  initializingExtends.x.expectStaticType<Exactly<int>>();
  initializingExtends.y.expectStaticType<Exactly<String>>();
  initializingExtends.x = expectContextType(num, value: 1);

  var declaringExtends = DeclaringExtends(1, 's');
  declaringExtends.x.expectStaticType<Exactly<int>>();
  declaringExtends.y.expectStaticType<Exactly<String>>();
  declaringExtends.x = expectContextType(num, value: 1);

  var defaultValues = DefaultValues();
  defaultValues.x.expectStaticType<Exactly<int>>();
  defaultValues.y.expectStaticType<Exactly<String>>();
  defaultValues.z.expectStaticType<Exactly<Object?>>();

  var noDefaultValue = NoDefaultValue(1, 's');
  noDefaultValue.x.expectStaticType<Exactly<Object?>>();
  noDefaultValue.y.expectStaticType<Exactly<Object?>>();

  var implements = Implements(1, 's');
  implements.y.expectStaticType<Exactly<String>>();

  var implementsMixin = ImplementsMixinOn(1, 's');
  implementsMixin.x.expectStaticType<Exactly<int>>();
  implementsMixin.y.expectStaticType<Exactly<String>>();

  var withMixin = With(1, 's');
  withMixin.x.expectStaticType<Exactly<int>>();
  withMixin.y.expectStaticType<Exactly<String>>();
}
