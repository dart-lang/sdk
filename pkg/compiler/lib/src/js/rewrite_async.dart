// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library rewrite_async;

import 'dart:collection';
import 'dart:math' show max;

import 'package:js_runtime/shared/async_await_error_codes.dart' as error_codes;

import '../common.dart';
import '../io/source_information.dart' show SourceInformation;
import '../util/util.dart' show Pair;
import 'js.dart' as js;

/// Rewrites a [js.Fun] with async/sync*/async* functions and await and yield
/// (with dart-like semantics) to an equivalent function without these.
/// await-for is not handled and must be rewritten before. (Currently handled
/// in ssa/builder.dart).
///
/// When generating the input to this, special care must be taken that
/// parameters to sync* functions that are mutated in the body must be boxed.
/// (Currently handled in closure.dart).
///
/// Look at [rewriteFunction], [visitDartYield] and [visitAwait] for more
/// explanation.
abstract class AsyncRewriterBase extends js.NodeVisitor {
  // Local variables are hoisted to the top of the function, so they are
  // collected here.
  List<js.VariableDeclaration> localVariables = <js.VariableDeclaration>[];

  Map<js.Node, int> continueLabels = new Map<js.Node, int>();
  Map<js.Node, int> breakLabels = new Map<js.Node, int>();

  /// The label of a finally part.
  Map<js.Block, int> finallyLabels = new Map<js.Block, int>();

  /// The label of the catch handler of a [js.Try] or a [js.Fun] or [js.Catch].
  ///
  /// These mark the points an error can be consumed.
  ///
  /// - The handler of a [js.Fun] is the outermost and will rethrow the error.
  /// - The handler of a [js.Try] will run the catch handler.
  /// - The handler of a [js.Catch] is a synthetic handler that ensures the
  ///   right finally blocks are run if an error is thrown inside a
  ///   catch-handler.
  Map<js.Node, int> handlerLabels = new Map<js.Node, int>();

  int exitLabel;
  int rethrowLabel;

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
  List<js.Node> jumpTargets = <js.Node>[];

  List<int> continueStack = <int>[];
  List<int> breakStack = <int>[];
  List<int> returnStack = <int>[];

  List<Pair<String, String>> variableRenamings = <Pair<String, String>>[];

  PreTranslationAnalysis analysis;

  final Function safeVariableName;

  // All the <x>Name variables are names of Javascript variables used in the
  // transformed code.

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
  js.VariableUse get result => new js.VariableUse(resultName);
  String resultName;

  /// A parameter to the [bodyName] function. Indicating if we are in success
  /// or error case.
  String errorCodeName;

  /// The inner function that is scheduled to do each await/yield,
  /// and called to do a new iteration for sync*.
  js.Name bodyName;

  /// Used to simulate a goto.
  ///
  /// To "goto" a label, the label is assigned to this variable, and break out
  /// of the switch to take another iteration in the while loop. See [addGoto]
  js.VariableUse get goto => new js.VariableUse(gotoName);
  String gotoName;

  /// Variable containing the label of the current error handler.
  js.VariableUse get handler => new js.VariableUse(handlerName);
  String handlerName;

  /// Set to `true` if any of the switch statement labels is a handler. At the
  /// end of rewriting this is used to see if a shorter form of error handling
  /// can be used. The shorter form could be a change in the method boilerplate,
  /// in the state machine wrapper, or not implemented. [addErrorExit] can test
  /// this to elide the error exit handler when there are no other handlers, or
  /// set it to `true` if there is no shorter form.
  bool hasHandlerLabels = false;

  /// A stack of labels of finally blocks to visit, and the label to go to after
  /// the last.
  js.VariableUse get next => new js.VariableUse(nextName);
  String nextName;

  /// The current returned value (a finally block may overwrite it).
  js.VariableUse get returnValue => new js.VariableUse(returnValueName);
  String returnValueName;

  /// Stores the current error when we are in the process of handling an error.
  js.VariableUse get currentError => new js.VariableUse(currentErrorName);
  String currentErrorName;

  /// The label of the outer loop.
  ///
  /// Used if there are untransformed loops containing break or continues to
  /// targets outside the loop.
  String outerLabelName;

  /// If javascript `this` is used, it is accessed via this variable, in the
  /// [bodyName] function.
  js.VariableUse get self => new js.VariableUse(selfName);
  String selfName;

  final DiagnosticReporter reporter;
  // For error reporting only.
  Spannable get spannable {
    return (_spannable == null) ? NO_LOCATION_SPANNABLE : _spannable;
  }

  Spannable _spannable;

  int _currentLabel = 0;

  // The highest temporary variable index currently in use.
  int currentTempVarIndex = 0;
  // The highest temporary variable index ever in use in this function.
  int tempVarHighWaterMark = 0;
  Map<int, js.Expression> tempVarNames = new Map<int, js.Expression>();

  bool get isAsync => false;
  bool get isSyncStar => false;
  bool get isAsyncStar => false;

  AsyncRewriterBase(
      this.reporter, this._spannable, this.safeVariableName, this.bodyName);

  /// Initialize names used by the subClass.
  void initializeNames();

  /// Main entry point.
  /// Rewrites a sync*/async/async* function to an equivalent normal function.
  ///
  /// [spannable] can be passed to have a location for error messages.
  js.Fun rewrite(js.Fun node, [Spannable spannable]) {
    _spannable = spannable;

    analysis = new PreTranslationAnalysis(unsupported);
    analysis.analyze(node);

    // To avoid name collisions with existing names, the fresh names are
    // generated after the analysis.
    resultName = freshName("result");
    errorCodeName = freshName("errorCode");
    gotoName = freshName("goto");
    handlerName = freshName("handler");
    nextName = freshName("next");
    returnValueName = freshName("returnValue");
    currentErrorName = freshName("currentError");
    outerLabelName = freshName("outer");
    selfName = freshName("self");
    // Initialize names specific to the subclass.
    initializeNames();

    return rewriteFunction(node);
  }

  js.Expression get currentErrorHandler {
    return js.number(handlerLabels[
        jumpTargets.lastWhere((node) => handlerLabels[node] != null)]);
  }

  int allocateTempVar() {
    assert(tempVarHighWaterMark >= currentTempVarIndex);
    currentTempVarIndex++;
    tempVarHighWaterMark = max(currentTempVarIndex, tempVarHighWaterMark);
    return currentTempVarIndex;
  }

  js.VariableUse useTempVar(int i) {
    return tempVarNames.putIfAbsent(
        i, () => new js.VariableUse(freshName("temp$i")));
  }

  /// Generates a variable name with [safeVariableName] based on [originalName]
  /// with a suffix to guarantee it does not collide with already used names.
  String freshName(String originalName) {
    String safeName = safeVariableName(originalName);
    String result = safeName;
    int counter = 1;
    while (analysis.usedNames.contains(result)) {
      result = "$safeName$counter";
      ++counter;
    }
    analysis.usedNames.add(result);
    return result;
  }

  /// All the pieces are collected in this map, to create a switch with a case
  /// for each label.
  ///
  /// The order is important, therefore the type is explicitly LinkedHashMap.
  LinkedHashMap<int, List<js.Statement>> labelledParts =
      new LinkedHashMap<int, List<js.Statement>>();

  /// Description of each label for readability of the non-minified output.
  Map<int, String> labelComments = new Map<int, String>();

  /// True if the function has any try blocks containing await.
  bool hasTryBlocks = false;

  /// True if the traversion currently is inside a loop or switch for which
  /// [shouldTransform] is false.
  bool insideUntranslatedBreakable = false;

  /// True if a label is used to break to an outer switch-statement.
  bool hasJumpThoughOuterLabel = false;

  /// True if there is a catch-handler protected by a finally with no enclosing
  /// catch-handlers.
  bool needsRethrow = false;

  /// Buffer for collecting translated statements belonging to the same switch
  /// case.
  List<js.Statement> currentStatementBuffer;

  // Labels will become cases in the big switch expression, and `goto label`
  // is expressed by assigning to the switch key [gotoName] and breaking out of
  // the switch.

  int newLabel([String comment]) {
    int result = _currentLabel;
    _currentLabel++;
    if (comment != null) {
      labelComments[result] = comment;
    }
    return result;
  }

  /// Begins outputting statements to a new buffer with label [label].
  ///
  /// Each buffer ends up as its own case part in the big state-switch.
  void beginLabel(int label) {
    assert(!labelledParts.containsKey(label));
    currentStatementBuffer = <js.Statement>[];
    labelledParts[label] = currentStatementBuffer;
    addStatement(new js.Comment(labelComments[label]));
  }

  /// Returns a statement assigning to the variable named [gotoName].
  /// This should be followed by a break for the goto to be executed. Use
  /// [gotoWithBreak] or [addGoto] for this.
  js.Statement setGotoVariable(int label) {
    return js.js.statement('# = #;', [goto, js.number(label)]);
  }

  /// Returns a block that has a goto to [label] including the break.
  ///
  /// Also inserts a comment describing the label if available.
  js.Block gotoAndBreak(int label) {
    List<js.Statement> statements = <js.Statement>[];
    if (labelComments.containsKey(label)) {
      statements.add(new js.Comment("goto ${labelComments[label]}"));
    }
    statements.add(setGotoVariable(label));
    if (insideUntranslatedBreakable) {
      hasJumpThoughOuterLabel = true;
      statements.add(new js.Break(outerLabelName));
    } else {
      statements.add(new js.Break(null));
    }
    return new js.Block(statements);
  }

