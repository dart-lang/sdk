// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

import '../names.dart';
import '../type_inference/external_ast_helper.dart';
import '../type_inference/inference_visitor_base.dart';
import 'delayed_expressions.dart';
import 'object_access_target.dart';
import 'type_schema.dart';

/// Cache used to create a set of pattern matching expressions.
///
/// A single cache is used for creating all pattern matches within a single
/// [PatternSwitchStatement], [SwitchExpression], [IfCaseStatement],
/// [PatternVariableDeclaration] and [PatternAssignment].
class MatchingCache {
  /// Index used to create unique variable names for synthesized variables.
  ///
  /// Currently the VM and dart2js need a non-null name for variables that are
  /// captured within local functions. Depending on caching encoding this can
  /// occur for most variable, so the matching cache conservatively assigns
  /// names to all variables.
  int _cachedExpressionIndex = 0;

  /// Used together with [_cachedExpressionIndex] to create unique indices.
  // TODO(johnniwinther): Can we avoid the need for this?
  final int _matchingCacheIndex;

  final InferenceVisitorBase _base;

  /// If `true`, late variables are lowered into an isSet variable, a caching
  /// variable and local function for accessing and initializing the variable.
  final bool useLowering;

  /// If `true` the encoding will use descriptive names and print statements
  /// in the late lowering.
  final bool useVerboseEncodingForDebugging = false;

  /// If `true`, cacheable are cache even when caching is not required.
  final bool eagerCaching = false;

  /// If `true`, the declarations created for the cached expressions have been
  /// finalized, and no new cached expressions can be created.
  bool _isClosed = false;

  /// The declarations need for the cached expressions.
  List<Statement> _declarations = [];

  /// Map for the known cached keys and their corresponding expressions.
  Map<CacheKey, CacheableExpression> _cache = {};

  /// Cache for constant expressions for fixed integer values.
  Map<int, CacheableExpression> _intConstantMap = {};

  /// Map for variable declarations to their aliases.
  ///
  /// This is used for using joint variables instead of the declared variables
  /// for instance in or patterns:
  ///
  ///   if (o case [int a, _] || [_, int a]) { ... }
  ///
  /// where a joint variable is used instead of the two declared 'a' variables.
  Map<VariableDeclaration, VariableDeclaration> _variableAliases = {};

  MatchingCache(this._matchingCacheIndex, this._base)
      : useLowering = _base.libraryBuilder.loader.target.backendTarget
            .isLateLocalLoweringEnabled(
                hasInitializer: true,
                isFinal: true,
                isPotentiallyNullable: true);

  /// Declares that [jointVariables] should be used as aliases of the variables
  /// of the same name in [variables1] and [variables2].
  ///
  /// This is used for instance in or patterns:
  ///
  ///   if (o case [int a, _] || [_, int a]) { ... }
  ///
  /// where a joint variable is used instead of the two declared 'a' variables.
  void declareJointVariables(
      List<VariableDeclaration> jointVariables,
      List<VariableDeclaration> variables1,
      List<VariableDeclaration> variables2) {
    Map<String, VariableDeclaration> jointVariablesMap = {};
    for (VariableDeclaration variable in jointVariables) {
      jointVariablesMap[variable.name!] = variable;
    }
    for (VariableDeclaration variable in variables1) {
      VariableDeclaration? jointVariable = jointVariablesMap[variable.name!];
      if (jointVariable != null) {
        _variableAliases[variable] = jointVariable;
      } else {
        // Error case. This variable is only declared one of the branches and
        // therefore not joint. Include the variable in the declarations.
        registerDeclaration(variable);
      }
    }
    for (VariableDeclaration variable in variables2) {
      VariableDeclaration? jointVariable = jointVariablesMap[variable.name!];
      if (jointVariable != null) {
        _variableAliases[variable] = jointVariable;
      } else {
        // Error case. This variable is only declared one of the branches and
        // therefore not joint. Include the variable in the declarations.
        registerDeclaration(variable);
      }
    }
  }

