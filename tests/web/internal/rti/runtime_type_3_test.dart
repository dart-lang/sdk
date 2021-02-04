// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--experiment-new-rti --no-minify

import "package:expect/expect.dart";
import "dart:_foreign_helper" show JS;

main() {
  Expect.equals('JSArray<int>', <int>[].runtimeType.toString());

  // TODO(35084): An 'any' type would make JS-interop easier to use.
  Expect.equals('JSArray<dynamic>', JS('', '[]').runtimeType.toString());
}
