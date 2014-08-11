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
  final Map<Continuation, List<InvokeContinuation>> cont2invokes =
      <Continuation, List<InvokeContinuation>>{};
  // For each reference r used in a continuation invocation i, stores the
  // corresponding continuation i.continuation. If required by other passes,
  // we could consider adding parent pointers to references instead.
  final Map<Reference, Continuation> ref2cont = <Reference, Continuation>{};
  final Set<Continuation> workSet = new Set<Continuation>();

  void rewrite(final FunctionDefinition root) {
    // Traverse the tree once to build the work set.
    visit(root);
    workSet.addAll(cont2invokes.keys);

    // Process each continuation one-by-one.
    while (workSet.isNotEmpty) {
      Continuation cont = workSet.first;
      workSet.remove(cont);

      if (cont.body == null) {
        continue; // Skip function return continuations.
      }

      List<InvokeContinuation> invokes = cont2invokes[cont];
      assert(invokes != null);

      _processContinuation(cont, invokes);
    }
  }

  /// Called for each continuation on the work set, together with its
  /// invocations.
  void _processContinuation(Continuation cont,
                            List<InvokeContinuation> invokes) {
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
        Continuation thatCont = ref2cont[ref];
        // thatCont is null if ref does not belong to a continuation invocation.
        if (thatCont != null && thatCont != cont) {
          workSet.add(thatCont);
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
    }

    // Remove trailing items from parameter and argument lists.
    cont.parameters.length = dst;
    for (InvokeContinuation invoke in invokes) {
      invoke.arguments.length = dst;
    }
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    // Update the continuation map.
    Continuation cont = node.continuation.definition;
    assert(cont != null);
    cont2invokes.putIfAbsent(cont, () => <InvokeContinuation>[])
        .add(node);

    // And the reference map.
    node.arguments.forEach((Reference ref) {
      assert(!ref2cont.containsKey(ref));
      ref2cont[ref] = node.continuation.definition;
    });
  }
}

