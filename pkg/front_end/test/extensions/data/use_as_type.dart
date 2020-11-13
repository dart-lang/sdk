// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[A2,B2]*/

class A1 {}

/*class: A2:
 builder-name=A2,
 builder-onType=A1,
 extension-name=A2,
 extension-onType=A1
*/
extension A2 on A1 {}

class B1<T> {}

/*class: B2:
 builder-name=B2,
 builder-onType=B1<T>,
 builder-type-params=[T],
 extension-name=B2,
 extension-onType=B1<T>,
 extension-type-params=[T]
*/
extension B2<T> on B1<T> {}

main() {
  /*error: errors=['A2' isn't a type.]*/
  A2 var1;
  /*error: errors=['B2' isn't a type.]*/
  B2<A1> var2;
  B1</*error: errors=['A2' isn't a type.]*/A2> var3;
}

/*error: errors=['A2' isn't a type.]*/
A2 method1() => null;

// TODO(johnniwinther): We should report an error on the number of type
// arguments here.
/*error: errors=['B2' isn't a type.,Expected 0 type arguments.]*/
B2<A1> method2() => null;

B1</*error: errors=['A2' isn't a type.]*/A2> method3() => null;
