// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
// A deferred library that doesn't exist.
import 'package:foo/foo.dart' deferred as foo;
// A deferred library that does exist.
import 'deferred/exists.dart' deferred as exists;
// A deferred library that transitively will fail due to a file not found.
import 'deferred/transitive_error.dart' deferred as te;

main() async {
  // Attempt to load foo which will fail.
  var fooError;
  await foo.loadLibrary().catchError((e) {
    fooError = e;
  });
  Expect.isNotNull(fooError);
  await exists.loadLibrary();
  Expect.equals(99, exists.x);
  /* TODO(johnmccutchan): Implement transitive error reporting.
  var teError;
  await te.loadLibrary().catchError((e) {
    teError = e;
  });
  Expect.isNotNull(teError);
  */
}
