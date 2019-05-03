// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=spread-collections

import 'package:expect/expect.dart';

const constList = [1, 2, 3, 4];
const constSet = {1, 2, 3, 4};
const constMap = {1: 1, 2: 2, 3: 3, 4: 4};

void main() {
  var list = [1, 2, 3];
  var set = {1, 2, 3};
  var map = {1:1, 2:2, 3:3};

  // Spread cannot be used in a const collection.
  const _ = [...list]; //# 00: compile-time error
  const _ = [...constList]; //# 01: compile-time error
  const _ = {...set}; //# 02: compile-time error
  const _ = {...constSet}; //# 03: compile-time error
  const _ = {...map}; //# 04: compile-time error
  const _ = {...constMap}; //# 05: compile-time error
}
