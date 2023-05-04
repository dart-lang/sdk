// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int? field;
}

typedef B<X> = A;

test(dynamic x) {
  if (x case A<int>()) {} // Error.
  if (x case B()) {} // Ok: the type argument is inferred.
  if (x case B<int>()) {} // Ok.
  if (x case B<String, num>()) {} // Error.
  if (x case A(: 5)) {} // Error
  if (x case A(5)) {} // Error
  if (x case A(var a)) {} // Error
}
