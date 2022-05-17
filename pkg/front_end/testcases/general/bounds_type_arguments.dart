// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

typedef H<X> = Class2;

void staticMethod<T1, T2, T3, T4, T5, T6, T7, T8, S1, S2, S3, S4, S5, S6, S7,
    S8>() {}

class Class1<T1, T2, T3, T4, T5, T6, T7, T8, S1, S2, S3, S4, S5, S6, S7, S8> {
  Class1();

  factory Class1.fact() => new Class1();

  factory Class1.redirect() = Class1;
}

class Class2 {
  void instanceMethod<T1, T2, T3, T4, T5, T6, T7, T8, S1, S2, S3, S4, S5, S6,
      S7, S8>() {}
}

test() {
  staticMethod<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >();

  var tearOff = staticMethod;
  tearOff<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >();

  tearOff<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >;

  new Class1<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >();

  new Class1<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >.fact();

  new Class1<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >.redirect();

  new Class2().instanceMethod<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >();

  dynamic d = staticMethod;
  d<
      F, // Ok
      F<dynamic>, // Ok
      F<Class>, // Ok
      F<Class<dynamic>>, // Ok
      F<ConcreteClass>, // Ok
      F<Class<ConcreteClass>>, // Ok
      F<Object>, // Error
      F<int>, // Error
      G, // Ok
      G<dynamic>, // Ok
      G<Class>, // Ok
      G<Class<dynamic>>, // Ok
      G<ConcreteClass>, // Ok
      G<Class<ConcreteClass>>, // Ok
      G<Object>, // Error
      G<int> // Error
      >();

  new H<F>(); // Ok
  new H<F<dynamic>>(); // Ok
  new H<F<Class>>(); // Ok
  new H<F<Class<dynamic>>>(); // Ok
  new H<F<ConcreteClass>>(); // Ok
  new H<F<Class<ConcreteClass>>>(); // Ok
  new H<F<Object>>(); // Error
  new H<F<int>>(); // Error
  new H<G>(); // Ok
  new H<G<dynamic>>(); // Ok
  new H<G<Class>>(); // Ok
  new H<G<Class<dynamic>>>(); // Ok
  new H<G<ConcreteClass>>(); // Ok
  new H<G<Class<ConcreteClass>>>(); // Ok
  new H<G<Object>>(); // Error
  new H<G<int>>(); // Error
}

main() {}
