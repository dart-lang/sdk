// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/names.dart';

/// Enum for recognized use kinds of `Object.runtimeType`.
enum RuntimeTypeUseKind {
  /// Unknown use of `Object.runtimeType`. This is the fallback value if the
  /// usage didn't match any of the recognized patterns.
  unknown,

  /// `Object.runtimeType` used in a pattern like
  /// `a.runtimeType == b.runtimeType`.
  equals,

  /// `Object.runtimeType` used in a pattern like `'${e.runtimeType}'` or
  /// `e.runtimeType.toString()`.
  string,
}

/// Data object use for computing static type information on uses of
/// `Object.runtimeType`.
class RuntimeTypeUseData {
  /// The use kind of `Object.runtimeType`.
  final RuntimeTypeUseKind kind;

  /// The property get for the left (or single) occurrence of `.runtimeType`.
  final ir.InstanceGet leftRuntimeTypeExpression;

  /// The receiver expression.
  final ir.Expression receiver;

  /// The static type of the receiver expression. This is set in the static type
  /// visitor.
  ir.DartType? receiverType;

  /// The property get for the right occurrence of `.runtimeType` when [kind]
  /// is `RuntimeTypeUseKind.equals`.
  final ir.InstanceGet? rightRuntimeTypeExpression;

  /// The argument expression if [kind] is `RuntimeTypeUseKind.equals`.
  final ir.Expression? argument;

  /// The static type of the argument expression. This is set in the static type
  /// visitor.
  ir.DartType? argumentType;

  RuntimeTypeUseData(this.kind, this.leftRuntimeTypeExpression, this.receiver,
      this.rightRuntimeTypeExpression, this.argument);

  bool get isComplete {
    switch (kind) {
      case RuntimeTypeUseKind.unknown:
      case RuntimeTypeUseKind.string:
        return receiverType != null;
      case RuntimeTypeUseKind.equals:
        return receiverType != null && argumentType != null;
    }
  }

  @override
  String toString() {
    return "RuntimeTypeUseData(kind=$kind,"
        "receiverGet=$leftRuntimeTypeExpression,receiver=$receiver,"
        "receiverType=$receiverType,argumentGet=$rightRuntimeTypeExpression,"
        "argument=$argument,argumentType=$argumentType)";
  }
}

