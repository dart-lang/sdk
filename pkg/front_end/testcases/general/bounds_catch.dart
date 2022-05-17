// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = X;

class G<X extends Class<X>> {}

t1a() {
  try {} on F catch (e) {
    // Ok
  }
}

t2a() {
  try {} on F<dynamic> catch (e) {
    // Ok
  }
}

t3a() {
  try {} on F<Class> catch (e) {
    // Ok
  }
}

t4a() {
  try {} on F<Class<dynamic>> catch (e) {
    // Ok
  }
}

t5a() {
  try {} on F<ConcreteClass> catch (e) {
    // Ok
  }
}

t6a() {
  try {} on F<Class<ConcreteClass>> catch (e) {
    // Ok
  }
}

t7a() {
  try {} on F<Object> catch (e) {
    // Error
  }
}

t8a() {
  try {} on F<int> catch (e) {
    // Error
  }
}

s1a() {
  try {} on G catch (e) {
    // Ok
  }
}

s2a() {
  try {} on G<dynamic> catch (e) {
    // Ok
  }
}

s3a() {
  try {} on G<Class> catch (e) {
    // Ok
  }
}

s4a() {
  try {} on G<Class<dynamic>> catch (e) {
    // Ok
  }
}

s5a() {
  try {} on G<ConcreteClass> catch (e) {
    // Ok
  }
}

s6a() {
  try {} on G<Class<ConcreteClass>> catch (e) {
    // Ok
  }
}

s7a() {
  try {} on G<Object> catch (e) {
    // Error
  }
}

s8a() {
  try {} on G<int> catch (e) {
    // Error
  }
}

t1b() {
  try {} on F catch (e) {
    // Ok
  }
}

t2b() {
  try {} on F<dynamic> catch (e) {
    // Ok
  }
}

t3b() {
  try {} on F<Class> catch (e) {
    // Ok
  }
}

t4b() {
  try {} on F<Class<dynamic>> catch (e) {
    // Ok
  }
}

t5b() {
  try {} on F<ConcreteClass> catch (e) {
    // Ok
  }
}

t6b() {
  try {} on F<Class<ConcreteClass>> catch (e) {
    // Ok
  }
}

t7b() {
  try {} on F<Object> catch (e) {
    // Error
  }
}

t8b() {
  try {} on F<int> catch (e) {
    // Error
  }
}

s1b() {
  try {} on G catch (e) {
    // Ok
  }
}

s2b() {
  try {} on G<dynamic> catch (e) {
    // Ok
  }
}

s3b() {
  try {} on G<Class> catch (e) {
    // Ok
  }
}

s4b() {
  try {} on G<Class<dynamic>> catch (e) {
    // Ok
  }
}

s5b() {
  try {} on G<ConcreteClass> catch (e) {
    // Ok
  }
}

s6b() {
  try {} on G<Class<ConcreteClass>> catch (e) {
    // Ok
  }
}

s7b() {
  try {} on G<Object> catch (e) {
    // Error
  }
}

s8b() {
  try {} on G<int> catch (e) {
    // Error
  }
}

main() {}
