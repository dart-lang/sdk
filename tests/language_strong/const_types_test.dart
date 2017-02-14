// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test handling of malformed types in constant expressions.

use(x) {}

class Class<T> implements Superclass {
  const Class();
  const Class.named();

  void test() {
    use(const []);
    use(const <Class>[]);
    use(const <Class<int>>[]);
    use(const <Class<Unresolved>>[]); /// 01: static type warning
    use(const <Unresolved>[]); /// 02: static type warning

    use(const {});
    use(const <Class>{}); /// 03: static type warning
    use(const <String, Class>{});
    use(const <String, Class<int>>{});
    use(const <String, Class<Unresolved>>{}); /// 04: static type warning
    use(const <String, Unresolved>{}); /// 05: static type warning

    use(const Class());
    use(const Class<int>());
    use(const Class<Unresolved>()); /// 06: static type warning
    use(const Class<T>()); /// 07: compile-time error
    use(const Class<Class<T>>()); /// 08: compile-time error

    use(const Unresolved()); /// 09: compile-time error
    use(const Unresolved<int>()); /// 10: compile-time error
    use(const prefix.Unresolved()); /// 11: compile-time error
    use(const prefix.Unresolved<int>()); /// 12: compile-time error

    use(const Class.named());
    use(const Class<int>.named());
    use(const Class<Unresolved>.named()); /// 13: static type warning
    use(const Class<T>.named()); /// 14: compile-time error
    use(const Class<Class<T>>.named()); /// 15: compile-time error

    use(const Class.nonamed()); /// 16: compile-time error
    use(const Class<int>.nonamed()); /// 17: compile-time error
    use(const Class<Unresolved>.nonamed()); /// 18: compile-time error
    use(const Class<T>.nonamed()); /// 19: compile-time error
    use(const Class<Class<T>>.nonamed()); /// 20: compile-time error

    use(const Unresolved.named()); /// 21: compile-time error
    use(const Unresolved<int>.named()); /// 22: compile-time error
  }
}

class Superclass<T> {
  const factory Superclass() = Unresolved; /// 23: compile-time error
  const factory Superclass() = Unresolved<int>; /// 24: compile-time error
  const factory Superclass() = Unresolved.named; /// 25: compile-time error
  const factory Superclass() = Unresolved<int>.named; /// 26: compile-time error

  const factory Superclass() = prefix.Unresolved; /// 27: compile-time error
  const factory Superclass() = prefix.Unresolved<int>; /// 28: compile-time error
  const factory Superclass() = prefix.Unresolved.named; /// 29: compile-time error
  const factory Superclass() = prefix.Unresolved<int>.named; /// 30: compile-time error

  const factory Superclass() = Class; /// 31: ok
  const factory Superclass() = Class<int>; /// 32: ok
  const factory Superclass() = Class<T>; /// 33: ok
  const factory Superclass() = Class<Class<T>>; /// 34: ok
  const factory Superclass() = Class<Unresolved>; /// 35: static type warning

  const factory Superclass() = Class.named; /// 36: ok
  const factory Superclass() = Class<int>.named; /// 37: ok
  const factory Superclass() = Class<T>.named; /// 38: ok
  const factory Superclass() = Class<Class<T>>.named; /// 39: ok
  const factory Superclass() = Class<Unresolved>.named; /// 40: static type warning

  const factory Superclass() = T; /// 41: compile-time error
}

void main() {
  new Class().test();
  new Superclass();
}
