// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic getNull() => null;
Stream<dynamic> getStreamNull() async* {
  yield null;
}

Stream<bool> getStreamBool() async* {
  yield true;
}

Stream<bool> test1() async* {
  yield getNull(); // ok
}

Stream<bool> test2() => getNull(); // ok
bool test3() => getNull(); // ok
Stream<bool> test4() async* {
  yield* getStreamNull(); // error
}

Stream<bool> test5() => getStreamNull(); // error
Stream<bool> test6() => getStreamBool(); // ok
Stream<bool> test7() async* {
  yield* getStreamBool(); // ok
}

test() async {
  Stream<bool> test1() async* {
    yield getNull(); // ok
  }

  Stream<bool> test2() => getNull(); // ok
  bool test3() => getNull(); // ok
  Stream<bool> test4() async* {
    yield* getStreamNull(); // error
  }

  Stream<bool> test5() => getStreamNull(); // error
  Stream<bool> test6() => getStreamBool(); // ok
  Stream<bool> test7() async* {
    yield* getStreamBool(); // ok
  }

  Stream<bool> var1 = (() async* {
    yield getNull();
  })(); // error
  Stream<bool> var2 = (() => getNull())(); // ok
  bool var3 = (() => getNull())(); // ok
  Stream<bool> var4 = (() async* {
    yield* getStreamNull();
  })(); // error
  Stream<bool> var5 = (() => getStreamNull())(); // error
  Stream<bool> var6 = (() => getStreamBool())(); // ok
  Stream<bool> var7 = (() async* {
    yield* getStreamBool();
  })(); // ok
}

main() {}
