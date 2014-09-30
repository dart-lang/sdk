// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.optimizers;

/**
 * Propagates constants throughout the IR, and replaces branches with fixed
 * jumps as well as side-effect free expressions with known constant results.
 * Should be followed by the [ShrinkingReducer] pass.
 *
 * Implemented according to 'Constant Propagation with Conditional Branches'
 * by Wegman, Zadeck.
 */
class ConstantPropagator implements Pass {

  // Required for type determination in analysis of TypeOperator expressions.
  final dart2js.Compiler _compiler;

  // The constant system is used for evaluation of expressions with constant
  // arguments.
  final dart2js.ConstantSystem _constantSystem;

  ConstantPropagator(this._compiler, this._constantSystem);

  void rewrite(FunctionDefinition root) {
    if (root.isAbstract) return;

    // Set all parent pointers.

    new _ParentVisitor().visit(root);

    // Analyze. In this phase, the entire term is analyzed for reachability
    // and the constant status of each expression.

    _ConstPropagationVisitor analyzer =
        new _ConstPropagationVisitor(_compiler, _constantSystem);
    analyzer.analyze(root);

    // Transform. Uses the data acquired in the previous analysis phase to
    // replace branches with fixed targets and side-effect-free expressions
    // with constant results.

    _TransformingVisitor transformer = new _TransformingVisitor(
        analyzer.reachableNodes, analyzer.node2value);
    transformer.transform(root);
  }
}

/**
 * Uses the information from a preceding analysis pass in order to perform the
 * actual transformations on the CPS graph.
 */
class _TransformingVisitor extends RecursiveVisitor {

  final Set<Node> reachable;
  final Map<Node, _ConstnessLattice> node2value;

  _TransformingVisitor(this.reachable, this.node2value);

  void transform(FunctionDefinition root) {
    visitFunctionDefinition(root);
  }

  /// Given an expression with a known constant result and a continuation,
  /// replaces the expression by a new LetPrim / InvokeContinuation construct.
  /// `unlink` is a closure responsible for unlinking all removed references.
  LetPrim constifyExpression(Expression node,
                             Continuation continuation,
                             void unlink()) {
    _ConstnessLattice cell = node2value[node];
    if (cell == null || !cell.isConstant) {
      return null;
    }

    assert(continuation.parameters.length == 1);

    // Set up the replacement structure.

    values.PrimitiveConstant primitiveConstant = cell.constant;
    ConstExp constExp = new PrimitiveConstExp(primitiveConstant);
    Constant constant = new Constant(constExp);
    LetPrim letPrim = new LetPrim(constant);
    InvokeContinuation invoke =
        new InvokeContinuation(continuation, <Definition>[constant]);

    invoke.parent = constant.parent = letPrim;
    letPrim.body = invoke;

    // Replace the method invocation.

    InteriorNode parent = node.parent;
    letPrim.parent = parent;
    parent.body = letPrim;

    unlink();

    return letPrim;
  }

  // A branch can be eliminated and replaced by an invocation if only one of
  // the possible continuations is reachable. Removal often leads to both dead
  // primitives (the condition variable) and dead continuations (the unreachable
  // branch), which are both removed by the shrinking reductions pass.
  //
  // (Branch (IsTrue true) k0 k1) -> (InvokeContinuation k0)
  void visitBranch(Branch node) {
    bool trueReachable  = reachable.contains(node.trueContinuation.definition);
    bool falseReachable = reachable.contains(node.falseContinuation.definition);
    bool bothReachable  = (trueReachable && falseReachable);
    bool noneReachable  = !(trueReachable || falseReachable);

    if (bothReachable || noneReachable) {
      // Nothing to do, shrinking reductions take care of the unreachable case.
      super.visitBranch(node);
      return;
    }

    Continuation successor = (trueReachable) ?
        node.trueContinuation.definition : node.falseContinuation.definition;

    // Replace the branch by a continuation invocation.

    assert(successor.parameters.isEmpty);
    InvokeContinuation invoke =
        new InvokeContinuation(successor, <Definition>[]);

    InteriorNode parent = node.parent;
    invoke.parent = parent;
    parent.body = invoke;

    // Unlink all removed references.

    node.trueContinuation.unlink();
    node.falseContinuation.unlink();
    IsTrue isTrue = node.condition;
    isTrue.value.unlink();

    visitInvokeContinuation(invoke);
  }

