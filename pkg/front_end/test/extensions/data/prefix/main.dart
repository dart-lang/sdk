// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[
 lib1.dart.ShownExtension1,
 lib2.dart.ShownExtension2,
 lib3.dart.ShownExtension3]
*/

import 'lib1.dart' as lib1 show ShownExtension1;
import 'lib2.dart' as lib2 hide HiddenExtension2;
import 'lib3.dart' as lib3;

main() {
  lib1.ShownExtension1.staticMethod();
  lib1. /*error: errors=[Getter not found: 'HiddenExtension1'.]*/
      HiddenExtension1.staticMethod();
  lib2.ShownExtension2.staticMethod();
  lib2. /*error: errors=[Getter not found: 'HiddenExtension2'.]*/
      HiddenExtension2.staticMethod();
  lib3.ShownExtension3.staticMethod();
}
