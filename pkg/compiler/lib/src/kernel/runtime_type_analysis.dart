// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../common/names.dart';
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../universe/feature.dart';

/// Computes the [RuntimeTypeUse] corresponding to the `e.runtimeType` [node].
RuntimeTypeUse computeRuntimeTypeUse(
    KernelToElementMapForImpact elementMap, ir.PropertyGet node) {
  /// Returns `true` if [node] is of the form `e.runtimeType`.
  bool isGetRuntimeType(ir.TreeNode node) {
    return node is ir.PropertyGet && node.name.name == Identifiers.runtimeType_;
  }

  /// Returns [node] if [node] is of the form `e.runtimeType` and `null`
  /// otherwise.
  ir.PropertyGet asGetRuntimeType(ir.TreeNode node) {
    return isGetRuntimeType(node) ? node : null;
  }

  /// Returns `true` if [node] is of the form `e.toString()`.
  bool isInvokeToString(ir.TreeNode node) {
    return node is ir.MethodInvocation && node.name.name == 'toString';
  }

  assert(isGetRuntimeType(node));

  // TODO(johnniwinther): Special-case `this.runtimeType`.
  ir.Expression receiver;
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
        }
      } else if (nullAware.parent is ir.MethodInvocation) {
        ir.MethodInvocation methodInvocation = nullAware.parent;
        if (methodInvocation.receiver == nullAware.let &&
            methodInvocation.name.name == '==') {
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
            argument = otherGetRuntimeType.receiver;
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
            argument = otherNullAware.receiver;
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
        }
      } else if (nullAware.parent is ir.Arguments &&
          nullAware.parent.parent is ir.MethodInvocation) {
        ir.MethodInvocation methodInvocation = nullAware.parent.parent;
        if (methodInvocation.name.name == '==' &&
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
            argument = nullAware.receiver;
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
            argument = nullAware.receiver;
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
    }
  } else if (node.parent is ir.MethodInvocation) {
    ir.MethodInvocation methodInvocation = node.parent;
    if (methodInvocation.name.name == '==' &&
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
        argument = otherGetRuntimeType.receiver;
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
        argument = nullAware.receiver;
      }
    } else if (isInvokeToString(node.parent)) {
      // Detected
      //
      //     e.runtimeType.toString()
      //       ^
      kind = RuntimeTypeUseKind.string;
      receiver = node.receiver;
    }
  } else if (node.parent is ir.Arguments &&
      node.parent.parent is ir.MethodInvocation) {
    ir.MethodInvocation methodInvocation = node.parent.parent;
    if (methodInvocation.name.name == '==' &&
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
        argument = node.receiver;
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
        argument = node.receiver;
      }
    }
  } else if (node.parent is ir.StringConcatenation) {
    // Detected
    //
    //     '${e.runtimeType}'
    //          ^
    kind = RuntimeTypeUseKind.string;
    receiver = node.receiver;
  }

  if (kind == null) {
    // Default to unknown
    //
    //     e.runtimeType
    //       ^
    kind = RuntimeTypeUseKind.unknown;
    receiver = node.receiver;
  }

  DartType receiverType = elementMap.getStaticType(receiver);
  DartType argumentType =
      argument == null ? argument : elementMap.getStaticType(argument);
  return new RuntimeTypeUse(kind, receiverType, argumentType);
}
