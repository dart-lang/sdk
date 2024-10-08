// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_shared/synced/async_status_codes.dart' as status_codes;

import '../js_ast/js_ast.dart' as js_ast;
import 'js_names.dart';

/// Rewrites a [js_ast.Fun] with async/sync*/async* functions and await and
/// yield (with dart-like semantics) to an equivalent function without these.
/// await-for is not handled and must be rewritten before (currently lowered to
/// a normal for loop in compiler.dart).
///
/// Look at [_rewriteFunction], [visitDartYield] and [visitAwait] for more
/// explanation.
abstract class AsyncRewriterBase extends js_ast.NodeVisitor<Object?> {
  // Local variables are hoisted to the top of the function, so they are
  // collected here.
  final List<js_ast.VariableBinding> _localVariables = [];

  final Map<js_ast.Node, int> _continueLabels = {};
  final Map<js_ast.Node, int> _breakLabels = {};

  /// The label of a finally part.
  final Map<js_ast.Block, int> _finallyLabels = {};

  /// The label of the catch handler of a [js_ast.Try] or a [js_ast.Fun] or
  /// [js_ast.Catch].
  ///
  /// These mark the points an error can be consumed.
  ///
  /// - The handler of a [js_ast.Fun] is the outermost and will rethrow the
  ///   error.
  /// - The handler of a [js_ast.Try] will run the catch handler.
  /// - The handler of a [js_ast.Catch] is a synthetic handler that ensures the
  ///   right finally blocks are run if an error is thrown inside a
  ///   catch-handler.
  final Map<js_ast.Node, int> _handlerLabels = {};

  /// The label index for the return clause. Only included in functions that
  /// have one or more explicit return statements or any async* function to
  /// handle the finally clause clean up.
  late final int _exitLabel = _newLabel('return');

  /// The label exit for the error case. If an async/sync*/async* function
  /// throws this label captures the error and rethrows it to the correct
  /// context.
  late final int _rethrowLabel = _newLabel('rethrow');

  /// A stack of all (surrounding) jump targets.
  ///
  /// Jump targets are:
  ///
  /// * The function, signalling a return or uncaught throw.
  /// * Loops.
  /// * LabeledStatements (also used for 'continue' when attached to loops).
  /// * Try statements, for catch and finally handlers.
  /// * Catch handlers, when inside a catch-part of a try, the catch-handler is
  ///   used to associate with a synthetic handler that will ensure the right
  ///   finally blocks are visited.
  ///
  /// When jumping to a target it is necessary to visit all finallies that
  /// are on the way to target (i.e. more nested than the jump target).
  final List<js_ast.Node> _jumpTargets = [];

  late final PreTranslationAnalysis _analysis;

  /// Contains the result of an awaited expression, or a conditional or
  /// lazy boolean operator.
  ///
  /// For example a conditional expression is roughly translated like:
  /// [[cond ? a : b]]
  ///
  /// Becomes:
  ///
  /// while true { // outer while loop
  ///   switch (goto) { // Simulates goto
  ///     ...
  ///       goto = [[cond]] ? thenLabel : elseLabel
  ///       break;
  ///     case thenLabel:
  ///       result = [[a]];
  ///       goto = joinLabel;
  ///       break;
  ///     case elseLabel:
  ///       result = [[b]];
  ///     case joinLabel:
  ///       // Now the result of computing the condition is in result.
  ///     ....
  ///   }
  /// }
  ///
  /// It is a parameter to the [body] function, so that [awaitStatement] can
  /// call [body] with the result of an awaited Future.
  late final js_ast.Identifier _result = TemporaryId('t\$result');

  /// A parameter to the [bodyName] function. Indicating if we are in success
  /// or error case.
  late final js_ast.Identifier _errorCode = TemporaryId('t\$errorCode');

  /// The inner function that is scheduled to do each await/yield,
  /// and called to do a new iteration for sync*.
  final js_ast.Identifier bodyName;

  /// Used to simulate a goto.
  ///
  /// To "goto" a label, the label is assigned to this variable, and break out
  /// of the switch to take another iteration in the while loop. See [_addGoto]
  late final js_ast.Identifier _goto = TemporaryId('t\$goto');

  /// Variable containing the label of the current error handler.
  late final js_ast.Identifier _handler = TemporaryId('t\$handler');

  /// Set to `true` if any of the switch statement labels is a handler. At the
  /// end of rewriting this is used to see if a shorter form of error handling
  /// can be used. The shorter form could be a change in the method boilerplate,
  /// in the state machine wrapper, or not implemented. [addErrorExit] can test
  /// this to elide the error exit handler when there are no other handlers, or
  /// set it to `true` if there is no shorter form.
  bool _hasHandlerLabels = false;

  /// A stack of labels of finally blocks to visit, and the label to go to after
  /// the last.
  late final js_ast.Identifier _next = TemporaryId('t\$next');

  /// The current returned value (a finally block may overwrite it).
  late final js_ast.Identifier _returnValue = TemporaryId('t\$returnValue');

  /// Stores the current error when we are in the process of handling an error.
  late final js_ast.Identifier _currentError = TemporaryId('t\$currentError');

  /// The label of the outer loop.
  ///
  /// Used if there are untransformed loops containing break or continues to
  /// targets outside the loop.
  late final String _outerLabelName;

  int _currentLabel = 0;

  bool get _isAsync => false;
  bool get _isSyncStar => false;
  bool get _isAsyncStar => false;

  /// Visitor that collects scopes for the function passed to [rewrite]. Used
  /// to initialize and reset scope objects where necessary.
  late _ScopeCollector _scopeCollector;

  AsyncRewriterBase({required this.bodyName});

  /// Main entry point. Rewrites a sync*/async/async* function to an equivalent
  /// normal function.
  ///
  /// [bodyPrefix] will get prepended to the body of the rewritten function and
  /// any references to parameters within it will be replaced with the correct
  /// temporary ID for that parameter.
  js_ast.Fun rewrite(js_ast.Fun node, Object? bodySourceInformation,
      Object? exitSourceInformation,
      {List<js_ast.Statement>? bodyPrefix}) {
    _analysis = PreTranslationAnalysis(_unsupported, node)..analyze();
    _scopeCollector = _ScopeCollector(_analysis)..collect(node);

    _outerLabelName = _freshLabelName('outer');

    final rewrittenFunction = _rewriteFunction(
        node, bodySourceInformation, exitSourceInformation,
        bodyPrefix: bodyPrefix);
    if (bodyPrefix != null) {
      // Prepend the body prefix to the start of the rewritten function.
      rewrittenFunction.body.statements.insertAll(0, bodyPrefix);
    }
    return rewrittenFunction;
  }

  js_ast.Expression get _currentErrorHandler {
    return js_ast.number(_handlerLabels[
        _jumpTargets.lastWhere((node) => _handlerLabels[node] != null)]!);
  }

  /// Generates a label name based on [originalName] with a suffix to
  /// guarantee it does not collide with already used names.
  String _freshLabelName(String originalName) {
    var result = originalName;
    var counter = 1;
    while (_analysis.usedLabelNames.contains(result)) {
      result = '$counter';
      ++counter;
    }
    _analysis.usedLabelNames.add(result);
    return result;
  }

  /// All the pieces are collected in this map, to create a switch with a case
  /// for each label.
  ///
  /// The order is important due to fall-through control flow, therefore the
  /// type is explicitly LinkedHashMap.
  Map<int, List<js_ast.Statement>> labelledParts = {};

  /// Description of each label for readability of the non-minified output.
  Map<int, String> labelComments = {};

  /// True if the function has any try blocks containing await.
  bool hasTryBlocks = false;

  /// True if the traversion currently is inside a loop or switch for which
  /// [_shouldTransform] is false.
  bool insideUntranslatedBreakable = false;

  /// True if a label is used to break to an outer switch-statement.
  bool hasJumpThoughOuterLabel = false;

  /// True if there is a catch-handler protected by a finally with no enclosing
  /// catch-handlers.
  bool needsRethrow = false;

  /// Buffer for collecting translated statements belonging to the same switch
  /// case.
  List<js_ast.Statement> currentStatementBuffer = [];

  /// Hoisted variables get declared in the outer scope of the function body
  /// being rewritten. Most variables get hoisted via a scope object. See
  /// [_ScopeCollector] for more info on scope objects. Temporary ids are
  /// already unique to a given scope so we can just hoist them directly.
  void _hoistIfNecessary(js_ast.Expression node) {
    if (node is TemporaryId) {
      _localVariables.add(node);
    }
  }

  // Labels will become cases in the big switch expression, and `goto label`
  // is expressed by assigning to the switch key [gotoName] and breaking out of
  // the switch.

  int _newLabel(String comment) {
    var result = _currentLabel++;
    labelComments[result] = comment;
    return result;
  }

  /// Begins outputting statements to a new buffer with label [label].
  ///
  /// Each buffer ends up as its own case part in the big state-switch.
  void _beginLabel(int label) {
    assert(!labelledParts.containsKey(label));
    currentStatementBuffer = [];
    labelledParts[label] = currentStatementBuffer;
    _addStatement(js_ast.Comment(labelComments[label]!));
  }

  /// Returns a statement assigning to the variable named [gotoName].
  /// This should be followed by a break for the goto to be executed. Use
  /// [_gotoAndBreak] or [_addGoto] for this.
  js_ast.Statement _setGotoVariable(int label, Object? sourceInformation) {
    return js_ast.ExpressionStatement(js_ast
        .js('# = #', [_goto, js_ast.number(label)]).withSourceInformation(
            sourceInformation));
  }

  /// Returns a block that has a goto to [label] including the break.
  ///
  /// Also inserts a comment describing the label if available.
  js_ast.Block _gotoAndBreak(int label, Object? sourceInformation) {
    var statements = <js_ast.Statement>[];
    if (labelComments.containsKey(label)) {
      statements.add(js_ast.Comment('goto ${labelComments[label]}'));
    }
    statements.add(_setGotoVariable(label, sourceInformation));
    if (insideUntranslatedBreakable) {
      hasJumpThoughOuterLabel = true;
      statements.add(js_ast.Break(_outerLabelName)
          .withSourceInformation(sourceInformation));
    } else {
      statements
          .add(js_ast.Break(null).withSourceInformation(sourceInformation));
    }
    return js_ast.Block(statements);
  }

  /// Adds a goto to [label] including the break.
  ///
  /// Also inserts a comment describing the label if available.
  void _addGoto(int label, Object? sourceInformation) {
    if (labelComments.containsKey(label)) {
      _addStatement(js_ast.Comment('goto ${labelComments[label]}'));
    }
    _addStatement(_setGotoVariable(label, sourceInformation));

    _addBreak(sourceInformation);
  }

  void _addStatement(js_ast.Statement node) {
    currentStatementBuffer.add(node);
  }

  void _addExpressionStatement(js_ast.Expression node,
      [Object? sourceInformation]) {
    _addStatement(js_ast.ExpressionStatement(node)
      ..sourceInformation = sourceInformation);
  }

  /// True if there is an await or yield in [node] or some subexpression.
  bool _shouldTransform(js_ast.Node? node) {
    return _analysis.hasAwaitOrYield.contains(node);
  }

  Never _unsupported(js_ast.Node node) {
    throw UnsupportedError(
        'Node $node cannot be transformed by the await-sync transformer');
  }

  Never _unreachable(js_ast.Node node) {
    throw StateError('Internal error, trying to visit $node');
  }

  void _visitStatement(js_ast.Statement node) {
    node.accept(this);
  }

  /// Visits [node] to ensure its side effects are performed, but throwing away
  /// the result.
  ///
  /// If the return value of visiting [node] is an expression guaranteed to have
  /// no side effect, it is dropped.
  void _visitExpressionIgnoreResult(js_ast.Expression node) {
    var result = node.accept(this) as js_ast.Expression;
    if (!(result is js_ast.Literal || result is js_ast.Identifier)) {
      _addExpressionStatement(result);
    }
  }

  js_ast.Expression visitExpression(js_ast.Expression node) {
    return node.accept(this) as js_ast.Expression;
  }

  /// Calls [fn] with the value of evaluating [node1] and [node2].
  ///
  /// Both nodes are evaluated in order.
  ///
  /// If node2 must be transformed (see [_shouldTransform]), then the evaluation
  /// of node1 is added to the current statement-list and the result is stored
  /// in a temporary variable. The evaluation of node2 is then free to emit
  /// statements without affecting the result of node1.
  ///
  /// This is necessary, because await or yield expressions have to emit
  /// statements, and these statements could affect the value of node1.
  ///
  /// For example:
  ///
  /// - _storeIfNecessary(someLiteral) returns someLiteral.
  /// - _storeIfNecessary(someVariable)
  ///   inserts: var tempX = someVariable
  ///   returns: tempX
  ///   where tempX is a fresh temporary variable.
  js_ast.Expression _storeIfNecessary(js_ast.Expression result) {
    // Note that RegExes, js_ast.ArrayInitializer and js_ast.ObjectInitializer
    // are not [js_ast.Literal]s.
    if (result is js_ast.Literal) return result;

    var tempVar = TemporaryId('t\$temp');
    _localVariables.add(tempVar);
    _addStatement(js_ast.js.statement('# = #;', [tempVar, result]));
    return tempVar;
  }

  // TODO(sra): Many calls to this method use `store: false`, and could be
  // replaced with calls to `visitExpression`.
  T _withExpression<T>(
      js_ast.Expression node, T Function(js_ast.Expression result) fn,
      {required bool store}) {
    var visited = visitExpression(node);
    if (store) {
      visited = _storeIfNecessary(visited);
    }
    var result = fn(visited);
    return result;
  }