  /// Adds a goto to [label] including the break.
  ///
  /// Also inserts a comment describing the label if available.
  void addGoto(int label) {
    if (labelComments.containsKey(label)) {
      addStatement(new js.Comment("goto ${labelComments[label]}"));
    }
    addStatement(setGotoVariable(label));

    addBreak();
  }

  void addStatement(js.Statement node) {
    currentStatementBuffer.add(node);
  }

  void addExpressionStatement(js.Expression node) {
    addStatement(new js.ExpressionStatement(node));
  }

  /// True if there is an await or yield in [node] or some subexpression.
  bool shouldTransform(js.Node node) {
    return analysis.hasAwaitOrYield.contains(node);
  }

  void unsupported(js.Node node) {
    throw new UnsupportedError(
        "Node $node cannot be transformed by the await-sync transformer");
  }

  void unreachable(js.Node node) {
    reporter.internalError(spannable, "Internal error, trying to visit $node");
  }

  visitStatement(js.Statement node) {
    node.accept(this);
  }

  /// Visits [node] to ensure its sideeffects are performed, but throwing away
  /// the result.
  ///
  /// If the return value of visiting [node] is an expression guaranteed to have
  /// no side effect, it is dropped.
  void visitExpressionIgnoreResult(js.Expression node) {
    js.Expression result = node.accept(this);
    if (!(result is js.Literal || result is js.VariableUse)) {
      addExpressionStatement(result);
    }
  }

  js.Expression visitExpression(js.Expression node) {
    return node.accept(this);
  }

  /// Calls [fn] with the value of evaluating [node1] and [node2].
  ///
  /// Both nodes are evaluated in order.
  ///
  /// If node2 must be transformed (see [shouldTransform]), then the evaluation
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
  js.Expression _storeIfNecessary(js.Expression result) {
    // Note that RegExes, js.ArrayInitializer and js.ObjectInitializer are not
    // [js.Literal]s.
    if (result is js.Literal) return result;

    js.Expression tempVar = useTempVar(allocateTempVar());
    addStatement(js.js.statement('# = #;', [tempVar, result]));
    return tempVar;
  }

  // TODO(sigurdm): This is obsolete - all calls use store: false. Replace with
  // visitExpression(node);
  withExpression(js.Expression node, fn(js.Expression result), {bool store}) {
    int oldTempVarIndex = currentTempVarIndex;
    js.Expression visited = visitExpression(node);
    if (store) {
      visited = _storeIfNecessary(visited);
    }
    var result = fn(visited);
    currentTempVarIndex = oldTempVarIndex;
    return result;
  }

