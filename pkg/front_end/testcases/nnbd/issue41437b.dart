// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic getNull() => null;
Iterable<dynamic> getIterableNull() sync* {
  yield null;
}

Iterable<bool> getIterableBool() sync* {
  yield true;
}

Iterable<bool> test1() sync* {
  yield getNull(); // ok
}

Iterable<bool> test2() => getNull(); // ok
bool test3() => getNull(); // ok
Iterable<bool> test4() sync* {
  yield* getIterableNull(); // error
}

Iterable<bool> test5() => getIterableNull(); // error
Iterable<bool> test6() => getIterableBool(); // ok
Iterable<bool> test7() sync* {
  yield* getIterableBool(); // ok
}

test() async {
  Iterable<bool> test1() sync* {
    yield getNull(); // ok
  }

  Iterable<bool> test2() => getNull(); // ok
  bool test3() => getNull(); // ok
  Iterable<bool> test4() sync* {
    yield* getIterableNull(); // error
  }

  Iterable<bool> test5() => getIterableNull(); // error
  Iterable<bool> test6() => getIterableBool(); // ok
  Iterable<bool> test7() sync* {
    yield* getIterableBool(); // ok
  }

  Iterable<bool> var1 = (() sync* {
    yield getNull();
  })(); // error
  Iterable<bool> var2 = (() => getNull())(); // ok
  bool var3 = (() => getNull())(); // ok
  Iterable<bool> var4 = (() sync* {
    yield* getIterableNull();
  })(); // error
  Iterable<bool> var5 = (() => getIterableNull())(); // error
  Iterable<bool> var6 = (() => getIterableBool())(); // ok
  Iterable<bool> var7 = (() sync* {
    yield* getIterableBool();
  })(); // ok
}

main() {}
