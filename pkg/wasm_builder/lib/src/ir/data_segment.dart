// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'data_segments.dart';

class BaseDataSegment {
  final int index;
  final Memory? memory;
  final int? offset;

  BaseDataSegment(this.index, this.memory, this.offset);
}

/// A data segment in a module.
class DataSegment extends BaseDataSegment implements Serializable {
  final Uint8List content;

  DataSegment(super.index, this.content, super.memory, super.offset);

  @override
  void serialize(Serializer s) {
    if (memory != null) {
      // Active segment
      if (memory!.index == 0) {
        s.writeByte(0x00);
      } else {
        s.writeByte(0x02);
        s.writeUnsigned(memory!.index);
      }
      s.writeByte(0x41); // i32.const
      s.writeSigned(offset!);
      s.writeByte(0x0B); // end
    } else {
      // Passive segment
      s.writeByte(0x01);
    }
    s.writeUnsigned(content.length);
    s.writeBytes(content);
  }
}
