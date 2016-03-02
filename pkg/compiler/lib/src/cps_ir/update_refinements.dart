library dart2js.cps_ir.update_refinements;

import 'cps_ir_nodes.dart';
import 'optimizers.dart' show Pass;
import 'type_mask_system.dart';
import '../world.dart';

/// Updates all references to use the most refined version in scope.
///
/// [GVN] and [RedundantJoinElimination], and possibly other passes, can create
/// references that don't use the best refinement in scope. This pass improves
/// the refinement information.
///
//
// TODO(asgerf): Could be done during GVN for another adjacent pass.
//   It is easier to measure performance and rearrange passes when it has its
//   own pass, but we can merge it with an adjacent pass later.
//
class UpdateRefinements extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Update refinements';

  final TypeMaskSystem typeSystem;
  World get classWorld => typeSystem.classWorld;

  Map<Primitive, Primitive> refinementFor = <Primitive, Primitive>{};

  UpdateRefinements(this.typeSystem);

  void rewrite(FunctionDefinition node) {
    visit(node);
  }

  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    visit(node.primitive);
    return next;
  }

  visitReceiverCheck(ReceiverCheck node) {
    if (refine(node.valueRef)) {
      // Update the type if the input has changed.
      Primitive value = node.value;
      if (value.type.needsNoSuchMethodHandling(node.selector, classWorld)) {
        node.type = typeSystem.receiverTypeFor(node.selector, value.type);
      } else {
        // Check is no longer needed.
        node..replaceUsesWith(value)..destroy();
        LetPrim letPrim = node.parent;
        letPrim.remove();
        return;
      }
    }
    // Use the ReceiverCheck as a refinement.
    Primitive value = node.effectiveDefinition;
    Primitive old = refinementFor[value];
    refinementFor[value] = node;
    pushAction(() {
      refinementFor[value] = old;
    });
  }

  visitRefinement(Refinement node) {
    if (refine(node.value)) {
      // Update the type if the input has changed.
      node.type = typeSystem.intersection(node.value.definition.type,
          node.refineType);
    }
    Primitive value = node.effectiveDefinition;
    Primitive old = refinementFor[value];
    refinementFor[value] = node;
    pushAction(() {
      refinementFor[value] = old;
    });
  }

  visitBoundsCheck(BoundsCheck node) {
    super.visitBoundsCheck(node);
    if (node.hasIntegerCheck &&
        typeSystem.isDefinitelyInt(node.index.type)) {
      node.checks &= ~BoundsCheck.INTEGER;
    }
  }

  processReference(Reference ref) {
    refine(ref);
  }

  bool refine(Reference ref) {
    Definition def = ref.definition;
    if (def is Primitive) {
      Primitive refinement = refinementFor[def.effectiveDefinition];
      if (refinement != null && refinement != ref.definition) {
        ref.changeTo(refinement);
        return true;
      }
    }
    return false;
  }
}
