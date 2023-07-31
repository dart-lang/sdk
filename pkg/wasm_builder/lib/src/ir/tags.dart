// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import 'ir.dart';

/// A tag in a module.
class Tag implements Serializable {
  final int index;
  final FunctionType type;

  Tag(this.index, this.type);

  @override
  void serialize(Serializer s) {
    // 0 byte for exception.
    s.writeByte(0x00);
    s.write(type);
  }

  @override
  String toString() => "#$index";
}

class Tags {
  /// All tags defined in this module.
  final List<Tag> defined;

  Tags(this.defined);
}
