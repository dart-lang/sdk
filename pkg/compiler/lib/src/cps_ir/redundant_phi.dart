// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.optimizers;

/// Eliminate redundant phis from the given [FunctionDefinition].
///
/// Phis in this case are [Continuations] together with corresponding
/// [InvokeContinuation]s. A [Continuation] parameter at position i is redundant
/// if for all [InvokeContinuation]s, the parameter at position i is identical
/// (except for feedback). Redundant parameters are removed from the
/// continuation signature, all invocations, and replaced within the
/// continuation body.
class RedundantPhiEliminator extends RecursiveVisitor implements Pass {
  final Set<Continuation> workSet = new Set<Continuation>();

  void rewrite(final ExecutableDefinition root) => root.applyPass(this);

  void rewriteFunctionDefinition(final FunctionDefinition root) {
    if (root.isAbstract) return;
    rewriteExecutableDefinition(root);
  }

  void rewriteFieldDefinition(final FieldDefinition root) {
    rewriteExecutableDefinition(root);
  }

  void rewriteExecutableDefinition(final ExecutableDefinition root) {

    // Set all parent pointers.
    new ParentVisitor().visit(root);

    // Traverse the tree once to build the work set.
    visit(root);

    // Process each continuation one-by-one.
    while (workSet.isNotEmpty) {
      Continuation cont = workSet.first;
      workSet.remove(cont);

      if (cont.isReturnContinuation) {
        continue; // Skip function return continuations.
      }

      _processContinuation(cont);
    }
  }

  /// Called for each continuation on the work set. Modifies the IR graph if
  /// [cont] is a candidate for redundant phi elimination.
  void _processContinuation(Continuation cont) {
    // Generate the list of all cont invocations. If cont is used in any other
    // context (i.e. as a continuation of InvokeMethod), it is not possible to
    // optimize.
    List<InvokeContinuation> invokes = <InvokeContinuation>[];
    for (Reference ref = cont.firstRef; ref != null; ref = ref.next) {
      Node parent = ref.parent;
      if (parent is InvokeContinuation && ref == parent.continuation) {
        invokes.add(parent);
      } else {
        return; // Can't optimize.
      }
    }

    if (invokes.isEmpty) {
      return; // Continuation is never invoked, can't optimize.
    }

    /// Returns the unique definition of parameter i if it exists and null
    /// otherwise. A definition is unique if it is the only value used to
    /// invoke the continuation, excluding feedback.
    Definition uniqueDefinitionOf(int i) {
      Definition value = null;
      for (InvokeContinuation invoke in invokes) {
        Definition def = invoke.arguments[i].definition;

        if (cont.parameters[i] == def) {
          // Invocation param == param in LetCont (i.e. a recursive call).
          continue;
        } else if (value == null) {
          value = def; // Set initial comparison value.
        } else if (value != def) {
          return null; // Differing invocation arguments.
        }
      }

      return value;
    }

    // Check if individual parameters are always called with a unique
    // definition, and remove them if that is the case. During each iteration,
    // we read the current parameter/argument from index `src` and copy it
    // to index `dst`.
    int dst = 0;
    for (int src = 0; src < cont.parameters.length; src++) {
      // Is the current phi redundant?
      Definition uniqueDefinition = uniqueDefinitionOf(src);
      if (uniqueDefinition == null) {
        // Reorganize parameters and arguments in case of deletions.
        cont.parameters[dst] = cont.parameters[src];
        for (InvokeContinuation invoke in invokes) {
            invoke.arguments[dst] = invoke.arguments[src];
        }

        dst++;
        continue;
      }

      Definition oldDefinition = cont.parameters[src];

      // Add continuations of about-to-be modified invokes to worklist since
      // we might introduce new optimization opportunities.
      for (Reference ref = oldDefinition.firstRef; ref != null;
           ref = ref.next) {
        Node parent = ref.parent;
        if (parent is InvokeContinuation) {
          Continuation thatCont = parent.continuation.definition;
          if (thatCont != cont) {
            workSet.add(thatCont);
          }
        }
      }

      // Replace individual parameters:
      // * In the continuation body, replace occurrence of param with value,
      // * and implicitly remove param from continuation signature and
      //   invocations by not incrementing `dst`. References of removed
      //   arguments are unlinked to keep definition usages up to date.
      uniqueDefinition.substituteFor(oldDefinition);
      for (InvokeContinuation invoke in invokes) {
        invoke.arguments[src].unlink();
      }

      // Finally, if the substituted definition is not in scope of the affected
      // continuation, move the continuation binding. This is safe to do since
      // the continuation is referenced only as the target in continuation
      // invokes, and all such invokes must be within the scope of
      // [uniqueDefinition]. Note that this is linear in the depth of
      // the binding of [uniqueDefinition].
      LetCont letCont = cont.parent;
      assert(letCont != null);
      _moveIntoScopeOf(letCont, uniqueDefinition);
    }

    // Remove trailing items from parameter and argument lists.
    cont.parameters.length = dst;
    for (InvokeContinuation invoke in invokes) {
      invoke.arguments.length = dst;
    }
  }

  void processLetCont(LetCont node) {
    workSet.add(node.continuation);
  }
}

/// Returns true, iff [letCont] is not scope of [definition].
/// Linear in the depth of definition within the IR graph.
bool _isInScopeOf(LetCont letCont, Definition definition) {
  for (Node node = definition.parent; node != null; node = node.parent) {
    if (node == letCont) {
      return false;
    }
  }

  return true;
}

/// Moves [letCont] below the binding of [definition] within the IR graph.
/// Does nothing if [letCont] is already within the scope of [definition].
/// Assumes that one argument is nested within the scope of the other
/// when this method is called.
void _moveIntoScopeOf(LetCont letCont, Definition definition) {
  if (_isInScopeOf(letCont, definition)) return;

  // Remove the continuation binding from its current spot.
  InteriorNode parent = letCont.parent;
  parent.body = letCont.body;
  letCont.body.parent = parent;

  // Insert it just below the binding of definition.
  InteriorNode binding = definition.parent;

  letCont.body = binding.body;
  binding.body.parent = letCont;

  binding.body = letCont;
  letCont.parent = binding;
}
