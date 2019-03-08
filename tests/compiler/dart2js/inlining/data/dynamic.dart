// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[]*/
main() {
  forceInlineDynamic();
  forceInlineOptional();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a dynamic call.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*element: Class1.:[]*/
  @pragma('dart2js:noInline')
  Class1();

  /*element: Class1.method:[forceInlineDynamic]*/
  @pragma('dart2js:tryInline')
  method() {}
}

/*element: forceInlineDynamic:[]*/
@pragma('dart2js:noInline')
forceInlineDynamic() {
  new Class1().method();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a instance method with optional argument.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*element: Class2.:[]*/
  @pragma('dart2js:noInline')
  Class2();

  /*element: Class2.method:[forceInlineOptional]*/
  @pragma('dart2js:tryInline')
  method([x]) {}
}

/*element: forceInlineOptional:[]*/
@pragma('dart2js:noInline')
forceInlineOptional() {
  new Class2().method();
}