  /// Calls [fn] with the result of evaluating [node]. Taking special care of
  /// property accesses.
  ///
  /// If [store] is true the result of evaluating [node] is stored in a
  /// temporary.
  ///
  /// We cannot rewrite `<receiver>.m()` to:
  ///     temp = <receiver>.m;
  ///     temp();
  /// Because this leaves `this` unbound in the call. But because of dart
  /// evaluation order we can write:
  ///     temp = <receiver>;
  ///     temp.m();
  withCallTargetExpression(js.Expression node, fn(js.Expression result),
      {bool store}) {
    int oldTempVarIndex = currentTempVarIndex;
    js.Expression visited = visitExpression(node);
    js.Expression selector;
    js.Expression storedIfNeeded;
    if (store) {
      if (visited is js.PropertyAccess) {
        js.PropertyAccess propertyAccess = visited;
        selector = propertyAccess.selector;
        visited = propertyAccess.receiver;
      }
      storedIfNeeded = _storeIfNecessary(visited);
    } else {
      storedIfNeeded = visited;
    }
    js.Expression result;
    if (selector == null) {
      result = fn(storedIfNeeded);
    } else {
      result = fn(new js.PropertyAccess(storedIfNeeded, selector));
    }
    currentTempVarIndex = oldTempVarIndex;
    return result;
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
  withExpression2(js.Expression node1, js.Expression node2,
      fn(js.Expression result1, js.Expression result2)) {
    int oldTempVarIndex = currentTempVarIndex;
    js.Expression r1 = visitExpression(node1);
    if (shouldTransform(node2)) {
      r1 = _storeIfNecessary(r1);
    }
    js.Expression r2 = visitExpression(node2);
    var result = fn(r1, r2);
    currentTempVarIndex = oldTempVarIndex;
    return result;
  }

  /// Calls [fn] with the value of evaluating all [nodes].
  ///
  /// All results before the last node where `shouldTransform(node)` are stored
  /// in temporary variables.
  ///
  /// See more explanation on [withExpression2].
  ///
  /// If any of the nodes are null, they are ignored, and a null is passed to
  /// [fn] in that place.
  withExpressions(List<js.Expression> nodes, fn(List<js.Expression> results)) {
    int oldTempVarIndex = currentTempVarIndex;
    // Find last occurence of a 'transform' expression in [nodes].
    // All expressions before that must be stored in temp-vars.
    int lastTransformIndex = 0;
    for (int i = nodes.length - 1; i >= 0; --i) {
      if (nodes[i] == null) continue;
      if (shouldTransform(nodes[i])) {
        lastTransformIndex = i;
        break;
      }
    }
    List<js.Node> visited = nodes.take(lastTransformIndex).map((js.Node node) {
      return (node == null) ? null : _storeIfNecessary(visitExpression(node));
    }).toList();
    visited.addAll(nodes.skip(lastTransformIndex).map((js.Node node) {
      return (node == null) ? null : visitExpression(node);
    }));
    var result = fn(visited);
    currentTempVarIndex = oldTempVarIndex;
    return result;
  }

  /// Emits the return block that all returns jump to (after going
  /// through all the enclosing finally blocks). The jump to here is made in
  /// [visitReturn].
  void addSuccesExit();

  /// Emits the block that control flows to if an error has been thrown
  /// but not caught. (after going through all the enclosing finally blocks).
  void addErrorExit();

  void addFunctionExits() {
    addSuccesExit();
    addErrorExit();
  }

  /// Returns the rewritten function.
  js.Fun finishFunction(
      List<js.Parameter> parameters,
      js.Statement rewrittenBody,
      js.VariableDeclarationList variableDeclarations,
      SourceInformation sourceInformation);

  Iterable<js.VariableInitialization> variableInitializations();

  /// Rewrites an async/sync*/async* function to a normal Javascript function.
  ///
  /// The control flow is flattened by simulating 'goto' using a switch in a
  /// loop and a state variable [goto] inside a nested function [body]
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
  /// Try/catch is implemented by maintaining [handler] to contain the label
  /// of the current handler. If [body] throws, the caller should catch the
  /// error and recall [body] with first argument [error_codes.ERROR] and
  /// second argument the error.
  ///
  /// A `finally` clause is compiled similar to normal code, with the additional
  /// complexity that `finally` clauses need to know where to jump to after the
  /// clause is done. In the translation, each flow-path that enters a `finally`
  /// sets up the variable [next] with a stack of finally-blocks and a final
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
  js.Expression rewriteFunction(js.Fun node) {
    beginLabel(newLabel("Function start"));
    // AsyncStar needs a returnlabel for its handling of cancelation. See
    // [visitDartYield].
    exitLabel = (analysis.hasExplicitReturns || isAsyncStar)
        ? newLabel("return")
        : null;
    rethrowLabel = newLabel("rethrow");
    handlerLabels[node] = rethrowLabel;
    js.Statement body = node.body;
    jumpTargets.add(node);
    visitStatement(body);
    jumpTargets.removeLast();
    addFunctionExits();

    List<js.SwitchClause> clauses = labelledParts.keys.map((label) {
      return new js.Case(js.number(label), new js.Block(labelledParts[label]));
    }).toList();
    js.Statement rewrittenBody = new js.Switch(goto, clauses);
    if (hasJumpThoughOuterLabel) {
      rewrittenBody = new js.LabeledStatement(outerLabelName, rewrittenBody);
    }
    rewrittenBody = js.js.statement('while (true) {#}', rewrittenBody);
    List<js.VariableInitialization> variables = <js.VariableInitialization>[];

    variables.add(_makeVariableInitializer(goto, js.number(0)));
    variables.addAll(variableInitializations());
    if (hasHandlerLabels) {
      variables.add(_makeVariableInitializer(handler, js.number(rethrowLabel)));
      variables.add(_makeVariableInitializer(currentError, null));
    }
    if (analysis.hasFinally || (isAsyncStar && analysis.hasYield)) {
      variables.add(_makeVariableInitializer(
          next, new js.ArrayInitializer(<js.Expression>[])));
    }
    if (analysis.hasThis && !isSyncStar) {
      // Sync* functions must remember `this` on the level of the outer
      // function.
      variables.add(_makeVariableInitializer(self, js.js('this')));
    }
    variables.addAll(localVariables.map((js.VariableDeclaration declaration) {
      return new js.VariableInitialization(declaration, null);
    }));
    variables.addAll(new Iterable.generate(tempVarHighWaterMark,
        (int i) => _makeVariableInitializer(useTempVar(i + 1).name, null)));
    js.VariableDeclarationList variableDeclarations =
        new js.VariableDeclarationList(variables);

    return finishFunction(node.params, rewrittenBody, variableDeclarations,
        node.sourceInformation);
  }

  @override
  js.Expression visitFun(js.Fun node) {
    if (node.asyncModifier.isAsync || node.asyncModifier.isYielding) {
      // The translation does not handle nested functions that are generators
      // or asynchronous.  These functions should only be ones that are
      // introduced by JS foreign code from our own libraries.
      reporter.internalError(
          spannable, 'Nested function is a generator or asynchronous.');
    }
    return node;
  }

  @override
  js.Expression visitAccess(js.PropertyAccess node) {
    return withExpression2(node.receiver, node.selector,
        (receiver, selector) => js.js('#[#]', [receiver, selector]));
  }

  @override
  js.Expression visitArrayHole(js.ArrayHole node) {
    return node;
  }

  @override
  js.Expression visitArrayInitializer(js.ArrayInitializer node) {
    return withExpressions(node.elements, (elements) {
      return new js.ArrayInitializer(elements);
    });
  }

  @override
  js.Expression visitAssignment(js.Assignment node) {
    if (!shouldTransform(node)) {
      return new js.Assignment.compound(visitExpression(node.leftHandSide),
          node.op, visitExpression(node.value));
    }
    js.Expression leftHandSide = node.leftHandSide;
    if (leftHandSide is js.VariableUse) {
      return withExpression(node.value, (js.Expression value) {
        // A non-compound [js.Assignment] has `op==null`. So it works out to
        // use [js.Assignment.compound] for all cases.
        // Visit the [js.VariableUse] to ensure renaming is done correctly.
        return new js.Assignment.compound(
            visitExpression(leftHandSide), node.op, value);
      }, store: false);
    } else if (leftHandSide is js.PropertyAccess) {
      return withExpressions(
          [leftHandSide.receiver, leftHandSide.selector, node.value],
          (evaluated) {
        return new js.Assignment.compound(
            new js.PropertyAccess(evaluated[0], evaluated[1]),
            node.op,
            evaluated[2]);
      });
    } else {
      throw "Unexpected assignment left hand side $leftHandSide";
    }
  }

  js.Statement awaitStatement(js.Expression value);

  /// An await is translated to an [awaitStatement].
  ///
  /// See the comments of [rewriteFunction] for an example.
  @override
  js.Expression visitAwait(js.Await node) {
    assert(isAsync || isAsyncStar);
    int afterAwait = newLabel("returning from await.");
    withExpression(node.expression, (js.Expression value) {
      addStatement(setGotoVariable(afterAwait));
      addStatement(awaitStatement(value));
    }, store: false);
    beginLabel(afterAwait);
    return result;
  }

  /// Checks if [node] is the variable named [resultName].
  ///
  /// [result] is used to hold the result of a transformed computation
  /// for example the result of awaiting, or the result of a conditional or
  /// short-circuiting expression.
  /// If the subexpression of some transformed node already is transformed and
  /// visiting it returns [result], it is not redundantly assigned to itself
  /// again.
  bool isResult(js.Expression node) {
    return node is js.VariableUse && node.name == resultName;
  }

  @override
  js.Expression visitBinary(js.Binary node) {
    if (shouldTransform(node.right) && (node.op == "||" || node.op == "&&")) {
      int thenLabel = newLabel("then");
      int joinLabel = newLabel("join");
      withExpression(node.left, (js.Expression left) {
        js.Statement assignLeft = isResult(left)
            ? new js.Block.empty()
            : js.js.statement('# = #;', [result, left]);
        if (node.op == "&&") {
          addStatement(js.js.statement('if (#) {#} else #',
              [left, gotoAndBreak(thenLabel), assignLeft]));
        } else {
          assert(node.op == "||");
          addStatement(js.js.statement('if (#) {#} else #',
              [left, assignLeft, gotoAndBreak(thenLabel)]));
        }
      }, store: true);
      addGoto(joinLabel);
      beginLabel(thenLabel);
      withExpression(node.right, (js.Expression value) {
        if (!isResult(value)) {
          addStatement(js.js.statement('# = #;', [result, value]));
        }
      }, store: false);
      beginLabel(joinLabel);
      return result;
    }

    return withExpression2(node.left, node.right,
        (left, right) => new js.Binary(node.op, left, right));
  }

  @override
  void visitBlock(js.Block node) {
    for (js.Statement statement in node.statements) {
      visitStatement(statement);
    }
  }

  @override
  void visitBreak(js.Break node) {
    js.Node target = analysis.targets[node];
    if (!shouldTransform(target)) {
      addStatement(node);
      return;
    }
    translateJump(target, breakLabels[target]);
  }

  @override
  js.Expression visitCall(js.Call node) {
    bool storeTarget = node.arguments.any(shouldTransform);
    return withCallTargetExpression(node.target, (target) {
      return withExpressions(node.arguments, (List<js.Expression> arguments) {
        return new js.Call(target, arguments)
            .withSourceInformation(node.sourceInformation);
      });
    }, store: storeTarget);
  }

  @override
  void visitCase(js.Case node) {
    return unreachable(node);
  }

  @override
  void visitCatch(js.Catch node) {
    return unreachable(node);
  }

  @override
  void visitComment(js.Comment node) {
    addStatement(node);
  }

  @override
  js.Expression visitConditional(js.Conditional node) {
    if (!shouldTransform(node.then) && !shouldTransform(node.otherwise)) {
      return js.js('# ? # : #', [
        visitExpression(node.condition),
        visitExpression(node.then),
        visitExpression(node.otherwise)
      ]);
    }
    int thenLabel = newLabel("then");
    int joinLabel = newLabel("join");
    int elseLabel = newLabel("else");
    withExpression(node.condition, (js.Expression condition) {
      addStatement(js.js.statement('# = # ? # : #;',
          [goto, condition, js.number(thenLabel), js.number(elseLabel)]));
    }, store: false);
    addBreak();
    beginLabel(thenLabel);
    withExpression(node.then, (js.Expression value) {
      if (!isResult(value)) {
        addStatement(js.js.statement('# = #;', [result, value]));
      }
    }, store: false);
    addGoto(joinLabel);
    beginLabel(elseLabel);
    withExpression(node.otherwise, (js.Expression value) {
      if (!isResult(value)) {
        addStatement(js.js.statement('# = #;', [result, value]));
      }
    }, store: false);
    beginLabel(joinLabel);
    return result;
  }

  @override
  void visitContinue(js.Continue node) {
    js.Node target = analysis.targets[node];
    if (!shouldTransform(target)) {
      addStatement(node);
      return;
    }
    translateJump(target, continueLabels[target]);
  }

  /// Emits a break statement that exits the big switch statement.
  void addBreak() {
    if (insideUntranslatedBreakable) {
      hasJumpThoughOuterLabel = true;
      addStatement(new js.Break(outerLabelName));
    } else {
      addStatement(new js.Break(null));
    }
  }

  /// Common code for handling break, continue, return.
  ///
  /// It is necessary to run all nesting finally-handlers between the jump and
  /// the target. For that [next] is used as a stack of places to go.
  ///
  /// See also [rewriteFunction].
  void translateJump(js.Node target, int targetLabel) {
    // Compute a stack of all the 'finally' nodes that must be visited before
    // the jump.
    // The bottom of the stack is the label where the jump goes to.
    List<int> jumpStack = <int>[];
    for (js.Node node in jumpTargets.reversed) {
      if (finallyLabels[node] != null) {
        jumpStack.add(finallyLabels[node]);
      } else if (node == target) {
        jumpStack.add(targetLabel);
        break;
      }
      // Ignore other nodes.
    }
    jumpStack = jumpStack.reversed.toList();
    // As the program jumps directly to the top of the stack, it is taken off
    // now.
    int firstTarget = jumpStack.removeLast();
    if (jumpStack.isNotEmpty) {
      js.Expression jsJumpStack = new js.ArrayInitializer(
          jumpStack.map((int label) => js.number(label)).toList());
      addStatement(js.js.statement("# = #;", [next, jsJumpStack]));
    }
    addGoto(firstTarget);
  }

  @override
  void visitDefault(js.Default node) => unreachable(node);

  @override
  void visitDo(js.Do node) {
    if (!shouldTransform(node)) {
      bool oldInsideUntranslatedBreakable = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      addStatement(js.js.statement('do {#} while (#)',
          [translateToStatement(node.body), visitExpression(node.condition)]));
      insideUntranslatedBreakable = oldInsideUntranslatedBreakable;
      return;
    }
    int startLabel = newLabel("do body");

    int continueLabel = newLabel("do condition");
    continueLabels[node] = continueLabel;

    int afterLabel = newLabel("after do");
    breakLabels[node] = afterLabel;

    beginLabel(startLabel);

    jumpTargets.add(node);
    visitStatement(node.body);
    jumpTargets.removeLast();

    beginLabel(continueLabel);
    withExpression(node.condition, (js.Expression condition) {
      addStatement(
          js.js.statement('if (#) #', [condition, gotoAndBreak(startLabel)]));
    }, store: false);
    beginLabel(afterLabel);
  }

  @override
  void visitEmptyStatement(js.EmptyStatement node) {
    addStatement(node);
  }

  @override
  void visitExpressionStatement(js.ExpressionStatement node) {
    visitExpressionIgnoreResult(node.expression);
  }

  @override
  void visitFor(js.For node) {
    if (!shouldTransform(node)) {
      bool oldInsideUntranslated = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      // Note that node.init, node.condition, node.update all can be null, but
      // withExpressions handles that.
      withExpressions([node.init, node.condition, node.update],
          (List<js.Expression> transformed) {
        addStatement(new js.For(transformed[0], transformed[1], transformed[2],
            translateToStatement(node.body)));
      });
      insideUntranslatedBreakable = oldInsideUntranslated;
      return;
    }

    if (node.init != null) {
      visitExpressionIgnoreResult(node.init);
    }
    int startLabel = newLabel("for condition");
    // If there is no update, continuing the loop is the same as going to the
    // start.
    int continueLabel =
        (node.update == null) ? startLabel : newLabel("for update");
    continueLabels[node] = continueLabel;
    int afterLabel = newLabel("after for");
    breakLabels[node] = afterLabel;
    beginLabel(startLabel);
    js.Expression condition = node.condition;
    if (condition == null ||
        (condition is js.LiteralBool && condition.value == true)) {
      addStatement(new js.Comment("trivial condition"));
    } else {
      withExpression(condition, (js.Expression condition) {
        addStatement(new js.If.noElse(
            new js.Prefix("!", condition), gotoAndBreak(afterLabel)));
      }, store: false);
    }
    jumpTargets.add(node);
    visitStatement(node.body);
    jumpTargets.removeLast();
    if (node.update != null) {
      beginLabel(continueLabel);
      visitExpressionIgnoreResult(node.update);
    }
    addGoto(startLabel);
    beginLabel(afterLabel);
  }

  @override
  void visitForIn(js.ForIn node) {
    // The dart output currently never uses for-in loops.
    throw "Javascript for-in not implemented yet in the await transformation";
  }

  @override
  void visitFunctionDeclaration(js.FunctionDeclaration node) {
    unsupported(node);
  }

  List<js.Statement> translateToStatementSequence(js.Statement node) {
    assert(!shouldTransform(node));
    List<js.Statement> oldBuffer = currentStatementBuffer;
    currentStatementBuffer = <js.Statement>[];
    List<js.Statement> resultBuffer = currentStatementBuffer;
    visitStatement(node);
    currentStatementBuffer = oldBuffer;
    return resultBuffer;
  }

  js.Statement translateToStatement(js.Statement node) {
    List<js.Statement> statements = translateToStatementSequence(node);
    if (statements.length == 1) return statements.single;
    return new js.Block(statements);
  }

  js.Block translateToBlock(js.Statement node) {
    return new js.Block(translateToStatementSequence(node));
  }

  @override
  void visitIf(js.If node) {
    if (!shouldTransform(node.then) && !shouldTransform(node.otherwise)) {
      withExpression(node.condition, (js.Expression condition) {
        js.Statement translatedThen = translateToStatement(node.then);
        js.Statement translatedElse = translateToStatement(node.otherwise);
        addStatement(new js.If(condition, translatedThen, translatedElse));
      }, store: false);
      return;
    }
    int thenLabel = newLabel("then");
    int joinLabel = newLabel("join");
    int elseLabel =
        (node.otherwise is js.EmptyStatement) ? joinLabel : newLabel("else");

    withExpression(node.condition, (js.Expression condition) {
      addExpressionStatement(new js.Assignment(
          goto,
          new js.Conditional(
              condition, js.number(thenLabel), js.number(elseLabel))));
    }, store: false);
    addBreak();
    beginLabel(thenLabel);
    visitStatement(node.then);
    if (node.otherwise is! js.EmptyStatement) {
      addGoto(joinLabel);
      beginLabel(elseLabel);
      visitStatement(node.otherwise);
    }
    beginLabel(joinLabel);
  }

  @override
  visitInterpolatedExpression(js.InterpolatedExpression node) {
    return unsupported(node);
  }

  @override
  visitInterpolatedDeclaration(js.InterpolatedDeclaration node) {
    return unsupported(node);
  }

  @override
  visitInterpolatedLiteral(js.InterpolatedLiteral node) => unsupported(node);

  @override
  visitInterpolatedParameter(js.InterpolatedParameter node) {
    return unsupported(node);
  }

  @override
  visitInterpolatedSelector(js.InterpolatedSelector node) {
    return unsupported(node);
  }

  @override
  visitInterpolatedStatement(js.InterpolatedStatement node) {
    return unsupported(node);
  }

  @override
  void visitLabeledStatement(js.LabeledStatement node) {
    if (!shouldTransform(node)) {
      addStatement(
          new js.LabeledStatement(node.label, translateToStatement(node.body)));
      return;
    }
    // `continue label` is really continuing the nested loop.
    // This is set up in [PreTranslationAnalysis.visitContinue].
    // Here we only need a breakLabel:
    int breakLabel = newLabel("break ${node.label}");
    breakLabels[node] = breakLabel;

    jumpTargets.add(node);
    visitStatement(node.body);
    jumpTargets.removeLast();
    beginLabel(breakLabel);
  }

  @override
  js.Expression visitLiteralBool(js.LiteralBool node) => node;

  @override
  visitLiteralExpression(js.LiteralExpression node) => unsupported(node);

  @override
  js.Expression visitLiteralNull(js.LiteralNull node) => node;

  @override
  js.Expression visitLiteralNumber(js.LiteralNumber node) => node;

  @override
  visitLiteralStatement(js.LiteralStatement node) => unsupported(node);

  @override
  js.Expression visitLiteralString(js.LiteralString node) => node;

  @override
  js.Expression visitStringConcatenation(js.StringConcatenation node) => node;

  @override
  js.Name visitName(js.Name node) => node;

  @override
  visitNamedFunction(js.NamedFunction node) {
    unsupported(node);
  }

  @override
  js.Expression visitDeferredExpression(js.DeferredExpression node) => node;

  @override
  js.Expression visitDeferredNumber(js.DeferredNumber node) => node;

  @override
  js.Expression visitDeferredString(js.DeferredString node) => node;

  @override
  js.Expression visitNew(js.New node) {
    bool storeTarget = node.arguments.any(shouldTransform);
    return withCallTargetExpression(node.target, (target) {
      return withExpressions(node.arguments, (List<js.Expression> arguments) {
        return new js.New(target, arguments);
      });
    }, store: storeTarget);
  }

  @override
  js.Expression visitObjectInitializer(js.ObjectInitializer node) {
    return withExpressions(
        node.properties.map((js.Property property) => property.value).toList(),
        (List<js.Node> values) {
      List<js.Property> properties = new List.generate(values.length, (int i) {
        return new js.Property(node.properties[i].name, values[i]);
      });
      return new js.ObjectInitializer(properties);
    });
  }

  @override
  visitParameter(js.Parameter node) => unreachable(node);

  @override
  js.Expression visitPostfix(js.Postfix node) {
    if (node.op == "++" || node.op == "--") {
      js.Expression argument = node.argument;
      if (argument is js.VariableUse) {
        return new js.Postfix(node.op, visitExpression(argument));
      } else if (argument is js.PropertyAccess) {
        return withExpression2(argument.receiver, argument.selector,
            (receiver, selector) {
          return new js.Postfix(
              node.op, new js.PropertyAccess(receiver, selector));
        });
      } else {
        throw "Unexpected postfix ${node.op} "
            "operator argument ${node.argument}";
      }
    }
    return withExpression(node.argument,
        (js.Expression argument) => new js.Postfix(node.op, argument),
        store: false);
  }

  @override
  js.Expression visitPrefix(js.Prefix node) {
    if (node.op == "++" || node.op == "--") {
      js.Expression argument = node.argument;
      if (argument is js.VariableUse) {
        return new js.Prefix(node.op, visitExpression(argument));
      } else if (argument is js.PropertyAccess) {
        return withExpression2(argument.receiver, argument.selector,
            (receiver, selector) {
          return new js.Prefix(
              node.op, new js.PropertyAccess(receiver, selector));
        });
      } else {
        throw "Unexpected prefix ${node.op} operator "
            "argument ${node.argument}";
      }
    }
    return withExpression(node.argument,
        (js.Expression argument) => new js.Prefix(node.op, argument),
        store: false);
  }

  @override
  visitProgram(js.Program node) => unsupported(node);

  @override
  js.Property visitProperty(js.Property node) {
    return withExpression(
        node.value, (js.Expression value) => new js.Property(node.name, value),
        store: false);
  }

  @override
  js.Expression visitRegExpLiteral(js.RegExpLiteral node) => node;

  @override
  void visitReturn(js.Return node) {
    js.Node target = analysis.targets[node];
    if (node.value != null) {
      if (isSyncStar || isAsyncStar) {
        // Even though `return expr;` is not allowed in the dart sync* and
        // async*  code, the backend sometimes generates code like this, but
        // only when it is known that the 'expr' throws, and the return is just
        // to tell the JavaScript VM that the code won't continue here.
        // It is therefore interpreted as `expr; return;`
        visitExpressionIgnoreResult(node.value);
      } else {
        withExpression(node.value, (js.Expression value) {
          addStatement(js.js.statement("# = #;", [returnValue, value]));
        }, store: false);
      }
    }
    translateJump(target, exitLabel);
  }

  @override
  void visitSwitch(js.Switch node) {
    if (!node.cases.any(shouldTransform)) {
      // If only the key has an await, translation can be simplified.
      bool oldInsideUntranslated = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      withExpression(node.key, (js.Expression key) {
        List<js.SwitchClause> cases = node.cases.map((js.SwitchClause clause) {
          if (clause is js.Case) {
            return new js.Case(
                clause.expression, translateToBlock(clause.body));
          } else if (clause is js.Default) {
            return new js.Default(translateToBlock(clause.body));
          }
        }).toList();
        addStatement(new js.Switch(key, cases));
      }, store: false);
      insideUntranslatedBreakable = oldInsideUntranslated;
      return;
    }
    int before = newLabel("switch");
    int after = newLabel("after switch");
    breakLabels[node] = after;

    beginLabel(before);
    List<int> labels = new List<int>(node.cases.length);

    bool anyCaseExpressionTransformed = node.cases.any(
        (js.SwitchClause x) => x is js.Case && shouldTransform(x.expression));
    if (anyCaseExpressionTransformed) {
      int defaultIndex = null; // Null means no default was found.
      // If there is an await in one of the keys, a chain of ifs has to be used.

      withExpression(node.key, (js.Expression key) {
        int i = 0;
        for (js.SwitchClause clause in node.cases) {
          if (clause is js.Default) {
            // The goto for the default case is added after all non-default
            // clauses have been handled.
            defaultIndex = i;
            labels[i] = newLabel("default");
            continue;
          } else if (clause is js.Case) {
            labels[i] = newLabel("case");
            withExpression(clause.expression, (expression) {
              addStatement(new js.If.noElse(
                  new js.Binary("===", key, expression),
                  gotoAndBreak(labels[i])));
            }, store: false);
          }
          i++;
        }
      }, store: true);

      if (defaultIndex == null) {
        addGoto(after);
      } else {
        addGoto(labels[defaultIndex]);
      }
    } else {
      bool hasDefault = false;
      int i = 0;
      List<js.SwitchClause> clauses = <js.SwitchClause>[];
      for (js.SwitchClause clause in node.cases) {
        if (clause is js.Case) {
          labels[i] = newLabel("case");
          clauses.add(new js.Case(
              visitExpression(clause.expression), gotoAndBreak(labels[i])));
        } else if (clause is js.Default) {
          labels[i] = newLabel("default");
          clauses.add(new js.Default(gotoAndBreak(labels[i])));
          hasDefault = true;
        } else {
          reporter.internalError(spannable, "Unknown clause type $clause");
        }
        i++;
      }
      if (!hasDefault) {
        clauses.add(new js.Default(gotoAndBreak(after)));
      }
      withExpression(node.key, (js.Expression key) {
        addStatement(new js.Switch(key, clauses));
      }, store: false);

      addBreak();
    }

    jumpTargets.add(node);
    for (int i = 0; i < labels.length; i++) {
      beginLabel(labels[i]);
      visitStatement(node.cases[i].body);
    }
    beginLabel(after);
    jumpTargets.removeLast();
  }

  @override
  js.Expression visitThis(js.This node) {
    return self;
  }

  @override
  void visitThrow(js.Throw node) {
    withExpression(node.expression, (js.Expression expression) {
      addStatement(new js.Throw(expression)
          .withSourceInformation(node.sourceInformation));
    }, store: false);
  }

  setErrorHandler([int errorHandler]) {
    hasHandlerLabels = true; // TODO(sra): Add short form error handler.
    js.Expression label =
        (errorHandler == null) ? currentErrorHandler : js.number(errorHandler);
    addStatement(js.js.statement('# = #;', [handler, label]));
  }

  List<int> _finalliesUpToAndEnclosingHandler() {
    List<int> result = <int>[];
    for (int i = jumpTargets.length - 1; i >= 0; i--) {
      js.Node node = jumpTargets[i];
      int handlerLabel = handlerLabels[node];
      if (handlerLabel != null) {
        result.add(handlerLabel);
        break;
      }
      int finallyLabel = finallyLabels[node];
      if (finallyLabel != null) {
        result.add(finallyLabel);
      }
    }
    return result.reversed.toList();
  }

  /// See the comments of [rewriteFunction] for more explanation.
  void visitTry(js.Try node) {
    if (!shouldTransform(node)) {
      js.Block body = translateToBlock(node.body);
      js.Catch catchPart = (node.catchPart == null)
          ? null
          : new js.Catch(node.catchPart.declaration,
              translateToBlock(node.catchPart.body));
      js.Block finallyPart = (node.finallyPart == null)
          ? null
          : translateToBlock(node.finallyPart);
      addStatement(new js.Try(body, catchPart, finallyPart));
      return;
    }

    hasTryBlocks = true;
    int uncaughtLabel = newLabel("uncaught");
    int handlerLabel =
        (node.catchPart == null) ? uncaughtLabel : newLabel("catch");

    int finallyLabel = newLabel("finally");
    int afterFinallyLabel = newLabel("after finally");
    if (node.finallyPart != null) {
      finallyLabels[node.finallyPart] = finallyLabel;
      jumpTargets.add(node.finallyPart);
    }

    handlerLabels[node] = handlerLabel;
    jumpTargets.add(node);

    // Set the error handler here. It must be cleared on every path out;
    // normal and error exit.
    setErrorHandler();

    visitStatement(node.body);

    js.Node last = jumpTargets.removeLast();
    assert(last == node);

    if (node.finallyPart == null) {
      setErrorHandler();
      addGoto(afterFinallyLabel);
    } else {
      // The handler is reset as the first thing in the finally block.
      addStatement(
          js.js.statement("#.push(#);", [next, js.number(afterFinallyLabel)]));
      addGoto(finallyLabel);
    }

    if (node.catchPart != null) {
      beginLabel(handlerLabel);
      // [uncaughtLabel] is the handler for the code in the catch-part.
      // It ensures that [nextName] is set up to run the right finally blocks.
      handlerLabels[node.catchPart] = uncaughtLabel;
      jumpTargets.add(node.catchPart);
      setErrorHandler();
      // The catch declaration name can shadow outer variables, so a fresh name
      // is needed to avoid collisions.  See Ecma 262, 3rd edition,
      // section 12.14.
      String errorRename = freshName(node.catchPart.declaration.name);
      localVariables.add(new js.VariableDeclaration(errorRename));
      variableRenamings
          .add(new Pair(node.catchPart.declaration.name, errorRename));
      addStatement(js.js.statement("# = #;", [errorRename, currentError]));
      visitStatement(node.catchPart.body);
      variableRenamings.removeLast();
      if (node.finallyPart != null) {
        // The error has been caught, so after the finally, continue after the
        // try.
        addStatement(js.js
            .statement("#.push(#);", [next, js.number(afterFinallyLabel)]));
        addGoto(finallyLabel);
      } else {
        addGoto(afterFinallyLabel);
      }
      js.Node last = jumpTargets.removeLast();
      assert(last == node.catchPart);
    }

    // The "uncaught"-handler tells the finally-block to continue with
    // the enclosing finally-blocks until the current catch-handler.
    beginLabel(uncaughtLabel);

    List<int> enclosingFinallies = _finalliesUpToAndEnclosingHandler();

    int nextLabel = enclosingFinallies.removeLast();
    if (enclosingFinallies.isNotEmpty) {
      // [enclosingFinallies] can be empty if there is no surrounding finally
      // blocks. Then [nextLabel] will be [rethrowLabel].
      addStatement(js.js.statement("# = #;", [
        next,
        new js.ArrayInitializer(enclosingFinallies.map(js.number).toList())
      ]));
    }
    if (node.finallyPart == null) {
      // The finally-block belonging to [node] will be visited because of
      // fallthrough. If it does not exist, add an explicit goto.
      addGoto(nextLabel);
    }
    if (node.finallyPart != null) {
      js.Node last = jumpTargets.removeLast();
      assert(last == node.finallyPart);

      beginLabel(finallyLabel);
      setErrorHandler();
      visitStatement(node.finallyPart);
      addStatement(new js.Comment("// goto the next finally handler"));
      addStatement(js.js.statement("# = #.pop();", [goto, next]));
      addBreak();
    }
    beginLabel(afterFinallyLabel);
  }

  @override
  visitVariableDeclaration(js.VariableDeclaration node) {
    unreachable(node);
  }

  @override
  js.Expression visitVariableDeclarationList(js.VariableDeclarationList node) {
    for (js.VariableInitialization initialization in node.declarations) {
      js.VariableDeclaration declaration = initialization.declaration;
      localVariables.add(declaration);
      if (initialization.value != null) {
        withExpression(initialization.value, (js.Expression value) {
          addExpressionStatement(
              new js.Assignment(new js.VariableUse(declaration.name), value));
        }, store: false);
      }
    }
    return js.number(0); // Dummy expression.
  }

  @override
  void visitVariableInitialization(js.VariableInitialization node) {
    unreachable(node);
  }

  @override
  js.Expression visitVariableUse(js.VariableUse node) {
    Pair<String, String> renaming = variableRenamings.lastWhere(
        (Pair renaming) => renaming.a == node.name,
        orElse: () => null);
    if (renaming == null) return node;
    return new js.VariableUse(renaming.b);
  }

  @override
  void visitWhile(js.While node) {
    if (!shouldTransform(node)) {
      bool oldInsideUntranslated = insideUntranslatedBreakable;
      insideUntranslatedBreakable = true;
      withExpression(node.condition, (js.Expression condition) {
        addStatement(new js.While(condition, translateToStatement(node.body)));
      }, store: false);
      insideUntranslatedBreakable = oldInsideUntranslated;
      return;
    }
    int continueLabel = newLabel("while condition");
    continueLabels[node] = continueLabel;
    beginLabel(continueLabel);

    int afterLabel = newLabel("after while");
    breakLabels[node] = afterLabel;
    js.Expression condition = node.condition;
    // If the condition is `true`, a test is not needed.
    if (!(condition is js.LiteralBool && condition.value == true)) {
      withExpression(node.condition, (js.Expression condition) {
        addStatement(new js.If.noElse(
            new js.Prefix("!", condition), gotoAndBreak(afterLabel)));
      }, store: false);
    }
    jumpTargets.add(node);
    visitStatement(node.body);
    jumpTargets.removeLast();
    addGoto(continueLabel);
    beginLabel(afterLabel);
  }

  addYield(js.DartYield node, js.Expression expression);

  @override
  void visitDartYield(js.DartYield node) {
    assert(isSyncStar || isAsyncStar);
    int label = newLabel("after yield");
    // Don't do a break here for the goto, but instead a return in either
    // addSynYield or addAsyncYield.
    withExpression(node.expression, (js.Expression expression) {
      addStatement(setGotoVariable(label));
      addYield(node, expression);
    }, store: false);
    beginLabel(label);
  }
}

js.VariableInitialization _makeVariableInitializer(
    dynamic variable, js.Expression initValue) {
  js.VariableDeclaration declaration;
  if (variable is js.VariableUse) {
    declaration = new js.VariableDeclaration(variable.name);
  } else if (variable is String) {
    declaration = new js.VariableDeclaration(variable);
  } else {
    assert(variable is js.VariableDeclaration);
    declaration = variable;
  }
  return new js.VariableInitialization(declaration, initValue);
}

class AsyncRewriter extends AsyncRewriterBase {
  bool get isAsync => true;

