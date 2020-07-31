// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Check that we correctly handle FutureOr<T> when computing if a location
// of the given static type can contain Smi or not.
import 'dart:async';

import 'package:expect/expect.dart';

class W<T> {
  final FutureOr<T> v;
  W({this.v});

  @pragma('vm:never-inline')
  bool compare(W<T> o) {
    // We will emit a dispatch table call here which uses LoadClassId
    // instruction to get class id of o. If FutureOr<T> is treated incorrectly
    // then optimizer will assume that v can't be a Smi and remove smi
    // handling from LoadClassId - leading to a crash.
    return this.v == o.v;
  }
}

@pragma('vm:never-inline')
FutureOr<int> make(int v) {
  return v > 0 ? v : Future.value(v);
}

void main(List<String> args) {
  final i0 = args.length == 0 ? 1 : -2;
  final i1 = args.length == 1 ? -3 : 4;
  var w = W(v: make(i0));
  Expect.isTrue(w.compare(W(v: make(i0))));
  Expect.isFalse(w.compare(W(v: make(i1))));
}
