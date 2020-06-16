// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddExplicitCast extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_EXPLICIT_CAST;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    Expression target;
    if (coveredNode is Expression) {
      target = coveredNode;
    } else {
      return;
    }

    var fromType = target.staticType;
    DartType toType;
    var parent = target.parent;
    if (parent is AssignmentExpression && target == parent.rightHandSide) {
      toType = parent.leftHandSide.staticType;
    } else if (parent is VariableDeclaration && target == parent.initializer) {
      toType = parent.declaredElement.type;
    } else {
      // TODO(brianwilkerson) Handle function arguments.
      return;
    }
    // TODO(brianwilkerson) Handle `toSet` in a manner similar to the below.
    if (target.isToListMethodInvocation) {
      var targetTarget = (target as MethodInvocation).target;
      if (targetTarget != null) {
        var targetTargetType = targetTarget.staticType;
        if (targetTargetType.isDartCoreIterable ||
            targetTargetType.isDartCoreList ||
            targetTargetType.isDartCoreMap ||
            targetTargetType.isDartCoreSet) {
          target = targetTarget;
          fromType = targetTargetType;
        }
      }
    }
    if (target is AsExpression) {
      // TODO(brianwilkerson) Consider updating the right operand.
      return;
    }
    var needsParentheses = target.precedence < Precedence.postfix;
    if (((fromType.isDartCoreIterable || fromType.isDartCoreList) &&
            toType.isDartCoreList) ||
        (fromType.isDartCoreSet && toType.isDartCoreSet)) {
      if (target.isCastMethodInvocation) {
        // TODO(brianwilkerson) Consider updating the type arguments to the
        // `cast` invocation.
        return;
      }
      await builder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (DartEditBuilder builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType((toType as InterfaceType).typeArguments[0]);
          builder.write('>()');
        });
      });
    } else if (fromType.isDartCoreMap && toType.isDartCoreMap) {
      if (target.isCastMethodInvocation) {
        // TODO(brianwilkerson) Consider updating the type arguments to the
        // `cast` invocation.
        return;
      }
      await builder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (DartEditBuilder builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType((toType as InterfaceType).typeArguments[0]);
          builder.write(', ');
          builder.writeType((toType as InterfaceType).typeArguments[1]);
          builder.write('>()');
        });
      });
    } else {
      await builder.addFileEdit(file, (DartFileEditBuilder builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (DartEditBuilder builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write(' as ');
          builder.writeType(toType);
        });
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddExplicitCast newInstance() => AddExplicitCast();
}
