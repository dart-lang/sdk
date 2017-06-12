// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

T id<T>(T x) => x;

main() async {
  Future<String> f;
  String s = await /*@typeArgs=FutureOr<String>*/ id(f);
}
