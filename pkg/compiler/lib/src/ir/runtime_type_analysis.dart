// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/names.dart';
import 'util.dart';

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
  final ir.PropertyGet leftRuntimeTypeExpression;

  /// The receiver expression.
  final ir.Expression receiver;

  /// The static type of the receiver expression. This is set in the static type
  /// visitor.
  ir.DartType receiverType;

  /// The property get for the right occurrence of `.runtimeType` when [kind]
  /// is `RuntimeTypeUseKind.equals`.
  final ir.PropertyGet rightRuntimeTypeExpression;

  /// The argument expression if [kind] is `RuntimeTypeUseKind.equals`.
  final ir.Expression argument;

  /// The static type of the argument expression. This is set in the static type
  /// visitor.
  ir.DartType argumentType;

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
    throw new UnsupportedError("Unexpected RuntimeTypeUseKind $kind.");
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
    Map<ir.PropertyGet, RuntimeTypeUseData> cache, ir.PropertyGet node) {
  RuntimeTypeUseData receiverData = cache[node];
  if (receiverData != null) return receiverData;

  /// Returns `true` if [node] is of the form `e.runtimeType`.
  bool isGetRuntimeType(ir.TreeNode node) {
    return node is ir.PropertyGet && node.name.text == Identifiers.runtimeType_;
  }

  /// Returns [node] if [node] is of the form `e.runtimeType` and `null`
  /// otherwise.
  ir.PropertyGet asGetRuntimeType(ir.TreeNode node) {
    return isGetRuntimeType(node) ? node : null;
  }

  /// Returns `true` if [node] is of the form `e.toString()`.
  bool isInvokeToString(ir.TreeNode node) {
    return node is ir.MethodInvocation && node.name.text == 'toString';
  }

  assert(isGetRuntimeType(node));

  // TODO(johnniwinther): Special-case `this.runtimeType`.
  ir.PropertyGet receiverGet;
  ir.Expression receiver;
  ir.PropertyGet argumentGet;
  ir.Expression argument;
  RuntimeTypeUseKind kind;

  if (node.receiver is ir.VariableGet &&
      node.parent is ir.ConditionalExpression &&
      node.parent.parent is ir.Let) {
    NullAwareExpression nullAware = getNullAwareExpression(node.parent.parent);
    if (nullAware != null) {
      // The node is of the form:
      //
      //     let #t1 = e in #t1 == null ? null : #t1.runtimeType
      //                                             ^

      if (nullAware.parent is ir.VariableDeclaration &&
          nullAware.parent.parent is ir.Let) {
        NullAwareExpression outer =
            getNullAwareExpression(nullAware.parent.parent);
        if (outer != null &&
            outer.receiver == nullAware.let &&
            isInvokeToString(outer.expression)) {
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
      } else if (nullAware.parent is ir.MethodInvocation) {
        ir.MethodInvocation methodInvocation = nullAware.parent;
        if (methodInvocation.receiver == nullAware.let &&
            methodInvocation.name.text == '==') {
          // Detected
          //
          //  e0?.runtimeType == other
          ir.PropertyGet otherGetRuntimeType =
              asGetRuntimeType(methodInvocation.arguments.positional.first);
          if (otherGetRuntimeType != null) {
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
            argument = otherGetRuntimeType.receiver;
            argumentGet = methodInvocation.arguments.positional.first;
          }

          NullAwareExpression otherNullAware = getNullAwareExpression(
              methodInvocation.arguments.positional.first);
          if (otherNullAware != null &&
              isGetRuntimeType(otherNullAware.expression)) {
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
            argumentGet = otherNullAware.expression;
          }
        } else if (isInvokeToString(nullAware.parent)) {
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
      } else if (nullAware.parent is ir.Arguments &&
          nullAware.parent.parent is ir.MethodInvocation) {
        ir.MethodInvocation methodInvocation = nullAware.parent.parent;
        if (methodInvocation.name.text == '==' &&
            methodInvocation.arguments.positional.first == nullAware.let) {
          // [nullAware] is the right hand side of ==.

          ir.PropertyGet otherGetRuntimeType =
              asGetRuntimeType(methodInvocation.receiver);
          NullAwareExpression otherNullAware =
              getNullAwareExpression(methodInvocation.receiver);

          if (otherGetRuntimeType != null) {
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
            receiver = otherGetRuntimeType.receiver;
            receiverGet = otherGetRuntimeType;
            argument = nullAware.receiver;
            argumentGet = node;
          }

          if (otherNullAware != null &&
              isGetRuntimeType(otherNullAware.expression)) {
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
            receiverGet = otherNullAware.expression;
            argument = nullAware.receiver;
            argumentGet = node;
          }
        }
      } else if (nullAware.parent is ir.StringConcatenation) {
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
  } else if (node.parent is ir.VariableDeclaration &&
      node.parent.parent is ir.Let) {
    NullAwareExpression nullAware = getNullAwareExpression(node.parent.parent);
    if (nullAware != null && isInvokeToString(nullAware.expression)) {
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
  } else if (node.parent is ir.MethodInvocation) {
    ir.MethodInvocation methodInvocation = node.parent;
    if (methodInvocation.name.text == '==' &&
        methodInvocation.receiver == node) {
      // [node] is the left hand side of ==.

      ir.PropertyGet otherGetRuntimeType =
          asGetRuntimeType(methodInvocation.arguments.positional.first);
      NullAwareExpression nullAware =
          getNullAwareExpression(methodInvocation.arguments.positional.first);
      if (otherGetRuntimeType != null) {
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
        argument = otherGetRuntimeType.receiver;
        argumentGet = otherGetRuntimeType;
      } else if (nullAware != null && isGetRuntimeType(nullAware.expression)) {
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
        argumentGet = nullAware.expression;
      }
    } else if (isInvokeToString(node.parent)) {
      // Detected
      //
      //     e.runtimeType.toString()
      //       ^
      kind = RuntimeTypeUseKind.string;
      receiver = node.receiver;
      receiverGet = node;
    }
  } else if (node.parent is ir.Arguments &&
      node.parent.parent is ir.MethodInvocation) {
    ir.MethodInvocation methodInvocation = node.parent.parent;
    if (methodInvocation.name.text == '==' &&
        methodInvocation.arguments.positional.first == node) {
      // [node] is the right hand side of ==.
      ir.PropertyGet otherGetRuntimeType =
          asGetRuntimeType(methodInvocation.receiver);
      NullAwareExpression nullAware =
          getNullAwareExpression(methodInvocation.receiver);

      if (otherGetRuntimeType != null) {
        // Detected
        //
        //     e0.runtimeType == e1.runtimeType
        //                          ^
        // encoded as
        //
        //     e0.runtimeType.==(e1.runtimeType)
        //                          ^
        kind = RuntimeTypeUseKind.equals;
        receiver = otherGetRuntimeType.receiver;
        receiverGet = otherGetRuntimeType;
        argument = node.receiver;
        argumentGet = node;
      } else if (nullAware != null && isGetRuntimeType(nullAware.expression)) {
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
        receiverGet = nullAware.expression;
        argument = node.receiver;
        argumentGet = node;
      }
    }
  } else if (node.parent is ir.StringConcatenation) {
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

  RuntimeTypeUseData data = new RuntimeTypeUseData(
      kind, receiverGet, receiver, argumentGet, argument);
  cache[receiverGet] = data;
  if (argumentGet != null) {
    cache[argumentGet] = data;
  }

  assert(receiverGet != null, "Missing receiverGet in $data for $node.");
  assert(!(argument != null && argumentGet == null),
      "Missing argumentGet in $data for $node.");
  assert(
      receiverGet != argumentGet, "Duplicate property get in $data for $node.");
  return data;
}
