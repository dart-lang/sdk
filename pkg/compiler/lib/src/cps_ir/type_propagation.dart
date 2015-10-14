// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.cps_ir.type_propagation;

import 'optimizers.dart';

import '../closure.dart' show
    ClosureClassElement;
import '../common.dart';
import '../common/names.dart' show
    Identifiers,
    Selectors;
import '../compiler.dart' as dart2js show
    Compiler;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../dart_types.dart' as types;
import '../elements/elements.dart';
import '../io/source_information.dart' show
    SourceInformation;
import '../js_backend/js_backend.dart' show
    JavaScriptBackend;
import '../js_backend/codegen/task.dart' show
    CpsFunctionCompiler;
import '../resolution/access_semantics.dart';
import '../resolution/operators.dart';
import '../resolution/send_structure.dart';
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../universe/selector.dart' show
    Selector;
import '../world.dart' show World;
import 'cps_fragment.dart';
import 'cps_ir_nodes.dart';
import 'type_mask_system.dart';

class ConstantPropagationLattice {
  final TypeMaskSystem typeSystem;
  final ConstantSystem constantSystem;
  final types.DartTypes dartTypes;
  final AbstractValue anything;
  final AbstractValue nullValue;

  ConstantPropagationLattice(TypeMaskSystem typeSystem,
                             this.constantSystem,
                             this.dartTypes)
    : this.typeSystem = typeSystem,
      anything = new AbstractValue.nonConstant(typeSystem.dynamicType),
      nullValue = new AbstractValue.constantValue(
          new NullConstantValue(), new TypeMask.empty());

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

  bool isDefinitelyUint31(AbstractValue value,
                       {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyUint31(value.type, allowNull: allowNull);
  }

  bool isDefinitelyUint32(AbstractValue value,
                       {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyUint32(value.type, allowNull: allowNull);
  }

  bool isDefinitelyUint(AbstractValue value,
                       {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyUint(value.type, allowNull: allowNull);
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

  bool isDefinitelyExtendableNativeList(AbstractValue value,
                                        {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyExtendableNativeList(value.type,
                                                    allowNull: allowNull);
  }

  bool isDefinitelyIndexable(AbstractValue value, {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyIndexable(value.type, allowNull: allowNull);
  }

  /// Returns `true` if [value] represents an int value that must be in the
  /// inclusive range.
  bool isDefinitelyIntInRange(AbstractValue value, {int min, int max}) {
    if (value.isNothing) return true;
    if (!isDefinitelyInt(value)) return false;
    PrimitiveConstantValue constant = value.constant;
    if (constant == null) return false;
    if (!constant.isInt) return false;
    if (min != null && constant.primitiveValue < min) return false;
    if (max != null && constant.primitiveValue > max) return false;
    return true;
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
    switch (operator.kind) {
      case BinaryOperatorKind.ADD:
        return addSpecial(left, right);

      case BinaryOperatorKind.SUB:
        return subtractSpecial(left, right);

      case BinaryOperatorKind.MUL:
        return multiplySpecial(left, right);

      case BinaryOperatorKind.DIV:
        return divideSpecial(left, right);

      case BinaryOperatorKind.IDIV:
        return truncatingDivideSpecial(left, right);

      case BinaryOperatorKind.MOD:
        return moduloSpecial(left, right);

      case BinaryOperatorKind.EQ:
        return equalSpecial(left, right);

      case BinaryOperatorKind.AND:
        return andSpecial(left, right);

      case BinaryOperatorKind.OR:
        return orSpecial(left, right);

      case BinaryOperatorKind.XOR:
        return xorSpecial(left, right);

      case BinaryOperatorKind.SHL:
        return shiftLeftSpecial(left, right);

      case BinaryOperatorKind.SHR:
        return shiftRightSpecial(left, right);

      case BinaryOperatorKind.LT:
        return lessSpecial(left, right);

      case BinaryOperatorKind.LTEQ:
        return lessEqualSpecial(left, right);

      case BinaryOperatorKind.GT:
        return greaterSpecial(left, right);

      case BinaryOperatorKind.GTEQ:
        return greaterEqualSpecial(left, right);

      default:
        break;
    }

    if (left.isNothing || right.isNothing) {
      return nothing;
    }
    if (left.isConstant && right.isConstant) {
      BinaryOperation operation = constantSystem.lookupBinary(operator);
      ConstantValue result = operation.fold(left.constant, right.constant);
      if (result != null) return constant(result);
    }
    return null; // The caller will use return type from type inference.
  }

  AbstractValue foldBinary(BinaryOperation operation,
      AbstractValue left, AbstractValue right) {
    if (left.isNothing || right.isNothing) return nothing;
    if (left.isConstant && right.isConstant) {
      ConstantValue result = operation.fold(left.constant, right.constant);
      if (result != null) return constant(result);
    }
    return null;
  }

  AbstractValue closedOnInt(AbstractValue left, AbstractValue right) {
    if (isDefinitelyInt(left) && isDefinitelyInt(right)) {
      return nonConstant(typeSystem.intType);
    }
    return null;
  }

  AbstractValue closedOnUint(AbstractValue left, AbstractValue right) {
    if (isDefinitelyUint(left) && isDefinitelyUint(right)) {
      return nonConstant(typeSystem.uintType);
    }
    return null;
  }

  AbstractValue closedOnUint31(AbstractValue left, AbstractValue right) {
    if (isDefinitelyUint31(left) && isDefinitelyUint31(right)) {
      return nonConstant(typeSystem.uint31Type);
    }
    return null;
  }

  AbstractValue addSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.add, left, right);
    if (folded != null) return folded;
    if (isDefinitelyNum(left)) {
      if (isDefinitelyUint31(left) && isDefinitelyUint31(right)) {
        return nonConstant(typeSystem.uint32Type);
      }
      return closedOnUint(left, right) ?? closedOnInt(left, right);
    }
    return null;
  }

  AbstractValue subtractSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.subtract, left, right);
    return folded ?? closedOnInt(left, right);
  }

  AbstractValue multiplySpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.multiply, left, right);
    return folded ?? closedOnUint(left, right) ?? closedOnInt(left, right);
  }

  AbstractValue divideSpecial(AbstractValue left, AbstractValue right) {
    return foldBinary(constantSystem.divide, left, right);
  }

  AbstractValue truncatingDivideSpecial(
      AbstractValue left, AbstractValue right) {
    AbstractValue folded =
        foldBinary(constantSystem.truncatingDivide, left, right);
    if (folded != null) return folded;
    if (isDefinitelyNum(left)) {
      if (isDefinitelyUint32(left) && isDefinitelyIntInRange(right, min: 2)) {
        return nonConstant(typeSystem.uint31Type);
      }
      if (isDefinitelyUint(right)) {
        // `0` will be an exception, other values will shrink the result.
        if (isDefinitelyUint31(left)) return nonConstant(typeSystem.uint31Type);
        if (isDefinitelyUint32(left)) return nonConstant(typeSystem.uint32Type);
        if (isDefinitelyUint(left)) return nonConstant(typeSystem.uintType);
      }
      return nonConstant(typeSystem.intType);
    }
    return null;
  }

