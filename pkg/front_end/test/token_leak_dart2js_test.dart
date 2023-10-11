// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'token_leak_test.dart' as test;

Future<void> main() async {
  await test.main(['--no-sdk', 'pkg/compiler/lib/src/dart2js.dart']);
}
