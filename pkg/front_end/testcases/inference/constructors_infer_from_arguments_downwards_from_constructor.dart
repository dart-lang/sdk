// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C<T> {
  C(List<T> list);
}

main() {
  var x = new C([123]);
  C<int> y = x;

  var a = new C<dynamic>([123]);

  // This one however works.
  var b = new C<Object>([123]);
}
