// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Set version of this file (not technically in package) explicitly to test as
// much as possibly separately.

// @dart = %VERSION_MARKER0%

import /*error: errors=UntranslatableUri*/ 'package:foo/foo.dart';

/*library: languageVersion=%VERSION_MARKER0%*/

main() {
  var result = /*error: errors=MethodNotFound*/ notNamedFoo();
  print(result);
}
