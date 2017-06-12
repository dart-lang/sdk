// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:sdk_library_metadata/libraries.dart'
    show LibraryInfo, libraries;

void main(_) {
  libraries.forEach((String name, LibraryInfo info) {
    print('"$name": sdk.resolve("lib/${info.path}"),');
  });
}
