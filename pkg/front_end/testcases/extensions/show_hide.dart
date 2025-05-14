// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'show_hide_lib1.dart' show ShownExtension1;
import 'show_hide_lib2.dart' hide HiddenExtension2;

test() {
  ShownExtension1.staticMethod(); // Ok
  HiddenExtension1.staticMethod(); // Error
  ShownExtension2.staticMethod(); // Ok
  HiddenExtension2.staticMethod(); // Error
}
