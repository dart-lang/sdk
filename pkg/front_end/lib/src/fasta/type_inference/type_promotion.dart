// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show DartType, Expression, TypeParameterType, VariableDeclaration;

import 'package:kernel/type_environment.dart' show SubtypeCheckMode;

import '../fasta_codes.dart' show templateInternalProblemStackNotEmpty;

import '../problems.dart' show internalProblem;

import '../kernel/internal_ast.dart' show ShadowTypePromoter;

import 'type_schema_environment.dart' show TypeSchemaEnvironment;

/// Keeps track of the state necessary to perform type promotion.
///
/// Theory of operation: during parsing, the BodyBuilder calls methods in this
/// class to inform it of syntactic constructs that are encountered.  Those
/// methods maintain a linked list of [TypePromotionFact] objects tracking what
/// is known about the state of each variable at the current point in the code,
/// as well as a linked list of [TypePromotionScope] objects tracking the
/// component's nesting structure.  Whenever a variable is read, the current
/// [TypePromotionFact] and [TypePromotionScope] are recorded for later use.
///
/// During type inference, the [TypeInferrer] calls back into this class to ask
/// whether each variable read is a promoted read.  This is determined by
/// examining the [TypePromotionScope] and [TypePromotionFact] objects that were
/// recorded at the time the variable read was parsed, as well as other state
/// that may have been updated later during the parsing process.
///
/// This class abstracts away the representation of the underlying AST using
/// generic parameters.  Derived classes should set E and V to the class they
/// use to represent expressions and variable declarations, respectively.
abstract class TypePromoter {
  TypePromoter.private();

  factory TypePromoter(TypeSchemaEnvironment typeSchemaEnvironment) =
      ShadowTypePromoter.private;

  factory TypePromoter.disabled() = TypePromoterDisabled.private;

  /// Returns the current type promotion scope.
  TypePromotionScope get currentScope;

  /// Computes the promoted type of a variable read having the given [fact] and
  /// [scope].  Returns `null` if there is no promotion.
  ///
  /// [mutatedInClosure] indicates whether the variable was mutated in a closure
  /// somewhere in the method.
  DartType computePromotedType(
      TypePromotionFact fact, TypePromotionScope scope, bool mutatedInClosure);

  /// Updates the state to reflect the fact that we are entering an "else"
  /// branch.
  void enterElse();

  /// Updates the state to reflect the fact that the LHS of an "&&" or "||"
  /// expression has just been parsed, and we are entering the RHS.
  void enterLogicalExpression(Expression lhs, String operator);

  /// Updates the state to reflect the fact that the "condition" part of an "if"
  /// statement or conditional expression has just been parsed, and we are
  /// entering the "then" branch.
  void enterThen(Expression condition);

  /// Updates the state to reflect the fact that we have exited the "else"
  /// branch of an "if" statement or conditional expression.
  void exitConditional();

  /// Updates the state to reflect the fact that we have exited the RHS of an
  /// "&&" or "||" expression.
  void exitLogicalExpression(Expression rhs, Expression logicalExpression);

  /// Verifies that enter/exit calls were properly nested.
  void finished();

  /// Records that the given [variable] was accessed for reading, and returns a
  /// [TypePromotionFact] describing the variable's current type promotion
  /// state.
  ///
  /// [functionNestingLevel] should be the current nesting level of closures.
  /// This is used to determine if the variable was accessed in a closure.
  TypePromotionFact getFactForAccess(
      VariableDeclaration variable, int functionNestingLevel);

  /// Updates the state to reflect the fact that an "is" check of a local
  /// variable was just parsed.
  void handleIsCheck(Expression isExpression, bool isInverted,
      VariableDeclaration variable, DartType type, int functionNestingLevel);

  /// Updates the state to reflect the fact that the given [variable] was
  /// mutated.
  void mutateVariable(VariableDeclaration variable, int functionNestingLevel);
}

/// Implementation of [TypePromoter] which doesn't do any type promotion.
///
/// This is intended for profiling, to ensure that type inference and type
/// promotion do not slow down compilation too much.
class TypePromoterDisabled extends TypePromoter {
  TypePromoterDisabled.private() : super.private();

  @override
  TypePromotionScope get currentScope => null;

  @override
  DartType computePromotedType(TypePromotionFact fact, TypePromotionScope scope,
          bool mutatedInClosure) =>
      null;

