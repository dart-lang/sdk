// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_js_rounded_ints`

final i1 = 1; // OK
final i2 = -45321; // OK
final i3 = 24361; // OK
final i4 = 245452; // OK
final min = -9007199254740991; // OK
final max = 9007199254740991; // OK

final minErr = -9007199254740993; // LINT
final maxErr = 9007199254740993; // LINT

final notRounded = 1000000000000000000; // OK
final rounded = 1000000000000000001; // LINT

// value.abs() for this number is negative on the 64-bit integer VM.
// Lucky it is not rounded! (-2^63)
final absNegative = -9223372036854775808; // OK