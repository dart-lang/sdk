// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddExplicitCast extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_EXPLICIT_CAST;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var target = coveredNode;
    if (target is! Expression) {
      return;
    }

    var fromType = target.typeOrThrow;
    if (fromType == typeProvider.nullType) {
      // There would only be a diagnostic if the `toType` is not nullable, in
      // which case a cast won't fix the problem.
      return;
    }
    DartType toType;
    var parent = target.parent;
    if (parent is CascadeExpression && target == parent.target) {
      target = parent;
      parent = target.parent;
    }
    if (parent is AssignmentExpression && target == parent.rightHandSide) {
      toType = parent.writeType!;
    } else if (parent is VariableDeclaration && target == parent.initializer) {
      toType = parent.declaredElement!.type;
    } else {
      // TODO(brianwilkerson) Handle function arguments.
      return;
    }
    if (typeSystem.isAssignableTo(
        toType, typeSystem.promoteToNonNull(fromType))) {
      // The only reason that `fromType` can't be assigned to `toType` is
      // because it's nullable, in which case a cast won't fix the problem.
      return;
    }
    // TODO(brianwilkerson) Handle `toSet` in a manner similar to the below.
    if (target.isToListMethodInvocation) {
      var targetTarget = (target as MethodInvocation).target;
      if (targetTarget != null) {
        var targetTargetType = targetTarget.typeOrThrow;
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

    final target_final = target;

    var needsParentheses = target.precedence < Precedence.postfix;
    if (((fromType.isDartCoreIterable || fromType.isDartCoreList) &&
            toType is InterfaceType &&
            toType.isDartCoreList) ||
        (fromType.isDartCoreSet &&
            toType is InterfaceType &&
            toType.isDartCoreSet)) {
      if (target.isCastMethodInvocation) {
        // TODO(brianwilkerson) Consider updating the type arguments to the
        // `cast` invocation.
        return;
      }
      final toType_final = toType;
      await builder.addDartFileEdit(file, (builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target_final.offset, '(');
        }
        builder.addInsertion(target_final.end, (builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType(toType_final.typeArguments[0]);
          builder.write('>()');
        });
      });
    } else if (fromType.isDartCoreMap &&
        toType is InterfaceType &&
        toType.isDartCoreMap) {
      if (target.isCastMethodInvocation) {
        // TODO(brianwilkerson) Consider updating the type arguments to the
        // `cast` invocation.
        return;
      }
      final toType_final = toType;
      await builder.addDartFileEdit(file, (builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target_final.offset, '(');
        }
        builder.addInsertion(target_final.end, (builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType(toType_final.typeArguments[0]);
          builder.write(', ');
          builder.writeType(toType_final.typeArguments[1]);
          builder.write('>()');
        });
      });
    } else {
      await builder.addDartFileEdit(file, (builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target_final.offset, '(');
        }
        builder.addInsertion(target_final.end, (builder) {
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