  @override
  void enterElse() {}

  @override
  void enterLogicalExpression(Expression lhs, String operator) {}

  @override
  void enterThen(Expression condition) {}

  @override
  void exitConditional() {}

  @override
  void exitLogicalExpression(Expression rhs, Expression logicalExpression) {}

  @override
  void finished() {}

  @override
  TypePromotionFact getFactForAccess(
          VariableDeclaration variable, int functionNestingLevel) =>
      null;

  @override
  void handleIsCheck(Expression isExpression, bool isInverted,
      VariableDeclaration variable, DartType type, int functionNestingLevel) {}

  @override
  void mutateVariable(VariableDeclaration variable, int functionNestingLevel) {}
}

/// Derived class containing generic implementations of [TypePromoter].
///
/// This class contains as much of the implementation of type promotion as
/// possible without needing access to private members of shadow objects.  It
/// defers to abstract methods for everything else.
abstract class TypePromoterImpl extends TypePromoter {
  final TypeSchemaEnvironment typeSchemaEnvironment;

  /// [TypePromotionFact] representing the initial state (no facts have been
  /// determined yet).
  ///
  /// All linked lists of facts terminate in this object.
  final _NullFact _nullFacts;

  /// Map from variable declaration to the most recent [TypePromotionFact]
  /// associated with the variable.
  ///
  /// [TypePromotionFact]s that are not associated with any variable show up in
  /// this map under the key `null`.
  final _factCache = <VariableDeclaration, TypePromotionFact>{};

  /// Linked list of [TypePromotionFact]s that was current at the time the
  /// [_factCache] was last updated.
  TypePromotionFact _factCacheState;

  /// Linked list of [TypePromotionFact]s describing what is known to be true
  /// after execution of the expression or statement that was most recently
  /// parsed.
  TypePromotionFact _currentFacts;

  /// The most recently parsed expression whose outcome potentially affects what
  /// is known to be true (e.g. an "is" check or a logical expression).  May be
  /// `null` if no such expression has been encountered yet.
  Expression _promotionExpression;

  /// Linked list of [TypePromotionFact]s describing what is known to be true
  /// after execution of [_promotionExpression], assuming that
  /// [_promotionExpression] evaluates to `true`.
  TypePromotionFact _trueFactsForPromotionExpression;

  /// Linked list of [TypePromotionScope]s describing the nesting structure that
  /// contains the expression or statement that was most recently parsed.
  TypePromotionScope _currentScope = const _TopLevelScope();

  /// The sequence number of the [TypePromotionFact] that was most recently
  /// created.
  int _lastFactSequenceNumber = 0;

  /// Map from variables to the set of scopes in which the variable is mutated.
  /// If a variable is missing from the map, it is not mutated anywhere.
  Map<VariableDeclaration, Set<TypePromotionScope>> _variableMutationScopes =
      new Map<VariableDeclaration, Set<TypePromotionScope>>.identity();

  TypePromoterImpl.private(TypeSchemaEnvironment typeSchemaEnvironment)
      : this._(typeSchemaEnvironment, new _NullFact());

  TypePromoterImpl._(this.typeSchemaEnvironment, _NullFact this._nullFacts)
      : _factCacheState = _nullFacts,
        _currentFacts = _nullFacts,
        super.private() {
    _factCache[null] = _nullFacts;
  }

  @override
  TypePromotionScope get currentScope => _currentScope;

  @override
  DartType computePromotedType(
      TypePromotionFact fact, TypePromotionScope scope, bool mutatedInClosure) {
    if (mutatedInClosure) return null;
    return fact?._computePromotedType(
        this, scope, _variableMutationScopes[fact.variable]);
  }

  /// For internal debugging use, optionally prints the current state followed
  /// by the event name.  Uncomment the call to [_printEvent] to see the
  /// sequence of calls into the type promoter and the corresponding states.
  void debugEvent(String name) {
    // _printEvent(name);
  }

  @override
  void enterElse() {
    debugEvent('enterElse');
    // Pop the scope and restore the facts to the state they were in before we
    // entered the conditional.  No promotion happens in the "else" branch.
    _ConditionalScope scope = _currentScope;
    _currentScope = _currentScope._enclosing;
    _currentFacts = scope.beforeElse;
  }

