// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/printer.dart';
import '../serialize/serialize.dart';
import 'ir.dart';

/// An (imported or defined) memory.
abstract class Memory with Indexable, Exportable {
  @override
  final FinalizableIndex finalizableIndex;
  final bool shared;
  final int minSize;
  final int? maxSize;
  @override
  final Module enclosingModule;

  Memory(this.enclosingModule, this.finalizableIndex, this.shared, this.minSize,
      [this.maxSize]) {
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
  Export buildExport(String name) => MemoryExport(name, this);

  void printTo(IrPrinter p);

  void _printType(IrPrinter p) {
    // We don't encode the optional address type in our representation because
    // it defaults to i32 and we don't support 64-bit addressing yet.

    p.write('$minSize');
    if (maxSize case final max?) {
      p.write(' $max');
    }
  }
}

/// A memory defined in a module.
class DefinedMemory extends Memory implements Serializable {
  DefinedMemory(super.enclosingModule, super.finalizableIndex, super.shared,
      super.minSize, super.maxSize);

  @override
  void serialize(Serializer s) => _serializeLimits(s);

  @override
  void printTo(IrPrinter p) {
    p.write('(memory ');
    p.writeMemoryReference(this);
    String? exportName;
    for (final e in enclosingModule.exports.exported) {
      if (e is MemoryExport && e.memory == this) {
        exportName = e.name;
        break;
      }
    }
    if (exportName != null) {
      p.write(' ');
      p.writeExport(exportName);
    }

    p.write(' ');
    _printType(p);
    p.write(')');
  }
}

/// An imported memory.
class ImportedMemory extends Memory implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedMemory(super.enclosingModule, this.module, this.name,
      super.finalizableIndex, super.shared, super.minSize, super.maxSize);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x02);
    _serializeLimits(s);
  }

  @override
  void printTo(IrPrinter p) {
    p.write('(memory ');
    p.writeMemoryReference(this);
    p.write(' ');
    p.writeImport(module, name);
    p.write(' ');
    _printType(p);
    p.write(')');
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
