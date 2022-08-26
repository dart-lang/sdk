// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

F? field1a, field1b; // Ok
F<dynamic>? field2a, field2b; // Ok
F<Class>? field3a, field3b; // Ok
F<Class<dynamic>>? field4a, field4b; // Ok
F<ConcreteClass>? field5a, field5b; // Ok
F<Class<ConcreteClass>>? field6a, field6b; // Ok
F<Object>? field7a, field7b; // Error
F<int>? field8a, field8b; // Error
G? field1c, field1d; // Ok
G<dynamic>? field2c, field2d; // Ok
G<Class>? field3c, field3d; // Ok
G<Class<dynamic>>? field4c, field4d; // Ok
G<ConcreteClass>? field5c, field5d; // Ok
G<Class<ConcreteClass>>? field6c, field6d; // Ok
G<Object>? field7c, field8d; // Error
G<int>? field8c, field7d; // Error

class Class1 {
  F? field1a, field1b; // Ok
  F<dynamic>? field2a, field2b; // Ok
  F<Class>? field3a, field3b; // Ok
  F<Class<dynamic>>? field4a, field4b; // Ok
  F<ConcreteClass>? field5a, field5b; // Ok
  F<Class<ConcreteClass>>? field6a, field6b; // Ok
  F<Object>? field7a, field7b; // Error
  F<int>? field8a, field8b; // Error
  G? field1c, field1d; // Ok
  G<dynamic>? field2c, field2d; // Ok
  G<Class>? field3c, field3d; // Ok
  G<Class<dynamic>>? field4c, field4d; // Ok
  G<ConcreteClass>? field5c, field5d; // Ok
  G<Class<ConcreteClass>>? field6c, field6d; // Ok
  G<Object>? field7c, field8d; // Error
  G<int>? field8c, field7d; // Error
}

extension Extension1 on int {
  static F? field1a, field1b; // Ok
  static F<dynamic>? field2a, field2b; // Ok
  static F<Class>? field3a, field3b; // Ok
  static F<Class<dynamic>>? field4a, field4b; // Ok
  static F<ConcreteClass>? field5a, field5b; // Ok
  static F<Class<ConcreteClass>>? field6a, field6b; // Ok
  static F<Object>? field7a, field7b; // Error
  static F<int>? field8a, field8b; // Error
  static G? field1c, field1d; // Ok
  static G<dynamic>? field2c, field2d; // Ok
  static G<Class>? field3c, field3d; // Ok
  static G<Class<dynamic>>? field4c, field4d; // Ok
  static G<ConcreteClass>? field5c, field5d; // Ok
  static G<Class<ConcreteClass>>? field6c, field6d; // Ok
  static G<Object>? field7c, field8d; // Error
  static G<int>? field8c, field7d; // Error
}

main() {}
