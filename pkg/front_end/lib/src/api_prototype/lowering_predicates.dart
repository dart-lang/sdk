// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import '../fasta/kernel/late_lowering.dart';

// TODO(johnniwinther): Add support for recognizing late lowered locals?

/// Returns `true` if [node] is the field holding the value of a lowered late
/// field.
///
/// For instance
///
///    late int field;
///
/// is lowered to (simplified):
///
///    int? _#field = null;
///    int get field => _#field != null ? _#field : throw 'Uninitialized';
///    void set field(int value) {
///      _#field = value;
///    }
///
/// where '_#field' is the field holding that value.
///
/// The default value of this field is `null`.
bool isLateLoweredField(Field node) {
  return node.isInternalImplementation &&
      node.name != null &&
      node.name.name.startsWith(lateFieldPrefix) &&
      !node.name.name.endsWith(lateIsSetSuffix);
}

/// Returns `true` if [node] is the field holding the marker for whether a
/// lowered late field has been set or not.
///
/// For instance
///
///    late int? field;
///
/// is lowered to (simplified):
///
///    bool _#field#isSet = false;
///    int? _#field = null;
///    int get field => _#field#isSet ? _#field : throw 'Uninitialized';
///    void set field(int value) {
///      _#field = value;
///      _#field#isSet = true;
///    }
///
/// where '_#field#isSet' is the field holding the marker.
///
/// The default value of this field is `false`.
bool isLateLoweredIsSetField(Field node) {
  return node.isInternalImplementation &&
      node.name != null &&
      node.name.name.startsWith(lateFieldPrefix) &&
      node.name.name.endsWith(lateIsSetSuffix);
}

/// Returns `true` if [node] is the getter for reading the value of a lowered
/// late field.
///
/// For instance
///
///    late int field;
///
/// is lowered to (simplified):
///
///    int? _#field = null;
///    int get field => _#field != null ? _#field : throw 'Uninitialized';
///    void set field(int value) {
///      _#field = value;
///    }
///
/// where 'int get field' is the getter for reading the field.
///
/// Note that the computation of this predicate is _not_ efficient and the
/// result should be cached on the use site if queried repeatedly.
bool isLateLoweredFieldGetter(Procedure node) {
  if (node.kind == ProcedureKind.Getter) {
    TreeNode parent = node.parent;
    if (parent is Class) {
      return parent.fields.any((Field field) =>
          isLateLoweredField(field) &&
          field.name.name.endsWith(node.name.name));
    } else if (parent is Library) {
      return parent.fields.any((Field field) =>
          isLateLoweredField(field) &&
          field.name.name.endsWith(node.name.name));
    }
  }
  return false;
}

/// Returns `true` if [node] is the setter for setting the value of a lowered
/// late field.
///
/// For instance
///
///    late int field;
///
/// is lowered to (simplified):
///
///    int? _#field = null;
///    int get field => _#field != null ? _#field : throw 'Uninitialized';
///    void set field(int value) {
///      _#field = value;
///    }
///
/// where 'void set field' is the setter for setting the value of the field.
///
/// Note that the computation of this predicate is _not_ efficient and the
/// result should be cached on the use site if queried repeatedly.
bool isLateLoweredFieldSetter(Procedure node) {
  if (node.kind == ProcedureKind.Setter) {
    TreeNode parent = node.parent;
    if (parent is Class) {
      return parent.fields.any((Field field) =>
          isLateLoweredField(field) &&
          field.name.name.endsWith(node.name.name));
    } else if (parent is Library) {
      return parent.fields.any((Field field) =>
          isLateLoweredField(field) &&
          field.name.name.endsWith(node.name.name));
    }
  }
  return false;
}
