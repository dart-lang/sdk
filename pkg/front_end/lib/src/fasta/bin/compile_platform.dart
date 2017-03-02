// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compile_platform.dart' as compile_platform;

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

main(List<String> arguments) async {
  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }
    await compile_platform.main(arguments);
  }
}
