// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = Class1;

class G<X extends Class<X>> {}

class Class1 {}

test() {
  new F(); // Error
  new F<dynamic>(); // Error
  new F<Class>(); // Error
  new F<Class<dynamic>>(); // Error
  new F<ConcreteClass>(); // Ok
  new F<Class<ConcreteClass>>(); // Ok
  new F<Object>(); // Error
  new F<int>(); // Error
  new G(); // Error
  new G<dynamic>(); // Error
  new G<Class>(); // Error
  new G<Class<dynamic>>(); // Error
  new G<ConcreteClass>(); // Ok
  new G<Class<ConcreteClass>>(); // Ok
  new G<Object>(); // Error
  new G<int>(); // Error

  F.new; // Ok
  F<dynamic>.new; // Ok
  F<Class>.new; // Ok
  F<Class<dynamic>>.new; // Ok
  F<ConcreteClass>.new; // Ok
  F<Class<ConcreteClass>>.new; // Ok
  F<Object>.new; // Error
  F<int>.new; // Error
  G.new; // Ok
  G<dynamic>.new; // Error
  G<Class>.new; // Error
  G<Class<dynamic>>.new; // Error
  G<ConcreteClass>.new; // Ok
  G<Class<ConcreteClass>>.new; // Ok
  G<Object>.new; // Error
  G<int>.new; // Error
}

main() {}