  @override
  void enterLogicalExpression(Expression lhs, String operator) {
    debugEvent('enterLogicalExpression');
    if (!identical(operator, '&&')) {
      // We don't promote for `||`.
      _currentScope = new _LogicalScope(_currentScope, false, _currentFacts);
    } else {
      // Figure out what the facts are based on possible LHS outcomes.
      TypePromotionFact trueFacts = _factsWhenTrue(lhs);
      // Record the fact that we are entering a new scope, and save the
      // appropriate facts for the case where the expression gets short-cut.
      _currentScope = new _LogicalScope(_currentScope, true, _currentFacts);
      // While processing the RHS, assume the condition was true.
      _currentFacts = _addBlockingScopeToFacts(trueFacts);
    }
  }

  @override
  void enterThen(Expression condition) {
    debugEvent('enterThen');
    // Figure out what the facts are based on possible condition outcomes.
    TypePromotionFact trueFacts = _factsWhenTrue(condition);
    // Record the fact that we are entering a new scope, and save the current
    // facts for when we enter the "else" branch.
    _currentScope = new _ConditionalScope(_currentScope, _currentFacts);
    // While processing the "then" block, assume the condition was true.
    _currentFacts = _addBlockingScopeToFacts(trueFacts);
  }

  @override
  void exitConditional() {
    debugEvent('exitConditional');
  }

  @override
  void exitLogicalExpression(Expression rhs, Expression logicalExpression) {
    debugEvent('exitLogicalExpression');
    _LogicalScope scope = _currentScope;
    if (scope.isAnd) {
      TypePromotionFact factsWhenTrue = _factsWhenTrue(rhs);
      _currentFacts = scope.shortcutFacts;
      _recordPromotionExpression(
          logicalExpression, _addBlockingScopeToFacts(factsWhenTrue));
    }
    _currentScope = _currentScope._enclosing;
  }

  @override
  void finished() {
    debugEvent('finished');
    if (_currentScope is! _TopLevelScope) {
      internalProblem(
          templateInternalProblemStackNotEmpty.withArguments(
              "$runtimeType", "$_currentScope"),
          -1,
          null);
    }
  }

  @override
  TypePromotionFact getFactForAccess(
      VariableDeclaration variable, int functionNestingLevel) {
    debugEvent('getFactForAccess');
    TypePromotionFact fact = _computeCurrentFactMap()[variable];
    TypePromotionFact._recordAccessedInScope(
        fact, _currentScope, functionNestingLevel);
    return fact;
  }

  /// Returns the nesting level that was in effect when [variable] was declared.
  int getVariableFunctionNestingLevel(VariableDeclaration variable);

  @override
  void handleIsCheck(Expression isExpression, bool isInverted,
      VariableDeclaration variable, DartType type, int functionNestingLevel) {
    debugEvent('handleIsCheck');
    if (!isPromotionCandidate(variable)) return;
    _IsCheck isCheck = new _IsCheck(
        ++_lastFactSequenceNumber,
        variable,
        _currentFacts,
        _computeCurrentFactMap()[variable],
        functionNestingLevel,
        type, []);
    if (!isInverted) {
      _recordPromotionExpression(isExpression, isCheck);
    }
  }

  /// Determines whether the given variable should be considered for promotion
  /// at all.
  ///
  /// This is needed because in kernel, [VariableDeclaration] objects are
  /// sometimes used to represent local functions, which are not subject to
  /// promotion.
  bool isPromotionCandidate(VariableDeclaration variable);

  /// Updates the state to reflect the fact that the given [variable] was
  /// mutated.
  void mutateVariable(VariableDeclaration variable, int functionNestingLevel) {
    debugEvent('mutateVariable');
    (_variableMutationScopes[variable] ??=
            new Set<TypePromotionScope>.identity())
        .add(_currentScope);
    if (getVariableFunctionNestingLevel(variable) < functionNestingLevel) {
      setVariableMutatedInClosure(variable);
    }
  }

  /// Determines whether [a] and [b] represent the same expression, after
  /// dropping redundant enclosing parentheses.
  bool sameExpressions(Expression a, Expression b);

  /// Records that the given variable was mutated inside a closure.
  void setVariableMutatedInClosure(VariableDeclaration variable);

