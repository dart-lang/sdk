// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' deferred as normal show HashSet;

@pragma('dart2js:load-priority:high')
import 'dart:math' deferred as high;

test1() async {
  await normal. /*spec.invoke: normal*/ loadLibrary();
  await high. /*spec.invoke: high*/ loadLibrary();

  @pragma('dart2js:load-priority:normal')
  final _1 = await normal. /*spec.invoke: normal*/ loadLibrary();
  @pragma('dart2js:load-priority:normal')
  final _2 = await normal. /*spec.invoke: normal*/ loadLibrary();

  @pragma('dart2js:load-priority:high')
  final _3 = await normal. /*spec.invoke: high*/ loadLibrary();
  @pragma('dart2js:load-priority:high')
  final _4 = await normal. /*spec.invoke: high*/ loadLibrary();
}

@pragma('dart2js:load-priority:high')
/*spec.member: testHigh:load-priority:high*/
testHigh() async {
  await normal. /*spec.invoke: high*/ loadLibrary();
  await high. /*spec.invoke: high*/ loadLibrary();

  @pragma('dart2js:load-priority:normal')
  final _1 = await normal. /*spec.invoke: normal*/ loadLibrary();
  @pragma('dart2js:load-priority:normal')
  final _2 = await normal. /*spec.invoke: normal*/ loadLibrary();

  @pragma('dart2js:load-priority:high')
  final _3 = await normal. /*spec.invoke: high*/ loadLibrary();
  @pragma('dart2js:load-priority:high')
  final _4 = await normal. /*spec.invoke: high*/ loadLibrary();
}

@pragma('dart2js:load-priority:normal')
/*spec.member: testNormal:load-priority:normal*/
testNormal() async {
  await normal. /*spec.invoke: normal*/ loadLibrary();
  await high. /*spec.invoke: normal*/ loadLibrary();

  @pragma('dart2js:load-priority:normal')
  final _1 = await normal. /*spec.invoke: normal*/ loadLibrary();
  @pragma('dart2js:load-priority:normal')
  final _2 = await normal. /*spec.invoke: normal*/ loadLibrary();

  @pragma('dart2js:load-priority:high')
  final _3 = await normal. /*spec.invoke: high*/ loadLibrary();
  @pragma('dart2js:load-priority:high')
  final _4 = await normal. /*spec.invoke: high*/ loadLibrary();
}

main() async {
  await test1();
  await testHigh();
  await testNormal();
}