/// Computes the [RuntimeTypeUseData] corresponding to the `e.runtimeType`
/// [node].
///
/// [cache] is used to ensure that only one [RuntimeTypeUseData] object is
/// created per case, even for the `==` case.
RuntimeTypeUseData computeRuntimeTypeUse(
    Map<ir.InstanceGet, RuntimeTypeUseData> cache, ir.InstanceGet node) {
  RuntimeTypeUseData? receiverData = cache[node];
  if (receiverData != null) return receiverData;

  assert(_isGetRuntimeType(node));

  // TODO(johnniwinther): Special-case `this.runtimeType`.
  late final ir.InstanceGet receiverGet;
  late final ir.Expression receiver;
  ir.InstanceGet? argumentGet;
  ir.Expression? argument;
  RuntimeTypeUseKind? kind;

  final nodeParent = node.parent;
  final nodeParentParent = nodeParent?.parent;
  if (node.receiver is ir.VariableGet &&
      nodeParent is ir.ConditionalExpression &&
      nodeParentParent is ir.Let) {
    _NullAwareExpression? nullAware = getNullAwareExpression(nodeParentParent);
    if (nullAware != null) {
      // The node is of the form:
      //
      //     let #t1 = e in #t1 == null ? null : #t1.runtimeType
      //                                             ^

      final nullAwareParent = nullAware.parent;
      final nullAwareParentParent = nullAwareParent.parent;
      if (nullAwareParent is ir.VariableDeclaration &&
          nullAwareParentParent is ir.Let) {
        _NullAwareExpression? outer =
            getNullAwareExpression(nullAwareParentParent);
        if (outer != null &&
            outer.receiver == nullAware.let &&
            _isInvokeToString(outer.expression)) {
          // Detected
          //
          //     e?.runtimeType?.toString()
          //        ^
          // encoded as
          //
          //     let #t2 = (let #t1 = e in #t1 == null ? null : #t1.runtimeType)
          //                                                        ^
          //        in #t2 == null ? null : #t2.toString()
          //
          kind = RuntimeTypeUseKind.string;
          receiver = nullAware.receiver;
          receiverGet = node;
        }
      } else if (_isObjectMethodInvocation(nullAwareParent)) {
        if (nullAwareParent is ir.EqualsCall &&
            nullAwareParent.left == nullAware.let) {
          // Detected
          //
          //  e0?.runtimeType == other
          if (_extractGetRuntimeType(nullAwareParent.right)
              case final getRuntimeType?) {
            // Detected
            //
            //     e0?.runtimeType == e1.runtimeType
            //         ^
            // encoded as
            //
            //     (let #t1 = e0 in #t1 == null ? null : #t1.runtimeType)
            //                                               ^
            //        .==(e1.runtimeType)
            kind = RuntimeTypeUseKind.equals;
            receiver = nullAware.receiver;
            receiverGet = node;
            argument = getRuntimeType.receiver;
            argumentGet = getRuntimeType;
          }

          _NullAwareExpression? otherNullAware =
              getNullAwareExpression(nullAwareParent.right);
          if (otherNullAware != null) {
            if (_extractGetRuntimeType(otherNullAware.expression)
                case final getRuntimeType?) {
              // Detected
              //
              //     e0?.runtimeType == e1?.runtimeType
              //         ^
              // encoded as
              //
              //     (let #t1 = e0 in #t1 == null ? null : #t1.runtimeType)
              //                                               ^
              //         .==(let #t2 = e1 in #t2 == null ? null : #t2.runtimeType)
              //
              kind = RuntimeTypeUseKind.equals;
              receiver = nullAware.receiver;
              receiverGet = node;
              argument = otherNullAware.receiver;
              argumentGet = getRuntimeType;
            }
          }
        } else if (_isInvokeToString(nullAwareParent)) {
          // Detected
          //
          //     e?.runtimeType.toString()
          //        ^
          // encoded as
          //
          //     (let #t1 = e in #t1 == null ? null : #t1.runtimeType)
          //                                          ^
          //         .toString()
          //
          kind = RuntimeTypeUseKind.string;
          receiver = nullAware.receiver;
          receiverGet = node;
        }
      } else if (nullAwareParent is ir.Arguments &&
          _isObjectMethodInvocation(nullAwareParentParent)) {
        if (nullAwareParentParent is ir.EqualsCall &&
            nullAwareParentParent.right == nullAware.let) {
          // [nullAware] is the right hand side of ==.

          _NullAwareExpression? otherNullAware =
              getNullAwareExpression(nullAwareParentParent.left);

          if (_extractGetRuntimeType(nullAwareParentParent.left)
              case final getRuntimeType?) {
            // Detected
            //
            //     e0.runtimeType == e1?.runtimeType
            //                           ^
            // encoded as
            //
            //     e0.runtimeType.==(
            //         let #t1 = e1 in #t1 == null ? null : #t1.runtimeType)
            //                                                  ^
            kind = RuntimeTypeUseKind.equals;
            receiver = getRuntimeType.receiver;
            receiverGet = getRuntimeType;
            argument = nullAware.receiver;
            argumentGet = node;
          }

          if (otherNullAware != null) {
            if (_extractGetRuntimeType(otherNullAware.expression)
                case final getRuntimeType?) {
              // Detected
              //
              //     e0?.runtimeType == e1?.runtimeType
              //                            ^
              // encoded as
              //
              //     (let #t1 = e0 in #t1 == null ? null : #t1.runtimeType)
              //         .==(let #t2 = e1 in #t2 == null ? null : #t2.runtimeType)
              //                                                      ^
              kind = RuntimeTypeUseKind.equals;
              receiver = otherNullAware.receiver;
              receiverGet = getRuntimeType;
              argument = nullAware.receiver;
              argumentGet = node;
            }
          }
        }
      } else if (nullAwareParent is ir.StringConcatenation) {
        // Detected
        //
        //     '${e?.runtimeType}'
        //           ^
        // encoded as
        //
        //     '${let #t1 = e in #t1 == null ? null : #t1.runtimeType}'
        //                                                ^
        kind = RuntimeTypeUseKind.string;
        receiver = nullAware.receiver;
        receiverGet = node;
      } else {
        // Default to unknown
        //
        //     e?.runtimeType
        //        ^
        // encoded as
        //
        //     let #t1 = e in #t1 == null ? null : #t1.runtimeType
        //                                         ^
        kind = RuntimeTypeUseKind.unknown;
        receiver = nullAware.receiver;
        receiverGet = node;
      }
    }
  } else if (nodeParent is ir.VariableDeclaration &&
      nodeParentParent is ir.Let) {
    _NullAwareExpression? nullAware = getNullAwareExpression(nodeParentParent);
    if (nullAware != null && _isInvokeToString(nullAware.expression)) {
      // Detected
      //
      //     e.runtimeType?.toString()
      //       ^
      // encoded as
      //
      //     let #t1 = e.runtimeType in #t1 == null ? null : #t1.toString()
      //                 ^
      kind = RuntimeTypeUseKind.string;
      receiver = node.receiver;
      receiverGet = node;
    }
  } else if (_isObjectMethodInvocation(nodeParent)) {
    if (nodeParent is ir.EqualsCall && nodeParent.left == node) {
      // [node] is the left hand side of ==.

      _NullAwareExpression? nullAware =
          getNullAwareExpression(nodeParent.right);
      if (_extractGetRuntimeType(nodeParent.right) case final getRuntimeType?) {
        // Detected
        //
        //     e0.runtimeType == e1.runtimeType
        //        ^
        // encoded as
        //
        //     e0.runtimeType.==(e1.runtimeType)
        //        ^
        kind = RuntimeTypeUseKind.equals;
        receiver = node.receiver;
        receiverGet = node;
        argument = getRuntimeType.receiver;
        argumentGet = getRuntimeType;
      } else if (nullAware != null) {
        if (_extractGetRuntimeType(nullAware.expression)
            case final getRuntimeType?) {
          // Detected
          //
          //     e0.runtimeType == e1?.runtimeType
          //        ^
          // encoded as
          //
          //     e0.runtimeType.==(
          //        ^
          //         let #t1 = e1 in #t1 == null ? null : #t1.runtimeType)
          kind = RuntimeTypeUseKind.equals;
          receiver = node.receiver;
          receiverGet = node;
          argument = nullAware.receiver;
          argumentGet = getRuntimeType;
        }
      }
    } else if (_isInvokeToString(nodeParent)) {
      // Detected
      //
      //     e.runtimeType.toString()
      //       ^
      kind = RuntimeTypeUseKind.string;
      receiver = node.receiver;
      receiverGet = node;
    }
  } else if (nodeParent is ir.Arguments &&
      _isObjectMethodInvocation(nodeParentParent)) {
    if (nodeParentParent is ir.EqualsCall && nodeParentParent.right == node) {
      // [node] is the right hand side of ==.
      _NullAwareExpression? nullAware =
          getNullAwareExpression(nodeParentParent.left);

      if (_extractGetRuntimeType(nodeParentParent.left)
          case final getRuntimeType?) {
        // Detected
        //
        //     e0.runtimeType == e1.runtimeType
        //                          ^
        // encoded as
        //
        //     e0.runtimeType.==(e1.runtimeType)
        //                          ^
        kind = RuntimeTypeUseKind.equals;
        receiver = getRuntimeType.receiver;
        receiverGet = getRuntimeType;
        argument = node.receiver;
        argumentGet = node;
      } else if (nullAware != null) {
        if (_extractGetRuntimeType(nullAware.expression)
            case final getRuntimeType?) {
          // Detected
          //
          //     e0?.runtimeType == e1.runtimeType
          //                           ^
          // encoded as
          //
          //     (let #t1 = e0 in #t1 == null ? null : #t1.runtimeType)
          //         .==(e1.runtimeType)
          //                ^
          kind = RuntimeTypeUseKind.equals;
          receiver = nullAware.receiver;
          receiverGet = getRuntimeType;
          argument = node.receiver;
          argumentGet = node;
        }
      }
    }
  } else if (nodeParent is ir.StringConcatenation) {
    // Detected
    //
    //     '${e.runtimeType}'
    //          ^
    kind = RuntimeTypeUseKind.string;
    receiver = node.receiver;
    receiverGet = node;
  }

  if (kind == null) {
    // Default to unknown
    //
    //     e.runtimeType
    //       ^
    kind = RuntimeTypeUseKind.unknown;
    receiver = node.receiver;
    receiverGet = node;
  }

  RuntimeTypeUseData data =
      RuntimeTypeUseData(kind, receiverGet, receiver, argumentGet, argument);
  cache[receiverGet] = data;
  if (argumentGet != null) {
    cache[argumentGet] = data;
  }

  assert(!(argument != null && argumentGet == null),
      "Missing argumentGet in $data for $node.");
  assert(
      receiverGet != argumentGet, "Duplicate property get in $data for $node.");
  return data;
}

