// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'send_unsupported_objects_test.dart';

main() async {
  asyncStart();

  final fu = Fu.unsendable('fu');
  try {
    // Pass a closure that captures [fu]
    await Isolate.spawn((arg) {
      arg();
    }, () {
      print('${fu.label}');
      Expect.fail('This closure should fail to be sent, shouldn\'t be called');
    });
  } catch (e) {
    checkForRetainingPath(e, <String>[
      'NativeWrapper',
      'Baz',
      'Fu',
      'Context',
      'Closure',
    ]);
    asyncEnd();
  }
}