  // Side-effect free method calls with constant results can be replaced by
  // a LetPrim / InvokeContinuation pair. May lead to dead primitives which
  // are removed by the shrinking reductions pass.
  //
  // (InvokeMethod v0 == v1 k0)
  // -> (assuming the result is a constant `true`)
  // (LetPrim v2 (Constant true))
  // (InvokeContinuation k0 v2)
  void visitInvokeMethod(InvokeMethod node) {
    Continuation cont = node.continuation.definition;
    LetPrim letPrim = constifyExpression(node, cont, () {
      node.receiver.unlink();
      node.continuation.unlink();
      node.arguments.forEach((Reference ref) => ref.unlink());
    });

    if (letPrim == null) {
      super.visitInvokeMethod(node);
    } else {
      visitLetPrim(letPrim);
    }
  }

  // See [visitInvokeMethod].
  void visitConcatenateStrings(ConcatenateStrings node) {
    Continuation cont = node.continuation.definition;
    LetPrim letPrim = constifyExpression(node, cont, () {
      node.continuation.unlink();
      node.arguments.forEach((Reference ref) => ref.unlink());
    });

    if (letPrim == null) {
      super.visitConcatenateStrings(node);
    } else {
      visitLetPrim(letPrim);
    }
  }

  // See [visitInvokeMethod].
  void visitTypeOperator(TypeOperator node) {
    Continuation cont = node.continuation.definition;
    LetPrim letPrim = constifyExpression(node, cont, () {
      node.receiver.unlink();
      node.continuation.unlink();
    });

    if (letPrim == null) {
      super.visitTypeOperator(node);
    } else {
      visitLetPrim(letPrim);
    }
  }
}

/**
 * Runs an analysis pass on the given function definition in order to detect
 * const-ness as well as reachability, both of which are used in the subsequent
 * transformation pass.
 */
class _ConstPropagationVisitor extends Visitor {
  // The node worklist stores nodes that are both reachable and need to be
  // processed, but have not been processed yet. Using a worklist avoids deep
  // recursion.
  // The node worklist and the reachable set operate in concert: nodes are
  // only ever added to the worklist when they have not yet been marked as
  // reachable, and adding a node to the worklist is always followed by marking
  // it reachable.
  // TODO(jgruber): Storing reachability per-edge instead of per-node would
  // allow for further optimizations.
  final List<Node> nodeWorklist = <Node>[];
  final Set<Node> reachableNodes = new Set<Node>();

  // The definition workset stores all definitions which need to be reprocessed
  // since their lattice value has changed.
  final Set<Definition> defWorkset = new Set<Definition>();

  final dart2js.Compiler compiler;
  final dart2js.ConstantSystem constantSystem;

  // Stores the current lattice value for nodes. Note that it contains not only
  // definitions as keys, but also expressions such as method invokes.
  // Access through [getValue] and [setValue].
  final Map<Node, _ConstnessLattice> node2value = <Node, _ConstnessLattice>{};

  _ConstPropagationVisitor(this.compiler, this.constantSystem);

  void analyze(FunctionDefinition root) {
    reachableNodes.clear();
    defWorkset.clear();
    nodeWorklist.clear();

    // Initially, only the root node is reachable.
    setReachable(root);

    while (true) {
      if (nodeWorklist.isNotEmpty) {
        // Process a new reachable expression.
        Node node = nodeWorklist.removeLast();
        visit(node);
      } else if (defWorkset.isNotEmpty) {
        // Process all usages of a changed definition.
        Definition def = defWorkset.first;
        defWorkset.remove(def);

        // Visit all uses of this definition. This might add new entries to
        // [nodeWorklist], for example by visiting a newly-constant usage within
        // a branch node.
        for (Reference ref = def.firstRef; ref != null; ref = ref.next) {
          visit(ref.parent);
        }
      } else {
        break;  // Both worklists empty.
      }
    }
  }

