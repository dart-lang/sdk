// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: zero:[exact=JSUInt31]*/
zero() => 0;

/*element: one:[exact=JSUInt31]*/
one() => 1;

/*element: half:[exact=JSDouble]*/
half() => 0.5;

/*element: large:[subclass=JSUInt32]*/
large() => 2147483648;

/*element: huge:[subclass=JSPositiveInt]*/
huge() => 4294967296;

/*element: main:[null]*/
main() {
  zero();
  one();
  half();
  large();
  huge();
}
