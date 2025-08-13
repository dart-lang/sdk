// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddExplicitCast extends ResolvedCorrectionProducer {
  AddExplicitCast({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.ADD_EXPLICIT_CAST;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_EXPLICIT_CAST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetAndTypes = _computeTargetAndTypes();
    if (targetAndTypes == null) {
      return;
    }

    var (:target, :fromType, :toType) = targetAndTypes;

    if (target is AsExpression) {
      var type = target.type;
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(type), (builder) {
          builder.writeType(toType);
        });
      });
      return;
    }

    var needsParentheses = target.precedence < Precedence.postfix;
    if (toType is InterfaceType &&
        (fromType.isDartCoreIterable ||
            fromType.isDartCoreList ||
            fromType.isDartCoreSet) &&
        (toType.isDartCoreList || toType.isDartCoreSet)) {
      if (target is MethodInvocation && target.isCastMethodInvocation) {
        var typeArguments = target.typeArguments;
        if (typeArguments != null) {
          await builder.addDartFileEdit(file, (builder) {
            _replaceTypeArgument(builder, typeArguments, toType, 0);
          });
        }
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType(toType.typeArguments[0]);
          builder.write('>()');
        });
      });
    } else if (fromType.isDartCoreMap &&
        toType is InterfaceType &&
        toType.isDartCoreMap) {
      if (target is MethodInvocation && target.isCastMethodInvocation) {
        var typeArguments = target.typeArguments;
        if (typeArguments != null) {
          await builder.addDartFileEdit(file, (builder) {
            _replaceTypeArgument(builder, typeArguments, toType, 0);
            _replaceTypeArgument(builder, typeArguments, toType, 1);
          });
        }
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write('.cast<');
          builder.writeType(toType.typeArguments[0]);
          builder.write(', ');
          builder.writeType(toType.typeArguments[1]);
          builder.write('>()');
        });
      });
    } else {
      await builder.addDartFileEdit(file, (builder) {
        if (needsParentheses) {
          builder.addSimpleInsertion(target.offset, '(');
        }
        builder.addInsertion(target.end, (builder) {
          if (needsParentheses) {
            builder.write(')');
          }
          builder.write(' as ');
          builder.writeType(toType);
        });
      });
    }
  }

  /// Computes the target [Expression], the "from" [DartType], and the "to"
  /// [DartType] for various types of casts.
  ///
  /// A `null` return value means these values cannot be computed, and a
  /// correction cannot be made.
  ({Expression target, DartType fromType, DartType toType})?
  _computeTargetAndTypes() {
    var target = coveringNode;
    if (target is! Expression || target.endToken.isSynthetic) {
      return null;
    }

    var fromType = target.staticType;
    if (fromType == null) {
      return null;
    }

    if (fromType == typeProvider.nullType) {
      // There would only be a diagnostic if the `toType` is not nullable, in
      // which case a cast won't fix the problem.
      return null;
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
      if (parent.declaredFragment?.element case var declaredElement?) {
        toType = declaredElement.type;
      } else {
        return null;
      }
    } else if (parent is ArgumentList) {
      var staticType = target.correspondingParameter?.type;
      if (staticType == null) return null;
      toType = staticType;
    } else {
      return null;
    }
    if (typeSystem.isAssignableTo(
      toType,
      typeSystem.promoteToNonNull(fromType),
      strictCasts: analysisOptions.strictCasts,
    )) {
      // The only reason that `fromType` can't be assigned to `toType` is
      // because it's nullable, in which case a cast won't fix the problem.
      return null;
    }
    if (target is MethodInvocation &&
        (target.isToListMethodInvocation || target.isToSetMethodInvocation)) {
      var targetTarget = target.target;
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

    return (target: target, fromType: fromType, toType: toType);
  }

  /// Replace the type argument of [typeArguments] at the specified [index]
  /// with the corresponding type argument of [toType].
  void _replaceTypeArgument(
    DartFileEditBuilder builder,
    TypeArgumentList typeArguments,
    InterfaceType toType,
    int index,
  ) {
    var replacementRange = range.node(typeArguments.arguments[index]);
    builder.addReplacement(replacementRange, (builder) {
      builder.writeType(toType.typeArguments[index]);
    });
  }
}
