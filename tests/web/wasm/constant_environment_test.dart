// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() async {
  const bool isDart2Wasm = bool.fromEnvironment('dart.tool.dart2wasm');
  Expect.isTrue(isDart2Wasm);
}
