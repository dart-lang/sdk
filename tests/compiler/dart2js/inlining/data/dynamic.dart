// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

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
  @NoInline()
  Class1();

  /*element: Class1.method:[forceInlineDynamic]*/
  @ForceInline()
  method() {}
}

/*element: forceInlineDynamic:[]*/
@NoInline()
forceInlineDynamic() {
  new Class1().method();
}

////////////////////////////////////////////////////////////////////////////////
// Force inline a instance method with optional argument.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*element: Class2.:[]*/
  @NoInline()
  Class2();

  /*element: Class2.method:[forceInlineOptional]*/
  @ForceInline()
  method([x]) {}
}

/*element: forceInlineOptional:[]*/
@NoInline()
forceInlineOptional() {
  new Class2().method();
}
