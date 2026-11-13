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
  final size = staticFunctionsTable.size;
  if (id == size) {
    staticFunctionsTable.grow(size == 0 ? 16 : size, null);
  }
  return id;
}

/// Defines [function] as static [id]'s function.
///
/// Statics are defined once.
void defineStatic(int id, WasmFuncRef function) {
  final info = statics[id];
  if (info.isDefined) {
    throw StateError('Static ${info.label} is already defined');
  }
  info.isDefined = true;
  staticFunctionsTable[id] = function;
}

/// Maps a static's ID to its function.
@pragma('wasm:table-type', TableType(limits: Limits(0)))
@pragma('wasm:export', 'static-functions-table')
external WasmTable<WasmFuncRef?> get staticFunctionsTable;

/// Maps a static's ID to its info.
final List<StaticInfo> statics = [];

/// Maps a static's label to its ID.
final Map<String, int> staticIds = {};

final class StaticInfo {
  final String label;

  /// Whether the static's function has been defined.
  bool isDefined = false;

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

/// Returns the ID of parameter shape [label] or assigns one.
///
/// Formatted like: `1,a,b` for `foo(x, {a, b}) {}`
int shapeId(String label) {
  final existing = shapeIds[label];
  if (existing != null) return existing;
  final id = shapeLabels.length;
  shapeLabels.add(label);
  shapeIds[label] = id;
  return id;
}

/// Starts defining class [id]'s instance members.
void startInstanceMemberDefinitions(int id) => classes[id].changeState(
  ClassState.typeInitialized,
  ClassState.initializingMembers,
);

/// Defines [function] as class [classId]'s instance member [instanceMemberId]
/// with shape [shapeId].
///
/// Members are defined once per shape, between [startInstanceMemberDefinitions]
/// and [endInstanceMemberDefinitions].
void defineInstanceMember(
  int classId,
  int instanceMemberId,
  int shapeId,
  WasmFuncRef function,
) => classes[classId].defineInstanceMember(instanceMemberId, shapeId, function);

/// Ends defining class [id]'s instance members, making it ready to use.
void endInstanceMemberDefinitions(int id) => classes[id].changeState(
  ClassState.initializingMembers,
  ClassState.initialized,
);

/// Returns [instanceMemberId] with shape [shapeId] in class [classId] or its
/// superclasses.
WasmFuncRef findTarget(int classId, int instanceMemberId, int shapeId) {
  int id = classId;
  while (id != -1) {
    final cls = classes[id]..expectState(ClassState.initialized);
    final shapes = cls.members[instanceMemberId];
    if (shapes != null) {
      // TODO(dart2wasm): Add forwarders for overrides that change the shape.
      final member = shapes[shapeId];
      if (member == null) break;
      return member.ref;
    }
    id = cls.superclassId;
  }
  throw StateError(
    'Class ${classes[classId].label} has no member '
    '${memberLabel(instanceMemberId, shapeId)}',
  );
}

/// Returns the label of instance member [instanceMemberId] with shape
/// [shapeId].
///
/// Formatted like: `bar(1,a,b)` for `bar(x, {a, b}) {}`.
String memberLabel(int instanceMemberId, int shapeId) =>
    '${instanceMemberNames[instanceMemberId]}(${shapeLabels[shapeId]})';

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

/// Maps a shape's label to its ID.
final Map<String, int> shapeIds = {};

/// Maps a shape ID to its label.
final List<String> shapeLabels = [];

final class ClassInfo {
  final String label;

  ClassState state = ClassState.declared;

  /// The superclass's ID or -1 for `Object`.
  int superclassId = -1;

  /// Maps member IDs to their functions by shape ID.
  final Map<int, Map<int, FunctionInfo>> members = {};

  ClassInfo(this.label);

  /// Defines [function] as instance member [instanceMemberId] with shape
  /// [shapeId].
  void defineInstanceMember(
    int instanceMemberId,
    int shapeId,
    WasmFuncRef function,
  ) {
    expectState(ClassState.initializingMembers);
    final shapes = members[instanceMemberId] ??= {};
    if (shapes.containsKey(shapeId)) {
      throw StateError(
        'Class $label already defines '
        '${memberLabel(instanceMemberId, shapeId)}',
      );
    }
    shapes[shapeId] = FunctionInfo(function);
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

/// Returns the sentinel callers pass for omitted optional parameters.
///
/// Every module calls this on startup with its own [sentinel] and gets the
/// first module's, so callees in any module can recognize it with `ref.eq`.
// TODO(dart2wasm): Move to an SDK module after dart:core is compiled.
WasmEqRef defaultValueSentinel(WasmEqRef sentinel) =>
    (_defaultValueSentinel ??= EqRefInfo(sentinel)).ref;

EqRefInfo? _defaultValueSentinel;

/// Wraps a [WasmEqRef], which dart2wasm can't null-check.
final class EqRefInfo {
  final WasmEqRef ref;

  EqRefInfo(this.ref);
}
