// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Runtime for the Wasm dev compiler.

import 'dart:_wasm';

/// Returns the ID of the static with [label] or assigns it one.
///
/// Static labels have a format like: `package:foo/foo.dart::bar`, or
/// `package:foo/foo.dart::Foo.bar` for a static member of class `Foo`.
int staticId(String label) {
  final existing = staticIds[label];
  if (existing != null) return existing;
  final id = statics.length;
  statics.add(StaticInfo(label));
  staticIds[label] = id;
  return id;
}

/// Defines [function] as static [id]'s function.
///
/// Statics are defined once.
void defineStatic(int id, WasmFuncRef function) {
  final info = statics[id];
  if (info.function != null) {
    throw StateError('Static ${info.label} is already defined');
  }
  info.function = FunctionInfo(function);
}

/// Returns static [id]'s function.
// TODO: Check the caller's arguments against the parameter shape.
WasmFuncRef lookupStatic(int id) {
  final info = statics[id];
  final function = info.function;
  if (function == null) {
    throw StateError('Static ${info.label} is not defined');
  }
  return function.ref;
}

/// Maps a static's ID to its info.
final List<StaticInfo> statics = [];

/// Maps a static's label to its ID.
final Map<String, int> staticIds = {};

final class StaticInfo {
  final String label;

  /// The static's function, or `null` if it hasn't been defined.
  FunctionInfo? function;

  // TODO: Store the parameter shape.
  StaticInfo(this.label);
}

/// Returns the ID of the class with [label] or assigns it one.
///
/// Formatted like: `package:foo/foo.dart::Foo`.
int classId(String label) {
  final existing = classIds[label];
  if (existing != null) return existing;
  final id = classes.length;
  classes.add(ClassInfo(label));
  classIds[label] = id;
  return id;
}

/// Defines class [id]'s superclass as [superclassId].
///
/// Classes are defined once and in any order.
void defineClassSupers(int id, int superclassId) {
  final cls = classes[id];
  cls.changeState(ClassState.declared, ClassState.typeInitialized);
  cls.superclassId = superclassId;
}

/// Returns the ID of instance member [name] or assigns one.
///
/// Formatted like: `bar` or `_bar@package:foo/foo.dart` if private.
int instanceMemberId(String name) {
  final existing = instanceMemberIds[name];
  if (existing != null) return existing;
  final id = instanceMemberNames.length;
  instanceMemberNames.add(name);
  instanceMemberIds[name] = id;
  return id;
}

/// Starts defining class [id]'s instance members.
void startInstanceMemberDefinitions(int id) => classes[id].changeState(
  ClassState.typeInitialized,
  ClassState.initializingMembers,
);

/// Defines [function] as class [classId]'s instance member [instanceMemberId].
///
/// Members are defined once, between [startInstanceMemberDefinitions] and
/// [endInstanceMemberDefinitions].
void defineInstanceMember(
  int classId,
  int instanceMemberId,
  WasmFuncRef function,
) => classes[classId].defineInstanceMember(instanceMemberId, function);

/// Ends defining class [id]'s instance members, making it ready to use.
void endInstanceMemberDefinitions(int id) => classes[id].changeState(
  ClassState.initializingMembers,
  ClassState.initialized,
);

/// Returns [instanceMemberId] in class [classId] or its superclasses.
// TODO: Check the caller's arguments against the parameter shape.
WasmFuncRef findTarget(int classId, int instanceMemberId) {
  int id = classId;
  while (id != -1) {
    final cls = classes[id]..expectState(ClassState.initialized);
    final member = cls.members[instanceMemberId];
    if (member != null) return member.ref;
    id = cls.superclassId;
  }
  throw StateError(
    'Class ${classes[classId].label} has no member '
    '${instanceMemberNames[instanceMemberId]}',
  );
}

// TODO: Remove when dart:core is compiled.
const objectLabel = 'dart:core::Object';

/// Maps a class ID to its info.
final List<ClassInfo> classes = [
  ClassInfo(objectLabel)..state = ClassState.initialized,
];

/// Maps a class's label to its ID.
final Map<String, int> classIds = {objectLabel: 0};

/// Maps an instance member name to its ID.
final Map<String, int> instanceMemberIds = {};

/// Maps an instance member ID to its name.
final List<String> instanceMemberNames = [];

final class ClassInfo {
  final String label;

  ClassState state = ClassState.declared;

  /// The superclass's ID or -1 for `Object`.
  int superclassId = -1;

  /// Maps member IDs to their function.
  final Map<int, FunctionInfo> members = {};

  ClassInfo(this.label);

  /// Defines [function] as instance member [instanceMemberId].
  void defineInstanceMember(int instanceMemberId, WasmFuncRef function) {
    expectState(ClassState.initializingMembers);
    if (members.containsKey(instanceMemberId)) {
      throw StateError(
        'Class $label already defines '
        '${instanceMemberNames[instanceMemberId]}',
      );
    }
    members[instanceMemberId] = FunctionInfo(function);
  }

  /// Changes this class's state from [from] to [to].
  void changeState(ClassState from, ClassState to) {
    expectState(from);
    state = to;
  }

  /// Throws if this class isn't in state [expectedState].
  void expectState(ClassState expectedState) {
    if (state != expectedState) {
      throw StateError(
        'Class $label in unexpected state: ${state.name}, '
        'expected ${expectedState.name}',
      );
    }
  }
}

/// Unidirectional states a class advances through before it can be used.
enum ClassState {
  /// Class ID assigned.
  declared,

  /// Super hierarchy assigned.
  typeInitialized,

  /// Instance members initialized.
  initializingMembers,

  /// Ready to be allocated and invoked.
  initialized,
}

/// Wraps a [WasmFuncRef], which dart2wasm can't null-check.
final class FunctionInfo {
  final WasmFuncRef ref;

  FunctionInfo(this.ref);
}
