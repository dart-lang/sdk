// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Factory constructors, member bodies and the bounds of the type parameters of
// a class are not member signatures, so variance modifiers don't restrict the
// positions of type parameters in them.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

class OutFactory<out T> {
  final Object? value;
  OutFactory._(this.value);
  factory OutFactory(T x) => OutFactory<T>._(x);
}

class InFactory<in T> {
  final Object? value;
  InFactory._(this.value);
  factory InFactory(void Function(T) f) => InFactory<T>._(f);
}

class OutBodies<out T> {
  bool test(Object? o) {
    bool local(T x) => true;
    void Function(T)? function;
    return o is T && local(o) && function == null;
  }
}

class InBodies<in T> {
  Object? test(T x) {
    T identity(T y) => y;
    T variable = identity(x);
    return variable;
  }
}

class OutBound<out T extends Comparable<T>>;

class InBound<in T, out U extends List<T>>;

void function(int x) {}

void main() {
  Expect.equals(1, OutFactory<int>(1).value);
  Expect.identical(function, InFactory<int>(function).value);

  Expect.isTrue(OutBodies<int>().test(1));
  Expect.equals(1, InBodies<int>().test(1));

  Expect.type<OutBound<String>>(OutBound<String>());
  Expect.type<InBound<int, List<int>>>(InBound<int, List<int>>());
}
