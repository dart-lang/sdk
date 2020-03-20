// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

/*cfe|cfe:builder.class: A:A,Object*/
/*analyzer.class: A:A,Function,Object*/
class A implements Function {}

/*cfe|cfe:builder.class: B:B,Object*/
/*analyzer.class: B:B,Function,Object*/
class B extends Function {}

/*class: C:C,Function,Object*/
class C extends Object with Function {
  /*cfe|cfe:builder.member: C.hashCode:int**/
  /*cfe|cfe:builder.member: C.==:bool* Function(Object*)**/
}
