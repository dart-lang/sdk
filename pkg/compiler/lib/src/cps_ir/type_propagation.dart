// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'optimizers.dart';

import '../constants/constant_system.dart';
import '../resolution/operators.dart';
import '../constants/values.dart';
import '../dart_types.dart' as types;
import '../dart2jslib.dart' as dart2js;
import '../tree/tree.dart' show DartString, ConsDartString, LiteralDartString;
import 'cps_ir_nodes.dart';
import '../types/types.dart';
import '../types/constants.dart' show computeTypeMask;
import '../elements/elements.dart';
import '../dart2jslib.dart' show ClassWorld, World;
import '../universe/universe.dart';
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../io/source_information.dart' show SourceInformation;
import 'cps_fragment.dart';

enum AbstractBool {
  True, False, Maybe, Nothing
}

class TypeMaskSystem {
  final TypesTask inferrer;
  final World classWorld;
  final JavaScriptBackend backend;

  TypeMask get dynamicType => inferrer.dynamicType;
  TypeMask get typeType => inferrer.typeType;
  TypeMask get functionType => inferrer.functionType;
  TypeMask get boolType => inferrer.boolType;
  TypeMask get intType => inferrer.intType;
  TypeMask get doubleType => inferrer.doubleType;
  TypeMask get numType => inferrer.numType;
  TypeMask get stringType => inferrer.stringType;
  TypeMask get listType => inferrer.listType;
  TypeMask get mapType => inferrer.mapType;
  TypeMask get nonNullType => inferrer.nonNullType;
  TypeMask get mutableNativeListType => backend.mutableArrayType;

  TypeMask numStringBoolType;

  ClassElement get jsNullClass => backend.jsNullClass;

  // TODO(karlklose): remove compiler here.
  TypeMaskSystem(dart2js.Compiler compiler)
    : inferrer = compiler.typesTask,
      classWorld = compiler.world,
      backend = compiler.backend {
    numStringBoolType =
      new TypeMask.unionOf(<TypeMask>[numType, stringType, boolType],
                           classWorld);
  }

  Element locateSingleElement(TypeMask mask, Selector selector) {
    return mask.locateSingleElement(selector, mask, classWorld.compiler);
  }

  bool needsNoSuchMethodHandling(TypeMask mask, Selector selector) {
    return mask.needsNoSuchMethodHandling(selector, classWorld);
  }

  TypeMask getReceiverType(MethodElement method) {
    assert(method.isInstanceMember);
    return nonNullSubclass(method.enclosingClass);
  }

  TypeMask getParameterType(ParameterElement parameter) {
    return inferrer.getGuaranteedTypeOfElement(parameter);
  }

  TypeMask getReturnType(FunctionElement function) {
    return inferrer.getGuaranteedReturnTypeOfElement(function);
  }

