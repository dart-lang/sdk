// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

t1a(o) => o as F; // Ok
t2a(o) => o as F<dynamic>; // Ok
t3a(o) => o as F<Class>; // Ok
t4a(o) => o as F<Class<dynamic>>; // Ok
t5a(o) => o as F<ConcreteClass>; // Ok
t6a(o) => o as F<Class<ConcreteClass>>; // Ok
t7a(o) => o as F<Object>; // Error
t8a(o) => o as F<int>; // Error
s1a(o) => o as G; // Ok
s2a(o) => o as G<dynamic>; // Ok
s3a(o) => o as G<Class>; // Ok
s4a(o) => o as G<Class<dynamic>>; // Ok
s5a(o) => o as G<ConcreteClass>; // Ok
s6a(o) => o as G<Class<ConcreteClass>>; // Ok
s7a(o) => o as G<Object>; // Error
s8a(o) => o as G<int>; // Error

t1b(o) => o is F; // Ok
t2b(o) => o is F<dynamic>; // Ok
t3b(o) => o is F<Class>; // Ok
t4b(o) => o is F<Class<dynamic>>; // Ok
t5b(o) => o is F<ConcreteClass>; // Ok
t6b(o) => o is F<Class<ConcreteClass>>; // Ok
t7b(o) => o is F<Object>; // Error
t8b(o) => o is F<int>; // Error
s1b(o) => o is G; // Ok
s2b(o) => o is G<dynamic>; // Ok
s3b(o) => o is G<Class>; // Ok
s4b(o) => o is G<Class<dynamic>>; // Ok
s5b(o) => o is G<ConcreteClass>; // Ok
s6b(o) => o is G<Class<ConcreteClass>>; // Ok
s7b(o) => o is G<Object>; // Error
s8b(o) => o is G<int>; // Error

main() {}
