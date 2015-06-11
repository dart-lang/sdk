// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'optimizers.dart' show Pass, ParentVisitor;

import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../resolution/operators.dart';
import '../constants/values.dart';
import '../dart_types.dart' as types;
import '../dart2jslib.dart' as dart2js;
import '../tree/tree.dart' show LiteralDartString;
import 'cps_ir_nodes.dart';
import '../types/types.dart' show TypeMask, TypesTask;
import '../types/constants.dart' show computeTypeMask;
import '../elements/elements.dart' show ClassElement, Element, Entity,
    FieldElement, FunctionElement, ParameterElement;
import '../dart2jslib.dart' show ClassWorld;
import '../universe/universe.dart';

enum AbstractBool {
  True, False, Maybe, Nothing
}

class TypeMaskSystem {
  final TypesTask inferrer;
  final ClassWorld classWorld;

  TypeMask get dynamicType => inferrer.dynamicType;
  TypeMask get typeType => inferrer.typeType;
  TypeMask get functionType => inferrer.functionType;
  TypeMask get boolType => inferrer.boolType;
  TypeMask get intType => inferrer.intType;
  TypeMask get numType => inferrer.numType;
  TypeMask get stringType => inferrer.stringType;
  TypeMask get listType => inferrer.listType;
  TypeMask get mapType => inferrer.mapType;
  TypeMask get nonNullType => inferrer.nonNullType;

  // TODO(karlklose): remove compiler here.
  TypeMaskSystem(dart2js.Compiler compiler)
    : inferrer = compiler.typesTask,
      classWorld = compiler.world;

  TypeMask getParameterType(ParameterElement parameter) {
    return inferrer.getGuaranteedTypeOfElement(parameter);
  }

  TypeMask getReturnType(FunctionElement function) {
    return inferrer.getGuaranteedReturnTypeOfElement(function);
  }

  TypeMask getSelectorReturnType(Selector selector) {
    return inferrer.getGuaranteedTypeOfSelector(selector);
  }

  TypeMask getFieldType(FieldElement field) {
    return inferrer.getGuaranteedTypeOfElement(field);
  }

  TypeMask join(TypeMask a, TypeMask b) {
    return a.union(b, classWorld);
  }

  TypeMask getTypeOf(ConstantValue constant) {
    return computeTypeMask(inferrer.compiler, constant);
  }

  TypeMask exact(ClassElement element) {
    // The class world does not know about classes created by
    // closure conversion, so just treat those as a subtypes of Function.
    // TODO(asgerf): Maybe closure conversion should create a new ClassWorld?
    if (element.isClosure) return functionType;
    return new TypeMask.exact(element, classWorld);
  }

  bool isDefinitelyBool(TypeMask t) {
    return t.containsOnlyBool(classWorld) && !t.isNullable;
  }

  bool isDefinitelyNotNull(TypeMask t) => !t.isNullable;

  bool areDisjoint(TypeMask leftType, TypeMask rightType) {
    TypeMask intersection = leftType.intersection(rightType, classWorld);
    return intersection.isEmpty && !intersection.isNullable;
  }

  AbstractBool isSubtypeOf(TypeMask value,
                           types.DartType type,
                           {bool allowNull}) {
    assert(allowNull != null);
    if (type is types.DynamicType) {
      if (!allowNull && value.isNullable) return AbstractBool.Maybe;
      return AbstractBool.True;
    }
    if (type is types.InterfaceType) {
      TypeMask typeAsMask = allowNull
          ? new TypeMask.subtype(type.element, classWorld)
          : new TypeMask.nonNullSubtype(type.element, classWorld);
      if (areDisjoint(value, typeAsMask)) {
        // Disprove the subtype relation based on the class alone.
        return AbstractBool.False;
      }
      if (!type.treatAsRaw) {
        // If there are type arguments, we cannot prove the subtype relation,
        // because the type arguments are unknown on both the value and type.
        return AbstractBool.Maybe;
      }
      if (typeAsMask.containsMask(value, classWorld)) {
        // All possible values are contained in the set of allowed values.
        // Note that we exploit the fact that [typeAsMask] is an exact
        // representation of [type], not an approximation.
        return AbstractBool.True;
      }
      // The value is neither contained in the type, nor disjoint from the type.
      return AbstractBool.Maybe;
    }
    // TODO(asgerf): Support function types, and what else might be missing.
    return AbstractBool.Maybe;
  }
}

