// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/printer.dart';
import '../serialize/serialize.dart';
import 'ir.dart';

/// A local variable defined in a function.
class Local {
  final int index;
  final ValueType type;

  Local(this.index, this.type);

  void printTo(IrPrinter p, Map<int, String> localNames,
      {bool isParam = false}) {
    p.write(isParam ? 'param' : 'local');
    p.write(' ');
    p.writeLocalIndexReference(index);
    p.write(' ');
    p.writeValueType(type);
  }

  @override
  String toString() => "$index";
}

/// An (imported or defined) function.
abstract class BaseFunction with Indexable, Exportable {
  @override
  final FinalizableIndex finalizableIndex;
  final FunctionType type;
  String? functionName;
  @override
  final Module enclosingModule;

  /// Whether this function is pure and has no effect.
  ///
  /// If marked as spure, we'll emit metadata in the
  /// `binaryen.removable.if.unused` custom section.
  bool isPure = false;

  BaseFunction(this.enclosingModule, this.finalizableIndex, this.type,
      [this.functionName]);

  @override
  String get name => functionName ?? super.name;

  /// Creates an export of this function in this module.
  @override
  Export buildExport(String name) {
    return FunctionExport(name, this);
  }
}

/// A function defined in a module.
class DefinedFunction extends BaseFunction implements Serializable {
  late final Instructions body;

  /// All local variables defined in the function, including its inputs.
  List<Local> get locals => body.locals;

  Map<int, String> get localNames => body.localNames;

  DefinedFunction(
      super.enclosingModule, this.body, super.finalizableIndex, super.type,
      [super.functionName]);

  DefinedFunction.withoutBody(
      super.enclosingModule, super.finalizableIndex, super.type,
      [super.functionName]);

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
    s.sourceMapSerializer.copyMappings(localS.sourceMapSerializer, s.offset);
    s.writeData(localS);
  }

  void printTo(IrPrinter p) {
    if (isPure) {
      p.writeln('(@binaryen.removable.if.unused)');
    }
    p.write('(func ');
    p.writeFunctionReference(this);
    String? exportName;
    for (final f in enclosingModule.exports.exported) {
      if (f is FunctionExport && f.function == this) {
        exportName = f.name;
        break;
      }
    }
    if (exportName != null) {
      p.write(' ');
      p.writeExport(exportName);
    }

    p.withLocalNames(localNames, () {
      if (type.inputs.isNotEmpty || type.outputs.isNotEmpty) {
        p.write(' ');
        type.printSignatureWithNamesTo(p, oneLine: true);
      }
      p.writeln('');
      p.withIndent(() {
        for (int i = type.inputs.length; i < locals.length; ++i) {
          p.write('(');
          locals[i].printTo(p, localNames);
          p.writeln(')');
        }
        body.printTo(p);
      });
    });
    p.write(')');
  }

  void printDeclarationTo(IrPrinter p) {
    p.write('(func \$$functionName ');
    p.withLocalNames(localNames, () {
      type.printSignatureWithNamesTo(p, oneLine: true);
    });
    p.write(' <...>');
    p.writeln(')');
  }

  @override
  String toString() => functionName ?? "#$finalizableIndex";
}

/// An imported function.
class ImportedFunction extends BaseFunction implements Import {
  @override
  final String module;
  @override
  final String name;

  ImportedFunction(super.enclosingModule, this.module, this.name,
      super.finalizableIndex, super.type,
      [super.functionName]);

  @override
  void serialize(Serializer s) {
    s.writeName(module);
    s.writeName(name);
    s.writeByte(0x00);
    s.writeUnsigned(type.index);
  }

  void printTo(IrPrinter p) {
    if (isPure) {
      p.writeln('(@binaryen.removable.if.unused)');
    }
    p.write('(func ');
    p.writeFunctionReference(this);
    p.write(' ');
    p.writeImport(module, name);
    p.write(' ');
    type.printOneLineSignatureTo(p);
    p.write(')');
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
