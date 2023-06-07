// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import '../fasta/kernel/late_lowering.dart';
export '../fasta/kernel/constructor_tearoff_lowering.dart'
    show
        extractConstructorNameFromTearOff,
        isConstructorTearOffLowering,
        isTearOffLowering,
        isTypedefTearOffLowering;

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
      // ignore: unnecessary_null_comparison
      node.name != null &&
      node.name.text.startsWith(lateFieldPrefix) &&
      !node.name.text.endsWith(lateIsSetSuffix);
}

/// Returns the name of the original field for a lowered late field where
/// [node] is the field holding the value of a lowered late field.
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
/// where '_#field' is the field holding that value and 'field' is the name of
/// the original field.
///
/// This assumes that `isLateLoweredField(node)` is true.
Name extractFieldNameFromLateLoweredField(Field node) {
  assert(isLateLoweredField(node));
  String prefix = lateFieldPrefix;
  if (node.isInstanceMember) {
    prefix = '$prefix${node.enclosingClass!.name}#';
  }
  return new Name(node.name.text.substring(prefix.length), node.name.library);
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
      // ignore: unnecessary_null_comparison
      node.name != null &&
      node.name.text.startsWith(lateFieldPrefix) &&
      node.name.text.endsWith(lateIsSetSuffix);
}

