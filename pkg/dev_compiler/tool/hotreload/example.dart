// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'hot_reload_helper.dart' as helper;

void myfunction(String m, int? y) => print('$m: 4');

Future<void> reloadExample() async {
  myfunction('text', 1);
}

/// Usage:
/// ```
/// dart --disable-dart-dev --enable-vm-service example.dart
/// ```
void main() => helper.run(reloadExample);