  /// Calls [fn] with the result of evaluating [node]. Taking special care of
  /// property accesses.
  ///
  /// If [store] is true the result of evaluating [node] is stored in a
  /// temporary.
  ///
  /// We might need to compute and store the receiver of a call expression if
  /// the arguments include an 'await' expression. Due to expression evaluation
  /// order we must first evaluate the receiver, then the arguments, and finally
  /// invoke the call. With this async lowering the argument evaluation might
  /// cause us to break out of the current function. We therefore need to store
  /// the receiver in a temporary variable to use after we re-enter the function
  /// body.
  ///
  /// We cannot simply rewrite `<receiver>.m()` to:
  ///
  ///     temp = <receiver>.m;
  ///     temp();
  ///
  /// Because this leaves `this` unbound in the call. To solve this we `bind`
  /// the receiver to the tear-off to re-establish the `this` context.
  ///
  /// [isCall] determines if the node is a [js_ast.Call] or a [js_ast.New]. We
  /// cannot `bind` to a constructor tear-off as it would no longer be a
  /// constructor. However, constructors have no `this` context anyway so they
  /// are safe to tear-off without binding.
  js_ast.Expression withCallTargetExpression(js_ast.Expression node,
      js_ast.Expression Function(js_ast.Expression result) fn,
      {required bool store, required bool isCall}) {
    var visited = visitExpression(node);
    js_ast.Expression storedIfNeeded;
    if (store) {
      if (visited is js_ast.PropertyAccess) {
        final storedReceiver = _storeIfNecessary(visited.receiver);
        // We handle the `super` literal specially since the bound object in
        // that case is `this`. `super` cannot be passed to `bind`.
        final bindTarget =
            storedReceiver is js_ast.Super ? js_ast.This() : storedReceiver;
        final jsTearOff = isCall
            ? js_ast.Call(
                js_ast.PropertyAccess.field(
                    js_ast.PropertyAccess(storedReceiver, visited.selector),
                    'bind'),
                [bindTarget])
            : visited;
        storedIfNeeded = _storeIfNecessary(jsTearOff);
      } else {
        storedIfNeeded = _storeIfNecessary(visited);
      }
    } else {
      storedIfNeeded = visited;
    }
    return fn(storedIfNeeded);
  }

  /// Calls [fn] with the value of evaluating [node1] and [node2].
  ///
  /// If `shouldTransform(node2)` the first expression is stored in a temporary
  /// variable.
  ///
  /// This is because node1 must be evaluated before visiting node2,
  /// because the evaluation of an await or yield cannot be expressed as
  /// an expression, visiting node2 it will output statements that
  /// might have an influence on the value of node1.
  js_ast.Expression withExpression2(
      js_ast.Expression node1,
      js_ast.Expression node2,
      js_ast.Expression Function(
              js_ast.Expression result1, js_ast.Expression result2)
          fn) {
    var r1 = visitExpression(node1);
    if (_shouldTransform(node2)) {
      r1 = _storeIfNecessary(r1);
    }
    var r2 = visitExpression(node2);
    var result = fn(r1, r2);
    return result;
  }

  /// Calls [fn] with the value of evaluating all [nodes].
  ///
  /// All results before the last node where `shouldTransform(node)` are stored
  /// in temporary variables.
  ///
  /// See more explanation on [withExpression2].
  T withExpressions<T>(List<js_ast.Expression> nodes,
      T Function(List<js_ast.Expression> results) fn) {
    var visited = <js_ast.Expression>[];
    _collectVisited(nodes, visited);
    final result = fn(visited);
    return result;
  }

  /// Like [withExpressions], but permitting `null` nodes. If any of the nodes
  /// are null, they are ignored, and a null is passed to [fn] in that place.
  T withNullableExpressions<T>(List<js_ast.Expression?> nodes,
      T Function(List<js_ast.Expression?> results) fn) {
    var visited = <js_ast.Expression?>[];
    _collectVisited(nodes, visited);
    final result = fn(visited);
    return result;
  }

