// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  final c = MyClass(() => Value((1, name: 1)));
  final value = c.myField()?.value.name;
  print(c);
}

class MyClass<T> {
  MyClass(this.myField);

  final Value<Hello<T>>? Function() myField;
}

class Value<T> {
  Value(this.value);

  final T value;
}

typedef Hello<T> = (T, {T name});