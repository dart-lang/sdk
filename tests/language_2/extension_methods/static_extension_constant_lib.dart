// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension ExtendObject on Object {
  int operator ~() => 1;
  bool operator &(Object other) => false;
  bool operator |(Object other) => false;
  bool operator ^(Object other) => true;
  int operator ~/(Object other) => 0;
  int operator >>(Object other) => 1;
  // int operator >>>(Object other) => 2; // Requires triple-shift.
  int operator <<(Object other) => 0;
  int operator +(Object other) => 0;
  double operator -() => 1.0;
  double operator -(Object other) => 1.0;
  double operator *(Object other) => 1.0;
  double operator /(Object other) => 2.0;
  double operator %(Object other) => 1.0;
  bool operator <(Object other) => false;
  bool operator <=(Object other) => true;
  bool operator >(Object other) => true;
  bool operator >=(Object other) => false;
  int get length => 1;
}

const Object b = true;
const Object i = 3;
const Object d = 2.4;
const Object s = 'Hello!';

// These expressions should be identical to the ones in
// static_extension_constant_{,error}_test.dart, to ensure that
// they invoke an extension method, and that this is an error.
var runtimeExtensionCalls = <Object>[
  ~i,
  b & b,
  b | b,
  b ^ b,
  i ~/ i,
  i >> i,
  // i >>> i, // Requries triple-shift.
  i << i,
  i + i,
  -i,
  d - d,
  d * d,
  d / d,
  d % d,
  d < i,
  i <= d,
  d > i,
  i >= i,
  s.length,
];
