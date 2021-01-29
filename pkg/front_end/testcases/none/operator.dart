// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Class<T> {
  Class<T> operator +(Class<T> other) => other;

  Class<T> operator -() => this;

  Class<T> operator [](int index) => this;

  operator []=(int index, Class<T> value) {}

  int method(double o) => 42;
}

add(num n, int i, double d, Class<String> c, dynamic dyn, Never never,
    String string) {
  print('InstanceInvocation');
  n + n;
  n + i;
  n + d;
  n + dyn;

  print('InstanceInvocation');
  i + n;
  i + i;
  i + d;
  i + dyn;

  print('InstanceInvocation');
  d + n;
  d + i;
  d + d;
  i + dyn;

  print('InstanceInvocation');
  c + c;
  c + dyn;

  print('DynamicInvocation');
  dyn + n;

  print('DynamicInvocation (Never)');
  never + n;

  print('DynamicInvocation (Invalid)');
  string - 42;
}

unaryMinus(num n, int i, double d, Class<String> c, dynamic dyn, Never never,
    String string) {
  print('InstanceInvocation');
  -n;
  -i;
  -d;
  -c;

  print('DynamicInvocation');
  -dyn;

  print('DynamicInvocation (Never)');
  -never;

  print('DynamicInvocation (Invalid)');
  -c.method();

  print('DynamicInvocation (Unresolved)');
  -string;
}

indexGet(List<int> list, Map<String, double> map, Class<String> c, dynamic dyn,
    Never never, String string) {
  print('InstanceInvocation');
  list[0];
  map['foo'];
  c[0];

  print('DynamicInvocation');
  dyn[0];

  print('DynamicInvocation (Never)');
  never[0];

  print('DynamicInvocation (Invalid)');
  c.method()[0];

  print('DynamicInvocation (Unresolved)');
  string[0];
}

indexSet(List<int> list, Map<String, double> map, Class<String> c, dynamic dyn,
    Never never) {
  print('InstanceInvocation');
  list[0] = 42;
  map['foo'] = 0.5;
  c[0] = c;

  print('DynamicInvocation');
  dyn[0] = 42;

  print('DynamicInvocation (Never)');
  never[0] = 42;

  print('DynamicInvocation (Invalid)');
  c.method()[0] = 42;

  print('DynamicInvocation (Unresolved)');
  string[0] = 42;
}

compound(List<int> list, Map<String, double> map, Class<String> c, dynamic dyn,
    Never never) {
  print('InstanceInvocation');
  list[0] += 42;
  map['foo'] += 0.5;
  c[0] += c;

  print('DynamicInvocation');
  dyn[0] += 42;

  print('DynamicInvocation (Never)');
  never[0] += 42;

  print('DynamicInvocation (Invalid)');
  c.method()[0] += 42;

  print('DynamicInvocation (Unresolved)');
  string[0] += 42;
}

main() {}
