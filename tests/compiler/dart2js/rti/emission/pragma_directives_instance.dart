// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
value(o) => o;

main() {
  var c = new Class();
  value(c).method1a(value(null));
  value(c).method1b(value(null));
  value(c).method2a(value(null));
  value(c).method2b(value(null));
  value(c).method3a(value(null));
  value(c).method3b(value(null));
  value(c).method4a(value(null));
  value(c).method4b(value(null));
  value(c).method5a(value(null));
  value(c).method5b(value(null));
  value(c).method6a(value(null));
  value(c).method6b(value(null));
}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class1a:checkedInstance*/
class Class1a {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class1b:*/
class Class1b {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class2a:checkedInstance*/
class Class2a {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class2b:*/
class Class2b {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class3a:checkedInstance*/
class Class3a {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class3b:*/
class Class3b {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class4a:checkedInstance*/
class Class4a<T> {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class4b:*/
class Class4b<T> {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class5a:checkedInstance*/
class Class5a<T> {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class5b:*/
class Class5b<T> {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class6a:checkedInstance*/
class Class6a<T> {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class6b:*/
class Class6b<T> {}

/*class: Class:checks=[],instance*/
class Class {
  @pragma('dart2js:parameter:check')
  method1a(Class1a c) {}

  @pragma('dart2js:parameter:trust')
  method1b(Class1b c) {}

  @pragma('dart2js:downcast:check')
  Class2a method2a(o) => o;

  @pragma('dart2js:downcast:trust')
  Class2b method2b(o) => o;

  @pragma('dart2js:as:check')
  method3a(o) => o as Class3a;

  @pragma('dart2js:as:trust')
  method3b(o) => o as Class3b;

  @pragma('dart2js:parameter:check')
  method4a(Class4a<int> c) {}

  @pragma('dart2js:parameter:trust')
  method4b(Class4b<int> c) {}

  @pragma('dart2js:downcast:check')
  Class5a<int> method5a(o) => o;

  @pragma('dart2js:downcast:trust')
  Class5b<int> method5b(o) => o;

  @pragma('dart2js:as:check')
  method6a(o) => o as Class6a<int>;

  @pragma('dart2js:as:trust')
  method6b(o) => o as Class6b<int>;
}