  /// Returns the unaliased variable for [variable] or [variable] itself, if it
  /// isn't aliased.
  ///
  /// This is used for instance in or patterns:
  ///
  ///   if (o case [int a, _] || [_, int a]) { ... }
  ///
  /// where a joint variable is the unaliased variable for  of the two
  /// declared 'a' variables.
  VariableDeclaration getUnaliasedVariable(VariableDeclaration variable) {
    VariableDeclaration? unalias = _variableAliases[variable];
    if (unalias != null) {
      // Joint variables might themselves be joint, for instance in nested
      // or patterns.
      unalias = getUnaliasedVariable(unalias);
    }
    return unalias ?? variable;
  }

  /// Creates a cacheable expression for the [cacheKey] using [expression] as
  /// the definition of the expression value.
  ///
  /// If [isLate] is `false`, a variable for the value is always created.
  /// Otherwise a late variable (or a lowering of a late variable) is required
  /// if [requiresCaching] `true` and the expression is used more than once.
  ///
  /// If [isConst] is `true`, a const variable is created. This cannot be used
  /// together with [isLate] set to `true`.
  CacheableExpression _createCacheableExpression(
      CacheKey cacheKey, DelayedExpression expression,
      {bool isLate = true,
      bool isConst = false,
      required int fileOffset,
      required bool requiresCaching}) {
    assert(!(isLate && isConst), "Cannot create a late const variable.");
    return _cache[cacheKey] = new CacheableExpression(
        cacheKey,
        this,
        expression,
        '${useVerboseEncodingForDebugging ? '${cacheKey.name}' : ''}'
        '#${this._matchingCacheIndex}'
        '#${_cachedExpressionIndex++}',
        isLate: isLate,
        isConst: isConst,
        requiresCaching: requiresCaching,
        fileOffset: fileOffset);
  }

  /// Registers that the variable or local function [declaration] is need for
  /// the cached expressions.
  void registerDeclaration(Statement declaration) {
    assert(!_isClosed);
    _declarations.add(declaration);
  }

  /// Returns the variable or local function declarations needed for the
  /// cached expressions.
  ///
  /// Once called, the matching cache is closed and no new cacheable expressions
  /// can be created.
  Iterable<Statement> get declarations {
    _isClosed = true;
    return _declarations;
  }

