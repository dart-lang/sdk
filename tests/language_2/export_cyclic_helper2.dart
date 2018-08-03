// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library export_cyclic_helper2;

import 'export_cyclic_test.dart';
import 'export_cyclic_helper3.dart';
export 'export_cyclic_test.dart';
export 'export_cyclic_helper3.dart';

class C {
  A a;
  B b;
  C c;
  D d;
}
