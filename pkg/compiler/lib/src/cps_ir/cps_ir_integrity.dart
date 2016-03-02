library dart2js.cps_ir_integrity;

import 'cps_ir_nodes.dart';
import 'cps_ir_nodes_sexpr.dart';
import '../tracer.dart' as tracer;

/// Dump S-expressions on error if the tracer is enabled.
///
/// Technically this has nothing to do with the tracer, but if you want one
/// enabled, you typically want the other as well, so we use the same flag.
const bool ENABLE_DUMP = tracer.TRACE_FILTER_PATTERN != null;

enum ScopeType { InScope, InDefinition, NotInScope }

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
class CheckCpsIntegrity extends TrampolineRecursiveVisitor {

  FunctionDefinition topLevelNode;
  final Map<Definition, ScopeType> inScope = <Definition, ScopeType>{};
  final List<Definition> definitions = [];
  String previousPass;

  void handleDeclaration(Definition def) {
    definitions.add(def);
    // Check the reference chain for cycles broken links.
    Reference anchor = null;
    int i = 0;
    for (Reference ref = def.firstRef; ref != null; ref = ref.next) {
      if (ref.definition != def) {
        error('Reference to ${ref.definition} found in '
              'reference chain for $def', def);
      }
      if (ref == anchor) {
        error('Cyclic reference chain for $def', def);
      }
      if (i & ++i == 0) { // Move the anchor every 2^Nth step.
        anchor = ref;
      }
    }
  }

  void enterScope(Iterable<Definition> definitions) {
    for (Definition def in definitions) {
      inScope[def] = ScopeType.InScope;
    }
    pushAction(() {
      for (Definition def in definitions) {
        inScope[def] = ScopeType.NotInScope;
      }
    });
  }

  void enterContinuation(Continuation cont) {
    inScope[cont] = ScopeType.InDefinition;
    pushAction(() {
      inScope[cont] = ScopeType.NotInScope;
    });
  }

  void check(FunctionDefinition node, String previousPass) {
    // [check] will be called multiple times per instance to avoid reallocating
    // the large [inScope] map. Reset the other fields.
    this.topLevelNode = node;
    this.previousPass = previousPass;
    this.definitions.clear();
    ParentChecker.checkParents(node, this);
    visit(node);
    // Check for broken reference chains. We check this last, so out-of-scope
    // references are not classified as a broken reference chain.
    definitions.forEach(checkReferenceChain);
  }

  @override
  Expression traverseLetCont(LetCont node) {
    node.continuations.forEach(handleDeclaration);
    node.continuations.forEach(push);

    // Put all continuations in scope when visiting the body.
    enterScope(node.continuations);

    return node.body;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    handleDeclaration(node.primitive);

    // Process references in the primitive.
    visit(node.primitive);

    // Put the primitive in scope when visiting the body.
    enterScope([node.primitive]);

    return node.body;
  }

  @override
  Expression traverseLetMutable(LetMutable node) {
    handleDeclaration(node.variable);
    processReference(node.valueRef);

    // Put the primitive in scope when visiting the body.
    enterScope([node.variable]);

    return node.body;
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    if (cont.isReturnContinuation) {
      error('Non-return continuation missing body', cont);
    }
    cont.parameters.forEach(handleDeclaration);
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
      handleDeclaration(node.thisParameter);
      enterScope([node.thisParameter]);
    }
    node.parameters.forEach(handleDeclaration);
    enterScope(node.parameters);
    handleDeclaration(node.returnContinuation);
    enterScope([node.returnContinuation]);
    if (!node.returnContinuation.isReturnContinuation) {
      error('Return continuation with a body', node);
    }
    visit(node.body);
  }

  @override
  processReference(Reference ref) {
    Definition def = ref.definition;
    if (inScope[def] == ScopeType.NotInScope) {
      error('Referenced out of scope: $def', ref);
    }
    if (ref.previous == ref) {
      error('Shared Reference object to $def', ref);
    }
    if (ref.previous == null && def.firstRef != ref ||
        ref.previous != null && ref.previous.next != ref) {
      error('Broken .previous link in reference to $def', def);
    }
    ref.previous = ref; // Mark reference as "seen". We will repair it later.
  }

  @override
  processInvokeContinuation(InvokeContinuation node) {
    Continuation target = node.continuation;
    if (node.isRecursive && inScope[target] == ScopeType.InScope) {
      error('Non-recursive InvokeContinuation marked as recursive', node);
    }
    if (!node.isRecursive && inScope[target] == ScopeType.InDefinition) {
      error('Recursive InvokeContinuation marked as non-recursive', node);
    }
    if (node.isRecursive && !target.isRecursive) {
      error('Recursive Continuation was not marked as recursive', node);
    }
    if (node.argumentRefs.length != target.parameters.length) {
      error('Arity mismatch in InvokeContinuation', node);
    }
  }

  void checkReferenceChain(Definition def) {
    Reference previous = null;
    for (Reference ref = def.firstRef; ref != null; ref = ref.next) {
      if (ref.previous != ref) {
        // Reference was not seen during IR traversal, so it is orphaned.
        error('Orphaned reference in reference chain for $def', def);
      }
      // Repair the .previous link that was used for marking.
      ref.previous = previous;
      previous = ref;
    }
  }

  error(String message, node) {
    String sexpr;
    if (ENABLE_DUMP) {
      try {
        Decorator decorator = (n, String s) => n == node ? '**$s**' : s;
        sexpr = new SExpressionStringifier(decorator).visit(topLevelNode);
        sexpr = 'SExpr dump (offending node marked with **):\n\n$sexpr';
      } catch (e) {
        sexpr = '(Exception thrown by SExpressionStringifier: $e)';
      }
    } else {
      sexpr = '(Set DUMP_IR flag to enable SExpr dump)';
    }
    throw 'CPS integrity violation\n'
          'After \'$previousPass\' on ${topLevelNode.element}\n'
          '$message\n\n'
          '$sexpr\n';
  }
}

/// Traverses the CPS term and checks that node.parent is correctly set
/// for each visited node.
class ParentChecker extends DeepRecursiveVisitor {
  static void checkParents(Node node, CheckCpsIntegrity main) {
    ParentChecker visitor = new ParentChecker._make(main);
    visitor._worklist.add(node);
    visitor.trampoline();
  }

  ParentChecker._make(this.main);

  Node _parent;
  final List<Node> _worklist = <Node>[];
  final CheckCpsIntegrity main;

  void trampoline() {
    while (_worklist.isNotEmpty) {
      _parent = _worklist.removeLast();
      _parent.accept(this);
    }
  }

  error(String message, node) => main.error(message, node);

  @override
  visit(Node node) {
    _worklist.add(node);
    if (node.parent != _parent) {
      error('Parent pointer on $node is ${node.parent} but should be $_parent',
            node);
    }
  }

  @override
  processReference(Reference node) {
    if (node.parent != _parent) {
      error('Parent pointer on $node is ${node.parent} but should be $_parent',
            node);
    }
  }
}
