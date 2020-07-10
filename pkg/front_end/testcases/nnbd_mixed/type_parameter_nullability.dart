// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_parameter_nullability_lib.dart';

class C<T extends num?, S, U> {
  void promoteNullable(T? t) {
    if (t is int) /* Creates T? & int! */ {
      t;
    }
    if (t is int?) /* Creates T? & int? */ {
      t;
    }
  }

  void nullableAsUndetermined(S? s) {
    s as U; /* Creates S? & U% */
  }
}

main() {
  var c = new C<num, num, num>();
  c.promoteNullable(null);
  c.promoteNullable(0);
  c.nullableAsUndetermined(null);
  c.nullableAsUndetermined(0);
  var d = new D<num>();
  d.promoteLegacy(null);
  d.promoteLegacy(0);
}
