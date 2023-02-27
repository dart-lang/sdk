// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/delayed_expressions.dart';
import 'package:front_end/src/fasta/type_inference/matching_cache.dart';
import 'package:kernel/ast.dart';

import '../kernel/internal_ast.dart';
import '../names.dart';

/// Visitor that creates the [DelayedExpression] needed to match expressions,
/// using [MatchingCache] to create cacheable expressions.
class MatchingExpressionVisitor
    implements PatternVisitor1<DelayedExpression, CacheableExpression> {
  final MatchingCache matchingCache;

  MatchingExpressionVisitor(this.matchingCache);

  DelayedExpression visitPattern(
      Pattern node, CacheableExpression matchedExpression) {
    if (node.error != null) {
      return new FixedExpression(node.error!, const InvalidType());
    }
    return node.acceptPattern1(this, matchedExpression);
  }

  @override
  DelayedExpression defaultPattern(
      Pattern node, CacheableExpression matchedExpression) {
    throw new UnsupportedError(
        "Unexpected pattern $node (${node.runtimeType}).");
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
    matchedExpression = matchedExpression.promote(node.matchedType);

    CacheableExpression valueExpression;
    if (node.needsCheck) {
      valueExpression = new PromotedCacheableExpression(
          matchedExpression, node.variable.type);
    } else {
      valueExpression = matchedExpression;
    }
    return new EffectExpression(
        new VariableSetExpression(node.variable, valueExpression,
            allowFinalAssignment: true, fileOffset: node.fileOffset),
        new BooleanExpression(true, fileOffset: node.fileOffset));
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
        .createConstantExpression(node.expression, node.expressionType);
    return matchingCache.createEqualsExpression(
        constExpression,
        matchedExpression,
        new DelayedEqualsExpression(constExpression, matchedExpression,
            node.equalsTarget, node.equalsType,
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
    matchedExpression = matchedExpression.promote(node.matchedType);

    CacheableExpression? isExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      isExpression = matchingCache.createIsExpression(
          matchedExpression, node.listType,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, node.listType);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    CacheableExpression lengthGet = matchingCache.createPropertyGetExpression(
        typedMatchedExpression,
        lengthName.text,
        new DelayedInstanceGet(
            typedMatchedExpression, node.lengthTarget, node.lengthType,
            fileOffset: node.fileOffset),
        fileOffset: node.fileOffset);

    CacheableExpression lengthCheck;
    if (node.hasRestPattern) {
      CacheableExpression constExpression = matchingCache.createIntConstant(
          node.patterns.length - 1,
          fileOffset: node.fileOffset);

      lengthCheck = matchingCache.createComparisonExpression(
          lengthGet,
          greaterThanOrEqualsName.text,
          constExpression,
          new DelayedInstanceInvocation(lengthGet, node.lengthCheckTarget,
              node.lengthCheckType, [constExpression],
              fileOffset: node.fileOffset),
          fileOffset: node.fileOffset);
    } else {
      CacheableExpression constExpression = matchingCache
          .createIntConstant(node.patterns.length, fileOffset: node.fileOffset);

      lengthCheck = matchingCache.createEqualsExpression(
          lengthGet,
          constExpression,
          new DelayedEqualsExpression(lengthGet, constExpression,
              node.lengthCheckTarget, node.lengthCheckType,
              fileOffset: node.fileOffset),
          fileOffset: node.fileOffset);
    }

    DelayedExpression matchingExpression;
    if (isExpression != null) {
      matchingExpression = matchingCache.createAndExpression(
          isExpression, lengthCheck,
          fileOffset: node.fileOffset);
    } else {
      matchingExpression = lengthCheck;
    }

    bool hasSeenRestPattern = false;
    for (int i = 0; i < node.patterns.length; i++) {
      CacheableExpression elementExpression;
      if (node.patterns[i] is RestPattern) {
        hasSeenRestPattern = true;
        Pattern? subPattern = (node.patterns[i] as RestPattern).subPattern;
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
              node.sublistType,
              [
                new IntegerExpression(headSize, fileOffset: node.fileOffset),
                new DelayedInstanceInvocation(
                    lengthGet,
                    node.minusTarget,
                    node.minusType,
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
              node.sublistType,
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
                  node.indexGetType,
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
                  node.indexGetType,
                  [
                    new DelayedInstanceInvocation(
                        lengthGet,
                        node.minusTarget,
                        node.minusType,
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
          visitPattern(node.patterns[i], elementExpression);
      if (!elementMatcher.uses(elementExpression)) {
        // Ensure that we perform the lookup even if we don't use the result.
        matchingExpression = DelayedAndExpression.merge(matchingExpression,
            new EffectExpression(elementExpression, elementMatcher),
            fileOffset: node.fileOffset);
      } else {
        matchingExpression = DelayedAndExpression.merge(
            matchingExpression, elementMatcher,
            fileOffset: node.fileOffset);
      }
    }
    return matchingExpression;
  }

  @override
  DelayedExpression visitMapPattern(
      MapPattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedType);

    CacheableExpression? isExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      isExpression = matchingCache.createIsExpression(
          matchedExpression, node.mapType,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, node.mapType);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    CacheableExpression lengthGet = matchingCache.createPropertyGetExpression(
        typedMatchedExpression,
        lengthName.text,
        new DelayedInstanceGet(
            typedMatchedExpression, node.lengthTarget, node.lengthType,
            fileOffset: node.fileOffset),
        fileOffset: node.fileOffset);

    CacheableExpression lengthCheck;
    if (node.hasRestPattern) {
      CacheableExpression constExpression = matchingCache.createIntConstant(
          node.entries.length - 1,
          fileOffset: node.fileOffset);

      lengthCheck = matchingCache.createComparisonExpression(
          lengthGet,
          greaterThanOrEqualsName.text,
          constExpression,
          new DelayedInstanceInvocation(lengthGet, node.lengthCheckTarget,
              node.lengthCheckType, [constExpression],
              fileOffset: node.fileOffset),
          fileOffset: node.fileOffset);
    } else {
      CacheableExpression constExpression = matchingCache
          .createIntConstant(node.entries.length, fileOffset: node.fileOffset);

      lengthCheck = matchingCache.createEqualsExpression(
          lengthGet,
          constExpression,
          new DelayedEqualsExpression(lengthGet, constExpression,
              node.lengthCheckTarget, node.lengthCheckType,
              fileOffset: node.fileOffset),
          fileOffset: node.fileOffset);
    }

    DelayedExpression matchingExpression;
    if (isExpression != null) {
      matchingExpression = matchingCache.createAndExpression(
          isExpression, lengthCheck,
          fileOffset: node.fileOffset);
    } else {
      matchingExpression = lengthCheck;
    }

    for (MapPatternEntry entry in node.entries) {
      if (entry is MapPatternRestEntry) continue;
      ConstantPattern keyPattern = entry.key as ConstantPattern;
      CacheableExpression keyExpression =
          matchingCache.createConstantExpression(
              keyPattern.expression, keyPattern.expressionType);

      CacheableExpression containsExpression =
          matchingCache.createContainsKeyExpression(
              typedMatchedExpression,
              keyExpression,
              new DelayedInstanceInvocation(typedMatchedExpression,
                  node.containsKeyTarget, node.containsKeyType, [keyExpression],
                  fileOffset: node.fileOffset),
              fileOffset: entry.fileOffset);

      matchingExpression = DelayedAndExpression.merge(
          matchingExpression, containsExpression,
          fileOffset: node.fileOffset);

      CacheableExpression valueExpression = matchingCache.createIndexExpression(
          typedMatchedExpression,
          keyExpression,
          new DelayedInstanceInvocation(typedMatchedExpression,
              node.indexGetTarget, node.indexGetType, [keyExpression],
              fileOffset: node.fileOffset),
          fileOffset: entry.fileOffset);
      valueExpression = new PromotedCacheableExpression(
          valueExpression,
          // TODO(johnniwinther): Compute the value type during inference.
          node.valueType ?? const DynamicType());

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
    return matchingExpression;
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
    return new DelayedConditionExpression(
        nullCheckExpression,
        visitPattern(node.pattern, matchedExpression),
        new BooleanExpression(false, fileOffset: node.fileOffset),
        fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitObjectPattern(
      ObjectPattern node, CacheableExpression matchedExpression) {
    matchedExpression = matchedExpression.promote(node.matchedType);

    DelayedExpression? matchingExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      matchingExpression = matchingCache.createIsExpression(
          matchedExpression, node.objectType,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, node.objectType);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    for (NamedPattern field in node.fields) {
      DelayedExpression expression;
      Member? staticTarget;
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
        case ObjectAccessKind.Static:
          expression = new DelayedExtensionInvocation(
              field.target as Procedure,
              [typedMatchedExpression],
              field.typeArguments!,
              field.functionType!,
              fileOffset: field.fileOffset);
          staticTarget = field.target;
          break;
        case ObjectAccessKind.RecordNamed:
          expression = new DelayedRecordNameGet(
              typedMatchedExpression, field.recordType!, field.fieldName.text,
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.RecordIndexed:
          expression = new DelayedRecordIndexGet(typedMatchedExpression,
              field.recordType!, field.recordFieldIndex!,
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
              typedMatchedExpression, node.objectType,
              fileOffset: field.fileOffset);
          break;
        case ObjectAccessKind.Error:
          expression = new FixedExpression(field.error!, const InvalidType());
          break;
      }
      CacheableExpression objectExpression =
          matchingCache.createPropertyGetExpression(
              typedMatchedExpression, field.fieldName.text, expression,
              staticTarget: staticTarget, fileOffset: field.fileOffset);

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
    matchedExpression = matchedExpression.promote(node.matchedType);

    DelayedExpression? matchingExpression;
    CacheableExpression typedMatchedExpression;
    if (node.needsCheck) {
      matchingExpression = matchingCache.createIsExpression(
          matchedExpression, node.type,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, node.type);
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
                typedMatchedExpression, node.recordType, fieldPattern.name,
                fileOffset: fieldPattern.fileOffset),
            fileOffset: fieldPattern.fileOffset);

        // [type] is computed by the CFE, so the absence of the named field is
        // an internal error, and we check the condition with an assert rather
        // than reporting a compile-time error.
        assert(node.type.named.any((named) => named.name == fieldPattern.name));
      } else {
        final int fieldIndex = recordFieldIndex;
        fieldExpression = matchingCache.createPropertyGetExpression(
            typedMatchedExpression,
            '\$${fieldIndex + 1}',
            new DelayedRecordIndexGet(
                typedMatchedExpression, node.recordType, fieldIndex,
                fileOffset: fieldPattern.fileOffset),
            fileOffset: fieldPattern.fileOffset);

        assert(recordFieldIndex < node.type.positional.length);

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
    CacheableExpression constant = matchingCache.createConstantExpression(
        node.expression, node.expressionType);

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
        switch (node.accessKind) {
          case RelationAccessKind.Instance:
            expression = new DelayedInstanceInvocation(
                matchedExpression, node.target!, node.functionType!, [constant],
                fileOffset: node.fileOffset);
            break;
          case RelationAccessKind.Static:
            expression = new DelayedExtensionInvocation(
                node.target!,
                [matchedExpression, constant],
                node.typeArguments!,
                node.functionType!,
                fileOffset: node.fileOffset);
            staticTarget = node.target;
            break;
          case RelationAccessKind.Dynamic:
            expression = new DelayedDynamicInvocation(
                matchedExpression,
                node.name,
                [constant],
                DynamicAccessKind.Dynamic,
                const DynamicType(),
                fileOffset: node.fileOffset);
            break;
          case RelationAccessKind.Never:
            expression = new DelayedDynamicInvocation(
                matchedExpression,
                node.name,
                [constant],
                DynamicAccessKind.Never,
                const NeverType.nonNullable(),
                fileOffset: node.fileOffset);
            break;
          case RelationAccessKind.Invalid:
            expression = new DelayedDynamicInvocation(
                matchedExpression,
                node.name,
                [constant],
                DynamicAccessKind.Invalid,
                const InvalidType(),
                fileOffset: node.fileOffset);
            break;
          case RelationAccessKind.Error:
            expression = new FixedExpression(node.error!, const InvalidType());
            break;
        }
        return matchingCache.createComparisonExpression(
            matchedExpression, node.name.text, constant, expression,
            staticTarget: staticTarget, fileOffset: node.fileOffset);
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
    DartType matchedType = node.matchedType;
    matchedExpression = matchedExpression.promote(matchedType);
    DelayedExpression? matchingExpression;
    if (node.type != null) {
      matchingExpression = new DelayedIsExpression(
          matchedExpression, node.type!,
          fileOffset: node.fileOffset);
    }
    VariableDeclaration target =
        matchingCache.getUnaliasedVariable(node.variable);
    CacheableExpression valueExpression =
        new PromotedCacheableExpression(matchedExpression, target.type);
    return DelayedAndExpression.merge(
        matchingExpression,
        new EffectExpression(
            new VariableSetExpression(target, valueExpression,
                allowFinalAssignment: true, fileOffset: node.fileOffset),
            new BooleanExpression(true, fileOffset: node.fileOffset)),
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
