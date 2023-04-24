// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const a1 = 'outer a1';
const b1 = 'outer b1';

test1(dynamic x) {
  return switch (x) {
    var a1 && == a1 => 0, // Error.
    var b1 && == b1 when b1 < 0 => 1, // Error.
    _ => null
  };
}

const a2 = 'outer a2';
const b2 = 'outer b2';

test2(dynamic x) {
  switch (x) {
    case var a2 && == a2: // Error.
      return 0;
    case var b2 && == b2 when b2 < 0: // Error.
      return 1;
    default:
      return null;
  }
}

const a3 = 'outer a3';
const b3 = 'outer b3';

test3(dynamic x) {
  if (x case var a3 && == a3) { // Error.
    return 0;
  } else if (x case var b3 && == b3 when b3 < 0) { // Error.
    return 1;
  } else {
    return null;
  }
}

const a4 = 'outer a4';
const b4 = 'outer b4';

test4(dynamic x) {
  return [
    if (x case var a4 && == a4) 0, // Error.
    if (x case var b4 && == b4 when b4 < 0) 1, // Error.
  ];
}
