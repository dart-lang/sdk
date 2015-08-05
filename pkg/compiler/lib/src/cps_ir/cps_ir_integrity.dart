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

  Set<Definition> inScope = new Set<Definition>();
  Set<Continuation> insideContinuations = new Set<Continuation>();

  void markAsSeen(Definition def) {
    if (!seenDefinitions.add(def)) {
      error('Redeclared $def', def);
    }
    seenReferences[def] = new Set<Reference>();
  }

  void enterScope(Iterable<Definition> definitions) {
    inScope.addAll(definitions);
    pushAction(() => inScope.removeAll(definitions));
  }

  void enterContinuation(Continuation cont) {
    insideContinuations.add(cont);
    pushAction(() => insideContinuations.remove(cont));
  }

  void check(FunctionDefinition node) {
    topLevelNode = node;
    visit(node);
    // Check for broken reference chains. We check this last, so out-of-scope
    // references are not classified as a broken reference chain.
    seenDefinitions.forEach(checkReferenceChain);
  }

  @override
  Expression traverseLetCont(LetCont node) {
    node.continuations.forEach(markAsSeen);
    node.continuations.forEach(push);

    // Put all continuations in scope when visiting the body.
    enterScope(node.continuations);

    return node.body;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    markAsSeen(node.primitive);

    // Process references in the primitive.
    visit(node.primitive);

    // Put the primitive in scope when visiting the body.
    enterScope([node.primitive]);

    return node.body;
  }

  @override
  Expression traverseLetMutable(LetMutable node) {
    markAsSeen(node.variable);
    processReference(node.value);
    
    // Put the primitive in scope when visiting the body.
    enterScope([node.variable]);

    return node.body;
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    if (cont.isReturnContinuation) {
      error('Non-return continuation missing body', cont);
    }
    cont.parameters.forEach(markAsSeen);
    enterScope(cont.parameters);
    // Put every continuation in scope at its own body. The isRecursive
    // flag is checked explicitly using [insideContinuations].
    enterScope([cont]);
    enterContinuation(cont);
    return cont.body;
  }

  @override
  visitFunctionDefinition(FunctionDefinition node) {
    if (node.thisParameter != null) {
      markAsSeen(node.thisParameter);
      enterScope([node.thisParameter]);
    }
    node.parameters.forEach(markAsSeen);
    enterScope(node.parameters);
    markAsSeen(node.returnContinuation);
    enterScope([node.returnContinuation]);
    if (!node.returnContinuation.isReturnContinuation) {
      error('Return continuation with a body', node);
    }
    visit(node.body);
  }

  @override
  processReference(Reference reference) {
    if (!inScope.contains(reference.definition)) {
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

}
