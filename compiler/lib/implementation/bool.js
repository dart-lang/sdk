// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



function native_BoolImplementation_EQ(other) {
  if (typeof other == 'boolean') {
    return this == other;
  } else if (other instanceof Boolean) {
    // Must convert other to a primitive for value equality to work
    return this == Boolean(other);
  } else {
    return false;
  }
}

function native_BoolImplementation_toString() {
  return (this == true) ? "true" : "false";
}
