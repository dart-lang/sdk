// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:front_end/src/fasta/deprecated_problems.dart';
import 'package:front_end/src/fasta/type_inference/type_inferrer.dart';
import 'package:kernel/ast.dart';

/// Keeps track of the state necessary to perform type promotion.
///
/// Theory of operation: during parsing, the BodyBuilder calls methods in this
/// class to inform it of syntactic constructs that are encountered.  Those
/// methods maintain a linked list of [TypePromotionFact] objects tracking what
/// is known about the state of each variable at the current point in the code,
/// as well as a linked list of [TypePromotionScope] objects tracking the
/// program's nesting structure.  Whenever a variable is read, the current
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

  /// Updates the state to reflect the fact that the "condition" part of an "if"
  /// statement or conditional expression has just been parsed, and we are
  /// entering the "then" branch.
  void enterThen(Expression condition);

  /// Updates the state to reflect the fact that we have exited the "else"
  /// branch of an "if" statement or conditional expression.
  void exitConditional();

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
  @override
  TypePromotionScope get currentScope => null;

  @override
  DartType computePromotedType(TypePromotionFact fact, TypePromotionScope scope,
          bool mutatedInClosure) =>
      null;

  @override
  void enterElse() {}

  @override
  void enterThen(Expression condition) {}

  @override
  void exitConditional() {}

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
  /// contains the expressoin or statement that was most recently parsed.
  TypePromotionScope _currentScope = const _TopLevelScope();

  /// The sequence number of the [TypePromotionFact] that was most recently
  /// created.
  int _lastFactSequenceNumber = 0;

  TypePromoterImpl() : this._(new _NullFact());

  TypePromoterImpl._(_NullFact this._nullFacts)
      : _factCacheState = _nullFacts,
        _currentFacts = _nullFacts {
    _factCache[null] = _nullFacts;
  }

  @override
  TypePromotionScope get currentScope => _currentScope;

  @override
  DartType computePromotedType(
      TypePromotionFact fact, TypePromotionScope scope, bool mutatedInClosure) {
    if (mutatedInClosure) return null;
    return fact?._computePromotedType(this, scope);
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
    _ConditionalScope scope = _currentScope;
    // Record the current fact state so that once we exit the "else" branch, we
    // can merge facts from the two branches.
    scope.afterTrue = _currentFacts;
    // While processing the "else" block, assume the condition was false.
    _currentFacts = scope.beforeElse;
  }

  @override
  void enterThen(Expression condition) {
    debugEvent('enterThen');
    // Figure out what the facts are based on possible condition outcomes.
    var trueFacts = _factsWhenTrue(condition);
    var falseFacts = _factsWhenFalse(condition);
    // Record the fact that we are entering a new scope, and save the "false"
    // facts for when we enter the "else" branch.
    _currentScope = new _ConditionalScope(_currentScope, falseFacts);
    // While processing the "then" block, assume the condition was true.
    _currentFacts = trueFacts;
  }

  @override
  void exitConditional() {
    debugEvent('exitConditional');
    _ConditionalScope scope = _currentScope;
    _currentScope = _currentScope._enclosing;
    _currentFacts = _mergeFacts(scope.afterTrue, _currentFacts);
  }

  @override
  void finished() {
    debugEvent('finished');
    if (_currentScope is! _TopLevelScope) {
      deprecated_internalProblem('Stack not empty');
    }
  }

  @override
  TypePromotionFact getFactForAccess(
      VariableDeclaration variable, int functionNestingLevel) {
    debugEvent('getFactForAccess');
    var fact = _computeCurrentFactMap()[variable];
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
    var isCheck = new _IsCheck(
        ++_lastFactSequenceNumber,
        variable,
        _currentFacts,
        _computeCurrentFactMap()[variable],
        functionNestingLevel,
        type);
    if (!isInverted) {
      _recordPromotionExpression(isExpression, isCheck, _currentFacts);
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
    var fact = _computeCurrentFactMap()[variable];
    TypePromotionFact._recordMutatedInScope(fact, _currentScope);
    if (getVariableFunctionNestingLevel(variable) < functionNestingLevel) {
      setVariableMutatedInClosure(variable);
    }
    setVariableMutatedAnywhere(variable);
  }

  /// Determines whether [a] and [b] represent the same expression, after
  /// dropping redundant enclosing parentheses.
  bool sameExpressions(Expression a, Expression b);

  /// Records that the given variable was mutated somewhere inside the method.
  void setVariableMutatedAnywhere(VariableDeclaration variable);

  /// Records that the given variable was mutated inside a closure.
  void setVariableMutatedInClosure(VariableDeclaration variable);

  /// Indicates whether [setVariableMutatedAnywhere] has been called for the
  /// given [variable].
  bool wasVariableMutatedAnywhere(VariableDeclaration variable);

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
      var currentlyCached = _factCache[newState.variable];
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
  /// assuming it evaluates to `false`.
  ///
  /// [e] must be the most resently parsed expression or statement.
  TypePromotionFact _factsWhenFalse(Expression e) {
    // Type promotion currently only occurs when an "is" or logical expression
    // evaluates to `true`, so no special logic is required; we just use
    // [_currentFacts].
    //
    // TODO(paulberry): experiment with supporting promotion in cases like
    // `if (x is! T) { ... } else { ...access x... }`
    return _currentFacts;
  }

  /// Returns the set of facts known to be true after the execution of [e]
  /// assuming it evaluates to `true`.
  ///
  /// [e] must be the most resently parsed expression or statement.
  TypePromotionFact _factsWhenTrue(Expression e) =>
      sameExpressions(_promotionExpression, e)
          ? _trueFactsForPromotionExpression
          : _currentFacts;

  /// Returns the set of facts known to be true after two branches of execution
  /// rejoin.
  TypePromotionFact _mergeFacts(TypePromotionFact a, TypePromotionFact b) {
    // Type promotion currently doesn't support any mechanism for facts to
    // accumulate along a straight-line execution path (they can only accumulate
    // when entering a scope), so we can simply find the common ancestor fact.
    //
    // TODO(paulberry): experiment with supporting promotion in cases like:
    //     if (...) {
    //       if (x is! T) return;
    //     } else {
    //       if (x is! T) return;
    //     }
    //     ...access x...
    while (a.sequenceNumber != b.sequenceNumber) {
      if (a.sequenceNumber > b.sequenceNumber) {
        a = a.previous;
      } else {
        b = b.previous;
      }
    }
    assert(identical(a, b));
    return a;
  }

  /// For internal debugging use, prints the current state followed by the event
  /// name.
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
    print(name);
  }

  /// Records that after the evaluation of [expression], the facts will be
  /// [ifTrue] on a branch where the expression evaluted to `true`, and
  /// [ifFalse] on a branch where the expression evaluated to `false` (or where
  /// the truth value of the expresison doesn't matter).
  ///
  /// TODO(paulberry): when we start handling promotion in "else" clauses, we'll
  /// need to split [ifFalse] into two cases, one for when the expression
  /// evaluated to `false`, and one where the truth value of the expression
  /// doesn't matter.
  void _recordPromotionExpression(Expression expression,
      TypePromotionFact ifTrue, TypePromotionFact ifFalse) {
    _promotionExpression = expression;
    _trueFactsForPromotionExpression = ifTrue;
    _currentFacts = ifFalse;
  }
}

