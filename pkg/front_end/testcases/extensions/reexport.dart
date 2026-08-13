// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'reexport_lib.dart';

test() {
  ClashingExtension.staticMethod(); // Error
  UniqueExtension1.staticMethod(); // Ok
  UniqueExtension2.staticMethod(); // Ok
}
