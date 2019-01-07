// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  method1(new Class1a());
  method2(new Class2a());
  method2(new Class2b());
  method3(new Class3a());
  method3(new Class3b());
  method4(new Class4a());
  method4(new Class4b());
}

class Class1a {
  int field1;
}

/*element: method1:FieldSet=[name=Class1a.field1]*/
@pragma('dart2js:noInline')
method1(Class1a c) {
  c.field1 = 42;
}

class Class2a {
  int field2 = 42;
}

class Class2b extends Class2a {}

/*element: method2:FieldSet=[name=Class2a.field2]*/
@pragma('dart2js:noInline')
method2(Class2a c) {
  c.field2 = 42;
}

class Class3a {
  int field3;
}

class Class3b implements Class3a {
  int get field3 => 42;
  set field3(int _) {}
}

@pragma('dart2js:noInline')
method3(Class3a c) {
  c.field3 = 42;
}

class Class4a {
  int field4;
}

class Class4b implements Class4a {
  int field4;
}

// TODO(johnniwinther,sra): Maybe we should optimize cases like this to a direct
// property write, because all targets are simple fields?
@pragma('dart2js:noInline')
method4(Class4a c) {
  c.field4 = 42;
}