  /// If the passed node is not yet reachable, mark it reachable and add it
  /// to the work list.
  void setReachable(Node node) {
    if (!reachableNodes.contains(node)) {
      reachableNodes.add(node);
      nodeWorklist.add(node);
    }
  }

  /// Returns the lattice value corresponding to [node], defaulting to unknown.
  ///
  /// Never returns null.
  _ConstnessLattice getValue(Node node) {
    _ConstnessLattice value = node2value[node];
    return (value == null) ? _ConstnessLattice.Unknown : value;
  }

  /// Joins the passed lattice [updateValue] to the current value of [node],
  /// and adds it to the definition work set if it has changed and [node] is
  /// a definition.
  void setValue(Node node, _ConstnessLattice updateValue) {
    _ConstnessLattice oldValue = getValue(node);
    _ConstnessLattice newValue = updateValue.join(oldValue);
    if (oldValue == newValue) {
      return;
    }

    // Values may only move in the direction UNKNOWN -> CONSTANT -> NONCONST.
    assert(newValue.kind >= oldValue.kind);

    node2value[node] = newValue;
    if (node is Definition) {
      defWorkset.add(node);
    }
  }

  // -------------------------- Visitor overrides ------------------------------

  void visitNode(Node node) {
    compiler.internalError(NO_LOCATION_SPANNABLE,
        "_ConstPropagationVisitor is stale, add missing visit overrides");
  }

  void visitFunctionDefinition(FunctionDefinition node) {
    node.parameters.forEach(visitParameter);
    setReachable(node.body);
  }

  // Expressions.

  void visitLetPrim(LetPrim node) {
    visit(node.primitive); // No reason to delay visits to primitives.
    setReachable(node.body);
  }

  void visitLetCont(LetCont node) {
    // The continuation is only marked as reachable on use.
    setReachable(node.body);
  }

  void visitInvokeStatic(InvokeStatic node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    setValue(returnValue, _ConstnessLattice.NonConst);
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    // Forward the constant status of all continuation invokes to the
    // continuation. Note that this is effectively a phi node in SSA terms.
    for (int i = 0; i < node.arguments.length; i++) {
      Definition def = node.arguments[i].definition;
      _ConstnessLattice cell = getValue(def);
      setValue(cont.parameters[i], cell);
    }
  }

  void visitInvokeMethod(InvokeMethod node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    /// Sets the value of both the current node and the target continuation
    /// parameter.
    void setValues(_ConstnessLattice updateValue) {
      setValue(node, updateValue);
      Parameter returnValue = cont.parameters[0];
      setValue(returnValue, updateValue);
    }

    _ConstnessLattice lhs = getValue(node.receiver.definition);
    if (lhs.isUnknown) {
      // This may seem like a missed opportunity for evaluating short-circuiting
      // boolean operations; we are currently skipping these intentionally since
      // expressions such as `(new Foo() || true)` may introduce type errors
      // and thus evaluation to `true` would not be correct.
      // TODO(jgruber): Handle such cases while ensuring that new Foo() and
      // a type-check (in checked mode) are still executed.
      return;  // And come back later.
    } else if (lhs.isNonConst) {
      setValues(_ConstnessLattice.NonConst);
      return;
    } else if (!node.selector.isOperator) {
      // TODO(jgruber): Handle known methods on constants such as String.length.
      setValues(_ConstnessLattice.NonConst);
      return;
    }

    // Calculate the resulting constant if possible.
    values.Constant result;
    String opname = node.selector.name;
    if (node.selector.argumentCount == 0) {
      // Unary operator.

      if (opname == "unary-") {
        opname = "-";
      }
      dart2js.UnaryOperation operation = constantSystem.lookupUnary(opname);
      if (operation != null) {
        result = operation.fold(lhs.constant);
      }
    } else if (node.selector.argumentCount == 1) {
      // Binary operator.

      _ConstnessLattice rhs = getValue(node.arguments[0].definition);
      if (!rhs.isConstant) {
        setValues(rhs);
        return;
      }

      dart2js.BinaryOperation operation = constantSystem.lookupBinary(opname);
      if (operation != null) {
        result = operation.fold(lhs.constant, rhs.constant);
      }
    }

    // Update value of the continuation parameter. Again, this is effectively
    // a phi.

    setValues((result == null) ?
        _ConstnessLattice.NonConst : new _ConstnessLattice(result));
   }

