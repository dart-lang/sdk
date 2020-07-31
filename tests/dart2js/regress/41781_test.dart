// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:noInline')
test(List a, List b) {
  return [
    throw 123,
    {...a, ...b}
  ];
}

void main() {
  try {
    print(test([1], [2, 3]));
    print(test([1, 2], [3]));
  } catch (e) {}
}