  /// The Completer that will finish an async function.
  ///
  /// Not used for sync* or async* functions.
  String completerName;
  js.VariableUse get completer => new js.VariableUse(completerName);

  /// The function called by an async function to initiate asynchronous
  /// execution of the body.  This is called with:
  ///
  /// - The body function [bodyName].
  /// - the completer object [completer].
  ///
  /// It returns the completer's future. Passing the completer and returning its
  /// future is a convenience to allow both the initiation and fetching the
  /// future to be compactly encoded in a return statement's expression.
  final js.Expression asyncStart;

  /// Function called by the async function to simulate an `await`
  /// expression. It is called with:
  ///
  /// - The value to await
  /// - The body function [bodyName]
  final js.Expression asyncAwait;

  /// Function called by the async function to simulate a return.
  /// It is called with:
  ///
  /// - The value to return
  /// - The completer object [completer]
  final js.Expression asyncReturn;

  /// Function called by the async function to simulate a rethrow.
  /// It is called with:
  ///
  /// - The value containing the exception and stack
  /// - The completer object [completer]
  final js.Expression asyncRethrow;

  /// Constructor used to initialize the [completer] variable.
  ///
  /// Specific to async methods.
  final js.Expression completerFactory;

  final js.Expression wrapBody;

  AsyncRewriter(DiagnosticReporter reporter, Spannable spannable,
      {this.asyncStart,
      this.asyncAwait,
      this.asyncReturn,
      this.asyncRethrow,
      this.completerFactory,
      this.wrapBody,
      String safeVariableName(String proposedName),
      js.Name bodyName})
      : super(reporter, spannable, safeVariableName, bodyName);

