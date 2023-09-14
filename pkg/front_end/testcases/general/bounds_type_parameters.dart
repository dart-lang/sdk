// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

class H<X extends (Class<X>, int)> {}

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
        S8 extends G<int>, // Error
        U1 extends (F, int), // Error
        U2 extends (F<dynamic>, int), // Ok
        U3 extends (F<Class>, int), // Ok
        U4 extends (F<Class<dynamic>>, int), // Ok
        U5 extends (F<ConcreteClass>, int), // Ok
        U6 extends (F<Class<ConcreteClass>>, int), // Ok
        U7 extends (F<Object>, int), // Error
        U8 extends (F<int>, int), // Error
        V1 extends ({G a, int b}), // Error
        V2 extends ({G<dynamic> a, int b}), // Ok
        V3 extends ({G<Class> a, int b}), // Ok
        V4 extends ({G<Class<dynamic>> a, int b}), // Ok
        V5 extends ({G<ConcreteClass> a, int b}), // Ok
        V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
        V7 extends ({G<Object> a, int b}), // Error
        V8 extends ({G<int> a, int b}), // Error
        W1 extends H, // Error
        W2 extends H<dynamic>, // Ok
        W3 extends H<(Class, int)>, // Ok
        W4 extends H<(Class<dynamic>, int)>, // Ok
        W5 extends H<(ConcreteClass, int)>, // Ok
        W6 extends H<(Class<ConcreteClass>, int)>, // Ok
        W7 extends H<(Object, int)>, // Error
        W8 extends H<(int, int)> // Error
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
      G<ConcreteClass>,
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      ({ConcreteClass a, int b}),
      ({ConcreteClass a, int b}),
      ({ConcreteClass a, int b}),
      ({ConcreteClass a, int b}),
      ({ConcreteClass a, int b}),
      ({ConcreteClass a, int b}),
      ({ConcreteClass a, int b}),
      ({ConcreteClass a, int b}),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int),
      (ConcreteClass, int)>()
}

extension Extension<
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
    S8 extends G<int>, // Error
    U1 extends (F, int), // Error
    U2 extends (F<dynamic>, int), // Ok
    U3 extends (F<Class>, int), // Ok
    U4 extends (F<Class<dynamic>>, int), // Ok
    U5 extends (F<ConcreteClass>, int), // Ok
    U6 extends (F<Class<ConcreteClass>>, int), // Ok
    U7 extends (F<Object>, int), // Error
    U8 extends (F<int>, int), // Error
    V1 extends ({G a, int b}), // Error
    V2 extends ({G<dynamic> a, int b}), // Ok
    V3 extends ({G<Class> a, int b}), // Ok
    V4 extends ({G<Class<dynamic>> a, int b}), // Ok
    V5 extends ({G<ConcreteClass> a, int b}), // Ok
    V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
    V7 extends ({G<Object> a, int b}), // Error
    V8 extends ({G<int> a, int b}), // Error
    W1 extends H, // Error
    W2 extends H<dynamic>, // Ok
    W3 extends H<(Class, int)>, // Ok
    W4 extends H<(Class<dynamic>, int)>, // Ok
    W5 extends H<(ConcreteClass, int)>, // Ok
    W6 extends H<(Class<ConcreteClass>, int)>, // Ok
    W7 extends H<(Object, int)>, // Error
    W8 extends H<(int, int)> // Error
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
      S8 extends G<int>, // Error
      U1 extends (F, int), // Error
      U2 extends (F<dynamic>, int), // Ok
      U3 extends (F<Class>, int), // Ok
      U4 extends (F<Class<dynamic>>, int), // Ok
      U5 extends (F<ConcreteClass>, int), // Ok
      U6 extends (F<Class<ConcreteClass>>, int), // Ok
      U7 extends (F<Object>, int), // Error
      U8 extends (F<int>, int), // Error
      V1 extends ({G a, int b}), // Error
      V2 extends ({G<dynamic> a, int b}), // Ok
      V3 extends ({G<Class> a, int b}), // Ok
      V4 extends ({G<Class<dynamic>> a, int b}), // Ok
      V5 extends ({G<ConcreteClass> a, int b}), // Ok
      V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
      V7 extends ({G<Object> a, int b}), // Error
      V8 extends ({G<int> a, int b}), // Error
      W1 extends H, // Error
      W2 extends H<dynamic>, // Ok
      W3 extends H<(Class, int)>, // Ok
      W4 extends H<(Class<dynamic>, int)>, // Ok
      W5 extends H<(ConcreteClass, int)>, // Ok
      W6 extends H<(Class<ConcreteClass>, int)>, // Ok
      W7 extends H<(Object, int)>, // Error
      W8 extends H<(int, int)> // Error
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
      S8 extends G<int>, // Error
      U1 extends (F, int), // Error
      U2 extends (F<dynamic>, int), // Ok
      U3 extends (F<Class>, int), // Ok
      U4 extends (F<Class<dynamic>>, int), // Ok
      U5 extends (F<ConcreteClass>, int), // Ok
      U6 extends (F<Class<ConcreteClass>>, int), // Ok
      U7 extends (F<Object>, int), // Error
      U8 extends (F<int>, int), // Error
      V1 extends ({G a, int b}), // Error
      V2 extends ({G<dynamic> a, int b}), // Ok
      V3 extends ({G<Class> a, int b}), // Ok
      V4 extends ({G<Class<dynamic>> a, int b}), // Ok
      V5 extends ({G<ConcreteClass> a, int b}), // Ok
      V6 extends ({G<Class<ConcreteClass>> a, int b}), // Ok
      V7 extends ({G<Object> a, int b}), // Error
      V8 extends ({G<int> a, int b}), // Error
      W1 extends H, // Error
      W2 extends H<dynamic>, // Ok
      W3 extends H<(Class, int)>, // Ok
      W4 extends H<(Class<dynamic>, int)>, // Ok
      W5 extends H<(ConcreteClass, int)>, // Ok
      W6 extends H<(Class<ConcreteClass>, int)>, // Ok
      W7 extends H<(Object, int)>, // Error
      W8 extends H<(int, int)> // Error
      >() local;
}

main() {}
