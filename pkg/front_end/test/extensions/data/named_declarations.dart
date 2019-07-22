// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {}

/*class: A2:
 builder-name=A2,
 builder-onTypes=[A1],
 builder-supertype=Object,
 cls-name=A2,
 cls-supertype=Object
*/
extension A2 on A1 {}

class B1<T> {}

/*class: B2:
 builder-name=B2,
 builder-onTypes=[B1<T>],
 builder-supertype=Object,
 builder-type-params=[T],
 cls-name=B2,
 cls-supertype=Object,
 cls-type-params=[T]
*/
extension B2<T> on B1<T> {}

// TODO(johnniwinther): Remove class type parameters.
/*class: B3:
 builder-name=B3,
 builder-onTypes=[B1<A1>],
 builder-supertype=Object,
 cls-name=B3,
 cls-supertype=Object
*/
extension B3 on B1<A1> {}

// TODO(johnniwinther): Remove class type parameters.
/*class: B4:
 builder-name=B4,
 builder-onTypes=[B1<T>],
 builder-supertype=Object,
 builder-type-params=[T extends A1],
 cls-name=B4,
 cls-supertype=Object,
 cls-type-params=[T extends A1]
*/
extension B4<T extends A1> on B1<T> {}

main() {}