  void _collectVisited(
      List<js_ast.Expression?> nodes, List<js_ast.Expression?> visited) {
    // Find last occurrence of a 'transform' expression in [nodes].
    // All expressions before that must be stored in temp-vars.
    var lastTransformIndex = 0;
    for (var i = nodes.length - 1; i >= 0; --i) {
      if (nodes[i] == null) continue;
      if (_shouldTransform(nodes[i])) {
        lastTransformIndex = i;
        break;
      }
    }
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node != null) {
        node = visitExpression(node);
        if (i < lastTransformIndex) {
          node = _storeIfNecessary(node);
        }
      }
      visited.add(node);
    }
  }

  /// Makes an empty scope object for captured variables.
  ///
  /// Uses `Object.create(null)` to ensure none of the JS Object prototype chain
  /// pollutes the namespace.
  js_ast.Expression _makeEmptyScopeObject() {
    return js_ast.js('Object.create(null)');
  }

  /// Creates a new scope object for [node] if it needs one.
  ///
  /// Only scopes that are captured need to be reset on re-entry. Otherwise the
  /// scope object becomes obsolete when the end of the scope is reached as
  /// there is no way to reference it anymore.
  ///
  /// This should be invoked whenever a scope is collected by [_ScopeCollector]
  /// and the scope would be re-entered by a loop in control flow.
  void _resetScopeIfNecessary(js_ast.Node node) {
    final nodeScope = _scopeCollector.scopeMapping[node];
    // Also exclude scopes with no declarations, these don't even have an
    // associated object.
    if (nodeScope != null &&
        nodeScope.isCaptured &&
        nodeScope.hasDeclarations) {
      _addExpressionStatement(
          js_ast.Assignment(nodeScope.scopeObject, _makeEmptyScopeObject()));
    }
  }

  /// Emits the return block that all returns jump to (after going
  /// through all the enclosing finally blocks). The jump to here is made in
  /// [visitReturn].
  void addSuccessExit(Object? sourceInformation);

  /// Emits the block that control flows to if an error has been thrown
  /// but not caught. (after going through all the enclosing finally blocks).
  void addErrorExit(Object? sourceInformation);

  void addFunctionExits(Object? sourceInformation) {
    addSuccessExit(sourceInformation);
    addErrorExit(sourceInformation);
  }

  /// Returns the rewritten function.
  js_ast.Fun _finishFunction(
      List<js_ast.Parameter> parameters,
      js_ast.Statement rewrittenBody,
      js_ast.VariableDeclarationList variableDeclarationLists,
      Object? functionSourceInformation,
      Object? bodySourceInformation);

  Iterable<js_ast.VariableInitialization> variableInitializations(
      Object? sourceInformation);

  /// Rewrites an async/sync*/async* function to a normal JavaScript function.
  ///
  /// The control flow is flattened by simulating 'goto' using a switch in a
  /// loop and a state variable [_goto] inside a nested function [body]
  /// that can be called back by [asyncStarHelper]/[asyncStarHelper]/the
  /// [Iterator].
  ///
  /// Local variables are hoisted outside the helper.
  ///
  /// Awaits in async/async* are translated to code that remembers the current
  /// location (so the function can resume from where it was) followed by a
  /// [awaitStatement]. The helper sets up the waiting for the awaited
  /// value and returns a future which is immediately returned by the
  /// [awaitStatement].
  ///
  /// Yields in sync*/async* are translated to a calls to helper functions.
  /// (see [visitYield])
  ///
  /// Simplified examples (not the exact translation, but intended to show the
  /// ideas):
  ///
  /// function (x, y, z) async {
  ///   var p = await foo();
  ///   return bar(p);
  /// }
  ///
  /// Becomes (without error handling):
  ///
  /// function(x, y, z) {
  ///   var goto = 0, returnValue, completer = new Completer(), p;
  ///   function body(result) {
  ///     while (true) {
  ///       switch (goto) {
  ///         case 0:
  ///           goto = 1 // Remember where to continue when the future succeeds.
  ///           return thenHelper(foo(), helper, completer);
  ///         case 1:
  ///           p = result;
  ///           returnValue = bar(p);
  ///           goto = 2;
  ///           break;
  ///         case 2:
  ///           return thenHelper(returnValue, null, completer)
  ///       }
  ///     }
  ///     return thenHelper(null, helper, completer);
  ///   }
  /// }
  ///
  /// Try/catch is implemented by maintaining [_handler] to contain the label
  /// of the current handler. If [body] throws, the caller should catch the
  /// error and recall [body] with first argument [status_codes.ERROR] and
  /// second argument the error.
  ///
  /// A `finally` clause is compiled similar to normal code, with the additional
  /// complexity that `finally` clauses need to know where to jump to after the
  /// clause is done. In the translation, each flow-path that enters a `finally`
  /// sets up the variable [_next] with a stack of finally-blocks and a final
  /// jump-target (exit, catch, ...).
  ///
  /// function(x, y, z) async {
  ///   try {
  ///     try {
  ///       throw "error";
  ///     } finally {
  ///       finalize1();
  ///     }
  ///   } catch (e) {
  ///     handle(e);
  ///   } finally {
  ///     finalize2();
  ///   }
  /// }
  ///
  /// Translates into (besides the fact that structures not containing
  /// await/yield/yield* are left intact):
  ///
  /// function(x, y, z) {
  ///   var goto = 0;
  ///   var returnValue;
  ///   var completer = new Completer();
  ///   var handler = 8; // Outside try-blocks go to the rethrow label.
  ///   var p;
  ///   var currentError;
  ///   // The result can be either the result of an awaited future, or an
  ///   // error if the future completed with an error.
  ///   function body(errorCode, result) {
  ///     if (errorCode == 1) {
  ///       currentError = result;
  ///       goto = handler;
  ///     }
  ///     while (true) {
  ///       switch (goto) {
  ///         case 0:
  ///           handler = 4; // The outer catch-handler
  ///           handler = 1; // The inner (implicit) catch-handler
  ///           throw "error";
  ///           next = [3];
  ///           // After the finally (2) continue normally after the try.
  ///           goto = 2;
  ///           break;
  ///         case 1: // (implicit) catch handler for inner try.
  ///           next = [3]; // destination after the finally.
  ///           // fall-though to the finally handler.
  ///         case 2: // finally for inner try
  ///           handler = 4; // catch-handler for outer try.
  ///           finalize1();
  ///           goto = next.pop();
  ///           break;
  ///         case 3: // exiting inner try.
  ///           next = [6];
  ///           goto = 5; // finally handler for outer try.
  ///           break;
  ///         case 4: // catch handler for outer try.
  ///           handler = 5; // If the handler throws, do the finally ..
  ///           next = [8] // ... and rethrow.
  ///           e = storedError;
  ///           handle(e);
  ///           // Fall through to finally.
  ///         case 5: // finally handler for outer try.
  ///           handler = null;
  ///           finalize2();
  ///           goto = next.pop();
  ///           break;
  ///         case 6: // Exiting outer try.
  ///         case 7: // return
  ///           return thenHelper(returnValue, 0, completer);
  ///         case 8: // Rethrow
  ///           return thenHelper(currentError, 1, completer);
  ///       }
  ///     }
  ///     return thenHelper(null, helper, completer);
  ///   }
  /// }
  ///
  /// [bodySourceInformation] is used on code generated to execute the function
  /// body and [exitSourceInformation] is used on code generated to exit the
  /// function.
  js_ast.Fun _rewriteFunction(js_ast.Fun node, Object? bodySourceInformation,
      Object? exitSourceInformation,
      {List<js_ast.Statement>? bodyPrefix}) {
    _beginLabel(_newLabel('Function start'));
    _handlerLabels[node] = _rethrowLabel;
    var body = node.body;
    _jumpTargets.add(node);
    _visitStatement(body);
    _jumpTargets.removeLast();
    addFunctionExits(exitSourceInformation);

    var clauses = <js_ast.SwitchClause>[
      for (final entry in labelledParts.entries)
        js_ast.Case(js_ast.number(entry.key), js_ast.Block(entry.value))
    ];
    var rewrittenBody = js_ast.Switch(_goto, clauses)
        .withSourceInformation(bodySourceInformation);
    if (hasJumpThoughOuterLabel) {
      rewrittenBody = js_ast.LabeledStatement(_outerLabelName, rewrittenBody);
    }
    rewrittenBody = js_ast.js
        .statement('while (true) #', rewrittenBody)
        .withSourceInformation(bodySourceInformation);
    var variables = <js_ast.VariableInitialization>[];

    variables.add(_makeVariableInitializer(
        _goto,
        js_ast.number(0).withSourceInformation(bodySourceInformation),
        bodySourceInformation));
    variables.addAll(variableInitializations(bodySourceInformation));
    if (_hasHandlerLabels) {
      variables.add(_makeVariableInitializer(
          _handler, js_ast.number(_rethrowLabel), bodySourceInformation));
      variables.add(
          _makeVariableInitializer(_currentError, null, bodySourceInformation));
    }
    if (_analysis.hasFinally || (_isAsyncStar && _analysis.hasYield)) {
      variables.add(_makeVariableInitializer(
          _next, js_ast.ArrayInitializer([]), bodySourceInformation));
    }
    variables.addAll(_localVariables.map((js_ast.VariableBinding declaration) {
      return js_ast.VariableInitialization(declaration, null);
    }));
    variables.addAll([
      for (final scope in _scopeCollector.scopeMapping.values)
        if (scope.hasDeclarations)
          js_ast.VariableInitialization(
              scope.scopeObject, _makeEmptyScopeObject())
    ].reversed);
    var variableDeclarationLists =
        js_ast.VariableDeclarationList('let', variables);

    // Names are already safe when added.
    return _finishFunction(node.params, rewrittenBody, variableDeclarationLists,
        exitSourceInformation, bodySourceInformation);
  }

  js_ast.Expression _visitFunctionExpression(js_ast.FunctionExpression node) {
    if (node.asyncModifier.isAsync || node.asyncModifier.isYielding) {
      // The translation does not handle nested functions that are generators
      // or asynchronous.  These functions should only be ones that are
      // introduced by JS foreign code from our own libraries.
      throw StateError('Nested function is a generator or asynchronous.');
    }

    final captureInfo = _scopeCollector.scopeCaptures[node]!;
    // If this closure does not capture any variables from an outside scope
    // then we can leave it as-is.
    if (!captureInfo.hasCapture) return node;

    // Rename any references to captured variables so they are instead looked
    // up via the captured scope object.
    node = _ClosureRenamer(_scopeCollector, captureInfo).visit(node);
    final scopeVariableList = <js_ast.Expression>[];
    final capturedScopeVariableList = <js_ast.Parameter>[];

    captureInfo.usedScopes.forEach((scope, capturedScopeVariable) {
      scopeVariableList.add(scope.scopeObject);
      capturedScopeVariableList.add(capturedScopeVariable);
    });

    // Wrap the closure in an IIFE that captures the necessary scope objects.
    // This ensures the closure grabs the scope before it gets reset (e.g. by
    // a loop iteration).
    //
    // Code that originally looked like:
    //   var foo = 3;
    //   function(x) {
    //     console.log(foo);
    //   }
    //
    // Would be transformed to:
    //    var asyncScope = {};
    //    asyncScope.foo = 3;
    //    ((capturedAsyncScope) =>
    //      function (x) {
    //        console.log(capturedAsyncScope.foo);
    //      })(asyncScope);
    return js_ast.Call(
        js_ast.ArrowFun(capturedScopeVariableList, node), scopeVariableList);
  }

  @override
  js_ast.Expression visitFun(js_ast.Fun node) {
    return _visitFunctionExpression(node);
  }

  @override
  js_ast.Expression visitArrowFun(js_ast.ArrowFun node) {
    return _visitFunctionExpression(node);
  }

  @override
  js_ast.Expression visitAccess(js_ast.PropertyAccess node) {
    return withExpression2(
        node.receiver,
        node.selector,
        (receiver, selector) => js_ast.PropertyAccess(receiver, selector)
            .withSourceInformation(node.sourceInformation));
  }

  @override
  js_ast.Expression visitArrayHole(js_ast.ArrayHole node) {
    return node;
  }

  @override
  js_ast.Expression visitArrayInitializer(js_ast.ArrayInitializer node) {
    return withExpressions(node.elements, (elements) {
      return js_ast.ArrayInitializer(elements);
    });
  }

  @override
  js_ast.Expression visitAssignment(js_ast.Assignment node) {
    if (!_shouldTransform(node)) {
      return js_ast.Assignment.compound(visitExpression(node.leftHandSide),
          node.op, visitExpression(node.value));
    }
    var leftHandSide = node.leftHandSide;
    if (leftHandSide is js_ast.Identifier) {
      return _withExpression(node.value, (js_ast.Expression value) {
        // A non-compound [js_ast.Assignment] has `op==null`. So it works out to
        // use [js_ast.Assignment.compound] for all cases.
        // Visit the [js_ast.Identifier] to ensure renaming is done correctly.
        return js_ast.Assignment.compound(
            visitExpression(leftHandSide), node.op, value);
      }, store: false);
    } else if (leftHandSide is js_ast.PropertyAccess) {
      return withExpressions(
          [leftHandSide.receiver, leftHandSide.selector, node.value],
          (evaluated) {
        return js_ast.Assignment.compound(
            js_ast.PropertyAccess(evaluated[0], evaluated[1]),
            node.op,
            evaluated[2]);
      });
    } else {
      throw 'Unexpected assignment left hand side $leftHandSide';
    }
  }

  js_ast.Statement awaitStatement(
      js_ast.Expression value, Object? sourceInformation);

  /// An await is translated to an [awaitStatement].
  ///
  /// See the comments of [_rewriteFunction] for an example.
  @override
  js_ast.Expression visitAwait(js_ast.Await node) {
    assert(_isAsync || _isAsyncStar);
    var afterAwait = _newLabel('returning from await.');
    _withExpression(node.expression, (js_ast.Expression value) {
      _addStatement(_setGotoVariable(afterAwait, node.sourceInformation));
      _addStatement(awaitStatement(value, node.sourceInformation));
    }, store: false);
    _beginLabel(afterAwait);
    return _result;
  }

  /// Checks if [node] is the variable for [_result].
  ///
  /// [_result] is used to hold the result of a transformed computation
  /// for example the result of awaiting, or the result of a conditional or
  /// short-circuiting expression.
  /// If the subexpression of some transformed node already is transformed and
  /// visiting it returns [_result], it is not redundantly assigned to itself
  /// again.
  bool isResult(js_ast.Expression node) {
    return node == _result;
  }

  @override
  js_ast.Expression visitBinary(js_ast.Binary node) {
    if (_shouldTransform(node.right) && (node.op == '||' || node.op == '&&')) {
      var thenLabel = _newLabel('then');
      var joinLabel = _newLabel('join');
      _withExpression(node.left, (js_ast.Expression left) {
        var assignLeft = isResult(left)
            ? js_ast.Block.empty()
            : js_ast.js.statement('# = #;', [_result, left]);
        if (node.op == '&&') {
          _addStatement(js_ast.js.statement('if (#) #; else #', [
            left,
            _gotoAndBreak(thenLabel, node.sourceInformation),
            assignLeft
          ]));
        } else {
          assert(node.op == '||');
          _addStatement(js_ast.js.statement('if (#) #; else #', [
            left,
            assignLeft,
            _gotoAndBreak(thenLabel, node.sourceInformation)
          ]));
        }
      }, store: true);
      _addGoto(joinLabel, node.sourceInformation);
      _beginLabel(thenLabel);
      _withExpression(node.right, (js_ast.Expression value) {
        if (!isResult(value)) {
          _addStatement(js_ast.js.statement('# = #;', [_result, value]));
        }
      }, store: false);
      _beginLabel(joinLabel);
      return _result;
    }

    return withExpression2(node.left, node.right,
        (left, right) => js_ast.Binary(node.op, left, right));
  }

  @override
  void visitBlock(js_ast.Block node) {
    _resetScopeIfNecessary(node);
    for (var statement in node.statements) {
      _visitStatement(statement);
    }
  }

  @override
  void visitBreak(js_ast.Break node) {
    var target = _analysis.targets[node]!;
    if (!_shouldTransform(target)) {
      _addStatement(node);
      return;
    }
    _translateJump(target, _breakLabels[target], node.sourceInformation);
  }

  @override
  js_ast.Expression visitCall(js_ast.Call node) {
    var storeTarget = node.arguments.any(_shouldTransform);
    return withCallTargetExpression(node.target, (target) {
      return withExpressions(node.arguments,
          (List<js_ast.Expression> arguments) {
        return js_ast.Call(target, arguments)
            .withSourceInformation(node.sourceInformation);
      });
    }, store: storeTarget, isCall: true);
  }

  @override
  void visitCase(js_ast.Case node) {
    _unreachable(node);
  }

  @override
  void visitCatch(js_ast.Catch node) {
    _unreachable(node);
  }

  @override
  void visitComment(js_ast.Comment node) {
    _addStatement(node);
  }

  @override
  js_ast.Expression visitConditional(js_ast.Conditional node) {
    if (!_shouldTransform(node.then) && !_shouldTransform(node.otherwise)) {
      return js_ast.js('# ? # : #', [
        visitExpression(node.condition),
        visitExpression(node.then),
        visitExpression(node.otherwise)
      ]).withSourceInformation(node.sourceInformation);
    }
    var thenLabel = _newLabel('then');
    var joinLabel = _newLabel('join');
    var elseLabel = _newLabel('else');
    _withExpression(node.condition, (js_ast.Expression condition) {
      _addStatement(js_ast.js.statement('# = # ? # : #;', [
        _goto,
        condition,
        js_ast.number(thenLabel),
        js_ast.number(elseLabel)
      ]));
    }, store: false);
    _addBreak(node.sourceInformation);
    _beginLabel(thenLabel);
    _withExpression(node.then, (js_ast.Expression value) {
      if (!isResult(value)) {
        _addStatement(js_ast.js.statement('# = #;', [_result, value]));
      }
    }, store: false);
    _addGoto(joinLabel, node.sourceInformation);
    _beginLabel(elseLabel);
    _withExpression(node.otherwise, (js_ast.Expression value) {
      if (!isResult(value)) {
        _addStatement(js_ast.js.statement('# = #;', [_result, value]));
      }
    }, store: false);
    _beginLabel(joinLabel);
    return _result;
  }

  @override
  void visitContinue(js_ast.Continue node) {
    var target = _analysis.targets[node];
    if (!_shouldTransform(target)) {
      _addStatement(node);
      return;
    }
    _translateJump(target, _continueLabels[target!], node.sourceInformation);
  }

  /// Emits a break statement that exits the big switch statement.
  void _addBreak(Object? sourceInformation) {
    if (insideUntranslatedBreakable) {
      hasJumpThoughOuterLabel = true;
      _addStatement(js_ast.Break(_outerLabelName)
          .withSourceInformation(sourceInformation));
    } else {
      _addStatement(
          js_ast.Break(null).withSourceInformation(sourceInformation));
    }
  }

  /// Common code for handling break, continue, return.
  ///
  /// It is necessary to run all nesting finally-handlers between the jump and
  /// the target. For that [_next] is used as a stack of places to go.
  ///
  /// See also [_rewriteFunction].
  void _translateJump(
      js_ast.Node? target, int? targetLabel, Object? sourceInformation) {
    // Compute a stack of all the 'finally' nodes that must be visited before
    // the jump.
    // The bottom of the stack is the label where the jump goes to.
    var jumpStack = <int>[];
    for (var node in _jumpTargets.reversed) {
      if (_finallyLabels[node] != null) {
        jumpStack.add(_finallyLabels[node]!);
      } else if (node == target) {
        jumpStack.add(targetLabel!);
        break;
      }
      // Ignore other nodes.
    }
    jumpStack = jumpStack.reversed.toList();
    // As the program jumps directly to the top of the stack, it is taken off
    // now.
    var firstTarget = jumpStack.removeLast();
    if (jumpStack.isNotEmpty) {
      var jsJumpStack = js_ast.ArrayInitializer(
          jumpStack.map((int label) => js_ast.number(label)).toList());
      _addStatement(js_ast.ExpressionStatement(js_ast.js('# = #',
          [_next, jsJumpStack]).withSourceInformation(sourceInformation)));
    }
    _addGoto(firstTarget, sourceInformation);
  }

  @override
  void visitDefault(js_ast.Default node) => _unreachable(node);

  @override
  void visitDo(js_ast.Do node) {
    if (!_shouldTransform(node)) {
      var oldInsideUntranslatedBreakable = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      _addStatement(js_ast.js.statement('do {#} while (#)',
          [_translateToStatement(node.body), visitExpression(node.condition)]));
      insideUntranslatedBreakable = oldInsideUntranslatedBreakable;
      return;
    }
    var startLabel = _newLabel('do body');

    var continueLabel = _newLabel('do condition');
    _continueLabels[node] = continueLabel;

    var afterLabel = _newLabel('after do');
    _breakLabels[node] = afterLabel;

    _beginLabel(startLabel);

    _jumpTargets.add(node);
    _visitStatement(node.body);
    _jumpTargets.removeLast();

    _beginLabel(continueLabel);
    _withExpression(node.condition, (js_ast.Expression condition) {
      _addStatement(js_ast.js.statement('if (#) #',
          [condition, _gotoAndBreak(startLabel, node.sourceInformation)]));
    }, store: false);
    _beginLabel(afterLabel);
  }

  @override
  void visitEmptyStatement(js_ast.EmptyStatement node) {
    _addStatement(node);
  }

  @override
  void visitExpressionStatement(js_ast.ExpressionStatement node) {
    _visitExpressionIgnoreResult(node.expression);
  }

  @override
  void visitFor(js_ast.For node) {
    if (!_shouldTransform(node)) {
      var oldInsideUntranslated = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;

      // Handle init specially as it might be a VariableDeclarationList.
      // These declarations should not be hoisted in an untransformed for loop.
      final init = node.init;
      js_ast.Expression? newInit;
      if (init is js_ast.VariableDeclarationList) {
        final newInitializationList = <js_ast.VariableInitialization>[];
        for (final initialization in init.declarations) {
          final value = initialization.value;
          newInitializationList.add(js_ast.VariableInitialization(
              initialization.declaration,
              value != null ? visitExpression(value) : null));
        }
        newInit =
            js_ast.VariableDeclarationList(init.keyword, newInitializationList);
      } else {
        newInit = init != null ? visitExpression(init) : null;
      }
      withNullableExpressions([node.condition, node.update],
          (List<js_ast.Expression?> transformed) {
        _addStatement(js_ast.For(newInit, transformed[0], transformed[1],
            _translateToStatement(node.body)));
      });
      insideUntranslatedBreakable = oldInsideUntranslated;
      return;
    }

    _resetScopeIfNecessary(node);
    if (node.init != null) {
      _visitExpressionIgnoreResult(node.init!);
    }
    var startLabel = _newLabel('for condition');
    // If there is no update, continuing the loop is the same as going to the
    // start.
    var continueLabel =
        (node.update == null) ? startLabel : _newLabel('for update');
    _continueLabels[node] = continueLabel;
    var afterLabel = _newLabel('after for');
    _breakLabels[node] = afterLabel;
    _beginLabel(startLabel);
    var condition = node.condition;
    if (condition == null ||
        (condition is js_ast.LiteralBool && condition.value == true)) {
      _addStatement(js_ast.Comment('trivial condition'));
    } else {
      _withExpression(condition, (js_ast.Expression condition) {
        _addStatement(js_ast.If.noElse(js_ast.Prefix('!', condition),
            _gotoAndBreak(afterLabel, node.sourceInformation)));
      }, store: false);
    }
    _jumpTargets.add(node);
    _visitStatement(node.body);
    _jumpTargets.removeLast();
    if (node.update != null) {
      _beginLabel(continueLabel);
      _visitExpressionIgnoreResult(node.update!);
    }
    _addGoto(startLabel, node.sourceInformation);
    _beginLabel(afterLabel);
  }

  @override
  void visitForIn(js_ast.ForIn node) {
    // The dart output currently never uses for-in loops.
    throw 'JavaScript for-in not implemented yet in the await transformation';
  }

  @override
  void visitFunctionDeclaration(js_ast.FunctionDeclaration node) {
    _withExpression(node.function, (js_ast.Expression function) {
      final name = visitExpression(node.name);
      _hoistIfNecessary(name);
      _addExpressionStatement(
          js_ast.Assignment(visitExpression(name), function));
    }, store: false);
  }

  List<js_ast.Statement> _translateToStatementSequence(js_ast.Statement node) {
    assert(!_shouldTransform(node));
    var oldBuffer = currentStatementBuffer;
    currentStatementBuffer = [];
    var resultBuffer = currentStatementBuffer;
    _visitStatement(node);
    currentStatementBuffer = oldBuffer;
    return resultBuffer;
  }

  js_ast.Statement _translateToStatement(js_ast.Statement node) {
    var statements = _translateToStatementSequence(node);
    if (statements.length == 1) return statements.single;
    return js_ast.Block(statements);
  }

  js_ast.Block translateToBlock(js_ast.Statement node) {
    return js_ast.Block(_translateToStatementSequence(node));
  }

  @override
  void visitIf(js_ast.If node) {
    if (!_shouldTransform(node.then) && !_shouldTransform(node.otherwise)) {
      _withExpression(node.condition, (js_ast.Expression condition) {
        var translatedThen = _translateToStatement(node.then);
        var translatedElse = _translateToStatement(node.otherwise);
        _addStatement(js_ast.If(condition, translatedThen, translatedElse));
      }, store: false);
      return;
    }
    var thenLabel = _newLabel('then');
    var joinLabel = _newLabel('join');
    var elseLabel = (node.otherwise is js_ast.EmptyStatement)
        ? joinLabel
        : _newLabel('else');

    _withExpression(node.condition, (js_ast.Expression condition) {
      _addExpressionStatement(js_ast.Assignment(
          _goto,
          js_ast.Conditional(
              condition, js_ast.number(thenLabel), js_ast.number(elseLabel))));
    }, store: false);
    _addBreak(node.sourceInformation);
    _beginLabel(thenLabel);
    _visitStatement(node.then);
    if (node.otherwise is! js_ast.EmptyStatement) {
      _addGoto(joinLabel, node.sourceInformation);
      _beginLabel(elseLabel);
      _visitStatement(node.otherwise);
    }
    _beginLabel(joinLabel);
  }

  @override
  Never visitInterpolatedExpression(js_ast.InterpolatedExpression node) {
    _unsupported(node);
  }

  @override
  Never visitInterpolatedLiteral(js_ast.InterpolatedLiteral node) {
    _unsupported(node);
  }

  @override
  Never visitInterpolatedParameter(js_ast.InterpolatedParameter node) {
    _unsupported(node);
  }

  @override
  Never visitInterpolatedSelector(js_ast.InterpolatedSelector node) {
    _unsupported(node);
  }

  @override
  Never visitInterpolatedStatement(js_ast.InterpolatedStatement node) {
    _unsupported(node);
  }

  @override
  void visitLabeledStatement(js_ast.LabeledStatement node) {
    if (!_shouldTransform(node)) {
      _addStatement(js_ast.LabeledStatement(
          node.label, _translateToStatement(node.body)));
      return;
    }
    // `continue label` is really continuing the nested loop.
    // This is set up in [PreTranslationAnalysis.visitContinue].
    // Here we only need a breakLabel:
    var breakLabel = _newLabel('break ${node.label}');
    _breakLabels[node] = breakLabel;

    _jumpTargets.add(node);
    _visitStatement(node.body);
    _jumpTargets.removeLast();
    _beginLabel(breakLabel);
  }

  @override
  js_ast.Expression visitLiteralBool(js_ast.LiteralBool node) => node;

  @override
  Never visitLiteralExpression(js_ast.LiteralExpression node) =>
      _unsupported(node);

  @override
  js_ast.Expression visitLiteralNull(js_ast.LiteralNull node) => node;

  @override
  js_ast.Expression visitLiteralNumber(js_ast.LiteralNumber node) => node;

  @override
  Never visitLiteralStatement(js_ast.LiteralStatement node) =>
      _unsupported(node);

  @override
  js_ast.Expression visitLiteralString(js_ast.LiteralString node) => node;

  @override
  Never visitNamedFunction(js_ast.NamedFunction node) {
    _unsupported(node);
  }

  @override
  js_ast.Expression visitNew(js_ast.New node) {
    var storeTarget = node.arguments.any(_shouldTransform);
    return withCallTargetExpression(node.target, (target) {
      return withExpressions(node.arguments,
          (List<js_ast.Expression> arguments) {
        return js_ast.New(target, arguments);
      });
    }, store: storeTarget, isCall: false);
  }

  @override
  js_ast.Expression visitObjectInitializer(js_ast.ObjectInitializer node) {
    return withExpressions(
        node.properties
            .map((js_ast.Property property) => property.value)
            .toList(), (List<js_ast.Expression> values) {
      var properties = List<js_ast.Property>.generate(values.length, (int i) {
        if (node.properties[i] is js_ast.Method) {
          return js_ast.Method(
              node.properties[i].name, values[i] as js_ast.Fun);
        }
        return js_ast.Property(node.properties[i].name, values[i]);
      });
      return js_ast.ObjectInitializer(properties);
    });
  }

  @override
  js_ast.Expression visitPostfix(js_ast.Postfix node) {
    if (node.op == '++' || node.op == '--') {
      var argument = node.argument;
      if (argument is js_ast.Identifier) {
        return js_ast.Postfix(node.op, visitExpression(argument));
      } else if (argument is js_ast.PropertyAccess) {
        return withExpression2(argument.receiver, argument.selector,
            (receiver, selector) {
          return js_ast.Postfix(
              node.op, js_ast.PropertyAccess(receiver, selector));
        });
      } else {
        throw 'Unexpected postfix ${node.op} '
            'operator argument ${node.argument}';
      }
    }
    return _withExpression(node.argument,
        (js_ast.Expression argument) => js_ast.Postfix(node.op, argument),
        store: false);
  }

  @override
  js_ast.Expression visitPrefix(js_ast.Prefix node) {
    if (node.op == '++' || node.op == '--') {
      var argument = node.argument;
      if (argument is js_ast.Identifier) {
        return js_ast.Prefix(node.op, visitExpression(argument));
      } else if (argument is js_ast.PropertyAccess) {
        return withExpression2(argument.receiver, argument.selector,
            (receiver, selector) {
          return js_ast.Prefix(
              node.op, js_ast.PropertyAccess(receiver, selector));
        });
      } else {
        throw 'Unexpected prefix ${node.op} operator '
            'argument ${node.argument}';
      }
    }
    return _withExpression(node.argument,
        (js_ast.Expression argument) => js_ast.Prefix(node.op, argument),
        store: false);
  }

  @override
  Never visitProgram(js_ast.Program node) => _unsupported(node);

  @override
  js_ast.Property visitProperty(js_ast.Property node) {
    assert(node.runtimeType == js_ast.Property);
    return _withExpression(node.value,
        (js_ast.Expression value) => js_ast.Property(node.name, value),
        store: false);
  }

  @override
  js_ast.Method visitMethod(js_ast.Method node) {
    return _withExpression(
        node.function,
        (js_ast.Expression value) =>
            js_ast.Method(node.name, value as js_ast.Fun),
        store: false);
  }

  @override
  js_ast.Expression visitRegExpLiteral(js_ast.RegExpLiteral node) => node;

  @override
  void visitReturn(js_ast.Return node) {
    var target = _analysis.targets[node];
    final expression = node.value;
    if (expression != null) {
      if (_isSyncStar || _isAsyncStar) {
        // Even though `return expr;` is not allowed in the dart sync* and
        // async*  code, the backend sometimes generates code like this, but
        // only when it is known that the 'expr' throws, and the return is just
        // to tell the JavaScript VM that the code won't continue here.
        // It is therefore interpreted as `expr; return;`
        _visitExpressionIgnoreResult(expression);
      } else {
        _withExpression(expression, (js_ast.Expression value) {
          _addStatement(js_ast.js
              .statement('# = #;', [_returnValue, value]).withSourceInformation(
                  node.sourceInformation));
        }, store: false);
      }
    }
    _translateJump(target, _exitLabel, node.sourceInformation);
  }

  @override
  void visitSwitch(js_ast.Switch node) {
    if (!_shouldTransform(node)) {
      // TODO(sra): If only the key has an await, translation can be simplified.
      var oldInsideUntranslated = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      _withExpression(node.key, (js_ast.Expression key) {
        var cases = node.cases.map((js_ast.SwitchClause clause) {
          if (clause is js_ast.Case) {
            return js_ast.Case(
                clause.expression, translateToBlock(clause.body));
          } else {
            return js_ast.Default(
                translateToBlock((clause as js_ast.Default).body));
          }
        }).toList();
        _addStatement(js_ast.Switch(key, cases));
      }, store: false);
      insideUntranslatedBreakable = oldInsideUntranslated;
      return;
    }
    var before = _newLabel('switch');
    var after = _newLabel('after switch');
    _breakLabels[node] = after;

    _beginLabel(before);
    var labels = List<int>.filled(node.cases.length, -1);

    var anyCaseExpressionTransformed = node.cases.any((js_ast.SwitchClause x) =>
        x is js_ast.Case && _shouldTransform(x.expression));
    if (anyCaseExpressionTransformed) {
      int? defaultIndex; // Null means no default was found.
      // If there is an await in one of the keys, a chain of ifs has to be used.

      _withExpression(node.key, (js_ast.Expression key) {
        var i = 0;
        for (var clause in node.cases) {
          if (clause is js_ast.Default) {
            // The goto for the default case is added after all non-default
            // clauses have been handled.
            defaultIndex = i;
            labels[i] = _newLabel('default');
            continue;
          } else if (clause is js_ast.Case) {
            labels[i] = _newLabel('case');
            _withExpression(clause.expression, (expression) {
              _addStatement(js_ast.If.noElse(
                  js_ast.Binary('===', key, expression),
                  _gotoAndBreak(labels[i], clause.sourceInformation)));
            }, store: false);
          }
          i++;
        }
      }, store: true);

      if (defaultIndex == null) {
        _addGoto(after, node.sourceInformation);
      } else {
        _addGoto(labels[defaultIndex!], node.sourceInformation);
      }
    } else {
      var hasDefault = false;
      var i = 0;
      var clauses = <js_ast.SwitchClause>[];
      for (var clause in node.cases) {
        if (clause is js_ast.Case) {
          labels[i] = _newLabel('case');
          clauses.add(js_ast.Case(visitExpression(clause.expression),
              _gotoAndBreak(labels[i], clause.sourceInformation)));
        } else if (clause is js_ast.Default) {
          labels[i] = _newLabel('default');
          clauses.add(js_ast.Default(
              _gotoAndBreak(labels[i], clause.sourceInformation)));
          hasDefault = true;
        } else {
          throw StateError('Unknown clause type $clause');
        }
        i++;
      }
      if (!hasDefault) {
        clauses
            .add(js_ast.Default(_gotoAndBreak(after, node.sourceInformation)));
      }
      _withExpression(node.key, (js_ast.Expression key) {
        _addStatement(js_ast.Switch(key, clauses));
      }, store: false);

      _addBreak(node.sourceInformation);
    }

    _jumpTargets.add(node);
    for (var i = 0; i < labels.length; i++) {
      _beginLabel(labels[i]);
      _visitStatement(node.cases[i].body);
    }
    _beginLabel(after);
    _jumpTargets.removeLast();
  }

  @override
  js_ast.Expression visitThis(js_ast.This node) => node;

  @override
  void visitThrow(js_ast.Throw node) {
    _withExpression(node.expression, (js_ast.Expression expression) {
      _addStatement(js_ast.Throw(expression)
          .withSourceInformation(node.sourceInformation));
    }, store: false);
  }

  void _setErrorHandler([int? errorHandler]) {
    _hasHandlerLabels = true; // TODO(sra): Add short form error handler.
    var label = (errorHandler == null)
        ? _currentErrorHandler
        : js_ast.number(errorHandler);
    _addStatement(js_ast.js.statement('# = #;', [_handler, label]));
  }

  List<int> _finalliesUpToAndEnclosingHandler() {
    var result = <int>[];
    for (var i = _jumpTargets.length - 1; i >= 0; i--) {
      var node = _jumpTargets[i];
      var handlerLabel = _handlerLabels[node];
      if (handlerLabel != null) {
        result.add(handlerLabel);
        break;
      }
      var finallyLabel = _finallyLabels[node];
      if (finallyLabel != null) {
        result.add(finallyLabel);
      }
    }
    return result.reversed.toList();
  }

  /// See the comments of [_rewriteFunction] for more explanation.
  @override
  void visitTry(js_ast.Try node) {
    final catchPart = node.catchPart;
    final finallyPart = node.finallyPart;

    if (!_shouldTransform(node)) {
      var body = translateToBlock(node.body);
      js_ast.Catch? translatedCatchPart;
      if (catchPart != null) {
        translatedCatchPart = js_ast.Catch(
            catchPart.declaration, translateToBlock(catchPart.body));
      }
      var translatedFinallyPart =
          (finallyPart == null) ? null : translateToBlock(finallyPart);
      _addStatement(
          js_ast.Try(body, translatedCatchPart, translatedFinallyPart));
      return;
    }

    hasTryBlocks = true;
    var uncaughtLabel = _newLabel('uncaught');
    var handlerLabel = (catchPart == null) ? uncaughtLabel : _newLabel('catch');

    var finallyLabel = _newLabel('finally');
    var afterFinallyLabel = _newLabel('after finally');
    if (finallyPart != null) {
      _finallyLabels[finallyPart] = finallyLabel;
      _jumpTargets.add(finallyPart);
    }

    _handlerLabels[node] = handlerLabel;
    _jumpTargets.add(node);

    // Set the error handler here. It must be cleared on every path out;
    // normal and error exit.
    _setErrorHandler();

    _visitStatement(node.body);

    var last = _jumpTargets.removeLast();
    assert(last == node);

    if (finallyPart == null) {
      _setErrorHandler();
      _addGoto(afterFinallyLabel, node.sourceInformation);
    } else {
      // The handler is reset as the first thing in the finally block.
      _addStatement(js_ast.js
          .statement('#.push(#);', [_next, js_ast.number(afterFinallyLabel)]));
      _addGoto(finallyLabel, node.sourceInformation);
    }

    if (catchPart != null) {
      _beginLabel(handlerLabel);
      // [uncaughtLabel] is the handler for the code in the catch-part.
      // It ensures that [nextName] is set up to run the right finally blocks.
      _handlerLabels[catchPart] = uncaughtLabel;
      _jumpTargets.add(catchPart);
      _setErrorHandler();
      // The catch declaration name can shadow outer variables, so a fresh name
      // is needed to avoid collisions.  See Ecma 262, 3rd edition,
      // section 12.14.
      var errorName = visitExpression(catchPart.declaration);
      _hoistIfNecessary(errorName);
      _addStatement(js_ast.js.statement('# = #;', [errorName, _currentError]));
      _visitStatement(catchPart.body);
      if (finallyPart != null) {
        // The error has been caught, so after the finally, continue after the
        // try.
        _addStatement(js_ast.js.statement(
            '#.push(#);', [_next, js_ast.number(afterFinallyLabel)]));
        _addGoto(finallyLabel, node.sourceInformation);
      } else {
        _addGoto(afterFinallyLabel, node.sourceInformation);
      }
      var last = _jumpTargets.removeLast();
      assert(last == catchPart);
    }

    // The "uncaught"-handler tells the finally-block to continue with
    // the enclosing finally-blocks until the current catch-handler.
    _beginLabel(uncaughtLabel);

    var enclosingFinallies = _finalliesUpToAndEnclosingHandler();

    var nextLabel = enclosingFinallies.removeLast();
    if (enclosingFinallies.isNotEmpty) {
      // [enclosingFinallies] can be empty if there is no surrounding finally
      // blocks. Then [nextLabel] will be [rethrowLabel].
      _addStatement(js_ast.js.statement('# = #;', [
        _next,
        js_ast.ArrayInitializer(enclosingFinallies.map(js_ast.number).toList())
      ]));
    }
    if (finallyPart == null) {
      // The finally-block belonging to [node] will be visited because of
      // fallthrough. If it does not exist, add an explicit goto.
      _addGoto(nextLabel, node.sourceInformation);
    }
    if (finallyPart != null) {
      var last = _jumpTargets.removeLast();
      assert(last == finallyPart);

      _beginLabel(finallyLabel);
      _setErrorHandler();
      _visitStatement(finallyPart);
      _addStatement(js_ast.Comment('// goto the next finally handler'));
      _addStatement(js_ast.js.statement('# = #.pop();', [_goto, _next]));
      _addBreak(node.sourceInformation);
    }
    _beginLabel(afterFinallyLabel);
  }

  @override
  js_ast.Expression visitVariableDeclarationList(
      js_ast.VariableDeclarationList node) {
    for (final initialization in node.declarations) {
      var declaration = visitExpression(initialization.declaration);
      _hoistIfNecessary(declaration);
      if (initialization.value != null) {
        _withExpression(initialization.value!, (js_ast.Expression value) {
          _addExpressionStatement(
              js_ast.Assignment(declaration, value)
                ..sourceInformation = initialization.sourceInformation,
              node.sourceInformation);
        }, store: false);
      }
    }
    return js_ast.number(0); // Dummy expression.
  }

  @override
  void visitVariableInitialization(js_ast.VariableInitialization node) {
    _unreachable(node);
  }

  @override
  js_ast.Expression visitIdentifier(js_ast.Identifier node) {
    return _scopeCollector.transformIdentifier(node);
  }

  @override
  void visitWhile(js_ast.While node) {
    if (!_shouldTransform(node)) {
      var oldInsideUntranslated = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      _withExpression(node.condition, (js_ast.Expression condition) {
        _addStatement(js_ast.While(condition, _translateToStatement(node.body))
            .withSourceInformation(node.sourceInformation));
      }, store: false);
      insideUntranslatedBreakable = oldInsideUntranslated;
      return;
    }
    var continueLabel = _newLabel('while condition');
    _continueLabels[node] = continueLabel;
    _beginLabel(continueLabel);

    var afterLabel = _newLabel('after while');
    _breakLabels[node] = afterLabel;
    var condition = node.condition;
    // If the condition is `true`, a test is not needed.
    if (!(condition is js_ast.LiteralBool && condition.value == true)) {
      _withExpression(node.condition, (js_ast.Expression condition) {
        _addStatement(js_ast.If.noElse(js_ast.Prefix('!', condition),
                _gotoAndBreak(afterLabel, node.sourceInformation))
            .withSourceInformation(node.sourceInformation));
      }, store: false);
    }
    _jumpTargets.add(node);
    _visitStatement(node.body);
    _jumpTargets.removeLast();
    _addGoto(continueLabel, node.sourceInformation);
    _beginLabel(afterLabel);
  }

  void addYield(js_ast.DartYield node, js_ast.Expression expression,
      Object? sourceInformation);

  @override
  void visitDartYield(js_ast.DartYield node) {
    assert(_isSyncStar || _isAsyncStar);
    var label = _newLabel('after yield');
    // Don't do a break here for the goto, but instead a return in either
    // addSynYield or addAsyncYield.
    _withExpression(node.expression, (js_ast.Expression expression) {
      _addStatement(_setGotoVariable(label, node.sourceInformation));
      addYield(node, expression, node.sourceInformation);
    }, store: false);
    _beginLabel(label);
  }

  @override
  void visitForOf(js_ast.ForOf node) {
    if (!_shouldTransform(node)) {
      var oldInsideUntranslated = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      _addStatement(js_ast.ForOf(node.leftHandSide,
          visitExpression(node.iterable), _translateToStatement(node.body)));
      insideUntranslatedBreakable = oldInsideUntranslated;
      return;
    }

    _visitExpressionIgnoreResult(node.leftHandSide);
    final loopVar = visitExpression(
        (node.leftHandSide as js_ast.VariableDeclarationList)
            .declarations
            .first
            .declaration);

    final valueWrapperVar = TemporaryId('t\$wrappedValue');
    final iteratorVar = TemporaryId('t\$iterator');
    _localVariables.add(valueWrapperVar);
    _localVariables.add(iteratorVar);

    // Get the iterator object for the iterable expresion.
    _withExpression(node.iterable, (js_ast.Expression iterable) {
      _addExpressionStatement(js_ast.Assignment(
          iteratorVar,
          js_ast.js('#[Symbol.iterator]()', [iterable])
            ..sourceInformation = node.iterable.sourceInformation));
    }, store: false);

    var continueLabel = _newLabel('for-of iterator update');
    _continueLabels[node] = continueLabel;

    var afterLabel = _newLabel('after for-of');
    _breakLabels[node] = afterLabel;

    // At the start of each loop step:
    // 1) Move the iterator forward.
    // 2) Check if the current value is marked as done.
    // 3a) If no: assign the value to the loop variable and execute the body.
    // 3b) If yes: jump to after the loop body.
    _beginLabel(continueLabel);
    _resetScopeIfNecessary(node);
    _addExpressionStatement(js_ast.Assignment(
        valueWrapperVar, js_ast.js('#.next()', [iteratorVar])));
    _addStatement(js_ast.If.noElse(js_ast.js('#.done', [valueWrapperVar]),
        _gotoAndBreak(afterLabel, node.sourceInformation)));
    _addExpressionStatement(
        js_ast.Assignment(loopVar, js_ast.js('#.value', [valueWrapperVar])));
    _jumpTargets.add(node);
    _visitStatement(node.body);
    _jumpTargets.removeLast();

    _addGoto(continueLabel, node.sourceInformation);
    _beginLabel(afterLabel);
  }

  @override
  js_ast.ArrayBindingPattern visitArrayBindingPattern(
          js_ast.ArrayBindingPattern node) =>
      node;

  @override
  Never visitClassDeclaration(js_ast.ClassDeclaration node) =>
      _unreachable(node);

  @override
  Never visitClassExpression(js_ast.ClassExpression node) => _unreachable(node);

  @override
  js_ast.CommentExpression visitCommentExpression(
          js_ast.CommentExpression node) =>
      node;

  @override
  js_ast.DebuggerStatement visitDebuggerStatement(
          js_ast.DebuggerStatement node) =>
      node;

  @override
  js_ast.DestructuredVariable visitDestructuredVariable(
          js_ast.DestructuredVariable node) =>
      node;

  @override
  Never visitExportClause(js_ast.ExportClause node) => _unreachable(node);

  @override
  Never visitExportDeclaration(js_ast.ExportDeclaration node) =>
      _unreachable(node);

  @override
  Never visitImportDeclaration(js_ast.ImportDeclaration node) =>
      _unreachable(node);

  @override
  js_ast.InterpolatedIdentifier visitInterpolatedIdentifier(
          js_ast.InterpolatedIdentifier node) =>
      node;

  @override
  js_ast.InterpolatedMethod visitInterpolatedMethod(
          js_ast.InterpolatedMethod node) =>
      node;

  @override
  Never visitNameSpecifier(js_ast.NameSpecifier node) => _unreachable(node);

  @override
  js_ast.ObjectBindingPattern visitObjectBindingPattern(
          js_ast.ObjectBindingPattern node) =>
      node;

  @override
  js_ast.RestParameter visitRestParameter(js_ast.RestParameter node) => node;

  @override
  js_ast.SimpleBindingPattern visitSimpleBindingPattern(
          js_ast.SimpleBindingPattern node) =>
      node;

  @override
  js_ast.Spread visitSpread(js_ast.Spread node) => node;

  @override
  js_ast.Super visitSuper(js_ast.Super node) => node;

  @override
  js_ast.TaggedTemplate visitTaggedTemplate(js_ast.TaggedTemplate node) => node;

  @override
  js_ast.TemplateString visitTemplateString(js_ast.TemplateString node) => node;

  @override
  Never visitYield(js_ast.Yield node) => _unreachable(node);
}