/// A single fact which is known to the type promotion engine about the state of
/// a variable (or about the flow control of the program).
///
/// The type argument V represents is the class which represents local variable
/// declarations.
///
/// Facts are linked together into linked lists via the [previous] pointer into
/// a data structure called a "fact chain" (or sometimes a "fact state"), which
/// represents all facts that are known to hold at a certain point in the
/// program.
///
/// The fact is said to "apply" to a given point in the execution of the program
/// if the fact is part of the current fact state at the point the parser
/// reaches that point in the program.
///
/// Note: just because a fact "applies" to a given point in the execution of the
/// program doesn't mean a type will be promoted--it simply means that the fact
/// was deduced at a previous point in the straight line execution of the code.
/// It's possible that the fact will be overshadowed by a later fact, or its
/// effect will be cancelled by a later assignment.  The final detemination of
/// whether promotion occurs is left to [_computePromotedType].
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

  /// If this fact's variable was mutated within any scopes the
  /// fact applies to, a set of the corresponding scopes.  Otherwise `null`.
  ///
  /// TODO(paulberry): the size of this set is probably very small most of the
  /// time.  Would it be better to use a list?
  Set<TypePromotionScope> _mutatedInScopes;

  /// If this fact's variable was accessed inside a closure within any scopes
  /// the fact applies to, a set of the corresponding scopes.  Otherwise `null`.
  ///
  /// TODO(paulberry): the size of this set is probably very small most of the
  /// time.  Would it be better to use a list?
  Set<TypePromotionScope> _accessedInClosureInScopes;

  TypePromotionFact(this.sequenceNumber, this.variable, this.previous,
      this.previousForVariable, this.functionNestingLevel);

  /// Computes the promoted type for [variable] at a location in the code where
  /// this fact applies.
  ///
  /// Should not be called until after parsing of the entire method is complete.
  DartType _computePromotedType(
      TypePromoterImpl promoter, TypePromotionScope scope);

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
        fact._accessedInClosureInScopes ??=
            new Set<TypePromotionScope>.identity();
        if (!fact._accessedInClosureInScopes.add(scope)) return;
      }
      fact = fact.previousForVariable;
    }
  }

  /// Records the fact that the variable referenced by [fact] was mutated
  /// within the given scope.
  ///
  /// If `null` is passed in for [fact], there is no effect.
  static void _recordMutatedInScope(
      TypePromotionFact fact, TypePromotionScope scope) {
    while (fact != null) {
      fact._mutatedInScopes ??= new Set<TypePromotionScope>.identity();
      if (!fact._mutatedInScopes.add(scope)) return;
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

  /// The fact state which was in effect at the bottom of the "then" block.
  TypePromotionFact afterTrue;

  _ConditionalScope(TypePromotionScope enclosing, this.beforeElse)
      : super(enclosing);
}

/// [TypePromotionFact] representing an "is" check which succeeded.
class _IsCheck extends TypePromotionFact {
  /// The type appearing on the right hand side of "is".
  final DartType checkedType;

  _IsCheck(
      int sequenceNumber,
      VariableDeclaration variable,
      TypePromotionFact previous,
      TypePromotionFact previousForVariable,
      int functionNestingLevel,
      this.checkedType)
      : super(sequenceNumber, variable, previous, previousForVariable,
            functionNestingLevel);

  @override
  String toString() => 'isCheck($checkedType)';

  @override
  DartType _computePromotedType(
      TypePromoterImpl promoter, TypePromotionScope scope) {
    // TODO(paulberry): add a subtype check.  For example:
    //     f(Object x) {
    //       if (x is int) { // promotes x to int
    //         if (x is String) { // does not promote x to String, since String
    //                            // not a subtype of int
    //         }
    //       }
    //     }

    // If the variable was mutated somewhere in the scope of the potential
    // promotion, promotion does not occur.
    if (_mutatedInScopes != null) {
      for (var assignmentScope in _mutatedInScopes) {
        if (assignmentScope.containsScope(scope)) {
          return previousForVariable?._computePromotedType(promoter, scope);
        }
      }
    }

    // If the variable was mutated anywhere, and it was accessed inside a
    // closure somewhere in the scope of the potential promotion, promotion does
    // not occur.
    if (promoter.wasVariableMutatedAnywhere(variable) &&
        _accessedInClosureInScopes != null) {
      for (var accessScope in _accessedInClosureInScopes) {
        if (accessScope.containsScope(scope)) {
          return previousForVariable?._computePromotedType(promoter, scope);
        }
      }
    }
    return checkedType;
  }
}

/// Instance of [TypePromotionFact] representing the facts which are known on
/// entry to the method (i.e. nothing).
class _NullFact extends TypePromotionFact {
  _NullFact() : super(0, null, null, null, 0);

  @override
  String toString() => 'null';

  @override
  DartType _computePromotedType(
      TypePromoter promoter, TypePromotionScope scope) {
    throw new StateError('Tried to create promoted type for no variable');
  }
}

/// Instance of [TypePromotionScope] representing the entire method body.
class _TopLevelScope extends TypePromotionScope {
  const _TopLevelScope() : super._topLevel();
}