class ConstantPropagationLattice {
  final TypeMaskSystem typeSystem;
  final ConstantSystem constantSystem;
  final types.DartTypes dartTypes;
  final AbstractValue anything;

  ConstantPropagationLattice(TypeMaskSystem typeSystem,
                             this.constantSystem,
                             this.dartTypes)
    : this.typeSystem = typeSystem,
      anything = new AbstractValue.nonConstant(typeSystem.dynamicType);

  final AbstractValue nothing = new AbstractValue.nothing();

  AbstractValue constant(ConstantValue value, [TypeMask type]) {
    if (type == null) type = typeSystem.getTypeOf(value);
    return new AbstractValue.constantValue(value, type);
  }

  AbstractValue nonConstant([TypeMask type]) {
    if (type == null) type = typeSystem.dynamicType;
    return new AbstractValue.nonConstant(type);
  }

  /// Compute the join of two values in the lattice.
  AbstractValue join(AbstractValue x, AbstractValue y) {
    assert(x != null);
    assert(y != null);

    if (x.isNothing) {
      return y;
    } else if (y.isNothing) {
      return x;
    } else if (x.isConstant && y.isConstant && x.constant == y.constant) {
      return x;
    } else {
      return new AbstractValue.nonConstant(typeSystem.join(x.type, y.type));
    }
  }

  /// True if all members of this value are booleans.
  bool isDefinitelyBool(AbstractValue value) {
    return value.isNothing || typeSystem.isDefinitelyBool(value.type);
  }

  /// True if null is not a member of this value.
  bool isDefinitelyNotNull(AbstractValue value) {
    if (value.isNothing) return true;
    if (value.isConstant) return !value.constant.isNull;
    return typeSystem.isDefinitelyNotNull(value.type);
  }

  /// Returns whether the given [value] is an instance of [type].
  ///
  /// Since [value] and [type] are not always known, [AbstractBool.Maybe] is
  /// returned if the answer is not known.
  ///
  /// [AbstractBool.Nothing] is returned if [value] is nothing.
  ///
  /// If [allowNull] is true, `null` is considered to an instance of anything,
  /// otherwise it is only considered an instance of [Object], [dynamic], and
  /// [Null].
  AbstractBool isSubtypeOf(AbstractValue value,
                           types.DartType type,
                           {bool allowNull}) {
    assert(allowNull != null);
    if (value.isNothing) {
      return AbstractBool.Nothing;
    }
    if (value.isConstant) {
      if (value.constant.isNull) {
        if (allowNull ||
            type.isObject ||
            type.isDynamic ||
            type == dartTypes.coreTypes.nullType) {
          return AbstractBool.True;
        }
        if (type is types.TypeVariableType) {
          return AbstractBool.Maybe;
        }
        return AbstractBool.False;
      }
      types.DartType valueType = value.constant.getType(dartTypes.coreTypes);
      if (constantSystem.isSubtype(dartTypes, valueType, type)) {
        return AbstractBool.True;
      }
      if (!dartTypes.isPotentialSubtype(valueType, type)) {
        return AbstractBool.False;
      }
      return AbstractBool.Maybe;
    }
    return typeSystem.isSubtypeOf(value.type, type, allowNull: allowNull);
  }

  /// Returns the possible results of applying [operator] to [value],
  /// assuming the operation does not throw.
  ///
  /// Because we do not explicitly track thrown values, we currently use the
  /// convention that constant values are returned from this method only
  /// if the operation is known not to throw.
  AbstractValue unaryOp(UnaryOperator operator,
                        AbstractValue value) {
    // TODO(asgerf): Also return information about whether this can throw?
    if (value.isNothing) {
      return nothing;
    }
    if (value.isConstant) {
      UnaryOperation operation = constantSystem.lookupUnary(operator);
      ConstantValue result = operation.fold(value.constant);
      if (result == null) return anything;
      return constant(result);
    }
    return anything; // TODO(asgerf): Look up type.
  }

