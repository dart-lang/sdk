// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
void callWith<T>(void Function(T arg) fun, T arg) {
  fun(arg);
}

@pragma('vm:testing:match-inner-flow-graph', 'foo')
void main() {
  @pragma('vm:testing:print-flow-graph')
  foo(Uint8List list) {
    if (list[0] != 0) throw 'a';
  }

  callWith<Uint8List>(foo, Uint8List(10));
}

void matchIL$main(FlowGraph graph) {}

void matchIL$main_foo(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'list' << match.Parameter(index: 1),
      match.LoadField('list', slot: 'TypedDataBase.length'),
      match.GenericCheckBound(),
      match.LoadField('list', slot: 'PointerBase.data'),
      match.LoadIndexed(),
    ]),
  ]);
}
