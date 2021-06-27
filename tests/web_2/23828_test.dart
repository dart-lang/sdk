// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for http://dartbug.com/23828
// Used to fail when methods contain a name starting with `get`
import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

class MA {
  noSuchMethod(i) => Expect.equals(i.positionalArguments.length, 1);
}

main() {
  confuse(new MA()).getFoo('a');
}