  AbstractValue moduloSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.modulo, left, right);
    return folded ?? closedOnUint(left, right) ?? closedOnInt(left, right);
  }

  AbstractValue remainderSpecial(AbstractValue left, AbstractValue right) {
    if (left.isNothing || right.isNothing) return nothing;
    AbstractValue folded = null;  // Remainder not in constant system.
    return folded ?? closedOnUint(left, right) ?? closedOnInt(left, right);
  }

  AbstractValue equalSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.equal, left, right);
    if (folded != null) return folded;
    bool behavesLikeIdentity =
        isDefinitelyNumStringBool(left, allowNull: true) ||
        right.isNullConstant;
    if (behavesLikeIdentity &&
        typeSystem.areDisjoint(left.type, right.type)) {
      return constant(new FalseConstantValue());
    }
    return null;
  }

  AbstractValue andSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.bitAnd, left, right);
    if (folded != null) return folded;
    if (isDefinitelyNum(left)) {
      if (isDefinitelyUint31(left) || isDefinitelyUint31(right)) {
        // Either 31-bit argument will truncate the other.
        return nonConstant(typeSystem.uint31Type);
      }
    }
    return null;
  }

  AbstractValue orSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.bitOr, left, right);
    return folded ?? closedOnUint31(left, right);
  }

  AbstractValue xorSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.bitXor, left, right);
    return folded ?? closedOnUint31(left, right);
  }

  AbstractValue shiftLeftSpecial(AbstractValue left, AbstractValue right) {
    return foldBinary(constantSystem.shiftLeft, left, right);
  }

  AbstractValue shiftRightSpecial(AbstractValue left, AbstractValue right) {
    AbstractValue folded = foldBinary(constantSystem.shiftRight, left, right);
    if (folded != null) return folded;
    if (isDefinitelyUint31(left)) {
      return nonConstant(typeSystem.uint31Type);
    } else if (isDefinitelyUint32(left)) {
      if (isDefinitelyIntInRange(right, min: 1, max: 31)) {
        // A zero will be shifted into the 'sign' bit.
        return nonConstant(typeSystem.uint31Type);
      }
      return nonConstant(typeSystem.uint32Type);
    }
    return null;
  }

  AbstractValue lessSpecial(AbstractValue left, AbstractValue right) {
    return foldBinary(constantSystem.less, left, right);
  }

  AbstractValue lessEqualSpecial(AbstractValue left, AbstractValue right) {
    return foldBinary(constantSystem.lessEqual, left, right);
  }

  AbstractValue greaterSpecial(AbstractValue left, AbstractValue right) {
    return foldBinary(constantSystem.greater, left, right);
  }

  AbstractValue greaterEqualSpecial(AbstractValue left, AbstractValue right) {
    return foldBinary(constantSystem.greaterEqual, left, right);
  }


  AbstractValue stringConstant(String value) {
    return constant(new StringConstantValue(new ast.DartString.literal(value)));
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

  /// Returns whether [value] is the value `true`.
  AbstractBool strictBoolify(AbstractValue value) {
    if (value.isNothing) return AbstractBool.Nothing;
    if (value.isConstant) {
      return value.constant.isTrue ? AbstractBool.True : AbstractBool.False;
    }
    return typeSystem.strictBoolify(value.type);
  }

  /// The possible return types of a method that may be targeted by
  /// [typedSelector]. If the given selector is not a [TypedSelector], any
  /// reachable method matching the selector may be targeted.
  AbstractValue getInvokeReturnType(Selector selector, TypeMask mask) {
    return fromMask(typeSystem.getInvokeReturnType(selector, mask));
  }

  AbstractValue fromMask(TypeMask mask) {
    ConstantValue constantValue = typeSystem.getConstantOf(mask);
    if (constantValue != null) return constant(constantValue, mask);
    return nonConstant(mask);
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
  final CpsFunctionCompiler _functionCompiler;
  final ConstantPropagationLattice _lattice;
  final InternalErrorFunction _internalError;
  final Map<Variable, ConstantValue> _values = <Variable, ConstantValue>{};
  final TypeMaskSystem _typeSystem;

  TypePropagator(dart2js.Compiler compiler,
                 TypeMaskSystem typeSystem,
                 this._functionCompiler)
      : _compiler = compiler,
        _internalError = compiler.reporter.internalError,
        _typeSystem = typeSystem,
        _lattice = new ConstantPropagationLattice(
            typeSystem,
            compiler.backend.constantSystem,
            compiler.types);

  @override
  void rewrite(FunctionDefinition root) {
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
        _functionCompiler,
        _lattice,
        analyzer,
        replacements,
        _internalError);
    transformer.transform(root);
  }
}

