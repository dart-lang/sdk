// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'globals.dart';

/// An (imported or defined) global variable.
abstract class Global with Indexable, Exportable {
  @override
  final FinalizableIndex finalizableIndex;
  final GlobalType type;
  @override
  final ModuleBuilder enclosingModule;

  /// Name of the global in the names section.
  final String? globalName;

  Global(
      this.enclosingModule, this.finalizableIndex, this.type, this.globalName);

  @override
  String toString() => globalName ?? "$finalizableIndex";

  @override
  Export buildExport(String name) {
    return GlobalExport(name, this);
  }
}

/// A global variable defined in a module.
class DefinedGlobal extends Global implements Serializable {
  final Instructions initializer;

  DefinedGlobal(super.enclosingModule, this.initializer, super.finalizableIndex,
      super.type,
      [super.globalName]);

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

  ImportedGlobal(super.enclosingModule, this.module, this.name,
      super.finalizableIndex, super.type,
      [super.globalName]);

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