js_ast.VariableInitialization _makeVariableInitializer(
    js_ast.Identifier variable,
    js_ast.Expression? initValue,
    Object? sourceInformation) {
  return js_ast.VariableInitialization(variable, initValue)
          .withSourceInformation(sourceInformation)
      as js_ast.VariableInitialization;
}

class AsyncRewriter extends AsyncRewriterBase {
  @override
  bool get _isAsync => true;

  /// The Completer that will finish an async function.
  ///
  /// Not used for sync* or async* functions.
  late final js_ast.Identifier completer = TemporaryId('t\$completer');

  /// The function called by an async function to initiate asynchronous
  /// execution of the body.  This is called with:
  ///
  /// - The body function [bodyName].
  /// - the completer object [completer].
  ///
  /// It returns the completer's future. Passing the completer and returning its
  /// future is a convenience to allow both the initiation and fetching the
  /// future to be compactly encoded in a return statement's expression.
  final js_ast.Expression asyncStart;

  /// Function called by the async function to simulate an `await`
  /// expression. It is called with:
  ///
  /// - The value to await
  /// - The body function [bodyName]
  final js_ast.Expression asyncAwait;

  /// Function called by the async function to simulate a return.
  /// It is called with:
  ///
  /// - The value to return
  /// - The completer object [completer]
  final js_ast.Expression asyncReturn;

