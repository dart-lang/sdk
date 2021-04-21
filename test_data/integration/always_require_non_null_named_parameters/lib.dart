// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:meta/meta.dart';

class A {
  var a;
  A.c({
    @required a, // OK
    b, // LINT
    @required c, // OK
  })
      : assert(a != null),
        assert(b != null);
}