  TypeMask getInvokeReturnType(Selector selector, TypeMask mask) {
    return inferrer.getGuaranteedTypeOfSelector(selector, mask);
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

  TypeMask nonNullExact(ClassElement element) {
    // The class world does not know about classes created by
    // closure conversion, so just treat those as a subtypes of Function.
    // TODO(asgerf): Maybe closure conversion should create a new ClassWorld?
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullExact(element.declaration, classWorld);
  }

  TypeMask nonNullSubclass(ClassElement element) {
    if (element.isClosure) return functionType;
    return new TypeMask.nonNullSubclass(element.declaration, classWorld);
  }

  bool isDefinitelyBool(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.containsOnlyBool(classWorld);
  }

  bool isDefinitelyNum(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.containsOnlyNum(classWorld);
  }

  bool isDefinitelyString(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.containsOnlyString(classWorld);
  }

  bool isDefinitelyNumStringBool(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return numStringBoolType.containsMask(t, classWorld);
  }

  bool isDefinitelyNotNumStringBool(TypeMask t) {
    return areDisjoint(t, numStringBoolType);
  }

  /// True if all values of [t] are either integers or not numbers at all.
  ///
  /// This does not imply that the value is an integer, since most other values
  /// such as null are also not a non-integer double.
  bool isDefinitelyNotNonIntegerDouble(TypeMask t) {
    // Even though int is a subclass of double in the JS type system, we can
    // still check this with disjointness, because [doubleType] is the *exact*
    // double class, so this excludes things that are known to be instances of a
    // more specific class.
    // We currently exploit that there are no subclasses of double that are
    // not integers (e.g. there is no UnsignedDouble class or whatever).
    return areDisjoint(t, doubleType);
  }

  bool isDefinitelyInt(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(backend.jsIntClass, classWorld);
  }

  bool isDefinitelyNativeList(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(backend.jsArrayClass, classWorld);
  }

  bool isDefinitelyMutableNativeList(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(backend.jsMutableArrayClass, classWorld);
  }

  bool isDefinitelyFixedNativeList(TypeMask t, {bool allowNull: false}) {
    if (!allowNull && t.isNullable) return false;
    return t.satisfies(backend.jsFixedArrayClass, classWorld);
  }

  bool areDisjoint(TypeMask leftType, TypeMask rightType) {
    TypeMask intersection = leftType.intersection(rightType, classWorld);
    return intersection.isEmpty && !intersection.isNullable;
  }

  AbstractBool isSubtypeOf(TypeMask value,
                           types.DartType type,
                           {bool allowNull}) {
    assert(allowNull != null);
    if (type is types.DynamicType) {
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

  /// Returns whether [type] is one of the falsy values: false, 0, -0, NaN,
  /// the empty string, or null.
  AbstractBool boolify(TypeMask type) {
    if (isDefinitelyNotNumStringBool(type) && !type.isNullable) {
      return AbstractBool.True;
    }
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
  bool isDefinitelyBool(AbstractValue value, {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyBool(value.type, allowNull: allowNull);
  }

  /// True if all members of this value are numbers.
  bool isDefinitelyNum(AbstractValue value, {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyNum(value.type, allowNull: allowNull);
  }

  /// True if all members of this value are strings.
  bool isDefinitelyString(AbstractValue value, {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyString(value.type, allowNull: allowNull);
  }

  /// True if all members of this value are numbers, strings, or booleans.
  bool isDefinitelyNumStringBool(AbstractValue value, {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyNumStringBool(value.type, allowNull: allowNull);
  }

  /// True if this value cannot be a string, number, or boolean.
  bool isDefinitelyNotNumStringBool(AbstractValue value) {
    return value.isNothing ||
      typeSystem.isDefinitelyNotNumStringBool(value.type);
  }

  /// True if this value cannot be a non-integer double.
  ///
  /// In other words, if true is returned, and the value is a number, then
  /// it is a whole number and is not NaN, Infinity, or minus Infinity.
  bool isDefinitelyNotNonIntegerDouble(AbstractValue value) {
    return value.isNothing ||
      value.isConstant && !value.constant.isDouble ||
      typeSystem.isDefinitelyNotNonIntegerDouble(value.type);
  }

  bool isDefinitelyInt(AbstractValue value,
                       {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyInt(value.type, allowNull: allowNull);
  }

  bool isDefinitelyNativeList(AbstractValue value,
                              {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyNativeList(value.type, allowNull: allowNull);
  }

  bool isDefinitelyMutableNativeList(AbstractValue value,
                                     {bool allowNull: false}) {
    return value.isNothing ||
         typeSystem.isDefinitelyMutableNativeList(value.type,
                                                  allowNull: allowNull);
  }

  bool isDefinitelyFixedNativeList(AbstractValue value,
                                   {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyFixedNativeList(value.type,
                                               allowNull: allowNull);
  }

  /// Returns whether the given [value] is an instance of [type].
  ///
  /// Since [value] and [type] are not always known, [AbstractBool.Maybe] is
  /// returned if the answer is not known.
  ///
  /// [AbstractBool.Nothing] is returned if [value] is nothing.
  ///
  /// If [allowNull] is true, `null` is considered an instance of anything,
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
      if (type == dartTypes.coreTypes.intType) {
        return constantSystem.isInt(value.constant)
          ? AbstractBool.True
          : AbstractBool.False;
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
  ///
  /// This method returns `null` if a good result could not be found. In that
  /// case, it is best to fall back on interprocedural type information.
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
    return null; // TODO(asgerf): Look up type?
  }

  /// Returns the possible results of applying [operator] to [left], [right],
  /// assuming the operation does not throw.
  ///
  /// Because we do not explicitly track thrown values, we currently use the
  /// convention that constant values are returned from this method only
  /// if the operation is known not to throw.
  ///
  /// This method returns `null` if a good result could not be found. In that
  /// case, it is best to fall back on interprocedural type information.
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
    // TODO(asgerf): Handle remaining operators and the UIntXX types.
    switch (operator.kind) {
      case BinaryOperatorKind.ADD:
      case BinaryOperatorKind.SUB:
      case BinaryOperatorKind.MUL:
        if (isDefinitelyInt(left) && isDefinitelyInt(right)) {
          return nonConstant(typeSystem.intType);
        }
        return null;

      default:
        return null; // The caller will use return type from type inference.
    }
  }

  AbstractValue stringConstant(String value) {
    return constant(new StringConstantValue(new DartString.literal(value)));
  }

  AbstractValue stringify(AbstractValue value) {
    if (value.isNothing) return nothing;
    if (value.isNonConst) return nonConstant(typeSystem.stringType);
    ConstantValue constantValue = value.constant;
    if (constantValue is StringConstantValue) {
      return value;
    } else if (constantValue is PrimitiveConstantValue) {
      // Note: The primitiveValue for a StringConstantValue is not suitable
      // for toString() use since it is a DartString. But the other subclasses
      // returns an unwrapped Dart value we can safely convert to a string.
      return stringConstant(constantValue.primitiveValue.toString());
    } else {
      return nonConstant(typeSystem.stringType);
    }
  }

  /// Returns whether [value] is one of the falsy values: false, 0, -0, NaN,
  /// the empty string, or null.
  AbstractBool boolify(AbstractValue value) {
    if (value.isNothing) return AbstractBool.Nothing;
    if (value.isConstant) {
      ConstantValue constantValue = value.constant;
      if (isFalsyConstant(constantValue)) {
        return AbstractBool.False;
      } else {
        return AbstractBool.True;
      }
    }
    return typeSystem.boolify(value.type);
  }

  /// The possible return types of a method that may be targeted by
  /// [typedSelector]. If the given selector is not a [TypedSelector], any
  /// reachable method matching the selector may be targeted.
  AbstractValue getInvokeReturnType(Selector selector, TypeMask mask) {
    return nonConstant(typeSystem.getInvokeReturnType(selector, mask));
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

  final dart2js.Compiler _compiler;
  // The constant system is used for evaluation of expressions with constant
  // arguments.
  final ConstantPropagationLattice _lattice;
  final dart2js.InternalErrorFunction _internalError;
  final Map<Definition, AbstractValue> _values = <Definition, AbstractValue>{};

  TypePropagator(dart2js.Compiler compiler)
      : _compiler = compiler,
        _internalError = compiler.internalError,
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
        _compiler,
        _lattice,
        analyzer,
        replacements,
        _internalError);
    transformer.transform(root);
  }

  getType(Node node) => _values[node];
}

final Map<String, BuiltinOperator> NumBinaryBuiltins =
  const <String, BuiltinOperator>{
    '+':  BuiltinOperator.NumAdd,
    '-':  BuiltinOperator.NumSubtract,
    '*':  BuiltinOperator.NumMultiply,
    '&':  BuiltinOperator.NumAnd,
    '|':  BuiltinOperator.NumOr,
    '^':  BuiltinOperator.NumXor,
    '<':  BuiltinOperator.NumLt,
    '<=': BuiltinOperator.NumLe,
    '>':  BuiltinOperator.NumGt,
    '>=': BuiltinOperator.NumGe
};

/**
 * Uses the information from a preceding analysis pass in order to perform the
 * actual transformations on the CPS graph.
 */
class TransformingVisitor extends LeafVisitor {
  final TypePropagationVisitor analyzer;
  final Map<Expression, ConstantValue> replacements;
  final ConstantPropagationLattice lattice;
  final dart2js.Compiler compiler;

  JavaScriptBackend get backend => compiler.backend;
  TypeMaskSystem get typeSystem => lattice.typeSystem;
  types.DartTypes get dartTypes => lattice.dartTypes;
  Map<Node, AbstractValue> get values => analyzer.values;

  final dart2js.InternalErrorFunction internalError;

  final List<Node> stack = <Node>[];

  TransformingVisitor(this.compiler,
                      this.lattice,
                      this.analyzer,
                      this.replacements,
                      this.internalError);

  void transform(FunctionDefinition root) {
    push(root.body);
    while (stack.isNotEmpty) {
      visit(stack.removeLast());
    }
  }

  void push(Node node) {
    assert(node != null);
    stack.add(node);
  }

  void pushAll(Iterable<Node> nodes) {
    nodes.forEach(push);
  }

  /************************* INTERIOR EXPRESSIONS *************************/
  //
  // These return nothing, and must push recursive children on the stack.

  void visitLetCont(LetCont node) {
    pushAll(node.continuations);
    push(node.body);
  }

  void visitLetHandler(LetHandler node) {
    push(node.handler);
    push(node.body);
  }

  void visitLetMutable(LetMutable node) {
    visit(node.variable);
    push(node.body);
  }

  void visitLetPrim(LetPrim node) {
    AbstractValue value = getValue(node.primitive);
    if (node.primitive is! Constant && value.isConstant) {
      // If the value is a known constant, compile it as a constant.
      Constant newPrim = makeConstantPrimitive(value.constant);
      newPrim.substituteFor(node.primitive);
      RemovalVisitor.remove(node.primitive);
      node.primitive = newPrim;
      newPrim.parent = node;
    } else {
      Primitive newPrim = visit(node.primitive);
      if (newPrim != null) {
        newPrim.substituteFor(node.primitive);
        RemovalVisitor.remove(node.primitive);
        node.primitive = newPrim;
        newPrim.parent = node;
        reanalyze(newPrim);
      }
      if (node.primitive.hasNoUses && node.primitive.isSafeForElimination) {
        // Remove unused primitives before entering the body.
        // This would also be done by shrinking reductions, but usage analyses
        // such as isAlwaysBoolified are more precise without the dead uses, so
        // we prefer to remove them early.
        RemovalVisitor.remove(node.primitive);
        node.parent.body = node.body;
        node.body.parent = node.parent;
      }
    }
    push(node.body);
  }

  void visitContinuation(Continuation node) {
    if (node.isReturnContinuation) return;
    // Process the continuation body.
    // Note that the continuation body may have changed since the continuation
    // was put on the stack (e.g. [visitInvokeContinuation] may do this).
    push(node.body);
  }

  /************************* TRANSFORMATION HELPERS *************************/

  /// Sets parent pointers and computes types for the given subtree.
  void reanalyze(Node node) {
    new ParentVisitor().visit(node);
    analyzer.reanalyzeSubtree(node);
  }

  /// Removes the entire subtree of [node] and inserts [replacement].
  ///
  /// By default, all references in the [node] subtree are unlinked, and parent
  /// pointers in [replacement] are initialized and its types recomputed.
  ///
  /// If the caller needs to manually unlink the node, because some references
  /// were adopted by other nodes, it can be disabled by passing `false`
  /// as the [unlink] parameter.
  ///
  /// [replacement] must be "fresh", i.e. it must not contain significant parts
  /// of the original IR inside of it since the [ParentVisitor] will
  /// redundantly reprocess it.
  void replaceSubtree(Expression node, Expression replacement,
                      {bool unlink: true}) {
    InteriorNode parent = node.parent;
    parent.body = replacement;
    replacement.parent = parent;
    node.parent = null;
    if (unlink) {
      RemovalVisitor.remove(node);
    }
    reanalyze(replacement);
  }

  /// Inserts [insertedCode] before [node].
  ///
  /// [node] will end up in the hole of [insertedCode], and [insertedCode]
  /// will become rooted where [node] was.
  void insertBefore(Expression node, CpsFragment insertedCode) {
    if (insertedCode.isEmpty) return; // Nothing to do.
    assert(insertedCode.isOpen);
    InteriorNode parent = node.parent;
    InteriorNode context = insertedCode.context;

    parent.body = insertedCode.root;
    insertedCode.root.parent = parent;

    // We want to recompute the types for [insertedCode] without
    // traversing the entire subtree of [node]. Temporarily close the
    // term with a dummy node while recomputing types.
    context.body = new Unreachable();
    new ParentVisitor().visit(insertedCode.root);
    reanalyze(insertedCode.root);

    context.body = node;
    node.parent = context;
  }
  
  /// Binds [prim] before [node].
  void insertLetPrim(Expression node, Primitive prim) {
    InteriorNode parent = node.parent;
    LetPrim let = new LetPrim(prim);
    parent.body = let;
    let.body = node;
    node.parent = let;
    let.parent = parent;
  }

  /// Make a constant primitive for [constant] and set its entry in [values].
  Constant makeConstantPrimitive(ConstantValue constant) {
    Constant primitive = new Constant(constant);
    values[primitive] = new AbstractValue.constantValue(constant,
        typeSystem.getTypeOf(constant));
    return primitive;
  }

  /// Builds `(LetPrim p (InvokeContinuation k p))`.
  ///
  /// No parent pointers are set.
  LetPrim makeLetPrimInvoke(Primitive primitive, Continuation continuation) {
    assert(continuation.parameters.length == 1);

    LetPrim letPrim = new LetPrim(primitive);
    InvokeContinuation invoke =
        new InvokeContinuation(continuation, <Primitive>[primitive]);
    letPrim.body = invoke;
    values[primitive] = values[continuation.parameters.single];
    primitive.hint = continuation.parameters.single.hint;

    return letPrim;
  }

  /************************* TAIL EXPRESSIONS *************************/

  // A branch can be eliminated and replaced by an invocation if only one of
  // the possible continuations is reachable. Removal often leads to both dead
  // primitives (the condition variable) and dead continuations (the unreachable
  // branch), which are both removed by the shrinking reductions pass.
  //
  // (Branch (IsTrue true) k0 k1) -> (InvokeContinuation k0)
  void visitBranch(Branch node) {
    Continuation trueCont = node.trueContinuation.definition;
    Continuation falseCont = node.falseContinuation.definition;
    IsTrue conditionNode = node.condition;
    Primitive condition = conditionNode.value.definition;

    AbstractValue conditionValue = getValue(condition);
    AbstractBool boolifiedValue = lattice.boolify(conditionValue);

    if (boolifiedValue == AbstractBool.True) {
      InvokeContinuation invoke = new InvokeContinuation(trueCont, []);
      replaceSubtree(node, invoke);
      push(invoke);
      return;
    }
    if (boolifiedValue == AbstractBool.False) {
      InvokeContinuation invoke = new InvokeContinuation(falseCont, []);
      replaceSubtree(node, invoke);
      push(invoke);
      return;
    }

    if (condition is ApplyBuiltinOperator &&
        condition.operator == BuiltinOperator.LooseEq) {
      Primitive leftArg = condition.arguments[0].definition;
      Primitive rightArg = condition.arguments[1].definition;
      AbstractValue left = getValue(leftArg);
      AbstractValue right = getValue(rightArg);
      if (right.isNullConstant &&
          lattice.isDefinitelyNotNumStringBool(left)) {
        // Rewrite:
        //   if (x == null) S1 else S2
        //     =>
        //   if (x) S2 else S1   (note the swapped branches)
        Branch branch = new Branch(new IsTrue(leftArg), falseCont, trueCont);
        replaceSubtree(node, branch);
        return;
      } else if (left.isNullConstant &&
                 lattice.isDefinitelyNotNumStringBool(right)) {
        Branch branch = new Branch(new IsTrue(rightArg), falseCont, trueCont);
        replaceSubtree(node, branch);
        return;
      }
    }
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    // Inline the single-use continuations. These are often introduced when
    // specializing an invocation node. These would also be inlined by a later
    // pass, but doing it here helps simplify pattern matching code, since the
    // effective definition of a primitive can then be found without going
    // through redundant InvokeContinuations.
    Continuation cont = node.continuation.definition;
    if (cont.hasExactlyOneUse &&
        !cont.isReturnContinuation &&
        !cont.isRecursive &&
        !node.isEscapingTry) {
      for (int i = 0; i < node.arguments.length; ++i) {
        node.arguments[i].definition.useElementAsHint(cont.parameters[i].hint);
        node.arguments[i].definition.substituteFor(cont.parameters[i]);
        node.arguments[i].unlink();
      }
      node.continuation.unlink();
      InteriorNode parent = node.parent;
      Expression body = cont.body;
      parent.body = body;
      body.parent = parent;
      cont.body = new Unreachable();
      cont.body.parent = cont;
      push(body);
    }
  }


  /************************* CALL EXPRESSIONS *************************/

  /// Replaces [node] with a more specialized instruction, if possible.
  ///
  /// Returns `true` if the node was replaced.
  bool specializeOperatorCall(InvokeMethod node) {
    Continuation cont = node.continuation.definition;
    bool replaceWithBinary(BuiltinOperator operator,
                           Primitive left,
                           Primitive right) {
      Primitive prim =
          new ApplyBuiltinOperator(operator, <Primitive>[left, right],
                                   node.sourceInformation);
      LetPrim let = makeLetPrimInvoke(prim, cont);
      replaceSubtree(node, let);
      push(let);
      return true; // So returning early is more convenient.
    }

    if (node.selector.isOperator && node.arguments.length == 2) {
      // The operators we specialize are are intercepted calls, so the operands
      // are in the argument list.
      Primitive leftArg = node.arguments[0].definition;
      Primitive rightArg = node.arguments[1].definition;
      AbstractValue left = getValue(leftArg);
      AbstractValue right = getValue(rightArg);

      if (node.selector.name == '==') {
        // Equality is special due to its treatment of null values and the
        // fact that Dart-null corresponds to both JS-null and JS-undefined.
        // Please see documentation for IsFalsy, StrictEq, and LooseEq.
        if (left.isNullConstant || right.isNullConstant) {
          return replaceWithBinary(BuiltinOperator.LooseEq, leftArg, rightArg);
        }
        // Comparison of numbers, strings, and booleans.
        if (lattice.isDefinitelyNumStringBool(left, allowNull: true) &&
            lattice.isDefinitelyNumStringBool(right, allowNull: true) &&
            !(left.isNullable && right.isNullable)) {
          return replaceWithBinary(BuiltinOperator.StrictEq, leftArg, rightArg);
        }
        if (lattice.isDefinitelyNum(left, allowNull: true) &&
            lattice.isDefinitelyNum(right, allowNull: true)) {
          return replaceWithBinary(BuiltinOperator.LooseEq, leftArg, rightArg);
        }
        if (lattice.isDefinitelyString(left, allowNull: true) &&
            lattice.isDefinitelyString(right, allowNull: true)) {
          return replaceWithBinary(BuiltinOperator.LooseEq, leftArg, rightArg);
        }
        if (lattice.isDefinitelyBool(left, allowNull: true) &&
            lattice.isDefinitelyBool(right, allowNull: true)) {
          return replaceWithBinary(BuiltinOperator.LooseEq, leftArg, rightArg);
        }
      } else {
        // Try to insert a numeric operator.
        if (lattice.isDefinitelyNum(left, allowNull: false) &&
            lattice.isDefinitelyNum(right, allowNull: false)) {
          BuiltinOperator operator = NumBinaryBuiltins[node.selector.name];
          if (operator != null) {
            return replaceWithBinary(operator, leftArg, rightArg);
          }
        }
        else if (lattice.isDefinitelyString(left, allowNull: false) &&
                 lattice.isDefinitelyString(right, allowNull: false)) {
          if (node.selector.name == '+') {
            return replaceWithBinary(BuiltinOperator.StringConcatenate,
                                     leftArg, rightArg);
          }
        }
      }
    }
    // We should only get here if the node was not specialized.
    assert(node.parent != null);
    return false;
  }

  bool isInterceptedSelector(Selector selector) {
    return backend.isInterceptedSelector(selector);
  }

  Primitive getDartReceiver(InvokeMethod node) {
    if (isInterceptedSelector(node.selector)) {
      return node.arguments[0].definition;
    } else {
      return node.receiver.definition;
    }
  }

  Primitive getDartArgument(InvokeMethod node, int n) {
    if (isInterceptedSelector(node.selector)) {
      return node.arguments[n+1].definition;
    } else {
      return node.arguments[n].definition;
    }
  }

  /// If [node] is a getter or setter invocation, tries to replace the
  /// invocation with a direct access to a field.
  ///
  /// Returns `true` if the node was replaced.
  bool specializeFieldAccess(InvokeMethod node) {
    if (!node.selector.isGetter && !node.selector.isSetter) return false;
    AbstractValue receiver = getValue(getDartReceiver(node));
    Element target =
        typeSystem.locateSingleElement(receiver.type, node.selector);
    if (target is! FieldElement) return false;
    // TODO(asgerf): Inlining native fields will make some tests pass for the
    // wrong reason, so for testing reasons avoid inlining them.
    if (target.isNative) return false;
    Continuation cont = node.continuation.definition;
    if (node.selector.isGetter) {
      GetField get = new GetField(getDartReceiver(node), target);
      LetPrim let = makeLetPrimInvoke(get, cont);
      replaceSubtree(node, let);
      push(let);
      return true;
    } else {
      if (target.isFinal) return false;
      assert(cont.parameters.single.hasNoUses);
      cont.parameters.clear();
      CpsFragment cps = new CpsFragment(node.sourceInformation);
      cps.letPrim(new SetField(getDartReceiver(node),
                               target,
                               getDartArgument(node, 0)));
      cps.invokeContinuation(cont);
      replaceSubtree(node, cps.result);
      push(cps.result);
      return true;
    }
  }

  /// Create a check that throws if [index] is not a valid index on [list].
  ///
  /// This function assumes that [index] is an integer.
  ///
  /// Returns a CPS fragment whose context is the branch where no error
  /// was thrown.
  CpsFragment makeBoundsCheck(Primitive list,
                              Primitive index,
                              SourceInformation sourceInfo) {
    CpsFragment cps = new CpsFragment(sourceInfo);
    Continuation fail = cps.letCont();
    Primitive isTooSmall = cps.applyBuiltin(
        BuiltinOperator.NumLt,
        <Primitive>[index, cps.makeZero()]);
    cps.ifTrue(isTooSmall).invokeContinuation(fail);
    Primitive isTooLarge = cps.applyBuiltin(
        BuiltinOperator.NumGe,
        <Primitive>[index, cps.letPrim(new GetLength(list))]);
    cps.ifTrue(isTooLarge).invokeContinuation(fail);
    cps.insideContinuation(fail).invokeStaticThrower(
        backend.getThrowIndexOutOfBoundsError(),
        <Primitive>[list, index]);
    return cps;
  }

  /// Create a check that throws if the length of [list] is not equal to
  /// [originalLength].
  ///
  /// Returns a CPS fragment whose context is the branch where no error
  /// was thrown.
  CpsFragment makeConcurrentModificationCheck(Primitive list,
                                              Primitive originalLength,
                                              SourceInformation sourceInfo) {
    CpsFragment cps = new CpsFragment(sourceInfo);
    Primitive lengthChanged = cps.applyBuiltin(
        BuiltinOperator.StrictNeq,
        <Primitive>[originalLength, cps.letPrim(new GetLength(list))]);
    cps.ifTrue(lengthChanged).invokeStaticThrower(
        backend.getThrowConcurrentModificationError(),
        <Primitive>[list]);
    return cps;
  }

  /// Counts number of index accesses on [list] and determines based on
  /// that number if we should try to inline them.
  ///
  /// This is a short-term solution to avoid inserting a lot of bounds checks,
  /// since there is currently no optimization for eliminating them.
  bool hasTooManyIndexAccesses(Primitive list) {
    int count = 0;
    for (Reference ref = list.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is InvokeMethod &&
          (use.selector.isIndex || use.selector.isIndexSet) &&
          getDartReceiver(use) == list) {
        ++count;
      } else if (use is GetIndex && use.object.definition == list) {
        ++count;
      } else if (use is SetIndex && use.object.definition == list) {
        ++count;
      }
      if (count > 2) return true;
    }
    return false;
  }

  /// Tries to replace [node] with one or more direct array access operations.
  ///
  /// Returns `true` if the node was replaced.
  bool specializeArrayAccess(InvokeMethod node) {
    Primitive list = getDartReceiver(node);
    AbstractValue listValue = getValue(list);
    // Ensure that the object is a native list or null.
    if (!lattice.isDefinitelyNativeList(listValue, allowNull: true)) {
      return false;
    }
    bool isFixedLength =
        lattice.isDefinitelyFixedNativeList(listValue, allowNull: true);
    bool isMutable =
        lattice.isDefinitelyMutableNativeList(listValue, allowNull: true);
    SourceInformation sourceInfo = node.sourceInformation;
    Continuation cont = node.continuation.definition;
    switch (node.selector.name) {
      case 'length':
        if (!node.selector.isGetter) return false;
        CpsFragment cps = new CpsFragment(sourceInfo);
        cps.invokeContinuation(cont, [cps.letPrim(new GetLength(list))]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case '[]':
        if (listValue.isNullable) return false;
        if (hasTooManyIndexAccesses(list)) return false;
        Primitive index = getDartArgument(node, 0);
        if (!lattice.isDefinitelyInt(getValue(index))) return false;
        CpsFragment cps = makeBoundsCheck(list, index, sourceInfo);
        GetIndex get = cps.letPrim(new GetIndex(list, index));
        cps.invokeContinuation(cont, [get]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case '[]=':
        if (listValue.isNullable) return false;
        if (hasTooManyIndexAccesses(list)) return false;
        Primitive index = getDartArgument(node, 0);
        Primitive value = getDartArgument(node, 1);
        if (!isMutable) return false;
        if (!lattice.isDefinitelyInt(getValue(index))) return false;
        CpsFragment cps = makeBoundsCheck(list, index, sourceInfo);
        cps.letPrim(new SetIndex(list, index, value));
        assert(cont.parameters.single.hasNoUses);
        cont.parameters.clear();
        cps.invokeContinuation(cont, []);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case 'forEach':
        if (!node.selector.isCall ||
            node.selector.positionalArgumentCount != 1 ||
            node.selector.namedArgumentCount != 0) {
          return false;
        }
        Primitive callback = getDartArgument(node, 0);
        // Rewrite to:
        //   var originalLength = array.length, i = 0;
        //   while (i < array.length) {
        //     callback(array[i]);
        //     if (array.length !== originalLength) throw;
        //     i = i + 1;
        //   }
        CpsFragment cps = new CpsFragment(sourceInfo);
        Primitive originalLength = cps.letPrim(new GetLength(list));
        originalLength.hint = new OriginalLengthEntity();

        // Build a loop.
        Parameter loopIndex = new Parameter(new LoopIndexEntity());
        Continuation loop = cps.beginLoop(
            <Parameter>[loopIndex], [cps.makeZero()]);

        // Check for loop exit.
        Primitive loopCondition = cps.applyBuiltin(
            BuiltinOperator.NumLt,
            [loopIndex, cps.letPrim(new GetLength(list))]);
        CpsFragment exitBranch = cps.ifFalse(loopCondition);
        exitBranch.invokeContinuation(cont, [exitBranch.makeNull()]);

        // Invoke the callback.
        Primitive arrayItem = cps.letPrim(new GetIndex(list, loopIndex));
        cps.invokeMethod(callback,
                         new Selector.callClosure(1),
                         getValue(callback).type,
                         [arrayItem]);

        // Check for concurrent modification, unless the list is fixed-length.
        if (!isFixedLength) {
          cps.append(
            makeConcurrentModificationCheck(list, originalLength, sourceInfo));
        }

        // Increment i and continue the loop.
        Primitive addOne = cps.applyBuiltin(
            BuiltinOperator.NumAdd,
            [loopIndex, cps.makeOne()]);
        cps.continueLoop(loop, [addOne]);

        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case 'iterator':
        if (!node.selector.isGetter) return false;
        Primitive iterator = cont.parameters.single;
        Continuation iteratorCont = cont;

        // Check that all uses of the iterator are 'moveNext' and 'current'.
        Selector moveNextSelector = new Selector.call('moveNext', null, 0);
        Selector currentSelector = new Selector.getter('current', null);
        assert(!isInterceptedSelector(moveNextSelector));
        assert(!isInterceptedSelector(currentSelector));
        for (Reference ref = iterator.firstRef; ref != null; ref = ref.next) {
          if (ref.parent is! InvokeMethod) return false;
          InvokeMethod use = ref.parent;
          if (ref != use.receiver) return false;
          if (use.selector != moveNextSelector &&
              use.selector != currentSelector) {
            return false;
          }
        }

        // Rewrite the iterator variable to 'current' and 'index' variables.
        Primitive originalLength = new GetLength(list);
        originalLength.hint = new OriginalLengthEntity();
        MutableVariable index = new MutableVariable(new LoopIndexEntity());
        MutableVariable current = new MutableVariable(new LoopItemEntity());

        // Rewrite all uses of the iterator.
        while (iterator.firstRef != null) {
          InvokeMethod use = iterator.firstRef.parent;
          Continuation useCont = use.continuation.definition;
          if (use.selector == currentSelector) {
            // Rewrite iterator.current to a use of the 'current' variable.
            Parameter result = useCont.parameters.single;
            if (result.hint != null) {
              // If 'current' was originally moved into a named variable, use
              // that variable name for the mutable variable.
              current.hint = result.hint;
            }
            LetPrim let = makeLetPrimInvoke(new GetMutable(current), useCont);
            replaceSubtree(use, let);
          } else {
            assert (use.selector == moveNextSelector);
            // Rewrite iterator.moveNext() to:
            //
            //   if (index < list.length) {
            //     current = null;
            //     continuation(false);
            //   } else {
            //     current = list[index];
            //     index = index + 1;
            //     continuation(true);
            //   }
            //
            // (The above does not show concurrent modification checks)

            // [cps] contains the code we insert instead of moveNext().
            CpsFragment cps = new CpsFragment(node.sourceInformation);

            // We must check for concurrent modification when calling moveNext.
            // When moveNext is used as a loop condition, the check prevents
            // `index < list.length` from becoming the loop condition, and we
            // get code like this:
            //
            //    while (true) {
            //      if (originalLength !== list.length) throw;
            //      if (index < list.length) {
            //        ...
            //      } else {
            //        ...
            //        break;
            //      }
            //    }
            //
            // For loops, we therefore check for concurrent modification before
            // invoking the recursive continuation, so the loop becomes:
            //
            //    if (originalLength !== list.length) throw;
            //    while (index < list.length) {
            //      ...
            //      if (originalLength !== list.length) throw;
            //    }
            //
            // The check before the loop can often be eliminated because it
            // follows immediately after the 'iterator' call.
            InteriorNode parent = getEffectiveParent(use);
            if (!isFixedLength) {
              if (parent is Continuation && parent.isRecursive) {
                // Check for concurrent modification before every invocation
                // of the continuation.
                // TODO(asgerf): Do this in a continuation so multiple
                //               continues can share the same code.
                for (Reference ref = parent.firstRef;
                     ref != null;
                     ref = ref.next) {
                  Expression invocationCaller = ref.parent;
                  if (getEffectiveParent(invocationCaller) == iteratorCont) {
                    // No need to check for concurrent modification immediately
                    // after the call to 'iterator'.
                    continue;
                  }
                  CpsFragment check = makeConcurrentModificationCheck(
                      list, originalLength, sourceInfo);
                  insertBefore(invocationCaller, check);
                }
              } else {
                cps.append(makeConcurrentModificationCheck(
                    list, originalLength, sourceInfo));
              }
            }

            // Check if there are more elements.
            Primitive hasMore = cps.applyBuiltin(
                BuiltinOperator.NumLt,
                [cps.getMutable(index), cps.letPrim(new GetLength(list))]);

            // Return false if there are no more.
            CpsFragment falseBranch = cps.ifFalse(hasMore);
            falseBranch
              ..setMutable(current, falseBranch.makeNull())
              ..invokeContinuation(useCont, [falseBranch.makeFalse()]);

            // Return true if there are more element.
            cps.setMutable(current,
                cps.letPrim(new GetIndex(list, cps.getMutable(index))));
            cps.setMutable(index, cps.applyBuiltin(
                BuiltinOperator.NumAdd,
                [cps.getMutable(index), cps.makeOne()]));
            cps.invokeContinuation(useCont, [cps.makeTrue()]);

            // Replace the moveNext() call. It will be visited later.
            replaceSubtree(use, cps.result);
          }
        }

        // Rewrite the iterator call to initializers for 'index' and 'current'.
        CpsFragment cps = new CpsFragment();
        cps.letMutable(index, cps.makeZero());
        cps.letMutable(current, cps.makeNull());
        cps.letPrim(originalLength);

        // Insert this fragment before the continuation body and replace the
        // iterator call with a call to the continuation without arguments.
        // For scoping reasons, the variables must be bound inside the
        // continuation, not at the invocation-site.
        iteratorCont.parameters.clear();
        insertBefore(iteratorCont.body, cps);
        InvokeContinuation invoke = new InvokeContinuation(iteratorCont, []);
        replaceSubtree(node, invoke);
        push(invoke);
        return true;

      // TODO(asgerf): Rewrite 'add', 'removeLast', ...

      default:
        return false;
    }
  }

  /// If [prim] is the parameter to a call continuation, returns the
  /// corresponding call.
  CallExpression getCallWithResult(Primitive prim) {
    if (prim is Parameter && prim.parent is Continuation) {
      Continuation cont = prim.parent;
      if (cont.hasExactlyOneUse) {
        Node use = cont.firstRef.parent;
        if (use is CallExpression) {
          return use;
        }
      }
    }
    return null;
  }

  /// Returns the first parent of [node] that is not a pure expression.
  InteriorNode getEffectiveParent(Expression node) {
    while (true) {
      Node parent = node.parent;
      if (parent is LetCont ||
          parent is LetPrim && parent.primitive.isSafeForReordering) {
        node = parent;
      } else {
        return parent;
      }
    }
  }

  /// Rewrites an invocation of a torn-off method into a method call directly
  /// on the receiver. For example:
  ///
  ///     obj.get$foo().call$<n>(<args>)
  ///       =>
  ///     obj.foo$<n>(<args>)
  ///
  bool specializeClosureCall(InvokeMethod node) {
    Selector call = node.selector;
    if (!call.isClosureCall) return false;

    assert(!isInterceptedSelector(call));
    assert(call.argumentCount == node.arguments.length);

    Primitive tearOff = node.receiver.definition;
    // Note: We don't know if [tearOff] is actually a tear-off.
    // We name variables based on the pattern we are trying to match.

    if (tearOff is GetStatic && tearOff.element.isFunction) {
      FunctionElement target = tearOff.element;
      FunctionSignature signature = target.functionSignature;

      // If the selector does not apply, don't bother (will throw at runtime).
      if (!call.signatureApplies(target)) return false;

      // If some optional arguments are missing, give up.
      // TODO(asgerf): Improve optimization by inserting default arguments.
      if (call.argumentCount != signature.parameterCount) return false;

      InvokeStatic invoke = new InvokeStatic.byReference(
          target,
          new Selector.fromElement(target),
          node.arguments,
          node.continuation,
          node.sourceInformation);
      node.receiver.unlink();
      replaceSubtree(node, invoke, unlink: false);
      push(invoke);
      return true;
    }
    CallExpression tearOffInvoke = getCallWithResult(tearOff);
    if (tearOffInvoke is InvokeMethod && tearOffInvoke.selector.isGetter) {
      Selector getter = tearOffInvoke.selector;

      // TODO(asgerf): Support torn-off intercepted methods.
      if (isInterceptedSelector(getter)) return false;

      Continuation getterCont = tearOffInvoke.continuation.definition;

      // TODO(asgerf): Support torn-off intercepted methods.
      if (isInterceptedSelector(getter)) return false;

      Primitive object = tearOffInvoke.receiver.definition;

      // Ensure that the object actually has a foo member, since we might
      // otherwise alter a noSuchMethod call.
      TypeMask type = getValue(object).type;
      if (typeSystem.needsNoSuchMethodHandling(type, getter)) return false;

      // Determine if the getter invocation can have side-effects.
      Element element = typeSystem.locateSingleElement(type, getter);
      bool isPure = element != null && !element.isGetter;

      // If there are multiple uses, we cannot eliminate the getter call and
      // therefore risk duplicating its side effects.
      if (!isPure && tearOff.hasMultipleUses) return false;

      // If the getter call is impure, we risk reordering side effects.
      if (!isPure && getEffectiveParent(node) != getterCont) {
        return false;
      }

      InvokeMethod invoke = new InvokeMethod.byReference(
        new Reference<Primitive>(object),
        new Selector(SelectorKind.CALL, getter.memberName, call.callStructure),
        type,
        node.arguments,
        node.continuation,
        node.sourceInformation);
      node.receiver.unlink();
      replaceSubtree(node, invoke, unlink: false);

      if (tearOff.hasNoUses) {
        // Eliminate the getter call if it has no more uses.
        // This cannot be delegated to other optimizations because we need to
        // avoid duplication of side effects.
        getterCont.parameters.clear();
        replaceSubtree(tearOffInvoke, new InvokeContinuation(getterCont, []));
      } else {
        // There are more uses, so we cannot eliminate the getter call. This
        // means we duplicated the effects of the getter call, but we should
        // only get here if the getter has no side effects.
        assert(isPure);
      }

      push(invoke);
      return true;
    }
    return false;
  }

  /// Side-effect free expressions with constant results are be replaced by:
  ///
  ///    (LetPrim p = constant (InvokeContinuation k p)).
  ///
  /// The new expression will be visited.
  ///
  /// Returns true if the node was replaced.
  bool constifyExpression(CallExpression node) {
    Continuation continuation = node.continuation.definition;
    ConstantValue constant = replacements[node];
    if (constant == null) return false;
    Constant primitive = makeConstantPrimitive(constant);
    LetPrim letPrim = makeLetPrimInvoke(primitive, continuation);
    replaceSubtree(node, letPrim);
    push(letPrim);
    return true;
  }

  void visitInvokeMethod(InvokeMethod node) {
    if (constifyExpression(node)) return;
    if (specializeOperatorCall(node)) return;
    if (specializeFieldAccess(node)) return;
    if (specializeArrayAccess(node)) return;
    if (specializeClosureCall(node)) return;

    AbstractValue receiver = getValue(node.receiver.definition);
    node.receiverIsNotNull = receiver.isDefinitelyNotNull;
  }

  void visitTypeCast(TypeCast node) {
    Continuation cont = node.continuation.definition;

    AbstractValue value = getValue(node.value.definition);
    switch (lattice.isSubtypeOf(value, node.type, allowNull: true)) {
      case AbstractBool.Maybe:
      case AbstractBool.Nothing:
        break;

      case AbstractBool.True:
        // Cast always succeeds, replace it with InvokeContinuation.
        InvokeContinuation invoke =
            new InvokeContinuation(cont, <Primitive>[node.value.definition]);
        replaceSubtree(node, invoke);
        push(invoke);
        return;

      case AbstractBool.False:
        // Cast always fails, remove unreachable continuation body.
        replaceSubtree(cont.body, new Unreachable());
        break;
    }
  }

  /// Specialize calls to internal static methods.
  ///
  /// Returns true if the call was replaced.
  bool specializeInternalMethodCall(InvokeStatic node) {
    // TODO(asgerf): This is written to easily scale to more cases,
    //               either add more cases or clean up.
    Continuation cont = node.continuation.definition;
    Primitive arg(int n) => node.arguments[n].definition;
    AbstractValue argType(int n) => getValue(arg(n));
    if (node.target.library.isInternalLibrary) {
      switch(node.target.name) {
        case InternalMethod.Stringify:
          if (lattice.isDefinitelyString(argType(0))) {
            InvokeContinuation invoke =
                new InvokeContinuation(cont, <Primitive>[arg(0)]);
            replaceSubtree(node, invoke);
            push(invoke);
            return true;
          }
          break;
      }
    }
    return false;
  }

  void visitInvokeStatic(InvokeStatic node) {
    if (constifyExpression(node)) return;
    if (specializeInternalMethodCall(node)) return;
  }

  AbstractValue getValue(Primitive primitive) {
    AbstractValue value = values[primitive];
    return value == null ? new AbstractValue.nothing() : value;
  }


  /*************************** PRIMITIVES **************************/
  //
  // The visit method for a primitive may optionally return a new
  // primitive. If non-null, the surrounding LetPrim will substitute it
  // and bind the new primitive instead.
  //

  void visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    DartString getString(AbstractValue value) {
      StringConstantValue constant = value.constant;
      return constant.primitiveValue;
    }
    switch (node.operator) {
      case BuiltinOperator.StringConcatenate:
        // Concatenate consecutive constants.
        bool argumentsWereRemoved = false;
        int i = 0;
        while (i < node.arguments.length - 1) {
          int startOfSequence = i;
          AbstractValue firstValue = getValue(node.arguments[i++].definition);
          if (!firstValue.isConstant) continue;
          AbstractValue secondValue = getValue(node.arguments[i++].definition);
          if (!secondValue.isConstant) continue;

          DartString string =
              new ConsDartString(getString(firstValue), getString(secondValue));

          // We found a sequence of at least two constants.
          // Look for the end of the sequence.
          while (i < node.arguments.length) {
            AbstractValue value = getValue(node.arguments[i].definition);
            if (!value.isConstant) break;
            string = new ConsDartString(string, getString(value));
            ++i;
          }
          Constant prim =
              makeConstantPrimitive(new StringConstantValue(string));
          insertLetPrim(node.parent, prim);
          for (int k = startOfSequence; k < i; ++k) {
            node.arguments[k].unlink();
            node.arguments[k] = null; // Remove the argument after the loop.
          }
          node.arguments[startOfSequence] = new Reference<Primitive>(prim);
          node.arguments[startOfSequence].parent = node;
          argumentsWereRemoved = true;
        }
        if (argumentsWereRemoved) {
          node.arguments.removeWhere((ref) => ref == null);
        }
        // TODO(asgerf): Rebalance nested StringConcats that arise from
        //               rewriting the + operator to StringConcat.
        break;

      case BuiltinOperator.Identical:
        Primitive left = node.arguments[0].definition;
        Primitive right = node.arguments[1].definition;
        AbstractValue leftValue = getValue(left);
        AbstractValue rightValue = getValue(right);
        // Replace identical(x, true) by x when x is known to be a boolean.
        if (lattice.isDefinitelyBool(leftValue) &&
            rightValue.isConstant &&
            rightValue.constant.isTrue) {
          left.substituteFor(node);
        }
        break;

      default:
    }
  }

  Primitive visitTypeTest(TypeTest node) {
    Primitive prim = node.value.definition;
    AbstractValue value = getValue(prim);
    if (node.type == dartTypes.coreTypes.intType) {
      // Compile as typeof x === 'number' && Math.floor(x) === x
      if (lattice.isDefinitelyNum(value, allowNull: true)) {
        // If value is null or a number, we can skip the typeof test.
        return new ApplyBuiltinOperator(
            BuiltinOperator.IsFloor,
            <Primitive>[prim, prim],
            node.sourceInformation);
      }
      if (lattice.isDefinitelyNotNonIntegerDouble(value)) {
        // If the value cannot be a non-integer double, but might not be a
        // number at all, we can skip the Math.floor test.
        return new ApplyBuiltinOperator(
            BuiltinOperator.IsNumber,
            <Primitive>[prim],
            node.sourceInformation);
      }
      return new ApplyBuiltinOperator(
          BuiltinOperator.IsNumberAndFloor,
          <Primitive>[prim, prim, prim],
          node.sourceInformation);
    }
    return null;
  }

  void visitGetField(GetField node) {
    node.objectIsNotNull = getValue(node.object.definition).isDefinitelyNotNull;
  }

  void visitGetLength(GetLength node) {
    node.objectIsNotNull = getValue(node.object.definition).isDefinitelyNotNull;
  }

  void visitInterceptor(Interceptor node) {
    // Filter out intercepted classes that do not match the input type.
    AbstractValue value = getValue(node.input.definition);
    node.interceptedClasses.retainWhere((ClassElement clazz) {
      if (clazz == typeSystem.jsNullClass) {
        return value.isNullable;
      } else {
        TypeMask classMask = typeSystem.nonNullSubclass(clazz);
        return !typeSystem.areDisjoint(value.type, classMask);
      }
    });
    // Remove the interceptor call if it can only return its input.
    if (node.interceptedClasses.isEmpty) {
      node.input.definition.substituteFor(node);
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
  final Set<Continuation> reachableContinuations = new Set<Continuation>();

  // The definition workset stores all definitions which need to be reprocessed
  // since their lattice value has changed.
  final List<Definition> defWorklist = <Definition>[];

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
    reachableContinuations.clear();

    // Initially, only the root node is reachable.
    push(root);

    iterateWorklist();
  }

  void reanalyzeSubtree(Node node) {
    new ResetAnalysisInfo(reachableContinuations, values).visit(node);
    push(node);
    iterateWorklist();
  }

  void iterateWorklist() {
    while (true) {
      if (nodeWorklist.isNotEmpty) {
        // Process a new reachable expression.
        Node node = nodeWorklist.removeLast();
        visit(node);
      } else if (defWorklist.isNotEmpty) {
        // Process all usages of a changed definition.
        Definition def = defWorklist.removeLast();

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

  /// Adds [node] to the worklist.
  void push(Node node) {
    nodeWorklist.add(node);
  }

  /// If the passed node is not yet reachable, mark it reachable and add it
  /// to the work list.
  void setReachable(Continuation cont) {
    if (reachableContinuations.add(cont)) {
      push(cont);
    }
  }

  /// Returns the lattice value corresponding to [node], defaulting to nothing.
  ///
  /// Never returns null.
  AbstractValue getValue(Definition node) {
    AbstractValue value = values[node];
    return (value == null) ? nothing : value;
  }

  /// Joins the passed lattice [updateValue] to the current value of [node],
  /// and adds it to the definition work set if it has changed and [node] is
  /// a definition.
  void setValue(Definition node, AbstractValue updateValue) {
    AbstractValue oldValue = getValue(node);
    AbstractValue newValue = lattice.join(oldValue, updateValue);
    if (oldValue == newValue) {
      return;
    }

    // Values may only move in the direction NOTHING -> CONSTANT -> NONCONST.
    assert(newValue.kind >= oldValue.kind);

    values[node] = newValue;
    defWorklist.add(node);
  }

  // -------------------------- Visitor overrides ------------------------------
  void visit(Node node) { node.accept(this); }

  void visitFunctionDefinition(FunctionDefinition node) {
    if (node.thisParameter != null) {
      setValue(node.thisParameter,
               nonConstant(typeSystem.getReceiverType(node.element)));
    }
    node.parameters.forEach(visit);
    push(node.body);
  }

  void visitLetPrim(LetPrim node) {
    visit(node.primitive); // No reason to delay visits to primitives.
    push(node.body);
  }

  void visitLetCont(LetCont node) {
    // The continuation is only marked as reachable on use.
    push(node.body);
  }

  void visitLetHandler(LetHandler node) {
    push(node.body);
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
    push(node.body);
  }

  void visitInvokeStatic(InvokeStatic node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    assert(cont.parameters.length == 1);
    Parameter returnValue = cont.parameters[0];

    /// Sets the value of the target continuation parameter, and possibly
    /// try to replace the whole invocation with a constant.
    void setResult(AbstractValue updateValue, {bool canReplace: false}) {
      setValue(returnValue, updateValue);
      if (canReplace && updateValue.isConstant) {
        replacements[node] = updateValue.constant;
      } else {
        // A previous iteration might have tried to replace this.
        replacements.remove(node);
      }
    }

    if (node.target.library.isInternalLibrary) {
      switch (node.target.name) {
        case InternalMethod.Stringify:
          AbstractValue argValue = getValue(node.arguments[0].definition);
          setResult(lattice.stringify(argValue), canReplace: true);
          return;
      }
    }

    TypeMask returnType = typeSystem.getReturnType(node.target);
    setResult(nonConstant(returnType));
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

    AbstractValue receiver = getValue(node.receiver.definition);
    if (receiver.isNothing) {
      return;  // And come back later.
    }
    if (!node.selector.isOperator) {
      // TODO(jgruber): Handle known methods on constants such as String.length.
      setResult(lattice.getInvokeReturnType(node.selector, node.mask));
      return;
    }

    // Calculate the resulting constant if possible.
    // Operators are intercepted, so the operands are in the argument list.
    AbstractValue result;
    String opname = node.selector.name;
    if (node.arguments.length == 1) {
      AbstractValue argument = getValue(node.arguments[0].definition);
      // Unary operator.
      if (opname == "unary-") {
        opname = "-";
      }
      UnaryOperator operator = UnaryOperator.parse(opname);
      result = lattice.unaryOp(operator, argument);
    } else if (node.arguments.length == 2) {
      // Binary operator.
      AbstractValue left = getValue(node.arguments[0].definition);
      AbstractValue right = getValue(node.arguments[1].definition);
      BinaryOperator operator = BinaryOperator.parse(opname);
      result = lattice.binaryOp(operator, left, right);
    }

    // Update value of the continuation parameter. Again, this is effectively
    // a phi.
    if (result == null) {
      setResult(lattice.getInvokeReturnType(node.selector, node.mask));
    } else {
      setResult(result, canReplace: true);
    }
  }

  void visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    switch (node.operator) {
      case BuiltinOperator.StringConcatenate:
        DartString stringValue = const LiteralDartString('');
        for (Reference<Primitive> arg in node.arguments) {
          AbstractValue value = getValue(arg.definition);
          if (value.isNothing) {
            return; // And come back later
          } else if (value.isConstant &&
                     value.constant.isString &&
                     stringValue != null) {
            StringConstantValue constant = value.constant;
            stringValue =
                new ConsDartString(stringValue, constant.primitiveValue);
          } else {
            stringValue = null;
            break;
          }
        }
        if (stringValue == null) {
          setValue(node, nonConstant(typeSystem.stringType));
        } else {
          setValue(node, constantValue(new StringConstantValue(stringValue)));
        }
        break;

      case BuiltinOperator.Identical:
        AbstractValue leftConst = getValue(node.arguments[0].definition);
        AbstractValue rightConst = getValue(node.arguments[1].definition);
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
          return;
        } else if (leftValue.isPrimitive && rightValue.isPrimitive) {
          assert(leftConst.isConstant && rightConst.isConstant);
          PrimitiveConstantValue left = leftValue;
          PrimitiveConstantValue right = rightValue;
          ConstantValue result =
            new BoolConstantValue(left.primitiveValue == right.primitiveValue);
          setValue(node, constantValue(result, typeSystem.boolType));
        } else {
          setValue(node, nonConstant(typeSystem.boolType));
        }
        break;

      // TODO(asgerf): Implement constant propagation for builtins.
      case BuiltinOperator.NumAdd:
      case BuiltinOperator.NumSubtract:
      case BuiltinOperator.NumMultiply:
      case BuiltinOperator.NumAnd:
      case BuiltinOperator.NumOr:
      case BuiltinOperator.NumXor:
        AbstractValue left = getValue(node.arguments[0].definition);
        AbstractValue right = getValue(node.arguments[1].definition);
        if (lattice.isDefinitelyInt(left) && lattice.isDefinitelyInt(right)) {
          setValue(node, nonConstant(typeSystem.intType));
        } else {
          setValue(node, nonConstant(typeSystem.numType));
        }
        break;

      case BuiltinOperator.NumLt:
      case BuiltinOperator.NumLe:
      case BuiltinOperator.NumGt:
      case BuiltinOperator.NumGe:
      case BuiltinOperator.StrictEq:
      case BuiltinOperator.StrictNeq:
      case BuiltinOperator.LooseEq:
      case BuiltinOperator.LooseNeq:
      case BuiltinOperator.IsFalsy:
      case BuiltinOperator.IsNumber:
      case BuiltinOperator.IsNotNumber:
      case BuiltinOperator.IsFloor:
      case BuiltinOperator.IsNumberAndFloor:
        setValue(node, nonConstant(typeSystem.boolType));
        break;
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

  void visitThrow(Throw node) {
  }

  void visitRethrow(Rethrow node) {
  }

  void visitUnreachable(Unreachable node) {
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

  void visitSetMutable(SetMutable node) {
    setValue(node.variable.definition, getValue(node.value.definition));
  }

  void visitLiteralList(LiteralList node) {
    // Constant lists are translated into (Constant ListConstant(...)) IR nodes,
    // and thus LiteralList nodes are NonConst.
    setValue(node, nonConstant(typeSystem.mutableNativeListType));
  }

  void visitLiteralMap(LiteralMap node) {
    // Constant maps are translated into (Constant MapConstant(...)) IR nodes,
    // and thus LiteralMap nodes are NonConst.
    setValue(node, nonConstant(typeSystem.mapType));
  }

  void visitConstant(Constant node) {
    ConstantValue value = node.value;
    if (value.isDummy || !value.isConstant) {
      // TODO(asgerf): Explain how this happens and why we don't want them.
      setValue(node, nonConstant(typeSystem.getTypeOf(value)));
    } else {
      setValue(node, constantValue(value, typeSystem.getTypeOf(value)));
    }
  }

  void visitCreateFunction(CreateFunction node) {
    throw 'CreateFunction is not used';
  }

  void visitGetMutable(GetMutable node) {
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
      push(node.body);
    }
  }

  void visitGetStatic(GetStatic node) {
    if (node.element.isFunction) {
      setValue(node, nonConstant(typeSystem.functionType));
    } else {
      setValue(node, nonConstant(typeSystem.getFieldType(node.element)));
    }
  }

  void visitSetStatic(SetStatic node) {}

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

  void visitInterceptor(Interceptor node) {
    push(node.input.definition);
    AbstractValue value = getValue(node.input.definition);
    if (!value.isNothing) {
      setValue(node, nonConstant(typeSystem.nonNullType));
    }
  }

  void visitGetField(GetField node) {
    setValue(node, nonConstant(typeSystem.getFieldType(node.field)));
  }

  void visitSetField(SetField node) {}

  void visitCreateBox(CreateBox node) {
    setValue(node, nonConstant(typeSystem.nonNullType));
  }

  void visitCreateInstance(CreateInstance node) {
    setValue(node, nonConstant(typeSystem.nonNullExact(node.classElement.declaration)));
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

  @override
  visitForeignCode(ForeignCode node) {
    if (node.continuation != null) {
      Continuation continuation = node.continuation.definition;
      setReachable(continuation);

      assert(continuation.parameters.length == 1);
      Parameter returnValue = continuation.parameters.first;
      setValue(returnValue, nonConstant(node.type));
    }
  }

  @override
  void visitGetLength(GetLength node) {
    setValue(node, nonConstant(typeSystem.intType));
  }

  @override
  void visitGetIndex(GetIndex node) {
    setValue(node, nonConstant());
  }

  @override
  void visitSetIndex(SetIndex node) {
    setValue(node, nonConstant());
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
    assert(constant is! SyntheticConstantValue);
  }

  AbstractValue.nothing()
      : this._internal(NOTHING, null, new TypeMask.nonNullEmpty());

  AbstractValue.constantValue(ConstantValue constant, TypeMask type)
      : this._internal(CONSTANT, constant, type);

  factory AbstractValue.nonConstant(TypeMask type) {
    if (type.isEmpty) {
      if (type.isNullable)
        return new AbstractValue.constantValue(new NullConstantValue(), type);
      else
        return new AbstractValue.nothing();
    } else {
      return new AbstractValue._internal(NONCONST, null, type);
    }
  }

  bool get isNothing  => (kind == NOTHING);
  bool get isConstant => (kind == CONSTANT);
  bool get isNonConst => (kind == NONCONST);
  bool get isNullConstant => kind == CONSTANT && constant.isNull;

  bool get isNullable => kind != NOTHING && type.isNullable;
  bool get isDefinitelyNotNull => kind == NOTHING || !type.isNullable;

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
      case CONSTANT: return "Constant: ${constant.unparse()}: $type";
      case NONCONST: return "Non-constant: $type";
      default: assert(false);
    }
    return null;
  }
}

/// Enum-like class with the names of internal methods we care about.
abstract class InternalMethod {
  static const String Stringify = 'S';
}

/// Suggested name for a synthesized loop index.
class LoopIndexEntity extends Entity {
  String get name => 'i';
}

/// Suggested name for the current element of a list being iterated.
class LoopItemEntity extends Entity {
  String get name => 'current';
}

/// Suggested name for the original length of a list, for use in checks
/// for concurrent modification.
class OriginalLengthEntity extends Entity {
  String get name => 'length';
}

class ResetAnalysisInfo extends RecursiveVisitor {
  Set<Continuation> reachableContinuations;
  Map<Definition, AbstractValue> values;

  ResetAnalysisInfo(this.reachableContinuations, this.values);

  processContinuation(Continuation cont) {
    reachableContinuations.remove(cont);
    cont.parameters.forEach(values.remove);
  }

  processLetPrim(LetPrim node) {
    values.remove(node.primitive);
  }

  processLetMutable(LetMutable node) {
    values.remove(node.variable);
  }
}
