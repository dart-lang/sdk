// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[lib1.dart.ShownExtension1,lib2.dart.ShownExtension2]*/

import 'lib1.dart' show ShownExtension1;
import 'lib2.dart' hide HiddenExtension2;

main() {
  ShownExtension1.staticMethod();
  /*error: errors=[Getter not found: 'HiddenExtension1'.]*/
  HiddenExtension1.staticMethod();
  ShownExtension2.staticMethod();
  /*error: errors=[Getter not found: 'HiddenExtension2'.]*/
  HiddenExtension2.staticMethod();
}
