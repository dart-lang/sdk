// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns if a [path] can be linted by this status file linter.
/// One file in src/co19.status is not a status file, but is some sort of
/// template.
bool canLint(String path) {
  return path.endsWith(".status") && !path.endsWith("src/co19.status");
}
