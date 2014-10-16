// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'poi.dart' as poi;

int count = 0;

int MAX_ITERATIONS =
    const int.fromEnvironment('MAX_ITERATIONS', defaultValue: null);

main(arguments) {
  count++;
  if (MAX_ITERATIONS != null && count > MAX_ITERATIONS) return;
  print('\n\n\n\nIteration #$count.');
  poi.main(arguments).then((_) => main(arguments));
}
