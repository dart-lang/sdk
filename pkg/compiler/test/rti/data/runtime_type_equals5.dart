// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

/*spec.class: Class1a:explicit=[Class1a]*/
class Class1a {
  Class1a();
}

/*class: Class1b:needsArgs*/
class Class1b<T> extends Class1a {
  Class1b();
}

/*class: Class1c:needsArgs*/
class Class1c<T> extends Class1a {
  Class1c();
}

class Class2<T> {
  Class2();
}

test(Class1a c, Type type) {
  return c.runtimeType == type;
}

main() {
  makeLive(test(new Class1a(), Class1a));
  makeLive(test(new Class1b<int>(), Class1a));
  makeLive(test(new Class1c<int>(), Class1a));
  Class2<int>();
}
