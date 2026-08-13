// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

@pragma('dyn-module:entry-point')
Future<bool> dynamicModuleEntrypoint() async {
  final list = ['1', '2', '3'];
  list.add('4');
  final list2 = list.map((e) => 'item $e').toList().reversed.toList();
  final list3 = <Future>[];
  for (var e in list2) {
    list3.add(Future.value(e));
  }
  Expect.equals('item 2', await list3[2]);
  return true;
}
