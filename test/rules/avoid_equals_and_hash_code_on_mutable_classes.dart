// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_equals_and_hash_code_on_mutable_classes`

import 'package:meta/meta.dart';

@immutable
class A {
  final String key;
  const A(this.key);
  @override
  operator ==(other) => other is A && other.key == key; // OK
  @override
  int hashCode() => key.hashCode; // OK
}

class B {
  final String key;
  const B(this.key);
  @override
  operator ==(other) => other is B && other.key == key; // LINT
  @override
  int hashCode() => key.hashCode; // LINT
}

@immutable
class C {
  const C();
}

class D extends C {
  final String key;
  const D(this.key);
  @override
  operator ==(other) => other is B && other.key == key; // OK
  @override
  int get hashCode => key.hashCode; // OK
}
