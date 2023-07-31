// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'functions.dart';

/// A local variable defined in a function.
class Local {
  final int index;
  final ValueType type;

  Local(this.index, this.type);

  @override
  String toString() => "$index";
}

/// An (imported or defined) function.
abstract class BaseFunction implements Exportable {
  final int index;
  final FunctionType type;
  final String? functionName;
  String? exportedName;

  BaseFunction(this.index, this.type, this.functionName);

  /// Creates an export of this function in this module.
  @override
  Export export(String name) {
    assert(exportedName == null);
    exportedName = name;
    return FunctionExport(name, this);
  }
}

/// A function defined in a module.
class DefinedFunction extends BaseFunction implements Serializable {
  final Instructions body;

  /// All local variables defined in the function, including its inputs.
  List<Local> get locals => body.locals;

  DefinedFunction(this.body, super.index, super.type, [super.functionName]);

  @override
  void serialize(Serializer s) {
    // Serialize locals internally first in order to compute the total size of
    // the serialized data.
    final localS = Serializer();
    int paramCount = type.inputs.length;
    int entries = 0;
    for (int i = paramCount + 1; i <= locals.length; i++) {
      if (i == locals.length || locals[i - 1].type != locals[i].type) entries++;
    }
    localS.writeUnsigned(entries);
    int start = paramCount;
    for (int i = paramCount + 1; i <= locals.length; i++) {
      if (i == locals.length || locals[i - 1].type != locals[i].type) {
        localS.writeUnsigned(i - start);
        localS.write(locals[i - 1].type);
        start = i;
      }
    }

    // Bundle locals and body
    localS.write(body);
    s.writeUnsigned(localS.data.length);
    s.writeData(localS);
  }

  @override
  String toString() => exportedName ?? "#$index";
}

/// An imported function.
class ImportedFunction extends BaseFunction implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedFunction(this.module, this.name, super.index, super.type,
      [super.functionName]);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x00);
    s.writeUnsigned(type.index);
  }

  @override
  String toString() => "$module.$name";
}

class FunctionExport extends Export {
  final BaseFunction function;

  FunctionExport(super.name, this.function);

  @override
  void serialize(Serializer s) {
    s.writeName(name);
    s.writeByte(0x00);
    s.writeUnsigned(function.index);
  }
}
