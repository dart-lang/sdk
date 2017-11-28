// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library part_of_uri2;

part "part_of_uri2_part.dart"; // declares bar1, baz1, uses URI.
part "part_of_uri2_part2.dart"; // declares bar2, baz2, uses id.

const foo = 'foo';
const qux = "$baz1$baz2";

main() {
  if (!identical(qux, "foopart21foopart12")) throw "Fail: $qux";
}
