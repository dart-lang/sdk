// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/problems.dart';
import 'package:front_end/src/fasta/type_inference/delayed_expressions.dart';
import 'package:front_end/src/fasta/type_inference/matching_cache.dart';
import 'package:kernel/ast.dart';

import '../fasta_codes.dart';
import '../kernel/internal_ast.dart';
import '../names.dart';
import 'inference_visitor_base.dart';
import 'object_access_target.dart';

/// Visitor that creates the [DelayedExpression] needed to match expressions,
/// using [MatchingCache] to create cacheable expressions.
class MatchingExpressionVisitor
    implements PatternVisitor1<DelayedExpression, CacheableExpression> {
  final InferenceVisitorBase base;
  final MatchingCache matchingCache;

  MatchingExpressionVisitor(this.base, this.matchingCache);

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
    unsupported("MatchingExpressionVisitor.defaultPattern", node.fileOffset,
        base.helper.uri);
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
    DartType matchedType = matchedExpression.getType(base);
    CacheableExpression valueExpression;
    if (!base.isAssignable(matchedType, node.variable.type) ||
        matchedType is DynamicType) {
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
        constExpression, matchedExpression,
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
    DartType matchedType = matchedExpression.getType(base);
    DartType typeArgument = node.typeArgument ?? const DynamicType();
    DartType targetListType = new InterfaceType(base.coreTypes.listClass,
        Nullability.nonNullable, <DartType>[typeArgument]);

    bool typeCheckForTargetListNeeded =
        !base.isAssignable(targetListType, matchedType) ||
            matchedType is DynamicType;

    CacheableExpression? isExpression;
    CacheableExpression typedMatchedExpression;
    if (typeCheckForTargetListNeeded) {
      isExpression = matchingCache.createIsExpression(
          matchedExpression, targetListType,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, targetListType);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    ObjectAccessTarget lengthTarget = base.findInterfaceMember(
        targetListType, lengthName, node.fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.getterInvocation);

    CacheableExpression lengthGet = matchingCache.createPropertyGetExpression(
        typedMatchedExpression, lengthName, lengthTarget,
        fileOffset: node.fileOffset);

    CacheableExpression lengthCheck;
    bool hasRestPattern = false;
    for (Pattern pattern in node.patterns) {
      if (pattern is RestPattern) {
        hasRestPattern = true;
        break;
      }
    }
    if (hasRestPattern) {
      lengthCheck = matchingCache.createComparisonExpression(
          lengthGet,
          greaterThanOrEqualsName,
          matchingCache.createIntConstant(node.patterns.length - 1,
              fileOffset: node.fileOffset),
          fileOffset: node.fileOffset);
    } else {
      lengthCheck = matchingCache.createEqualsExpression(
          lengthGet,
          matchingCache.createIntConstant(node.patterns.length,
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
        elementExpression = matchingCache.createSublistExpression(
            typedMatchedExpression,
            lengthGet,
            i,
            node.patterns.length - nextIndex,
            fileOffset: node.fileOffset);
      } else {
        if (!hasSeenRestPattern) {
          elementExpression = matchingCache.createHeadIndexExpression(
              typedMatchedExpression, i,
              fileOffset: node.fileOffset);
        } else {
          elementExpression = matchingCache.createTailIndexExpression(
              typedMatchedExpression, lengthGet, node.patterns.length - i,
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
    DartType matchedType = matchedExpression.getType(base);
    DartType keyType = node.keyType ?? const DynamicType();
    DartType valueType = node.valueType ?? const DynamicType();
    DartType targetMapType = new InterfaceType(
        base.coreTypes.mapClass, Nullability.nonNullable, [keyType, valueType]);

    bool typeCheckForTargetMapNeeded =
        !base.isAssignable(targetMapType, matchedType) ||
            matchedType is DynamicType;

    CacheableExpression? isExpression;
    CacheableExpression typedMatchedExpression;
    if (typeCheckForTargetMapNeeded) {
      isExpression = matchingCache.createIsExpression(
          matchedExpression, targetMapType,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, targetMapType);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    ObjectAccessTarget lengthTarget = base.findInterfaceMember(
        targetMapType, lengthName, node.fileOffset,
        includeExtensionMethods: true,
        callSiteAccessKind: CallSiteAccessKind.getterInvocation);

    CacheableExpression lengthGet = matchingCache.createPropertyGetExpression(
        typedMatchedExpression, lengthName, lengthTarget,
        fileOffset: node.fileOffset);

    CacheableExpression lengthCheck;
    // In map patterns the rest pattern can appear only in the end.
    bool hasRestPattern = node.entries.isNotEmpty &&
        identical(node.entries.last, restMapPatternEntry);
    if (hasRestPattern) {
      lengthCheck = matchingCache.createComparisonExpression(
          lengthGet,
          greaterThanOrEqualsName,
          matchingCache.createIntConstant(node.entries.length - 1,
              fileOffset: node.fileOffset),
          fileOffset: node.fileOffset);
    } else {
      lengthCheck = matchingCache.createEqualsExpression(
          lengthGet,
          matchingCache.createIntConstant(node.entries.length,
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
      if (identical(entry, restMapPatternEntry)) continue;
      ConstantPattern keyPattern = entry.key as ConstantPattern;
      CacheableExpression keyExpression =
          matchingCache.createConstantExpression(
              keyPattern.expression, keyPattern.expressionType);
      CacheableExpression containsExpression = matchingCache
          .createContainsKeyExpression(typedMatchedExpression, keyExpression,
              fileOffset: entry.fileOffset);
      matchingExpression = DelayedAndExpression.merge(
          matchingExpression, containsExpression,
          fileOffset: node.fileOffset);

      ObjectAccessTarget invokeTarget = base.findInterfaceMember(
          targetMapType, indexGetName, node.fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);

      CacheableExpression valueExpression = matchingCache.createIndexExpression(
          typedMatchedExpression, keyExpression, invokeTarget,
          fileOffset: entry.fileOffset);
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
    DartType matchedType = matchedExpression.getType(base);
    DartType targetObjectType = node.type;

    bool typeCheckForTargetNeeded =
        !base.isAssignable(targetObjectType, matchedType) ||
            matchedType is DynamicType;

    DelayedExpression? matchingExpression;
    CacheableExpression typedMatchedExpression;
    if (typeCheckForTargetNeeded) {
      matchingExpression = matchingCache.createIsExpression(
          matchedExpression, targetObjectType,
          fileOffset: node.fileOffset);
      typedMatchedExpression =
          new PromotedCacheableExpression(matchedExpression, targetObjectType);
    } else {
      typedMatchedExpression = matchedExpression;
    }

    for (NamedPattern field in node.fields) {
      String? fieldNameString;
      if (field.name.isNotEmpty) {
        fieldNameString = field.name;
      } else {
        // The name is defined by the nested variable pattern.
        Pattern nestedPattern = field.pattern;
        if (nestedPattern is VariablePattern) {
          fieldNameString = nestedPattern.name;
        }
      }

      if (fieldNameString != null) {
        Name fieldName = new Name(fieldNameString);

        ObjectAccessTarget fieldTarget = base.findInterfaceMember(
            targetObjectType, fieldName, node.fileOffset,
            includeExtensionMethods: true,
            callSiteAccessKind: CallSiteAccessKind.getterInvocation);

        CacheableExpression objectExpression =
            matchingCache.createPropertyGetExpression(
                typedMatchedExpression, fieldName, fieldTarget,
                fileOffset: node.fileOffset);
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
      } else {
        matchingExpression = DelayedAndExpression.merge(
            matchingExpression,
            new FixedExpression(
                base.helper.buildProblem(
                    messageUnspecifiedGetterNameInObjectPattern,
                    node.fileOffset,
                    noLength),
                const InvalidType()),
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
    DartType matchedType = matchedExpression.getType(base);
    bool typeCheckNeeded = !base.isAssignable(node.type, matchedType) ||
        matchedType is DynamicType;

    DelayedExpression? matchingExpression;
    CacheableExpression typedMatchedExpression;
    if (typeCheckNeeded) {
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
        Name fieldName =
            new Name(fieldPattern.name, base.libraryBuilder.library);

        ObjectAccessTarget fieldTarget = base.findInterfaceMember(
            node.type, fieldName, node.fileOffset,
            includeExtensionMethods: true,
            callSiteAccessKind: CallSiteAccessKind.getterInvocation);

        fieldExpression = matchingCache.createPropertyGetExpression(
            typedMatchedExpression, fieldName, fieldTarget,
            fileOffset: fieldPattern.fileOffset);

        // [type] is computed by the CFE, so the absence of the named field is
        // an internal error, and we check the condition with an assert rather
        // than reporting a compile-time error.
        assert(node.type.named.any((named) => named.name == fieldPattern.name));
      } else {
        Name fieldName =
            new Name('\$${recordFieldIndex + 1}', base.libraryBuilder.library);

        ObjectAccessTarget fieldTarget = base.findInterfaceMember(
            node.type, fieldName, node.fileOffset,
            includeExtensionMethods: true,
            callSiteAccessKind: CallSiteAccessKind.getterInvocation);

        fieldExpression = matchingCache.createPropertyGetExpression(
            typedMatchedExpression, fieldName, fieldTarget,
            fileOffset: fieldPattern.fileOffset);

        // [type] is computed by the CFE, so the field index out of range is an
        // internal error, and we check the condition with an assert rather than
        // reporting a compile-time error.
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
    Name name;
    switch (node.kind) {
      case RelationalPatternKind.equals:
      case RelationalPatternKind.notEquals:
        DelayedExpression expression = matchingCache.createEqualsExpression(
            matchedExpression, constant,
            fileOffset: node.fileOffset);
        if (node.kind == RelationalPatternKind.notEquals) {
          expression = new DelayedNotExpression(expression);
        }
        return expression;
      case RelationalPatternKind.lessThan:
        name = lessThanName;
        break;
      case RelationalPatternKind.lessThanEqual:
        name = lessThanOrEqualsName;
        break;
      case RelationalPatternKind.greaterThan:
        name = greaterThanName;
        break;
      case RelationalPatternKind.greaterThanEqual:
        name = greaterThanOrEqualsName;
        break;
    }
    return matchingCache.createComparisonExpression(
        matchedExpression, name, constant,
        fileOffset: node.fileOffset);
  }

  @override
  DelayedExpression visitRestPattern(
      RestPattern node, CacheableExpression matchedExpression) {
    if (node.subPattern != null) {
      return visitPattern(node.subPattern!, matchedExpression);
    }
    return unsupported("RestPattern.createMatchingExpression", node.fileOffset,
        base.helper.uri);
  }

  @override
  DelayedExpression visitVariablePattern(
      VariablePattern node, CacheableExpression matchedExpression) {
    DartType matchedType = matchedExpression.getType(base);
    DelayedExpression? matchingExpression;
    if (node.type != null) {
      matchingExpression = new DelayedIsExpression(
          matchedExpression, node.type!,
          fileOffset: node.fileOffset);
    }
    VariableDeclaration target =
        matchingCache.getUnaliasedVariable(node.variable);
    CacheableExpression valueExpression;
    if (!base.isAssignable(matchedType, target.type) ||
        matchedType is DynamicType) {
      valueExpression =
          new PromotedCacheableExpression(matchedExpression, target.type);
    } else {
      valueExpression = matchedExpression;
    }
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
