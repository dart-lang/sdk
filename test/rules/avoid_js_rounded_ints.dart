// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_js_rounded_ints`

final i = 1; // OK
final min = -9007199254740991; // OK
final max = 9007199254740991; // OK

final minErr = -9007199254740993; // LINT
final maxErr = 9007199254740993; // LINT

final notRounded = 1000000000000000000; // OK
final rounded = 1000000000000000001; // LINT
