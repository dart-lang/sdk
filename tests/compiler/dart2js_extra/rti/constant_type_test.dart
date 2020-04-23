// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
//
// dart2jsOptions=--experiment-new-rti --no-minify

import "package:expect/expect.dart";

class Thingy {
  const Thingy();
}

class Generic<AA> {
  const Generic();
}

@pragma('dart2js:noInline')
void check<T>(o) {
  Expect.isTrue(o is T);
  Expect.isFalse(o is! T);
}

main() {
  check<Thingy>(const Thingy());

  check<Generic<int>>(const Generic<int>());

  check<Generic<dynamic>>(const Generic<dynamic>());
  check<Generic<Object>>(const Generic<Object>());
  check<Generic<Object>>(const Generic<dynamic>());
  check<Generic<dynamic>>(const Generic<Object>());

  check<List<int>>(const [1]);
  check<List<String>>(const ['one']);

  check<Set<int>>(const {1, 2, 3});
  check<Map<String, int>>(const {'one': 1});

  check<Symbol>(#hello);
}
