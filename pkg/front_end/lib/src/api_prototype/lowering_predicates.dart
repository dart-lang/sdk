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
      node.name.text.startsWith(lateFieldPrefix) &&
      !node.name.text.endsWith(lateIsSetSuffix);
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
      node.name.text.startsWith(lateFieldPrefix) &&
      node.name.text.endsWith(lateIsSetSuffix);
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
          field.name.text.endsWith(node.name.text));
    } else if (parent is Library) {
      return parent.fields.any((Field field) =>
          isLateLoweredField(field) &&
          field.name.text.endsWith(node.name.text));
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
          field.name.text.endsWith(node.name.text));
    } else if (parent is Library) {
      return parent.fields.any((Field field) =>
          isLateLoweredField(field) &&
          field.name.text.endsWith(node.name.text));
    }
  }
  return false;
}

/// Returns `true` if [node] is the local variable holding the value of a
/// lowered late variable.
///
/// For instance
///
///    late int local;
///
/// is lowered to (simplified):
///
///    int? #local = null;
///    int #local#get() => #local != null ? #local : throw 'Uninitialized';
///    void #local#set(int value) {
///      #local = value;
///    }
///
/// where '#local' is the local variable holding that value.
///
/// The default value of this variable is `null`.
// TODO(johnniwinther): Enable these if the name of late locals is changed
//  to  '${lateLocalPrefix}${name}'. See
// backends can benefit from identifying late locals.
/*bool isLateLoweredLocal(VariableDeclaration node) {
  return node.name != null && isLateLoweredLocalName(node.name);
}

/// Returns `true` if [name] is the name of a local variable holding the value
/// of a lowered late variable.
bool isLateLoweredLocalName(String name) {
  return name.startsWith(lateLocalPrefix) &&
      !(name.endsWith(lateIsSetSuffix) ||
          name.endsWith(lateLocalGetterSuffix) ||
          name.endsWith(lateLocalSetterSuffix));
}

/// Returns the name of the original late local variable from the [name] of the
/// local variable holding the value of the lowered late variable.
///
/// This method assumes that `isLateLoweredLocalName(name)` is `true`.
String extractLateLoweredLocalNameFrom(String name) {
  return name.substring(lateLocalPrefix.length);
}*/

/// Returns `true` if [node] is the local variable holding the marker for
/// whether a lowered late local variable has been set or not.
///
/// For instance
///
///    late int? local;
///
/// is lowered to (simplified):
///
///    bool #local#isSet = false;
///    int? #local = null;
///    int #local#get() => _#field#isSet ? #local : throw 'Uninitialized';
///    void #local#set(int value) {
///      #local = value;
///      #local#isSet = true;
///    }
///
/// where '#local#isSet' is the local variable holding the marker.
///
/// The default value of this variable is `false`.
bool isLateLoweredIsSetLocal(VariableDeclaration node) {
  return node.name != null && isLateLoweredIsSetName(node.name);
}

/// Returns `true` if [name] is the name of a local variable holding the marker
/// for whether a lowered late local variable has been set or not.
bool isLateLoweredIsSetName(String name) {
  return name.startsWith(lateLocalPrefix) && name.endsWith(lateIsSetSuffix);
}

/// Returns the name of the original late local variable from the [name] of the
/// local variable holding the marker for whether the lowered late local
/// variable has been set or not.
///
/// This method assumes that `isLateLoweredIsSetName(name)` is `true`.
String extractLocalNameFromLateLoweredIsSet(String name) {
  return name.substring(
      lateLocalPrefix.length, name.length - lateIsSetSuffix.length);
}

/// Returns `true` if [node] is the local variable for the local function for
/// reading the value of a lowered late variable.
///
/// For instance
///
///    late int local;
///
/// is lowered to (simplified):
///
///    int? #local = null;
///    int #local#get() => #local != null ? #local : throw 'Uninitialized';
///    void #local#set(int value) {
///      #local = value;
///    }
///
/// where '#local#get' is the local function for reading the variable.
bool isLateLoweredLocalGetter(VariableDeclaration node) {
  return node.name != null && isLateLoweredGetterName(node.name);
}

/// Returns `true` if [name] is the name of the local variable for the local
/// function for reading the value of a lowered late variable.
bool isLateLoweredGetterName(String name) {
  return name.startsWith(lateLocalPrefix) &&
      name.endsWith(lateLocalGetterSuffix);
}

/// Returns the name of the original late local variable from the [name] of the
/// local variable for the local function for reading the value of the lowered
/// late variable.
///
/// This method assumes that `isLateLoweredGetterName(name)` is `true`.
String extractLocalNameFromLateLoweredGetter(String name) {
  return name.substring(
      lateLocalPrefix.length, name.length - lateLocalGetterSuffix.length);
}

/// Returns `true` if [node] is the local variable for the local function for
/// setting the value of a lowered late variable.
///
/// For instance
///
///    late int local;
///
/// is lowered to (simplified):
///
///    int? #local = null;
///    int #local#get() => #local != null ? #local : throw 'Uninitialized';
///    void #local#set(int value) {
///      #local = value;
///    }
///
/// where '#local#set' is the local function for setting the value of the
/// variable.
bool isLateLoweredLocalSetter(VariableDeclaration node) {
  return node.name != null && isLateLoweredSetterName(node.name);
}

/// Returns `true` if [name] is the name of the local variable for the local
/// function for setting the value of a lowered late variable.
bool isLateLoweredSetterName(String name) {
  return name.startsWith(lateLocalPrefix) &&
      name.endsWith(lateLocalSetterSuffix);
}

/// Returns the name of the original late local variable from the [name] of the
/// local variable for the local function for setting the value of the lowered
/// late variable.
///
/// This method assumes that `isLateLoweredSetterName(name)` is `true`.
String extractLocalNameFromLateLoweredSetter(String name) {
  return name.substring(
      lateLocalPrefix.length, name.length - lateLocalSetterSuffix.length);
}
