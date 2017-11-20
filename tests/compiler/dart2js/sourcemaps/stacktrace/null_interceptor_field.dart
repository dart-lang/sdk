// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class MyType {
  get length => 3; // ensures we build an interceptor for `.length`
}

main() {
  confuse('').trim(); // includes some code above the interceptors
  confuse([]).length;
  confuse(new MyType()).length;
  // TODO(johnniwinther): Intercepted access should point to 'length':
  /*1:main*/ confuse(null).length; // called through the interceptor
}

@NoInline()
confuse(x) => x;