  /// Returns the possible results of applying [operator] to [left], [right],
  /// assuming the operation does not throw.
  ///
  /// Because we do not explicitly track thrown values, we currently use the
  /// convention that constant values are returned from this method only
  /// if the operation is known not to throw.
  AbstractValue binaryOp(BinaryOperator operator,
                         AbstractValue left,
                         AbstractValue right) {
    if (left.isNothing || right.isNothing) {
      return nothing;
    }
    if (left.isConstant && right.isConstant) {
      BinaryOperation operation = constantSystem.lookupBinary(operator);
      ConstantValue result = operation.fold(left.constant, right.constant);
      if (result == null) return anything;
      return constant(result);
    }
    return anything; // TODO(asgerf): Look up type.
  }
}

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
class TypePropagator extends Pass {
  String get passName => 'Sparse constant propagation';

  // The constant system is used for evaluation of expressions with constant
  // arguments.
  final ConstantPropagationLattice _lattice;
  final dart2js.InternalErrorFunction _internalError;
  final Map<Definition, AbstractValue> _values = <Definition, AbstractValue>{};

  TypePropagator(dart2js.Compiler compiler)
      : _internalError = compiler.internalError,
        _lattice = new ConstantPropagationLattice(
            new TypeMaskSystem(compiler),
            compiler.backend.constantSystem,
            compiler.types);

  @override
  void rewrite(FunctionDefinition root) {
    // Set all parent pointers.
    new ParentVisitor().visit(root);

    Map<Expression, ConstantValue> replacements = <Expression, ConstantValue>{};

    // Analyze. In this phase, the entire term is analyzed for reachability
    // and the abstract value of each expression.
    TypePropagationVisitor analyzer = new TypePropagationVisitor(
        _lattice,
        _values,
        replacements,
        _internalError);

    analyzer.analyze(root);

    // Transform. Uses the data acquired in the previous analysis phase to
    // replace branches with fixed targets and side-effect-free expressions
    // with constant results or existing values that are in scope.
    TransformingVisitor transformer = new TransformingVisitor(
        _lattice,
        analyzer.reachableNodes,
        analyzer.values,
        replacements,
        _internalError);
    transformer.transform(root);
  }

  getType(Node node) => _values[node];
}

/**
 * Uses the information from a preceding analysis pass in order to perform the
 * actual transformations on the CPS graph.
 */
class TransformingVisitor extends RecursiveVisitor {
  final Set<Node> reachable;
  final Map<Node, AbstractValue> values;
  final Map<Expression, ConstantValue> replacements;
  final ConstantPropagationLattice lattice;

  TypeMaskSystem get typeSystem => lattice.typeSystem;

  final dart2js.InternalErrorFunction internalError;

  TransformingVisitor(this.lattice,
                      this.reachable,
                      this.values,
                      this.replacements,
                      this.internalError);

  void transform(FunctionDefinition root) {
    visit(root);
  }

  Constant makeConstantPrimitive(ConstantValue constant) {
    ConstantExpression constExp =
        const ConstantExpressionCreator().convert(constant);
    Constant primitive = new Constant(constExp, constant);
    values[primitive] = new AbstractValue.constantValue(constant,
        typeSystem.getTypeOf(constant));
    return primitive;
  }

