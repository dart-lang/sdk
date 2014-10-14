// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Returns the name of the shell script for a binstub named [name].
///
/// Adds a ".bat" extension on Windows.
binStubName(String name) {
  if (Platform.operatingSystem == "windows") return "$name.bat";
  return name;
}
