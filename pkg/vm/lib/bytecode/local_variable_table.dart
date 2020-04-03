// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.local_variable_table;

import 'bytecode_serialization.dart';

enum LocalVariableEntryKind {
  invalid,
  scope,
  variableDeclaration,
  contextVariable,
}

abstract class LocalVariableEntry {
  static const KindMask = 0x0F;
  static const IsCapturedFlag = 1 << 4;

  LocalVariableEntryKind get kind;
  int get flags => 0;
  final int startPC;
  void writeContents(BufferedWriter writer);

  LocalVariableEntry(this.startPC);
}

class Scope extends LocalVariableEntry {
  int endPC;
  int contextLevel;
  int position;
  int endPosition;
  final List<VariableDeclaration> variables = <VariableDeclaration>[];

  Scope(int startPC, this.endPC, this.contextLevel, this.position,
      this.endPosition)
      : super(startPC);

  @override
  LocalVariableEntryKind get kind => LocalVariableEntryKind.scope;

  @override
  void writeContents(BufferedWriter writer) {
    if (endPC == null) {
      throw '$this is not closed';
    }
    writer.writePackedUInt30(endPC - startPC);
    writer.writeSLEB128(contextLevel);
    writer.writePackedUInt30(position + 1);
    writer.writePackedUInt30(endPosition + 1);
  }

  Scope.readContents(BufferedReader reader, int startPC) : super(startPC) {
    endPC = startPC + reader.readPackedUInt30();
    contextLevel = reader.readSLEB128();
    position = reader.readPackedUInt30() - 1;
    endPosition = reader.readPackedUInt30() - 1;
  }

  @override
  String toString() =>
      'scope (pc $startPC-$endPC pos $position-$endPosition context-level $contextLevel)';
}

class VariableDeclaration extends LocalVariableEntry {
  bool isCaptured;
  int index;
  int name;
  int type;
  int position;
  int initializedPosition;

  VariableDeclaration(int startPC, this.isCaptured, this.index, this.name,
      this.type, this.position, this.initializedPosition)
      : super(startPC);

  @override
  LocalVariableEntryKind get kind => LocalVariableEntryKind.variableDeclaration;

  @override
  int get flags => (isCaptured ? LocalVariableEntry.IsCapturedFlag : 0);

  @override
  void writeContents(BufferedWriter writer) {
    writer.writeSLEB128(index);
    writer.writePackedUInt30(name);
    writer.writePackedUInt30(type);
    writer.writePackedUInt30(position + 1);
    writer.writePackedUInt30(initializedPosition + 1);
  }

  VariableDeclaration.readContents(
      BufferedReader reader, int startPC, int flags)
      : super(startPC) {
    isCaptured = (flags & LocalVariableEntry.IsCapturedFlag) != 0;
    index = reader.readSLEB128();
    name = reader.readPackedUInt30();
    type = reader.readPackedUInt30();
    position = reader.readPackedUInt30() - 1;
    initializedPosition = reader.readPackedUInt30() - 1;
  }

  @override
  String toString() =>
      'variable $index${isCaptured ? ' (captured)' : ''} pc $startPC, name CP#$name, type CP#$type, pos $position, init-pos $initializedPosition';
}

class ContextVariable extends LocalVariableEntry {
  int index;

  ContextVariable(int startPC, this.index) : super(startPC);

  @override
  LocalVariableEntryKind get kind => LocalVariableEntryKind.contextVariable;

  @override
  void writeContents(BufferedWriter writer) {
    writer.writeSLEB128(index);
  }

  ContextVariable.readContents(BufferedReader reader, int startPC)
      : super(startPC) {
    index = reader.readSLEB128();
  }

  @override
  String toString() => 'context variable $index';
}

/// Keeps information about declared local variables.
class LocalVariableTable extends BytecodeDeclaration {
  final scopes = <Scope>[];
  final activeScopes = <Scope>[];
  ContextVariable contextVariable;

  LocalVariableTable();

  void enterScope(int pc, int contextLevel, int position) {
    final scope = new Scope(pc, null, contextLevel, position, null);
    activeScopes.add(scope);
    scopes.add(scope);
  }

  void declareVariable(int pc, bool isCaptured, int index, int nameCpIndex,
      int typeCpIndex, int position, int initializedPosition) {
    final variable = new VariableDeclaration(pc, isCaptured, index, nameCpIndex,
        typeCpIndex, position, initializedPosition);
    activeScopes.last.variables.add(variable);
  }

  void leaveScope(int pc, int endPosition) {
    final scope = activeScopes.removeLast();
    scope.endPC = pc;
    scope.endPosition = endPosition;
    if (scope.variables.isEmpty &&
        activeScopes.isNotEmpty &&
        scope.contextLevel == activeScopes.last.contextLevel) {
      scopes.remove(scope);
    }
  }

  void leaveAllScopes(int pc, int endPosition) {
    while (activeScopes.isNotEmpty) {
      leaveScope(pc, endPosition);
    }
  }

  void recordContextVariable(int pc, int index) {
    assert(contextVariable == null);
    contextVariable = new ContextVariable(pc, index);
  }

  bool get isEmpty => scopes.isEmpty && contextVariable == null;

  bool get isNotEmpty => !isEmpty;

  bool get hasActiveScopes => activeScopes.isNotEmpty;

  List<LocalVariableEntry> getEntries() {
    final entries = <LocalVariableEntry>[];
    if (contextVariable != null) {
      entries.add(contextVariable);
    }
    for (Scope scope in scopes) {
      entries.add(scope);
      entries.addAll(scope.variables);
    }
    return entries;
  }

  void write(BufferedWriter writer) {
    final entries = getEntries();
    writer.writePackedUInt30(entries.length);
    final encodeStartPC = new SLEB128DeltaEncoder();
    for (var entry in entries) {
      writer.writeByte(entry.kind.index | entry.flags);
      encodeStartPC.write(writer, entry.startPC);
      entry.writeContents(writer);
    }
  }

  LocalVariableTable.read(BufferedReader reader) {
    final int numEntries = reader.readPackedUInt30();
    final decodeStartPC = new SLEB128DeltaDecoder();
    Scope scope;
    for (int i = 0; i < numEntries; ++i) {
      final int kindAndFlags = reader.readByte();
      final LocalVariableEntryKind kind = LocalVariableEntryKind
          .values[kindAndFlags & LocalVariableEntry.KindMask];
      final int flags = kindAndFlags & ~LocalVariableEntry.KindMask;
      final int startPC = decodeStartPC.read(reader);
      switch (kind) {
        case LocalVariableEntryKind.scope:
          scope = new Scope.readContents(reader, startPC);
          scopes.add(scope);
          break;
        case LocalVariableEntryKind.variableDeclaration:
          scope.variables.add(
              new VariableDeclaration.readContents(reader, startPC, flags));
          break;
        case LocalVariableEntryKind.contextVariable:
          contextVariable = new ContextVariable.readContents(reader, startPC);
          break;
        default:
          throw 'Unexpected entry kind ${kind}';
      }
    }
  }

  Map<int, String> getBytecodeAnnotations() {
    final map = <int, String>{};
    for (var entry in getEntries()) {
      final pc = entry.startPC;
      if (map[pc] == null) {
        map[pc] = entry.toString();
      } else {
        map[pc] = "${map[pc]}; $entry";
      }
    }
    return map;
  }
}
