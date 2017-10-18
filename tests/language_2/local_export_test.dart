// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library localExportTest;

import "package:expect/expect.dart";
import 'local_export_a.dart';

void main() {
  Expect.equals(42, new A().method());
}