  /// Updates any facts that are present in [facts] but not in [_currentFacts]
  /// so that they include [_currentScope] in their list of blocking scopes, and
  /// returns the resulting new linked list of facts.
  ///
  /// This is used when entering the body of a conditional, or the RHS of a
  /// logical "and", to ensure that promotions are blocked if the construct
  /// being entered contains any modifications of the corresponding variables.
  /// It is also used when leaving the RHS of a logical "and", to ensure that
  /// any promotions induced by the RHS of the "and" are blocked if the RHS of
  /// the "and" contains any modifications of the corresponding variables.
  TypePromotionFact _addBlockingScopeToFacts(TypePromotionFact facts) {
    List<TypePromotionFact> factsToUpdate = [];
    while (facts != _currentFacts) {
      factsToUpdate.add(facts);
      facts = facts.previous;
    }
    Map<VariableDeclaration, TypePromotionFact> factMap =
        _computeCurrentFactMap();
    for (TypePromotionFact fact in factsToUpdate.reversed) {
      _IsCheck isCheck = fact as _IsCheck;
      VariableDeclaration variable = isCheck.variable;
      facts = new _IsCheck(
          ++_lastFactSequenceNumber,
          variable,
          facts,
          factMap[variable],
          isCheck.functionNestingLevel,
          isCheck.checkedType,
          [...isCheck._blockingScopes, _currentScope]);
      factMap[variable] = facts;
      _factCacheState = facts;
    }
    return facts;
  }

  /// Returns a map from variable declaration to the most recent
  /// [TypePromotionFact] associated with the variable.
  Map<VariableDeclaration, TypePromotionFact> _computeCurrentFactMap() {
    // Roll back any map entries associated with facts that are no longer in
    // effect, and set [commonAncestor] to the fact that is an ancestor of
    // the current state and the previously cached state.  To do this, we set a
    // variable pointing to [_currentFacts], and then walk both it and
    // [_factCacheState] back to their common ancestor, updating [_factCache] as
    // we go.
    TypePromotionFact commonAncestor = _currentFacts;
    while (commonAncestor.sequenceNumber != _factCacheState.sequenceNumber) {
      if (commonAncestor.sequenceNumber > _factCacheState.sequenceNumber) {
        // The currently cached state is older than the common ancestor guess,
        // so the common ancestor guess needs to be walked back.
        commonAncestor = commonAncestor.previous;
      } else {
        // The common ancestor guess is older than the currently cached state,
        // so we need to roll back the map entry associated with the currently
        // cached state.
        _factCache[_factCacheState.variable] =
            _factCacheState.previousForVariable;
        _factCacheState = _factCacheState.previous;
      }
    }
    assert(identical(commonAncestor, _factCacheState));
    // Roll forward any map entries associated with facts that are newly in
    // effect.  Since newer facts link to older ones, it is easiest to do roll
    // forward the most recent facts first.
    for (TypePromotionFact newState = _currentFacts;
        !identical(newState, commonAncestor);
        newState = newState.previous) {
      TypePromotionFact currentlyCached = _factCache[newState.variable];
      // Note: Since we roll forward the most recent facts first, we need to be
      // careful not write an older fact over a newer one.
      if (currentlyCached == null ||
          newState.sequenceNumber > currentlyCached.sequenceNumber) {
        _factCache[newState.variable] = newState;
      }
    }
    _factCacheState = _currentFacts;
    return _factCache;
  }

  /// Returns the set of facts known to be true after the execution of [e]
  /// assuming it evaluates to `true`.
  ///
  /// [e] must be the most recently parsed expression or statement.
  TypePromotionFact _factsWhenTrue(Expression e) =>
      sameExpressions(_promotionExpression, e)
          ? _trueFactsForPromotionExpression
          : _currentFacts;

  /// For internal debugging use, prints the current state followed by the event
  /// name.
  // ignore: unused_element
  void _printEvent(String name) {
    Iterable<TypePromotionFact> factChain(TypePromotionFact fact) sync* {
      while (fact != null) {
        yield fact;
        fact = fact.previousForVariable;
      }
    }

    _computeCurrentFactMap().forEach((variable, fact) {
      if (fact == null) return;
      print('  ${variable ?? '(null)'}: ${factChain(fact).join(' -> ')}');
    });
    if (_promotionExpression != null) {
      print('  _promotionExpression: $_promotionExpression');
      if (!identical(_trueFactsForPromotionExpression, _currentFacts)) {
        print('    if true: '
            '${factChain(_trueFactsForPromotionExpression).join(' -> ')}');
      }
    }
    print(name);
  }

