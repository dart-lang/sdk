// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies correct type assignment of type to const maps.

enum _AttributeName {
  name,
  sibling,
}

const _attributeNames = <int, _AttributeName>{
  0x01: _AttributeName.sibling,
  0x03: _AttributeName.name,
};

class _Attribute {
  final _AttributeName name;

  // This should not be thrown away by TFA.
  _Attribute._(this.name);

  static _Attribute fromReader(int nameInt) {
    final name = _attributeNames[nameInt]!;
    return _Attribute._(name);
  }
}

void main() {
  final result = _Attribute.fromReader(1);

  print(result);
}
