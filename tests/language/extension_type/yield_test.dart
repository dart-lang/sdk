// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'dart:async';
import 'package:expect/expect.dart';

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MyStream<T>(Stream<T> it) implements Stream<T> {}

MyList<T> copyList<T>(MyList<T> list) {
  List<T> result = [];
  for (var a in list) {
    result.add(a);
  }
  return MyList<T>(result);
}

Iterable<T> duplicateList<T>(MyList<T> list) sync* {
  for (var a in list) {
    yield a;
  }
  yield* list;
}

Stream<T> toStream<T>(MyList<T> list) async* {
  for (var a in list) {
     yield a;
  }
}

Future<List<T>> toList<T>(MyStream<T> stream) async {
  List<T> result = [];
  await for (var a in stream) {
    result.add(a);
  }
  return result;
}

Stream<T> duplicateStream<T>(MyStream<T> stream1, MyStream<T> stream2) async* {
  await for (var a in stream1) {
    yield a;
  }
  yield* stream2;
}

main() async {
  MyList<int> list = MyList<int>([1, 2, 3]);
  Expect.listEquals([1, 2, 3], copyList(list));
  Expect.listEquals([1, 2, 3, 1, 2, 3], duplicateList(list).toList());

  MyStream<int> stream = MyStream<int>(toStream<int>(list));
  Expect.listEquals([1, 2, 3], await toList(stream));
  MyStream<int> stream1 = MyStream<int>(toStream<int>(list));
  MyStream<int> stream2 = MyStream<int>(toStream<int>(list));
  Expect.listEquals([1, 2, 3, 1, 2, 3], 
      await toList(MyStream<int>(duplicateStream(stream1, stream2))));
}