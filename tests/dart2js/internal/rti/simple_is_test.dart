// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--experiment-new-rti --no-minify

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

class Thingy {}

class Generic<AA> {
  checkMethod(o) => o is AA;
}

@pragma('dart2js:noInline')
void check<T>(o) {
  Expect.isTrue(o is T);
  Expect.isFalse(o is! T);
}

main() {
  check<Thingy>(Thingy());

  check<Generic<int>>(Generic<int>());

  check<Generic<dynamic>>(Generic<dynamic>());
  check<Generic<Object?>>(Generic<Object?>());
  check<Generic<Object?>>(Generic<dynamic>());
  check<Generic<dynamic>>(Generic<Object?>());

  Expect.isTrue(Generic<Thingy>().checkMethod(Thingy()));
  Expect.isTrue(Generic<Object>().checkMethod(Object()));
  Expect.isTrue(Generic<Object>().checkMethod(Thingy()));
  Expect.isFalse(Generic<Thingy>().checkMethod(Object()));
  Expect.isTrue(Generic<dynamic>().checkMethod(Object()));

  Expect.isFalse(Generic<Thingy>().checkMethod(123));
  Expect.isFalse(Generic<Thingy>().checkMethod(Object()));
}