  @override
  void addYield(js.DartYield node, js.Expression expression) {
    reporter.internalError(spannable, "Yield in non-generating async function");
  }

  void addErrorExit() {
    if (!hasHandlerLabels) return; // rethrow handled in method boilerplate.
    beginLabel(rethrowLabel);
    addStatement(js.js.statement(
        "return #thenHelper(#currentError, #completer);", {
      "thenHelper": asyncRethrow,
      "currentError": currentError,
      "completer": completer
    }));
  }

  /// Returning from an async method calls [asyncStarHelper] with the result.
  /// (the result might have been stored in [returnValue] by some finally
  /// block).
  void addSuccesExit() {
    if (analysis.hasExplicitReturns) {
      beginLabel(exitLabel);
    } else {
      addStatement(new js.Comment("implicit return"));
    }
    addStatement(
        js.js.statement("return #runtimeHelper(#returnValue, #completer);", {
      "runtimeHelper": asyncReturn,
      "returnValue":
          analysis.hasExplicitReturns ? returnValue : new js.LiteralNull(),
      "completer": completer
    }));
  }

  @override
  Iterable<js.VariableInitialization> variableInitializations() {
    List<js.VariableInitialization> variables = <js.VariableInitialization>[];
    variables.add(
        _makeVariableInitializer(completer, new js.Call(completerFactory, [])));
    if (analysis.hasExplicitReturns) {
      variables.add(_makeVariableInitializer(returnValue, null));
    }
    return variables;
  }