  /// Function called by the async function to simulate a rethrow.
  /// It is called with:
  ///
  /// - The value containing the exception and stack
  /// - The completer object [completer]
  final js_ast.Expression asyncRethrow;

  /// Constructor used to initialize the [completer] variable.
  ///
  /// Specific to async methods.
  final js_ast.Expression completerFactory;
  final List<js_ast.Expression> completerFactoryTypeArguments;

  final js_ast.Expression wrapBody;

  AsyncRewriter(
      {required this.asyncStart,
      required this.asyncAwait,
      required this.asyncReturn,
      required this.asyncRethrow,
      required this.completerFactory,
      required this.completerFactoryTypeArguments,
      required this.wrapBody,
      required super.bodyName});

  @override
  void addYield(js_ast.DartYield node, js_ast.Expression expression,
      Object? sourceInformation) {
    throw StateError('Yield in non-generating async function');
  }

  @override
  void addErrorExit(Object? sourceInformation) {
    if (!_hasHandlerLabels) return; // rethrow handled in method boilerplate.
    _beginLabel(_rethrowLabel);
    var thenHelperCall = js_ast.js('#thenHelper(#currentError, #completer)', {
      'thenHelper': asyncRethrow,
      'currentError': _currentError,
      'completer': completer
    }).withSourceInformation(sourceInformation);
    _addStatement(
        js_ast.Return(thenHelperCall).withSourceInformation(sourceInformation));
  }

