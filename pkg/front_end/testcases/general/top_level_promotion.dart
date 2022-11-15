// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Class1 {
  String get field1;
}

abstract class Class2<V> {}

typedef Function1<O, I> = Class2<O>? Function(I i);

class Class3<V, D> {}

extension Extension1<V> on Class2<V> {
  Class3<M, V> method1<M>(Function1<M, V> f) {
    throw '';
  }
}

class Class4<K, V> {
  Class2<V> operator [](K key) => throw '';
}

class Class5 {
  late final field2 = Class4<String?, bool>();
  late final field3 =
      getter1.method1((o) => o != null ? field2[o.field1] : null);

  method2() {
    late final local1 =
        getter1.method1((o) => o != null ? field2[o.field1] : null);
  }

  Class2<Class1?> get getter1 => throw '';
}
