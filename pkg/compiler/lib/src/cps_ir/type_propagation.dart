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
import '../js_backend/backend_helpers.dart' show
    BackendHelpers;
import '../js_backend/js_backend.dart' show
    JavaScriptBackend;
import '../js_backend/codegen/task.dart' show
    CpsFunctionCompiler;
import '../resolution/access_semantics.dart';
import '../resolution/operators.dart';
import '../resolution/send_structure.dart';
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../types/abstract_value_domain.dart' show
    AbstractBool;
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
  final AbstractConstantValue anything;
  final AbstractConstantValue nullValue;

  ConstantPropagationLattice(CpsFunctionCompiler functionCompiler)
    : typeSystem = functionCompiler.typeSystem,
      constantSystem = functionCompiler.compiler.backend.constantSystem,
      dartTypes = functionCompiler.compiler.types,
      anything = new AbstractConstantValue.nonConstant(
          functionCompiler.typeSystem.dynamicType),
      nullValue = new AbstractConstantValue.constantValue(
          new NullConstantValue(), new TypeMask.empty());

  final AbstractConstantValue nothing = new AbstractConstantValue.nothing();

  AbstractConstantValue constant(ConstantValue value, [TypeMask type]) {
    if (type == null) type = typeSystem.getTypeOf(value);
    return new AbstractConstantValue.constantValue(value, type);
  }

  AbstractConstantValue nonConstant([TypeMask type]) {
    if (type == null) type = typeSystem.dynamicType;
    return new AbstractConstantValue.nonConstant(type);
  }

  /// Compute the join of two values in the lattice.
  AbstractConstantValue join(AbstractConstantValue x, AbstractConstantValue y) {
    assert(x != null);
    assert(y != null);

    if (x.isNothing) {
      return y;
    } else if (y.isNothing) {
      return x;
    } else if (x.isConstant && y.isConstant && x.constant == y.constant) {
      return x;
    } else {
      return new AbstractConstantValue.nonConstant(
          typeSystem.join(x.type, y.type));
    }
  }

  /// True if all members of this value are booleans.
  bool isDefinitelyBool(AbstractConstantValue value, {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyBool(value.type, allowNull: allowNull);
  }

  /// True if all members of this value are numbers.
  bool isDefinitelyNum(AbstractConstantValue value, {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyNum(value.type, allowNull: allowNull);
  }

  /// True if all members of this value are strings.
  bool isDefinitelyString(AbstractConstantValue value,
                          {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyString(value.type, allowNull: allowNull);
  }

  /// True if all members of this value are numbers, strings, or booleans.
  bool isDefinitelyNumStringBool(AbstractConstantValue value,
                                 {bool allowNull: false}) {
    return value.isNothing ||
      typeSystem.isDefinitelyNumStringBool(value.type, allowNull: allowNull);
  }

  /// True if this value cannot be a string, number, or boolean.
  bool isDefinitelyNotNumStringBool(AbstractConstantValue value) {
    return value.isNothing ||
      typeSystem.isDefinitelyNotNumStringBool(value.type);
  }

  /// True if this value cannot be a non-integer double.
  ///
  /// In other words, if true is returned, and the value is a number, then
  /// it is a whole number and is not NaN, Infinity, or minus Infinity.
  bool isDefinitelyNotNonIntegerDouble(AbstractConstantValue value) {
    return value.isNothing ||
      value.isConstant && !value.constant.isDouble ||
      typeSystem.isDefinitelyNotNonIntegerDouble(value.type);
  }

  bool isDefinitelyInt(AbstractConstantValue value,
                       {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyInt(value.type, allowNull: allowNull);
  }

  bool isDefinitelyUint31(AbstractConstantValue value,
                          {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyUint31(value.type, allowNull: allowNull);
  }

  bool isDefinitelyUint32(AbstractConstantValue value,
                          {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyUint32(value.type, allowNull: allowNull);
  }

  bool isDefinitelyUint(AbstractConstantValue value,
                       {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyUint(value.type, allowNull: allowNull);
  }

  bool isDefinitelyArray(AbstractConstantValue value,
                              {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyArray(value.type, allowNull: allowNull);
  }

  bool isDefinitelyMutableArray(AbstractConstantValue value,
                                     {bool allowNull: false}) {
    return value.isNothing ||
         typeSystem.isDefinitelyMutableArray(value.type,
                                                  allowNull: allowNull);
  }

  bool isDefinitelyFixedArray(AbstractConstantValue value,
                              {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyFixedArray(value.type,
                                          allowNull: allowNull);
  }

  bool isDefinitelyExtendableArray(AbstractConstantValue value,
                                   {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyExtendableArray(value.type,
                                               allowNull: allowNull);
  }

  bool isDefinitelyIndexable(AbstractConstantValue value,
                             {bool allowNull: false}) {
    return value.isNothing ||
        typeSystem.isDefinitelyIndexable(value.type, allowNull: allowNull);
  }

  /// Returns `true` if [value] represents an int value that must be in the
  /// inclusive range.
  bool isDefinitelyIntInRange(AbstractConstantValue value, {int min, int max}) {
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
  AbstractBool isSubtypeOf(AbstractConstantValue value,
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
  AbstractConstantValue unaryOp(UnaryOperator operator,
                                AbstractConstantValue value) {
    switch (operator.kind) {
      case UnaryOperatorKind.COMPLEMENT:
        return bitNotSpecial(value);
      case UnaryOperatorKind.NEGATE:
        return negateSpecial(value);
      default:
        break;
    }
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
  AbstractConstantValue binaryOp(BinaryOperator operator,
                         AbstractConstantValue left,
                         AbstractConstantValue right) {
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

  AbstractConstantValue foldUnary(UnaryOperation operation,
                                  AbstractConstantValue value) {
    if (value.isNothing) return nothing;
    if (value.isConstant) {
      ConstantValue result = operation.fold(value.constant);
      if (result != null) return constant(result);
    }
    return null;
  }

  AbstractConstantValue bitNotSpecial(AbstractConstantValue value) {
    return foldUnary(constantSystem.bitNot, value);
  }

  AbstractConstantValue negateSpecial(AbstractConstantValue value) {
    AbstractConstantValue folded = foldUnary(constantSystem.negate, value);
    if (folded != null) return folded;
    if (isDefinitelyInt(value)) return nonConstant(typeSystem.intType);
    return null;
  }


  AbstractConstantValue foldBinary(BinaryOperation operation,
      AbstractConstantValue left, AbstractConstantValue right) {
    if (left.isNothing || right.isNothing) return nothing;
    if (left.isConstant && right.isConstant) {
      ConstantValue result = operation.fold(left.constant, right.constant);
      if (result != null) return constant(result);
    }
    return null;
  }

  AbstractConstantValue closedOnInt(AbstractConstantValue left,
                                    AbstractConstantValue right) {
    if (isDefinitelyInt(left) && isDefinitelyInt(right, allowNull: true)) {
      return nonConstant(typeSystem.intType);
    }
    return null;
  }

  AbstractConstantValue closedOnUint(AbstractConstantValue left,
                                     AbstractConstantValue right) {
    if (isDefinitelyUint(left) && isDefinitelyUint(right, allowNull: true)) {
      return nonConstant(typeSystem.uintType);
    }
    return null;
  }

  AbstractConstantValue closedOnUint31(AbstractConstantValue left,
                                       AbstractConstantValue right) {
    if (isDefinitelyUint31(left) && isDefinitelyUint31(right, allowNull: true)) {
      return nonConstant(typeSystem.uint31Type);
    }
    return null;
  }

  AbstractConstantValue addSpecial(AbstractConstantValue left,
                                   AbstractConstantValue right) {
    AbstractConstantValue folded = foldBinary(constantSystem.add, left, right);
    if (folded != null) return folded;
    if (isDefinitelyNum(left)) {
      if (isDefinitelyUint31(left) &&
          isDefinitelyUint31(right, allowNull: true)) {
        return nonConstant(typeSystem.uint32Type);
      }
      return closedOnUint(left, right) ?? closedOnInt(left, right);
    }
    return null;
  }

  AbstractConstantValue subtractSpecial(AbstractConstantValue left,
                                        AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.subtract, left, right);
    return folded ?? closedOnInt(left, right);
  }

  AbstractConstantValue multiplySpecial(AbstractConstantValue left,
                                        AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.multiply, left, right);
    return folded ?? closedOnUint(left, right) ?? closedOnInt(left, right);
  }

  AbstractConstantValue divideSpecial(AbstractConstantValue left,
                                      AbstractConstantValue right) {
    return foldBinary(constantSystem.divide, left, right);
  }

  AbstractConstantValue truncatingDivideSpecial(
      AbstractConstantValue left, AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.truncatingDivide, left, right);
    if (folded != null) return folded;
    if (isDefinitelyNum(left)) {
      if (isDefinitelyUint32(left) && isDefinitelyIntInRange(right, min: 2)) {
        return nonConstant(typeSystem.uint31Type);
      }
      if (isDefinitelyUint(right, allowNull: true)) {
        // `0` will be an exception, other values will shrink the result.
        if (isDefinitelyUint31(left)) return nonConstant(typeSystem.uint31Type);
        if (isDefinitelyUint32(left)) return nonConstant(typeSystem.uint32Type);
        if (isDefinitelyUint(left)) return nonConstant(typeSystem.uintType);
      }
      return nonConstant(typeSystem.intType);
    }
    return null;
  }

  AbstractConstantValue moduloSpecial(AbstractConstantValue left,
                                      AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.modulo, left, right);
    return folded ?? closedOnUint(left, right) ?? closedOnInt(left, right);
  }

  AbstractConstantValue remainderSpecial(AbstractConstantValue left,
                                         AbstractConstantValue right) {
    if (left.isNothing || right.isNothing) return nothing;
    AbstractConstantValue folded = null;  // Remainder not in constant system.
    return folded ?? closedOnUint(left, right) ?? closedOnInt(left, right);
  }

  AbstractConstantValue codeUnitAtSpecial(AbstractConstantValue left,
                                          AbstractConstantValue right) {
    return foldBinary(constantSystem.codeUnitAt, left, right);
  }

  AbstractConstantValue equalSpecial(AbstractConstantValue left,
                                     AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.equal, left, right);
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

  AbstractConstantValue andSpecial(AbstractConstantValue left,
                                   AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.bitAnd, left, right);
    if (folded != null) return folded;
    if (isDefinitelyNum(left)) {
      if (isDefinitelyUint31(left) ||
          isDefinitelyUint31(right, allowNull: true)) {
        // Either 31-bit argument will truncate the other.
        return nonConstant(typeSystem.uint31Type);
      }
    }
    return null;
  }

  AbstractConstantValue orSpecial(AbstractConstantValue left,
                                  AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.bitOr, left, right);
    return folded ?? closedOnUint31(left, right);
  }

  AbstractConstantValue xorSpecial(AbstractConstantValue left,
                                   AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.bitXor, left, right);
    return folded ?? closedOnUint31(left, right);
  }

  AbstractConstantValue shiftLeftSpecial(AbstractConstantValue left,
                                         AbstractConstantValue right) {
    return foldBinary(constantSystem.shiftLeft, left, right);
  }

  AbstractConstantValue shiftRightSpecial(AbstractConstantValue left,
                                          AbstractConstantValue right) {
    AbstractConstantValue folded =
        foldBinary(constantSystem.shiftRight, left, right);
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

  AbstractConstantValue lessSpecial(AbstractConstantValue left,
                                    AbstractConstantValue right) {
    return foldBinary(constantSystem.less, left, right);
  }

  AbstractConstantValue lessEqualSpecial(AbstractConstantValue left,
                                         AbstractConstantValue right) {
    return foldBinary(constantSystem.lessEqual, left, right);
  }

  AbstractConstantValue greaterSpecial(AbstractConstantValue left,
                                       AbstractConstantValue right) {
    return foldBinary(constantSystem.greater, left, right);
  }

  AbstractConstantValue greaterEqualSpecial(AbstractConstantValue left,
                                            AbstractConstantValue right) {
    return foldBinary(constantSystem.greaterEqual, left, right);
  }

  AbstractConstantValue intConstant(int value) {
    return constant(new IntConstantValue(value));
  }

  AbstractConstantValue lengthSpecial(AbstractConstantValue input) {
    if (input.isConstant) {
      ConstantValue constant = input.constant;
      if (constant is StringConstantValue) {
        return intConstant(constant.length);
      } else if (constant is ListConstantValue) {
        return intConstant(constant.length);
      }
    }
    int length = typeSystem.getContainerLength(input.type);
    if (length != null) {
      return intConstant(length);
    }
    return null;  // The caller will use return type from type inference.
  }

  AbstractConstantValue stringConstant(String value) {
    return constant(new StringConstantValue(new ast.DartString.literal(value)));
  }

  AbstractConstantValue indexSpecial(AbstractConstantValue left,
                                     AbstractConstantValue right) {
    if (left.isNothing || right.isNothing) return nothing;
    if (right.isConstant) {
      ConstantValue index = right.constant;
      if (left.isConstant) {
        ConstantValue receiver = left.constant;
        if (receiver is StringConstantValue) {
          if (index is IntConstantValue) {
            String stringValue = receiver.primitiveValue.slowToString();
            int indexValue = index.primitiveValue;
            if (0 <= indexValue && indexValue < stringValue.length) {
              return stringConstant(stringValue[indexValue]);
            } else {
              return nothing;  // Will throw.
            }
          }
        } else if (receiver is ListConstantValue) {
          if (index is IntConstantValue) {
            int indexValue = index.primitiveValue;
            if (0 <= indexValue && indexValue < receiver.length) {
              return constant(receiver.entries[indexValue]);
            } else {
              return nothing;  // Will throw.
            }
          }
        } else if (receiver is MapConstantValue) {
          ConstantValue result = receiver.lookup(index);
          if (result != null) {
            return constant(result);
          }
          return constant(new NullConstantValue());
        }
      }
      TypeMask type = typeSystem.indexWithConstant(left.type, index);
      if (type != null) return nonConstant(type);
    }
    return null;  // The caller will use return type from type inference.
  }

  AbstractConstantValue stringify(AbstractConstantValue value) {
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
  AbstractBool boolify(AbstractConstantValue value) {
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
  AbstractBool strictBoolify(AbstractConstantValue value) {
    if (value.isNothing) return AbstractBool.Nothing;
    if (value.isConstant) {
      return value.constant.isTrue ? AbstractBool.True : AbstractBool.False;
    }
    return typeSystem.strictBoolify(value.type);
  }

  /// The possible return types of a method that may be targeted by
  /// [selector] on [receiver].
  AbstractConstantValue getInvokeReturnType(
      Selector selector, AbstractConstantValue receiver) {
    return fromMask(typeSystem.getInvokeReturnType(selector, receiver.type));
  }

  AbstractConstantValue fromMask(TypeMask mask) {
    ConstantValue constantValue = typeSystem.getConstantOf(mask);
    if (constantValue != null) return constant(constantValue, mask);
    return nonConstant(mask);
  }

  AbstractConstantValue nonNullable(AbstractConstantValue value) {
    if (value.isNullConstant) return nothing;
    if (!value.isNullable) return value;
    return nonConstant(value.type.nonNullable());
  }

  /// If [value] is an integer constant, returns its value, otherwise `null`.
  int intValue(AbstractConstantValue value) {
    if (value.isConstant && value.constant.isInt) {
      PrimitiveConstantValue constant = value.constant;
      return constant.primitiveValue;
    }
    return null;
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
  String get passName => 'Type propagation';

  final CpsFunctionCompiler _functionCompiler;
  final Map<Variable, ConstantValue> _values= <Variable, ConstantValue>{};
  final ConstantPropagationLattice _lattice;

  TypePropagator(CpsFunctionCompiler functionCompiler)
      : _functionCompiler = functionCompiler,
        _lattice = new ConstantPropagationLattice(functionCompiler);

  dart2js.Compiler get _compiler => _functionCompiler.compiler;
  InternalErrorFunction get _internalError => _compiler.reporter.internalError;

  @override
  void rewrite(FunctionDefinition root) {
    // Analyze. In this phase, the entire term is analyzed for reachability
    // and the abstract value of each expression.
    TypePropagationVisitor analyzer = new TypePropagationVisitor(
        _lattice,
        _values,
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
  final ConstantPropagationLattice lattice;
  final dart2js.Compiler compiler;
  final CpsFunctionCompiler functionCompiler;

  JavaScriptBackend get backend => compiler.backend;
  BackendHelpers get helpers => backend.helpers;
  TypeMaskSystem get typeSystem => lattice.typeSystem;
  types.DartTypes get dartTypes => lattice.dartTypes;
  World get classWorld => typeSystem.classWorld;
  Map<Variable, ConstantValue> get values => analyzer.values;

  final InternalErrorFunction internalError;

  final List<Node> stack = <Node>[];

  TransformingVisitor(this.compiler,
                      this.functionCompiler,
                      this.lattice,
                      this.analyzer,
                      this.internalError);

  void transform(FunctionDefinition root) {
    // If one of the parameters has no value, the function is unreachable.
    // We assume all values in scope have a non-empty type (otherwise the
    // scope is unreachable), so this optimization is required.
    // TODO(asgerf): Can we avoid emitting the function is the first place?
    for (Parameter param in root.parameters) {
      if (getValue(param).isNothing) {
        // Replace with `throw "Unreachable";`
        CpsFragment cps = new CpsFragment(null);
        Primitive message = cps.makeConstant(
            new StringConstantValue.fromString("Unreachable"));
        cps.put(new Throw(message));
        replaceSubtree(root.body, cps.result);
        return;
      }
    }
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
    Primitive prim = node.primitive;

    // Try to remove a dead primitive.
    if (prim.hasNoUses && prim.isSafeForElimination) {
      push(node.body);
      prim.destroy();
      node.remove();
      return;
    }

    // Try to constant-fold the primitive.
    if (prim is! Constant && prim is! Refinement && prim.isSafeForElimination) {
      AbstractConstantValue value = getValue(prim);
      if (value.isConstant) {
        if (constantIsSafeToCopy(value.constant)) {
          prim.replaceWith(makeConstantPrimitive(value.constant));
          push(node.body);
          return;
        }
      }
    }

    // Try to specialize the primitive.
    var replacement = visit(prim);
    if (replacement is CpsFragment) {
      reanalyzeFragment(replacement);
      replacement.insertBelow(node);
      push(node.body); // Get the body before removing the node.
      prim.destroy();
      node.remove();
      return;
    }
    if (replacement is Primitive) {
      prim.replaceWith(replacement);
      reanalyze(replacement);
      // Reanalyze this node. Further specialization may be possible.
      push(node);
      return;
    }
    assert(replacement == null);

    // Remove dead code after a primitive that always throws.
    if (isAlwaysThrowingOrDiverging(prim)) {
      replaceSubtree(node.body, new Unreachable());
      return;
    }

    push(node.body);
  }

  bool constantIsSafeToCopy(ConstantValue constant) {
    // TODO(25230, 25231): We should refer to large shared strings by name.
    // This number is chosen to prevent huge strings being copied. Don't make
    // this too small, otherwise it will suppress otherwise harmless constant
    // folding.
    const int MAXIMUM_LENGTH_OF_DUPLICATED_STRING = 500;
    return constant is StringConstantValue
        ? constant.length < MAXIMUM_LENGTH_OF_DUPLICATED_STRING
        : true;
  }

  bool isAlwaysThrowingOrDiverging(Primitive prim) {
    if (prim is SetField) {
      return getValue(prim.object.definition).isNullConstant;
    }
    if (prim is SetIndex) {
      return getValue(prim.object.definition).isNullConstant;
    }
    // If a primitive has a value, but can't return anything, it must throw
    // or diverge.
    return prim.hasValue && prim.type.isEmpty && !prim.type.isNullable;
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

  /// Sets parent pointers and computes types for the given fragment.
  void reanalyzeFragment(CpsFragment code) {
    if (code.isEmpty) return;
    if (code.isOpen) {
      // Temporarily close the fragment while analyzing it.
      // TODO(asgerf): Perhaps the analyzer should just cope with missing nodes.
      InteriorNode context = code.context;
      code.put(new Unreachable());
      reanalyze(code.root);
      code.context = context;
      context.body = null;
    } else {
      reanalyze(code.root);
    }
  }

  /// Removes the entire subtree of [node] and inserts [replacement].
  ///
  /// All references in the [node] subtree are unlinked all types in
  /// [replacement] are recomputed.
  ///
  /// [replacement] must be "fresh", i.e. it must not contain significant parts
  /// of the original IR inside of it, as this leads to redundant reprocessing.
  void replaceSubtree(Expression node, Expression replacement) {
    InteriorNode parent = node.parent;
    parent.body = replacement;
    replacement.parent = parent;
    node.parent = null;
    RemovalVisitor.remove(node);
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
    AbstractConstantValue conditionValue = getValue(condition);

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
        Primitive argument = node.arguments[i].definition;
        Parameter parameter = cont.parameters[i];
        argument.useElementAsHint(parameter.hint);
        parameter.replaceUsesWith(argument);
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
  specializeOperatorCall(InvokeMethod node) {
    bool trustPrimitives = compiler.trustPrimitives;

    /// Throws a [NoSuchMethodError] if the receiver is null, where [guard]
    /// is a predicate that is true if and only if the receiver is null.
    ///
    /// See [NullCheck.guarded].
    Primitive guardReceiver(CpsFragment cps, BuiltinOperator guard) {
      if (guard == null || getValue(node.dartReceiver).isDefinitelyNotNull) {
        return node.dartReceiver;
      }
      if (!trustPrimitives) {
        // TODO(asgerf): Perhaps a separate optimization should decide that
        // the guarded check is better based on the type?
        Primitive check = cps.applyBuiltin(guard, [node.dartReceiver]);
        return cps.letPrim(new NullCheck.guarded(check, node.dartReceiver,
          node.selector, node.sourceInformation));
      } else {
        // Refine the receiver to be non-null for use in the operator.
        // This restricts code motion and improves the type computed for the
        // built-in operator that depends on it.
        // This must be done even if trusting primitives.
        return cps.letPrim(
            new Refinement(node.dartReceiver, typeSystem.nonNullType));
      }
    }

    /// Replaces the call with [operator], using the receiver and first argument
    /// as operands (in that order).
    ///
    /// If [guard] is given, the receiver is checked using [guardReceiver],
    /// unless it is known not to be null.
    CpsFragment makeBinary(BuiltinOperator operator, {BuiltinOperator guard}) {
      CpsFragment cps = new CpsFragment(node.sourceInformation);
      Primitive left = guardReceiver(cps, guard);
      Primitive right = node.dartArgument(0);
      Primitive result = cps.applyBuiltin(operator, [left, right]);
      result.hint = node.hint;
      node.replaceUsesWith(result);
      return cps;
    }

    /// Like [makeBinary] but for unary operators with the receiver as the
    /// argument.
    CpsFragment makeUnary(BuiltinOperator operator, {BuiltinOperator guard}) {
      CpsFragment cps = new CpsFragment(node.sourceInformation);
      Primitive argument = guardReceiver(cps, guard);
      Primitive result = cps.applyBuiltin(operator, [argument]);
      result.hint = node.hint;
      node.replaceUsesWith(result);
      return cps;
    }

    if (node.selector.isOperator && node.arguments.length == 2) {
      Primitive leftArg = node.dartReceiver;
      Primitive rightArg = node.dartArgument(0);
      AbstractConstantValue left = getValue(leftArg);
      AbstractConstantValue right = getValue(rightArg);

      String opname = node.selector.name;
      if (opname == '==') {
        // Equality is special due to its treatment of null values and the
        // fact that Dart-null corresponds to both JS-null and JS-undefined.
        // Please see documentation for IsFalsy, StrictEq, and LooseEq.
        if (left.isNullConstant || right.isNullConstant) {
          return makeBinary(BuiltinOperator.Identical);
        }
        // There are several implementations of == that behave like identical.
        // Specialize it if we definitely call one of those.
        bool behavesLikeIdentical = true;
        for (Element target in getAllTargets(left.type, node.selector)) {
          ClassElement clazz = target.enclosingClass.declaration;
          if (clazz != compiler.world.objectClass &&
              clazz != helpers.jsInterceptorClass &&
              clazz != helpers.jsNullClass) {
            behavesLikeIdentical = false;
            break;
          }
        }
        if (behavesLikeIdentical) {
          return makeBinary(BuiltinOperator.Identical);
        }
      } else {
        if (lattice.isDefinitelyNum(left, allowNull: true) &&
            lattice.isDefinitelyNum(right, allowNull: trustPrimitives)) {
          // Try to insert a numeric operator.
          BuiltinOperator operator = NumBinaryBuiltins[opname];
          if (operator != null) {
            return makeBinary(operator, guard: BuiltinOperator.IsNotNumber);
          }
          // Shift operators are not in [NumBinaryBuiltins] because Dart shifts
          // behave different to JS shifts, especially in the handling of the
          // shift count.
          // Try to insert a shift-left operator.
          if (opname == '<<' &&
              lattice.isDefinitelyInt(left, allowNull: true) &&
              lattice.isDefinitelyIntInRange(right, min: 0, max: 31)) {
            return makeBinary(BuiltinOperator.NumShl,
                guard: BuiltinOperator.IsNotNumber);
          }
          // Try to insert a shift-right operator. JavaScript's right shift is
          // consistent with Dart's only for left operands in the unsigned
          // 32-bit range.
          if (opname == '>>' &&
              lattice.isDefinitelyUint32(left, allowNull: true) &&
              lattice.isDefinitelyIntInRange(right, min: 0, max: 31)) {
            return makeBinary(BuiltinOperator.NumShr,
                guard: BuiltinOperator.IsNotNumber);
          }
          // Try to use remainder for '%'. Both operands must be non-negative
          // and the divisor must be non-zero.
          if (opname == '%' &&
              lattice.isDefinitelyUint(left, allowNull: true) &&
              lattice.isDefinitelyUint(right) &&
              lattice.isDefinitelyIntInRange(right, min: 1)) {
            return makeBinary(BuiltinOperator.NumRemainder,
                guard: BuiltinOperator.IsNotNumber);
          }

          if (opname == '~/' &&
              lattice.isDefinitelyUint32(left, allowNull: true) &&
              lattice.isDefinitelyIntInRange(right, min: 2)) {
            return makeBinary(BuiltinOperator.NumTruncatingDivideToSigned32,
                guard: BuiltinOperator.IsNotNumber);
          }
        }
        if (lattice.isDefinitelyString(left, allowNull: trustPrimitives) &&
            lattice.isDefinitelyString(right, allowNull: trustPrimitives) &&
            opname == '+') {
          // TODO(asgerf): Add IsString builtin so we can use a guard here.
          return makeBinary(BuiltinOperator.StringConcatenate);
        }
      }
    }
    if (node.selector.isOperator && node.arguments.length == 1) {
      Primitive argument = node.dartReceiver;
      AbstractConstantValue value = getValue(argument);

      if (lattice.isDefinitelyNum(value, allowNull: true)) {
        String opname = node.selector.name;
        if (opname == '~') {
          return makeUnary(BuiltinOperator.NumBitNot,
              guard: BuiltinOperator.IsNotNumber);
        }
        if (opname == 'unary-') {
          return makeUnary(BuiltinOperator.NumNegate,
              guard: BuiltinOperator.IsNotNumber);
        }
      }
    }
    if (node.selector.isCall) {
      String name = node.selector.name;
      Primitive receiver = node.dartReceiver;
      AbstractConstantValue receiverValue = getValue(receiver);
      if (name == 'remainder') {
        if (node.arguments.length == 2) {
          Primitive arg = node.dartArgument(0);
          AbstractConstantValue argValue = getValue(arg);
          if (lattice.isDefinitelyInt(receiverValue, allowNull: true) &&
              lattice.isDefinitelyInt(argValue) &&
              isIntNotZero(argValue)) {
            return makeBinary(BuiltinOperator.NumRemainder,
                guard: BuiltinOperator.IsNotNumber);
          }
        }
      } else if (name == 'codeUnitAt') {
        if (node.arguments.length == 2) {
          Primitive index = node.dartArgument(0);
          if (lattice.isDefinitelyString(receiverValue) &&
              lattice.isDefinitelyInt(getValue(index))) {
            CpsFragment cps = new CpsFragment(node.sourceInformation);
            receiver = makeBoundsCheck(cps, receiver, index);
            ApplyBuiltinOperator get =
                cps.applyBuiltin(BuiltinOperator.CharCodeAt,
                                 <Primitive>[receiver, index]);
            node.replaceUsesWith(get);
            get.hint = node.hint;
            return cps;
          }
        }
      }
    }
    return null;
  }

  /// Returns `true` if [value] represents an int value that cannot be zero.
  bool isIntNotZero(AbstractConstantValue value) {
    return lattice.isDefinitelyIntInRange(value, min: 1) ||
        lattice.isDefinitelyIntInRange(value, max: -1);
  }

  bool isInterceptedSelector(Selector selector) {
    return backend.isInterceptedSelector(selector);
  }

  /// If [node] is a getter or setter invocation, tries to replace the
  /// invocation with a direct access to a field.
  ///
  /// Returns `true` if the node was replaced.
  Primitive specializeFieldAccess(InvokeMethod node) {
    if (!node.selector.isGetter && !node.selector.isSetter) return null;
    AbstractConstantValue receiver = getValue(node.dartReceiver);
    Element target =
        typeSystem.locateSingleElement(receiver.type, node.selector);
    if (target is! FieldElement) return null;
    // TODO(asgerf): Inlining native fields will make some tests pass for the
    // wrong reason, so for testing reasons avoid inlining them.
    if (backend.isNative(target) || backend.isJsInterop(target)) {
      return null;
    }
    if (node.selector.isGetter) {
      return new GetField(node.dartReceiver, target);
    } else {
      if (target.isFinal) return null;
      assert(node.hasNoUses);
      return new SetField(node.dartReceiver,
                          target,
                          node.dartArgument(0));
    }
  }

  /// Create a check that throws if [index] is not a valid index on [list].
  ///
  /// This function assumes that [index] is an integer.
  ///
  /// Returns a CPS fragment whose context is the branch where no error
  /// was thrown.
  Primitive makeBoundsCheck(CpsFragment cps,
                            Primitive list,
                            Primitive index,
                            [int checkKind = BoundsCheck.BOTH_BOUNDS]) {
    if (compiler.trustPrimitives) {
      return cps.letPrim(new BoundsCheck.noCheck(list, cps.sourceInformation));
    } else {
      GetLength length = cps.letPrim(new GetLength(list));
      list = cps.refine(list, typeSystem.nonNullType);
      return cps.letPrim(new BoundsCheck(list, index, length, checkKind,
          cps.sourceInformation));
    }
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
        helpers.throwConcurrentModificationError,
        <Primitive>[list]);
    return cps;
  }

  /// Tries to replace [node] with a direct `length` or index access.
  ///
  /// Returns `true` if the node was replaced.
  specializeIndexableAccess(InvokeMethod node) {
    Primitive receiver = node.dartReceiver;
    AbstractConstantValue receiverValue = getValue(receiver);
    if (!typeSystem.isDefinitelyIndexable(receiverValue.type,
            allowNull: true)) {
      return null;
    }
    switch (node.selector.name) {
      case 'length':
        if (!node.selector.isGetter) return null;
        return new GetLength(receiver);

      case '[]':
        Primitive index = node.dartArgument(0);
        if (!lattice.isDefinitelyInt(getValue(index))) return null;
        CpsFragment cps = new CpsFragment(node.sourceInformation);
        receiver = makeBoundsCheck(cps, receiver, index);
        GetIndex get = cps.letPrim(new GetIndex(receiver, index));
        node.replaceUsesWith(get);
        // TODO(asgerf): Make replaceUsesWith set the hint?
        get.hint = node.hint;
        return cps;

      case '[]=':
        if (!typeSystem.isDefinitelyMutableIndexable(receiverValue.type,
                allowNull: true)) {
          return null;
        }
        Primitive index = node.dartArgument(0);
        Primitive value = node.dartArgument(1);
        if (!lattice.isDefinitelyInt(getValue(index))) return null;
        CpsFragment cps = new CpsFragment(node.sourceInformation);
        receiver = makeBoundsCheck(cps, receiver, index);
        cps.letPrim(new SetIndex(receiver, index, value));
        assert(node.hasNoUses);
        return cps;

      case 'isEmpty':
        if (!node.selector.isGetter) return null;
        CpsFragment cps = new CpsFragment(node.sourceInformation);
        Primitive length = cps.letPrim(new GetLength(receiver));
        Constant zero = cps.makeZero();
        ApplyBuiltinOperator op = cps.applyBuiltin(BuiltinOperator.StrictEq,
                                                   [length, zero]);
        node.replaceUsesWith(op);
        op.hint = node.hint;
        return cps;

      case 'isNotEmpty':
        if (!node.selector.isGetter) return null;
        CpsFragment cps = new CpsFragment(node.sourceInformation);
        Primitive length = cps.letPrim(new GetLength(receiver));
        Constant zero = cps.makeZero();
        ApplyBuiltinOperator op = cps.applyBuiltin(BuiltinOperator.StrictNeq,
                                                   [length, zero]);
        node.replaceUsesWith(op);
        op.hint = node.hint;
        return cps;

      default:
        return null;
    }
  }

  /// Tries to replace [node] with one or more direct array access operations.
  ///
  /// Returns `true` if the node was replaced.
  CpsFragment specializeArrayAccess(InvokeMethod node) {
    Primitive list = node.dartReceiver;
    AbstractConstantValue listValue = getValue(list);
    // Ensure that the object is a native list or null.
    if (!lattice.isDefinitelyArray(listValue, allowNull: true)) {
      return null;
    }
    bool isFixedLength =
        lattice.isDefinitelyFixedArray(listValue, allowNull: true);
    bool isExtendable =
        lattice.isDefinitelyExtendableArray(listValue, allowNull: true);
    SourceInformation sourceInfo = node.sourceInformation;
    switch (node.selector.name) {
      case 'add':
        if (!node.selector.isCall ||
            node.selector.positionalArgumentCount != 1 ||
            node.selector.namedArgumentCount != 0) {
          return null;
        }
        if (!isExtendable) return null;
        Primitive addedItem = node.dartArgument(0);
        CpsFragment cps = new CpsFragment(sourceInfo);
        cps.invokeBuiltin(BuiltinMethod.Push,
            list,
            <Primitive>[addedItem]);
        if (node.hasAtLeastOneUse) {
          node.replaceUsesWith(cps.makeNull());
        }
        return cps;

      case 'removeLast':
        if (!node.selector.isCall ||
            node.selector.argumentCount != 0) {
          return null;
        }
        if (!isExtendable) return null;
        CpsFragment cps = new CpsFragment(sourceInfo);
        list = makeBoundsCheck(cps, list, cps.makeMinusOne(),
            BoundsCheck.EMPTINESS);
        Primitive removedItem = cps.invokeBuiltin(BuiltinMethod.Pop,
            list,
            <Primitive>[]);
        removedItem.hint = node.hint;
        node.replaceUsesWith(removedItem);
        return cps;

      case 'addAll':
        if (!node.selector.isCall ||
            node.selector.argumentCount != 1) {
          return null;
        }
        if (!isExtendable) return null;
        Primitive addedList = node.dartArgument(0);
        // Rewrite addAll([x1, ..., xN]) to push(x1), ..., push(xN).
        // Ensure that the list is not mutated between creation and use.
        // We aim for the common case where this is the only use of the list,
        // which also guarantees that this list is not mutated before use.
        if (addedList is! LiteralList || !addedList.hasExactlyOneUse) {
          return null;
        }
        LiteralList addedLiteral = addedList;
        CpsFragment cps = new CpsFragment(sourceInfo);
        for (Reference value in addedLiteral.values) {
          cps.invokeBuiltin(BuiltinMethod.Push,
              list,
              <Primitive>[value.definition]);
        }
        if (node.hasAtLeastOneUse) {
          node.replaceUsesWith(cps.makeNull());
        }
        return cps;

      case 'elementAt':
        if (!node.selector.isCall ||
            node.selector.positionalArgumentCount != 1 ||
            node.selector.namedArgumentCount != 0) {
          return null;
        }
        if (listValue.isNullable) return null;
        Primitive index = node.dartArgument(0);
        if (!lattice.isDefinitelyInt(getValue(index))) return null;
        CpsFragment cps = new CpsFragment(node.sourceInformation);
        list = makeBoundsCheck(cps, list, index);
        GetIndex get = cps.letPrim(new GetIndex(list, index));
        get.hint = node.hint;
        node.replaceUsesWith(get);
        return cps;

      case 'forEach':
        Element element =
            compiler.world.locateSingleElement(node.selector, listValue.type);
        if (element == null ||
            !element.isFunction ||
            !node.selector.isCall) return null;
        assert(node.selector.positionalArgumentCount == 1);
        assert(node.selector.namedArgumentCount == 0);
        FunctionDefinition target = functionCompiler.compileToCpsIr(element);

        CpsFragment cps = new CpsFragment(node.sourceInformation);
        Primitive result = cps.inlineFunction(target,
            node.receiver.definition,
            node.arguments.map((ref) => ref.definition).toList(),
            hint: node.hint);
        node.replaceUsesWith(result);
        return cps;

      case 'iterator':
        // TODO(asgerf): This should be done differently.
        //               The types are recomputed in a very error-prone manner.
        if (!node.selector.isGetter) return null;
        Primitive iterator = node;
        LetPrim iteratorBinding = node.parent;

        // Check that all uses of the iterator are 'moveNext' and 'current'.
        assert(!isInterceptedSelector(Selectors.moveNext));
        assert(!isInterceptedSelector(Selectors.current));
        for (Reference ref in iterator.effectiveUses) {
          if (ref.parent is! InvokeMethod) return null;
          InvokeMethod use = ref.parent;
          if (ref != use.receiver) return null;
          if (use.selector != Selectors.moveNext &&
              use.selector != Selectors.current) {
            return null;
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
          if (use.selector == Selectors.current) {
            // Rewrite iterator.current to a use of the 'current' variable.
            if (use.hint != null) {
              // If 'current' was originally moved into a named variable, use
              // that variable name for the mutable variable.
              current.hint = use.hint;
            }
            use.replaceWith(new GetMutable(current));
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
            Parameter result = new Parameter(node.hint);
            Continuation moveNextCont = cps.letCont(<Parameter>[result]);

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
            InteriorNode parent = getEffectiveParent(use.parent);
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
                  if (getEffectiveParent(invocationCaller) == iteratorBinding) {
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
              ..invokeContinuation(moveNextCont, [falseBranch.makeFalse()]);

            // Return true if there are more element.
            current.type = typeSystem.elementTypeOfIndexable(listValue.type);
            cps.setMutable(current,
                cps.letPrim(new GetIndex(list, cps.getMutable(index))));
            cps.setMutable(index, cps.applyBuiltin(
                BuiltinOperator.NumAdd,
                [cps.getMutable(index), cps.makeOne()]));
            cps.invokeContinuation(moveNextCont, [cps.makeTrue()]);

            reanalyzeFragment(cps);

            // Replace the moveNext() call. It will be visited later.
            LetPrim let = use.parent;
            cps.context = moveNextCont;
            cps.insertBelow(let);
            let.remove();
            use..replaceUsesWith(result)..destroy();
          }
        }

        // All effective uses have been rewritten.
        destroyRefinementsOfDeadPrimitive(iterator);

        // Rewrite the iterator call to initializers for 'index' and 'current'.
        CpsFragment cps = new CpsFragment();
        cps.letMutable(index, cps.makeZero());
        cps.letMutable(current, cps.makeNull());
        cps.letPrim(originalLength);
        return cps;

      default:
        return null;
    }
  }

  /// Returns the first parent of [node] that is not a pure expression.
  InteriorNode getEffectiveParent(Expression node) {
    while (true) {
      InteriorNode parent = node.parent;
      if (parent is LetCont ||
          parent is LetPrim && parent.primitive.isSafeForReordering ||
          parent is LetPrim && parent.primitive is Refinement) {
        node = parent as dynamic; // Make analyzer accept cross cast.
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
  Primitive specializeClosureCall(InvokeMethod node) {
    Selector call = node.selector;
    if (!call.isClosureCall) return null;

    assert(!isInterceptedSelector(call));
    assert(call.argumentCount == node.arguments.length);

    Primitive tearOff = node.dartReceiver.effectiveDefinition;
    // Note: We don't know if [tearOff] is actually a tear-off.
    // We name variables based on the pattern we are trying to match.

    if (tearOff is GetStatic && tearOff.element.isFunction) {
      FunctionElement target = tearOff.element;
      FunctionSignature signature = target.functionSignature;

      // If the selector does not apply, don't bother (will throw at runtime).
      if (!call.signatureApplies(target)) return null;

      // If some optional arguments are missing, give up.
      // TODO(asgerf): Improve optimization by inserting default arguments.
      if (call.argumentCount != signature.parameterCount) return null;

      // Replace with InvokeStatic.
      // The tear-off will be cleaned up by shrinking reductions.
      return new InvokeStatic(target,
          new Selector.fromElement(target),
          node.arguments.map((ref) => ref.definition).toList(),
          node.sourceInformation);
    }
    if (tearOff is InvokeMethod && tearOff.selector.isGetter) {
      Selector getter = tearOff.selector;

      // TODO(asgerf): Support torn-off intercepted methods.
      if (isInterceptedSelector(getter)) return null;

      LetPrim tearOffBinding = tearOff.parent;

      Primitive object = tearOff.receiver.definition;

      // Ensure that the object actually has a foo member, since we might
      // otherwise alter a noSuchMethod call.
      TypeMask type = getValue(object).type;
      if (typeSystem.needsNoSuchMethodHandling(type, getter)) return null;

      Element element = typeSystem.locateSingleElement(type, getter);

      // If it's definitely not a tear-off, the rewrite is not worth it.
      // If we don't know what the target is, we assume that it's better to
      // rewrite (as long as it's safe to do so).
      if (element != null && element.isGetter) return null;

      // Either the target is a tear-off or we don't know what it is.
      // If we don't know for sure, the getter might have side effects, which
      // can make the rewriting unsafe, because we risk suppressing side effects
      // in the getter.
      // Determine if the getter invocation can have side-effects.
      bool isPure = element != null && !element.isGetter;

      // If there are multiple uses, we cannot eliminate the getter call and
      // therefore risk duplicating its side effects.
      if (!isPure && tearOff.hasMultipleEffectiveUses) return null;

      // If the getter call is impure, we risk reordering side effects,
      // unless it is immediately prior to the closure call.
      if (!isPure && getEffectiveParent(node.parent) != tearOffBinding) {
        return null;
      }

      InvokeMethod invoke = new InvokeMethod(
        object,
        new Selector.call(getter.memberName, call.callStructure),
        type,
        node.arguments.map((ref) => ref.definition).toList(),
        sourceInformation: node.sourceInformation);
      node.receiver.changeTo(new Parameter(null)); // Remove the tear off use.

      if (tearOff.hasNoEffectiveUses) {
        // Eliminate the getter call if it has no more uses.
        // This cannot be delegated to other optimizations because we need to
        // avoid duplication of side effects.
        destroyRefinementsOfDeadPrimitive(tearOff);
        tearOff.destroy();
        tearOffBinding.remove();
      } else {
        // There are more uses, so we cannot eliminate the getter call. This
        // means we duplicated the effects of the getter call, but we should
        // only get here if the getter has no side effects.
        assert(isPure);
      }

      return invoke;
    }
    return null;
  }

  /// Inlines a single-use closure if it leaves the closure object with only
  /// field accesses.  This is optimized later by [ScalarReplacer].
  CpsFragment specializeSingleUseClosureCall(InvokeMethod node) {
    Selector call = node.selector;
    if (!call.isClosureCall) return null;

    assert(!isInterceptedSelector(call));
    assert(call.argumentCount == node.arguments.length);

    Primitive receiver = node.receiver.definition;
    if (receiver is !CreateInstance) return null;
    CreateInstance createInstance = receiver;
    if (!createInstance.hasExactlyOneUse) return null;

    // Inline only closures. This avoids inlining the 'call' method of a class
    // that has many allocation sites.
    if (createInstance.classElement is !ClosureClassElement) return null;

    ClosureClassElement closureClassElement = createInstance.classElement;
    Element element = closureClassElement.localLookup(Identifiers.call);

    if (element == null || !element.isFunction) return null;
    FunctionElement functionElement = element;
    if (functionElement.asyncMarker != AsyncMarker.SYNC) return null;

    if (!call.signatureApplies(functionElement)) return null;
    // Inline only for exact match.
    // TODO(sra): Handle call with defaulted arguments.
    Selector targetSelector = new Selector.fromElement(functionElement);
    if (call.callStructure != targetSelector.callStructure) return null;

    // Don't inline if [target] contains try-catch or try-finally. JavaScript
    // engines typically do poor optimization of the entire function containing
    // the 'try'.
    if (functionElement.resolvedAst.elements.containsTryStatement) return null;

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
      return null;
    }

    CpsFragment cps = new CpsFragment(node.sourceInformation);
    Primitive returnValue = cps.inlineFunction(target,
        node.receiver.definition,
        node.arguments.map((ref) => ref.definition).toList(),
        hint: node.hint);
    node.replaceUsesWith(returnValue);
    return cps;
  }

  visitInterceptor(Interceptor node) {
    // Replace the interceptor with its input if the value is not intercepted.
    // If the input might be null, we cannot do this since the interceptor
    // might have to return JSNull.  That case is handled by visitInvokeMethod
    // and visitInvokeMethodDirectly which can sometimes tolerate that null
    // is used instead of JSNull.
    Primitive input = node.input.definition;
    if (!input.type.isNullable &&
        typeSystem.areDisjoint(input.type, typeSystem.interceptorType)) {
      node.replaceUsesWith(input);
    }
  }

  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    TypeMask receiverType = node.dartReceiver.type;
    if (node.callingConvention == CallingConvention.Intercepted &&
        typeSystem.areDisjoint(receiverType, typeSystem.interceptorType)) {
      // Some direct calls take an interceptor because the target class is
      // mixed into a native class.  If it is known at the call site that the
      // receiver is non-intercepted, get rid of the interceptor.
      node.receiver.changeTo(node.dartReceiver);
    }
  }

  visitInvokeMethod(InvokeMethod node) {
    var specialized =
        specializeOperatorCall(node) ??
        specializeFieldAccess(node) ??
        specializeIndexableAccess(node) ??
        specializeArrayAccess(node) ??
        specializeSingleUseClosureCall(node) ??
        specializeClosureCall(node);
    if (specialized != null) return specialized;

    TypeMask receiverType = node.dartReceiver.type;
    node.mask = typeSystem.intersection(node.mask, receiverType);

    bool canBeNonThrowingCallOnNull =
        selectorsOnNull.contains(node.selector) &&
        receiverType.isNullable;

    if (node.callingConvention == CallingConvention.Intercepted &&
        !canBeNonThrowingCallOnNull &&
        typeSystem.areDisjoint(receiverType, typeSystem.interceptorType)) {
      // Use the Dart receiver as the JS receiver. This changes the wording of
      // the error message when the receiver is null, but we accept this.
      node.receiver.changeTo(node.dartReceiver);

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
      if (!getAllTargets(receiverType, node.selector).any(needsReceiver)) {
        // Replace the extra receiver argument with a dummy value if the
        // target definitely does not use it.
        Constant dummy = makeConstantPrimitive(new IntConstantValue(0));
        new LetPrim(dummy).insertAbove(node.parent);
        node.arguments[0].changeTo(dummy);
        node.callingConvention = CallingConvention.DummyIntercepted;
      }
    }
  }

  CpsFragment visitTypeCast(TypeCast node) {
    AbstractConstantValue value = getValue(node.value.definition);
    switch (lattice.isSubtypeOf(value, node.dartType, allowNull: true)) {
      case AbstractBool.Maybe:
      case AbstractBool.Nothing:
        return null;

      case AbstractBool.True:
        // Return an unused primitive moved again.
        node.replaceUsesWith(node.value.definition);
        return new CpsFragment(); // Remove the node.

      case AbstractBool.False:
        // Note: The surrounding LetPrim will remove the following code because
        // it always throws. We don't need to do it here.
        return null;
    }
  }

  /// Specialize calls to internal static methods.
  specializeInternalMethodCall(InvokeStatic node) {
    if (node.target == backend.helpers.stringInterpolationHelper) {
      AbstractConstantValue value = getValue(node.arguments[0].definition);
      if (lattice.isDefinitelyString(value)) {
        node.replaceUsesWith(node.arguments[0].definition);
        return new CpsFragment();
      }
    } else if (node.target == compiler.identicalFunction) {
      if (node.arguments.length == 2) {
        return new ApplyBuiltinOperator(BuiltinOperator.Identical,
            [node.arguments[0].definition, node.arguments[1].definition],
            node.sourceInformation);
      }
    }
    return null;
  }

  visitInvokeStatic(InvokeStatic node) {
    return specializeInternalMethodCall(node);
  }

  AbstractConstantValue getValue(Variable node) {
    assert(node.type != null);
    ConstantValue constant = values[node];
    if (constant != null) {
      return new AbstractConstantValue.constantValue(constant, node.type);
    }
    return new AbstractConstantValue.nonConstant(node.type);
  }


  /*************************** PRIMITIVES **************************/
  //
  // The visit method for a primitive may return one of the following:
  // - Primitive:
  //     The visited primitive will be replaced by the returned primitive.
  //     The type of the primitive will be recomputed.
  // - CpsFragment:
  //     The primitive binding will be destroyed and replaced by the given
  //     code fragment.  All types in the fragment will be recomputed.
  // - Null:
  //     Nothing happens. The primitive remains as it is.
  //

  void visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    ast.DartString getString(AbstractConstantValue value) {
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
          AbstractConstantValue firstValue =
              getValue(node.arguments[i++].definition);
          if (!firstValue.isConstant) continue;
          AbstractConstantValue secondValue =
              getValue(node.arguments[i++].definition);
          if (!secondValue.isConstant) continue;

          ast.DartString string =
              new ast.ConsDartString(getString(firstValue),
                                     getString(secondValue));

          // We found a sequence of at least two constants.
          // Look for the end of the sequence.
          while (i < node.arguments.length) {
            AbstractConstantValue value =
                getValue(node.arguments[i].definition);
            if (!value.isConstant) break;
            string = new ast.ConsDartString(string, getString(value));
            ++i;
          }
          Constant prim =
              makeConstantPrimitive(new StringConstantValue(string));
          new LetPrim(prim).insertAbove(node.parent);
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
        if (node.arguments.length == 1) {
          Primitive input = node.arguments[0].definition;
          node.replaceUsesWith(input);
          input.useElementAsHint(node.hint);
        }
        // TODO(asgerf): Rebalance nested StringConcats that arise from
        //               rewriting the + operator to StringConcat.
        break;

      case BuiltinOperator.Identical:
        Primitive leftArg = node.arguments[0].definition;
        Primitive rightArg = node.arguments[1].definition;
        AbstractConstantValue left = getValue(leftArg);
        AbstractConstantValue right = getValue(rightArg);
        if (lattice.isDefinitelyBool(left) &&
            right.isConstant &&
            right.constant.isTrue) {
          // Replace identical(x, true) by x when x is known to be a boolean.
          // Note that this is not safe if x is null, because the value might
          // not be used as a condition.
          node.replaceUsesWith(leftArg);
        } else if (lattice.isDefinitelyBool(right) &&
            left.isConstant &&
            left.constant.isTrue) {
          node.replaceUsesWith(rightArg);
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
  }

  visitTypeTest(TypeTest node) {
    Primitive prim = node.value.definition;

    Primitive unaryBuiltinOperator(BuiltinOperator operator) =>
        new ApplyBuiltinOperator(
            operator, <Primitive>[prim], node.sourceInformation);

    AbstractConstantValue value = getValue(prim);
    types.DartType dartType = node.dartType;

    if (!(dartType.isInterfaceType && dartType.isRaw)) {
      // TODO(23685): Efficient function arity check.
      // TODO(sra): Pass interceptor to runtime subtype functions.
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
      new LetPrim(nullConst).insertAbove(node.parent);
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
      return null;
    }

    // TODO(sra): If getInterceptor(x) === x or JSNull, rewrite
    //     getInterceptor(x).$isFoo ---> x != null && x.$isFoo
    CpsFragment cps = new CpsFragment(node.sourceInformation);
    Interceptor interceptor =
        cps.letPrim(new Interceptor(prim, node.sourceInformation));
    Primitive testViaFlag =
        cps.letPrim(new TypeTestViaFlag(interceptor, dartType));
    node.replaceUsesWith(testViaFlag);
    return cps;
  }

  Primitive visitTypeTestViaFlag(TypeTestViaFlag node) {
    return null;
  }

  visitBoundsCheck(BoundsCheck node) {
    // Eliminate bounds checks using constant folding.
    // The [BoundsChecker] pass does not try to eliminate checks that could be
    // eliminated by constant folding.
    if (node.hasNoChecks) return;
    int index = lattice.intValue(getValue(node.index.definition));
    int length = node.length == null
        ? null
        : lattice.intValue(getValue(node.length.definition));
    if (index != null && length != null && index < length) {
      node.checks &= ~BoundsCheck.UPPER_BOUND;
    }
    if (index != null && index >= 0) {
      node.checks &= ~BoundsCheck.LOWER_BOUND;
    }
    if (length != null && length > 0) {
      node.checks &= ~BoundsCheck.EMPTINESS;
    }
    if (!node.lengthUsedInCheck && node.length != null) {
      node..length.unlink()..length = null;
    }
    if (node.checks == BoundsCheck.NONE) {
      // We can't remove the bounds check node because it may still be used to
      // restrict code motion.  But the index is no longer needed.
      // TODO(asgerf): Since this was eliminated by constant folding, it should
      //     be safe to remove because any path-sensitive information we relied
      //     upon to do this are expressed by other refinement nodes that also
      //     restrict code motion.  However, if we want to run this pass after
      //     [BoundsChecker] that would not be safe any more, so for now we
      //     keep the node for forward compatibilty.
      node..index.unlink()..index = null;
    }
  }

  visitNullCheck(NullCheck node) {
    if (!getValue(node.value.definition).isNullable) {
      node.replaceUsesWith(node.value.definition);
      return new CpsFragment();
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

  dart2js.Compiler get compiler => backend.compiler;

  World get classWorld => typeSystem.classWorld;

  AbstractConstantValue get nothing => lattice.nothing;

  AbstractConstantValue nonConstant([TypeMask type]) {
    return lattice.nonConstant(type);
  }

  AbstractConstantValue constantValue(ConstantValue constant, [TypeMask type]) {
    return lattice.constant(constant, type);
  }

  // Stores the current lattice value for primitives and mutable variables.
  // Access through [getValue] and [setValue].
  final Map<Variable, ConstantValue> values;

  TypePropagationVisitor(this.lattice,
                         this.values,
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
  AbstractConstantValue getValue(Variable node) {
    ConstantValue constant = values[node];
    if (constant != null) {
      return new AbstractConstantValue.constantValue(constant, node.type);
    }
    if (node.type != null) {
      return new AbstractConstantValue.nonConstant(node.type);
    }
    return lattice.nothing;
  }

  /// Joins the passed lattice [updateValue] to the current value of [node],
  /// and adds it to the definition work set if it has changed and [node] is
  /// a definition.
  void setValue(Variable node, AbstractConstantValue updateValue) {
    AbstractConstantValue oldValue = getValue(node);
    AbstractConstantValue newValue = lattice.join(oldValue, updateValue);
    node.type = newValue.type; // Ensure type is initialized even if bottom.
    if (oldValue == newValue) {
      return;
    }

    // Values may only move in the direction NOTHING -> CONSTANT -> NONCONST.
    assert(newValue.kind >= oldValue.kind);

    values[node] = newValue.isConstant ? newValue.constant : null;
    defWorklist.add(node);
  }

  /// Sets the type of the given primitive.
  ///
  /// If [updateValue] is a constant and [canReplace] is true, the primitive
  /// is also marked as safe for elimination, so it can be constant-folded.
  void setResult(UnsafePrimitive prim,
                 AbstractConstantValue updateValue,
                 {bool canReplace: false}) {
    // TODO(asgerf): Separate constant folding from side effect analysis.
    setValue(prim, updateValue);
    prim.isSafeForElimination = canReplace && updateValue.isConstant;
  }

  bool isInterceptedSelector(Selector selector) {
    return backend.isInterceptedSelector(selector);
  }

  // -------------------------- Visitor overrides ------------------------------
  void visit(Node node) { node.accept(this); }

  void visitFunctionDefinition(FunctionDefinition node) {
    bool isIntercepted = backend.isInterceptedMethod(node.element);

    // If the abstract value of the function parameters is Nothing, use the
    // inferred parameter type.  Otherwise (e.g., when inlining) do not
    // change the abstract value.
    if (node.thisParameter != null && getValue(node.thisParameter).isNothing) {
      if (isIntercepted &&
          typeSystem.methodUsesReceiverArgument(node.element)) {
        setValue(node.thisParameter, nonConstant(typeSystem.nonNullType));
      } else {
        setValue(node.thisParameter,
            nonConstant(typeSystem.getReceiverType(node.element)));
      }
    }
    if (isIntercepted && getValue(node.parameters[0]).isNothing) {
      if (typeSystem.methodUsesReceiverArgument(node.element)) {
        setValue(node.parameters[0],
            nonConstant(typeSystem.getReceiverType(node.element)));
      } else {
        setValue(node.parameters[0], nonConstant());
      }
    }
    bool hasParameterWithoutValue = false;
    for (Parameter param in node.parameters.skip(isIntercepted ? 1 : 0)) {
      if (getValue(param).isNothing) {
        TypeMask type = param.hint is ParameterElement
            ? typeSystem.getParameterType(param.hint)
            : typeSystem.dynamicType;
        setValue(param, lattice.fromMask(type));
        if (type.isEmpty && !type.isNullable) {
          hasParameterWithoutValue = true;
        }
      }
    }
    if (!hasParameterWithoutValue) { // Don't analyze unreachable code.
      push(node.body);
    }
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
    if (node.target == backend.helpers.stringInterpolationHelper) {
      AbstractConstantValue argValue = getValue(node.arguments[0].definition);
      setResult(node, lattice.stringify(argValue), canReplace: true);
      return;
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
      AbstractConstantValue cell = getValue(def);
      setValue(cont.parameters[i], cell);
    }
  }

  void visitInvokeMethod(InvokeMethod node) {
    AbstractConstantValue receiver = getValue(node.dartReceiver);
    node.receiverIsNotNull = receiver.isDefinitelyNotNull;
    if (receiver.isNothing) {
      return setResult(node, lattice.nothing);
    }

    void finish(AbstractConstantValue result, {bool canReplace: false}) {
      if (result == null) {
        canReplace = false;
        result = lattice.getInvokeReturnType(node.selector, receiver);
      }
      setResult(node, result, canReplace: canReplace);
    }

    if (node.selector.isGetter) {
      // Constant fold known length of containers.
      if (node.selector == Selectors.length) {
        if (typeSystem.isDefinitelyIndexable(receiver.type, allowNull: true)) {
          AbstractConstantValue length = lattice.lengthSpecial(receiver);
          return finish(length, canReplace: !receiver.isNullable);
        }
      }
      return finish(null);
    }

    if (node.selector.isCall) {
      if (node.selector == Selectors.codeUnitAt) {
        AbstractConstantValue right = getValue(node.dartArgument(0));
        AbstractConstantValue result =
            lattice.codeUnitAtSpecial(receiver, right);
        return finish(result, canReplace: !receiver.isNullable);
      }
      return finish(null);
    }

    if (node.selector == Selectors.index) {
      AbstractConstantValue right = getValue(node.dartArgument(0));
      AbstractConstantValue result = lattice.indexSpecial(receiver, right);
      return finish(result, canReplace: !receiver.isNullable);
    }

    if (!node.selector.isOperator) {
      return finish(null);
    }

    // Calculate the resulting constant if possible.
    String opname = node.selector.name;
    if (node.arguments.length == 1) {
      // Unary operator.
      if (opname == "unary-") {
        opname = "-";
      }
      UnaryOperator operator = UnaryOperator.parse(opname);
      AbstractConstantValue result = lattice.unaryOp(operator, receiver);
      return finish(result, canReplace: !receiver.isNullable);
    } else if (node.arguments.length == 2) {
      // Binary operator.
      AbstractConstantValue right = getValue(node.dartArgument(0));
      BinaryOperator operator = BinaryOperator.parse(opname);
      AbstractConstantValue result =
          lattice.binaryOp(operator, receiver, right);
      return finish(result, canReplace: !receiver.isNullable);
    }
    return finish(null);
  }

  void visitApplyBuiltinOperator(ApplyBuiltinOperator node) {

    void unaryOp(
        AbstractConstantValue operation(AbstractConstantValue argument),
        TypeMask defaultType) {
      AbstractConstantValue value = getValue(node.arguments[0].definition);
      setValue(node, operation(value) ?? nonConstant(defaultType));
    }

    void binaryOp(
        AbstractConstantValue operation(AbstractConstantValue left,
                                        AbstractConstantValue right),
        TypeMask defaultType) {
      AbstractConstantValue left = getValue(node.arguments[0].definition);
      AbstractConstantValue right = getValue(node.arguments[1].definition);
      setValue(node, operation(left, right) ?? nonConstant(defaultType));
    }

    void binaryNumOp(
        AbstractConstantValue operation(AbstractConstantValue left,
                                        AbstractConstantValue right)) {
      binaryOp(operation, typeSystem.numType);
    }

    void binaryUint32Op(
        AbstractConstantValue operation(AbstractConstantValue left,
                                        AbstractConstantValue right)) {
      binaryOp(operation, typeSystem.uint32Type);
    }

    void binaryBoolOp(
        AbstractConstantValue operation(AbstractConstantValue left,
                                        AbstractConstantValue right)) {
      binaryOp(operation, typeSystem.boolType);
    }

    switch (node.operator) {
      case BuiltinOperator.StringConcatenate:
        ast.DartString stringValue = const ast.LiteralDartString('');
        for (Reference<Primitive> arg in node.arguments) {
          AbstractConstantValue value = getValue(arg.definition);
          if (value.isNothing) {
            setValue(node, lattice.nothing);
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

      case BuiltinOperator.CharCodeAt:
        binaryOp(lattice.codeUnitAtSpecial, typeSystem.uint31Type);
        break;

      case BuiltinOperator.Identical:
      case BuiltinOperator.StrictEq:
      case BuiltinOperator.LooseEq:
        AbstractConstantValue leftConst =
            getValue(node.arguments[0].definition);
        AbstractConstantValue rightConst =
            getValue(node.arguments[1].definition);
        ConstantValue leftValue = leftConst.constant;
        ConstantValue rightValue = rightConst.constant;
        if (leftConst.isNothing || rightConst.isNothing) {
          setValue(node, lattice.nothing);
          return; // And come back later.
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

      case BuiltinOperator.NumBitNot:
        unaryOp(lattice.bitNotSpecial, typeSystem.uint32Type);
        break;

      case BuiltinOperator.NumNegate:
        unaryOp(lattice.negateSpecial, typeSystem.numType);
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
    AbstractConstantValue receiver = getValue(node.receiver.definition);
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
    if (node.allocationSiteType != null) {
      setResult(node, nonConstant(node.allocationSiteType));
    } else {
      setResult(node, nonConstant(typeSystem.getReturnType(node.target)));
    }
  }

  void visitThrow(Throw node) {
  }

  void visitRethrow(Rethrow node) {
  }

  void visitUnreachable(Unreachable node) {
  }

  void visitBranch(Branch node) {
    AbstractConstantValue conditionCell = getValue(node.condition.definition);
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
      Primitive node, AbstractConstantValue input, types.DartType dartType) {
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
    AbstractConstantValue input = getValue(node.value.definition);
    switch (lattice.isSubtypeOf(input, node.dartType, allowNull: true)) {
      case AbstractBool.Nothing:
        setValue(node, lattice.nothing);
        break; // And come back later.

      case AbstractBool.True:
        setValue(node, input);
        break;

      case AbstractBool.False:
        setValue(node, lattice.nothing); // Cast fails.
        break;

      case AbstractBool.Maybe:
        // Narrow type of output to those that survive the cast.
        TypeMask type = input.type.intersection(
            typeSystem.subtypesOf(node.dartType).nullable(),
            classWorld);
        setValue(node, nonConstant(type));
        break;
    }
  }

  void visitSetMutable(SetMutable node) {
    setValue(node.variable.definition, getValue(node.value.definition));
  }

  void visitLiteralList(LiteralList node) {
    if (node.allocationSiteType != null) {
      setValue(node, nonConstant(node.allocationSiteType));
    } else {
      setValue(node, nonConstant(typeSystem.extendableArrayType));
    }
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
    AbstractConstantValue value = getValue(node.input.definition);
    if (value.isNothing) {
      setValue(node, nothing);
    } else if (value.isNullable &&
        !node.interceptedClasses.contains(backend.helpers.jsNullClass)) {
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
    AbstractConstantValue object = getValue(node.object.definition);
    if (object.isNothing || object.isNullConstant) {
      setValue(node, nothing);
      return;
    }
    node.objectIsNotNull = object.isDefinitelyNotNull;
    if (object.isConstant && object.constant.isConstructedObject) {
      ConstructedConstantValue constructedConstant = object.constant;
      ConstantValue value = constructedConstant.fields[node.field];
      if (value != null) {
        setValue(node, constantValue(value));
        return;
      }
    }
    setValue(node, lattice.fromMask(typeSystem.getFieldType(node.field)));
  }

  void visitSetField(SetField node) {}

  void visitCreateBox(CreateBox node) {
    setValue(node, nonConstant(typeSystem.nonNullType));
  }

  void visitCreateInstance(CreateInstance node) {
    setValue(node,
        nonConstant(typeSystem.nonNullExact(node.classElement.declaration)));
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
    setValue(node, nonConstant(node.type));
  }

  @override
  void visitGetLength(GetLength node) {
    AbstractConstantValue input = getValue(node.object.definition);
    node.objectIsNotNull = input.isDefinitelyNotNull;
    AbstractConstantValue length = lattice.lengthSpecial(input);
    if (length != null) {
      // TODO(asgerf): Constant-folding the length might degrade the VM's
      // own bounds-check elimination?
      setValue(node, length);
    } else {
      setValue(node, nonConstant(typeSystem.uint32Type));
    }
  }

  @override
  void visitGetIndex(GetIndex node) {
    AbstractConstantValue object = getValue(node.object.definition);
    if (object.isNothing || object.isNullConstant) {
      setValue(node, nothing);
    } else {
      node.objectIsNotNull = object.isDefinitelyNotNull;
      setValue(node, nonConstant(typeSystem.elementTypeOfIndexable(object.type)));
    }
  }

  @override
  void visitSetIndex(SetIndex node) {}

  @override
  void visitAwait(Await node) {
    setResult(node, nonConstant());
  }

  @override
  visitYield(Yield node) {
    setValue(node, nonConstant());
  }

  @override
  void visitRefinement(Refinement node) {
    AbstractConstantValue value = getValue(node.value.definition);
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

  @override
  void visitBoundsCheck(BoundsCheck node) {
    setValue(node, getValue(node.object.definition));
  }

  @override
  void visitNullCheck(NullCheck node) {
    setValue(node, lattice.nonNullable(getValue(node.value.definition)));
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
class AbstractConstantValue {
  static const int NOTHING  = 0;
  static const int CONSTANT = 1;
  static const int NONCONST = 2;

  final int kind;
  final ConstantValue constant;
  final TypeMask type;

  AbstractConstantValue._internal(this.kind, this.constant, this.type) {
    assert(kind != CONSTANT || constant != null);
    assert(constant is! SyntheticConstantValue);
  }

  AbstractConstantValue.nothing()
      : this._internal(NOTHING, null, new TypeMask.nonNullEmpty());

  AbstractConstantValue.constantValue(ConstantValue constant, TypeMask type)
      : this._internal(CONSTANT, constant, type);

  factory AbstractConstantValue.nonConstant(TypeMask type) {
    if (type.isEmpty) {
      if (type.isNullable)
        return new AbstractConstantValue.constantValue(
            new NullConstantValue(), type);
      else
        return new AbstractConstantValue.nothing();
    } else {
      return new AbstractConstantValue._internal(NONCONST, null, type);
    }
  }

  bool get isNothing  => (kind == NOTHING);
  bool get isConstant => (kind == CONSTANT);
  bool get isNonConst => (kind == NONCONST);
  bool get isNullConstant => kind == CONSTANT && constant.isNull;
  bool get isTrueConstant => kind == CONSTANT && constant.isTrue;
  bool get isFalseConstant => kind == CONSTANT && constant.isFalse;

  bool get isNullable => kind != NOTHING && type.isNullable;
  bool get isDefinitelyNotNull => kind == NOTHING || !type.isNullable;

  int get hashCode {
    int hash = kind * 31 + constant.hashCode * 59 + type.hashCode * 67;
    return hash & 0x3fffffff;
  }

  bool operator ==(AbstractConstantValue that) {
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
