// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that exports are serialized in platform.dill.

// Note: "dart:profiler" exports UserTag from "dart:developer". This is
// somewhat brittle and we should extend this test framework to be able to deal
// with multiple .dill files.
import 'dart:profiler' show UserTag;

export 'dart:core' show print;

main() {
  print(UserTag);
}