  @override
  void initializeNames() {
    completerName = freshName("completer");
  }

  @override
  js.Statement awaitStatement(js.Expression value) {
    return js.js.statement(
        """
          return #asyncHelper(#value,
                              #bodyName);
          """,
        {
          "asyncHelper": asyncAwait,
          "value": value,
          "bodyName": bodyName,
        });
  }

  @override
  js.Fun finishFunction(
      List<js.Parameter> parameters,
      js.Statement rewrittenBody,
      js.VariableDeclarationList variableDeclarations,
      SourceInformation sourceInformation) {
    return js.js(
        """
        function (#parameters) {
          #variableDeclarations;
          var #bodyName = #wrapBody(function (#errorCode, #result) {
            if (#errorCode === #ERROR) {
              if (#hasHandlerLabels) {
                  #currentError = #result;
                  #goto = #handler;
              } else
                  return #asyncRethrow(#result, #completer);
            }
            #rewrittenBody;
          });
          return #asyncStart(#bodyName, #completer);
        }""",
        {
          "parameters": parameters,
          "variableDeclarations": variableDeclarations,
          "ERROR": js.number(error_codes.ERROR),
          "rewrittenBody": rewrittenBody,
          "bodyName": bodyName,
          "currentError": currentError,
          "goto": goto,
          "handler": handler,
          "errorCode": errorCodeName,
          "result": resultName,
          "asyncStart": asyncStart,
          "asyncRethrow": asyncRethrow,
          "hasHandlerLabels": hasHandlerLabels,
          "completer": completer,
          "wrapBody": wrapBody,
        }).withSourceInformation(sourceInformation);
  }
}

class SyncStarRewriter extends AsyncRewriterBase {
  bool get isSyncStar => true;

  /// Constructor creating the Iterable for a sync* method. Called with
  /// [bodyName].
  final js.Expression iterableFactory;

  /// A JS Expression that creates a marker showing that iteration is over.
  ///
  /// Called without arguments.
  final js.Expression endOfIteration;

  /// A JS Expression that creates a marker indication a 'yield*' statement.
  ///
  /// Called with the stream to yield from.
  final js.Expression yieldStarExpression;

  /// Used by sync* functions to throw exeptions.
  final js.Expression uncaughtErrorExpression;

  SyncStarRewriter(DiagnosticReporter diagnosticListener, spannable,
      {this.endOfIteration,
      this.iterableFactory,
      this.yieldStarExpression,
      this.uncaughtErrorExpression,
      String safeVariableName(String proposedName),
      js.Name bodyName})
      : super(diagnosticListener, spannable, safeVariableName, bodyName);

  /// Translates a yield/yield* in an sync*.
  ///
  /// `yield` in a sync* function just returns [value].
  /// `yield*` wraps [value] in a [yieldStarExpression] and returns it.
  @override
  void addYield(js.DartYield node, js.Expression expression) {
    if (node.hasStar) {
      addStatement(
          new js.Return(new js.Call(yieldStarExpression, [expression])));
    } else {
      addStatement(new js.Return(expression));
    }
  }

  @override
  js.Fun finishFunction(
      List<js.Parameter> parameters,
      js.Statement rewrittenBody,
      js.VariableDeclarationList variableDeclarations,
      SourceInformation sourceInformation) {
    // Each iterator invocation on the iterable should work on its own copy of
    // the parameters.
    // TODO(sigurdm): We only need to do this copying for parameters that are
    // mutated.
    List<js.VariableInitialization> declarations =
        <js.VariableInitialization>[];
    List<js.Parameter> renamedParameters = <js.Parameter>[];
    for (js.Parameter parameter in parameters) {
      String name = parameter.name;
      String renamedName = freshName(name);
      renamedParameters.add(new js.Parameter(renamedName));
      declarations.add(new js.VariableInitialization(
          new js.VariableDeclaration(name), new js.VariableUse(renamedName)));
    }
    js.VariableDeclarationList copyParameters =
        new js.VariableDeclarationList(declarations);
    return js.js(
        """
          function (#renamedParameters) {
            if (#needsThis)
              var #self = this;
            return #iterableFactory(function () {
              if (#hasParameters) {
                #copyParameters;
              }
              #varDecl;
              return function #body(#errorCode, #result) {
                if (#errorCode === #ERROR) {
                    #currentError = #result;
                    #goto = #handler;
                }
                #helperBody;
              };
            });
          }
          """,
        {
          "renamedParameters": renamedParameters,
          "needsThis": analysis.hasThis,
          "helperBody": rewrittenBody,
          "hasParameters": parameters.isNotEmpty,
          "copyParameters": copyParameters,
          "varDecl": variableDeclarations,
          "errorCode": errorCodeName,
          "iterableFactory": iterableFactory,
          "body": bodyName,
          "self": selfName,
          "result": resultName,
          "goto": goto,
          "handler": handler,
          "currentError": currentErrorName,
          "ERROR": js.number(error_codes.ERROR),
        }).withSourceInformation(sourceInformation);
  }

