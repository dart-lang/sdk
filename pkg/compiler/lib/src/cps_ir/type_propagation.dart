// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.optimizers;

abstract class TypeSystem<T> {
  T get dynamicType;
  T get typeType;
  T get functionType;
  T get boolType;
  T get intType;
  T get stringType;
  T get listType;
  T get mapType;

  T getReturnType(FunctionElement element);
  T getParameterType(ParameterElement element);
  bool areAssignable(T a, T b);
  T join(T a, T b);
  T typeOf(ConstantValue constant);
}

class TypeMaskSystem implements TypeSystem<TypeMask> {
  final TypesTask inferrer;
  final ClassWorld classWorld;

  TypeMask get dynamicType => inferrer.dynamicType;
  TypeMask get typeType => inferrer.typeType;
  TypeMask get functionType => inferrer.functionType;
  TypeMask get boolType => inferrer.boolType;
  TypeMask get intType => inferrer.intType;
  TypeMask get stringType => inferrer.stringType;
  TypeMask get listType => inferrer.listType;
  TypeMask get mapType => inferrer.mapType;

  // TODO(karlklose): the map should be per continuation.
  Map<Node, TypeMask> map = <Node, TypeMask>{};

  TypeMaskSystem(dart2js.Compiler compiler)
    : inferrer = compiler.typesTask,
      classWorld = compiler.world;

  TypeMask getType(Node node) => map[node];

  setType(Primitive node, TypeMask type) => map[node] = type;

  TypeMask getParameterType(ParameterElement parameter) {
    return inferrer.getGuaranteedTypeOfElement(parameter);
  }

  TypeMask getReturnType(FunctionElement function) {
    return inferrer.getGuaranteedReturnTypeOfElement(function);
  }

  @override
  bool areAssignable(TypeMask a, TypeMask b) {
    return a.containsMask(b, classWorld) || b.containsMask(a, classWorld);
  }

  @override
  TypeMask join(TypeMask a, TypeMask b) {
    return a.union(b, classWorld);
  }

  @override
  TypeMask typeOf(ConstantValue constant) {
    return constant.computeMask(inferrer.compiler);
  }
}

typedef void InternalErrorFunction(Spannable location, String message);

/**
 * Propagates types (including value types for constants) throughout the IR, and
 * replaces branches with fixed jumps as well as side-effect free expressions
 * with known constant results.
 *
 * Should be followed by the [ShrinkingReducer] pass.
 *
 * Implemented according to 'Constant Propagation with Conditional Branches'
 * by Wegman, Zadeck.
 */
class TypePropagator<T> extends Pass {
  // TODO(karlklose): remove reference to _compiler. It is currently used to
  // compute [TypeMask]s.
  final dart2js.Compiler _compiler;

  // The constant system is used for evaluation of expressions with constant
  // arguments.
  final dart2js.ConstantSystem _constantSystem;
  final TypeSystem _typeSystem;
  final InternalErrorFunction _internalError;
  final Map<Node, _AbstractValue> _types;


  TypePropagator(this._compiler,
                 this._constantSystem,
                 this._typeSystem,
                 this._internalError)
      : _types = <Node, _AbstractValue>{};

  void _rewriteExecutableDefinition(ExecutableDefinition root) {
    // Set all parent pointers.
    new ParentVisitor().visit(root);

    // Analyze. In this phase, the entire term is analyzed for reachability
    // and the abstract value of each expression.
    _ConstPropagationVisitor<T> analyzer = new _ConstPropagationVisitor<T>(
        _constantSystem,
        _typeSystem,
        _types,
        _internalError,
        _compiler);

    analyzer.analyze(root);

    // Transform. Uses the data acquired in the previous analysis phase to
    // replace branches with fixed targets and side-effect-free expressions
    // with constant results.
    _TransformingVisitor transformer = new _TransformingVisitor(
        analyzer.reachableNodes, analyzer.values, _internalError);
    transformer.transform(root);
  }

  void rewriteFunctionDefinition(FunctionDefinition root) {
    if (root.isAbstract) return;
    _rewriteExecutableDefinition(root);
  }

  void rewriteFieldDefinition(FieldDefinition root) {
    if (!root.hasInitializer) return;
    _rewriteExecutableDefinition(root);
  }

  getType(Node node) => _types[node];
}

/**
 * Uses the information from a preceding analysis pass in order to perform the
 * actual transformations on the CPS graph.
 */
class _TransformingVisitor extends RecursiveVisitor {
  final Set<Node> reachable;
  final Map<Node, _AbstractValue> values;

