// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N unnecessary_to_list_in_spreads`

var ok = [
  ...[1, 2].whereType<int>(), // OK
];

var t1 = [
  ...[1, 2].toList(), // LINT
];
var t2 = [
  ...{1, 2}.toList(), // LINT
];
var t3 = [
  ...?[1, 2].toList(), // LINT
];
var t4 = [
  ...?{1, 2}.toList(), // LINT
];
var t5 = [
  ...[1, 2].whereType<int>().toList(), // LINT
];
