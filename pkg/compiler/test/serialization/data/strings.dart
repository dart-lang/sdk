// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/strings_deferred.dart' deferred as def;

Future<void> main() async {
  print(''.length);
  await def.loadLibrary();
  def.useStrings();
}