/// Returns `true` if [node] is a potential invocation of an Object method.
bool _isObjectMethodInvocation(ir.TreeNode? node) {
  return node is ir.InstanceInvocation || node is ir.EqualsCall;
}

/// Returns `true` if [node] is of the form `e.runtimeType` and `null`
/// otherwise.
bool _isGetRuntimeType(ir.InstanceGet node) =>
    node.name.text == Identifiers.runtimeType_;

/// Returns `true` if [node] is of the form `e.toString()`.
bool _isInvokeToString(ir.TreeNode? node) =>
    node is ir.InstanceInvocation && node.name.text == 'toString';

ir.InstanceGet? _extractGetRuntimeType(ir.TreeNode node) =>
    node is ir.InstanceGet && _isGetRuntimeType(node) ? node : null;

/// Kernel encodes a null-aware expression `a?.b` as
///
///     let final #1 = a in #1 == null ? null : #1.b
///
/// [getNullAwareExpression] recognizes such expressions storing the result in
/// a [_NullAwareExpression] object.
///
/// [syntheticVariable] holds the synthesized `#1` variable. [expression] holds
/// the `#1.b` expression. [receiver] returns `a` expression. [parent] returns
/// the parent of the let node, i.e. the parent node of the original null-aware
/// expression. [let] returns the let node created for the encoding.
class _NullAwareExpression {
  final ir.Let let;
  final ir.VariableDeclaration syntheticVariable;
  final ir.Expression expression;

  _NullAwareExpression(this.let, this.syntheticVariable, this.expression);

  ir.Expression get receiver => syntheticVariable.initializer!;

  ir.TreeNode get parent => let.parent!;

  @override
  String toString() => let.toString();
}

_NullAwareExpression? getNullAwareExpression(ir.TreeNode node) {
  if (node is ir.Let) {
    ir.Expression body = node.body;
    if (node.variable.name == null &&
        node.variable.isFinal &&
        body is ir.ConditionalExpression) {
      final condition = body.condition;
      if (condition is ir.EqualsNull) {
        ir.Expression receiver = condition.expression;
        if (receiver is ir.VariableGet && receiver.variable == node.variable) {
          // We have
          //   let #t1 = e0 in #t1 == null ? null : e1
          return _NullAwareExpression(node, node.variable, body.otherwise);
        }
      }
    }
  }
  return null;
}
