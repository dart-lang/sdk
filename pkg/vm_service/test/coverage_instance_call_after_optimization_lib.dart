// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

@pragma('vm:never-inline')
String leafFunction(Uri base, Map json) {
  String root = json['root'];
  if (!root.endsWith('/')) {
    print('Inside if!');
    root += '/';
  }
  print(base.resolve(root));
  return 'some constant';
}

const optimizationCounterThreshold = 10;

void testFunction() {
  debugger();
  // Note that if we do `i < 1`` here optimization doesn't kick in
  // (I'm not sure why it kicks in so soon though).
  for (int i = 0; i < optimizationCounterThreshold; i++) {
    leafFunction(Uri.base, {'root': 'foo/'});
  }
  // Assuming `leafFunction` is optimized now, does coverage still work?
  leafFunction(Uri.base, {'root': 'bar'});
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