  /// Given an expression with a known constant result and a continuation,
  /// replaces the expression by a new LetPrim / InvokeContinuation construct.
  /// `unlink` is a closure responsible for unlinking all removed references.
  LetPrim constifyExpression(Expression node,
                             Continuation continuation,
                             void unlink()) {
    ConstantValue constant = replacements[node];
    if (constant == null) return null;

    assert(continuation.parameters.length == 1);
    InteriorNode parent = node.parent;
    Constant primitive = makeConstantPrimitive(constant);
    LetPrim letPrim = new LetPrim(primitive);

    InvokeContinuation invoke =
        new InvokeContinuation(continuation, <Primitive>[primitive]);
    parent.body = letPrim;
    letPrim.body = invoke;
    invoke.parent = letPrim;
    letPrim.parent = parent;

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
      AbstractValue receiver = getValue(node.receiver.definition);
      node.receiverIsNotNull = lattice.isDefinitelyNotNull(receiver);
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

  void visitTypeCast(TypeCast node) {
    Continuation cont = node.continuation.definition;
    InteriorNode parent = node.parent;

    AbstractValue value = getValue(node.value.definition);
    switch (lattice.isSubtypeOf(value, node.type, allowNull: true)) {
      case AbstractBool.Maybe:
      case AbstractBool.Nothing:
        break;

      case AbstractBool.True:
        // Cast always succeeds, replace it with InvokeContinuation.
        InvokeContinuation invoke =
            new InvokeContinuation.fromCall(node.continuation, node.value);
        parent.body = invoke;
        invoke.parent = parent;
        super.visitInvokeContinuation(invoke);
        return;

      case AbstractBool.False:
        // Cast always fails, remove unreachable continuation body.
        assert(!reachable.contains(cont));
        RemovalVisitor.remove(cont.body);
        cont.body = new Unreachable()..parent = cont;
        break;
    }

    super.visitTypeCast(node);
  }

  AbstractValue getValue(Primitive primitive) {
    AbstractValue value = values[primitive];
    return value == null ? new AbstractValue.nothing() : value;
  }

  void visitIdentical(Identical node) {
    Primitive left = node.left.definition;
    Primitive right = node.right.definition;
    AbstractValue leftValue = getValue(left);
    AbstractValue rightValue = getValue(right);
    // Replace identical(x, true) by x when x is known to be a boolean.
    if (lattice.isDefinitelyBool(leftValue) &&
        rightValue.isConstant &&
        rightValue.constant.isTrue) {
      left.substituteFor(node);
    }
  }

  void visitLetPrim(LetPrim node) {
    AbstractValue value = getValue(node.primitive);
    if (node.primitive is! Constant && value.isConstant) {
      // If the value is a known constant, compile it as a constant.
      Constant newPrim = makeConstantPrimitive(value.constant);
      LetPrim newLet = new LetPrim(newPrim);
      node.parent.body = newLet;
      newLet.body = node.body;
      node.body.parent = newLet;
      newLet.parent = node.parent;
      newPrim.substituteFor(node.primitive);
      RemovalVisitor.remove(node.primitive);
      visit(newLet.body);
    } else {
      super.visitLetPrim(node);
    }
  }
}

/**
 * Runs an analysis pass on the given function definition in order to detect
 * const-ness as well as reachability, both of which are used in the subsequent
 * transformation pass.
 */
class TypePropagationVisitor implements Visitor {
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

  final ConstantPropagationLattice lattice;
  final dart2js.InternalErrorFunction internalError;

  TypeMaskSystem get typeSystem => lattice.typeSystem;

  AbstractValue get nothing => lattice.nothing;

  AbstractValue nonConstant([TypeMask type]) => lattice.nonConstant(type);

  AbstractValue constantValue(ConstantValue constant, [TypeMask type]) {
    return lattice.constant(constant, type);
  }

  // Stores the current lattice value for primitives and mutable variables.
  // Access through [getValue] and [setValue].
  final Map<Definition, AbstractValue> values;

  /// Expressions that invoke their call continuation with a constant value
  /// and without any side effects. These can be replaced by the constant.
  final Map<Expression, ConstantValue> replacements;

  TypePropagationVisitor(this.lattice,
                         this.values,
                         this.replacements,
                         this.internalError);

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

  /// Returns the lattice value corresponding to [node], defaulting to nothing.
  ///
  /// Never returns null.
  AbstractValue getValue(Node node) {
    AbstractValue value = values[node];
    return (value == null) ? nothing : value;
  }

  /// Joins the passed lattice [updateValue] to the current value of [node],
  /// and adds it to the definition work set if it has changed and [node] is
  /// a definition.
  void setValue(Node node, AbstractValue updateValue) {
    AbstractValue oldValue = getValue(node);
    AbstractValue newValue = lattice.join(oldValue, updateValue);
    if (oldValue == newValue) {
      return;
    }

    // Values may only move in the direction NOTHING -> CONSTANT -> NONCONST.
    assert(newValue.kind >= oldValue.kind);

    values[node] = newValue;
    if (node is Definition) {
      defWorkset.add(node);
    }
  }