  /// Returning from an async method calls [asyncStarHelper] with the result.
  /// (the result might have been stored in [_returnValue] by some finally
  /// block).
  @override
  void addSuccessExit(Object? sourceInformation) {
    if (_analysis.hasExplicitReturns) {
      _beginLabel(_exitLabel);
    } else {
      _addStatement(js_ast.Comment('implicit return'));
    }

    var runtimeHelperCall =
        js_ast.js('#runtimeHelper(#returnValue, #completer)', {
      'runtimeHelper': asyncReturn,
      'returnValue':
          _analysis.hasExplicitReturns ? _returnValue : js_ast.LiteralNull(),
      'completer': completer
    }).withSourceInformation(sourceInformation);
    _addStatement(js_ast.Return(runtimeHelperCall)
        .withSourceInformation(sourceInformation));
  }

  @override
  Iterable<js_ast.VariableInitialization> variableInitializations(
      Object? sourceInformation) {
    var variables = <js_ast.VariableInitialization>[];
    variables.add(_makeVariableInitializer(
        completer,
        js_ast.js('#(#)', [
          completerFactory,
          completerFactoryTypeArguments
        ]).withSourceInformation(sourceInformation),
        sourceInformation));
    if (_analysis.hasExplicitReturns) {
      variables
          .add(_makeVariableInitializer(_returnValue, null, sourceInformation));
    }
    return variables;
  }

  @override
  js_ast.Statement awaitStatement(
      js_ast.Expression value, Object? sourceInformation) {
    var asyncHelperCall =
        js_ast.js('#asyncHelper(#value, #bodyName, #completer)', {
      'asyncHelper': asyncAwait,
      'value': value,
      'bodyName': bodyName,
      'completer': completer,
    }).withSourceInformation(sourceInformation);
    return js_ast.Return(asyncHelperCall)
        .withSourceInformation(sourceInformation);
  }

  @override
  js_ast.Fun _finishFunction(
      List<js_ast.Parameter> parameters,
      js_ast.Statement rewrittenBody,
      js_ast.VariableDeclarationList variableDeclarationLists,
      Object? functionSourceInformation,
      Object? bodySourceInformation) {
    js_ast.Statement errorCheck;
    if (_hasHandlerLabels) {
      errorCheck = js_ast.js.statement('''
            if (#errorCode === #ERROR) {
              #currentError = #result;
              #goto = #handler;
            }''', {
        'errorCode': _errorCode,
        'ERROR': js_ast.number(status_codes.ERROR),
        'currentError': _currentError,
        'result': _result,
        'goto': _goto,
        'handler': _handler,
      });
    } else {
      var asyncRethrowCall = js_ast.js('#asyncRethrow(#result, #completer)', {
        'result': _result,
        'asyncRethrow': asyncRethrow,
        'completer': completer,
      });
      var returnAsyncRethrow = js_ast.Return(asyncRethrowCall);
      errorCheck = js_ast.js.statement('''
            if (#errorCode === #ERROR)
              #returnAsyncRethrow;
            ''', {
        'errorCode': _errorCode,
        'ERROR': js_ast.number(status_codes.ERROR),
        'returnAsyncRethrow': returnAsyncRethrow,
      });
    }

    // Use an arrow function so that we can access 'this' from the outer scope.
    var innerFunction = js_ast.js('''
      (#errorCode, #result) => {
        #errorCheck;
        #rewrittenBody;
      }''', {
      'errorCode': _errorCode,
      'result': _result,
      'errorCheck': errorCheck,
      'rewrittenBody': rewrittenBody,
    }).withSourceInformation(bodySourceInformation);
    var asyncStartCall = js_ast.js('#asyncStart(#bodyName, #completer)', {
      'asyncStart': asyncStart,
      'bodyName': bodyName,
      'completer': completer,
    }).withSourceInformation(bodySourceInformation);
    var returnAsyncStart = js_ast.Return(asyncStartCall);
    var wrapBodyCall = js_ast.js('#wrapBody(#innerFunction)', {
      'wrapBody': wrapBody,
      'innerFunction': innerFunction,
    }).withSourceInformation(bodySourceInformation);
    return (js_ast.js('''
        function (#parameters) {
          #variableDeclarationLists;
          var #bodyName = #wrapBodyCall;
          #returnAsyncStart;
        }''', {
      'parameters': parameters,
      'variableDeclarationLists': variableDeclarationLists,
      'bodyName': bodyName,
      'wrapBodyCall': wrapBodyCall,
      'returnAsyncStart': returnAsyncStart,
    }).withSourceInformation(functionSourceInformation)) as js_ast.Fun;
  }
}

class SyncStarRewriter extends AsyncRewriterBase {
  @override
  bool get _isSyncStar => true;

  /// A parameter to the [bodyName] function that passes the controlling
  /// `_SyncStarIterator`. This parameter is used to update the state of the
  /// iterator.
  late final js_ast.Identifier iterator = TemporaryId('t\$iterator');

  /// Static method to create a sync star iterable.
  final js_ast.Expression makeSyncStarIterable;

  /// The type argument expression to instantiate the sync star iterable.
  final js_ast.Expression syncStarIterableTypeArgument;

  /// Property of the iterator that contains the current value.
  final js_ast.Expression iteratorCurrentValueProperty;

  /// Property of the iterator that contains the uncaught exeception.
  final js_ast.Expression iteratorDatumProperty;

  /// Property of the iterator that is bound to the `_yieldStar` method.
  final js_ast.Expression yieldStarSelector;

  SyncStarRewriter(
      {required this.makeSyncStarIterable,
      required this.syncStarIterableTypeArgument,
      required this.iteratorCurrentValueProperty,
      required this.iteratorDatumProperty,
      required this.yieldStarSelector,
      required super.bodyName});

  /// Translates a yield/yield* in an sync*.
  @override
  void addYield(js_ast.DartYield node, js_ast.Expression expression,
      Object? sourceInformation) {
    if (node.hasStar) {
      // ``yield* expression` is translated to:
      //
      //     return $iterator._yieldStar(expression);
      //
      // The `_yieldStar` method updates the state of the Iterator to 'enter'
      // the expression and returns the SYNC_STAR_YIELD_STAR status code.
      _addStatement(js_ast.Return(js_ast.Call(
              js_ast.PropertyAccess(iterator, yieldStarSelector),
              [expression]).withSourceInformation(sourceInformation))
          .withSourceInformation(sourceInformation));
    } else {
      // `yield expression` is translated to:
      //
      //     return $iterator._current = expression, SYNC_STAR_YIELD;
      //
      // This sets the `_current` field of the Iterator and returns the
      // SYNC_STAR_YIELD status code.
      final store = js_ast.Assignment(
          js_ast.PropertyAccess(iterator, iteratorCurrentValueProperty),
          expression);
      _addStatement(js_ast.Return(js_ast.Binary(
              ',', store, js_ast.number(status_codes.SYNC_STAR_YIELD)))
          .withSourceInformation(sourceInformation));
    }
  }

  @override
  js_ast.Fun _finishFunction(
      List<js_ast.Parameter> parameters,
      js_ast.Statement rewrittenBody,
      js_ast.VariableDeclarationList variableDeclarationLists,
      Object? functionSourceInformation,
      Object? bodySourceInformation) {
    // Each iterator invocation on the iterable should work on its own copy of
    // the parameters. Since parameter initialization code at the start of the
    // function may reference the original parameter names, we create an alias
    // for each parameter. Then in the async body we shadow each parameter with
    // a copy of that alias so each iteration of the body works on it's own
    // version of the parameter in case of modification.
    var outerDeclarationsList = <js_ast.VariableInitialization>[];
    var innerDeclarationsList = <js_ast.VariableInitialization>[];
    for (var parameter in parameters) {
      final name = parameter.parameterName;
      final renamedIdentifier = TemporaryId(name);
      final parameterRef =
          parameter is TemporaryId ? parameter : js_ast.Identifier(name);
      innerDeclarationsList
          .add(js_ast.VariableInitialization(parameterRef, renamedIdentifier));
      outerDeclarationsList
          .add(js_ast.VariableInitialization(renamedIdentifier, parameterRef));
    }
    var outerDeclarations =
        js_ast.VariableDeclarationList('let', outerDeclarationsList);
    var innerDeclarations =
        js_ast.VariableDeclarationList('let', innerDeclarationsList);

    var setCurrentError = js_ast.js('#currentError = #result', {
      'result': _result,
      'currentError': _currentError,
    });
    var setGoto = js_ast.js('#goto = #handler', {
      'goto': _goto,
      'handler': _handler,
    });
    var checkErrorCode = js_ast.js.statement('''
          if (#errorCode === #ERROR) {
              #setCurrentError;
              #setGoto;
          }''', {
      'errorCode': _errorCode,
      'ERROR': js_ast.number(status_codes.ERROR),
      'setCurrentError': setCurrentError,
      'setGoto': setGoto,
    });
    // Use an arrow function so that we can access 'this' from the outer scope.
    var innerInnerFunction = js_ast.js('''
          (#iterator, #errorCode, #result) => {
            #checkErrorCode;
            #helperBody;
          }''', {
      'helperBody': rewrittenBody,
      'errorCode': _errorCode,
      'iterator': iterator,
      'result': _result,
      'checkErrorCode': checkErrorCode,
    });
    var returnInnerInnerFunction = js_ast.Return(innerInnerFunction);
    // Use an arrow function so that we can access 'this' from the outer scope.
    var innerInnerFunctionInvocation = js_ast.js('''
          #makeSyncStarIterable(#iterableType, () => {
            if (#hasParameters) {
              #innerDeclarations;
            }
            #varDecl;
            #returnInnerInnerFunction;
          })''', {
      'hasParameters': parameters.isNotEmpty,
      'innerDeclarations': innerDeclarations,
      'varDecl': variableDeclarationLists,
      'returnInnerInnerFunction': returnInnerInnerFunction,
      'makeSyncStarIterable': makeSyncStarIterable,
      'iterableType': syncStarIterableTypeArgument,
    });
    var returnInnerFunction = js_ast.Return(innerInnerFunctionInvocation);
    // Add the copied parameter declarations outside the inner function in case
    // one is a type parameter that gets passed to the inner function.
    return (js_ast.js('''
          function (#parameters) {
            if (#hasParameters) {
              #outerDeclarations;
            }
            #returnInnerFunction;
          }
          ''', {
      'hasParameters': parameters.isNotEmpty,
      'outerDeclarations': outerDeclarations,
      'parameters': parameters,
      'returnInnerFunction': returnInnerFunction,
    }).withSourceInformation(functionSourceInformation)) as js_ast.Fun;
  }

  @override
  void addErrorExit(Object? sourceInformation) {
    _hasHandlerLabels = true; // TODO(sra): Add short form error handler.
    _beginLabel(_rethrowLabel);
    // Unguarded rethrow is translated to:
    //
    //     return $iterator._datum = exception, SYNC_STAR_UNCAUGHT_EXCEPTION;
    //
    // This stashes the exception on the Iterator and returns the
    // SYNC_STAR_UNCAUGHT_EXCEPTION status code.
    final store = js_ast.Assignment(
        js_ast.PropertyAccess(iterator, iteratorDatumProperty), _currentError);
    _addStatement(js_ast.Return(js_ast.Binary(',', store,
            js_ast.number(status_codes.SYNC_STAR_UNCAUGHT_EXCEPTION)))
        .withSourceInformation(sourceInformation));
  }

  /// Returning from a sync* function returns the SYNC_STAR_DONE status code.
  @override
  void addSuccessExit(Object? sourceInformation) {
    if (_analysis.hasExplicitReturns) {
      _beginLabel(_exitLabel);
    } else {
      _addStatement(js_ast.Comment('implicit return'));
    }
    _addStatement(js_ast.Return(js_ast.number(status_codes.SYNC_STAR_DONE))
        .withSourceInformation(sourceInformation));
  }

  @override
  Iterable<js_ast.VariableInitialization> variableInitializations(
      Object? sourceInformation) {
    var variables = <js_ast.VariableInitialization>[];
    return variables;
  }

  @override
  js_ast.Statement awaitStatement(
      js_ast.Expression value, Object? sourceInformation) {
    throw StateError('Sync* functions cannot contain await statements.');
  }
}

class AsyncStarRewriter extends AsyncRewriterBase {
  @override
  bool get _isAsyncStar => true;

  /// The stack of labels of finally blocks to assign to [_next] if the
  /// async* [StreamSubscription] was canceled during a yield.
  late final js_ast.Identifier nextWhenCanceled =
      TemporaryId('t\$nextWhenCanceled');

  /// The StreamController that controls an async* function.
  late final js_ast.Identifier controller = TemporaryId('t\$controller');

  /// The function called by an async* function to simulate an await, yield or
  /// yield*.
  ///
  /// For an await/yield/yield* it is called with:
  ///
  /// - The value to await/yieldExpression(value to yield)/
  /// yieldStarExpression(stream to yield)
  /// - The body function [bodyName]
  /// - The controller object [controller]
  ///
  /// For a return it is called with:
  ///
  /// - null
  /// - null
  /// - The [controller]
  /// - null.
  final js_ast.Expression asyncStarHelper;

  /// Constructor used to initialize the [controller] variable.
  ///
  /// Specific to async* methods.
  final js_ast.Expression newController;
  List<js_ast.Expression> newControllerTypeArguments;

  /// Used to get the `Stream` out of the [controllerName] variable.
  final js_ast.Expression streamOfController;

  /// A JS Expression that creates a marker indicating a 'yield' statement.
  ///
  /// Called with the value to yield.
  final js_ast.Expression yieldExpression;

  /// A JS Expression that creates a marker indication a 'yield*' statement.
  ///
  /// Called with the stream to yield from.
  final js_ast.Expression yieldStarExpression;

  final js_ast.Expression wrapBody;

  AsyncStarRewriter(
      {required this.asyncStarHelper,
      required this.streamOfController,
      required this.newController,
      required this.newControllerTypeArguments,
      required this.yieldExpression,
      required this.yieldStarExpression,
      required this.wrapBody,
      required super.bodyName});