  /// Creates the cacheable expression for the scrutinee [expression] of the
  /// [expressionType]. For instance `o` in
  ///
  ///     if (o case <pattern>) { ... }
  ///     switch (o) {  case <pattern>: ... }
  ///     switch (o) {  <pattern> => ... }
  ///     var <pattern> = o;
  ///     <pattern> = o;
  ///
  // TODO(johnniwinther): Support _not_ caching the expression if it is a pure
  // expression like `this`.
  CacheableExpression createRootExpression(
      Expression expression, DartType expressionType) {
    CacheKey cacheKey = new ExpressionKey(expression);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(
          cacheKey, new FixedExpression(expression, expressionType),
          isLate: false,
          requiresCaching: true,
          fileOffset: expression.fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression for integer constant [value].
  CacheableExpression createIntConstant(int value, {required int fileOffset}) {
    CacheableExpression? result = _intConstantMap[value];
    if (result == null) {
      result = _intConstantMap[value] = createConstantExpression(
          createIntLiteral(value, fileOffset: fileOffset),
          _base.coreTypes.intNonNullableRawType);
    }
    return result;
  }

  /// Creates a cacheable expression for the constant [expression] of the
  /// given [expressionType].
  // TODO(johnniwinther): Support using constant value identity to determine
  // the cache key.
  CacheableExpression createConstantExpression(
      Expression expression, DartType expressionType) {
    assert(isKnown(expressionType));
    CacheKey cacheKey = new ExpressionKey(expression);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(
          cacheKey, new FixedExpression(expression, expressionType),
          isLate: false,
          isConst: true,
          requiresCaching: true,
          fileOffset: expression.fileOffset);
    }
    return result;
  }

  /// Creates a cacheable as expression of the [operand] against [type].
  CacheableExpression createAsExpression(
      CacheableExpression operand, DartType type,
      {required int fileOffset}) {
    CacheKey cacheKey = new AsKey(operand.cacheKey, type);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(cacheKey,
          new DelayedAsExpression(operand, type, fileOffset: fileOffset),
          requiresCaching: false, fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression for a null assert pattern, which asserts
  /// that [operand] is non-null.
  CacheableExpression createNullAssertMatcher(CacheableExpression operand,
      {required int fileOffset}) {
    CacheKey cacheKey = new NullAssertKey(operand.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(cacheKey,
          new DelayedNullAssertExpression(operand, fileOffset: fileOffset),
          requiresCaching: false, fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression for a null check pattern, which matches if
  /// [operand] is non-null.
  CacheableExpression createNullCheckMatcher(CacheableExpression operand,
      {required int fileOffset}) {
    CacheKey cacheKey = new NullCheckKey(operand.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(cacheKey,
          new DelayedNullCheckExpression(operand, fileOffset: fileOffset),
          requiresCaching: false, fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression for an is test on [operand] against [type].
  CacheableExpression createIsExpression(
      CacheableExpression operand, DartType type,
      {required int fileOffset}) {
    CacheKey cacheKey = new IsKey(operand.cacheKey, type);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(cacheKey,
          new DelayedIsExpression(operand, type, fileOffset: fileOffset),
          requiresCaching: false, fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression for accessing the [propertyName] property
  /// on [receiver] of type [receiverType].
  CacheableExpression createPropertyGetExpression(
      DartType receiverType, CacheableExpression receiver, Name propertyName,
      {required int fileOffset}) {
    // TODO(johnniwinther): Support extension access.
    CacheKey cacheKey = new PropertyGetKey(receiver.cacheKey, propertyName);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      ObjectAccessTarget readTarget = _base.findInterfaceMember(
          receiverType, propertyName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.getterInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedPropertyGetExpression(
              receiverType, receiver, readTarget, propertyName,
              fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression that compares [left] of type [leftType]
  /// against [right] with the [operatorName] operator.
  CacheableExpression createComparisonExpression(DartType leftType,
      CacheableExpression left, Name operatorName, CacheableExpression right,
      {required int fileOffset}) {
    String operator = operatorName.text;
    CacheKey cacheKey =
        new ComparisonKey(left.cacheKey, operator, right.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      ObjectAccessTarget invokeTarget = _base.findInterfaceMember(
          leftType, operatorName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedInvokeExpression(
              leftType, left, invokeTarget, operatorName, [right],
              fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression that checks [left] of type [leftType]
  /// for equality against [right]. If [isNot] is `true`, the result is negated.
  CacheableExpression createEqualsExpression(
      DartType leftType, CacheableExpression left, CacheableExpression right,
      {bool isNot = false, required int fileOffset}) {
    String operator = isNot ? '!=' : '==';
    CacheKey cacheKey =
        new ComparisonKey(left.cacheKey, operator, right.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      ObjectAccessTarget invokeTarget = _base.findInterfaceMember(
          leftType, equalsName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedEqualsExpression(leftType, left, invokeTarget, right,
              isNot: isNot, fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable lazy-and expression of [left] and [right].
  CacheableExpression createAndExpression(
      CacheableExpression left, CacheableExpression right,
      {required int fileOffset}) {
    CacheKey cacheKey = new AndKey(left.cacheKey, right.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(cacheKey,
          new DelayedAndExpression(left, right, fileOffset: fileOffset),
          requiresCaching: false, fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable lazy-or expression of [left] and [right].
  CacheableExpression createOrExpression(InferenceVisitorBase base,
      CacheableExpression left, CacheableExpression right,
      {required int fileOffset}) {
    CacheKey cacheKey = new OrKey(left.cacheKey, right.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      result = _createCacheableExpression(cacheKey,
          new DelayedOrExpression(left, right, fileOffset: fileOffset),
          requiresCaching: false, fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression that accesses the `List.[]` operator on
  /// [receiver] of type [receiverType] with index [headSize].
  ///
  /// This is used access the first elements in a list.
  CacheableExpression createHeadIndexExpression(
      DartType receiverType, CacheableExpression receiver, int headSize,
      {required int fileOffset}) {
    CacheKey cacheKey = new HeadIndexKey(receiver.cacheKey, headSize);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      ObjectAccessTarget invokeTarget = _base.findInterfaceMember(
          receiverType, indexGetName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedInvokeExpression(
              receiverType,
              receiver,
              invokeTarget,
              indexGetName,
              [new IntegerExpression(headSize, fileOffset: fileOffset)],
              fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression that accesses the `List.[]` operator on
  /// [receiver] of type [receiverType] with an index that is [lengthGet], the
  /// `.length` on the [receiver], minus [tailSize].
  ///
  /// This is used access the last elements in a list.
  CacheableExpression createTailIndexExpression(DartType receiverType,
      CacheableExpression receiver, CacheableExpression length, int tailSize,
      {required int fileOffset}) {
    CacheKey cacheKey = new TailIndexKey(receiver.cacheKey, tailSize);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      ObjectAccessTarget invokeTarget = _base.findInterfaceMember(
          receiverType, indexGetName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      ObjectAccessTarget minusTarget = _base.findInterfaceMember(
          length.getType(_base), minusName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedInvokeExpression(
              receiverType,
              receiver,
              invokeTarget,
              indexGetName,
              [
                new DelayedInvokeExpression(
                    length.getType(_base),
                    length,
                    minusTarget,
                    minusName,
                    [new IntegerExpression(tailSize, fileOffset: fileOffset)],
                    fileOffset: fileOffset)
              ],
              fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression that calls the `List.sublist` method on
  /// [receiver] of type [receiverType] with start index [headIndex] and end
  /// index that is [lengthGet], the `.length` on the [receiver], minus
  /// [tailSize].
  CacheableExpression createSublistExpression(
      DartType receiverType,
      CacheableExpression receiver,
      CacheableExpression length,
      int headSize,
      int tailSize,
      {required int fileOffset}) {
    CacheKey cacheKey = new SublistKey(receiver.cacheKey, headSize, tailSize);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      DelayedExpression startIndex =
          new IntegerExpression(headSize, fileOffset: fileOffset);
      DelayedExpression? endIndex;
      if (tailSize > 0) {
        ObjectAccessTarget minusTarget = _base.findInterfaceMember(
            length.getType(_base), minusName, fileOffset,
            includeExtensionMethods: true,
            callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
        endIndex = new DelayedInvokeExpression(
            length.getType(_base),
            length,
            minusTarget,
            minusName,
            [new IntegerExpression(tailSize, fileOffset: fileOffset)],
            fileOffset: fileOffset);
      }
      ObjectAccessTarget invokeTarget = _base.findInterfaceMember(
          receiverType, sublistName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedInvokeExpression(receiverType, receiver, invokeTarget,
              sublistName, [startIndex, if (endIndex != null) endIndex],
              fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression that calls the `Map.containsKey` on
  /// [receiver] of type [receiverType] with the given [key].
  CacheableExpression createContainsKeyExpression(DartType receiverType,
      CacheableExpression receiver, CacheableExpression key,
      {required int fileOffset}) {
    CacheKey cacheKey = new ContainsKeyKey(receiver.cacheKey, key.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      ObjectAccessTarget invokeTarget = _base.findInterfaceMember(
          receiverType, containsKeyName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.methodInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedInvokeExpression(
              receiverType, receiver, invokeTarget, containsKeyName, [key],
              fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }

  /// Creates a cacheable expression that access the `Map.[]` on [receiver] of
  /// type [receiverType] with the given [key].
  CacheableExpression createIndexExpression(DartType receiverType,
      CacheableExpression receiver, CacheableExpression key,
      {required int fileOffset}) {
    CacheKey cacheKey = new IndexKey(receiver.cacheKey, key.cacheKey);
    CacheableExpression? result = _cache[cacheKey];
    if (result == null) {
      ObjectAccessTarget invokeTarget = _base.findInterfaceMember(
          receiverType, indexGetName, fileOffset,
          includeExtensionMethods: true,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      result = _createCacheableExpression(
          cacheKey,
          new DelayedInvokeExpression(
              receiverType, receiver, invokeTarget, indexGetName, [key],
              fileOffset: fileOffset),
          requiresCaching: true,
          fileOffset: fileOffset);
    }
    return result;
  }
}

/// A key that identifies the value computed by a [CacheableExpression].
///
/// This is related to the "invocation key" concept found in the patterns
/// specification, but doesn't fully match, since it always for caching of
/// more properties that necessary but also doesn't handle the constant value
/// identity of the constant expressions.
abstract class CacheKey {
  /// Descriptor name of the key used for verbose encoding of cached variables.
  String get name;
}

/// A key that is defined by the [expression] node that created it.
// TODO(johnniwinther): Handle constant expressions differently.
class ExpressionKey extends CacheKey {
  final Expression expression;

  ExpressionKey(this.expression);

  @override
  String get name => '${expression.toText(defaultAstTextStrategy)}';

  @override
  int get hashCode => expression.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpressionKey && expression == other.expression;
  }
}

/// A key for an is-test, defined by the [receiver] key of the [type].
class IsKey extends CacheKey {
  final CacheKey receiver;
  final DartType type;

  IsKey(this.receiver, this.type);

  @override
  String get name =>
      '${receiver.name}_is_${type.toText(defaultAstTextStrategy)}';

  @override
  int get hashCode => Object.hash(receiver, type);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IsKey && receiver == other.receiver && type == other.type;
  }
}

/// A key for an as-cast, defined by the [receiver] key of the [type].
class AsKey extends CacheKey {
  final CacheKey receiver;
  final DartType type;

  AsKey(this.receiver, this.type);

  @override
  String get name => '${receiver.name}_as_${type}';

  @override
  int get hashCode => Object.hash(receiver, type);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsKey && receiver == other.receiver && type == other.type;
  }
}

/// A key for a null check, defined by the [operand] key.
class NullCheckKey extends CacheKey {
  final CacheKey operand;

  NullCheckKey(this.operand);

  @override
  String get name => '${operand.name}?';

  @override
  int get hashCode => operand.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NullCheckKey && operand == other.operand;
  }
}

/// A key for a null check, defined by the [operand] key.
class NullAssertKey extends CacheKey {
  final CacheKey operand;

  NullAssertKey(this.operand);

  @override
  String get name => '${operand.name}!';

  @override
  int get hashCode => operand.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NullAssertKey && operand == other.operand;
  }
}

/// A key for a property access, defined by the [receiver] key and the
/// [propertyName].
class PropertyGetKey extends CacheKey {
  final CacheKey receiver;
  final Name propertyName;

  PropertyGetKey(this.receiver, this.propertyName);

  @override
  String get name => '${receiver.name}_${propertyName.text}';

  @override
  int get hashCode => Object.hash(receiver, propertyName);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyGetKey &&
        receiver == other.receiver &&
        propertyName == other.propertyName;
  }
}

/// A key for a binary comparison, defined by the [left] key and [right] key and
/// the [operator].
class ComparisonKey extends CacheKey {
  final CacheKey left;
  final String operator;
  final CacheKey right;

  ComparisonKey(this.left, this.operator, this.right);

  @override
  String get name => '${left.name}_${operator}_${right.name}';

  @override
  int get hashCode => Object.hash(left, operator, right);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComparisonKey &&
        left == other.left &&
        operator == other.operator &&
        right == other.right;
  }
}

/// A key for a lazy-and, defined by the [left] key and [right] key.
class AndKey extends CacheKey {
  final CacheKey left;
  final CacheKey right;

  AndKey(this.left, this.right);

  @override
  String get name => '${left.name}_&&_${right.name}';

  @override
  int get hashCode => Object.hash(left, right);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AndKey && left == other.left && right == other.right;
  }
}

/// A key for a lazy-or, defined by the [left] key and [right] key.
class OrKey extends CacheKey {
  final CacheKey left;
  final CacheKey right;

  OrKey(this.left, this.right);

  @override
  String get name => '${left.name}_||_${right.name}';

  @override
  int get hashCode => Object.hash(left, right);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrKey && left == other.left && right == other.right;
  }
}

/// A key for a list index lookup, defined by the [receiver] key and [headSize].
// TODO(johnniwinther): Merge this with [IndexKey].
class HeadIndexKey extends CacheKey {
  final CacheKey receiver;
  final int headSize;

  HeadIndexKey(this.receiver, this.headSize);

  @override
  String get name => '${receiver.name}[${headSize}]';

  @override
  int get hashCode => Object.hash(receiver, headSize);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HeadIndexKey &&
        receiver == other.receiver &&
        headSize == other.headSize;
  }
}

/// A key for a list index lookup from the end of the list, defined by the
/// [receiver] key and [tailSize].
class TailIndexKey extends CacheKey {
  final CacheKey receiver;
  final int tailSize;

  TailIndexKey(this.receiver, this.tailSize);

  @override
  String get name => '${receiver.name}[-${tailSize}]';

  @override
  int get hashCode => Object.hash(receiver, tailSize);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TailIndexKey &&
        receiver == other.receiver &&
        tailSize == other.tailSize;
  }
}

/// A key for a `sublist` access of a list, defined by the [receiver] key,
/// [headSize] and [tailSize].
class SublistKey extends CacheKey {
  final CacheKey receiver;
  final int headSize;
  final int tailSize;

  SublistKey(this.receiver, this.headSize, this.tailSize);

  @override
  String get name => '${receiver.name}[${headSize};${tailSize}]';

  @override
  int get hashCode => Object.hash(receiver, headSize, tailSize);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SublistKey &&
        receiver == other.receiver &&
        headSize == other.headSize &&
        tailSize == other.tailSize;
  }
}

/// A key for a map index lookup, defined by the [receiver] key and [key] key.
class IndexKey extends CacheKey {
  final CacheKey receiver;
  final CacheKey key;

  IndexKey(this.receiver, this.key);

  @override
  String get name => '${receiver.name}[${key.name}]';

  @override
  int get hashCode => Object.hash(receiver, key);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IndexKey && receiver == other.receiver && key == other.key;
  }
}

/// A key for a map `containsKey`, defined by the [receiver] key and [key] key.
class ContainsKeyKey extends CacheKey {
  final CacheKey receiver;
  final CacheKey key;

  ContainsKeyKey(this.receiver, this.key);

  @override
  String get name => '${receiver.name}.containsKey(${key.name}';

  @override
  int get hashCode => Object.hash(receiver, key);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContainsKeyKey &&
        receiver == other.receiver &&
        key == other.key;
  }
}

/// A [DelayedExpression] that supports caching of the expression value.
class CacheableExpression implements DelayedExpression {
  /// The [CacheKey] that identifies the computed by the [_expression].
  final CacheKey cacheKey;

  /// The matching cache in which this cacheable expression was created.
  final MatchingCache _matchingCache;

  /// Track that number of times the expression is used, as registered through
  /// [registerUser]. This is used to determine whether a caching variable is
  /// needed or the expression can be used in-place.
  int _useCount = 0;

  /// Set to `true` when the encoding of this expression has been chosen
  /// (cached or in-place). No more uses can be registered once it the encoding
  /// has been chosen.
  bool _hasBeenCreated = false;

  /// If cached, the variable that stores the cached value.
  ///
  /// If the caching uses late variables, this will be a late final variable
  /// whose initializer is the expression created by [_expression].
  ///
  /// If the caching uses late lowering, this will be an uninitialized non-final
  /// non-late variable.
  ///
  /// Otherwise [_variable] is unused.
  VariableDeclaration? _variable;

  /// If cached using late lowering, this will be the boolean variable that
  /// tracks whether [_variable] as been initialized.
  ///
  /// Otherwise [_isSetVariable] is unused.
  VariableDeclaration? _isSetVariable;

  /// If cached using late lowering, this will be the variable for the local
  /// function that initializes or reads [_variable].
  ///
  /// Otherwise [_getVariable] is unused.
  VariableDeclaration? _getVariable;

  /// The [DelayedExpression] that creates the expression value.
  final DelayedExpression _expression;

  /// The name used to name [_variable], [_isSetVariable] and [_getVariable].
  final String _name;

  /// If `true`, the expression is lazily cached, if at all.
  final bool _isLate;

  /// If `true`, the [_variable] will be a const variable.
  final bool _isConst;

  /// If `true`, the expression needs to be cached if used more than once.
  final bool _requiresCaching;

  /// The file offset used for synthesized AST nodes.
  final int _fileOffset;

  CacheableExpression(
      this.cacheKey, this._matchingCache, this._expression, this._name,
      {required bool isLate,
      required bool isConst,
      required bool requiresCaching,
      required int fileOffset})
      : this._isLate = isLate,
        this._isConst = isConst,
        this._requiresCaching = requiresCaching,
        this._fileOffset = fileOffset;

  /// Creates an [Expression] for the [_expression] value.
  ///
  /// If cached, the value is accessed through a caching variable, otherwise
  /// a fresh [Expression] is created.
  ///
  /// If [promotedType] is provided, the resulting expression is ensured to
  /// have a type that is a subtype of [promotedType], either by promoted
  /// access of the cached variable or by
  @override
  Expression createExpression(InferenceVisitorBase base,
      [DartType? promotedType]) {
    assert(_useCount >= 1);
    _hasBeenCreated = true;
    bool createCache;
    if (_isLate) {
      if (_useCount == 1) {
        createCache = false;
      } else {
        createCache = _requiresCaching || _matchingCache.eagerCaching;
      }
    } else {
      createCache = true;
    }
    Expression result;
    if (!createCache) {
      result = _expression.createExpression(base);
    } else {
      VariableDeclaration? variable = _variable;
      VariableDeclaration? isSetVariable = _isSetVariable;
      if (variable == null) {
        if (_matchingCache.useLowering && _isLate) {
          variable = _variable = createUninitializedVariable(
              _expression.getType(base),
              fileOffset: _fileOffset)
            ..name = _name;
          _matchingCache.registerDeclaration(variable);
          isSetVariable = _isSetVariable = createInitializedVariable(
              createBoolLiteral(false, fileOffset: _fileOffset),
              base.coreTypes.boolNonNullableRawType,
              fileOffset: _fileOffset)
            ..name = '$_name#isSet';
          _matchingCache.registerDeclaration(isSetVariable);
          DartType type = _expression.getType(base);
          VariableDeclaration getVariable =
              _getVariable = createUninitializedVariable(
                  new FunctionType([], type, Nullability.nonNullable),
                  fileOffset: _fileOffset)
                ..name = '$_name#func'
                ..isFinal = true;

          Statement body;
          if (_matchingCache.useVerboseEncodingForDebugging) {
            body = createBlock([
              createIfStatement(
                  createNot(createVariableGet(isSetVariable)),
                  createBlock([
                    createExpressionStatement(createStaticInvocation(
                        base.coreTypes.printProcedure,
                        createArguments([
                          createStringConcatenation([
                            createStringLiteral('compute $_name',
                                fileOffset: _fileOffset),
                          ], fileOffset: _fileOffset)
                        ], fileOffset: _fileOffset),
                        fileOffset: _fileOffset)),
                    createExpressionStatement(createVariableSet(isSetVariable,
                        createBoolLiteral(true, fileOffset: _fileOffset),
                        fileOffset: _fileOffset)),
                    createExpressionStatement(createVariableSet(
                        variable, _expression.createExpression(base),
                        fileOffset: _fileOffset)),
                  ], fileOffset: _fileOffset),
                  fileOffset: _fileOffset),
              createExpressionStatement(createStaticInvocation(
                  base.coreTypes.printProcedure,
                  createArguments([
                    createStringConcatenation([
                      createStringLiteral('$_name = ', fileOffset: _fileOffset),
                      createVariableGet(variable)
                    ], fileOffset: _fileOffset)
                  ], fileOffset: _fileOffset),
                  fileOffset: _fileOffset)),
              createReturnStatement(createVariableGet(variable),
                  fileOffset: _fileOffset),
            ], fileOffset: _fileOffset)
              ..fileOffset = _fileOffset;
          } else {
            body = createReturnStatement(
                createConditionalExpression(
                    createVariableGet(isSetVariable),
                    createVariableGet(variable),
                    createLetEffect(
                        effect: createVariableSet(isSetVariable,
                            createBoolLiteral(true, fileOffset: _fileOffset),
                            fileOffset: _fileOffset),
                        result: createVariableSet(
                            variable, _expression.createExpression(base),
                            fileOffset: _fileOffset)),
                    staticType: type,
                    fileOffset: _fileOffset),
                fileOffset: _fileOffset);
          }
          FunctionDeclaration functionDeclaration = new FunctionDeclaration(
                  getVariable, new FunctionNode(body, returnType: type))
              // TODO(johnniwinther): Reinsert the file offset when the vm
              //  doesn't use it for function declaration identity.
              /*..fileOffset = fileOffset*/;
          getVariable.type = functionDeclaration.function
              .computeFunctionType(Nullability.nonNullable);
          _matchingCache.registerDeclaration(functionDeclaration);
        } else {
          variable = _variable = createVariableCache(
              _expression.createExpression(base), _expression.getType(base))
            ..isConst = _isConst
            ..isLate = _isLate
            ..name = _name;
          _matchingCache.registerDeclaration(variable);
        }
      }
      if (_matchingCache.useLowering && _isLate) {
        result = createLocalFunctionInvocation(_getVariable!,
            fileOffset: _fileOffset);
      } else {
        result = createVariableGet(variable);
      }
    }
    if (promotedType != null) {
      DartType expressionType = _expression.getType(base);
      if (!base.isAssignable(promotedType, expressionType) ||
          expressionType is DynamicType) {
        if (result is VariableGet) {
          result.promotedType = promotedType;
        } else {
          result = createAsExpression(result, promotedType,
              forNonNullableByDefault: base.isNonNullableByDefault,
              isUnchecked: true,
              fileOffset: result.fileOffset);
        }
      }
    }
    return result;
  }

  @override
  DartType getType(InferenceVisitorBase base) => _expression.getType(base);

  @override
  void registerUse() {
    assert(!_hasBeenCreated, "Expression has already been created.");
    _useCount++;
    if (_useCount == 1) {
      _expression.registerUse();
    } else {
      bool createCache;
      if (_isLate) {
        createCache = _requiresCaching || _matchingCache.eagerCaching;
      } else {
        createCache = true;
      }
      if (!createCache) {
        _expression.registerUse();
      }
    }
  }

  @override
  bool uses(DelayedExpression expression) =>
      identical(this, expression) || this._expression.uses(expression);
}
