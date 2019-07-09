// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: C:OutputUnit(main, {})*/
class C<T> {
  /*strong.member: C.:OutputUnit(main, {})*/
  const C();
}

/*class: D:OutputUnit(main, {})*/
class D {}

/*strong.member: field:OutputUnit(main, {})*/
const dynamic field = /*strong.OutputUnit(main, {})*/ const C<D>();