  /// Translates a yield/yield* in an async* function.
  ///
  /// yield/yield* in an async* function is translated much like the `await` is
  /// translated in [visitAwait], only the object is wrapped in a
  /// [yieldExpression]/[yieldStarExpression] to let [asyncStarHelper]
  /// distinguish them.
  /// Also [nextWhenCanceled] is set up to contain the finally blocks that
  /// must be run in case the stream was canceled.
  @override
  void addYield(js_ast.DartYield node, js_ast.Expression expression,
      Object? sourceInformation) {
    // Find all the finally blocks that should be performed if the stream is
    // canceled during the yield.
    var enclosingFinallyLabels = <int>[
      // At the bottom of the stack is the return label.
      _exitLabel,
      for (final node in _jumpTargets)
        if (_finallyLabels[node] != null) _finallyLabels[node]!
    ];

    _addStatement(js_ast.js.statement('# = #;', [
      nextWhenCanceled,
      js_ast.ArrayInitializer(
          enclosingFinallyLabels.map(js_ast.number).toList())
    ]).withSourceInformation(sourceInformation));
    var yieldExpressionCall = js_ast.js('#yieldExpression(#expression)', {
      'yieldExpression': node.hasStar ? yieldStarExpression : yieldExpression,
      'expression': expression,
    }).withSourceInformation(sourceInformation);
    var asyncStarHelperCall = js_ast
        .js('#asyncStarHelper(#yieldExpressionCall, #bodyName, #controller)', {
      'asyncStarHelper': asyncStarHelper,
      'yieldExpressionCall': yieldExpressionCall,
      'bodyName': bodyName,
      'controller': controller,
    }).withSourceInformation(sourceInformation);
    _addStatement(js_ast.Return(asyncStarHelperCall)
        .withSourceInformation(sourceInformation));
  }

  @override
  js_ast.Fun _finishFunction(
      List<js_ast.Parameter> parameters,
      js_ast.Statement rewrittenBody,
      js_ast.VariableDeclarationList variableDeclarationLists,
      Object? functionSourceInformation,
      Object? bodySourceInformation) {
    var updateNext = js_ast.js('#next = #nextWhenCanceled', {
      'next': _next,
      'nextWhenCanceled': nextWhenCanceled,
    });
    var callPop = js_ast.js('#next.pop()', {
      'next': _next,
    });
    var gotoCancelled = js_ast.js('#goto = #callPop', {
      'goto': _goto,
      'callPop': callPop,
    });
    var updateError = js_ast.js('#currentError = #result', {
      'currentError': _currentError,
      'result': _result,
    });
    var gotoError = js_ast.js('#goto = #handler', {
      'goto': _goto,
      'handler': _handler,
    });
    var breakStatement = js_ast.Break(null);
    var switchCase = js_ast.js.statement('''
        switch (#errorCode) {
          case #STREAM_WAS_CANCELED:
            #updateNext;
            #gotoCancelled;
            #break;
          case #ERROR:
            #updateError;
            #gotoError;
        }''', {
      'errorCode': _errorCode,
      'STREAM_WAS_CANCELED': js_ast.number(status_codes.STREAM_WAS_CANCELED),
      'updateNext': updateNext,
      'gotoCancelled': gotoCancelled,
      'break': breakStatement,
      'ERROR': js_ast.number(status_codes.ERROR),
      'updateError': updateError,
      'gotoError': gotoError,
    });
    var ifError = js_ast.js.statement('''
        if (#errorCode === #ERROR) {
          #updateError;
          #gotoError;
        }''', {
      'errorCode': _errorCode,
      'ERROR': js_ast.number(status_codes.ERROR),
      'updateError': updateError,
      'gotoError': gotoError,
    });
    var ifHasYield = js_ast.js.statement('''
        if (#hasYield) {
          #switchCase
        } else {
          #ifError;
        }
    ''', {
      'hasYield': _analysis.hasYield,
      'switchCase': switchCase,
      'ifError': ifError,
    });
    // Use an arrow function so that we can access 'this' from the outer scope.
    var innerFunction = js_ast.js('''
        (#errorCode, #result) => {
          #ifHasYield;
          #rewrittenBody;
        }''', {
      'errorCode': _errorCode,
      'result': _result,
      'ifHasYield': ifHasYield,
      'rewrittenBody': rewrittenBody,
    }).withSourceInformation(functionSourceInformation);
    var wrapBodyCall = js_ast.js('#wrapBody(#innerFunction)', {
      'wrapBody': wrapBody,
      'innerFunction': innerFunction,
    }).withSourceInformation(bodySourceInformation);
    var declareBodyName =
        js_ast.js.statement('var #bodyName = #wrapBodyCall;', {
      'bodyName': bodyName,
      'wrapBodyCall': wrapBodyCall,
    });
    var streamOfControllerCall = js_ast.js('#streamOfController(#controller)', {
      'streamOfController': streamOfController,
      'controller': controller,
    });
    var returnStreamOfControllerCall = js_ast.Return(streamOfControllerCall);
    return (js_ast.js('''
        function (#parameters) {
          #declareBodyName;
          #variableDeclarationLists;
          #returnStreamOfControllerCall;
        }''', {
      'parameters': parameters,
      'declareBodyName': declareBodyName,
      'variableDeclarationLists': variableDeclarationLists,
      'returnStreamOfControllerCall': returnStreamOfControllerCall,
    }).withSourceInformation(functionSourceInformation)) as js_ast.Fun;
  }

  @override
  void addErrorExit(Object? sourceInformation) {
    _hasHandlerLabels = true;
    _beginLabel(_rethrowLabel);
    var asyncHelperCall =
        js_ast.js('#asyncHelper(#currentError, #errorCode, #controller)', {
      'asyncHelper': asyncStarHelper,
      'errorCode': js_ast.number(status_codes.ERROR),
      'currentError': _currentError,
      'controller': controller
    }).withSourceInformation(sourceInformation);
    _addStatement(js_ast.Return(asyncHelperCall)
        .withSourceInformation(sourceInformation));
  }

  /// Returning from an async* function calls the [streamHelper] with an
  /// [endOfIteration] marker.
  @override
  void addSuccessExit(Object? sourceInformation) {
    _beginLabel(_exitLabel);

    var streamHelperCall =
        js_ast.js('#streamHelper(null, #successCode, #controller)', {
      'streamHelper': asyncStarHelper,
      'successCode': js_ast.number(status_codes.SUCCESS),
      'controller': controller
    }).withSourceInformation(sourceInformation);
    _addStatement(js_ast.Return(streamHelperCall)
        .withSourceInformation(sourceInformation));
  }

  @override
  Iterable<js_ast.VariableInitialization> variableInitializations(
      Object? sourceInformation) {
    var variables = <js_ast.VariableInitialization>[];
    variables.add(_makeVariableInitializer(
        controller,
        js_ast.js('#(#, #)', [
          newController,
          newControllerTypeArguments,
          bodyName
        ]).withSourceInformation(sourceInformation),
        sourceInformation));
    if (_analysis.hasYield) {
      variables.add(
          _makeVariableInitializer(nextWhenCanceled, null, sourceInformation));
    }
    return variables;
  }

  @override
  js_ast.Statement awaitStatement(
      js_ast.Expression value, Object? sourceInformation) {
    var asyncHelperCall =
        js_ast.js('#asyncHelper(#value, #bodyName, #controller)', {
      'asyncHelper': asyncStarHelper,
      'value': value,
      'bodyName': bodyName,
      'controller': controller
    }).withSourceInformation(sourceInformation);
    return js_ast.Return(asyncHelperCall)
        .withSourceInformation(sourceInformation);
  }
}

/// Finds out
///
/// - which expressions have yield or await nested in them.
/// - targets of jumps
/// - a set of used label names.
class PreTranslationAnalysis extends js_ast.NodeVisitor<bool> {
  final Set<js_ast.Node> hasAwaitOrYield = {};
  final Map<js_ast.Node, js_ast.Node> targets = {};
  final List<js_ast.Node> loopsAndSwitches = [];
  final List<js_ast.LabeledStatement> labelledStatements = [];
  final Set<String> usedLabelNames = {};

  bool hasExplicitReturns = false;

  bool hasYield = false;

  bool hasFinally = false;

  // The function currently being analyzed.
  final js_ast.FunctionExpression currentFunction;

  // For error messages.
  final Never Function(js_ast.Node) unsupported;

  PreTranslationAnalysis(this.unsupported, this.currentFunction);

  bool visit(js_ast.Node node) {
    var containsAwait = node.accept(this);
    if (containsAwait) {
      hasAwaitOrYield.add(node);
    }
    return containsAwait;
  }

  void analyze() {
    currentFunction.params.forEach(visit);
    visit(currentFunction.body);
  }

  @override
  bool visitAccess(js_ast.PropertyAccess node) {
    var receiver = visit(node.receiver);
    var selector = visit(node.selector);
    return receiver || selector;
  }

  @override
  bool visitArrayHole(js_ast.ArrayHole node) {
    return false;
  }