  void addErrorExit() {
    hasHandlerLabels = true; // TODO(sra): Add short form error handler.
    beginLabel(rethrowLabel);
    addStatement(js.js
        .statement('return #(#);', [uncaughtErrorExpression, currentError]));
  }

  /// Returning from a sync* function returns an [endOfIteration] marker.
  void addSuccesExit() {
    if (analysis.hasExplicitReturns) {
      beginLabel(exitLabel);
    } else {
      addStatement(new js.Comment("implicit return"));
    }
    addStatement(js.js.statement('return #();', [endOfIteration]));
  }

  @override
  Iterable<js.VariableInitialization> variableInitializations() {
    List<js.VariableInitialization> variables = <js.VariableInitialization>[];
    return variables;
  }

  @override
  js.Statement awaitStatement(js.Expression value) {
    throw reporter.internalError(
        spannable, "Sync* functions cannot contain await statements.");
  }

  @override
  void initializeNames() {}
}

class AsyncStarRewriter extends AsyncRewriterBase {
  bool get isAsyncStar => true;

  /// The stack of labels of finally blocks to assign to [next] if the
  /// async* [StreamSubscription] was canceled during a yield.
  js.VariableUse get nextWhenCanceled {
    return new js.VariableUse(nextWhenCanceledName);
  }

  String nextWhenCanceledName;

  /// The StreamController that controls an async* function.
  String controllerName;
  js.VariableUse get controller => new js.VariableUse(controllerName);

  /// The function called by an async* function to simulate an await, yield or
  /// yield*.
  ///
  /// For an await/yield/yield* it is called with:
  ///
  /// - The value to await/yieldExpression(value to yield)/
  /// yieldStarExpression(stream to yield)
  /// - The body function [bodyName]
  /// - The controller object [controllerName]
  ///
  /// For a return it is called with:
  ///
  /// - null
  /// - null
  /// - The [controllerName]
  /// - null.
  final js.Expression asyncStarHelper;

  /// Constructor used to initialize the [controllerName] variable.
  ///
  /// Specific to async* methods.
  final js.Expression newController;

  /// Used to get the `Stream` out of the [controllerName] variable.
  final js.Expression streamOfController;

  /// A JS Expression that creates a marker indicating a 'yield' statement.
  ///
  /// Called with the value to yield.
  final js.Expression yieldExpression;

  /// A JS Expression that creates a marker indication a 'yield*' statement.
  ///
  /// Called with the stream to yield from.
  final js.Expression yieldStarExpression;

  final js.Expression wrapBody;

  AsyncStarRewriter(DiagnosticReporter reporter, Spannable spannable,
      {this.asyncStarHelper,
      this.streamOfController,
      this.newController,
      this.yieldExpression,
      this.yieldStarExpression,
      this.wrapBody,
      String safeVariableName(String proposedName),
      js.Name bodyName})
      : super(reporter, spannable, safeVariableName, bodyName);

  /// Translates a yield/yield* in an async* function.
  ///
  /// yield/yield* in an async* function is translated much like the `await` is
  /// translated in [visitAwait], only the object is wrapped in a
  /// [yieldExpression]/[yieldStarExpression] to let [asyncStarHelper]
  /// distinguish them.
  /// Also [nextWhenCanceled] is set up to contain the finally blocks that
  /// must be run in case the stream was canceled.
  @override
  void addYield(js.DartYield node, js.Expression expression) {
    // Find all the finally blocks that should be performed if the stream is
    // canceled during the yield.
    // At the bottom of the stack is the return label.
    List<int> enclosingFinallyLabels = <int>[exitLabel];
    enclosingFinallyLabels.addAll(jumpTargets
        .where((js.Node node) => finallyLabels[node] != null)
        .map((js.Block node) => finallyLabels[node]));
    addStatement(js.js.statement("# = #;", [
      nextWhenCanceled,
      new js.ArrayInitializer(enclosingFinallyLabels.map(js.number).toList())
    ]));
    addStatement(js.js.statement(
        """
        return #asyncStarHelper(#yieldExpression(#expression), #bodyName,
            #controller);""",
        {
          "asyncStarHelper": asyncStarHelper,
          "yieldExpression":
              node.hasStar ? yieldStarExpression : yieldExpression,
          "expression": expression,
          "bodyName": bodyName,
          "controller": controllerName,
        }));
  }

  @override
  js.Fun finishFunction(
      List<js.Parameter> parameters,
      js.Statement rewrittenBody,
      js.VariableDeclarationList variableDeclarations,
      SourceInformation sourceInformation) {
    return js.js(
        """
        function (#parameters) {
          var #bodyName = #wrapBody(function (#errorCode, #result) {
            if (#hasYield) {
              switch (#errorCode) {
                case #STREAM_WAS_CANCELED:
                  #next = #nextWhenCanceled;
                  #goto = #next.pop();
                  break;
                case #ERROR:
                  #currentError = #result;
                  #goto = #handler;
              }
            } else {
              if (#errorCode === #ERROR) {
                #currentError = #result;
                #goto = #handler;
              }
            }
            #rewrittenBody;
          });
          #variableDeclarations;
          return #streamOfController(#controller);
        }""",
        {
          "parameters": parameters,
          "variableDeclarations": variableDeclarations,
          "STREAM_WAS_CANCELED": js.number(error_codes.STREAM_WAS_CANCELED),
          "ERROR": js.number(error_codes.ERROR),
          "hasYield": analysis.hasYield,
          "rewrittenBody": rewrittenBody,
          "bodyName": bodyName,
          "currentError": currentError,
          "goto": goto,
          "handler": handler,
          "next": next,
          "nextWhenCanceled": nextWhenCanceled,
          "errorCode": errorCodeName,
          "result": resultName,
          "streamOfController": streamOfController,
          "controller": controllerName,
          "wrapBody": wrapBody,
        }).withSourceInformation(sourceInformation);
  }

  @override
  void addErrorExit() {
    hasHandlerLabels = true;
    beginLabel(rethrowLabel);
    addStatement(js.js.statement(
        "return #asyncHelper(#currentError, #errorCode, #controller);", {
      "asyncHelper": asyncStarHelper,
      "errorCode": js.number(error_codes.ERROR),
      "currentError": currentError,
      "controller": controllerName
    }));
  }

  /// Returning from an async* function calls the [streamHelper] with an
  /// [endOfIteration] marker.
  @override
  void addSuccesExit() {
    beginLabel(exitLabel);

    addStatement(js.js
        .statement("return #streamHelper(null, #successCode, #controller);", {
      "streamHelper": asyncStarHelper,
      "successCode": js.number(error_codes.SUCCESS),
      "controller": controllerName
    }));
  }

  @override
  Iterable<js.VariableInitialization> variableInitializations() {
    List<js.VariableInitialization> variables = <js.VariableInitialization>[];
    variables.add(_makeVariableInitializer(
        controller, js.js('#(#)', [newController, bodyName])));
    if (analysis.hasYield) {
      variables.add(_makeVariableInitializer(nextWhenCanceled, null));
    }
    return variables;
  }

  @override
  void initializeNames() {
    controllerName = freshName("controller");
    nextWhenCanceledName = freshName("nextWhenCanceled");
  }

  @override
  js.Statement awaitStatement(js.Expression value) {
    return js.js.statement(
        """
          return #asyncHelper(#value,
                              #bodyName,
                              #controller);
          """,
        {
          "asyncHelper": asyncStarHelper,
          "value": value,
          "bodyName": bodyName,
          "controller": controllerName
        });
  }
}

/// Finds out
///
/// - which expressions have yield or await nested in them.
/// - targets of jumps
/// - a set of used names.
/// - if any [This]-expressions are used.
class PreTranslationAnalysis extends js.NodeVisitor<bool> {
  Set<js.Node> hasAwaitOrYield = new Set<js.Node>();

  Map<js.Node, js.Node> targets = new Map<js.Node, js.Node>();
  List<js.Node> loopsAndSwitches = <js.Node>[];
  List<js.LabeledStatement> labelledStatements = <js.LabeledStatement>[];
  Set<String> usedNames = new Set<String>();

  bool hasExplicitReturns = false;

  bool hasThis = false;

  bool hasYield = false;

  bool hasFinally = false;

  // The function currently being analyzed.
  js.Fun currentFunction;

  // For error messages.
  final Function unsupported;

  PreTranslationAnalysis(void this.unsupported(js.Node node));

  bool visit(js.Node node) {
    bool containsAwait = node.accept(this);
    if (containsAwait) {
      hasAwaitOrYield.add(node);
    }
    return containsAwait;
  }