  void visitInvokeSuperMethod(InvokeSuperMethod node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    setValue(returnValue, _ConstnessLattice.NonConst);
  }

  void visitInvokeConstructor(InvokeConstructor node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    setValue(returnValue, _ConstnessLattice.NonConst);
  }

  void visitConcatenateStrings(ConcatenateStrings node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    void setValues(_ConstnessLattice updateValue) {
      setValue(node, updateValue);
      Parameter returnValue = cont.parameters[0];
      setValue(returnValue, updateValue);
    }

    // TODO(jgruber): Currently we only optimize if all arguments are string
    // constants, but we could also handle cases such as "foo${42}".
    bool allStringConstants = node.arguments.every((Reference ref) {
      if (!(ref.definition is Constant)) {
        return false;
      }
      Constant constant = ref.definition;
      return constant != null && constant.value.isString;
    });

    assert(cont.parameters.length == 1);
    if (allStringConstants) {
      // All constant, we can concatenate ourselves.
      Iterable<String> allStrings = node.arguments.map((Reference ref) {
        Constant constant = ref.definition;
        values.StringConstant stringConstant = constant.value;
        return stringConstant.value.slowToString();
      });
      LiteralDartString dartString = new LiteralDartString(allStrings.join());
      values.Constant constant = new values.StringConstant(dartString);
      setValues(new _ConstnessLattice(constant));
    } else {
      setValues(_ConstnessLattice.NonConst);
    }
  }

  void visitBranch(Branch node) {
    IsTrue isTrue = node.condition;
    _ConstnessLattice conditionCell = getValue(isTrue.value.definition);

    if (conditionCell.isUnknown) {
      return;  // And come back later.
    } else if (conditionCell.isNonConst) {
      setReachable(node.trueContinuation.definition);
      setReachable(node.falseContinuation.definition);
    } else if (conditionCell.isConstant &&
        !(conditionCell.constant.isBool)) {
      // Treat non-bool constants in condition as non-const since they result
      // in type errors in checked mode.
      // TODO(jgruber): Default to false in unchecked mode.
      setReachable(node.trueContinuation.definition);
      setReachable(node.falseContinuation.definition);
      setValue(isTrue.value.definition, _ConstnessLattice.NonConst);
    } else if (conditionCell.isConstant &&
        conditionCell.constant.isBool) {
      values.BoolConstant boolConstant = conditionCell.constant;
      setReachable((boolConstant.isTrue) ?
          node.trueContinuation.definition : node.falseContinuation.definition);
    }
  }

  void visitTypeOperator(TypeOperator node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    void setValues(_ConstnessLattice updateValue) {
      setValue(node, updateValue);
      Parameter returnValue = cont.parameters[0];
      setValue(returnValue, updateValue);
    }

    if (node.operator != "is") {
      // TODO(jgruber): Add support for `as` casts.
      setValues(_ConstnessLattice.NonConst);
    }

    _ConstnessLattice cell = getValue(node.receiver.definition);
    if (cell.isUnknown) {
      return;  // And come back later.
    } else if (cell.isNonConst) {
      setValues(_ConstnessLattice.NonConst);
    } else if (node.type.kind == types.TypeKind.INTERFACE) {
      // Receiver is a constant, perform is-checks at compile-time.

      types.InterfaceType checkedType = node.type;
      values.Constant constant = cell.constant;
      types.DartType constantType = constant.computeType(compiler);

      _ConstnessLattice result = _ConstnessLattice.NonConst;
      if (constant.isNull &&
          checkedType.element != compiler.nullClass &&
          checkedType.element != compiler.objectClass) {
        // `(null is Type)` is true iff Type is in { Null, Object }.
        result = new _ConstnessLattice(new values.FalseConstant());
      } else {
        // Otherwise, perform a standard subtype check.
        result = new _ConstnessLattice(
            constantSystem.isSubtype(compiler, constantType, checkedType)
            ? new values.TrueConstant()
            : new values.FalseConstant());
      }

      setValues(result);
    }
  }