  @override
  bool visitArrayInitializer(js_ast.ArrayInitializer node) {
    var containsAwait = false;
    for (var element in node.elements) {
      if (visit(element)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitAssignment(js_ast.Assignment node) {
    var leftHandSide = visit(node.leftHandSide);
    var value = visit(node.value);
    return leftHandSide || value;
  }

  @override
  bool visitAwait(js_ast.Await node) {
    visit(node.expression);
    return true;
  }

  @override
  bool visitBinary(js_ast.Binary node) {
    var left = visit(node.left);
    var right = visit(node.right);
    return left || right;
  }

  @override
  bool visitBlock(js_ast.Block node) {
    var containsAwait = false;
    for (var statement in node.statements) {
      if (visit(statement)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitBreak(js_ast.Break node) {
    if (node.targetLabel != null) {
      targets[node] =
          labelledStatements.lastWhere((js_ast.LabeledStatement statement) {
        return statement.label == node.targetLabel;
      });
    } else {
      targets[node] = loopsAndSwitches.last;
    }
    return false;
  }

  @override
  bool visitCall(js_ast.Call node) {
    var containsAwait = visit(node.target);
    for (var argument in node.arguments) {
      if (visit(argument)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitCase(js_ast.Case node) {
    var expression = visit(node.expression);
    var body = visit(node.body);
    return expression || body;
  }

  @override
  bool visitCatch(js_ast.Catch node) {
    var declaration = visit(node.declaration);
    var body = visit(node.body);
    return declaration || body;
  }

  @override
  bool visitComment(js_ast.Comment node) {
    return false;
  }

  @override
  bool visitConditional(js_ast.Conditional node) {
    var condition = visit(node.condition);
    var then = visit(node.then);
    var otherwise = visit(node.otherwise);
    return condition || then || otherwise;
  }

  @override
  bool visitContinue(js_ast.Continue node) {
    if (node.targetLabel != null) {
      var targetLabel = labelledStatements.lastWhere(
          (js_ast.LabeledStatement stm) => stm.label == node.targetLabel);
      targets[node] = targetLabel.body;
    } else {
      targets[node] = loopsAndSwitches
          .lastWhere((js_ast.Node node) => node is! js_ast.Switch);
    }
    assert(() {
      var target = targets[node];
      return target is js_ast.Loop ||
          (target is js_ast.LabeledStatement && target.body is js_ast.Loop);
    }());
    return false;
  }

  @override
  bool visitDefault(js_ast.Default node) {
    return visit(node.body);
  }

  @override
  bool visitDo(js_ast.Do node) {
    loopsAndSwitches.add(node);
    var body = visit(node.body);
    var condition = visit(node.condition);
    loopsAndSwitches.removeLast();
    return body || condition;
  }

  @override
  bool visitEmptyStatement(js_ast.EmptyStatement node) {
    return false;
  }

  @override
  bool visitExpressionStatement(js_ast.ExpressionStatement node) {
    return visit(node.expression);
  }

  @override
  bool visitFor(js_ast.For node) {
    var init = (node.init == null) ? false : visit(node.init!);
    var condition = (node.condition == null) ? false : visit(node.condition!);
    var update = (node.update == null) ? false : visit(node.update!);
    loopsAndSwitches.add(node);
    var body = visit(node.body);
    loopsAndSwitches.removeLast();
    return init || condition || update || body;
  }

  @override
  bool visitForIn(js_ast.ForIn node) {
    var object = visit(node.object);
    loopsAndSwitches.add(node);
    var body = visit(node.body);
    loopsAndSwitches.removeLast();
    return object || body;
  }

  @override
  bool visitFun(js_ast.Fun node) {
    return false;
  }

  @override
  bool visitFunctionDeclaration(js_ast.FunctionDeclaration node) {
    return false;
  }

  @override
  bool visitArrowFun(js_ast.ArrowFun node) {
    return false;
  }

  @override
  bool visitIf(js_ast.If node) {
    var condition = visit(node.condition);
    var then = visit(node.then);
    var otherwise = visit(node.otherwise);
    return condition || then || otherwise;
  }

  @override
  bool visitInterpolatedExpression(js_ast.InterpolatedExpression node) {
    unsupported(node);
  }

  @override
  bool visitInterpolatedLiteral(js_ast.InterpolatedLiteral node) {
    unsupported(node);
  }

  @override
  bool visitInterpolatedParameter(js_ast.InterpolatedParameter node) {
    unsupported(node);
  }

  @override
  bool visitInterpolatedSelector(js_ast.InterpolatedSelector node) {
    unsupported(node);
  }

  @override
  bool visitInterpolatedStatement(js_ast.InterpolatedStatement node) {
    unsupported(node);
  }

  @override
  bool visitLabeledStatement(js_ast.LabeledStatement node) {
    usedLabelNames.add(node.label);
    labelledStatements.add(node);
    var containsAwait = visit(node.body);
    labelledStatements.removeLast();
    return containsAwait;
  }

  @override
  bool visitLiteralBool(js_ast.LiteralBool node) {
    return false;
  }

  @override
  bool visitLiteralExpression(js_ast.LiteralExpression node) {
    unsupported(node);
  }

  @override
  bool visitLiteralNull(js_ast.LiteralNull node) {
    return false;
  }

  @override
  bool visitLiteralNumber(js_ast.LiteralNumber node) {
    return false;
  }

  @override
  bool visitLiteralStatement(js_ast.LiteralStatement node) {
    unsupported(node);
  }

  @override
  bool visitLiteralString(js_ast.LiteralString node) {
    return false;
  }

  @override
  bool visitNamedFunction(js_ast.NamedFunction node) {
    return false;
  }

  @override
  bool visitNew(js_ast.New node) {
    return visitCall(node);
  }

  @override
  bool visitObjectInitializer(js_ast.ObjectInitializer node) {
    var containsAwait = false;
    for (var property in node.properties) {
      if (visit(property)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitPostfix(js_ast.Postfix node) {
    return visit(node.argument);
  }

  @override
  bool visitPrefix(js_ast.Prefix node) {
    return visit(node.argument);
  }

  @override
  bool visitProgram(js_ast.Program node) {
    throw 'Unexpected';
  }

  @override
  bool visitProperty(js_ast.Property node) {
    return visit(node.value);
  }

  @override
  bool visitMethod(js_ast.Method node) {
    return false;
  }

  @override
  bool visitRegExpLiteral(js_ast.RegExpLiteral node) {
    return false;
  }

  @override
  bool visitReturn(js_ast.Return node) {
    hasExplicitReturns = true;
    targets[node] = currentFunction;
    if (node.value == null) return false;
    return visit(node.value!);
  }

  @override
  bool visitSwitch(js_ast.Switch node) {
    loopsAndSwitches.add(node);
    // TODO(sra): If just the key has an `await` expression, do not transform
    // the body of the switch.
    var result = visit(node.key);
    for (var clause in node.cases) {
      if (visit(clause)) result = true;
    }
    loopsAndSwitches.removeLast();
    return result;
  }

  @override
  bool visitThis(js_ast.This node) {
    return false;
  }

  @override
  bool visitThrow(js_ast.Throw node) {
    return visit(node.expression);
  }

  @override
  bool visitTry(js_ast.Try node) {
    if (node.finallyPart != null) hasFinally = true;
    var body = visit(node.body);
    var catchPart = (node.catchPart == null) ? false : visit(node.catchPart!);
    var finallyPart =
        (node.finallyPart == null) ? false : visit(node.finallyPart!);
    return body || catchPart || finallyPart;
  }

  @override
  bool visitVariableDeclarationList(js_ast.VariableDeclarationList node) {
    var result = false;
    for (var init in node.declarations) {
      if (visit(init)) result = true;
    }
    return result;
  }

  @override
  bool visitVariableInitialization(js_ast.VariableInitialization node) {
    var leftHandSide = visit(node.declaration);
    var value = (node.value == null) ? false : visit(node.value!);
    return leftHandSide || value;
  }

  @override
  bool visitIdentifier(js_ast.Identifier node) {
    return false;
  }

  @override
  bool visitWhile(js_ast.While node) {
    loopsAndSwitches.add(node);
    var condition = visit(node.condition);
    var body = visit(node.body);
    loopsAndSwitches.removeLast();
    return condition || body;
  }

  @override
  bool visitDartYield(js_ast.DartYield node) {
    hasYield = true;
    visit(node.expression);
    return true;
  }

  @override
  bool visitCommentExpression(js_ast.CommentExpression node) {
    return false;
  }

  @override
  bool visitArrayBindingPattern(js_ast.ArrayBindingPattern node) {
    return false;
  }

  @override
  bool visitClassDeclaration(js_ast.ClassDeclaration node) {
    return false;
  }

  @override
  bool visitClassExpression(js_ast.ClassExpression node) {
    return false;
  }

  @override
  bool visitDebuggerStatement(js_ast.DebuggerStatement node) {
    return false;
  }

  @override
  bool visitDestructuredVariable(js_ast.DestructuredVariable node) {
    return false;
  }

  @override
  bool visitExportClause(js_ast.ExportClause node) {
    return false;
  }

  @override
  bool visitExportDeclaration(js_ast.ExportDeclaration node) {
    return false;
  }

  @override
  bool visitForOf(js_ast.ForOf node) {
    node.leftHandSide.accept(this);
    var iterable = node.iterable.accept(this);
    loopsAndSwitches.add(node);
    var body = node.body.accept(this);
    loopsAndSwitches.removeLast();
    return iterable || body;
  }

  @override
  bool visitImportDeclaration(js_ast.ImportDeclaration node) {
    return false;
  }

  @override
  bool visitInterpolatedIdentifier(js_ast.InterpolatedIdentifier node) {
    return false;
  }

  @override
  bool visitInterpolatedMethod(js_ast.InterpolatedMethod node) {
    return false;
  }

  @override
  bool visitNameSpecifier(js_ast.NameSpecifier node) {
    return false;
  }

  @override
  bool visitObjectBindingPattern(js_ast.ObjectBindingPattern node) {
    return false;
  }

  @override
  bool visitRestParameter(js_ast.RestParameter node) {
    return false;
  }

  @override
  bool visitSimpleBindingPattern(js_ast.SimpleBindingPattern node) {
    return false;
  }

  @override
  bool visitSpread(js_ast.Spread node) {
    return false;
  }

  @override
  bool visitSuper(js_ast.Super node) {
    return false;
  }

  @override
  bool visitTaggedTemplate(js_ast.TaggedTemplate node) {
    return false;
  }

  @override
  bool visitTemplateString(js_ast.TemplateString node) {
    return node.interpolations.any((e) => e.accept(this));
  }

  @override
  bool visitYield(js_ast.Yield node) {
    unsupported(node);
  }
}

/// Defines a scope in the async body of a function tracking all variables
/// available in the scope.
///
/// We maintain a mapping from each variable name to the scope it is declared
/// in. This allows us to refer to the correct scope object for uses of that
/// variable.
///
/// Each scope also tracks if it was captured. Only captured scopes need to be
/// reset upon re-entry, otherwise the values within them cannot leak out.
class _ScopeInfo {
  late final TemporaryId scopeObject = TemporaryId('asyncScope');
  bool isCaptured = false;
  bool hasDeclarations = false;
  final Map<String, _ScopeInfo> _nameDeclarations;

  _ScopeInfo([Map<String, _ScopeInfo>? nameDeclarations])
      : _nameDeclarations = {...?nameDeclarations};

  _ScopeInfo childScope() {
    return _ScopeInfo(_nameDeclarations);
  }

  void declare(js_ast.Identifier node, bool isUntrackedDeclaration) {
    final key = node.name;
    assert(_nameDeclarations[key] != this,
        'Name "$node" already declared in scope.');
    if (isUntrackedDeclaration) {
      _nameDeclarations.remove(key);
    } else {
      _nameDeclarations[key] = this;
      hasDeclarations = true;
    }
  }

  _ScopeInfo? getDeclaringScope(js_ast.Identifier node) {
    return _nameDeclarations[node.name];
  }
}

/// Tracks [_ScopeInfo] are captured by this closure.
///
/// We use an IIFE to capture scope objects used within this closure. Capture
/// names are assigned to each captured scope, this is the parameter name in the
/// IIFE. Within the body of this closure, captured scopes will be referred to
/// by their capture name.
class _ClosureCaptureInfo {
  final _ScopeInfo scopeInfo;
  final Map<_ScopeInfo, TemporaryId> usedScopes = {};
  bool get hasCapture => usedScopes.isNotEmpty;

  _ClosureCaptureInfo(this.scopeInfo);

  TemporaryId useScope(_ScopeInfo scope) {
    scope.isCaptured = true;
    return usedScopes[scope] ??= TemporaryId('capturedAsyncScope');
  }
}

/// Updates references to captured variables to read the value from the
/// appropriate captured scope name.
class _ClosureRenamer extends js_ast.Transformer {
  final _ScopeCollector scopeCollector;
  final _ClosureCaptureInfo closureInfo;

  _ClosureRenamer(this.scopeCollector, this.closureInfo);

  @override
  js_ast.Node visitIdentifier(js_ast.Identifier node) {
    final declaringScope = scopeCollector.useToDeclaringScope[node];
    if (declaringScope == null) return node;
    final captureVariable = closureInfo.usedScopes[declaringScope];
    return captureVariable != null
        ? (js_ast.PropertyAccess.field(captureVariable, node.name)
          ..sourceInformation = node.sourceInformation)
        : node;
  }
}

/// Collects scoped names for each variable declared within the scope of the
/// given function.
///
/// In order to support scope capture we define a [_ScopeInfo] for each scope
/// we enter. Each one will be a JS Object that we can capture in inner
/// functions. This object can also be reset when we re-enter a scoped
/// construct (e.g. different iterations of a for loop).
///
/// The [_ScopeInfo] object will get hoisted to the top of the async body so it
/// can be accessed where needed across async gaps.
///
/// This approach also works well for debugging, users will see "asyncScope"
/// objects. Since we have one scope object (roughly) per Dart scope, users will
/// see variables matching the names they've used in the source code. In the
/// future DevTools can even recognize these objects and flatten them into their
/// appropriate scopes.
///
/// We also track [_ClosureCaptureInfo] for each capturing function so that we
/// can maintain the correct captured scopes.
///
/// Variables that are not hoisted (i.e. we can maintain their control flow
/// constructs because they don't contain awaits or yields) do not need to be
/// referenced via scope objects.
class _ScopeCollector extends js_ast.VariableDeclarationVisitor {
  final PreTranslationAnalysis _analysis;

  _ScopeInfo _currentScope = _ScopeInfo(null);
  _ClosureCaptureInfo? _currentOuterClosure;
  bool skipHoisting = false;
  final Map<js_ast.Identifier, _ScopeInfo> useToDeclaringScope = {};
  final Map<js_ast.Node, _ScopeInfo> scopeMapping = {};
  final Map<js_ast.FunctionExpression, _ClosureCaptureInfo> scopeCaptures = {};
  bool get inClosure => _currentOuterClosure != null;

  _ScopeCollector(this._analysis);

  void collect(js_ast.FunctionExpression node) {
    node.body.accept(this);
    scopeMapping[node.body] = _currentScope;
  }

  js_ast.Expression transformIdentifier(js_ast.Identifier node) {
    final declaringScope = useToDeclaringScope[node];
    if (declaringScope == null) return node;
    return (js_ast.PropertyAccess.field(declaringScope.scopeObject, node.name)
      ..sourceInformation = node.sourceInformation);
  }

  void registerUsed(js_ast.Identifier node) {
    final declaringScope = _currentScope.getDeclaringScope(node);
    if (declaringScope != null) {
      useToDeclaringScope[node] = declaringScope;
      _currentOuterClosure?.useScope(declaringScope);
    }
  }

  void withNewScope(js_ast.Node node, void Function() f) {
    final savedScope = _currentScope;
    _currentScope = _currentScope.childScope();
    scopeMapping[node] = _currentScope;
    f();
    _currentScope = savedScope;
  }

  @override
  void declare(js_ast.Identifier node) {
    if (node is TemporaryId) return;
    _currentScope.declare(node, inClosure || skipHoisting);
    registerUsed(node);
  }

  @override
  void visitIdentifier(js_ast.Identifier node) {
    if (node is TemporaryId) return;
    registerUsed(node);
  }

  @override
  void visitFunctionExpression(js_ast.FunctionExpression node) {
    withNewScope(node, () {
      if (!inClosure) {
        _currentOuterClosure = _ClosureCaptureInfo(_currentScope);
        scopeCaptures[node] = _currentOuterClosure!;
        super.visitFunctionExpression(node);
        _currentOuterClosure = null;
      } else {
        super.visitFunctionExpression(node);
      }
    });
  }

  @override
  void visitBlock(js_ast.Block node) {
    if (node.isScope) {
      withNewScope(node, () => super.visitBlock(node));
    } else {
      super.visitBlock(node);
    }
  }

  @override
  void visitForIn(js_ast.ForIn node) {
    node.object.accept(this);
    withNewScope(node, () {
      final savedSkipHoisting = skipHoisting;
      skipHoisting = !_analysis.hasAwaitOrYield.contains(node);
      node.leftHandSide.accept(this);
      skipHoisting = savedSkipHoisting;
      node.body.accept(this);
    });
  }

  @override
  void visitForOf(js_ast.ForOf node) {
    node.iterable.accept(this);
    withNewScope(node, () {
      final savedSkipHoisting = skipHoisting;
      skipHoisting = !_analysis.hasAwaitOrYield.contains(node);
      node.leftHandSide.accept(this);
      skipHoisting = savedSkipHoisting;
      node.body.accept(this);
    });
  }

  @override
  void visitFor(js_ast.For node) {
    // Make sure any declared variables are scoped to this loop.
    withNewScope(node, () {
      final savedSkipHoisting = skipHoisting;
      skipHoisting = !_analysis.hasAwaitOrYield.contains(node);
      node.init?.accept(this);
      skipHoisting = savedSkipHoisting;
      node.condition?.accept(this);
      node.update?.accept(this);
      node.body.accept(this);
    });
  }

  @override
  void visitTry(js_ast.Try node) {
    node.body.accept(this);
    final savedSkipHoisting = skipHoisting;
    skipHoisting = !_analysis.hasAwaitOrYield.contains(node);
    node.catchPart?.declaration.accept(this);
    skipHoisting = savedSkipHoisting;
    node.catchPart?.body.accept(this);
    node.finallyPart?.accept(this);
  }
}
