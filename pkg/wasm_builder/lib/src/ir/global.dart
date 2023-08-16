// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'globals.dart';

/// An (imported or defined) global variable.
abstract class Global implements Exportable {
  final int index;
  final GlobalType type;

  Global(this.index, this.type);

  @override
  String toString() => "$index";

  @override
  Export export(String name) => GlobalExport(name, this);
}

/// A global variable defined in a module.
class DefinedGlobal extends Global implements Serializable {
  final Instructions initializer;

  DefinedGlobal(this.initializer, super.index, super.type);

  @override
  void serialize(Serializer s) {
    s.write(type);
    s.write(initializer);
  }
}

/// An imported global variable.
class ImportedGlobal extends Global implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedGlobal(this.module, this.name, super.index, super.type);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x03);
    s.write(type);
  }
}

class GlobalExport extends Export {
  final Global global;

  GlobalExport(super.name, this.global);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x03);
    s.writeUnsigned(global.index);
  }
}
