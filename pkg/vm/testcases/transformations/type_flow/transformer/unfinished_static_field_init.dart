// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

dynamic good() => new A();
dynamic bad() => throw 'No return!';

var static_field_good = good();
var static_field_bad = bad();

main(List<String> args) {
  print(static_field_good);
  print(static_field_bad); // Should infer null.
}
