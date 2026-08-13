// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

test1() {
  F local1a, local1b; // Ok
  F<dynamic> local2a, local2b; // Ok
  F<Class> local3a, local3b; // Ok
  F<Class<dynamic>> local4a, local4b; // Ok
  F<ConcreteClass> local5a, local5b; // Ok
  F<Class<ConcreteClass>> local6a, local6b; // Ok
  F<Object> local7a, local7b; // Error
  F<int> local8a, local8b; // Error
  G local1c, local1d; // Ok
  G<dynamic> local2c, local2d; // Ok
  G<Class> local3c, local3d; // Ok
  G<Class<dynamic>> local4c, local4d; // Ok
  G<ConcreteClass> local5c, local5d; // Ok
  G<Class<ConcreteClass>> local6c, local6d; // Ok
  G<Object> local7c, local8d; // Error
  G<int> local8c, local7d; // Error
}

test2() {
  void Function(F) local1a, local1b; // Ok
  void Function(F<dynamic>) local2a, local2b; // Ok
  void Function(F<Class>) local3a, local3b; // Ok
  void Function(F<Class<dynamic>>) local4a, local4b; // Ok
  void Function(F<ConcreteClass>) local5a, local5b; // Ok
  void Function(F<Class<ConcreteClass>>) local6a, local6b; // Ok
  void Function(F<Object>) local7a, local7b; // Error
  void Function(F<int>) local8a, local8b; // Error
  void Function(G) local1c, local1d; // Ok
  void Function(G<dynamic>) local2c, local2d; // Ok
  void Function(G<Class>) local3c, local3d; // Ok
  void Function(G<Class<dynamic>>) local4c, local4d; // Ok
  void Function(G<ConcreteClass>) local5c, local5d; // Ok
  void Function(G<Class<ConcreteClass>>) local6c, local6d; // Ok
  void Function(G<Object>) local7c, local8d; // Error
  void Function(G<int>) local8c, local7d; // Error
}

test3() {
  void Function(F f) local1a, local1b; // Ok
  void Function(F<dynamic> f) local2a, local2b; // Ok
  void Function(F<Class> f) local3a, local3b; // Ok
  void Function(F<Class<dynamic>> f) local4a, local4b; // Ok
  void Function(F<ConcreteClass> f) local5a, local5b; // Ok
  void Function(F<Class<ConcreteClass>> f) local6a, local6b; // Ok
  void Function(F<Object> f) local7a, local7b; // Error
  void Function(F<int> f) local8a, local8b; // Error
  void Function(G g) local1c, local1d; // Ok
  void Function(G<dynamic> g) local2c, local2d; // Ok
  void Function(G<Class> g) local3c, local3d; // Ok
  void Function(G<Class<dynamic>> g) local4c, local4d; // Ok
  void Function(G<ConcreteClass> g) local5c, local5d; // Ok
  void Function(G<Class<ConcreteClass>> g) local6c, local6d; // Ok
  void Function(G<Object> g) local7c, local8d; // Error
  void Function(G<int> g) local8c, local7d; // Error
}

test4() {
  void Function(void Function(F)) local1a, local1b; // Ok
  void Function(void Function(F<dynamic>)) local2a, local2b; // Ok
  void Function(void Function(F<Class>)) local3a, local3b; // Ok
  void Function(void Function(F<Class<dynamic>>)) local4a, local4b; // Ok
  void Function(void Function(F<ConcreteClass>)) local5a, local5b; // Ok
  void Function(void Function(F<Class<ConcreteClass>>)) local6a, local6b; // Ok
  void Function(void Function(F<Object>)) local7a, local7b; // Error
  void Function(void Function(F<int>)) local8a, local8b; // Error
  void Function(void Function(G)) local1c, local1d; // Ok
  void Function(void Function(G<dynamic>)) local2c, local2d; // Ok
  void Function(void Function(G<Class>)) local3c, local3d; // Ok
  void Function(void Function(G<Class<dynamic>>)) local4c, local4d; // Ok
  void Function(void Function(G<ConcreteClass>)) local5c, local5d; // Ok
  void Function(void Function(G<Class<ConcreteClass>>)) local6c, local6d; // Ok
  void Function(void Function(G<Object>)) local7c, local8d; // Error
  void Function(void Function(G<int>)) local8c, local7d; // Error
}

test5() {
  void Function(void Function(F f) f) local1a, local1b; // Ok
  void Function(void Function(F<dynamic> f) f) local2a, local2b; // Ok
  void Function(void Function(F<Class> f) f) local3a, local3b; // Ok
  void Function(void Function(F<Class<dynamic>> f) f) local4a, local4b; // Ok
  void Function(void Function(F<ConcreteClass> f) f) local5a, local5b; // Ok
  void Function(void Function(F<Class<ConcreteClass>> f) f) local6a,
      local6b; // Ok
  void Function(void Function(F<Object> f) f) local7a, local7b; // Error
  void Function(void Function(F<int> f) f) local8a, local8b; // Error
  void Function(void Function(G g) g) local1c, local1d; // Ok
  void Function(void Function(G<dynamic> g) g) local2c, local2d; // Ok
  void Function(void Function(G<Class> g) g) local3c, local3d; // Ok
  void Function(void Function(G<Class<dynamic>> g) g) local4c, local4d; // Ok
  void Function(void Function(G<ConcreteClass> g) g) local5c, local5d; // Ok
  void Function(void Function(G<Class<ConcreteClass>> g) g) local6c,
      local6d; // Ok
  void Function(void Function(G<Object> g) g) local7c, local8d; // Error
  void Function(void Function(G<int> g) g) local8c, local7d; // Error
}

main() {}
