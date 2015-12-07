// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.mutable_ssa;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';

/// Determines which mutable variables should be rewritten to phi assignments
/// in this pass.
///
/// We do not rewrite variables that have an assignment inside a try block that
/// does not contain its declaration.
class MutableVariablePreanalysis extends TrampolineRecursiveVisitor {
  // Number of try blocks enclosing the current position.
  int currentDepth = 0;

  /// Number of try blocks enclosing the declaration of a given mutable
  /// variable.
  ///
  /// All mutable variables seen will be present in the map after the analysis.
  Map<MutableVariable, int> variableDepth = <MutableVariable, int>{};

  /// Variables with an assignment inside a try block that does not contain
  /// its declaration.
  Set<MutableVariable> hasAssignmentInTry = new Set<MutableVariable>();

  @override
  Expression traverseLetHandler(LetHandler node) {
    push(node.handler);
    ++currentDepth;
    pushAction(() => --currentDepth);
    return node.body;
  }

  void processLetMutable(LetMutable node) {
    variableDepth[node.variable] = currentDepth;
  }

  void processSetMutable(SetMutable node) {
    MutableVariable variable = node.variable.definition;
    if (currentDepth > variableDepth[variable]) {
      hasAssignmentInTry.add(variable);
    }
  }

  /// True if there are no mutable variables or they are all assigned inside
  /// a try block. In this case, there is nothing to do and the pass should
  /// be skipped.
  bool get allMutablesAreAssignedInTryBlocks {
    return hasAssignmentInTry.length == variableDepth.length;
  }
}

/// Replaces mutable variables with continuation parameters, effectively
/// bringing them into SSA form.
///
/// This pass is intended to clean up mutable variables that were introduced
/// by an optimization in the type propagation pass.
///
/// This implementation potentially creates a lot of redundant and dead phi
/// parameters. These will be cleaned up by redundant phi elimination and
/// shrinking reductions.
///
/// Discussion:
/// For methods with a lot of mutable variables, creating all the spurious
/// parameters might be too expensive. If this is the case, we should
/// improve this pass to avoid most spurious parameters in practice.
class MutableVariableEliminator implements Pass {
  String get passName => 'Mutable variable elimination';

  /// Mutable variables currently in scope, in order of declaration.
  /// This list determines the order of the corresponding phi parameters.
  final List<MutableVariable> mutableVariables = <MutableVariable>[];

  /// Number of phi parameters added to the given continuation.
  final Map<Continuation, int> continuationPhiCount = <Continuation, int>{};

  /// Stack of yet unprocessed continuations interleaved with the
  /// mutable variables currently in scope.
  ///
  /// Continuations are processed when taken off the stack and mutable
  /// variables fall out of scope (i.e. removed from [mutableVariables]) when
  /// taken off the stack.
  final List<StackItem> stack = <StackItem>[];

  MutableVariablePreanalysis analysis;

  void rewrite(FunctionDefinition node) {
    analysis = new MutableVariablePreanalysis()..visit(node);
    if (analysis.allMutablesAreAssignedInTryBlocks) {
      // Skip the pass if there is nothing to do.
      return;
    }
    processBlock(node.body, <MutableVariable, Primitive>{});
    while (stack.isNotEmpty) {
      StackItem item = stack.removeLast();
      if (item is ContinuationItem) {
        processBlock(item.continuation.body, item.environment);
      } else {
        assert(item is VariableItem);
        mutableVariables.removeLast();
      }
    }
  }

  bool shouldRewrite(MutableVariable variable) {
    return !analysis.hasAssignmentInTry.contains(variable);
  }

  bool isJoinContinuation(Continuation cont) {
    return !cont.hasExactlyOneUse ||
           cont.firstRef.parent is InvokeContinuation;
  }

  /// If some useful source information is attached to exactly one of the
  /// two definitions, the information is copied onto the other.
  void mergeHints(MutableVariable variable, Primitive value) {
    if (variable.hint == null) {
      variable.hint = value.hint;
    } else if (value.hint == null) {
      value.hint = variable.hint;
    }
  }