  analyze(js.Fun node) {
    currentFunction = node;
    node.params.forEach(visit);
    visit(node.body);
  }

  @override
  bool visitAccess(js.PropertyAccess node) {
    bool receiver = visit(node.receiver);
    bool selector = visit(node.selector);
    return receiver || selector;
  }

  @override
  bool visitArrayHole(js.ArrayHole node) {
    return false;
  }

  @override
  bool visitArrayInitializer(js.ArrayInitializer node) {
    bool containsAwait = false;
    for (js.Expression element in node.elements) {
      if (visit(element)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitAssignment(js.Assignment node) {
    bool leftHandSide = visit(node.leftHandSide);
    bool value = (node.value == null) ? false : visit(node.value);
    return leftHandSide || value;
  }

  @override
  bool visitAwait(js.Await node) {
    visit(node.expression);
    return true;
  }

  @override
  bool visitBinary(js.Binary node) {
    bool left = visit(node.left);
    bool right = visit(node.right);
    return left || right;
  }

  @override
  bool visitBlock(js.Block node) {
    bool containsAwait = false;
    for (js.Statement statement in node.statements) {
      if (visit(statement)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitBreak(js.Break node) {
    if (node.targetLabel != null) {
      targets[node] =
          labelledStatements.lastWhere((js.LabeledStatement statement) {
        return statement.label == node.targetLabel;
      });
    } else {
      targets[node] = loopsAndSwitches.last;
    }
    return false;
  }

  @override
  bool visitCall(js.Call node) {
    bool containsAwait = visit(node.target);
    for (js.Expression argument in node.arguments) {
      if (visit(argument)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitCase(js.Case node) {
    bool expression = visit(node.expression);
    bool body = visit(node.body);
    return expression || body;
  }

  @override
  bool visitCatch(js.Catch node) {
    bool declaration = visit(node.declaration);
    bool body = visit(node.body);
    return declaration || body;
  }

  @override
  bool visitComment(js.Comment node) {
    return false;
  }

  @override
  bool visitConditional(js.Conditional node) {
    bool condition = visit(node.condition);
    bool then = visit(node.then);
    bool otherwise = visit(node.otherwise);
    return condition || then || otherwise;
  }

  @override
  bool visitContinue(js.Continue node) {
    if (node.targetLabel != null) {
      js.LabeledStatement targetLabel = labelledStatements.lastWhere(
          (js.LabeledStatement stm) => stm.label == node.targetLabel);
      js.Loop targetStatement = targetLabel.body;
      targets[node] = targetStatement;
    } else {
      targets[node] =
          loopsAndSwitches.lastWhere((js.Node node) => node is! js.Switch);
    }
    assert(() {
      js.Node target = targets[node];
      return target is js.Loop ||
          (target is js.LabeledStatement && target.body is js.Loop);
    });
    return false;
  }

  @override
  bool visitDefault(js.Default node) {
    return visit(node.body);
  }

  @override
  bool visitDo(js.Do node) {
    loopsAndSwitches.add(node);
    bool body = visit(node.body);
    bool condition = visit(node.condition);
    loopsAndSwitches.removeLast();
    return body || condition;
  }

  @override
  bool visitEmptyStatement(js.EmptyStatement node) {
    return false;
  }

  @override
  bool visitExpressionStatement(js.ExpressionStatement node) {
    return visit(node.expression);
  }

  @override
  bool visitFor(js.For node) {
    bool init = (node.init == null) ? false : visit(node.init);
    bool condition = (node.condition == null) ? false : visit(node.condition);
    bool update = (node.update == null) ? false : visit(node.update);
    loopsAndSwitches.add(node);
    bool body = visit(node.body);
    loopsAndSwitches.removeLast();
    return init || condition || update || body;
  }

  @override
  bool visitForIn(js.ForIn node) {
    bool object = visit(node.object);
    loopsAndSwitches.add(node);
    bool body = visit(node.body);
    loopsAndSwitches.removeLast();
    return object || body;
  }

  @override
  bool visitFun(js.Fun node) {
    return false;
  }

  @override
  bool visitFunctionDeclaration(js.FunctionDeclaration node) {
    return false;
  }

  @override
  bool visitIf(js.If node) {
    bool condition = visit(node.condition);
    bool then = visit(node.then);
    bool otherwise = visit(node.otherwise);
    return condition || then || otherwise;
  }

  @override
  bool visitInterpolatedExpression(js.InterpolatedExpression node) {
    return unsupported(node);
  }

  @override
  bool visitInterpolatedDeclaration(js.InterpolatedDeclaration node) {
    return unsupported(node);
  }

  @override
  bool visitInterpolatedLiteral(js.InterpolatedLiteral node) {
    return unsupported(node);
  }

  @override
  bool visitInterpolatedParameter(js.InterpolatedParameter node) {
    return unsupported(node);
  }

  @override
  bool visitInterpolatedSelector(js.InterpolatedSelector node) {
    return unsupported(node);
  }

  @override
  bool visitInterpolatedStatement(js.InterpolatedStatement node) {
    return unsupported(node);
  }

  @override
  bool visitLabeledStatement(js.LabeledStatement node) {
    usedNames.add(node.label);
    labelledStatements.add(node);
    bool containsAwait = visit(node.body);
    labelledStatements.removeLast();
    return containsAwait;
  }

  @override
  bool visitDeferredExpression(js.DeferredExpression node) {
    return false;
  }

  @override
  bool visitDeferredNumber(js.DeferredNumber node) {
    return false;
  }

  @override
  bool visitDeferredString(js.DeferredString node) {
    return false;
  }

  @override
  bool visitLiteralBool(js.LiteralBool node) {
    return false;
  }

  @override
  bool visitLiteralExpression(js.LiteralExpression node) {
    return unsupported(node);
  }

  @override
  bool visitLiteralNull(js.LiteralNull node) {
    return false;
  }

  @override
  bool visitLiteralNumber(js.LiteralNumber node) {
    return false;
  }

  @override
  bool visitLiteralStatement(js.LiteralStatement node) {
    return unsupported(node);
  }

  @override
  bool visitLiteralString(js.LiteralString node) {
    return false;
  }

  @override
  bool visitStringConcatenation(js.StringConcatenation node) {
    return false;
  }

  @override
  bool visitName(js.Name node) {
    return false;
  }

  @override
  bool visitNamedFunction(js.NamedFunction node) {
    return false;
  }

  @override
  bool visitNew(js.New node) {
    return visitCall(node);
  }

  @override
  bool visitObjectInitializer(js.ObjectInitializer node) {
    bool containsAwait = false;
    for (js.Property property in node.properties) {
      if (visit(property)) containsAwait = true;
    }
    return containsAwait;
  }

  @override
  bool visitParameter(js.Parameter node) {
    usedNames.add(node.name);
    return false;
  }

  @override
  bool visitPostfix(js.Postfix node) {
    return visit(node.argument);
  }

  @override
  bool visitPrefix(js.Prefix node) {
    return visit(node.argument);
  }

  @override
  bool visitProgram(js.Program node) {
    throw "Unexpected";
  }

  @override
  bool visitProperty(js.Property node) {
    return visit(node.value);
  }

  @override
  bool visitRegExpLiteral(js.RegExpLiteral node) {
    return false;
  }

  @override
  bool visitReturn(js.Return node) {
    hasExplicitReturns = true;
    targets[node] = currentFunction;
    if (node.value == null) return false;
    return visit(node.value);
  }

  @override
  bool visitSwitch(js.Switch node) {
    loopsAndSwitches.add(node);
    // If the key has an `await` expression, do not transform the
    // body of the switch.
    visit(node.key);
    bool result = false;
    for (js.SwitchClause clause in node.cases) {
      if (visit(clause)) result = true;
    }
    loopsAndSwitches.removeLast();
    return result;
  }

  @override
  bool visitThis(js.This node) {
    hasThis = true;
    return false;
  }

  @override
  bool visitThrow(js.Throw node) {
    return visit(node.expression);
  }

  @override
  bool visitTry(js.Try node) {
    bool body = visit(node.body);
    bool catchPart = (node.catchPart == null) ? false : visit(node.catchPart);
    bool finallyPart =
        (node.finallyPart == null) ? false : visit(node.finallyPart);
    if (finallyPart != null) hasFinally = true;
    return body || catchPart || finallyPart;
  }

  @override
  bool visitVariableDeclaration(js.VariableDeclaration node) {
    usedNames.add(node.name);
    return false;
  }

  @override
  bool visitVariableDeclarationList(js.VariableDeclarationList node) {
    bool result = false;
    for (js.VariableInitialization init in node.declarations) {
      if (visit(init)) result = true;
    }
    return result;
  }

  @override
  bool visitVariableInitialization(js.VariableInitialization node) {
    return visitAssignment(node);
  }

  @override
  bool visitVariableUse(js.VariableUse node) {
    usedNames.add(node.name);
    return false;
  }

  @override
  bool visitWhile(js.While node) {
    loopsAndSwitches.add(node);
    bool condition = visit(node.condition);
    bool body = visit(node.body);
    loopsAndSwitches.removeLast();
    return condition || body;
  }

  @override
  bool visitDartYield(js.DartYield node) {
    hasYield = true;
    visit(node.expression);
    return true;
  }
}
