// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_BoolImplementation_EQ(other) {
  throw Error('UNREACHABLE');
}

function native_BoolImplementation_toString() {
  return this.toString();
}

function native_BoolImplementation_toBool() {
  return this == true;
}