  // -------------------------- Visitor overrides ------------------------------
  void visit(Node node) { node.accept(this); }

  void visitFunctionDefinition(FunctionDefinition node) {
    if (node.thisParameter != null) {
      // TODO(asgerf): Use a more precise type for 'this'.
      setValue(node.thisParameter, nonConstant(typeSystem.nonNullType));
    }
    node.parameters.forEach(visit);
    setReachable(node.body);
  }

  void visitLetPrim(LetPrim node) {
    visit(node.primitive); // No reason to delay visits to primitives.
    setReachable(node.body);
  }

  void visitLetCont(LetCont node) {
    // The continuation is only marked as reachable on use.
    setReachable(node.body);
  }

  void visitLetHandler(LetHandler node) {
    setReachable(node.body);
    // The handler is assumed to be reachable (we could instead treat it as
    // unreachable unless we find something reachable that might throw in the
    // body --- it's not clear if we want to do that here or in some other
    // pass).  The handler parameters are assumed to be unknown.
    //
    // TODO(kmillikin): we should set the type of the exception and stack
    // trace here.  The way we do that depends on how we handle 'on T' catch
    // clauses.
    setReachable(node.handler);
    for (Parameter param in node.handler.parameters) {
      setValue(param, nonConstant());
    }
  }

  void visitLetMutable(LetMutable node) {
    setValue(node.variable, getValue(node.value.definition));
    setReachable(node.body);
  }

  void visitInvokeStatic(InvokeStatic node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    Entity target = node.target;
    TypeMask returnType = target is FieldElement
        ? typeSystem.dynamicType
        : typeSystem.getReturnType(node.target);
    setValue(returnValue, nonConstant(returnType));
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    // Forward the constant status of all continuation invokes to the
    // continuation. Note that this is effectively a phi node in SSA terms.
    for (int i = 0; i < node.arguments.length; i++) {
      Definition def = node.arguments[i].definition;
      AbstractValue cell = getValue(def);
      setValue(cont.parameters[i], cell);
    }
  }

  void visitInvokeMethod(InvokeMethod node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    /// Sets the value of the target continuation parameter, and possibly
    /// try to replace the whole invocation with a constant.
    void setResult(AbstractValue updateValue, {bool canReplace: false}) {
      Parameter returnValue = cont.parameters[0];
      setValue(returnValue, updateValue);
      if (canReplace && updateValue.isConstant) {
        replacements[node] = updateValue.constant;
      } else {
        // A previous iteration might have tried to replace this.
        replacements.remove(node);
      }
    }

    AbstractValue lhs = getValue(node.receiver.definition);
    if (lhs.isNothing) {
      return;  // And come back later.
    }
    if (!node.selector.isOperator) {
      // TODO(jgruber): Handle known methods on constants such as String.length.
      setResult(nonConstant(typeSystem.getSelectorReturnType(node.selector)));
      return;
    }

    // TODO(asgerf): Support constant folding on intercepted calls!

    // Calculate the resulting constant if possible.
    AbstractValue result;
    String opname = node.selector.name;
    if (node.selector.argumentCount == 0) {
      // Unary operator.
      if (opname == "unary-") {
        opname = "-";
      }
      UnaryOperator operator = UnaryOperator.parse(opname);
      result = lattice.unaryOp(operator, lhs);
    } else if (node.selector.argumentCount == 1) {
      // Binary operator.
      AbstractValue rhs = getValue(node.arguments[0].definition);
      BinaryOperator operator = BinaryOperator.parse(opname);
      result = lattice.binaryOp(operator, lhs, rhs);
    }

    // Update value of the continuation parameter. Again, this is effectively
    // a phi.
    if (result == null) {
      setResult(nonConstant());
    } else {
      setResult(result, canReplace: true);
    }
   }

  void visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    // TODO(karlklose): lookup the function and get ites return type.
    setValue(returnValue, nonConstant());
  }

  void visitInvokeConstructor(InvokeConstructor node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    setValue(returnValue, nonConstant(typeSystem.getReturnType(node.target)));
  }

