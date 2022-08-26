// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

typedef T1 = F; // Error
typedef T2 = F<dynamic>; // Error
typedef T3 = F<Class>; // Error
typedef T4 = F<Class<dynamic>>; // Error
typedef T5 = F<ConcreteClass>; // Ok
typedef T6 = F<Class<ConcreteClass>>; // Ok
typedef T7 = F<Object>; // Error
typedef T8 = F<int>; // Error

typedef S1 = G; // Error
typedef S2 = G<dynamic>; // Error
typedef S3 = G<Class>; // Error
typedef S4 = G<Class<dynamic>>; // Error
typedef S5 = G<ConcreteClass>; // Ok
typedef S6 = G<Class<ConcreteClass>>; // Ok
typedef S7 = G<Object>; // Error
typedef S8 = G<int>; // Error

typedef Typedef1 = void Function<
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

main() {}
