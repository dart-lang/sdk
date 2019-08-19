// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_operator_equals_on_mutable_classes`

// Hack to work around issues importing `meta.dart` in tests.
// Ideally, remove:
library meta;

class _Immutable {
  const _Immutable();
}

const _Immutable immutable = _Immutable();

@immutable
class A {
  final String key;
  const A(this.key);
  @override operator ==(other) => other is A && other.key == key; // OK
  @override int hashCode() => key.hashCode; // OK
}

class B {
  final String key;
  const B(this.key);
  @override operator ==(other) => other is B && other.key == key; // LINT
  @override int hashCode() => key.hashCode; // LINT
}
