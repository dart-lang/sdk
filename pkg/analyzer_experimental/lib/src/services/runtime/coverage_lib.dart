// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is injected into the applications under coverage.
library coverage_lib;

/// Notifies that the object with the given [id] - statement, token, etc was executed.
touch(int id) {
  print('touch: $id');
}
