library dart2js.cps_ir_integrity;

import 'cps_ir_nodes.dart';
import 'cps_ir_nodes_sexpr.dart';
import '../tracer.dart' as tracer;

/// Dump S-expressions on error if the tracer is enabled.
///
/// Technically this has nothing to do with the tracer, but if you want one
/// enabled, you typically want the other as well, so we use the same flag.
const bool ENABLE_DUMP = tracer.TRACE_FILTER_PATTERN != null;

/// Performs integrity checks on the CPS IR.
///
/// To be run for debugging purposes, not for use in production.
///
/// The following integrity checks are performed:
///
/// - References are in scope of their definitions.
/// - Recursive Continuations and InvokeContinuations are marked as recursive.
/// - InvokeContinuations have the same arity as their target.
/// - Reference chains are valid doubly-linked lists.
/// - Reference chains contain exactly the references that are in the IR.
/// - Each definition object occurs only once in the IR (no redeclaring).
/// - Each reference object occurs only once in the IR (no sharing).
///
class CheckCpsIntegrity extends RecursiveVisitor {

  FunctionDefinition topLevelNode;

  Set<Definition> seenDefinitions = new Set<Definition>();
  Map<Definition, Set<Reference>> seenReferences =
      <Definition, Set<Reference>>{};

  Map<Definition, Node> bindings = <Definition, Node>{};
  Set<Continuation> insideContinuations = new Set<Continuation>();

  doInScope(Iterable<Definition> defs, Node binding, action()) {
    for (Definition def in defs) {
      bindings[def] = binding;
    }
    action();
    for (Definition def in defs) {
      bindings.remove(def);
    }
  }

  void markAsSeen(Definition def) {
    if (!seenDefinitions.add(def)) {
      error('Redeclared $def', def);
    }
    seenReferences[def] = new Set<Reference>();
  }

  @override
  visitLetCont(LetCont node) {
    // Analyze each continuation separately without the others in scope.
    for (Continuation continuation in node.continuations) {
      // We always consider a continuation to be in scope of itself.
      // The isRecursive flag is checked explicitly to give more useful
      // error messages.
      doInScope([continuation], node, () => visit(continuation));
    }
    // Analyze the body with all continuations in scope.
    doInScope(node.continuations, node, () => visit(node.body));
  }

  @override
  visitContinuation(Continuation node) {
    markAsSeen(node);
    if (node.isReturnContinuation) {
      error('Non-return continuation missing body', node);
    }
    node.parameters.forEach(markAsSeen);
    insideContinuations.add(node);
    doInScope(node.parameters, node, () => visit(node.body));
    insideContinuations.remove(node);
  }

  @override
  visitLetPrim(LetPrim node) {
    markAsSeen(node.primitive);
    visit(node.primitive);
    doInScope([node.primitive], node, () => visit(node.body));
  }

  @override
  visitLetMutable(LetMutable node) {
    markAsSeen(node.variable);
    processReference(node.value);
    doInScope([node.variable], node, () => visit(node.body));
  }

  @override
  visitFunctionDefinition(FunctionDefinition node) {
    if (node.thisParameter != null) {
      markAsSeen(node.thisParameter);
    }
    node.parameters.forEach(markAsSeen);
    markAsSeen(node.returnContinuation);
    if (!node.returnContinuation.isReturnContinuation) {
      error('Return continuation with a body', node);
    }
    doInOptionalScope(node.thisParameter, node,
        () => doInScope(node.parameters, node,
            () => doInScope([node.returnContinuation], node,
                () => visit(node.body))));
  }

  doInOptionalScope(Parameter parameter, Node node, action) {
    return (parameter == null)
        ? action()
        : doInScope([parameter], node, action);
  }

  @override
  processReference(Reference reference) {
    if (!bindings.containsKey(reference.definition)) {
      error('Referenced out of scope: ${reference.definition}', reference);
    }
    if (!seenReferences[reference.definition].add(reference)) {
      error('Duplicate use of Reference to ${reference.definition}', reference);
    }
  }

  @override
  processInvokeContinuation(InvokeContinuation node) {
    Continuation target = node.continuation.definition;
    if (node.isRecursive && !insideContinuations.contains(target)) {
      error('Non-recursive InvokeContinuation marked as recursive', node);
    }
    if (!node.isRecursive && insideContinuations.contains(target)) {
      error('Recursive InvokeContinuation marked as non-recursive', node);
    }
    if (node.isRecursive && !target.isRecursive) {
      error('Recursive Continuation was not marked as recursive', node);
    }
    if (node.arguments.length != target.parameters.length) {
      error('Arity mismatch in InvokeContinuation', node);
    }
  }

  void checkReferenceChain(Definition def) {
    Set<Reference> chainedReferences = new Set<Reference>();
    Reference prev = null;
    for (Reference ref = def.firstRef; ref != null; ref = ref.next) {
      if (ref.definition != def) {
        error('Reference in chain for $def points to ${ref.definition}', def);
      }
      if (ref.previous != prev) {
        error('Broken .previous link in reference to $def', def);
      }
      prev = ref;
      if (!chainedReferences.add(ref)) {
        error('Cyclic reference chain for $def', def);
      }
    }
    if (!chainedReferences.containsAll(seenReferences[def])) {
      error('Seen reference to $def not in reference chain', def);
    }
    if (!seenReferences[def].containsAll(chainedReferences)) {
      error('Reference chain for $def contains orphaned references', def);
    }
  }

  error(String message, node) {
    String sexpr;
    if (ENABLE_DUMP) {
      try {
        Decorator decorator = (n, String s) => n == node ? '**$s**' : s;
        sexpr = new SExpressionStringifier(decorator).visit(topLevelNode);
      } catch (e) {
        sexpr = '(Exception thrown by SExpressionStringifier: $e)';
      }
    } else {
      sexpr = '(Set DUMP_IR flag to enable)';
    }
    throw 'CPS integrity violation in ${topLevelNode.element}:\n'
          '$message\n\n'
          'SExpr dump (offending node marked with **):\n\n'
          '$sexpr\n';
  }

  void check(FunctionDefinition node) {
    topLevelNode = node;
    visit(node);

    // Check this last, so out-of-scope references are not classified as
    // a broken reference chain.
    seenDefinitions.forEach(checkReferenceChain);
  }

}
