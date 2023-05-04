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
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddExplicitCast extends CorrectionProducer {
  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.ADD_EXPLICIT_CAST;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_EXPLICIT_CAST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var target = coveredNode;
    if (target is! Expression) {
      return;
    }

    var fromType = target.staticType;
    if (fromType == null) {
      return;
    }

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
    } else if (parent is ArgumentList) {
      var staticType = target.staticParameterElement?.type;
      if (staticType == null) return;
      toType = staticType;
    } else {
      return;
    }
    if (typeSystem.isAssignableTo(
        toType, typeSystem.promoteToNonNull(fromType))) {
      // The only reason that `fromType` can't be assigned to `toType` is
      // because it's nullable, in which case a cast won't fix the problem.
      return;
    }
    if (target.isToListMethodInvocation || target.isToSetMethodInvocation) {
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
      var type = target.type;
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(type), (builder) {
          builder.writeType(toType);
        });
      });
      return;
    }

    final target_final = target;

    var needsParentheses = target.precedence < Precedence.postfix;
    if (toType is InterfaceType &&
        (fromType.isDartCoreIterable ||
            fromType.isDartCoreList ||
            fromType.isDartCoreSet) &&
        (toType.isDartCoreList || toType.isDartCoreSet)) {
      final toType_final = toType;
      if (target.isCastMethodInvocation) {
        var typeArguments = (target as MethodInvocation).typeArguments;
        if (typeArguments != null) {
          await builder.addDartFileEdit(file, (builder) {
            _replaceTypeArgument(builder, typeArguments, toType_final, 0);
          });
        }
        return;
      }
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
      final toType_final = toType;
      if (target.isCastMethodInvocation) {
        var typeArguments = (target as MethodInvocation).typeArguments;
        if (typeArguments != null) {
          await builder.addDartFileEdit(file, (builder) {
            _replaceTypeArgument(builder, typeArguments, toType_final, 0);
            _replaceTypeArgument(builder, typeArguments, toType_final, 1);
          });
        }
        return;
      }
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

  /// Replace the type argument of [typeArguments] at the specified [index]
  /// with the corresponding type argument of [toType].
  void _replaceTypeArgument(DartFileEditBuilder builder,
      TypeArgumentList typeArguments, InterfaceType toType, int index) {
    var replacementRange = range.node(typeArguments.arguments[index]);
    builder.addReplacement(replacementRange, (builder) {
      builder.writeType(toType.typeArguments[index]);
    });
  }
}
