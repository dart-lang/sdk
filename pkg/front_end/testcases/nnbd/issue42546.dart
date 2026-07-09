// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/unsorted/flatten_test/12

import 'dart:async';

class Divergent<T> implements Future<Divergent<Divergent<T>>> {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

test() async {
  Future<Divergent<Divergent<int>>> x = (() async => new Divergent<int>())();
}

main() {}
