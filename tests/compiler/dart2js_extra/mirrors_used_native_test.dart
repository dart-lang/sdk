// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(targets: 'List')
import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  List;  // work-around for a bug in the type-variable handler. TODO(zarah): remove.
  Expect.equals(3, reflect([1, 2, 3]).getField(#length).reflectee);
  Expect.throws(() => reflect({"hest": 42}).getField(#length),
                (e) => e is UnsupportedError);
}
