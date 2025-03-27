// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'prefix_lib1.dart' as lib1 show ShownExtension1;
import 'prefix_lib2.dart' as lib2 hide HiddenExtension2;
import 'prefix_lib3.dart' as lib3;

test() {
  lib1.ShownExtension1.staticMethod(); // Ok
  lib1.HiddenExtension1.staticMethod(); // Error
  lib2.ShownExtension2.staticMethod(); // Ok
  lib2.HiddenExtension2.staticMethod(); // Error
  lib3.ShownExtension3.staticMethod(); // Ok
}
