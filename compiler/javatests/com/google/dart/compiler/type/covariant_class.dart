// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
}

abstract class B extends A {
}

abstract class C extends A {
}

abstract class D {
}

class Super {
  A field;
  A get accessor { return null; }
  void set accessor(A newValue) { }
  A method() { return null; }
  
  var untypedField;
  get untypedAccessor { return null; }
  set untypedAccessor(newValue) { }
  untypedMethod() { return null; }
}

class Sub extends Super {
  B field;
  B get accessor { return null; }
  void set accessor(B newValue) { }
  B method() { return null; }
  
  B untypedField;
  B get untypedAccessor { return null; }
  set untypedAccessor(B newValue) { }
  B untypedMethod() { return null; }
  
  B b;
  C c;
  D d;
}
