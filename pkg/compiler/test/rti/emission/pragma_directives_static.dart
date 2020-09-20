// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
value(o) => o;

main() {
  method1a(value(null));
  method1b(value(null));
  method2a(value(null));
  method2b(value(null));
  method3a(value(null));
  method3b(value(null));
  method4a(value(null));
  method4b(value(null));
  method5a(value(null));
  method5b(value(null));
  method6a(value(null));
  method6b(value(null));
}

// TODO(johnniwinther,sra): Find a way to check parameter checks on static
// methods. For [Class1a], [Class1b], [Class4a] and [Class4b] either the CFE
// inserts an implicit cast at the call-site or we disregard the forced check
// because it is a static call.

/*spec.class: Class1a:checkedInstance*/
class Class1a {}

/*spec.class: Class1b:checkedInstance*/
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

/*spec.class: Class4a:checkedInstance*/
class Class4a<T> {}

/*spec.class: Class4b:checkedInstance*/
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
