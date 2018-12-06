// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N test_types_in_equals`

class Field {}

class Good {
  final Field someField;

  Good(this.someField);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Good && this.someField == other.someField;
  }

  @override
  int get hashCode {
    return someField.hashCode;
  }
}

class Bad {
  final Field someField;

  Bad(this.someField);

  @override
  bool operator ==(Object other) {
    Bad otherBad = other as Bad; // LINT
    return otherBad != null && otherBad.someField == someField;
  }

  @override
  int get hashCode {
    return someField.hashCode;
  }
}
