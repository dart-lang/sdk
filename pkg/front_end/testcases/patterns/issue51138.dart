// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test(List list) {
  return switch (list) {
    <num>[3, >0] => "relational",
    [4, var c as num] => "cast",
    _ => "default",
  };
}

main() {
  throws(() => test([4, "42"]));
}

throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Missing exception';
}