  void visitSetClosureVariable(SetClosureVariable node) {
    setReachable(node.body);
  }

  void visitDeclareFunction(DeclareFunction node) {
    setReachable(node.definition);
    setReachable(node.body);
  }

  // Definitions.
  void visitLiteralList(LiteralList node) {
    // Constant lists are translated into (Constant ListConstant(...)) IR nodes,
    // and thus LiteralList nodes are NonConst.
    setValue(node, _ConstnessLattice.NonConst);
  }

  void visitLiteralMap(LiteralMap node) {
    // Constant maps are translated into (Constant MapConstant(...)) IR nodes,
    // and thus LiteralMap nodes are NonConst.
    setValue(node, _ConstnessLattice.NonConst);
  }

  void visitConstant(Constant node) {
    setValue(node, new _ConstnessLattice(node.value));
  }

  void visitThis(This node) {
    setValue(node, _ConstnessLattice.NonConst);
  }

  void visitReifyTypeVar(ReifyTypeVar node) {
    setValue(node, _ConstnessLattice.NonConst);
  }

  void visitCreateFunction(CreateFunction node) {
    setReachable(node.definition);
    values.Constant constant =
        new values.FunctionConstant(node.definition.element);
    setValue(node, new _ConstnessLattice(constant));
  }

  void visitGetClosureVariable(GetClosureVariable node) {
    setValue(node, _ConstnessLattice.NonConst);
  }

  void visitParameter(Parameter node) {
    if (node.parent is FunctionDefinition) {
      // Functions may escape and thus their parameters must be initialized to
      // NonConst.
      setValue(node, _ConstnessLattice.NonConst);
    } else if (node.parent is Continuation) {
      // Continuations on the other hand are local, and parameters are
      // initialized to Unknown.
      setValue(node, _ConstnessLattice.Unknown);
    } else {
      compiler.internalError(node.hint, "Unexpected parent of Parameter");
    }
  }

  void visitContinuation(Continuation node) {
    node.parameters.forEach((Parameter p) {
      setValue(p, _ConstnessLattice.Unknown);
      defWorkset.add(p);
    });

    if (node.body != null) {
      setReachable(node.body);
    }
  }

  // Conditions.

  void visitIsTrue(IsTrue node) {
    Branch branch = node.parent;
    visitBranch(branch);
  }
}

/// Represents the constant-state of a variable at some point in the program.
/// UNKNOWN: may be some as yet undetermined constant.
/// CONSTANT: is a constant as stored in the local field.
/// NONCONST: not a constant.
class _ConstnessLattice {
  static const int UNKNOWN  = 0;
  static const int CONSTANT = 1;
  static const int NONCONST = 2;

  final int kind;
  final values.Constant constant;

  static final _ConstnessLattice Unknown =
      new _ConstnessLattice._internal(UNKNOWN, null);
  static final _ConstnessLattice NonConst =
      new _ConstnessLattice._internal(NONCONST, null);

  _ConstnessLattice._internal(this.kind, this.constant);
  _ConstnessLattice(this.constant) : kind = CONSTANT {
    assert(this.constant != null);
  }

  bool get isUnknown  => (kind == UNKNOWN);
  bool get isConstant => (kind == CONSTANT);
  bool get isNonConst => (kind == NONCONST);

  int get hashCode => kind | (constant.hashCode << 2);
  bool operator==(_ConstnessLattice that) =>
      (that.kind == this.kind && that.constant == this.constant);

  String toString() {
    switch (kind) {
      case UNKNOWN: return "Unknown";
      case CONSTANT: return "Constant: $constant";
      case NONCONST: return "Non-constant";
      default: assert(false);
    }
    return null;
  }

  /// Compute the join of two values in the lattice.
  _ConstnessLattice join(_ConstnessLattice that) {
    assert(that != null);

    if (this.isNonConst || that.isUnknown) {
      return this;
    }

    if (this.isUnknown || that.isNonConst) {
      return that;
    }

    if (this.constant == that.constant) {
      return this;
    }

    return NonConst;
  }
}