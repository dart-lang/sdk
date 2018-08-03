// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_constants2_lib;

/*class: Constant:OutputUnit(1, {lib})*/
class Constant {
  /*element: Constant.value:OutputUnit(1, {lib})*/
  final value;
  /*element: Constant.:OutputUnit(1, {lib})*/
  const Constant(this.value);

  /*element: Constant.==:OutputUnit(1, {lib})*/
  operator ==(other) => other is Constant && value == other.value;
  /*element: Constant.hashCode:OutputUnit(1, {lib})*/
  get hashCode => 0;
}

/*element: C1:OutputUnit(1, {lib})*/
const C1 = /*OutputUnit(1, {lib})*/ const Constant(499);
