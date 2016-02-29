library dart2js.cps_ir.loop_effects;

import 'cps_ir_nodes.dart';
import 'loop_hierarchy.dart';
import '../world.dart';
import 'effects.dart';

/// Determines the side effects that may occur in each loop.
class LoopSideEffects extends TrampolineRecursiveVisitor {
  LoopHierarchy loopHierarchy;
  final World world;
  final Map<Continuation, List<Continuation>> exitContinuations = {};
  final Map<Continuation, int> loopSideEffects = {};
  Continuation currentLoopHeader;

  LoopSideEffects(FunctionDefinition node, this.world, {this.loopHierarchy}) {
    if (loopHierarchy == null) {
      loopHierarchy = new LoopHierarchy(node);
    }
    visit(node);
  }

  /// Returns the accumulated effects and dependencies on all paths from the
  /// loop entry to any recursive invocation of the loop.
  int getSideEffectsInLoop(Continuation loop) {
    return loopSideEffects[loop];
  }

  /// True if the length of an indexable object may change between the loop
  /// entry and a recursive invocation of the loop.
  bool changesIndexableLength(Continuation loop) {
    return loopSideEffects[loop] & Effects.changesIndexableLength != 0;
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    if (cont.isRecursive) {
      loopSideEffects[cont] = Effects.none;
      exitContinuations[cont] = <Continuation>[];
      pushAction(() {
        if (currentLoopHeader != null) {
          loopSideEffects[currentLoopHeader] |= loopSideEffects[cont];
        }
        exitContinuations[cont].forEach(push);
      });
    }
    Continuation oldLoopHeader = currentLoopHeader;
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
    pushAction(() {
      currentLoopHeader = oldLoopHeader;
    });
    return cont.body;
  }

  @override
  Expression traverseLetHandler(LetHandler node) {
    enqueueContinuation(node.handler);
    return node.body;
  }

  @override
  Expression traverseLetCont(LetCont node) {
    node.continuations.forEach(enqueueContinuation);
    return node.body;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    if (currentLoopHeader != null) {
      loopSideEffects[currentLoopHeader] |= node.primitive.effects;
    }
    return node.body;
  }

  void enqueueContinuation(Continuation cont) {
    Continuation loop = loopHierarchy.getEnclosingLoop(cont);
    if (loop == currentLoopHeader) {
      push(cont);
    } else {
      // Multiple loops can be exited at once.
      // Register as an exit from the outermost loop being exited.
      Continuation inner = currentLoopHeader;
      Continuation outer = loopHierarchy.getEnclosingLoop(currentLoopHeader);
      while (outer != loop) {
        if (inner == null) {
          // The shrinking reductions pass must run before any pass that relies
          // on computing loop side effects.
          world.compiler.reporter.internalError(null,
              'Unreachable continuations must be removed before computing '
              'loop side effects.');
        }
        inner = outer;
        outer = loopHierarchy.getEnclosingLoop(outer);
      }
      exitContinuations[inner].add(cont);
    }
  }
}
