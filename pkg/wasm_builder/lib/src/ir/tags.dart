// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import '../serialize/printer.dart';
import 'ir.dart';

/// An exported tag from the current module.
class TagExport extends Export {
  final Tag tag;

  TagExport(super.name, this.tag);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x04);
    s.writeUnsigned(tag.index);
  }
}

/// A tag in a module.
abstract class Tag with Indexable, Exportable {
  @override
  final FinalizableIndex finalizableIndex;
  final FunctionType type;
  @override
  final Module enclosingModule;

  Tag(this.enclosingModule, this.finalizableIndex, this.type);

  @override
  String toString() => "#$name";

  @override
  Export buildExport(String name) {
    return TagExport(name, this);
  }

  void printTo(IrPrinter p);
}

/// A tag defined in the current module.
class DefinedTag extends Tag implements Serializable {
  DefinedTag(super.enclosingModule, super.finalizableIndex, super.type);

  @override
  void serialize(Serializer s) {
    // 0 byte for exception.
    s.writeByte(0x00);
    s.write(type);
  }

  @override
  void printTo(IrPrinter p) {
    p.write('(tag ');
    p.writeTagReference(this);
    p.write(' ');
    type.printOneLineSignatureTo(p);
    p.write(')');
  }
}

/// A tag imported from another module.
class ImportedTag extends Tag implements Import {
  @override
  final String module;

  @override
  final String name;

  ImportedTag(super.enclosingModule, this.module, this.name,
      super.finalizableIndex, super.type);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x04);
    // 0 byte for exception.
    s.writeByte(0x00);
    s.write(type);
  }

  @override
  void printTo(IrPrinter p) {
    p.write('(tag ');
    p.writeTagReference(this);
    p.write(' ');
    p.writeImport(module, name);
    p.write(' ');
    type.printOneLineSignatureTo(p);
    p.write(')');
  }
}

class Tags {
  /// All tags defined in this module.
  final List<DefinedTag> defined;

  /// All tags imported into this module.
  final List<ImportedTag> imported;

  Tags(this.defined, this.imported);

  Tag operator [](int index) => index < imported.length
      ? imported[index]
      : defined[index - imported.length];
}
