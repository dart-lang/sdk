library dart2js.cps_ir.loop_effects;

import 'cps_ir_nodes.dart';
import 'loop_hierarchy.dart';
import '../universe/side_effects.dart';
import '../elements/elements.dart';
import '../world.dart';

/// Determines which the [SideEffects] that may occur during each loop in
/// a given function, in addition to whether the loop may change the length
/// of an indexable object.
///
/// TODO(asgerf): Make length a flag on [SideEffects] for better precision and
/// so we don't need to special case the length in this class.
class LoopSideEffects extends TrampolineRecursiveVisitor {
  LoopHierarchy loopHierarchy;
  final World world;
  final Map<Continuation, List<Continuation>> exitContinuations = {};
  final Map<Continuation, SideEffects> loopSideEffects = {};
  final Set<Continuation> loopsChangingLength = new Set<Continuation>();
  Continuation currentLoopHeader;
  SideEffects currentLoopSideEffects = new SideEffects.empty();
  bool currentLoopChangesLength = false;

  LoopSideEffects(FunctionDefinition node, this.world, {this.loopHierarchy}) {
    if (loopHierarchy == null) {
      loopHierarchy = new LoopHierarchy(node);
    }
    visit(node);
  }

  /// Returns the accumulated effects and dependencies on all paths from the
  /// loop entry to any recursive invocation of the loop.
  SideEffects getSideEffectsInLoop(Continuation loop) {
    return loopSideEffects[loop];
  }

  /// True if the length of an indexable object may change between the loop
  /// entry and a recursive invocation of the loop.
  bool loopChangesLength(Continuation loop) {
    return loopsChangingLength.contains(loop);
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    if (cont.isRecursive) {
      SideEffects oldEffects = currentLoopSideEffects;
      bool oldChangesLength = currentLoopChangesLength;
      loopSideEffects[cont] = currentLoopSideEffects = new SideEffects.empty();
      exitContinuations[cont] = <Continuation>[];
      pushAction(() {
        oldEffects.add(currentLoopSideEffects);
        if (currentLoopChangesLength) {
          loopsChangingLength.add(cont);
        }
        currentLoopChangesLength = currentLoopChangesLength || oldChangesLength;
        currentLoopSideEffects = oldEffects;
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

  void addSideEffects(SideEffects effects) {
    currentLoopSideEffects.add(effects);
    if (effects.changesIndex()) {
      currentLoopChangesLength = true;
    }
  }

  void addAllSideEffects() {
    currentLoopSideEffects.setAllSideEffects();
    currentLoopSideEffects.setDependsOnSomething();
    currentLoopChangesLength = true;
  }

  void visitInvokeMethod(InvokeMethod node) {
    addSideEffects(world.getSideEffectsOfSelector(node.selector, node.mask));
  }

  void visitInvokeStatic(InvokeStatic node) {
    addSideEffects(world.getSideEffectsOfElement(node.target));
  }

  void visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    FunctionElement target = node.target;
    if (target is ConstructorBodyElement) {
      ConstructorBodyElement body = target;
      target = body.constructor;
    }
    addSideEffects(world.getSideEffectsOfElement(target));
  }

  void visitInvokeConstructor(InvokeConstructor node) {
    addSideEffects(world.getSideEffectsOfElement(node.target));
  }

  void visitSetStatic(SetStatic node) {
    currentLoopSideEffects.setChangesStaticProperty();
  }

  void visitGetStatic(GetStatic node) {
    currentLoopSideEffects.setDependsOnStaticPropertyStore();
  }

  void visitGetField(GetField node) {
    currentLoopSideEffects.setDependsOnInstancePropertyStore();
  }

  void visitSetField(SetField node) {
    currentLoopSideEffects.setChangesInstanceProperty();
  }

  void visitGetIndex(GetIndex node) {
    currentLoopSideEffects.setDependsOnIndexStore();
  }

  void visitSetIndex(SetIndex node) {
    // Set the change index flag without setting the change length flag.
    currentLoopSideEffects.setChangesIndex();
  }

  void visitForeignCode(ForeignCode node) {
    addSideEffects(node.nativeBehavior.sideEffects);
  }

  void visitGetLazyStatic(GetLazyStatic node) {
    // TODO(asgerf): How do we get the side effects of a lazy field initializer?
    addAllSideEffects();
  }

  void visitAwait(Await node) {
    addAllSideEffects();
  }

  void visitYield(Yield node) {
    addAllSideEffects();
  }

  void visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    currentLoopSideEffects.setChangesIndex();
    currentLoopChangesLength = true; // Push and pop.
  }
}
