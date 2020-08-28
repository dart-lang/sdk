// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This version should opt out of null safety on all sdks after 2.9, regardless
// of the experiment flag.
// @dart = 2.9
// Requirements=nnbd-weak

void main() {
  // This should be an error since we are opted out.
  int? x;
  // ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] Null safety features are disabled for this library.
}