/// Returns the name of the original field for a lowered late field where [node]
/// is the field holding the marker for whether the lowered late field has been
/// set or not.
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
/// where '_#field#isSet' is the field holding the marker and 'field' is the
/// name of the original field.
///
/// This assumes that `isLateLoweredIsSetField(node)` is true.
Name extractFieldNameFromLateLoweredIsSetField(Field node) {
  assert(isLateLoweredIsSetField(node));
  String prefix = lateFieldPrefix;
  if (node.isInstanceMember) {
    prefix = '$prefix${node.enclosingClass!.name}#';
  }
  return new Name(
      node.name.text.substring(
          prefix.length, node.name.text.length - lateIsSetSuffix.length),
      node.name.library);
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
    TreeNode? parent = node.parent;
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

/// Returns the name of the original field for a lowered late field where [node]
/// is the getter for reading the value of a lowered late field.
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
/// where 'int get field' is the getter for reading the field and 'field' is the
/// name of the original field.
///
/// This assumes that `isLateLoweredFieldGetter(node)` is true.
Name extractFieldNameFromLateLoweredFieldGetter(Procedure node) {
  assert(isLateLoweredFieldGetter(node));
  return node.name;
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
    TreeNode? parent = node.parent;
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

/// Returns the name of the original field for a lowered late field where [node]
/// is the setter for setting the value of a lowered late field.
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
/// where 'void set field' is the setter for setting the value of the field and
/// 'field' is the name of the original field.
///
/// This assumes that `isLateLoweredFieldSetter(node)` is true.
Name extractFieldNameFromLateLoweredFieldSetter(Procedure node) {
  assert(isLateLoweredFieldSetter(node));
  return node.name;
}

/// Returns the original initializer of a lowered late field where [node] is
/// either the field holding the value, the field holding the marker for whether
/// it has been set or not, getter for reading the value, or the setter for
/// setting the value of the field.
///
/// For instance
///
///    late int field = 42;
///
/// is lowered to (simplified):
///
///    int? _#field = null;
///    int get field => _#field == null ? throw 'Uninitialized' : _#field = 42;
///    void set field(int value) {
///      _#field = value;
///    }
///
/// where this original initializer is `42`, '_#field' is the field holding that
/// value,  '_#field#isSet' is the field holding the marker, 'int get field' is
/// the getter for reading the field, and 'void set field' is the setter for
/// setting the value of the field.
///
/// If the original late field had no initializer, `null` is returned.
///
/// If [node] is not part of a late field lowering, `null` is returned.
Expression? getLateFieldInitializer(Member node) {
  Procedure? lateFieldGetter = _getLateFieldTarget(node);
  if (lateFieldGetter != null) {
    Statement body = lateFieldGetter.function.body!;
    // TODO(johnniwinther): Rewrite to avoid `as X`.
    if (body is Block &&
        body.statements.length == 2 &&
        body.statements.first is IfStatement) {
      IfStatement ifStatement = body.statements.first as IfStatement;
      if (ifStatement.then is Block) {
        Block block = ifStatement.then as Block;
        if (block.statements.isNotEmpty &&
            block.statements.first is ExpressionStatement) {
          ExpressionStatement firstStatement =
              block.statements.first as ExpressionStatement;
          if (firstStatement.expression is InstanceSet) {
            // We have
            //
            //    get field {
            //      if (!_#isSet#field) {
            //        this._#field = <init>;
            //        ...
            //      }
            //      return _#field;
            //    }
            //
            // in case `<init>` is the initializer.
            InstanceSet instanceSet = firstStatement.expression as InstanceSet;
            assert(instanceSet.interfaceTarget == getLateFieldTarget(node));
            return instanceSet.value;
          } else if (firstStatement.expression is StaticSet) {
            // We have
            //
            //    get field {
            //      if (!_#isSet#field) {
            //        _#field = <init>;
            //        ...
            //      }
            //      return _#field;
            //    }
            //
            // in case `<init>` is the initializer.
            StaticSet staticSet = firstStatement.expression as StaticSet;
            assert(staticSet.target == getLateFieldTarget(node));
            return staticSet.value;
          }
        } else if (block.statements.isNotEmpty &&
            block.statements.first is VariableDeclaration) {
          // We have
          //
          //    get field {
          //      if (!_#isSet#field) {
          //        var temp = <init>;
          //        if (_#isSet#field) throw '...'
          //        _#field = temp;
          //        _#isSet#field = true
          //      }
          //      return _#field;
          //    }
          //
          // in case `<init>` is the initializer.
          VariableDeclaration variableDeclaration =
              block.statements.first as VariableDeclaration;
          return variableDeclaration.initializer;
        }
      }
      return null;
    } else if (body is ReturnStatement) {
      Expression? expression = body.expression;
      if (expression is ConditionalExpression &&
          expression.otherwise is Throw) {
        // We have
        //
        //    get field => _#field#isSet ? #field : throw ...;
        //
        // in which case there is no initializer.
        return null;
      } else if (expression is Let) {
        Expression letBody = expression.body;
        if (letBody is ConditionalExpression) {
          Expression then = letBody.then;
          if (then is Throw) {
            // We have
            //
            //    get field => let # = _#field in <is-unset> ? throw ... : #;
            //
            // in which case there is no initializer.
            return null;
          } else if (then is InstanceSet) {
            // We have
            //
            //    get field => let # = this._#field in <is-unset>
            //        ? this._#field = <init> : #;
            //
            // in which case `<init>` is the initializer.
            assert(then.interfaceTarget == getLateFieldTarget(node));
            return then.value;
          } else if (then is StaticSet) {
            // We have
            //
            //    get field => let # = this._#field in <is-unset>
            //        ? this._#field = <init> : #;
            //
            // in which case `<init>` is the initializer.
            assert(then.target == getLateFieldTarget(node));
            return then.value;
          } else if (then is Let && then.body is ConditionalExpression) {
            // We have
            //
            //    get field => let #1 = _#field in <is-unset>
            //        ? let #2 = <init> in ...
            //        : #1;
            //
            // in which case `<init>` is the initializer.
            return then.variable.initializer;
          }
        }
      }
    }
    throw new UnsupportedError(
        'Unrecognized late getter encoding for $lateFieldGetter: ${body}');
  }

  return null;
}

/// Returns getter for reading the value of a lowered late field where [node] is
/// either the field holding the value, the field holding the marker for whether
/// it has been set or not, getter for reading the value, or the setter for
/// setting the value of the field.
Procedure? _getLateFieldTarget(Member node) {
  Name? lateFieldName;
  if (node is Procedure) {
    if (isLateLoweredFieldGetter(node)) {
      return node;
    } else if (isLateLoweredFieldSetter(node)) {
      lateFieldName = extractFieldNameFromLateLoweredFieldSetter(node);
    }
  } else if (node is Field) {
    if (isLateLoweredField(node)) {
      lateFieldName = extractFieldNameFromLateLoweredField(node);
    } else if (isLateLoweredIsSetField(node)) {
      lateFieldName = extractFieldNameFromLateLoweredIsSetField(node);
    }
  }
  if (lateFieldName != null) {
    TreeNode? parent = node.parent;
    List<Procedure>? procedures;
    if (parent is Class) {
      procedures = parent.procedures;
    } else if (parent is Library) {
      procedures = parent.procedures;
    }
    return procedures!.singleWhere((Procedure procedure) =>
        isLateLoweredFieldGetter(procedure) &&
        extractFieldNameFromLateLoweredFieldGetter(procedure) == lateFieldName);
  }
  return null;
}

/// Returns the field holding the value for a lowered late field where [node] is
/// either the field holding the value, the field holding the marker for whether
/// it has been set or not, getter for reading the value, or the setter for
/// setting the value of the field.
///
/// For instance
///
///    late int field = 42;
///
/// is lowered to (simplified):
///
///    int? _#field = null;
///    int get field => _#field == null ? throw 'Uninitialized' : _#field = 42;
///    void set field(int value) {
///      _#field = value;
///    }
///
/// where '_#field' is the field holding that value,  '_#field#isSet' is the
/// field holding the marker, 'int get field' is the getter for reading the
/// field, and 'void set field' is the setter for setting the value of the
/// field.
///
/// If [node] is not part of a late field lowering, `null` is returned.
Field? getLateFieldTarget(Member node) {
  Name? lateFieldName;
  if (node is Procedure) {
    if (isLateLoweredFieldGetter(node)) {
      lateFieldName = extractFieldNameFromLateLoweredFieldGetter(node);
    } else if (isLateLoweredFieldSetter(node)) {
      lateFieldName = extractFieldNameFromLateLoweredFieldSetter(node);
    }
  } else if (node is Field) {
    if (isLateLoweredField(node)) {
      return node;
    } else if (isLateLoweredIsSetField(node)) {
      lateFieldName = extractFieldNameFromLateLoweredIsSetField(node);
    }
  }
  if (lateFieldName != null) {
    TreeNode? parent = node.parent;
    List<Field>? fields;
    if (parent is Class) {
      fields = parent.fields;
    } else if (parent is Library) {
      fields = parent.fields;
    }
    return fields!.singleWhere((Field field) =>
        isLateLoweredField(field) &&
        extractFieldNameFromLateLoweredField(field) == lateFieldName);
  }
  return null;
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
bool isLateLoweredLocal(VariableDeclaration node) {
  return node.isLowered && isLateLoweredLocalName(node.name!);
}

/// Returns `true` if [name] is the name of a local variable holding the value
/// of a lowered late variable.
bool isLateLoweredLocalName(String name) {
  return name != syntheticThisName &&
      name.startsWith(lateLocalPrefix) &&
      !name.endsWith(lateIsSetSuffix) &&
      !name.endsWith(lateLocalGetterSuffix) &&
      !name.endsWith(lateLocalSetterSuffix) &&
      !name.contains(joinedIntermediateInfix);
}

/// Returns the name of the original late local variable from the [name] of the
/// local variable holding the value of the lowered late variable.
///
/// This method assumes that `isLateLoweredLocalName(name)` is `true`.
String extractLocalNameFromLateLoweredLocal(String name) {
  return name.substring(lateLocalPrefix.length);
}

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
  return node.isLowered && isLateLoweredIsSetLocalName(node.name!);
}

/// Returns `true` if [name] is the name of a local variable holding the marker
/// for whether a lowered late local variable has been set or not.
bool isLateLoweredIsSetLocalName(String name) {
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
  return node.isLowered && isLateLoweredLocalGetterName(node.name!);
}

/// Returns `true` if [name] is the name of the local variable for the local
/// function for reading the value of a lowered late variable.
bool isLateLoweredLocalGetterName(String name) {
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
  return node.isLowered && isLateLoweredLocalSetterName(node.name!);
}

/// Returns `true` if [name] is the name of the local variable for the local
/// function for setting the value of a lowered late variable.
bool isLateLoweredLocalSetterName(String name) {
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

/// Returns `true` if [node] is the synthetic parameter holding the `this` value
/// in the encoding of extension instance members.
///
/// For instance
///
///     extension Extension on int {
///        int method() => this;
///     }
///
/// is encoded as
///
///     int Extension|method(int #this) => #this;
///
/// where '#this' is the synthetic "extension this" parameter.
bool isExtensionThis(VariableDeclaration node) {
  assert(node.isLowered || node.name == null || !isExtensionThisName(node.name),
      "$node has name ${node.name} and node.isLowered = ${node.isLowered}");
  return node.isLowered && isExtensionThisName(node.name);
}

/// Name used for synthetic 'this' variables in extension instance members and
/// inline class instance members.
const String syntheticThisName = '#this';

/// Returns `true` if [name] is the name of the synthetic parameter holding the
/// `this` value in the encoding of extension instance members.
bool isExtensionThisName(String? name) {
  return name == syntheticThisName;
}

bool isInlineClassThis(VariableDeclaration node) {
  return node.isLowered && isInlineClassThisName(node.name);
}

/// Returns `true` if [name] is the name of the synthetic parameter holding the
/// `this` value in the encoding of inline class instance members.
bool isInlineClassThisName(String? name) {
  return name == syntheticThisName;
}

/// Returns the name of the original variable from the [name] of the synthetic
/// parameter holding the `this` value in the encoding of extension instance
/// members.
///
/// This method assumes that `isExtensionThisName(name)` is `true`.
String extractLocalNameForExtensionThis(String name) {
  return 'this';
}

/// Returns the original name of the variable [node].
///
/// If [node] is a lowered variable then the name before lowering is returned.
/// Otherwise the name of the variable itself is returned.
///
/// Note that the name can be `null` in case of a synthetic variable created
/// for instance for encoding of `?.`.
String? extractLocalNameFromVariable(VariableDeclaration node) {
  if (node.isLowered) {
    String? name = _extractLocalName(node.name!);
    if (name == null) {
      throw new UnsupportedError("Unrecognized lowered local $node");
    }
    return name;
  }
  return node.name;
}

/// Returns the original name of a variable by the given [name].
///
/// If [name] is the name of a lowered variable then the name before lowering is
/// returned. Otherwise the name of the variable itself is returned.
///
/// This assumed that [name] is non-null.
String extractLocalName(String name) {
  return _extractLocalName(name) ?? name;
}

/// Returns the original name of a lowered variable by the given [name].
///
/// If [name] doesn't correspond to a lowered name `null` is returned.
String? _extractLocalName(String name) {
  if (isExtensionThisName(name)) {
    return extractLocalNameForExtensionThis(name);
  } else if (isLateLoweredLocalName(name)) {
    return extractLocalNameFromLateLoweredLocal(name);
  } else if (isLateLoweredLocalGetterName(name)) {
    return extractLocalNameFromLateLoweredGetter(name);
  } else if (isLateLoweredLocalSetterName(name)) {
    return extractLocalNameFromLateLoweredSetter(name);
  } else if (isLateLoweredIsSetLocalName(name)) {
    return extractLocalNameFromLateLoweredIsSet(name);
  } else if (isJoinedIntermediateName(name)) {
    return extractJoinedIntermediateName(name);
  }
  return null;
}

/// Infix used for the name of a joined intermediate variable.
///
/// See [isJoinedIntermediateName] for details.
const String joinedIntermediateInfix = "#case#";

/// Returns `true` if [node] is a joined intermediate variable.
///
/// See [isJoinedIntermediateName] for details.
bool isJoinedIntermediateVariable(VariableDeclaration node) {
  return node.isLowered &&
      node.name != null &&
      isJoinedIntermediateName(node.name!);
}

/// Returns `true` if [name] is the name of the "joined intermediate" variable
/// for a "joined local variable".
///
/// A joined local variable occurs when variables of the same name are declared
/// in multiple switch cases for the same body. For instance
///
///     switch (o) {
///       case [var a, _] when a > 5:
///       case [_, var a] when a < 5:
///         print(a);
///     }
///
/// In this cases the 'a' in `print(a)` is a joined variable but the 'a'
/// variables used in the guards of the case are joined intermediate variables:
///
///     {
///       var a#case#0; // intermediate variable for the joined variable 'a'.
///       var a#case#1; // intermediate variable for the joined variable 'a'.
///       var #t1; // temporary variable for the joined variable 'a'.
///       if (o is List<dynamic> &&
///           o.length == 2 &&
///           let #1 in #t1 = a#case#0 = o[0] in true &&
///           a#case#0 > 5 ||
///           o is List<dynamic> &&
///           o.length == 2 &&
///           let #1 in #t1 = a#case#1 = o[1] in true &&
///           a#case#1 < 5) {
///         var a = #t1;
///         {
///           print(a);
///         }
///       }
///     }
///
bool isJoinedIntermediateName(String name) {
  int index = name.indexOf(joinedIntermediateInfix);
  if (index == -1) {
    return false;
  }
  return int.tryParse(name.substring(index + joinedIntermediateInfix.length)) !=
      null;
}

/// Returns the original name for a joined intermediate variable from the [name]
/// of the lowered variable.
///
/// This method assumes that `isJoinedIntermediateName(name)` is `true`.
///
/// See [isJoinedIntermediateName] for details.
String extractJoinedIntermediateName(String name) {
  int index = name.indexOf(joinedIntermediateInfix);
  return name.substring(0, index);
}

/// Infix used for the name of a joined intermediate variable.
///
/// See [isJoinedIntermediateName] for details.
String createJoinedIntermediateName(String variableName, int index) {
  return '$variableName$joinedIntermediateInfix$index';
}
