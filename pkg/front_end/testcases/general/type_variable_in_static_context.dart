// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef A<T> = Class<T>;

typedef B<T extends num> = Class<T>;

class Class<T> {
  const Class();

  @T()
  static T? method0<S extends T>(T arg) {
    T? local;
    T;
    void fun<U extends T>() {}
  }

  @Class<T>()
  static Class<T>? method1<S extends Class<T>>(Class<T> arg) {
    Class<T>? local;
    new Class<T>();
    Class<T>;
    Class<T>.new;
    void fun<U extends Class<T>>() {}
  }

  @Class<Class<T>>()
  static Class<Class<T>>? method2<S extends Class<Class<T>>>(Class<Class<T>> arg) {
    Class<Class<T>>? local;
    new Class<Class<T>>();
    Class<Class<T>>;
    Class<Class<T>>.new;
    void fun<U extends Class<Class<T>>>() {}
  }

  @A<T>()
  static A<T>? method3<S extends A<T>>(A<T> arg) {
    A<T>? local;
    new A<T>();
    A<T>;
    A<T>.new;
    void fun<U extends A<T>>() {}
  }

  @A<A<T>>()
  static A<A<T>>? method4<S extends A<A<T>>>(A<A<T>> arg) {
    A<A<T>>? local;
    new A<A<T>>();
    A<A<T>>;
    A<A<T>>.new;
    void fun<U extends A<A<T>>>() {}
  }

  @B<T>()
  static B<T>? method5<S extends B<T>>(B<T> arg) {
    B<T>? local;
    new B<T>();
    B<T>;
    B<T>.new;
    void fun<U extends B<T>>() {}
  }

  @A<B<T>>()
  static A<B<T>>? method6<S extends A<B<T>>>(A<B<T>> arg) {
    A<B<T>>? local;
    new A<B<T>>();
    A<B<T>>;
    A<B<T>>.new;
    void fun<U extends A<B<T>>>() {}
  }

  @Class<void Function<S extends T>()>()
  static void Function<S extends T>()? method7<U extends void Function<S extends T>()>(void Function<S extends T>() arg) {
    void Function<S extends T>()? local;
    void fun<V extends void Function<S extends T>()>() {}
  }

  @T()
  static T field0;

  @Class<T>()
  static Class<T>? field1;

  @Class<Class<T>>()
  static Type field2 = T;

  @A<T>()
  static Type field3 = Class<T>;

  @B<T>()
  static var field4 = (T t) => T;

  @T()
  final T? instanceField;

  @T()
  T instanceMethod<S extends T>(T t) {
    T;
    return t;
  }
}

extension Extension<T> on T {
  Extension(T t);

  factory Extension.fact(T t) => null;

  @T()
  static T field0;

  @T()
  T field1;

  @T()
  static T? staticMethod<S extends T>(T arg) {
    T? local;
    T;
    void fun<U extends T>() {}
  }

  @T()
  T instanceMethod<S extends T>(T t) {
    T;
    return t;
  }
}

mixin Mixin<T> {
  Mixin(T t);

  factory Mixin.fact(T t) => null;

  @T()
  static T field0;

  @T()
  static T? staticMethod<S extends T>(T arg) {
    T? local;
    T;
    void fun<U extends T>() {}
  }

  @T()
  T? instanceField;

  @T()
  T instanceMethod<S extends T>(T t) {
    T;
    return t;
  }
}

main() {}