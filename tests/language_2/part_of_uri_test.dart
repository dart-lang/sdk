// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// No library declaration
part "part_of_uri_part.dart"; // declares bar1, baz1
part "part_of_uri_part2.dart"; // declares bar2, baz2

const foo = 'foo';
const qux = "$baz1$baz2";

main() {
  if (!identical(qux, "foopart21foopart12")) throw "Fail: $qux";
}