final Map<String, BuiltinOperator> NumBinaryBuiltins =
  const <String, BuiltinOperator>{
    '+':  BuiltinOperator.NumAdd,
    '-':  BuiltinOperator.NumSubtract,
    '*':  BuiltinOperator.NumMultiply,
    '/':  BuiltinOperator.NumDivide,
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
class TransformingVisitor extends DeepRecursiveVisitor {
  final TypePropagationVisitor analyzer;
  final Map<Expression, ConstantValue> replacements;
  final ConstantPropagationLattice lattice;
  final dart2js.Compiler compiler;
  final CpsFunctionCompiler functionCompiler;

  JavaScriptBackend get backend => compiler.backend;
  TypeMaskSystem get typeSystem => lattice.typeSystem;
  types.DartTypes get dartTypes => lattice.dartTypes;
  Map<Variable, ConstantValue> get values => analyzer.values;

  final InternalErrorFunction internalError;

  final List<Node> stack = <Node>[];

  TransformingVisitor(this.compiler,
                      this.functionCompiler,
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
    if (node.primitive is! Constant &&
        node.primitive is! Refinement &&
        node.primitive.isSafeForElimination &&
        value.isConstant) {
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
    if (!analyzer.reachableContinuations.contains(node)) {
      replaceSubtree(node.body, new Unreachable());
    }
    // Process the continuation body.
    // Note that the continuation body may have changed since the continuation
    // was put on the stack (e.g. [visitInvokeContinuation] may do this).
    push(node.body);
  }

  /************************* TRANSFORMATION HELPERS *************************/

  /// Sets parent pointers and computes types for the given subtree.
  void reanalyze(Node node) {
    ParentVisitor.setParents(node);
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
    primitive.type = typeSystem.getTypeOf(constant);
    values[primitive] = constant;
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
    Primitive condition = node.condition.definition;
    AbstractValue conditionValue = getValue(condition);

    // Change to non-strict check if the condition is a boolean or null.
    if (lattice.isDefinitelyBool(conditionValue, allowNull: true)) {
      node.isStrictCheck = false;
    }

    AbstractBool boolifiedValue = node.isStrictCheck
        ? lattice.strictBoolify(conditionValue)
        : lattice.boolify(conditionValue);

    if (boolifiedValue == AbstractBool.True) {
      replaceSubtree(falseCont.body, new Unreachable());
      InvokeContinuation invoke = new InvokeContinuation(trueCont, []);
      replaceSubtree(node, invoke);
      push(invoke);
      return;
    }
    if (boolifiedValue == AbstractBool.False) {
      replaceSubtree(trueCont.body, new Unreachable());
      InvokeContinuation invoke = new InvokeContinuation(falseCont, []);
      replaceSubtree(node, invoke);
      push(invoke);
      return;
    }

    if (condition is ApplyBuiltinOperator &&
        (condition.operator == BuiltinOperator.LooseEq ||
         condition.operator == BuiltinOperator.StrictEq)) {
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
        Branch branch = new Branch.loose(leftArg, falseCont, trueCont);
        replaceSubtree(node, branch);
        return;
      } else if (left.isNullConstant &&
                 lattice.isDefinitelyNotNumStringBool(right)) {
        Branch branch = new Branch.loose(rightArg, falseCont, trueCont);
        replaceSubtree(node, branch);
        return;
      } else if (right.isTrueConstant &&
                 lattice.isDefinitelyBool(left, allowNull: true)) {
        // Rewrite:
        //   if (x == true) S1 else S2
        //     =>
        //   if (x) S1 else S2
        Branch branch = new Branch.loose(leftArg, trueCont, falseCont);
        replaceSubtree(node, branch);
        return;
      } else if (left.isTrueConstant &&
                 lattice.isDefinitelyBool(right, allowNull: true)) {
        Branch branch = new Branch.loose(rightArg, trueCont, falseCont);
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

  /// Returns the possible targets of [selector] when invoked on a receiver
  /// of type [receiverType].
  Iterable<Element> getAllTargets(TypeMask receiverType, Selector selector) {
    return compiler.world.allFunctions.filter(selector, receiverType);
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
      Primitive leftArg = getDartReceiver(node);
      Primitive rightArg = getDartArgument(node, 0);
      AbstractValue left = getValue(leftArg);
      AbstractValue right = getValue(rightArg);

      String opname = node.selector.name;
      if (opname == '==') {
        // Equality is special due to its treatment of null values and the
        // fact that Dart-null corresponds to both JS-null and JS-undefined.
        // Please see documentation for IsFalsy, StrictEq, and LooseEq.
        if (left.isNullConstant || right.isNullConstant) {
          return replaceWithBinary(BuiltinOperator.Identical,
                                   leftArg, rightArg);
        }
        // There are several implementations of == that behave like identical.
        // Specialize it if we definitely call one of those.
        bool behavesLikeIdentical = true;
        for (Element target in getAllTargets(left.type, node.selector)) {
          ClassElement clazz = target.enclosingClass.declaration;
          if (clazz != compiler.world.objectClass &&
              clazz != backend.jsInterceptorClass &&
              clazz != backend.jsNullClass) {
            behavesLikeIdentical = false;
            break;
          }
        }
        if (behavesLikeIdentical) {
          return replaceWithBinary(BuiltinOperator.Identical,
                                   leftArg, rightArg);
        }
      } else {
        if (lattice.isDefinitelyNum(left, allowNull: false) &&
            lattice.isDefinitelyNum(right, allowNull: false)) {
          // Try to insert a numeric operator.
          BuiltinOperator operator = NumBinaryBuiltins[opname];
          if (operator != null) {
            return replaceWithBinary(operator, leftArg, rightArg);
          }
          // Shift operators are not in [NumBinaryBuiltins] because Dart shifts
          // behave different to JS shifts, especially in the handling of the
          // shift count.
          // Try to insert a shift-left operator.
          if (opname == '<<' &&
              lattice.isDefinitelyInt(left) &&
              lattice.isDefinitelyIntInRange(right, min: 0, max: 31)) {
            return replaceWithBinary(BuiltinOperator.NumShl, leftArg, rightArg);
          }
          // Try to insert a shift-right operator. JavaScript's right shift is
          // consistent with Dart's only for left operands in the unsigned
          // 32-bit range.
          if (opname == '>>' &&
              lattice.isDefinitelyUint32(left) &&
              lattice.isDefinitelyIntInRange(right, min: 0, max: 31)) {
            return replaceWithBinary(BuiltinOperator.NumShr, leftArg, rightArg);
          }
          // Try to use remainder for '%'. Both operands must be non-negative
          // and the divisor must be non-zero.
          if (opname == '%' &&
              lattice.isDefinitelyUint(left) &&
              lattice.isDefinitelyUint(right) &&
              lattice.isDefinitelyIntInRange(right, min: 1)) {
            return replaceWithBinary(
                BuiltinOperator.NumRemainder, leftArg, rightArg);
          }

          if (opname == '~/' &&
              lattice.isDefinitelyUint32(left) &&
              lattice.isDefinitelyIntInRange(right, min: 2)) {
            return replaceWithBinary(
                BuiltinOperator.NumTruncatingDivideToSigned32,
                leftArg, rightArg);
          }
        }
        if (lattice.isDefinitelyString(left, allowNull: false) &&
            lattice.isDefinitelyString(right, allowNull: false) &&
            opname == '+') {
          return replaceWithBinary(BuiltinOperator.StringConcatenate,
                                   leftArg, rightArg);
        }
      }
    }
    if (node.selector.isCall) {
      String name = node.selector.name;
      Primitive receiver = getDartReceiver(node);
      AbstractValue receiverValue = getValue(receiver);
      if (name == 'remainder') {
        if (node.arguments.length == 2) {
          Primitive arg = getDartArgument(node, 0);
          AbstractValue argValue = getValue(arg);
          if (lattice.isDefinitelyInt(receiverValue) &&
              lattice.isDefinitelyInt(argValue) &&
              isIntNotZero(argValue)) {
            return
                replaceWithBinary(BuiltinOperator.NumRemainder, receiver, arg);
          }
        }
      }
    }
    // We should only get here if the node was not specialized.
    assert(node.parent != null);
    return false;
  }

  /// Returns `true` if [value] represents an int value that cannot be zero.
  bool isIntNotZero(AbstractValue value) {
    return lattice.isDefinitelyIntInRange(value, min: 1) ||
        lattice.isDefinitelyIntInRange(value, max: -1);
  }

  bool isInterceptedSelector(Selector selector) {
    return backend.isInterceptedSelector(selector);
  }

  Primitive getDartReceiver(InvokeMethod node) {
    if (node.receiverIsIntercepted) {
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
    if (target.isNative || target.isJsInterop) return false;
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
    cps.ifTruthy(isTooSmall).invokeContinuation(fail);
    Primitive isTooLarge = cps.applyBuiltin(
        BuiltinOperator.NumGe,
        <Primitive>[index, cps.letPrim(new GetLength(list))]);
    cps.ifTruthy(isTooLarge).invokeContinuation(fail);
    cps.insideContinuation(fail).invokeStaticThrower(
        backend.helpers.throwIndexOutOfBoundsError,
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
    cps.ifTruthy(lengthChanged).invokeStaticThrower(
        backend.helpers.throwConcurrentModificationError,
        <Primitive>[list]);
    return cps;
  }

  /// Tries to replace [node] with a direct `length` or index access.
  ///
  /// Returns `true` if the node was replaced.
  bool specializeIndexableAccess(InvokeMethod node) {
    Primitive receiver = getDartReceiver(node);
    AbstractValue receiverValue = getValue(receiver);
    if (!typeSystem.isDefinitelyIndexable(receiverValue.type,
            allowNull: true)) {
      return false;
    }
    SourceInformation sourceInfo = node.sourceInformation;
    Continuation cont = node.continuation.definition;
    switch (node.selector.name) {
      case 'length':
        if (!node.selector.isGetter) return false;
        CpsFragment cps = new CpsFragment(sourceInfo);
        cps.invokeContinuation(cont, [cps.letPrim(new GetLength(receiver))]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case '[]':
        Primitive index = getDartArgument(node, 0);
        if (!lattice.isDefinitelyInt(getValue(index))) return false;
        CpsFragment cps = makeBoundsCheck(receiver, index, sourceInfo);
        GetIndex get = cps.letPrim(new GetIndex(receiver, index));
        cps.invokeContinuation(cont, [get]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case '[]=':
        if (receiverValue.isNullable) return false;
        if (!typeSystem.isDefinitelyMutableIndexable(receiverValue.type)) {
          return false;
        }
        Primitive index = getDartArgument(node, 0);
        Primitive value = getDartArgument(node, 1);
        if (!lattice.isDefinitelyInt(getValue(index))) return false;
        CpsFragment cps = makeBoundsCheck(receiver, index, sourceInfo);
        cps.letPrim(new SetIndex(receiver, index, value));
        assert(cont.parameters.single.hasNoUses);
        cont.parameters.clear();
        cps.invokeContinuation(cont, []);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      default:
        return false;
    }
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
    bool isExtendable =
        lattice.isDefinitelyExtendableNativeList(listValue, allowNull: true);
    SourceInformation sourceInfo = node.sourceInformation;
    Continuation cont = node.continuation.definition;
    switch (node.selector.name) {
      case 'add':
        if (!node.selector.isCall ||
            node.selector.positionalArgumentCount != 1 ||
            node.selector.namedArgumentCount != 0) {
          return false;
        }
        if (!isExtendable) return false;
        Primitive addedItem = getDartArgument(node, 0);
        CpsFragment cps = new CpsFragment(sourceInfo);
        cps.invokeBuiltin(BuiltinMethod.Push,
            list,
            <Primitive>[addedItem]);
        cps.invokeContinuation(cont, [cps.makeNull()]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case 'removeLast':
        if (!node.selector.isCall ||
            node.selector.argumentCount != 0) {
          return false;
        }
        if (!isExtendable) return false;
        CpsFragment cps = new CpsFragment(sourceInfo);
        Primitive length = cps.letPrim(new GetLength(list));
        Primitive isEmpty = cps.applyBuiltin(
            BuiltinOperator.StrictEq,
            [length, cps.makeZero()]);
        CpsFragment fail = cps.ifTruthy(isEmpty);
        fail.invokeStaticThrower(
            backend.helpers.throwIndexOutOfBoundsError,
            [list, fail.makeConstant(new IntConstantValue(-1))]);
        Primitive removedItem = cps.invokeBuiltin(BuiltinMethod.Pop,
            list,
            <Primitive>[]);
        cps.invokeContinuation(cont, [removedItem]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case 'addAll':
        if (!node.selector.isCall ||
            node.selector.argumentCount != 1) {
          return false;
        }
        if (!isExtendable) return false;
        Primitive addedList = getDartArgument(node, 0);
        // Rewrite addAll([x1, ..., xN]) to push(x1, ..., xN).
        // Ensure that the list is not mutated between creation and use.
        // We aim for the common case where this is the only use of the list,
        // which also guarantees that this list is not mutated before use.
        if (addedList is! LiteralList || !addedList.hasExactlyOneUse) {
          return false;
        }
        LiteralList addedLiteral = addedList;
        CpsFragment cps = new CpsFragment(sourceInfo);
        cps.invokeBuiltin(BuiltinMethod.Push,
            list,
            addedLiteral.values.map((ref) => ref.definition).toList());
        cps.invokeContinuation(cont, [cps.makeNull()]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case 'elementAt':
        if (!node.selector.isCall ||
            node.selector.positionalArgumentCount != 1 ||
            node.selector.namedArgumentCount != 0) {
          return false;
        }
        if (listValue.isNullable) return false;
        Primitive index = getDartArgument(node, 0);
        if (!lattice.isDefinitelyInt(getValue(index))) return false;
        CpsFragment cps = makeBoundsCheck(list, index, sourceInfo);
        GetIndex get = cps.letPrim(new GetIndex(list, index));
        cps.invokeContinuation(cont, [get]);
        replaceSubtree(node, cps.result);
        push(cps.result);
        return true;

      case 'forEach':
        Element element =
            compiler.world.locateSingleElement(node.selector, listValue.type);
        if (element == null ||
            !element.isFunction ||
            !node.selector.isCall) return false;
        assert(node.selector.positionalArgumentCount == 1);
        assert(node.selector.namedArgumentCount == 0);
        FunctionDefinition target = functionCompiler.compileToCpsIr(element);

        node.receiver.definition.substituteFor(target.thisParameter);
        for (int i = 0; i < node.arguments.length; ++i) {
          node.arguments[i].definition.substituteFor(target.parameters[i]);
        }
        node.continuation.definition.substituteFor(target.returnContinuation);

        replaceSubtree(node, target.body);
        push(target.body);
        return true;

      case 'iterator':
        if (!node.selector.isGetter) return false;
        Primitive iterator = cont.parameters.single;
        Continuation iteratorCont = cont;

        // Check that all uses of the iterator are 'moveNext' and 'current'.
        assert(!isInterceptedSelector(Selectors.moveNext));
        assert(!isInterceptedSelector(Selectors.current));
        for (Reference ref in iterator.effectiveUses) {
          if (ref.parent is! InvokeMethod) return false;
          InvokeMethod use = ref.parent;
          if (ref != use.receiver) return false;
          if (use.selector != Selectors.moveNext &&
              use.selector != Selectors.current) {
            return false;
          }
        }

        // Rewrite the iterator variable to 'current' and 'index' variables.
        Primitive originalLength = new GetLength(list);
        originalLength.hint = new OriginalLengthEntity();
        MutableVariable index = new MutableVariable(new LoopIndexEntity());
        MutableVariable current = new MutableVariable(new LoopItemEntity());

        // Rewrite all uses of the iterator.
        for (Reference ref in iterator.effectiveUses) {
          InvokeMethod use = ref.parent;
          Continuation useCont = use.continuation.definition;
          if (use.selector == Selectors.current) {
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
            assert (use.selector == Selectors.moveNext);
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
            CpsFragment falseBranch = cps.ifFalsy(hasMore);
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

        // All effective uses have been rewritten.
        destroyRefinementsOfDeadPrimitive(iterator);

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
          parent is LetPrim && parent.primitive.isSafeForReordering ||
          parent is LetPrim && parent.primitive is Refinement) {
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

    Primitive tearOff = node.receiver.definition.effectiveDefinition;
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
      if (!isPure && tearOff.hasMultipleEffectiveUses) return false;

      // If the getter call is impure, we risk reordering side effects.
      if (!isPure && getEffectiveParent(node) != getterCont) {
        return false;
      }

      InvokeMethod invoke = new InvokeMethod.byReference(
        new Reference<Primitive>(object),
        new Selector.call(getter.memberName, call.callStructure),
        type,
        node.arguments,
        node.continuation,
        node.sourceInformation);
      node.receiver.unlink();
      replaceSubtree(node, invoke, unlink: false);

      if (tearOff.hasNoEffectiveUses) {
        // Eliminate the getter call if it has no more uses.
        // This cannot be delegated to other optimizations because we need to
        // avoid duplication of side effects.
        destroyRefinementsOfDeadPrimitive(tearOff);
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

  void destroyRefinementsOfDeadPrimitive(Primitive prim) {
    while (prim.firstRef != null) {
      Refinement refine = prim.firstRef.parent;
      destroyRefinementsOfDeadPrimitive(refine);
      LetPrim letPrim = refine.parent;
      InteriorNode parent = letPrim.parent;
      parent.body = letPrim.body;
      letPrim.body.parent = parent;
      prim.firstRef.unlink();
    }
  }

  /// Inlines a single-use closure if it leaves the closure object with only
  /// field accesses.  This is optimized later by [ScalarReplacer].
  bool specializeSingleUseClosureCall(InvokeMethod node) {
    Selector call = node.selector;
    if (!call.isClosureCall) return false;

    assert(!isInterceptedSelector(call));
    assert(call.argumentCount == node.arguments.length);

    Primitive receiver = node.receiver.definition;
    if (receiver is !CreateInstance) return false;
    CreateInstance createInstance = receiver;
    if (!createInstance.hasExactlyOneUse) return false;

    // Inline only closures. This avoids inlining the 'call' method of a class
    // that has many allocation sites.
    if (createInstance.classElement is !ClosureClassElement) return false;

    ClosureClassElement closureClassElement = createInstance.classElement;
    Element element = closureClassElement.localLookup(Identifiers.call);

    if (element == null || !element.isFunction) return false;
    FunctionElement functionElement = element;
    if (functionElement.asyncMarker != AsyncMarker.SYNC) return false;

    if (!call.signatureApplies(functionElement)) return false;
    // Inline only for exact match.
    // TODO(sra): Handle call with defaulted arguments.
    Selector targetSelector = new Selector.fromElement(functionElement);
    if (call.callStructure != targetSelector.callStructure) return false;

    // Don't inline if [target] contains try-catch or try-finally. JavaScript
    // engines typically do poor optimization of the entire function containing
    // the 'try'.
    if (functionElement.resolvedAst.elements.containsTryStatement) return false;

    FunctionDefinition target =
        functionCompiler.compileToCpsIr(functionElement);

    // Accesses to closed-over values are field access primitives.  We we don't
    // inline if there are other uses of 'this' since that could be an escape or
    // a recursive call.
    for (Reference ref = target.thisParameter.firstRef;
         ref != null;
         ref = ref.next) {
      Node use = ref.parent;
      if (use is GetField) continue;
      // Closures do not currently have writable fields, but closure conversion
      // could esily be changed to allocate some cells in a closure object.
      if (use is SetField && ref == use.object) continue;
      return false;
    }

    node.receiver.definition.substituteFor(target.thisParameter);
    for (int i = 0; i < node.arguments.length; ++i) {
      node.arguments[i].definition.substituteFor(target.parameters[i]);
    }
    node.continuation.definition.substituteFor(target.returnContinuation);

    replaceSubtree(node, target.body);
    push(target.body);
    return true;
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
    if (specializeIndexableAccess(node)) return;
    if (specializeArrayAccess(node)) return;
    if (specializeSingleUseClosureCall(node)) return;
    if (specializeClosureCall(node)) return;

    AbstractValue receiver = getValue(node.receiver.definition);

    if (node.receiverIsIntercepted &&
        node.receiver.definition.sameValue(node.arguments[0].definition)) {
      // The receiver and first argument are the same; that means we already
      // determined in visitInterceptor that we are targeting a non-interceptor.

      // Check if any of the possible targets depend on the extra receiver
      // argument. Mixins do this, and tear-offs always needs the extra receiver
      // argument because BoundClosure uses it for equality and hash code.
      // TODO(15933): Make automatically generated property extraction
      // closures work with the dummy receiver optimization.
      bool needsReceiver(Element target) {
        if (target is! FunctionElement) return false;
        FunctionElement function = target;
        return typeSystem.methodUsesReceiverArgument(function) ||
               node.selector.isGetter && !function.isGetter;
      }
      if (!getAllTargets(receiver.type, node.selector).any(needsReceiver)) {
        // Replace the extra receiver argument with a dummy value if the
        // target definitely does not use it.
        Constant dummy = makeConstantPrimitive(new IntConstantValue(0));
        insertLetPrim(node, dummy);
        node.arguments[0].changeTo(dummy);
        node.receiverIsIntercepted = false;
      }
    }
  }

  void visitTypeCast(TypeCast node) {
    Continuation cont = node.continuation.definition;

    AbstractValue value = getValue(node.value.definition);
    switch (lattice.isSubtypeOf(value, node.dartType, allowNull: true)) {
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
    } else if (node.target.library.isDartCore) {
      switch(node.target.name) {
        case CorelibMethod.Identical:
          if (node.arguments.length == 2) {
            return replaceWithBinary(BuiltinOperator.Identical, arg(0), arg(1));
          }
          break;
      }
    }
    return false;
  }

  /// Try to inline static invocations.
  ///
  /// Performs the inlining and returns true if the call was inlined.  Inlining
  /// uses a fixed heuristic:
  ///
  /// * Inline functions with a single expression statement or return statement
  /// provided that the subexpression is an invocation of foreign code.
  bool inlineInvokeStatic(InvokeStatic node) {
    // The target might not have an AST, for example if it deferred.
    if (!node.target.hasNode) return false;

    // True if an expression is non-expansive, in the sense defined by this
    // predicate.
    bool isNonExpansive(ast.Expression expr) {
      if (expr is ast.LiteralNull ||
          expr is ast.LiteralBool ||
          expr is ast.LiteralInt ||
          expr is ast.LiteralDouble) {
        return true;
      }
      if (expr is ast.Send) {
        SendStructure structure =
            node.target.treeElements.getSendStructure(expr);
        if (structure is InvokeStructure) {
          // Calls to foreign functions.
          return structure.semantics.kind == AccessKind.TOPLEVEL_METHOD &&
              backend.isForeign(structure.semantics.element);
        } else if (structure is IsStructure || structure is IsNotStructure) {
          // is and is! checks on nonexpansive expressions.
          return isNonExpansive(expr.receiver);
        } else if (structure is EqualsStructure ||
            structure is NotEqualsStructure) {
          // == and != on nonexpansive expressions.
          return isNonExpansive(expr.receiver) &&
              isNonExpansive(expr.argumentsNode.nodes.head);
        } else if (structure is GetStructure) {
          // Parameters.
          return structure.semantics.kind == AccessKind.PARAMETER;
        }
      }
      return false;
    }

    ast.Statement body = node.target.node.body;
    bool shouldInline() {
      if (backend.annotations.noInline(node.target)) return false;
      if (node.target.resolvedAst.elements.containsTryStatement) return false;

      // Inline functions that are a single return statement, expression
      // statement, or block containing a return statement or expression
      // statement.
      if (body is ast.Return) {
        return isNonExpansive(body.expression);
      } else if (body is ast.ExpressionStatement) {
        return isNonExpansive(body.expression);
      } else if (body is ast.Block) {
        var link = body.statements.nodes;
        if (link.isNotEmpty && link.tail.isEmpty) {
          if (link.head is ast.Return) {
            return isNonExpansive(link.head.expression);
          } else if (link.head is ast.ExpressionStatement) {
            return isNonExpansive(link.head.expression);
          }
        }
      }
      return false;
    }

    if (!shouldInline()) return false;

    FunctionDefinition target = functionCompiler.compileToCpsIr(node.target);
    for (int i = 0; i < node.arguments.length; ++i) {
      node.arguments[i].definition.substituteFor(target.parameters[i]);
    }
    node.continuation.definition.substituteFor(target.returnContinuation);

    replaceSubtree(node, target.body);
    push(target.body);
    return true;
  }

  void visitInvokeStatic(InvokeStatic node) {
    if (constifyExpression(node)) return;
    if (specializeInternalMethodCall(node)) return;
    if (inlineInvokeStatic(node)) return;
  }

  AbstractValue getValue(Variable node) {
    ConstantValue constant = values[node];
    if (constant != null) {
      return new AbstractValue.constantValue(constant, node.type);
    }
    if (node.type != null) {
      return new AbstractValue.nonConstant(node.type);
    }
    return lattice.nothing;
  }


  /*************************** PRIMITIVES **************************/
  //
  // The visit method for a primitive may optionally return a new
  // primitive. If non-null, the surrounding LetPrim will substitute it
  // and bind the new primitive instead.
  //

  void visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    ast.DartString getString(AbstractValue value) {
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

          ast.DartString string =
              new ast.ConsDartString(getString(firstValue),
                                     getString(secondValue));

          // We found a sequence of at least two constants.
          // Look for the end of the sequence.
          while (i < node.arguments.length) {
            AbstractValue value = getValue(node.arguments[i].definition);
            if (!value.isConstant) break;
            string = new ast.ConsDartString(string, getString(value));
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
        Primitive leftArg = node.arguments[0].definition;
        Primitive rightArg = node.arguments[1].definition;
        AbstractValue left = getValue(leftArg);
        AbstractValue right = getValue(rightArg);
        if (lattice.isDefinitelyBool(left) &&
            right.isConstant &&
            right.constant.isTrue) {
          // Replace identical(x, true) by x when x is known to be a boolean.
          // Note that this is not safe if x is null, because the value might
          // not be used as a condition. A rule for [IsTrue] handles that case.
          leftArg.substituteFor(node);
        } else if (lattice.isDefinitelyBool(right) &&
            left.isConstant &&
            left.constant.isTrue) {
          rightArg.substituteFor(node);
        } else if (left.isNullConstant || right.isNullConstant) {
          // Use `==` for comparing against null, so JS undefined and JS null
          // are considered equal.
          node.operator = BuiltinOperator.LooseEq;
        } else if (!left.isNullable || !right.isNullable) {
          // If at most one operand can be Dart null, we can use `===`.
          // This is not safe when we might compare JS null and JS undefined.
          node.operator = BuiltinOperator.StrictEq;
        } else if (lattice.isDefinitelyNum(left, allowNull: true) &&
                   lattice.isDefinitelyNum(right, allowNull: true)) {
          // If both operands can be null, but otherwise are of the same type,
          // we can use `==` for comparison.
          // This is not safe e.g. for comparing strings against numbers.
          node.operator = BuiltinOperator.LooseEq;
        } else if (lattice.isDefinitelyString(left, allowNull: true) &&
                   lattice.isDefinitelyString(right, allowNull: true)) {
          node.operator = BuiltinOperator.LooseEq;
        } else if (lattice.isDefinitelyBool(left, allowNull: true) &&
                   lattice.isDefinitelyBool(right, allowNull: true)) {
          node.operator = BuiltinOperator.LooseEq;
        }
        break;

      default:
    }
  }

  void visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    if (node.method == BuiltinMethod.Push) {
      // Convert consecutive pushes into a single push.
      InteriorNode parent = getEffectiveParent(node.parent);
      if (parent is LetPrim && parent.primitive is ApplyBuiltinMethod) {
        ApplyBuiltinMethod previous = parent.primitive;
        if (previous.method == BuiltinMethod.Push &&
            previous.receiver.definition.sameValue(node.receiver.definition)) {
          // We found two consecutive pushes.
          // Move all arguments from the first push onto the second one.
          List<Reference<Primitive>> arguments = previous.arguments;
          for (Reference ref in arguments) {
            ref.parent = node;
          }
          arguments.addAll(node.arguments);
          node.arguments = arguments;
          // Elimnate the old push.
          previous.receiver.unlink();
          assert(previous.hasNoUses);
          parent.parent.body = parent.body;
          parent.body.parent = parent.parent;
        }
      }
    }
  }

  Primitive visitTypeTest(TypeTest node) {
    Primitive prim = node.value.definition;

    Primitive unaryBuiltinOperator(BuiltinOperator operator) =>
        new ApplyBuiltinOperator(
            operator, <Primitive>[prim], node.sourceInformation);

    void unlinkInterceptor() {
      if (node.interceptor != null) {
        node.interceptor.unlink();
        node.interceptor = null;
      }
    }

    AbstractValue value = getValue(prim);
    types.DartType dartType = node.dartType;

    if (!(dartType.isInterfaceType && dartType.isRaw)) {
      // TODO(23685): Efficient function arity check.
      // TODO(sra): Pass interceptor to runtime subtype functions.
      unlinkInterceptor();
      return null;
    }

    if (dartType == dartTypes.coreTypes.intType) {
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
        return unaryBuiltinOperator(BuiltinOperator.IsNumber);
      }
      return new ApplyBuiltinOperator(
          BuiltinOperator.IsNumberAndFloor,
          <Primitive>[prim, prim, prim],
          node.sourceInformation);
    }
    if (node.dartType == dartTypes.coreTypes.numType ||
        node.dartType == dartTypes.coreTypes.doubleType) {
      return new ApplyBuiltinOperator(
          BuiltinOperator.IsNumber,
          <Primitive>[prim],
          node.sourceInformation);
    }

    AbstractBool isNullableSubtype =
        lattice.isSubtypeOf(value, node.dartType, allowNull: true);
    AbstractBool isNullPassingTest =
        lattice.isSubtypeOf(lattice.nullValue, node.dartType, allowNull: false);
    if (isNullableSubtype == AbstractBool.True &&
        isNullPassingTest == AbstractBool.False) {
      // Null is the only value not satisfying the type test.
      // Replace the type test with a null-check.
      // This has lower priority than the 'typeof'-based tests because
      // 'typeof' expressions might give the VM some more useful information.
      Primitive nullConst = makeConstantPrimitive(new NullConstantValue());
      insertLetPrim(node.parent, nullConst);
      return new ApplyBuiltinOperator(
          BuiltinOperator.LooseNeq,
          <Primitive>[prim, nullConst],
          node.sourceInformation);
    }

    if (dartType.element == functionCompiler.glue.jsFixedArrayClass) {
      // TODO(sra): Check input is restricted to JSArray.
      return unaryBuiltinOperator(BuiltinOperator.IsFixedLengthJSArray);
    }

    if (dartType.element == functionCompiler.glue.jsExtendableArrayClass) {
      // TODO(sra): Check input is restricted to JSArray.
      return unaryBuiltinOperator(BuiltinOperator.IsExtendableJSArray);
    }

    if (dartType.element == functionCompiler.glue.jsMutableArrayClass) {
      // TODO(sra): Check input is restricted to JSArray.
      return unaryBuiltinOperator(BuiltinOperator.IsModifiableJSArray);
    }

    if (dartType.element == functionCompiler.glue.jsUnmodifiableArrayClass) {
      // TODO(sra): Check input is restricted to JSArray.
      return unaryBuiltinOperator(BuiltinOperator.IsUnmodifiableJSArray);
    }

    if (dartType == dartTypes.coreTypes.stringType ||
        dartType == dartTypes.coreTypes.boolType) {
      // These types are recognized in tree_ir TypeOperator codegen.
      unlinkInterceptor();
      return null;
    }

    // TODO(sra): Propagate sourceInformation.
    // TODO(sra): If getInterceptor(x) === x or JSNull, rewrite
    //     getInterceptor(x).$isFoo ---> x != null && x.$isFoo
    return new TypeTestViaFlag(node.interceptor.definition, dartType);
  }

  Primitive visitTypeTestViaFlag(TypeTestViaFlag node) {
    return null;
  }

  Primitive visitInterceptor(Interceptor node) {
    AbstractValue value = getValue(node.input.definition);
    // If the exact class of the input is known, replace with a constant
    // or the input itself.
    ClassElement singleClass;
    if (lattice.isDefinitelyInt(value)) {
      // Classes like JSUInt31 and JSUInt32 do not exist at runtime, so ensure
      // all the int classes get mapped tor their runtime class.
      singleClass = backend.jsIntClass;
    } else if (lattice.isDefinitelyNativeList(value)) {
      // Ensure all the array subclasses get mapped to the array class.
      singleClass = backend.jsArrayClass;
    } else {
      singleClass = typeSystem.singleClass(value.type);
    }
    if (singleClass != null &&
        singleClass.isSubclassOf(backend.jsInterceptorClass)) {
      node.constantValue = new InterceptorConstantValue(singleClass.rawType);
    }
    // Filter out intercepted classes that do not match the input type.
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
    return null;
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
  final InternalErrorFunction internalError;

  TypeMaskSystem get typeSystem => lattice.typeSystem;

  JavaScriptBackend get backend => typeSystem.backend;

  World get classWorld => typeSystem.classWorld;

  AbstractValue get nothing => lattice.nothing;

  AbstractValue nonConstant([TypeMask type]) => lattice.nonConstant(type);

  AbstractValue constantValue(ConstantValue constant, [TypeMask type]) {
    return lattice.constant(constant, type);
  }

  // Stores the current lattice value for primitives and mutable variables.
  // Access through [getValue] and [setValue].
  final Map<Variable, ConstantValue> values;

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
  AbstractValue getValue(Variable node) {
    ConstantValue constant = values[node];
    if (constant != null) {
      return new AbstractValue.constantValue(constant, node.type);
    }
    if (node.type != null) {
      return new AbstractValue.nonConstant(node.type);
    }
    return lattice.nothing;
  }

  /// Joins the passed lattice [updateValue] to the current value of [node],
  /// and adds it to the definition work set if it has changed and [node] is
  /// a definition.
  void setValue(Variable node, AbstractValue updateValue) {
    AbstractValue oldValue = getValue(node);
    AbstractValue newValue = lattice.join(oldValue, updateValue);
    node.type = newValue.type; // Ensure type is initialized even if bottom.
    if (oldValue == newValue) {
      return;
    }

    // Values may only move in the direction NOTHING -> CONSTANT -> NONCONST.
    assert(newValue.kind >= oldValue.kind);

    values[node] = newValue.isConstant ? newValue.constant : null;
    defWorklist.add(node);
  }

  /// Updates the value of a [CallExpression]'s continuation parameter.
  void setResult(CallExpression call,
                 AbstractValue updateValue,
                 {bool canReplace: false}) {
    Continuation cont = call.continuation.definition;
    setValue(cont.parameters.single, updateValue);
    if (!updateValue.isNothing) {
      setReachable(cont);

      if (updateValue.isConstant && canReplace) {
        replacements[call] = updateValue.constant;
      } else {
        // A replacement might have been set in a previous iteration.
        replacements.remove(call);
      }
    }
  }

  bool isInterceptedSelector(Selector selector) {
    return backend.isInterceptedSelector(selector);
  }

  Primitive getDartReceiver(InvokeMethod node) {
    if (node.receiverIsIntercepted) {
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

  // -------------------------- Visitor overrides ------------------------------
  void visit(Node node) { node.accept(this); }

  void visitFunctionDefinition(FunctionDefinition node) {
    int firstActualParameter = 0;
    if (backend.isInterceptedMethod(node.element)) {
      if (typeSystem.methodUsesReceiverArgument(node.element)) {
        setValue(node.thisParameter, nonConstant(typeSystem.nonNullType));
        setValue(node.parameters[0],
                 nonConstant(typeSystem.getReceiverType(node.element)));
      } else {
        setValue(node.thisParameter,
              nonConstant(typeSystem.getReceiverType(node.element)));
        setValue(node.parameters[0], nonConstant());
      }
      firstActualParameter = 1;
    } else if (node.thisParameter != null) {
      setValue(node.thisParameter,
               nonConstant(typeSystem.getReceiverType(node.element)));
    }
    for (Parameter param in node.parameters.skip(firstActualParameter)) {
      // TODO(karlklose): remove reference to the element model.
      TypeMask type = param.hint is ParameterElement
          ? typeSystem.getParameterType(param.hint)
          : typeSystem.dynamicType;
      setValue(param, lattice.fromMask(type));
    }
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
    if (node.target.library != null && node.target.library.isInternalLibrary) {
      switch (node.target.name) {
        case InternalMethod.Stringify:
          AbstractValue argValue = getValue(node.arguments[0].definition);
          setResult(node, lattice.stringify(argValue), canReplace: true);
          return;
      }
    }

    TypeMask returnType = typeSystem.getReturnType(node.target);
    setResult(node, lattice.fromMask(returnType));
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    Continuation cont = node.continuation.definition;
    setReachable(cont);

    // Forward the constant status of all continuation invokes to the
    // continuation. Note that this is effectively a phi node in SSA terms.
    for (int i = 0; i < node.arguments.length; i++) {
      Primitive def = node.arguments[i].definition;
      AbstractValue cell = getValue(def);
      setValue(cont.parameters[i], cell);
    }
  }

  void visitInvokeMethod(InvokeMethod node) {
    AbstractValue receiver = getValue(node.receiver.definition);
    node.receiverIsNotNull = receiver.isDefinitelyNotNull;
    if (receiver.isNothing) {
      return;  // And come back later.
    }
    if (!node.selector.isOperator) {
      // TODO(jgruber): Handle known methods on constants such as String.length.
      setResult(node, lattice.getInvokeReturnType(node.selector, node.mask));
      return;
    }

    // Calculate the resulting constant if possible.
    AbstractValue result;
    String opname = node.selector.name;
    if (node.arguments.length == 1) {
      AbstractValue argument = getValue(getDartReceiver(node));
      // Unary operator.
      if (opname == "unary-") {
        opname = "-";
      }
      UnaryOperator operator = UnaryOperator.parse(opname);
      result = lattice.unaryOp(operator, argument);
    } else if (node.arguments.length == 2) {
      // Binary operator.
      AbstractValue left = getValue(getDartReceiver(node));
      AbstractValue right = getValue(getDartArgument(node, 0));
      BinaryOperator operator = BinaryOperator.parse(opname);
      result = lattice.binaryOp(operator, left, right);
    }

    // Update value of the continuation parameter. Again, this is effectively
    // a phi.
    if (result == null) {
      setResult(node, lattice.getInvokeReturnType(node.selector, node.mask));
    } else {
      setResult(node, result, canReplace: true);
    }
  }

  void visitApplyBuiltinOperator(ApplyBuiltinOperator node) {

    void binaryOp(
        AbstractValue operation(AbstractValue left, AbstractValue right),
        TypeMask defaultType) {
      AbstractValue left = getValue(node.arguments[0].definition);
      AbstractValue right = getValue(node.arguments[1].definition);
      setValue(node, operation(left, right) ?? nonConstant(defaultType));
    }

    void binaryNumOp(
        AbstractValue operation(AbstractValue left, AbstractValue right)) {
      binaryOp(operation, typeSystem.numType);
    }

    void binaryUint32Op(
        AbstractValue operation(AbstractValue left, AbstractValue right)) {
      binaryOp(operation, typeSystem.uint32Type);
    }

    void binaryBoolOp(
        AbstractValue operation(AbstractValue left, AbstractValue right)) {
      binaryOp(operation, typeSystem.boolType);
    }

    switch (node.operator) {
      case BuiltinOperator.StringConcatenate:
        ast.DartString stringValue = const ast.LiteralDartString('');
        for (Reference<Primitive> arg in node.arguments) {
          AbstractValue value = getValue(arg.definition);
          if (value.isNothing) {
            return; // And come back later
          } else if (value.isConstant &&
                     value.constant.isString &&
                     stringValue != null) {
            StringConstantValue constant = value.constant;
            stringValue =
                new ast.ConsDartString(stringValue, constant.primitiveValue);
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
      case BuiltinOperator.StrictEq:
      case BuiltinOperator.LooseEq:
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
          // Should this be constantSystem.identity.fold(left, right)?
          ConstantValue result =
            new BoolConstantValue(left.primitiveValue == right.primitiveValue);
          setValue(node, constantValue(result, typeSystem.boolType));
        } else {
          setValue(node, nonConstant(typeSystem.boolType));
        }
        break;

      case BuiltinOperator.NumAdd:
        binaryNumOp(lattice.addSpecial);
        break;

      case BuiltinOperator.NumSubtract:
        binaryNumOp(lattice.subtractSpecial);
        break;

      case BuiltinOperator.NumMultiply:
        binaryNumOp(lattice.multiplySpecial);
        break;

      case BuiltinOperator.NumDivide:
        binaryNumOp(lattice.divideSpecial);
        break;

      case BuiltinOperator.NumRemainder:
        binaryNumOp(lattice.remainderSpecial);
        break;

      case BuiltinOperator.NumTruncatingDivideToSigned32:
        binaryNumOp(lattice.truncatingDivideSpecial);
        break;

      case BuiltinOperator.NumAnd:
        binaryUint32Op(lattice.andSpecial);
        break;

      case BuiltinOperator.NumOr:
        binaryUint32Op(lattice.orSpecial);
        break;

      case BuiltinOperator.NumXor:
        binaryUint32Op(lattice.xorSpecial);
        break;

      case BuiltinOperator.NumShl:
        binaryUint32Op(lattice.shiftLeftSpecial);
        break;

      case BuiltinOperator.NumShr:
        binaryUint32Op(lattice.shiftRightSpecial);
        break;

      case BuiltinOperator.NumLt:
        binaryBoolOp(lattice.lessSpecial);
        break;

      case BuiltinOperator.NumLe:
        binaryBoolOp(lattice.lessEqualSpecial);
        break;

      case BuiltinOperator.NumGt:
        binaryBoolOp(lattice.greaterSpecial);
        break;

      case BuiltinOperator.NumGe:
        binaryBoolOp(lattice.greaterEqualSpecial);
        break;

      case BuiltinOperator.StrictNeq:
      case BuiltinOperator.LooseNeq:
      case BuiltinOperator.IsFalsy:
      case BuiltinOperator.IsNumber:
      case BuiltinOperator.IsNotNumber:
      case BuiltinOperator.IsFloor:
      case BuiltinOperator.IsNumberAndFloor:
        setValue(node, nonConstant(typeSystem.boolType));
        break;

      case BuiltinOperator.IsFixedLengthJSArray:
      case BuiltinOperator.IsExtendableJSArray:
      case BuiltinOperator.IsUnmodifiableJSArray:
      case BuiltinOperator.IsModifiableJSArray:
        setValue(node, nonConstant(typeSystem.boolType));
        break;
    }
  }

  void visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    AbstractValue receiver = getValue(node.receiver.definition);
    if (node.method == BuiltinMethod.Pop) {
      setValue(node, nonConstant(
          typeSystem.elementTypeOfIndexable(receiver.type)));
    } else {
      setValue(node, nonConstant());
    }
  }

  void visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    // TODO(karlklose): lookup the function and get ites return type.
    setResult(node, nonConstant());
  }

  void visitInvokeConstructor(InvokeConstructor node) {
    setResult(node, nonConstant(typeSystem.getReturnType(node.target)));
  }

  void visitThrow(Throw node) {
  }

  void visitRethrow(Rethrow node) {
  }

  void visitUnreachable(Unreachable node) {
  }

  void visitBranch(Branch node) {
    AbstractValue conditionCell = getValue(node.condition.definition);
    AbstractBool boolifiedValue = node.isStrictCheck
        ? lattice.strictBoolify(conditionCell)
        : lattice.boolify(conditionCell);
    switch (boolifiedValue) {
      case AbstractBool.Nothing:
        break;
      case AbstractBool.True:
        setReachable(node.trueContinuation.definition);
        break;
      case AbstractBool.False:
        setReachable(node.falseContinuation.definition);
        break;
      case AbstractBool.Maybe:
        setReachable(node.trueContinuation.definition);
        setReachable(node.falseContinuation.definition);
        break;
    }
  }

  void visitTypeTest(TypeTest node) {
    handleTypeTest(node, getValue(node.value.definition), node.dartType);
  }

  void visitTypeTestViaFlag(TypeTestViaFlag node) {
    // TODO(sra): We could see if we can find the value in the interceptor
    // expression. It would probably have no benefit - we only see
    // TypeTestViaFlag after rewriting TypeTest and the rewrite of TypeTest
    // would already have done the interesting optimizations.
    setValue(node, nonConstant(typeSystem.boolType));
  }

  void handleTypeTest(
      Primitive node, AbstractValue input, types.DartType dartType) {
    TypeMask boolType = typeSystem.boolType;
    switch(lattice.isSubtypeOf(input, dartType, allowNull: false)) {
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
    switch (lattice.isSubtypeOf(input, node.dartType, allowNull: true)) {
      case AbstractBool.Nothing:
        break; // And come back later.

      case AbstractBool.True:
        setReachable(cont);
        setValue(cont.parameters.single, input);
        break;

      case AbstractBool.False:
        break; // Cast fails. Continuation should remain unreachable.

      case AbstractBool.Maybe:
        setReachable(cont);
        // Narrow type of output to those that survive the cast.
        TypeMask type = input.type.intersection(
            typeSystem.subtypesOf(node.dartType),
            classWorld);
        setValue(cont.parameters.single, nonConstant(type));
        break;
    }
  }

  void visitSetMutable(SetMutable node) {
    setValue(node.variable.definition, getValue(node.value.definition));
  }

  void visitLiteralList(LiteralList node) {
    // Constant lists are translated into (Constant ListConstant(...)) IR nodes,
    // and thus LiteralList nodes are NonConst.
    setValue(node, nonConstant(typeSystem.extendableNativeListType));
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
  }

  void visitParameter(Parameter node) {
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
    setResult(node, nonConstant(typeSystem.getFieldType(node.element)));
  }

  void visitInterceptor(Interceptor node) {
    push(node.input.definition);
    AbstractValue value = getValue(node.input.definition);
    if (value.isNothing) {
      setValue(node, nothing);
    } else if (value.isNullable &&
        !node.interceptedClasses.contains(backend.jsNullClass)) {
      // If the input is null and null is not mapped to an interceptor then
      // null gets returned.
      // TODO(asgerf): Add the NullInterceptor when it enables us to
      //               propagate an assignment.
      setValue(node, nonConstant());
    } else {
      setValue(node, nonConstant(typeSystem.nonNullType));
    }
  }

  void visitGetField(GetField node) {
    node.objectIsNotNull = getValue(node.object.definition).isDefinitelyNotNull;
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
  void visitTypeExpression(TypeExpression node) {
    // TODO(karlklose): come up with a type marker for JS entities or switch to
    // real constants of type [Type].
    setValue(node, nonConstant());
  }

  void visitCreateInvocationMirror(CreateInvocationMirror node) {
    // TODO(asgerf): Expose [Invocation] type.
    setValue(node, nonConstant(typeSystem.nonNullType));
  }

  @override
  void visitForeignCode(ForeignCode node) {
    if (node.continuation != null) {
      setResult(node, nonConstant(node.type));
    }
  }

  @override
  void visitGetLength(GetLength node) {
    AbstractValue input = getValue(node.object.definition);
    node.objectIsNotNull = getValue(node.object.definition).isDefinitelyNotNull;
    int length = typeSystem.getContainerLength(input.type);
    if (length != null) {
      // TODO(asgerf): Constant-folding the length might degrade the VM's
      // own bounds-check elimination?
      setValue(node, constantValue(new IntConstantValue(length)));
    } else {
      setValue(node, nonConstant(typeSystem.intType));
    }
  }

  @override
  void visitGetIndex(GetIndex node) {
    AbstractValue input = getValue(node.object.definition);
    setValue(node, nonConstant(typeSystem.elementTypeOfIndexable(input.type)));
  }

  @override
  void visitSetIndex(SetIndex node) {
    setValue(node, nonConstant());
  }

  @override
  void visitAwait(Await node) {
    setResult(node, nonConstant());
  }

  @override
  visitYield(Yield node) {
    setReachable(node.continuation.definition);
  }

  @override
  void visitRefinement(Refinement node) {
    AbstractValue value = getValue(node.value.definition);
    if (value.isNothing ||
        typeSystem.areDisjoint(value.type, node.refineType)) {
      setValue(node, nothing);
    } else if (value.isConstant) {
      setValue(node, value);
    } else {
      setValue(node,
          nonConstant(value.type.intersection(node.refineType, classWorld)));
    }
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
  bool get isTrueConstant => kind == CONSTANT && constant.isTrue;

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

/// Enum-like class with the names of dart:core methods we care about.
abstract class CorelibMethod {
  static const String Identical = 'identical';
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

class ResetAnalysisInfo extends TrampolineRecursiveVisitor {
  Set<Continuation> reachableContinuations;
  Map<Variable, ConstantValue> values;

  ResetAnalysisInfo(this.reachableContinuations, this.values);

  processContinuation(Continuation cont) {
    reachableContinuations.remove(cont);
    cont.parameters.forEach(values.remove);
  }

  processLetPrim(LetPrim node) {
    node.primitive.type = null;
    values[node.primitive] = null;
  }

  processLetMutable(LetMutable node) {
    node.variable.type = null;
    values[node.variable] = null;
  }
}
