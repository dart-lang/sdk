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
  // Ok
  try {} on F<Class<ConcreteClass>> catch (e) {}
}

t7a() {
  // Error
  try {} on F<Object> catch (e) {}
}

t8a() {
  // Error
  try {} on F<int> catch (e) {}
}

s1a() {
  // Ok
  try {} on G catch (e) {}
}

s2a() {
  // Ok
  try {} on G<dynamic> catch (e) {}
}

s3a() {
  // Ok
  try {} on G<Class> catch (e) {}
}

s4a() {
  // Ok
  try {} on G<Class<dynamic>> catch (e) {}
}

s5a() {
  // Ok
  try {} on G<ConcreteClass> catch (e) {}
}

s6a() {
  // Ok
  try {} on G<Class<ConcreteClass>> catch (e) {}
}

s7a() {
  // Error
  try {} on G<Object> catch (e) {}
}

s8a() {
  // Error
  try {} on G<int> catch (e) {}
}

t1b() {
  // Ok
  try {} on F catch (e) {}
}

t2b() {
  // Ok
  try {} on F<dynamic> catch (e) {}
}

t3b() {
  // Ok
  try {} on F<Class> catch (e) {}
}

t4b() {
  // Ok
  try {} on F<Class<dynamic>> catch (e) {}
}

t5b() {
  // Ok
  try {} on F<ConcreteClass> catch (e) {}
}

t6b() {
  // Ok
  try {} on F<Class<ConcreteClass>> catch (e) {}
}

t7b() {
  // Error
  try {} on F<Object> catch (e) {}
}

t8b() {
  // Error
  try {} on F<int> catch (e) {}
}

s1b() {
  // Ok
  try {} on G catch (e) {}
}

s2b() {
  // Ok
  try {} on G<dynamic> catch (e) {}
}

s3b() {
  // Ok
  try {} on G<Class> catch (e) {}
}

s4b() {
  // Ok
  try {} on G<Class<dynamic>> catch (e) {}
}

s5b() {
  // Ok
  try {} on G<ConcreteClass> catch (e) {}
}

s6b() {
  // Ok
  try {} on G<Class<ConcreteClass>> catch (e) {}
}

s7b() {
  // Error
  try {} on G<Object> catch (e) {}
}

s8b() {
  // Error
  try {} on G<int> catch (e) {}
}

main() {}
