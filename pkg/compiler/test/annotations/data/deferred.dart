// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' deferred as normal show HashSet;

@pragma('dart2js:load-priority', 'someArg1')
import 'dart:math' deferred as high;

test() async {
  await normal. /*spec.invoke: */ loadLibrary();
  await high. /*spec.invoke: someArg1*/ loadLibrary();

  @pragma('dart2js:load-priority', 'someArg2')
  final _1 = await normal. /*spec.invoke: someArg2*/ loadLibrary();
  @pragma('dart2js:load-priority', 'someArg3')
  final _2 = await normal. /*spec.invoke: someArg3*/ loadLibrary();

  @pragma('dart2js:load-priority', 'someArg4')
  final _3 = await normal. /*spec.invoke: someArg4*/ loadLibrary();
  @pragma('dart2js:load-priority', 'someArg5')
  final _4 = await normal. /*spec.invoke: someArg5*/ loadLibrary();
}

main() async {
  await test();
}
