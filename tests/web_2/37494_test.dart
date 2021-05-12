// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for http://dartbug.com/37494

import 'dart:collection';
import 'dart:typed_data';

void main() {
  final u8 = Uint8List(10);
  // Uint8List.{sort,join} are ListMixin.{sort,join} which takes and explicit
  // receiver because Uint8List is an intercepted type.
  u8.sort();
  print(u8.join());

  final list = Example();
  list.addAll([1, 2, 3]);
  list.sort();
  print(list.join());
}

class Example<T> extends ListBase<T> {
  final _list = <T>[];

  @override
  operator [](int index) => _list[index];

  @override
  operator []=(int index, T value) {
    _list[index] = value;
  }

  @override
  int get length => _list.length;

  @override
  set length(int value) {
    _list.length = value;
  }

  @override
  String join([String separator = ""]) {
    return super.join(separator); // This super call had bad dummy interceptor.
  }

  @override
  @pragma('dart2js:noInline')
  void sort([int compare(T a, T b)]) {
    super.sort(compare); // This super call had bad dummy interceptor.
  }
}
