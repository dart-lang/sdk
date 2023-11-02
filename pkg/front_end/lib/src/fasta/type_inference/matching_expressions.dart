// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/delayed_expressions.dart';
import 'package:front_end/src/fasta/type_inference/external_ast_helper.dart';
import 'package:front_end/src/fasta/type_inference/matching_cache.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../../api_prototype/constant_evaluator.dart';
import '../names.dart';

/// Visitor that creates the [DelayedExpression] needed to match expressions,
/// using [MatchingCache] to create cacheable expressions.
class MatchingExpressionVisitor
    implements PatternVisitor1<DelayedExpression, CacheableExpression> {
  final MatchingCache matchingCache;
  final CoreTypes coreTypes;
  final EvaluationMode evaluationMode;

  MatchingExpressionVisitor(
      this.matchingCache, this.coreTypes, this.evaluationMode);

  DelayedExpression visitPattern(
      Pattern node, CacheableExpression matchedExpression) {
    return node.accept1(this, matchedExpression);
  }

  @override
  DelayedExpression visitAndPattern(
      AndPattern node, CacheableExpression matchedExpression) {
    return new DelayedAndExpression(visitPattern(node.left, matchedExpression),
        visitPattern(node.right, matchedExpression),
        fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitAssignedVariablePattern(
      AssignedVariablePattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedValueType!);

    DelayedExpression valueExpression;
    if (node.needsCast) {
      valueExpression = new DelayedAsExpression(
          matchedExpression, node.variable.type,
          fileOffset: node.fileOffset);
    } else {
      valueExpression = matchedExpression;
    }
    return new DelayedAssignment(
        matchingCache, node.variable, node.variable.type, valueExpression,
        fileOffset: node.fileOffset, hasEffect: node.hasObservableEffect);
  }

  @override
  DelayedExpression visitCastPattern(
      CastPattern node, CacheableExpression matchedExpression) {
    CacheableExpression asExpression = matchingCache.createAsExpression(
        matchedExpression, node.type,
        fileOffset: node.fileOffset);
    return new EffectExpression(
        asExpression, visitPattern(node.pattern, asExpression));
  }

  @override
  DelayedExpression visitConstantPattern(
      ConstantPattern node, CacheableExpression matchedExpression) {
    CacheableExpression constExpression = matchingCache
        .createConstantExpression(node.value!, node.expressionType!,
            fileOffset: node.fileOffset);
    return matchingCache.createEqualsExpression(
        constExpression,
        matchedExpression,
        new DelayedEqualsExpression(constExpression, matchedExpression,
            node.equalsTarget, node.equalsType!,
            fileOffset: node.fileOffset),
        fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitInvalidPattern(
      InvalidPattern node, CacheableExpression matchedExpression) {
    return new FixedExpression(node.invalidExpression, const InvalidType());
  }

  @override
  DelayedExpression visitListPattern(
      ListPattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedValueType!);

    CacheableExpression? isExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      isExpression = matchingCache.createIsExpression(
          matchedExpression, node.requiredType!,
          fileOffset: node.fileOffset);
      typedMatchedExpression = new PromotedCacheableExpression(
          matchedExpression, node.requiredType!);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    CacheableExpression lengthGet = matchingCache.createPropertyGetExpression(
        typedMatchedExpression,
        lengthName.text,
        new DelayedInstanceGet(
            typedMatchedExpression, node.lengthTarget, node.lengthType!,
            fileOffset: node.fileOffset),
        fileOffset: node.fileOffset);

    CacheableExpression? lengthCheck;
    if (node.hasRestPattern) {
      int minLength = node.patterns.length - 1;
      if (minLength > 0) {
        CacheableExpression constExpression = matchingCache
            .createIntConstant(minLength, fileOffset: node.fileOffset);

        lengthCheck = matchingCache.createComparisonExpression(
            lengthGet,
            greaterThanOrEqualsName.text,
            constExpression,
            new DelayedInstanceInvocation(lengthGet, node.lengthCheckTarget,
                node.lengthCheckType!, [constExpression],
                fileOffset: node.fileOffset),
            fileOffset: node.fileOffset);
      }
    } else {
      int length = node.patterns.length;
      CacheableExpression constExpression =
          matchingCache.createIntConstant(length, fileOffset: node.fileOffset);

      if (length == 0) {
        lengthCheck = matchingCache.createComparisonExpression(
            lengthGet,
            lessThanOrEqualsName.text,
            constExpression,
            new DelayedInstanceInvocation(lengthGet, node.lengthCheckTarget,
                node.lengthCheckType!, [constExpression],
                fileOffset: node.fileOffset),
            fileOffset: node.fileOffset);
      } else {
        lengthCheck = matchingCache.createEqualsExpression(
            lengthGet,
            constExpression,
            new DelayedEqualsExpression(lengthGet, constExpression,
                node.lengthCheckTarget, node.lengthCheckType!,
                fileOffset: node.fileOffset),
            fileOffset: node.fileOffset);
      }
    }

    DelayedExpression? matchingExpression;
    if (isExpression != null && lengthCheck != null) {
      matchingExpression = matchingCache.createAndExpression(
          isExpression, lengthCheck,
          fileOffset: node.fileOffset);
    } else if (isExpression != null) {
      matchingExpression = isExpression;
    } else if (lengthCheck != null) {
      matchingExpression = lengthCheck;
    }

    bool hasSeenRestPattern = false;
    for (int i = 0; i < node.patterns.length; i++) {
      CacheableExpression elementExpression;
      Pattern elementPattern = node.patterns[i];
      if (elementPattern is RestPattern) {
        hasSeenRestPattern = true;
        Pattern? subPattern = elementPattern.subPattern;
        if (subPattern == null) {
          continue;
        }

        int nextIndex = i + 1;
        int headSize = i;
        int tailSize = node.patterns.length - nextIndex;

        DelayedExpression expression;
        if (tailSize > 0) {
          expression = new DelayedInstanceInvocation(
              typedMatchedExpression,
              node.sublistTarget,
              node.sublistType!,
              [
                new IntegerExpression(headSize, fileOffset: node.fileOffset),
                new DelayedInstanceInvocation(
                    lengthGet,
                    node.minusTarget,
                    node.minusType!,
                    [
                      new IntegerExpression(tailSize,
                          fileOffset: node.fileOffset)
                    ],
                    fileOffset: node.fileOffset)
              ],
              fileOffset: node.fileOffset);
        } else {
          expression = new DelayedInstanceInvocation(
              typedMatchedExpression,
              node.sublistTarget,
              node.sublistType!,
              [new IntegerExpression(headSize, fileOffset: node.fileOffset)],
              fileOffset: node.fileOffset);
        }
        elementExpression = matchingCache.createSublistExpression(
            typedMatchedExpression, lengthGet, headSize, tailSize, expression,
            fileOffset: node.fileOffset);
      } else {
        if (!hasSeenRestPattern) {
          int index = i;
          elementExpression = matchingCache.createHeadIndexExpression(
              typedMatchedExpression,
              index,
              new DelayedInstanceInvocation(
                  typedMatchedExpression,
                  node.indexGetTarget,
                  node.indexGetType!,
                  [new IntegerExpression(index, fileOffset: node.fileOffset)],
                  fileOffset: node.fileOffset),
              fileOffset: node.fileOffset);
        } else {
          int index = node.patterns.length - i;
          elementExpression = matchingCache.createTailIndexExpression(
              typedMatchedExpression,
              lengthGet,
              index,
              new DelayedInstanceInvocation(
                  typedMatchedExpression,
                  node.indexGetTarget,
                  node.indexGetType!,
                  [
                    new DelayedInstanceInvocation(
                        lengthGet,
                        node.minusTarget,
                        node.minusType!,
                        [
                          new IntegerExpression(index,
                              fileOffset: node.fileOffset)
                        ],
                        fileOffset: node.fileOffset)
                  ],
                  fileOffset: node.fileOffset),
              fileOffset: node.fileOffset);
        }
      }

      DelayedExpression elementMatcher =
          visitPattern(elementPattern, elementExpression);
      matchingExpression = DelayedAndExpression.merge(
          matchingExpression, elementMatcher,
          fileOffset: node.fileOffset);
    }
    return matchingExpression ??
        new BooleanExpression(true, fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitMapPattern(
      MapPattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedValueType!);

    CacheableExpression? isExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      isExpression = matchingCache.createIsExpression(
          matchedExpression, node.requiredType!,
          fileOffset: node.fileOffset);
      typedMatchedExpression = new PromotedCacheableExpression(
          matchedExpression, node.requiredType!);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    DelayedExpression? matchingExpression;
    if (isExpression != null) {
      matchingExpression = isExpression;
    }

    InterfaceType requiredType = node.requiredType as InterfaceType;
    assert(requiredType.classNode == coreTypes.mapClass &&
        requiredType.typeArguments.length == 2);
    DartType valueType = requiredType.typeArguments[1];
    for (MapPatternEntry entry in node.entries) {
      if (entry is MapPatternRestEntry) continue;
      CacheableExpression keyExpression = matchingCache
          .createConstantExpression(entry.keyValue!, entry.keyType!,
              fileOffset: entry.key.fileOffset);
      CacheableExpression containsExpression =
          matchingCache.createContainsKeyExpression(
              typedMatchedExpression,
              keyExpression,
              new DelayedInstanceInvocation(
                  typedMatchedExpression,
                  node.containsKeyTarget,
                  node.containsKeyType!,
                  [keyExpression],
                  fileOffset: entry.fileOffset),
              fileOffset: entry.fileOffset);
      CacheableExpression valueExpression = matchingCache.createIndexExpression(
          typedMatchedExpression,
          keyExpression,
          new DelayedInstanceInvocation(typedMatchedExpression,
              node.indexGetTarget, node.indexGetType!, [keyExpression],
              fileOffset: entry.fileOffset),
          fileOffset: entry.fileOffset);
      if (evaluationMode == EvaluationMode.strong) {
        matchingExpression = DelayedAndExpression.merge(
            matchingExpression,
            new DelayedOrExpression(
                new DelayedNullCheckExpression(valueExpression,
                    fileOffset: entry.fileOffset),
                new DelayedAndExpression(
                    new DelayedIsExpression(
                        new FixedExpression(
                            createNullLiteral(fileOffset: entry.fileOffset),
                            const NullType()),
                        valueType,
                        fileOffset: entry.fileOffset),
                    containsExpression,
                    fileOffset: entry.fileOffset),
                fileOffset: entry.fileOffset),
            fileOffset: entry.fileOffset);
      } else {
        matchingExpression = DelayedAndExpression.merge(
            matchingExpression, containsExpression,
            fileOffset: entry.fileOffset);
      }
      valueExpression =
          new PromotedCacheableExpression(valueExpression, valueType);

      DelayedExpression subExpression =
          visitPattern(entry.value, valueExpression);
      if (!subExpression.uses(valueExpression)) {
        // Ensure that we perform the lookup even if we don't use the result.
        matchingExpression = DelayedAndExpression.merge(matchingExpression,
            new EffectExpression(valueExpression, subExpression),
            fileOffset: node.fileOffset);
      } else {
        matchingExpression = DelayedAndExpression.merge(
            matchingExpression, subExpression,
            fileOffset: node.fileOffset);
      }
    }
    return matchingExpression ??
        new BooleanExpression(true, fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitNamedPattern(
      NamedPattern node, CacheableExpression matchedExpression) {
    return visitPattern(node.pattern, matchedExpression);
  }

  @override
  DelayedExpression visitNullAssertPattern(
      NullAssertPattern node, CacheableExpression matchedExpression) {
    CacheableExpression nullAssertExpression =
        matchingCache.createNullAssertMatcher(matchedExpression,
            fileOffset: node.fileOffset);
    return new EffectExpression(
        nullAssertExpression, visitPattern(node.pattern, nullAssertExpression));
  }

  @override
  DelayedExpression visitNullCheckPattern(
      NullCheckPattern node, CacheableExpression matchedExpression) {
    CacheableExpression nullCheckExpression = matchingCache
        .createNullCheckMatcher(matchedExpression, fileOffset: node.fileOffset);
    return new DelayedConditionalExpression(
        nullCheckExpression,
        visitPattern(node.pattern, matchedExpression),
        new BooleanExpression(false, fileOffset: node.fileOffset),
        fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitObjectPattern(
      ObjectPattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedValueType!);

    DelayedExpression? matchingExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      matchingExpression = matchingCache.createIsExpression(
          matchedExpression, node.requiredType,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, node.requiredType);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    for (NamedPattern field in node.fields) {
      DelayedExpression expression;
      Member? staticTarget;
      List<DartType>? typeArguments;
      switch (field.accessKind) {
        case ObjectAccessKind.Object:
          expression = new DelayedInstanceGet(
              typedMatchedExpression, field.target!, field.resultType!,
              isObjectAccess: true, fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.Instance:
          expression = new DelayedInstanceGet(
              typedMatchedExpression, field.target!, field.resultType!,
              isObjectAccess: false, fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.Direct:
          expression = new DelayedAsExpression(
              typedMatchedExpression, field.resultType!,
              isUnchecked: true, fileOffset: field.fileOffset);
        case ObjectAccessKind.Extension:
        case ObjectAccessKind.ExtensionType:
          expression = new DelayedExtensionInvocation(field.target as Procedure,
              [typedMatchedExpression], field.typeArguments!, field.resultType!,
              fileOffset: field.fileOffset);
          staticTarget = field.target;
          typeArguments = field.typeArguments;
          break;
        case ObjectAccessKind.RecordNamed:
          expression = new DelayedRecordNameGet(
              typedMatchedExpression, field.recordType!, field.fieldName.text,
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.RecordIndexed:
          expression = new DelayedRecordIndexGet(
              typedMatchedExpression, field.recordType!, field.recordFieldIndex,
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.Dynamic:
          expression = new DelayedDynamicGet(typedMatchedExpression,
              field.fieldName, DynamicAccessKind.Dynamic, const DynamicType(),
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.Never:
          expression = new DelayedDynamicGet(
              typedMatchedExpression,
              field.fieldName,
              DynamicAccessKind.Never,
              const NeverType.nonNullable(),
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.Invalid:
          expression = new DelayedDynamicGet(typedMatchedExpression,
              field.fieldName, DynamicAccessKind.Invalid, const InvalidType(),
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.FunctionTearOff:
          expression = new DelayedFunctionTearOff(
              typedMatchedExpression, node.requiredType,
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.Error:
          expression = new FixedExpression(
              (field.pattern as InvalidPattern).invalidExpression,
              const InvalidType());
          break;
      }
      CacheableExpression objectExpression =
          matchingCache.createPropertyGetExpression(
              typedMatchedExpression, field.fieldName.text, expression,
              staticTarget: staticTarget,
              typeArguments: typeArguments,
              fileOffset: field.fileOffset);
      if (field.checkReturn) {
        objectExpression = new CovariantCheckCacheableExpression(
            objectExpression, field.resultType!,
            fileOffset: field.fileOffset);
      }

      DelayedExpression subExpression =
          visitPattern(field.pattern, objectExpression);
      if (!subExpression.uses(objectExpression)) {
        // Ensure that we perform the access even if we don't use the result.
        matchingExpression = DelayedAndExpression.merge(matchingExpression,
            new EffectExpression(objectExpression, subExpression),
            fileOffset: node.fileOffset);
      } else {
        matchingExpression = DelayedAndExpression.merge(
            matchingExpression, subExpression,
            fileOffset: node.fileOffset);
      }
    }
    return matchingExpression ??
        new BooleanExpression(true, fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitOrPattern(
      OrPattern node, CacheableExpression matchedExpression) {
    matchingCache.declareJointVariables(node.orPatternJointVariables,
        node.left.declaredVariables, node.right.declaredVariables);
    return new DelayedOrExpression(visitPattern(node.left, matchedExpression),
        visitPattern(node.right, matchedExpression),
        fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitRecordPattern(
      RecordPattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedValueType!);

    DelayedExpression? matchingExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      matchingExpression = matchingCache.createIsExpression(
          matchedExpression, node.requiredType!,
          fileOffset: node.fileOffset);
      typedMatchedExpression = new PromotedCacheableExpression(
          matchedExpression, node.requiredType!);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    int recordFieldIndex = 0;
    for (Pattern fieldPattern in node.patterns) {
      CacheableExpression fieldExpression;
      if (fieldPattern is NamedPattern) {
        fieldExpression = matchingCache.createPropertyGetExpression(
            typedMatchedExpression,
            fieldPattern.name,
            new DelayedRecordNameGet(
                typedMatchedExpression, node.lookupType!, fieldPattern.name,
                fileOffset: fieldPattern.fileOffset),
            fileOffset: fieldPattern.fileOffset);

        // [type] is computed by the CFE, so the absence of the named field is
        // an internal error, and we check the condition with an assert rather
        // than reporting a compile-time error.
        assert(node.requiredType!.named
            .any((named) => named.name == fieldPattern.name));
      } else {
        final int fieldIndex = recordFieldIndex;
        fieldExpression = matchingCache.createPropertyGetExpression(
            typedMatchedExpression,
            '\$${fieldIndex + 1}',
            new DelayedRecordIndexGet(
                typedMatchedExpression, node.lookupType!, fieldIndex,
                fileOffset: fieldPattern.fileOffset),
            fileOffset: fieldPattern.fileOffset);

        assert(recordFieldIndex < node.requiredType!.positional.length);

        recordFieldIndex++;
      }

      DelayedExpression fieldMatcher =
          visitPattern(fieldPattern, fieldExpression);
      matchingExpression = DelayedAndExpression.merge(
          matchingExpression, fieldMatcher,
          fileOffset: node.fileOffset);
    }

    return matchingExpression ??
        new BooleanExpression(true, fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitRelationalPattern(
      RelationalPattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedValueType!);

    CacheableExpression constant = matchingCache.createConstantExpression(
        node.expressionValue!, node.expressionType!,
        fileOffset: node.expression.fileOffset);

    switch (node.kind) {
      case RelationalPatternKind.equals:
      case RelationalPatternKind.notEquals:
        DelayedExpression expression = matchingCache.createEqualsExpression(
            matchedExpression,
            constant,
            new DelayedEqualsExpression(
                matchedExpression, constant, node.target!, node.functionType!,
                fileOffset: node.fileOffset),
            fileOffset: node.fileOffset);

        if (node.kind == RelationalPatternKind.notEquals) {
          expression = new DelayedNotExpression(expression);
        }
        return expression;
      case RelationalPatternKind.lessThan:
      case RelationalPatternKind.lessThanEqual:
      case RelationalPatternKind.greaterThan:
      case RelationalPatternKind.greaterThanEqual:
        DelayedExpression expression;
        Member? staticTarget;
        List<DartType>? typeArguments;
        switch (node.accessKind) {
          case RelationalAccessKind.Instance:
            FunctionType functionType = node.functionType!;
            DartType argumentType = functionType.positionalParameters.single;
            expression = new DelayedInstanceInvocation(
                matchedExpression,
                node.target!,
                functionType,
                [
                  new DelayedAsExpression(constant, argumentType,
                      isImplicit: true, fileOffset: node.fileOffset)
                ],
                fileOffset: node.fileOffset);

            break;
          case RelationalAccessKind.Static:
            FunctionType functionType = node.functionType!;
            DartType argumentType = functionType.positionalParameters[1];
            expression = new DelayedExtensionInvocation(
                node.target!,
                [
                  matchedExpression,
                  new DelayedAsExpression(constant, argumentType,
                      isImplicit: true, fileOffset: node.fileOffset)
                ],
                node.typeArguments!,
                functionType.returnType,
                fileOffset: node.fileOffset);
            staticTarget = node.target;
            typeArguments = node.typeArguments!;

            break;
          case RelationalAccessKind.Dynamic:
            expression = new DelayedDynamicInvocation(
                matchedExpression,
                node.name!,
                [constant],
                DynamicAccessKind.Dynamic,
                const DynamicType(),
                fileOffset: node.fileOffset);
            break;
          case RelationalAccessKind.Never:
            expression = new DelayedDynamicInvocation(
                matchedExpression,
                node.name!,
                [constant],
                DynamicAccessKind.Never,
                const NeverType.nonNullable(),
                fileOffset: node.fileOffset);
            break;
          case RelationalAccessKind.Invalid:
            expression = new DelayedDynamicInvocation(
                matchedExpression,
                node.name!,
                [constant],
                DynamicAccessKind.Invalid,
                const InvalidType(),
                fileOffset: node.fileOffset);
            break;
        }
        expression = new DelayedAsExpression(
            expression, coreTypes.boolNonNullableRawType,
            isImplicit: true, fileOffset: node.fileOffset);
        return matchingCache.createComparisonExpression(
            matchedExpression, node.name!.text, constant, expression,
            staticTarget: staticTarget,
            typeArguments: typeArguments,
            fileOffset: node.fileOffset);
    }
  }

  @override
  DelayedExpression visitRestPattern(
      RestPattern node, CacheableExpression matchedExpression) {
    if (node.subPattern != null) {
      return visitPattern(node.subPattern!, matchedExpression);
    }
    throw new UnsupportedError("RestPattern without subpattern.");
  }

  @override
  DelayedExpression visitVariablePattern(
      VariablePattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedValueType!);
    DelayedExpression? matchingExpression;
    if (node.type != null) {
      matchingExpression = new DelayedIsExpression(
          matchedExpression, node.type!,
          fileOffset: node.fileOffset);
    }
    VariableDeclaration target =
        matchingCache.getUnaliasedVariable(node.variable);
    target.isHoisted = true;
    CacheableExpression valueExpression =
        new PromotedCacheableExpression(matchedExpression, target.type);
    return DelayedAndExpression.merge(
        matchingExpression,
        new DelayedAssignment(
            matchingCache, target, target.type, valueExpression,
            hasEffect: false, fileOffset: node.fileOffset),
        fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitWildcardPattern(
      WildcardPattern node, CacheableExpression matchedExpression) {
    if (node.type != null) {
      return new DelayedIsExpression(matchedExpression, node.type!,
          fileOffset: node.fileOffset);
    } else {
      return new BooleanExpression(true, fileOffset: node.fileOffset);
    }
  }
}
