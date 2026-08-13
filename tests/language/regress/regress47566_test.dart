// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47566

import 'package:expect/expect.dart';

final List trace = [];
void log(String s) {
  trace.add(s);
}

Future<void> test(bool value) async {
  log('f1');

  if (value) {
    final result = await bar();
    switch (result) {
      case 1:
        log('sb');
        break;
      case 0:
        return;
    }
    log('sc');
  }

  log('f2');
}

Future<int> bar() async => 1;

Future<void> main() async {
  trace.clear();
  await test(true);
  Expect.equals('f1,sb,sc,f2', trace.join(','));

  trace.clear();
  await test(false);
  Expect.equals('f1,f2', trace.join(','));
}