  final InternalErrorFunction internalError;

  _TransformingVisitor(this.reachable, this.values, this.internalError);

  void transform(ExecutableDefinition root) {
    visit(root);
  }

  /// Given an expression with a known constant result and a continuation,
  /// replaces the expression by a new LetPrim / InvokeContinuation construct.
  /// `unlink` is a closure responsible for unlinking all removed references.
  LetPrim constifyExpression(Expression node,
                             Continuation continuation,
                             void unlink()) {
    _AbstractValue value = values[node];
    if (value == null || !value.isConstant) {
      return null;
    }

    assert(continuation.parameters.length == 1);

    // Set up the replacement structure.
    PrimitiveConstantValue primitiveConstant = value.constant;
    ConstantExpression constExp =
        new PrimitiveConstantExpression(primitiveConstant);
    Constant constant = new Constant(constExp);
    LetPrim letPrim = new LetPrim(constant);
    InvokeContinuation invoke =
        new InvokeContinuation(continuation, <Primitive>[constant]);

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
        new InvokeContinuation(successor, <Primitive>[]);

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
class _ConstPropagationVisitor<T> extends Visitor {
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

  final dart2js.ConstantSystem constantSystem;
  final TypeSystem typeSystem;
  final InternalErrorFunction internalError;
  final Compiler compiler;

  _AbstractValue unknownDynamic;

  _AbstractValue unknown([T t]) {
    if (t == null) {
      return unknownDynamic;
    } else {
      return new _AbstractValue.unknown(t);
    }
  }

  _AbstractValue nonConst([T type]) {
    if (type == null) {
      type = typeSystem.dynamicType;
    }
    return new _AbstractValue.nonConst(type);
  }

  _AbstractValue constantValue(ConstantValue constant, T type) {
    return new _AbstractValue(constant, type);
  }

  // Stores the current lattice value for nodes. Note that it contains not only
  // definitions as keys, but also expressions such as method invokes.
  // Access through [getValue] and [setValue].
  final Map<Node, _AbstractValue> values;

  _ConstPropagationVisitor(this.constantSystem, TypeSystem typeSystem,
      this.values,
      this.internalError, this.compiler)
    : this.unknownDynamic = new _AbstractValue.unknown(typeSystem.dynamicType),
      this.typeSystem = typeSystem;

  void analyze(ExecutableDefinition root) {
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
  _AbstractValue getValue(Node node) {
    _AbstractValue value = values[node];
    return (value == null) ? unknown() : value;
  }

  /// Joins the passed lattice [updateValue] to the current value of [node],
  /// and adds it to the definition work set if it has changed and [node] is
  /// a definition.
  void setValue(Node node, _AbstractValue updateValue) {
    _AbstractValue oldValue = getValue(node);
    _AbstractValue newValue = updateValue.join(oldValue, typeSystem);
    if (oldValue == newValue) {
      return;
    }

    // Values may only move in the direction UNKNOWN -> CONSTANT -> NONCONST.
    assert(newValue.kind >= oldValue.kind);

    values[node] = newValue;
    if (node is Definition) {
      defWorkset.add(node);
    }
  }

  // -------------------------- Visitor overrides ------------------------------

  void visitNode(Node node) {
    internalError(NO_LOCATION_SPANNABLE,
        "_ConstPropagationVisitor is stale, add missing visit overrides");
  }

  void visitFunctionDefinition(FunctionDefinition node) {
    node.parameters.forEach(visit);
    setReachable(node.body);
  }

  void visitFieldDefinition(FieldDefinition node) {
    if (node.hasInitializer) {
      setReachable(node.body);
    }
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
    Entity target = node.target;
    T returnType = target is FieldElement
        ? typeSystem.dynamicType
        : typeSystem.getReturnType(node.target);
    setValue(returnValue, nonConst(returnType));
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    // Forward the constant status of all continuation invokes to the
    // continuation. Note that this is effectively a phi node in SSA terms.
    for (int i = 0; i < node.arguments.length; i++) {
      Definition def = node.arguments[i].definition;
      _AbstractValue cell = getValue(def);
      setValue(cont.parameters[i], cell);
    }
  }

  void visitInvokeMethod(InvokeMethod node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    /// Sets the value of both the current node and the target continuation
    /// parameter.
    void setValues(_AbstractValue updateValue) {
      setValue(node, updateValue);
      Parameter returnValue = cont.parameters[0];
      setValue(returnValue, updateValue);
    }

    _AbstractValue lhs = getValue(node.receiver.definition);
    if (lhs.isUnknown) {
      // This may seem like a missed opportunity for evaluating short-circuiting
      // boolean operations; we are currently skipping these intentionally since
      // expressions such as `(new Foo() || true)` may introduce type errors
      // and thus evaluation to `true` would not be correct.
      // TODO(jgruber): Handle such cases while ensuring that new Foo() and
      // a type-check (in checked mode) are still executed.
      return;  // And come back later.
    } else if (lhs.isNonConst) {
      setValues(nonConst());
      return;
    } else if (!node.selector.isOperator) {
      // TODO(jgruber): Handle known methods on constants such as String.length.
      setValues(nonConst());
      return;
    }

    // Calculate the resulting constant if possible.
    ConstantValue result;
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

      _AbstractValue rhs = getValue(node.arguments[0].definition);
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
    if (result == null) {
      setValues(nonConst());
    } else {
      T type = typeSystem.typeOf(result);
      setValues(new _AbstractValue(result, type));
    }
   }

  void visitInvokeSuperMethod(InvokeSuperMethod node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    // TODO(karlklose): lookup the function and get ites return type.
    setValue(returnValue, nonConst());
  }

  void visitInvokeConstructor(InvokeConstructor node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    setValue(returnValue, nonConst());
  }

  void visitConcatenateStrings(ConcatenateStrings node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    void setValues(_AbstractValue updateValue) {
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

    T type = typeSystem.stringType;
    assert(cont.parameters.length == 1);
    if (allStringConstants) {
      // All constant, we can concatenate ourselves.
      Iterable<String> allStrings = node.arguments.map((Reference ref) {
        Constant constant = ref.definition;
        StringConstantValue stringConstant = constant.value;
        return stringConstant.primitiveValue.slowToString();
      });
      LiteralDartString dartString = new LiteralDartString(allStrings.join());
      ConstantValue constant = new StringConstantValue(dartString);
      setValues(new _AbstractValue(constant, type));
    } else {
      setValues(nonConst(type));
    }
  }

  void visitBranch(Branch node) {
    IsTrue isTrue = node.condition;
    _AbstractValue conditionCell = getValue(isTrue.value.definition);

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
      setValue(isTrue.value.definition, nonConst(typeSystem.boolType));
    } else if (conditionCell.isConstant &&
        conditionCell.constant.isBool) {
      BoolConstantValue boolConstant = conditionCell.constant;
      setReachable((boolConstant.isTrue) ?
          node.trueContinuation.definition : node.falseContinuation.definition);
    }
  }

  void visitTypeOperator(TypeOperator node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    void setValues(_AbstractValue updateValue) {
      setValue(node, updateValue);
      Parameter returnValue = cont.parameters[0];
      setValue(returnValue, updateValue);
    }

    if (node.isTypeCast) {
      // TODO(jgruber): Add support for `as` casts.
      setValues(nonConst());
    }

    _AbstractValue cell = getValue(node.receiver.definition);
    if (cell.isUnknown) {
      return;  // And come back later.
    } else if (cell.isNonConst) {
      setValues(nonConst(cell.type));
    } else if (node.type.kind == types.TypeKind.INTERFACE) {
      // Receiver is a constant, perform is-checks at compile-time.

      types.InterfaceType checkedType = node.type;
      ConstantValue constant = cell.constant;
      // TODO(karlklose): remove call to computeType.
      types.DartType constantType = constant.computeType(compiler);

      T type = typeSystem.boolType;
      _AbstractValue result;
      if (constant.isNull &&
          checkedType.element != compiler.nullClass &&
          checkedType.element != compiler.objectClass) {
        // `(null is Type)` is true iff Type is in { Null, Object }.
        result = constantValue(new FalseConstantValue(), type);
      } else {
        // Otherwise, perform a standard subtype check.
        result = constantValue(
            constantSystem.isSubtype(compiler, constantType, checkedType)
            ? new TrueConstantValue()
            : new FalseConstantValue(),
            type);
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
    setValue(node, nonConst(typeSystem.listType));
  }

  void visitLiteralMap(LiteralMap node) {
    // Constant maps are translated into (Constant MapConstant(...)) IR nodes,
    // and thus LiteralMap nodes are NonConst.
    setValue(node, nonConst(typeSystem.mapType));
  }

  void visitConstant(Constant node) {
    ConstantValue value = node.value;
    setValue(node, constantValue(value, typeSystem.typeOf(value)));
  }

  void visitThis(This node) {
    // TODO(karlklose): Add the type.
    setValue(node, nonConst());
  }

  void visitReifyTypeVar(ReifyTypeVar node) {
    setValue(node, nonConst(typeSystem.typeType));
  }

  void visitCreateFunction(CreateFunction node) {
    setReachable(node.definition);
    ConstantValue constant =
        new FunctionConstantValue(node.definition.element);
    setValue(node, constantValue(constant, typeSystem.functionType));
  }

  void visitGetClosureVariable(GetClosureVariable node) {
    setValue(node, nonConst());
  }

  void visitClosureVariable(ClosureVariable node) {
  }

  void visitParameter(Parameter node) {
    T type = typeSystem.getParameterType(node.hint);
    if (node.parent is FunctionDefinition) {
      // Functions may escape and thus their parameters must be initialized to
      // NonConst.
      setValue(node, nonConst(type));
    } else if (node.parent is Continuation) {
      // Continuations on the other hand are local, and parameters are
      // initialized to Unknown.
      setValue(node, unknown());
    } else {
      internalError(node.hint, "Unexpected parent of Parameter");
    }
  }

  void visitContinuation(Continuation node) {
    node.parameters.forEach((Parameter p) {
      // TODO(karlklose): join parameter types from use sites.
      setValue(p, unknown());
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

  // JavaScript specific nodes.

  void visitIdentical(Identical node) {
    _AbstractValue leftConst = getValue(node.left.definition);
    _AbstractValue rightConst = getValue(node.right.definition);
    ConstantValue leftValue = leftConst.constant;
    ConstantValue rightValue = rightConst.constant;
    if (leftConst.isUnknown || rightConst.isUnknown) {
      // Come back later.
      return;
    } else if (!leftConst.isConstant || !rightConst.isConstant) {
      T leftType = leftConst.type;
      T rightType = rightConst.type;
      if (!typeSystem.areAssignable(leftType, rightType)) {
        setValue(node,
            constantValue(new FalseConstantValue(), typeSystem.boolType));
      } else {
        setValue(node, nonConst(typeSystem.boolType));
      }
    } else if (leftValue.isPrimitive && rightValue.isPrimitive) {
      assert(leftConst.isConstant && rightConst.isConstant);
      PrimitiveConstantValue left = leftValue;
      PrimitiveConstantValue right = rightValue;
      ConstantValue result =
          new BoolConstantValue(left.primitiveValue == right.primitiveValue);
      setValue(node, new _AbstractValue(result, typeSystem.boolType));
    }
  }
}

/// Represents the abstract value of a primitive value at some point in the
/// program. Abstract values of all kinds have a type [T].
///
/// The different kinds of abstract values represents the knowledge about the
/// constness of the value:
///   UNKNOWN: may be some as yet undetermined constant.
///   CONSTANT: is a constant as stored in the local field.
///   NONCONST: not a constant.
class _AbstractValue<T> {
  static const int UNKNOWN  = 0;
  static const int CONSTANT = 1;
  static const int NONCONST = 2;

  final int kind;
  final ConstantValue constant;
  final T type;

  _AbstractValue._internal(this.kind, this.constant, this.type) {
    assert(kind != CONSTANT || constant != null);
    assert(type != null);
  }

  _AbstractValue(ConstantValue constant, T type)
      : this._internal(CONSTANT, constant, type);

  _AbstractValue.unknown(T type)
      : this._internal(UNKNOWN, null, type);

  _AbstractValue.nonConst(T type)
      : this._internal(NONCONST, null, type);

  bool get isUnknown  => (kind == UNKNOWN);
  bool get isConstant => (kind == CONSTANT);
  bool get isNonConst => (kind == NONCONST);

  int get hashCode {
    return kind | (constant.hashCode * 5) | type.hashCode * 7;
  }

  bool operator ==(_AbstractValue that) {
      return that.kind == this.kind &&
          that.constant == this.constant &&
          that.type == this.type;
  }

  String toString() {
    switch (kind) {
      case UNKNOWN: return "Unknown";
      case CONSTANT: return "Constant: $constant: $type";
      case NONCONST: return "Non-constant: $type";
      default: assert(false);
    }
    return null;
  }

  /// Compute the join of two values in the lattice.
  _AbstractValue join(_AbstractValue that, TypeSystem typeSystem) {
    assert(that != null);

    if (this.isUnknown) {
      return that;
    } else if (that.isUnknown) {
      return this;
    } else if (this.isConstant && that.isConstant &&
               this.constant == that.constant) {
      return this;
    } else {
      return new _AbstractValue.nonConst(typeSystem.join(this.type, that.type));
    }
  }
}