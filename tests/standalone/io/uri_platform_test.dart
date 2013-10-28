// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "dart:platform" as platform;

main() {
  Expect.equals(Uri.base,
                new Uri.file(Directory.current.path + platform.pathSeparator));
}