  /// Records that after the evaluation of [expression], the facts will be
  /// [ifTrue] on a branch where the expression evaluated to `true`.
  void _recordPromotionExpression(
      Expression expression, TypePromotionFact ifTrue) {
    _promotionExpression = expression;
    _trueFactsForPromotionExpression = ifTrue;
  }
}

/// A single fact which is known to the type promotion engine about the state of
/// a variable (or about the flow control of the component).
///
/// The type argument V represents is the class which represents local variable
/// declarations.
///
/// Facts are linked together into linked lists via the [previous] pointer into
/// a data structure called a "fact chain" (or sometimes a "fact state"), which
/// represents all facts that are known to hold at a certain point in the
/// component.
///
/// The fact is said to "apply" to a given point in the execution of the
/// component if the fact is part of the current fact state at the point the
/// parser reaches that point in the component.
///
/// Note: just because a fact "applies" to a given point in the execution of
/// the component doesn't mean a type will be promoted--it simply means that
/// the fact was deduced at a previous point in the straight line execution of
/// the code.  It's possible that the fact will be overshadowed by a later
/// fact, or its effect will be cancelled by a later assignment.  The final
/// determination of whether promotion occurs is left to [_computePromotedType].
abstract class TypePromotionFact {
  /// The variable this fact records information about, or `null` if this fact
  /// records information about general flow control.
  final VariableDeclaration variable;

  /// The fact chain that was in effect prior to execution of the statement or
  /// expression that caused this fact to be true.
  final TypePromotionFact previous;

  /// Integer associated with this fact.  Each time a fact is created it is
  /// given a sequence number one greater than the previously generated fact.
  /// This simplifies the algorithm for finding the common ancestor of two
  /// facts; we repeatedly walk backward the fact with the larger sequence
  /// number until the sequence numbers are the same.
  final int sequenceNumber;

  /// The most recent fact appearing in the fact chain [previous] whose
  /// [variable] matches this one, or `null` if there is no such fact.
  final TypePromotionFact previousForVariable;

  /// The function nesting level of the expression that led to this fact.
  final int functionNestingLevel;

  /// Indicates whether this fact's variable was accessed inside a closure
  /// within the scope the fact applies to.
  bool _accessedInClosureInScope = false;

  TypePromotionFact(this.sequenceNumber, this.variable, this.previous,
      this.previousForVariable, this.functionNestingLevel);

  /// Computes the promoted type for [variable] at a location in the code where
  /// this fact applies.
  ///
  /// [scope] is the scope containing the read that might be promoted, and
  /// [mutationScopes] is the set of scopes in which the variable is mutated, or
  /// `null` if the variable isn't mutated anywhere.
  ///
  /// Should not be called until after parsing of the entire method is complete.
  DartType _computePromotedType(TypePromoterImpl promoter,
      TypePromotionScope scope, Iterable<TypePromotionScope> mutationScopes);

  /// Records the fact that the variable referenced by [fact] was accessed
  /// within the given scope, at the given function nesting level.
  ///
  /// If `null` is passed in for [fact], there is no effect.
  static void _recordAccessedInScope(TypePromotionFact fact,
      TypePromotionScope scope, int functionNestingLevel) {
    // TODO(paulberry): make some integration test cases that exercise the
    // behaviors of this function.  In particular verify that it's correct to
    // test functionNestingLevel against fact.functionNestingLevel (as opposed
    // to testing it against getVariableFunctionNestingLevel(variable)).
    while (fact != null) {
      if (functionNestingLevel > fact.functionNestingLevel) {
        if (fact._accessedInClosureInScope) {
          // The variable has already been accessed in a closure in the scope of
          // the current promotion (and this, any enclosing promotions), so
          // no further information needs to be updated.
          return;
        }
        fact._accessedInClosureInScope = true;
      }
      fact = fact.previousForVariable;
    }
  }
}

/// Represents a contiguous block of program text in which variables may or may
/// not be promoted.  Also used as a stack to keep track of state while the
/// method is being parsed.
class TypePromotionScope {
  /// The nesting depth of this scope.  The outermost scope (representing the
  /// whole method body) has a depth of 0.
  final int _depth;

  /// The [TypePromotionScope] representing the scope enclosing this one.
  final TypePromotionScope _enclosing;

  TypePromotionScope(this._enclosing) : _depth = _enclosing._depth + 1;

  const TypePromotionScope._topLevel()
      : _enclosing = null,
        _depth = 0;

