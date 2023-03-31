// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'const_patterns.dart' as prefix;

const int value = 42;

void func() {}

class Class {
  const Class([a]);

  const Class.named();

  call() {}

  test(o) async {
    const dynamic local = 0;
    dynamic variable = 0;
    switch (o) {
      case true: // Ok
      case null: // Ok
      case this: // Error
      case this(): // Error
      case super(): // Error
      case 42: // Ok
      case -42: // Ok
      case 42.5: // Ok
      case -42.5: // Ok
      case 'foo': // Ok
      case 'foo' 'bar': // Ok
      case value: // Ok
      case value!: // Ok
      case value?: // Ok
      case (value?)!: // Ok
      case (value!)?: // Ok
      case -42!: // Ok
      case -42?: // Ok
      case (-42!)?: // Ok
      case (-42?)!: // Ok
      case value as int: // Ok
      case -value: // Error
      case local: // Ok
      case -local: // Error
      case func: // Ok
      case prefix.value: // Ok
      case -prefix.value: // Error
      case prefix.Class.named: // Ok
      case 1 + 2: // Error
      case 1 * 2: // Error
      case void fun() {}: // Error
      case assert(false): // Error
      case switch (o) { _ => true }: // Error
      case await 0: // Error
      case !false: // Error
      case ~0: // Error
      case ++variable: // Error
      case const 0: // Error
      case const 0x0: // Error
      case const 0.5: // Error
      case const true: // Error
      case const null: // Error
      case const -0: // Error
      case const 'foo': // Error
      case const #a: // Error
      case const value: // Error
      case const local: // Error
      case const prefix.value: // Error
      case const -prefix.value: // Error
      case const prefix.Class.named: // Error
      case const 1 + 2: // Error
      case const void fun() {}: // Error
      case const assert(false): // Error
      case const switch (o) { _ => true }: // Error
      case const await 0: // Error
      case const !false: // Error
      case const ~0: // Error
      case const ++variable: // Error
      case const Class(): // Ok
      case const Class(0): // Ok
      case const GenericClass(): // Ok
      case const GenericClass(a: 0): // Ok
      case const GenericClass<int>(): // Ok
      case const GenericClass<int>(a: 0): // Ok
      case const GenericClass<int>.new(): // Ok
      case const GenericClass<int>.new(a: 1): // Ok
      case const []: // Ok
      case const <int>[]: // Ok
      case const {}: // Ok
      case const <int, String>{}: // Ok
      case const const Class(): // Error
      case const const Class(0): // Error
      case const const GenericClass(): // Error
      case const const GenericClass(a: 0): // Error
      case const const GenericClass<int>(): // Error
      case const const GenericClass<int>(a: 0): // Error
      case const const []: // Error
      case const const <int>[]: // Error
      case const const {}: // Error
      case const const <int, String>{}: // Error
      case const new Class(): // Error
      case new Class(): // Error
      case const (): // Error
      case const const (): // Error
      case const (1): // Ok
      case const (-1): // Ok
      case const (value): // Ok
      case const (-value): // Ok
      case const (1 + 2): // Ok
      case GenericClass<int>: // Error
      case prefix.GenericClass<int>: // Error
      case GenericClass<int>.new: // Error
      case prefix.GenericClass<int>.new: // Error
      case const GenericClass<int>: // Error
      case const prefix.GenericClass<int>: // Error
      case const (GenericClass<int>): // Ok
      case const (prefix.GenericClass<int>): // Ok
      case const (GenericClass<int>.new): // Ok
      case const (prefix.GenericClass<int>.new): // Ok
       print(0);
    }
  }
}

class GenericClass<T> {
  const GenericClass({a});
}
