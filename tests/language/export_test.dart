// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test export and re-export.

library export_test;

import 'export_helper1.dart';
import 'export_helper3.dart' as lib;

void main() {
  print(new Exported());
  print(new ReExported());
  print(new lib.Exported());
  print(new lib.ReExported());
}