  /// Determines whether this scope completely encloses (or is the same as)
  /// [other].
  bool containsScope(TypePromotionScope other) {
    if (this._depth > other._depth) {
      // We can't possibly contain a scope if we are at greater nesting depth
      // than it is.
      return false;
    }
    while (this._depth < other._depth) {
      other = other._enclosing;
    }
    return identical(this, other);
  }
}

/// [TypePromotionScope] representing the "then" and "else" bodies of an "if"
/// statement or conditional expression.
class _ConditionalScope extends TypePromotionScope {
  /// The fact state in effect at the top of the "else" block.
  final TypePromotionFact beforeElse;

  _ConditionalScope(TypePromotionScope enclosing, this.beforeElse)
      : super(enclosing);
}

/// [TypePromotionFact] representing an "is" check which succeeded.
class _IsCheck extends TypePromotionFact {
  /// The type appearing on the right hand side of "is".
  final DartType checkedType;

  /// List of the scopes in which a mutation to the variable would block
  /// promotion.
  final List<TypePromotionScope> _blockingScopes;

  _IsCheck(
      int sequenceNumber,
      VariableDeclaration variable,
      TypePromotionFact previous,
      TypePromotionFact previousForVariable,
      int functionNestingLevel,
      this.checkedType,
      this._blockingScopes)
      : super(sequenceNumber, variable, previous, previousForVariable,
            functionNestingLevel);

  @override
  String toString() => 'isCheck($checkedType)';

  @override
  DartType _computePromotedType(TypePromoterImpl promoter,
      TypePromotionScope scope, Iterable<TypePromotionScope> mutationScopes) {
    DartType previousPromotedType = previousForVariable?._computePromotedType(
        promoter, scope, mutationScopes);

    if (mutationScopes != null) {
      // If the variable was mutated somewhere in a that blocks the promotion,
      // promotion does not occur.
      for (TypePromotionScope blockingScope in _blockingScopes) {
        for (TypePromotionScope mutationScope in mutationScopes) {
          if (blockingScope.containsScope(mutationScope)) {
            return previousPromotedType;
          }
        }
      }

      // If the variable was mutated anywhere, and it was accessed inside a
      // closure somewhere in the scope of the potential promotion, promotion
      // does not occur.
      if (_accessedInClosureInScope) {
        return previousPromotedType;
      }
    }

    // What we do now depends on the relationship between the previous type of
    // the variable and the type we are checking against.
    DartType previousType = previousPromotedType ?? variable.type;
    if (promoter.typeSchemaEnvironment.isSubtypeOf(
        checkedType, previousType, SubtypeCheckMode.withNullabilities)) {
      // The type we are checking against is a subtype of the previous type of
      // the variable, so this is a refinement; we can promote.
      return checkedType;
    } else if (previousType is TypeParameterType &&
        promoter.typeSchemaEnvironment.isSubtypeOf(checkedType,
            previousType.bound, SubtypeCheckMode.withNullabilities)) {
      // The type we are checking against is a subtype of the bound of the
      // previous type of the variable; we can promote the bound.
      return new TypeParameterType.intersection(
          previousType.parameter, previousType.nullability, checkedType);
    } else {
      // The types aren't sufficiently related; we can't promote.
      return previousPromotedType;
    }
  }
}

/// [TypePromotionScope] representing the RHS of a logical expression.
class _LogicalScope extends TypePromotionScope {
  /// Indicates whether the logical operation is an `&&` or an `||`.
  final bool isAnd;

  /// The fact state in effect if the logical expression gets short-cut.
  final TypePromotionFact shortcutFacts;

  _LogicalScope(TypePromotionScope enclosing, this.isAnd, this.shortcutFacts)
      : super(enclosing);
}

/// Instance of [TypePromotionFact] representing the facts which are known on
/// entry to the method (i.e. nothing).
class _NullFact extends TypePromotionFact {
  _NullFact() : super(0, null, null, null, 0);

  @override
  String toString() => 'null';

  @override
  DartType _computePromotedType(TypePromoter promoter, TypePromotionScope scope,
      Iterable<TypePromotionScope> mutationScopes) {
    throw new StateError('Tried to create promoted type for no variable');
  }
}

/// Instance of [TypePromotionScope] representing the entire method body.
class _TopLevelScope extends TypePromotionScope {
  const _TopLevelScope() : super._topLevel();
}
