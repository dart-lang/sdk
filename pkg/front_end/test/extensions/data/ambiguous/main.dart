// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[
 lib1.dart.AmbiguousExtension1,
 lib1.dart.AmbiguousExtension2,
 lib1.dart.UnambiguousExtension1,
 lib2.dart.AmbiguousExtension1,
 lib2.dart.AmbiguousExtension2,
 lib2.dart.UnambiguousExtension2]
*/

import 'lib1.dart';
import 'lib2.dart';

main() {
  /*error: errors=['AmbiguousExtension1' is imported from both 'org-dartlang-test:///a/b/c/lib1.dart' and 'org-dartlang-test:///a/b/c/lib2.dart'.]*/
  AmbiguousExtension1.ambiguousStaticMethod1();
  /*error: errors=['AmbiguousExtension2' is imported from both 'org-dartlang-test:///a/b/c/lib1.dart' and 'org-dartlang-test:///a/b/c/lib2.dart'.]*/
  AmbiguousExtension2.unambiguousStaticMethod1();
  UnambiguousExtension1.ambiguousStaticMethod2();
  UnambiguousExtension2.ambiguousStaticMethod2();
}
