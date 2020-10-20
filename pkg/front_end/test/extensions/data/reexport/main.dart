// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[lib1.dart.UniqueExtension1,lib2.dart.UniqueExtension2]*/

import 'lib.dart';

main() {
  /*error: errors=['ClashingExtension' is exported from both 'org-dartlang-test:///a/b/c/lib1.dart' and 'org-dartlang-test:///a/b/c/lib2.dart'.]*/
  ClashingExtension.staticMethod();
  UniqueExtension1.staticMethod();
  UniqueExtension2.staticMethod();
}
