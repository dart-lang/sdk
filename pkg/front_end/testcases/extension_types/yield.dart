// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MyStream<T>(Stream<T> it) implements Stream<T> {}

method(MyList<int> list, MyStream<String> stream) {
  var a = () sync* {
    yield* list;
  };
  var b = () async* {
    yield* stream;
  };
}