  /// Processes a basic block, replacing mutable variable uses with direct
  /// references to their values.
  ///
  /// [environment] is the current value of each mutable variable. The map
  /// will be mutated during the processing.
  ///
  /// Continuations to be processed are put on the stack for later processing.
  void processBlock(Expression node,
                    Map<MutableVariable, Primitive> environment) {
    Expression next = node.next;
    for (; node is! TailExpression; node = next, next = node.next) {
      if (node is LetMutable && shouldRewrite(node.variable)) {
        // Put the new mutable variable on the stack while processing the body,
        // and pop it off again when done with the body.
        mutableVariables.add(node.variable);
        stack.add(new VariableItem());

        // Put the initial value into the environment.
        Primitive value = node.value.definition;
        environment[node.variable] = value;

        // Preserve variable names.
        mergeHints(node.variable, value);

        // Remove the mutable variable binding.
        node.value.unlink();
        node.remove();
      } else if (node is LetPrim && node.primitive is SetMutable) {
        SetMutable setter = node.primitive;
        MutableVariable variable = setter.variable.definition;
        if (shouldRewrite(variable)) {
          // As above, update the environment, preserve variables and remove
          // the mutable variable assignment.
          environment[variable] = setter.value.definition;
          mergeHints(variable, setter.value.definition);
          setter.value.unlink();
          node.remove();
        }
      } else if (node is LetPrim && node.primitive is GetMutable) {
        GetMutable getter = node.primitive;
        MutableVariable variable = getter.variable.definition;
        if (shouldRewrite(variable)) {
          // Replace with the reaching definition from the environment.
          Primitive value = environment[variable];
          getter.replaceUsesWith(value);
          mergeHints(variable, value);
          node.remove();
        }
      } else if (node is LetCont) {
        // Create phi parameters for each join continuation bound here, and put
        // them on the stack for later processing.
        // Note that non-join continuations are handled at the use-site.
        for (Continuation cont in node.continuations) {
          if (!isJoinContinuation(cont)) continue;
          // Create a phi parameter for every mutable variable in scope.
          // At the same time, build the environment to use for processing
          // the continuation (mapping mutables to phi parameters).
          continuationPhiCount[cont] = mutableVariables.length;
          Map<MutableVariable, Primitive> environment =
              <MutableVariable, Primitive>{};
          for (MutableVariable variable in mutableVariables) {
            Parameter phi = new Parameter(variable.hint);
            phi.type = variable.type;
            cont.parameters.add(phi);
            phi.parent = cont;
            environment[variable] = phi;
          }
          stack.add(new ContinuationItem(cont, environment));
        }
      } else if (node is LetHandler) {
        // Process the catch block later and continue into the try block.
        // We can use the same environment object for the try and catch blocks.
        // The current environment bindings cannot change inside the try block
        // because we exclude all variables assigned inside a try block.
        // The environment might be extended with more bindings before we
        // analyze the catch block, but that's ok.
        stack.add(new ContinuationItem(node.handler, environment));
      }
    }

    // Analyze the terminal node.
    if (node is InvokeContinuation) {
      Continuation cont = node.continuation.definition;
      if (cont.isReturnContinuation) return;
      // This is a call to a join continuation. Add arguments for the phi
      // parameters that were added to this continuation.
      int phiCount = continuationPhiCount[cont];
      for (int i = 0; i < phiCount; ++i) {
        Primitive value = environment[mutableVariables[i]];
        Reference<Primitive> arg = new Reference<Primitive>(value);
        node.arguments.add(arg);
        arg.parent = node;
      }
    } else if (node is Branch) {
      // Enqueue both branches with the current environment.
      // Clone the environments once so the processing of one branch does not
      // mutate the environment needed to process the other branch.
      stack.add(new ContinuationItem(
          node.trueContinuation.definition,
          new Map<MutableVariable, Primitive>.from(environment)));
      stack.add(new ContinuationItem(
          node.falseContinuation.definition,
          environment));
    } else {
      assert(node is Throw || node is Unreachable);
    }
  }
}

abstract class StackItem {}

/// Represents a mutable variable that is in scope.
///
/// The topmost mutable variable falls out of scope when this item is
/// taken off the stack.
class VariableItem extends StackItem {}

/// Represents a yet unprocessed continuation together with the
/// environment in which to process it.
class ContinuationItem extends StackItem {
  final Continuation continuation;
  final Map<MutableVariable, Primitive> environment;

  ContinuationItem(this.continuation, this.environment);
}
