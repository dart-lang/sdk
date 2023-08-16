// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'memories.dart';

/// An (imported or defined) memory.
class Memory implements Exportable {
  final int index;
  final bool shared;
  final int minSize;
  final int? maxSize;

  Memory(this.index, this.shared, this.minSize, [this.maxSize]) {
    if (shared && maxSize == null) {
      throw "Shared memory must specify a maximum size.";
    }
  }

  void _serializeLimits(Serializer s) {
    if (shared) {
      assert(maxSize != null);
      s.writeByte(0x03);
      s.writeUnsigned(minSize);
      s.writeUnsigned(maxSize!);
    } else if (maxSize == null) {
      s.writeByte(0x00);
      s.writeUnsigned(minSize);
    } else {
      s.writeByte(0x01);
      s.writeUnsigned(minSize);
      s.writeUnsigned(maxSize!);
    }
  }

  /// Export a memory from the module.
  @override
  Export export(String name) => MemoryExport(name, this);
}

/// A memory defined in a module.
class DefinedMemory extends Memory implements Serializable {
  DefinedMemory(super.index, super.shared, super.minSize, super.maxSize);

  @override
  void serialize(Serializer s) => _serializeLimits(s);
}

/// An imported memory.
class ImportedMemory extends Memory implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedMemory(this.module, this.name, super.index, super.shared,
      super.minSize, super.maxSize);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x02);
    _serializeLimits(s);
  }
}

class MemoryExport extends Export {
  final Memory memory;

  MemoryExport(super.name, this.memory);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x02);
    s.writeUnsigned(memory.index);
  }
}
