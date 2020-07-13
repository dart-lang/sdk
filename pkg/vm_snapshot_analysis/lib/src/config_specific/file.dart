// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '_file_stub.dart'
    if (dart.library.html) '_file_web.dart'
    if (dart.library.io) '_file_vm.dart';

Future<Object> loadJson(dynamic file) {
  return loadJsonFromFile(file);
}