  void visitConcatenateStrings(ConcatenateStrings node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    /// Sets the value of the target continuation parameter, and possibly
    /// try to replace the whole invocation with a constant.
    void setResult(AbstractValue updateValue, {bool canReplace: false}) {
      Parameter returnValue = cont.parameters[0];
      setValue(returnValue, updateValue);
      if (canReplace && updateValue.isConstant) {
        replacements[node] = updateValue.constant;
      } else {
        // A previous iteration might have tried to replace this.
        replacements.remove(node);
      }
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

    TypeMask type = typeSystem.stringType;
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
      setResult(constantValue(constant, type), canReplace: true);
    } else {
      setResult(nonConstant(type));
    }
  }

  void visitThrow(Throw node) {
  }

  void visitRethrow(Rethrow node) {
  }

  void visitUnreachable(Unreachable node) {
  }

  void visitNonTailThrow(NonTailThrow node) {
    internalError(null, 'found non-tail throw after they were eliminated');
  }

  void visitBranch(Branch node) {
    IsTrue isTrue = node.condition;
    AbstractValue conditionCell = getValue(isTrue.value.definition);

    if (conditionCell.isNothing) {
      return;  // And come back later.
    } else if (conditionCell.isNonConst) {
      setReachable(node.trueContinuation.definition);
      setReachable(node.falseContinuation.definition);
    } else if (conditionCell.isConstant && !conditionCell.constant.isBool) {
      // Treat non-bool constants in condition as non-const since they result
      // in type errors in checked mode.
      // TODO(jgruber): Default to false in unchecked mode.
      setReachable(node.trueContinuation.definition);
      setReachable(node.falseContinuation.definition);
      setValue(isTrue.value.definition, nonConstant(typeSystem.boolType));
    } else if (conditionCell.isConstant && conditionCell.constant.isBool) {
      BoolConstantValue boolConstant = conditionCell.constant;
      setReachable((boolConstant.isTrue) ?
          node.trueContinuation.definition : node.falseContinuation.definition);
    }
  }

  void visitTypeTest(TypeTest node) {
    AbstractValue input = getValue(node.value.definition);
    TypeMask boolType = typeSystem.boolType;
    switch(lattice.isSubtypeOf(input, node.type, allowNull: false)) {
      case AbstractBool.Nothing:
        break; // And come back later.

      case AbstractBool.True:
        setValue(node, constantValue(new TrueConstantValue(), boolType));
        break;

      case AbstractBool.False:
        setValue(node, constantValue(new FalseConstantValue(), boolType));
        break;

      case AbstractBool.Maybe:
        setValue(node, nonConstant(boolType));
        break;
    }
  }

  void visitTypeCast(TypeCast node) {
    Continuation cont = node.continuation.definition;
    AbstractValue input = getValue(node.value.definition);
    switch (lattice.isSubtypeOf(input, node.type, allowNull: true)) {
      case AbstractBool.Nothing:
        break; // And come back later.

      case AbstractBool.True:
        setReachable(cont);
        setValue(cont.parameters.single, input);
        break;

      case AbstractBool.False:
        break; // Cast fails. Continuation should remain unreachable.

      case AbstractBool.Maybe:
        // TODO(asgerf): Narrow type of output to those that survive the cast.
        setReachable(cont);
        setValue(cont.parameters.single, input);
        break;
    }
  }

  void visitSetMutableVariable(SetMutableVariable node) {
    setValue(node.variable.definition, getValue(node.value.definition));
    setReachable(node.body);
  }

  void visitLiteralList(LiteralList node) {
    // Constant lists are translated into (Constant ListConstant(...)) IR nodes,
    // and thus LiteralList nodes are NonConst.
    setValue(node, nonConstant(typeSystem.listType));
  }

  void visitLiteralMap(LiteralMap node) {
    // Constant maps are translated into (Constant MapConstant(...)) IR nodes,
    // and thus LiteralMap nodes are NonConst.
    setValue(node, nonConstant(typeSystem.mapType));
  }

  void visitConstant(Constant node) {
    ConstantValue value = node.value;
    setValue(node, constantValue(value, typeSystem.getTypeOf(value)));
  }

  void visitCreateFunction(CreateFunction node) {
    setReachable(node.definition);
    ConstantValue constant =
        new FunctionConstantValue(node.definition.element);
    setValue(node, constantValue(constant, typeSystem.functionType));
  }

