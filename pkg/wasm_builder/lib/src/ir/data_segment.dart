// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../serialize/printer.dart';
import '../serialize/serialize.dart';
import 'ir.dart';

/// A data segment in a module.
class DataSegment implements Serializable {
  late final int index;
  late final Memory? memory;
  late final int? offset;
  late final Uint8List content;

  DataSegment(this.index, this.content, this.memory, this.offset);
  DataSegment.withoutContent(this.index, this.memory, this.offset);
  DataSegment.uninitialized();

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

  void printTo(IrPrinter p) {
    p.write('(data ');
    p.writeDataReference(this);
    p.write(' ');
    p.write('<... ${content.length} bytes ...>');
    p.write(')');
  }
}
