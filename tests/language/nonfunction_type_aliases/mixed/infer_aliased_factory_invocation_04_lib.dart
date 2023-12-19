// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C<X> {
  factory C(Type t) => D<X>(t);
}

class D<X> implements C<X> {
  D(Type t) {
    Expect.equals(t, X);
  }
}


typedef T<X> = C<List<X>>;