  void visitGetMutableVariable(GetMutableVariable node) {
    setValue(node, getValue(node.variable.definition));
  }

  void visitMutableVariable(MutableVariable node) {
    // [MutableVariable]s are bound either as parameters to
    // [FunctionDefinition]s, by [LetMutable].
    if (node.parent is FunctionDefinition) {
      // Just like immutable parameters, the values of mutable parameters are
      // never constant.
      // TODO(karlklose): remove reference to the element model.
      Entity source = node.hint;
      TypeMask type = (source is ParameterElement)
          ? typeSystem.getParameterType(source)
          : typeSystem.dynamicType;
      setValue(node, nonConstant(type));
    } else if (node.parent is LetMutable) {
      // Mutable values bound by LetMutable could have known values.
    } else {
      internalError(node.hint, "Unexpected parent of MutableVariable");
    }
  }

  void visitParameter(Parameter node) {
    Entity source = node.hint;
    // TODO(karlklose): remove reference to the element model.
    TypeMask type = (source is ParameterElement)
        ? typeSystem.getParameterType(source)
        : typeSystem.dynamicType;
    if (node.parent is FunctionDefinition) {
      // Functions may escape and thus their parameters must be non-constant.
      setValue(node, nonConstant(type));
    } else if (node.parent is Continuation) {
      // Continuations on the other hand are local, and parameters can have
      // some other abstract value than non-constant.
    } else {
      internalError(node.hint, "Unexpected parent of Parameter: ${node.parent}");
    }
  }

  void visitContinuation(Continuation node) {
    node.parameters.forEach(visit);

    if (node.body != null) {
      setReachable(node.body);
    }
  }

  void visitGetStatic(GetStatic node) {
    if (node.element.isFunction) {
      setValue(node, nonConstant(typeSystem.functionType));
    } else {
      setValue(node, nonConstant(typeSystem.getFieldType(node.element)));
    }
  }

  void visitSetStatic(SetStatic node) {
    setReachable(node.body);
  }

  void visitGetLazyStatic(GetLazyStatic node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];
    setValue(returnValue, nonConstant(typeSystem.getFieldType(node.element)));
  }

  void visitIsTrue(IsTrue node) {
    Branch branch = node.parent;
    visitBranch(branch);
  }

  void visitIdentical(Identical node) {
    AbstractValue leftConst = getValue(node.left.definition);
    AbstractValue rightConst = getValue(node.right.definition);
    ConstantValue leftValue = leftConst.constant;
    ConstantValue rightValue = rightConst.constant;
    if (leftConst.isNothing || rightConst.isNothing) {
      // Come back later.
      return;
    } else if (!leftConst.isConstant || !rightConst.isConstant) {
      TypeMask leftType = leftConst.type;
      TypeMask rightType = rightConst.type;
      if (typeSystem.areDisjoint(leftType, rightType)) {
        setValue(node,
            constantValue(new FalseConstantValue(), typeSystem.boolType));
      } else {
        setValue(node, nonConstant(typeSystem.boolType));
      }
    } else if (leftValue.isPrimitive && rightValue.isPrimitive) {
      assert(leftConst.isConstant && rightConst.isConstant);
      PrimitiveConstantValue left = leftValue;
      PrimitiveConstantValue right = rightValue;
      ConstantValue result =
          new BoolConstantValue(left.primitiveValue == right.primitiveValue);
      setValue(node, constantValue(result, typeSystem.boolType));
    }
  }

  void visitInterceptor(Interceptor node) {
    setReachable(node.input.definition);
    AbstractValue value = getValue(node.input.definition);
    if (!value.isNothing) {
      setValue(node, nonConstant(typeSystem.nonNullType));
    }
  }

  void visitGetField(GetField node) {
    setValue(node, nonConstant(typeSystem.getFieldType(node.field)));
  }

  void visitSetField(SetField node) {
    setReachable(node.body);
  }

  void visitCreateBox(CreateBox node) {
    setValue(node, nonConstant(typeSystem.nonNullType));
  }

  void visitCreateInstance(CreateInstance node) {
    setValue(node, nonConstant(typeSystem.exact(node.classElement)));
  }

  void visitReifyRuntimeType(ReifyRuntimeType node) {
    setValue(node, nonConstant(typeSystem.typeType));
  }

  void visitReadTypeVariable(ReadTypeVariable node) {
    // TODO(karlklose): come up with a type marker for JS entities or switch to
    // real constants of type [Type].
    setValue(node, nonConstant());
  }

  @override
  visitTypeExpression(TypeExpression node) {
    // TODO(karlklose): come up with a type marker for JS entities or switch to
    // real constants of type [Type].
    setValue(node, nonConstant());
  }

  void visitCreateInvocationMirror(CreateInvocationMirror node) {
    // TODO(asgerf): Expose [Invocation] type.
    setValue(node, nonConstant(typeSystem.nonNullType));
  }
}

