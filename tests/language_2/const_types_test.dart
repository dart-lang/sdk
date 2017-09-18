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
    use(const <Class<Unresolved>>[]); /*@compile-error=unspecified*/
    use(const <Unresolved>[]); /*@compile-error=unspecified*/

    use(const {});
    use(const <Class>{}); /*@compile-error=unspecified*/
    use(const <String, Class>{});
    use(const <String, Class<int>>{});
    use(const <String, Class<Unresolved>>{}); /*@compile-error=unspecified*/
    use(const <String, Unresolved>{}); /*@compile-error=unspecified*/

    use(const Class());
    use(const Class<int>());
    use(const Class<Unresolved>()); /*@compile-error=unspecified*/
    use(const Class<T>()); /*@compile-error=unspecified*/
    use(const Class<Class<T>>()); /*@compile-error=unspecified*/

    use(const Unresolved()); /*@compile-error=unspecified*/
    use(const Unresolved<int>()); /*@compile-error=unspecified*/
    use(const prefix.Unresolved()); /*@compile-error=unspecified*/
    use(const prefix.Unresolved<int>()); /*@compile-error=unspecified*/

    use(const Class.named());
    use(const Class<int>.named());
    use(const Class<Unresolved>.named()); /*@compile-error=unspecified*/
    use(const Class<T>.named()); /*@compile-error=unspecified*/
    use(const Class<Class<T>>.named()); /*@compile-error=unspecified*/

    use(const Class.nonamed()); /*@compile-error=unspecified*/
    use(const Class<int>.nonamed()); /*@compile-error=unspecified*/
    use(const Class<Unresolved>.nonamed()); /*@compile-error=unspecified*/
    use(const Class<T>.nonamed()); /*@compile-error=unspecified*/
    use(const Class<Class<T>>.nonamed()); /*@compile-error=unspecified*/

    use(const Unresolved.named()); /*@compile-error=unspecified*/
    use(const Unresolved<int>.named()); /*@compile-error=unspecified*/
  }
}

class Superclass<T> {
  const factory Superclass() = Unresolved; /*@compile-error=unspecified*/
  const factory Superclass() = Unresolved<int>; /*@compile-error=unspecified*/
  const factory Superclass() = Unresolved.named; /*@compile-error=unspecified*/
  const factory Superclass() =
      Unresolved<int>.named; /*@compile-error=unspecified*/

  const factory Superclass() = prefix.Unresolved; /*@compile-error=unspecified*/
  const factory Superclass() =
      prefix.Unresolved<int>; /*@compile-error=unspecified*/
  const factory Superclass() =
      prefix.Unresolved.named; /*@compile-error=unspecified*/
  const factory Superclass() =
      prefix.Unresolved<int>.named; /*@compile-error=unspecified*/

  const factory Superclass() = Class; /*@compile-error=unspecified*/
  const factory Superclass() = Class<int>; /*@compile-error=unspecified*/
  const factory Superclass() = Class<T>; /*@compile-error=unspecified*/
  const factory Superclass() = Class<Class<T>>; /*@compile-error=unspecified*/
  const factory Superclass() = Class<Unresolved>; /*@compile-error=unspecified*/

  const factory Superclass() = Class.named; /*@compile-error=unspecified*/
  const factory Superclass() = Class<int>.named; /*@compile-error=unspecified*/
  const factory Superclass() = Class<T>.named; /*@compile-error=unspecified*/
  const factory Superclass() =
      Class<Class<T>>.named; /*@compile-error=unspecified*/
  const factory Superclass() =
      Class<Unresolved>.named; /*@compile-error=unspecified*/

  const factory Superclass() = T; /*@compile-error=unspecified*/
}

void main() {
  new Class().test();
  new Superclass();
}
