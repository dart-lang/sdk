// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

typedef Typedef1<
        T1 extends F, // Error
        T2 extends F<dynamic>, // Ok
        T3 extends F<Class>, // Ok
        T4 extends F<Class<dynamic>>, // Ok
        T5 extends F<ConcreteClass>, // Ok
        T6 extends F<Class<ConcreteClass>>, // Ok
        T7 extends F<Object>, // Error
        T8 extends F<int>, // Error
        S1 extends G, // Error
        S2 extends G<dynamic>, // Ok
        S3 extends G<Class>, // Ok
        S4 extends G<Class<dynamic>>, // Ok
        S5 extends G<ConcreteClass>, // Ok
        S6 extends G<Class<ConcreteClass>>, // Ok
        S7 extends G<Object>, // Error
        S8 extends G<int> // Error
        >
    = void Function();

typedef Typedef2 = void Function<
    T1 extends F, // Error
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Ok
    T4 extends F<Class<dynamic>>, // Ok
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Error
    S2 extends G<dynamic>, // Ok
    S3 extends G<Class>, // Ok
    S4 extends G<Class<dynamic>>, // Ok
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    >();

typedef void Typedef3<
    T1 extends F, // Error
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Ok
    T4 extends F<Class<dynamic>>, // Ok
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Error
    S2 extends G<dynamic>, // Ok
    S3 extends G<Class>, // Ok
    S4 extends G<Class<dynamic>>, // Ok
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    >();

class Class1<
    T1 extends F, // Error
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Ok
    T4 extends F<Class<dynamic>>, // Ok
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Error
    S2 extends G<dynamic>, // Ok
    S3 extends G<Class>, // Ok
    S4 extends G<Class<dynamic>>, // Ok
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    > {}

class Class2<
    T1 extends F, // Error
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Ok
    T4 extends F<Class<dynamic>>, // Ok
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Error
    S2 extends G<dynamic>, // Ok
    S3 extends G<Class>, // Ok
    S4 extends G<Class<dynamic>>, // Ok
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    > = Object with Class;

mixin Mixin1<
    T1 extends F, // Error
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Ok
    T4 extends F<Class<dynamic>>, // Ok
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Error
    S2 extends G<dynamic>, // Ok
    S3 extends G<Class>, // Ok
    S4 extends G<Class<dynamic>>, // Ok
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    > {}

// TODO(johnniwinther): Check/create this type as regular bounded i2b.
enum Enum1<
    T1 extends F, // Error
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Error
    T4 extends F<Class<dynamic>>, // Error
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Error
    S2 extends G<dynamic>, // Error
    S3 extends G<Class>, // Error
    S4 extends G<Class<dynamic>>, // Error
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    > {
  a<
      ConcreteClass,
      ConcreteClass,
      ConcreteClass,
      ConcreteClass,
      ConcreteClass,
      ConcreteClass,
      ConcreteClass,
      ConcreteClass,
      G<ConcreteClass>,
      G<ConcreteClass>,
      G<ConcreteClass>,
      G<ConcreteClass>,
      G<ConcreteClass>,
      G<ConcreteClass>,
      G<ConcreteClass>,
      G<ConcreteClass>>()
}

extension Extension<
    T1 extends F, // Ok
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Ok
    T4 extends F<Class<dynamic>>, // Ok
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Ok
    S2 extends G<dynamic>, // Ok
    S3 extends G<Class>, // Ok
    S4 extends G<Class<dynamic>>, // Ok
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    > on Class {}

void method1<
    T1 extends F, // Error
    T2 extends F<dynamic>, // Ok
    T3 extends F<Class>, // Ok
    T4 extends F<Class<dynamic>>, // Ok
    T5 extends F<ConcreteClass>, // Ok
    T6 extends F<Class<ConcreteClass>>, // Ok
    T7 extends F<Object>, // Error
    T8 extends F<int>, // Error
    S1 extends G, // Error
    S2 extends G<dynamic>, // Ok
    S3 extends G<Class>, // Ok
    S4 extends G<Class<dynamic>>, // Ok
    S5 extends G<ConcreteClass>, // Ok
    S6 extends G<Class<ConcreteClass>>, // Ok
    S7 extends G<Object>, // Error
    S8 extends G<int> // Error
    >() {}

test() {
  void local1<
      T1 extends F, // Ok
      T2 extends F<dynamic>, // Ok
      T3 extends F<Class>, // Ok
      T4 extends F<Class<dynamic>>, // Ok
      T5 extends F<ConcreteClass>, // Ok
      T6 extends F<Class<ConcreteClass>>, // Ok
      T7 extends F<Object>, // Error
      T8 extends F<int>, // Error
      S1 extends G, // Ok
      S2 extends G<dynamic>, // Ok
      S3 extends G<Class>, // Ok
      S4 extends G<Class<dynamic>>, // Ok
      S5 extends G<ConcreteClass>, // Ok
      S6 extends G<Class<ConcreteClass>>, // Ok
      S7 extends G<Object>, // Error
      S8 extends G<int> // Error
      >() {}
  void Function<
      T1 extends F, // Ok
      T2 extends F<dynamic>, // Ok
      T3 extends F<Class>, // Ok
      T4 extends F<Class<dynamic>>, // Ok
      T5 extends F<ConcreteClass>, // Ok
      T6 extends F<Class<ConcreteClass>>, // Ok
      T7 extends F<Object>, // Error
      T8 extends F<int>, // Error
      S1 extends G, // Ok
      S2 extends G<dynamic>, // Ok
      S3 extends G<Class>, // Ok
      S4 extends G<Class<dynamic>>, // Ok
      S5 extends G<ConcreteClass>, // Ok
      S6 extends G<Class<ConcreteClass>>, // Ok
      S7 extends G<Object>, // Error
      S8 extends G<int> // Error
      >() local;
}

main() {}
