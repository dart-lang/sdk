// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:isolate';

import "package:async_helper/async_helper.dart";
import 'package:expect/expect.dart';

import 'send_unsupported_objects_test.dart';

const NESTED_DEPTH = 500;
Future<List> buildNestedList(List<dynamic> list, int level) async {
  final fu = level == NESTED_DEPTH ? Fu.unsendable("$level") : Fu("$level");
  final newlist = <dynamic>[list, fu];
  if (--level == 0) {
    return newlist;
  }
  return await buildNestedList(newlist, level);
}

main() async {
  asyncStart();
  try {
    final nestedList = await buildNestedList(<dynamic>[], NESTED_DEPTH);
    // Send closure capturing nestedList
    await Isolate.spawn((arg) {
      arg();
    }, () {
      print('$nestedList');
    });
  } catch (e) {
    Expect.isTrue(checkForRetainingPath(e, <String>[
      'NativeClass',
      'Baz',
      'Fu',
      'closure',
    ]));

    final msg = e.toString();
    Expect.isTrue(msg.split('\n').length > NESTED_DEPTH * 2);
    asyncEnd();
  }
}
