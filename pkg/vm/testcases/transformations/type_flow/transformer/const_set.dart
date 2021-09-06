// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies correct type assignment of type to const sets.

enum _AttributeName {
  name,
  sibling,
}

const _attributeNames = <int>{
  0x00,
  0x01,
};

class _Attribute {
  final _AttributeName name;

  // This should not be thrown away by TFA.
  _Attribute._(this.name);

  static _Attribute fromReader(int nameInt) {
    final name = _attributeNames.contains(nameInt);

    // This should not be transformed into
    // "Attempt to execute code removed by Dart AOT compiler".
    return _Attribute._(_AttributeName.values[nameInt]);
  }
}

void main() {
  final result = _Attribute.fromReader(1);

  print(result);
}