/// Represents the abstract value of a primitive value at some point in the
/// program. Abstract values of all kinds have a type [T].
///
/// The different kinds of abstract values represents the knowledge about the
/// constness of the value:
///   NOTHING:  cannot have any value
///   CONSTANT: is a constant. The value is stored in the [constant] field,
///             and the type of the constant is in the [type] field.
///   NONCONST: not a constant, but [type] may hold some information.
class AbstractValue {
  static const int NOTHING  = 0;
  static const int CONSTANT = 1;
  static const int NONCONST = 2;

  final int kind;
  final ConstantValue constant;
  final TypeMask type;

  AbstractValue._internal(this.kind, this.constant, this.type) {
    assert(kind != CONSTANT || constant != null);
  }

  AbstractValue.nothing()
      : this._internal(NOTHING, null, null);

  AbstractValue.constantValue(ConstantValue constant, TypeMask type)
      : this._internal(CONSTANT, constant, type);

  AbstractValue.nonConstant(TypeMask type)
      : this._internal(NONCONST, null, type);

  bool get isNothing  => (kind == NOTHING);
  bool get isConstant => (kind == CONSTANT);
  bool get isNonConst => (kind == NONCONST);

  int get hashCode {
    int hash = kind * 31 + constant.hashCode * 59 + type.hashCode * 67;
    return hash & 0x3fffffff;
  }

  bool operator ==(AbstractValue that) {
    return that.kind == this.kind &&
           that.constant == this.constant &&
           that.type == this.type;
  }

  String toString() {
    switch (kind) {
      case NOTHING: return "Nothing";
      case CONSTANT: return "Constant: $constant: $type";
      case NONCONST: return "Non-constant: $type";
      default: assert(false);
    }
    return null;
  }
}

class ConstantExpressionCreator
    implements ConstantValueVisitor<ConstantExpression, dynamic> {

  const ConstantExpressionCreator();

  ConstantExpression convert(ConstantValue value) => value.accept(this, null);

  @override
  ConstantExpression visitBool(BoolConstantValue constant, _) {
    return new BoolConstantExpression(constant.primitiveValue);
  }

  @override
  ConstantExpression visitConstructed(ConstructedConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitConstructed");
  }

  @override
  ConstantExpression visitDeferred(DeferredConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitDeferred");
  }

  @override
  ConstantExpression visitDouble(DoubleConstantValue constant, arg) {
    return new DoubleConstantExpression(constant.primitiveValue);
  }

  @override
  ConstantExpression visitSynthetic(SyntheticConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitSynthetic");
  }

  @override
  ConstantExpression visitFunction(FunctionConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitFunction");
  }

  @override
  ConstantExpression visitInt(IntConstantValue constant, arg) {
    return new IntConstantExpression(constant.primitiveValue);
  }

  @override
  ConstantExpression visitInterceptor(InterceptorConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitInterceptor");
  }

  @override
  ConstantExpression visitList(ListConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitList");
  }

  @override
  ConstantExpression visitMap(MapConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitMap");
  }

  @override
  ConstantExpression visitNull(NullConstantValue constant, arg) {
    return new NullConstantExpression();
  }

  @override
  ConstantExpression visitString(StringConstantValue constant, arg) {
    return new StringConstantExpression(
        constant.primitiveValue.slowToString());
  }

  @override
  ConstantExpression visitType(TypeConstantValue constant, arg) {
    throw new UnsupportedError("ConstantExpressionCreator.visitType");
  }
}