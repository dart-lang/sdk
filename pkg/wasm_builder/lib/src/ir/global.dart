// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import '../serialize/printer.dart';
import 'ir.dart';

/// An (imported or defined) global variable.
abstract class Global with Indexable, Exportable {
  @override
  final FinalizableIndex finalizableIndex;
  final GlobalType type;
  @override
  final Module enclosingModule;

  /// Name of the global in the names section.
  String? globalName;

  Global(this.enclosingModule, this.finalizableIndex, this.type,
      [this.globalName]);

  @override
  String toString() => globalName ?? "$finalizableIndex";

  @override
  Export buildExport(String name) {
    return GlobalExport(name, this);
  }

  void printTo(IrPrinter p, {bool includeInitializer = true}) =>
      throw 'not implemented';
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

  @override
  void printTo(IrPrinter p, {bool includeInitializer = true}) {
    // This may generate globals this one refers to.
    final ip = p.dup();
    if (includeInitializer) {
      initializer.printInitializerTo(ip);
    }

    p.write('(global ');
    p.writeGlobalReference(this);
    p.write(' ');
    type.printTo(p);
    if (includeInitializer) {
      if (p.preferMultiline) {
        p.indent();
        p.writeln();
      } else {
        p.write(' ');
      }
      p.write(ip.getText().trim());
      if (p.preferMultiline) {
        p.deindent();
      }
    } else {
      p.write(' <...>');
    }
    p.write(')');
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

  @override
  void printTo(IrPrinter p, {bool includeInitializer = true}) {
    p.write('(global ');
    p.writeGlobalReference(this);
    p.write(' ');
    p.writeImport(module, name);
    p.write(' ');
    p.writeValueType(type.type);
    p.write(')');
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
