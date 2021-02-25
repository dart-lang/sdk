// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Class1 {
  int field;

  Class1(this.field);

  method(o) {}
}

test(Class1 nonNullableClass1, Class1? nullableClass1, dynamic dyn,
    Never never) {
  print("InstanceSet");
  nonNullableClass1.field = 42;
  nullableClass1?.field = 42;
  const int set_instance_field = nonNullableClass1.field = 42;

  print("DynamicSet");
  dyn.field = 42;
  dyn?.field = 42;
  const int set_dynamic_field = dyn.field = 42;

  print("DynamicSet (Never)");
  never.field = 42;

  print("DynamicSet (Invalid)");
  nonNullableClass1.method().field = 42;

  print("DynamicSet (Unresolved)");
  nonNullableClass1.unresolved = 42;
}

main() {}
