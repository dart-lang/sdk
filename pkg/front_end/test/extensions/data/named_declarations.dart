// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[A2,B2,B3,B4]*/

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

/*class: B3:
 builder-name=B3,
 builder-onType=B1<A1>,
 extension-name=B3,
 extension-onType=B1<A1>
*/
extension B3 on B1<A1> {}

/*class: B4:
 builder-name=B4,
 builder-onType=B1<T>,
 builder-type-params=[T extends A1],
 extension-name=B4,extension-onType=B1<T>,
 extension-type-params=[T extends A1]
*/
extension B4<T extends A1> on B1<T> {}

main() {}
