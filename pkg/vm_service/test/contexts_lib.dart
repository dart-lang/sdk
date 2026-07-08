// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

// Make sure these variables are not removed by the tree shaker.
@pragma('vm:entry-point')
late final Function cleanBlock;
@pragma('vm:entry-point')
late final Function copyingBlock;
@pragma('vm:entry-point')
late final Function fullBlock;
@pragma('vm:entry-point')
late final Function fullBlockWithChain;

Function genCleanBlock() {
  dynamic block(x) => x;
  return block;
}

Function genCopyingBlock() {
  final x = 'I could be copied into the block';
  String block() => x;
  return block;
}

Function genFullBlock() {
  var x = 42; // I must captured in a context.
  int block() => x;
  x++;
  return block;
}

Function genFullBlockWithChain() {
  var x = 420; // I must captured in a context.
  int Function() outerBlock() {
    var y = 4200;
    int innerBlock() => x + y;
    y++;
    return innerBlock;
  }

  x++;
  return outerBlock();
}

void script() {
  cleanBlock = genCleanBlock();
  copyingBlock = genCopyingBlock();
  fullBlock = genFullBlock();
  fullBlockWithChain = genFullBlockWithChain();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
