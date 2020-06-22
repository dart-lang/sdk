// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--experiment-new-rti --no-minify

import "package:expect/expect.dart";

@pragma('dart2js:noInline')
Type grab<T>() => T;

@pragma('dart2js:noInline')
Type grabList<T>() => grab<List<T>>();

main() {
  Expect.equals('int', grab<int>().toString());

  Expect.identical(int, grab<int>());
  Expect.identical(dynamic, grab<dynamic>());
  Expect.identical(Object, grab<Object>());
  Expect.identical(Null, grab<Null>());

  Expect.equals('List<int>', grabList<int>().toString());
  Expect.equals('List<Null>', grabList<Null>().toString());

  Expect.equals('List<dynamic>', (List).toString());

  Expect.equals('dynamic', (dynamic).toString());
  Expect.equals('Object', (Object).toString());
  Expect.equals('Null', (Null).toString());

  Expect.equals(List, grabList<dynamic>());
}
