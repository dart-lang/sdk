// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  method1a(null);
  method1b(null);
  method2a(null);
  method2b(null);
  method3a(null);
  method3b(null);
  method4a(null);
  method4b(null);
  method5a(null);
  method5b(null);
  method6a(null);
  method6b(null);
}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class1a:explicit=[Class1a*]*/
class Class1a {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class1b:*/
class Class1b {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class2a:explicit=[Class2a*]*/
class Class2a {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class2b:*/
class Class2b {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class3a:explicit=[Class3a*]*/
class Class3a {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class3b:*/
class Class3b {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class4a:explicit=[Class4a<int*>*],needsArgs*/
class Class4a<T> {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class4b:*/
class Class4b<T> {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class5a:explicit=[Class5a<int*>*],needsArgs*/
class Class5a<T> {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class5b:*/
class Class5b<T> {}

// Checks are needed both with and without --omit-implicit-checks.
/*class: Class6a:explicit=[Class6a<int*>*],needsArgs*/
class Class6a<T> {}

// Checks are needed neither with nor without --omit-implicit-checks.
/*class: Class6b:*/
class Class6b<T> {}

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
