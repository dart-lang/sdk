// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'duplicated_bad_prefix_lib1.dart' as dupe;
import 'duplicated_bad_prefix_lib2.dart' as dupe;

class Dupe {}

class Dupe {}

class C {
  Dupe.a b;
  dupe.C d;
}

main() {}
