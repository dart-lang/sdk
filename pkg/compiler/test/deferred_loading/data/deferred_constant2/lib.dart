// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library deferred_constants2_lib;

/*class: Constant:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class Constant {
  /*member: Constant.value:member_unit=1{lib}*/
  final value;

  const Constant(this.value);

  /*member: Constant.==:member_unit=1{lib}*/
  @override
  operator ==(other) => other is Constant && value == other.value;

  /*member: Constant.hashCode:member_unit=1{lib}*/
  @override
  get hashCode => 0;
}

const C1 = const Constant(499);
