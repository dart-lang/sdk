// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Type flow summary of a member, function or initializer.
library;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart'
    hide Statement, StatementVisitor, MapLiteralEntry;

import 'calls.dart';
import 'types.dart';
import 'utils.dart';

abstract class CallHandler {
  Type applyCall(Call callSite, Selector selector, Args<Type> args,
      {required bool isResultUsed});
  void typeCheckTriggered();
  void addAllocatedClass(Class c);
}

/// Base class for all statements in a summary.
abstract class Statement extends TypeExpr {
  /// Index of this statement in the [Summary].
  int index = -1;
  late Summary summary;

  TypeExpr? condition;

  @override
  Type getComputedType(List<Type?> types) => types[index]!;

  String get label => "t$index";
  String get _conditionSuffix => (condition != null) ? ' {$condition}' : '';

  @override
  String toString() => label;

  /// Prints body of this statement.
  String dump();

  /// Visit this statement by calling a corresponding [visitor] method.
  void accept(StatementVisitor visitor);

  /// Simplifies this statement during summary normalization.
  ///
  /// Returns replacement (Type or one of the arguments), or null if
  /// this statement cannot be replaced.
  TypeExpr? simplify(TypesBuilder typesBuilder) => null;

  /// Execute this statement and compute its resulting type.
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler);
}

/// Statement visitor.
abstract class StatementVisitor {
  void visitParameter(Parameter expr);
  void visitNarrow(Narrow expr);
  void visitJoin(Join expr);
  void visitUse(Use expr);
  void visitCall(Call expr);
  void visitExtract(Extract expr);
  void visitApplyNullability(ApplyNullability expr);
  void visitCreateConcreteType(CreateConcreteType expr);
  void visitCreateRuntimeType(CreateRuntimeType expr);
  void visitTypeCheck(TypeCheck expr);
  void visitUnaryOperation(UnaryOperation expr);
  void visitBinaryOperation(BinaryOperation expr);
  void visitReadVariable(ReadVariable expr);
  void visitWriteVariable(WriteVariable expr);
}

/// Input parameter of the summary.
class Parameter extends Statement {
  final String name;

  // [staticType] is null if no narrowing should be performed. This happens for
  // type parameters and for parameters whose type is narrowed by a [TypeCheck]
  // statement.
  final Type? staticTypeForNarrowing;

  Type? defaultValue;
  Type _argumentType = emptyType;

  Parameter(this.name, this.staticTypeForNarrowing);

  @override
  String get label => "%$name";

  @override
  void accept(StatementVisitor visitor) => visitor.visitParameter(this);

  @override
  String dump() {
    String text = "$label = _Parameter #$index";
    if (staticTypeForNarrowing != null) {
      text += " [$staticTypeForNarrowing]";
    }
    text += _conditionSuffix;
    return text;
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      throw 'Unable to apply _Parameter';

  Type get argumentType => _argumentType;

  void _observeArgumentType(Type argType, TypeHierarchy typeHierarchy) {
    assert(argType.isSpecialized);
    _argumentType = _argumentType.union(argType, typeHierarchy);
    assert(_argumentType.isSpecialized);
  }

  Type _observeNotPassed(TypeHierarchy typeHierarchy) {
    final Type argType = defaultValue!.specialize(typeHierarchy);
    _observeArgumentType(argType, typeHierarchy);
    return argType;
  }
}

/// Narrows down [arg] to [type].
class Narrow extends Statement {
  TypeExpr arg;
  Type type;

  Narrow(this.arg, this.type);

  @override
  void accept(StatementVisitor visitor) => visitor.visitNarrow(this);

  @override
  String dump() => "$label = _Narrow ($arg to $type)$_conditionSuffix";

  @override
  TypeExpr? simplify(TypesBuilder typesBuilder) {
    // This pattern may appear after approximations during summary
    // normalization (so it's not enough to handle it in
    // SummaryCollector._makeNarrow).
    final arg = this.arg;
    if (type is AnyInstanceType) {
      if (arg is Type) {
        return (arg is NullableType) ? arg.baseType : arg;
      }
      if (arg is Call && arg.isInstanceCreation) {
        return arg;
      }
    }
    return null;
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      arg.getComputedType(computedTypes).intersection(type, typeHierarchy);
}

/// A flavor of [Narrow] statement which narrows argument
/// to a non-nullable type and records if argument can be
/// null or not null.
class NarrowNotNull extends Narrow {
  static const int canBeNullFlag = 1 << 0;
  static const int canBeNotNullFlag = 1 << 1;
  int _flags = 0;

  NarrowNotNull(TypeExpr arg) : super(arg, anyInstanceType);

  // Shared NarrowNotNull instances which are used when the outcome is
  // known at summary creation time.
  static final NarrowNotNull alwaysNotNull = NarrowNotNull(emptyType)
    .._flags = canBeNotNullFlag;
  static final NarrowNotNull alwaysNull = NarrowNotNull(emptyType)
    .._flags = canBeNullFlag;
  static final NarrowNotNull unknown = NarrowNotNull(emptyType)
    .._flags = canBeNullFlag | canBeNotNullFlag;

  bool get isAlwaysNull => (_flags & canBeNotNullFlag) == 0;
  bool get isAlwaysNotNull => (_flags & canBeNullFlag) == 0;

  Type handleArgument(Type argType) {
    if (argType is NullableType) {
      final baseType = argType.baseType;
      if (baseType is EmptyType) {
        _flags |= canBeNullFlag;
      } else {
        _flags |= (canBeNullFlag | canBeNotNullFlag);
      }
      return baseType;
    } else {
      _flags |= canBeNotNullFlag;
      return argType;
    }
  }

  @override
  TypeExpr? simplify(TypesBuilder typesBuilder) {
    // This pattern may appear after approximations during summary
    // normalization, so it's not enough to handle it in
    // SummaryCollector._makeNarrowNotNull.
    final arg = this.arg;
    if (arg is Type) {
      return handleArgument(arg);
    }
    return null;
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      handleArgument(arg.getComputedType(computedTypes));
}

/// Joins values from multiple sources. Its type is a union of [values].
class Join extends Statement {
  final String? _name;
  final DartType staticType;
  final List<TypeExpr> values = <TypeExpr>[]; // TODO(alexmarkov): Set

  Join(this._name, this.staticType);

  @override
  String get label => _name ?? super.label;

  @override
  void accept(StatementVisitor visitor) => visitor.visitJoin(this);

  @override
  String dump() => "$label = _Join [${nodeToText(staticType)}]"
      " (${values.join(", ")})$_conditionSuffix";

  @override
  TypeExpr? simplify(TypesBuilder typesBuilder) {
    final values = this.values;
    // Calculate the set of values and remove duplicates and empty types.
    final valuesSet = Set<TypeExpr>();
    int n = values.length;
    int j = 0;
    for (int i = 0; i < n; ++i) {
      final v = values[i];
      if (v is! EmptyType && valuesSet.add(v)) {
        values[j++] = v;
      }
    }
    n = j;
    j = 0;
    // Remove duplicate moves and narrow.
    for (int i = 0; i < n; ++i) {
      final v = values[i];
      bool redundant = false;
      for (TypeExpr e = v;;) {
        TypeExpr arg;
        if (e is UnaryOperation && e.op == UnaryOp.Move) {
          arg = e.arg;
        } else if (e is Narrow) {
          arg = e.arg;
        } else {
          break;
        }
        if (arg is EmptyType || valuesSet.contains(arg)) {
          redundant = true;
          break;
        }
        e = arg;
      }
      if (!redundant) {
        values[j++] = v;
      }
    }
    n = j;
    if (n == 0) {
      return emptyType;
    } else if (n == 1) {
      return values[0];
    }
    values.removeRange(n, values.length);
    return null;
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type? type = null;
    for (var value in values) {
      final valueType = value.getComputedType(computedTypes);
      type = type != null ? type.union(valueType, typeHierarchy) : valueType;
    }
    return type!;
  }
}

/// Artificial use of [arg]. Removed during summary normalization.
class Use extends Statement {
  TypeExpr arg;

  Use(this.arg);

  @override
  void accept(StatementVisitor visitor) => visitor.visitUse(this);

  @override
  String dump() => "$label = _Use ($arg)$_conditionSuffix";

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      throw 'Use statements should be removed during summary normalization';
}

/// Call site.
class Call extends Statement {
  final Selector selector;
  final Args<TypeExpr> args;
  final Type? staticResultType;

  Call(this.selector, this.args, this.staticResultType,
      bool isInstanceCreation) {
    // TODO(sjindel/tfa): Support inferring unchecked entry-points for dynamic
    // and direct calls as well.
    if (selector is DynamicSelector || selector is DirectSelector) {
      setUseCheckedEntry();
    }
    if (isInstanceCreation) {
      setInstanceCreation();
    }
  }

  @override
  void accept(StatementVisitor visitor) => visitor.visitCall(this);

  @override
  String dump() => "$label${isResultUsed ? '*' : ''} = _Call $selector $args"
      "$_conditionSuffix";

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final List<Type> argTypes =
        new List<Type>.filled(args.values.length, emptyType);
    for (int i = 0; i < args.values.length; i++) {
      final Type type = args.values[i].getComputedType(computedTypes);
      if (type == emptyType) {
        debugPrint("Optimized call with empty arg");
        return emptyType;
      }
      argTypes[i] = type;
    }
    setReachable();
    if (selector is! DirectSelector) {
      _observeReceiverType(argTypes[0], typeHierarchy);
    }
    if (isInstanceCreation) {
      callHandler
          .addAllocatedClass((argTypes[0] as ConcreteType).cls.classNode);
    }
    final Stopwatch? timer = kPrintTimings ? (new Stopwatch()..start()) : null;
    Type result = callHandler.applyCall(
        this, selector, new Args<Type>(argTypes, names: args.names),
        isResultUsed: isResultUsed);
    summary.calleeTime += kPrintTimings ? timer!.elapsedMicroseconds : 0;
    if (isInstanceCreation) {
      result = argTypes[0];
    } else if (isResultUsed) {
      final staticResultType = this.staticResultType;
      if (staticResultType != null) {
        result = result.intersection(staticResultType, typeHierarchy);
      }
      result = result.specialize(typeHierarchy);
      _observeResultType(result, typeHierarchy);
    }
    return result;
  }

  // --- Inferred call site information. ---

  int _flags = 0;
  Type _resultType = emptyType;

  static const int kMonomorphic = (1 << 0);
  static const int kPolymorphic = (1 << 1);
  static const int kNullableReceiver = (1 << 2);
  static const int kResultUsed = (1 << 3);
  static const int kReachable = (1 << 4);
  static const int kUseCheckedEntry = (1 << 5);
  static const int kReceiverMayBeInt = (1 << 6);
  static const int kInstanceCreation = (1 << 7);

  Member? _monomorphicTarget;

  Member? get monomorphicTarget => filterArtificialNode(_monomorphicTarget);

  bool get isMonomorphic => (_flags & kMonomorphic) != 0;

  bool get isPolymorphic => (_flags & kPolymorphic) != 0;

  bool get isNullableReceiver => (_flags & kNullableReceiver) != 0;

  bool get isResultUsed => (_flags & kResultUsed) != 0;

  bool get isReachable => (_flags & kReachable) != 0;

  bool get receiverMayBeInt => (_flags & kReceiverMayBeInt) != 0;

  bool get useCheckedEntry => (_flags & kUseCheckedEntry) != 0;

  bool get isInstanceCreation => (_flags & kInstanceCreation) != 0;

  Type get resultType => _resultType;

  void setUseCheckedEntry() {
    _flags |= kUseCheckedEntry;
  }

  void setResultUsed() {
    _flags |= kResultUsed;
  }

  void setReachable() {
    _flags |= kReachable;
  }

  void setInstanceCreation() {
    _flags |= kInstanceCreation;
  }

  void setPolymorphic() {
    _flags = (_flags & ~kMonomorphic) | kPolymorphic;
    _monomorphicTarget = null;
  }

  void addTarget(Member target) {
    if (!isPolymorphic) {
      if (isMonomorphic) {
        if (_monomorphicTarget != target) {
          setPolymorphic();
        }
      } else {
        _flags |= kMonomorphic;
        _monomorphicTarget = target;
      }
    }
  }

  void _observeReceiverType(Type receiver, TypeHierarchy typeHierarchy) {
    if (receiver is NullableType) {
      _flags |= kNullableReceiver;
    }
    final receiverIntIntersect =
        receiver.intersection(typeHierarchy.intType, typeHierarchy);
    if (receiverIntIntersect != emptyType &&
        receiverIntIntersect != nullableEmptyType) {
      _flags |= kReceiverMayBeInt;
    }
  }

  void _observeResultType(Type result, TypeHierarchy typeHierarchy) {
    assert(result.isSpecialized);
    _resultType = _resultType.union(result, typeHierarchy);
    assert(_resultType.isSpecialized);
  }
}

// Extract a type argument from a ConcreteType (used to extract type arguments
// from receivers of methods).
class Extract extends Statement {
  TypeExpr arg;

  final Class referenceClass;
  final int paramIndex;
  final Nullability nullability;

  Extract(this.arg, this.referenceClass, this.paramIndex, this.nullability);

  @override
  void accept(StatementVisitor visitor) => visitor.visitExtract(this);

  @override
  String dump() => "$label = _Extract ($arg[${nodeToText(referenceClass)}"
      "/$paramIndex]${nullability.suffix})$_conditionSuffix";

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type argType = arg.getComputedType(computedTypes);
    Type? extractedType;

    void extractType(ConcreteType c) {
      final typeArgs = c.typeArgs;
      if (typeArgs == null) {
        extractedType = unknownType;
      } else {
        final interfaceOffset = typeHierarchy.genericInterfaceOffsetFor(
            c.cls.classNode, referenceClass);
        final typeArg = typeArgs[interfaceOffset + paramIndex];
        Type extracted = typeArg;
        if (typeArg is RuntimeType) {
          extracted = typeArg.applyNullability(nullability);
        } else {
          assert(typeArg is UnknownType);
        }
        if (extractedType == null || extracted == extractedType) {
          extractedType = extracted;
        } else {
          extractedType = unknownType;
        }
      }
    }

    // TODO(sjindel/tfa): Support more types here if possible.
    if (argType is ConcreteType) {
      extractType(argType);
    } else if (argType is SetType) {
      argType.types.forEach(extractType);
    }

    return extractedType ?? unknownType;
  }
}

// Applies nullability to a given type argument.
class ApplyNullability extends Statement {
  TypeExpr arg;

  final Nullability nullability;

  ApplyNullability(this.arg, this.nullability);

  @override
  void accept(StatementVisitor visitor) => visitor.visitApplyNullability(this);

  @override
  String dump() => "$label = _ApplyNullability ($arg, ${nullability.suffix})"
      "$_conditionSuffix";

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type argType = arg.getComputedType(computedTypes);
    if (argType is RuntimeType) {
      return argType.applyNullability(nullability);
    } else {
      assert(argType is UnknownType);
    }
    return argType;
  }
}

// Instantiate a concrete type with type arguments. For example, used to fill in
// "T = int" in "C<T>" to create "C<int>".
//
// The type arguments are factored against the generic interfaces; for more
// details see 'ClassHierarchyCache.factoredGenericInterfacesOf'.
class CreateConcreteType extends Statement {
  final TFClass cls;
  final List<TypeExpr> flattenedTypeArgs;

  CreateConcreteType(this.cls, this.flattenedTypeArgs);

  @override
  void accept(StatementVisitor visitor) =>
      visitor.visitCreateConcreteType(this);

  @override
  String dump() {
    int numImmediateTypeArgs = cls.classNode.typeParameters.length;
    return "$label = _CreateConcreteType ($cls @ "
        "${flattenedTypeArgs.take(numImmediateTypeArgs)})$_conditionSuffix";
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    bool hasRuntimeType = false;
    final types = List<Type>.generate(flattenedTypeArgs.length, (int i) {
      final computed = flattenedTypeArgs[i].getComputedType(computedTypes);
      assert(computed is RuntimeType || computed is UnknownType);
      if (computed is RuntimeType) hasRuntimeType = true;
      return computed;
    });
    return hasRuntimeType ? ConcreteType(cls, types) : cls.concreteType;
  }
}

// Similar to "CreateConcreteType", but creates a "RuntimeType" rather than a
// "ConcreteType". Unlike a "ConcreteType", none of the type arguments can be
// missing ("UnknownType").
class CreateRuntimeType extends Statement {
  final Class klass;
  final Nullability nullability;
  final List<TypeExpr> flattenedTypeArgs;

  CreateRuntimeType(this.klass, this.nullability, this.flattenedTypeArgs);

  @override
  void accept(StatementVisitor visitor) => visitor.visitCreateRuntimeType(this);

  @override
  String dump() => "$label = _CreateRuntimeType (${nodeToText(klass)} @ "
      "${flattenedTypeArgs.take(klass.typeParameters.length)}"
      "${nullability.suffix})$_conditionSuffix";

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final types = <RuntimeType>[];
    for (TypeExpr arg in flattenedTypeArgs) {
      final computed = arg.getComputedType(computedTypes);
      if (computed is UnknownType) return unknownType;
      if (computed is EmptyType) return emptyType;
      types.add(computed as RuntimeType);
    }
    DartType dartType;
    if (klass == typeHierarchy.coreTypes.deprecatedFutureOrClass) {
      dartType = new FutureOrType(const DynamicType(), nullability);
    } else {
      dartType = new InterfaceType(klass, nullability);
    }
    return RuntimeType(dartType, types);
  }
}

// Used to simulate a runtime type-check, to determine when it can be skipped.
// TODO(sjindel/tfa): Unify with Narrow.
class TypeCheck extends Statement {
  TypeExpr arg;
  TypeExpr type;

  // The Kernel which this TypeCheck corresponds to. Can be a
  // VariableDeclaration, AsExpression or Field.
  //
  // VariableDeclaration is used for parameter type-checks.
  // Field is used for type-checks of parameters to implicit setters.
  final TreeNode node;

  final Type staticType;
  final SubtypeTestKind kind;

  // 'isTestedOnlyOnCheckedEntryPoint' is whether or not this parameter's type-check will
  // occur on the "checked" entrypoint in the VM but will be skipped on
  // "unchecked" entrypoint.
  bool isTestedOnlyOnCheckedEntryPoint;

  bool get isParameterCheck => node is VariableDeclaration;
  VariableDeclaration get parameterVariable => node as VariableDeclaration;

  bool alwaysPass = true;
  bool alwaysFail = true;

  TypeCheck(this.arg, this.type, this.node, this.staticType, this.kind)
      : isTestedOnlyOnCheckedEntryPoint =
            node is VariableDeclaration && !node.isCovariantByDeclaration;

  @override
  void accept(StatementVisitor visitor) => visitor.visitTypeCheck(this);

  @override
  String dump() {
    String result = "$label = _TypeCheck ($arg against $type)";
    result += " (for ${nodeToText(node)})";
    result += _conditionSuffix;
    return result;
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type argType = arg.getComputedType(computedTypes);
    Type checkType = type.getComputedType(computedTypes);
    if (argType is EmptyType || checkType is EmptyType) {
      return emptyType;
    }
    // TODO(sjindel/tfa): Narrow the result if possible.
    assert(checkType is UnknownType || checkType is RuntimeType);

    bool pass = true; // Can this check be skipped on this invocation.

    if (checkType is UnknownType) {
      // If we don't know what the RHS of the check is going to be, we can't
      // guarantee that it will pass.
      pass = false;
    } else if (checkType is RuntimeType) {
      pass = argType.isSubtypeOfRuntimeType(typeHierarchy, checkType, kind);
      argType = argType.intersection(
          typeHierarchy.fromStaticType(checkType.representedTypeRaw, true),
          typeHierarchy);
    } else {
      throw "Cannot see $checkType on RHS of TypeCheck.";
    }

    // If this check might be skipped on an
    // unchecked entry-point, we need to signal that the call-site must be
    // checked.
    if (!pass) {
      alwaysPass = false;
      if (isTestedOnlyOnCheckedEntryPoint) {
        callHandler.typeCheckTriggered();
      }
      if (kPrintTrace) {
        tracePrint("TypeCheck of $argType against $checkType failed.");
      }
    }

    argType = argType
        .intersection(staticType, typeHierarchy)
        .specialize(typeHierarchy);

    if (argType is! EmptyType) {
      alwaysFail = false;
    }

    return argType;
  }
}

enum UnaryOp {
  Move,

  // IsNull(Empty) = Empty
  // IsNull(Nullable(Empty)) = bool(true)
  // IsNull(Nullable(other)) = bool
  // IsNull(other) = bool(false)
  IsNull,

  // IsEmpty(Empty) = bool(true)
  // IsEmpty(other) = bool
  IsEmpty,

  // Not(Empty) = Empty
  // Not(bool(true)) = bool(false)
  // Not(bool(false)) = bool(true)
  // Not(other) = bool
  Not,
}

class UnaryOperation extends Statement {
  final UnaryOp op;
  TypeExpr arg;

  UnaryOperation(this.op, this.arg);

  @override
  void accept(StatementVisitor visitor) => visitor.visitUnaryOperation(this);

  @override
  String dump() => "$label = ${op.name} ($arg)$_conditionSuffix";

  @override
  TypeExpr? simplify(TypesBuilder typesBuilder) {
    if (op == UnaryOp.Move && condition == null) {
      return arg;
    }
    return null;
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final Type arg = this.arg.getComputedType(computedTypes);
    switch (op) {
      case UnaryOp.Move:
        return arg;
      case UnaryOp.IsNull:
        if (arg is EmptyType) {
          return emptyType;
        }
        if (arg is NullableType) {
          if (arg.baseType.specialize(typeHierarchy) is EmptyType) {
            return typeHierarchy.constantTrue;
          }
          return typeHierarchy.boolType;
        } else {
          return typeHierarchy.constantFalse;
        }
      case UnaryOp.IsEmpty:
        return (arg.specialize(typeHierarchy) is EmptyType)
            ? typeHierarchy.constantTrue
            : typeHierarchy.boolType;
      case UnaryOp.Not:
        if (arg is EmptyType) {
          return emptyType;
        }
        if (identical(arg, typeHierarchy.constantTrue)) {
          return typeHierarchy.constantFalse;
        } else if (identical(arg, typeHierarchy.constantFalse)) {
          return typeHierarchy.constantTrue;
        } else {
          return typeHierarchy.boolType;
        }
    }
  }
}

enum BinaryOp {
  // And(Empty, _) = Empty
  // And(bool(false), _) = bool(false)
  // And(bool(true), Empty) = Empty
  // And(bool(true), bool(true)) = bool(true)
  // And(bool(true), bool(false)) = bool(false)
  // And(bool(true), other) = bool
  // And(other, _) = bool
  And,

  // Or(Empty, _) = Empty
  // Or(bool(true), _) = bool(true)
  // Or(bool(false), Empty) = Empty
  // Or(bool(false), bool(true)) = bool(true)
  // Or(bool(false), bool(false)) = bool(false)
  // Or(bool(false), other) = bool
  // Or(other, _) = bool
  Or,
}

class BinaryOperation extends Statement {
  final BinaryOp op;
  TypeExpr arg1;
  TypeExpr arg2;

  BinaryOperation(this.op, this.arg1, this.arg2);

  @override
  void accept(StatementVisitor visitor) => visitor.visitBinaryOperation(this);

  @override
  String dump() => "$label = ${op.name} ($arg1, $arg2)$_conditionSuffix";

  @override
  TypeExpr? simplify(TypesBuilder typesBuilder) {
    final TypeExpr left = arg1;
    switch (op) {
      case BinaryOp.Or:
        if (identical(left, typesBuilder.constantTrue)) {
          return typesBuilder.constantTrue;
        }
        if (identical(left, typesBuilder.constantFalse)) {
          return arg2;
        }
        break;
      case BinaryOp.And:
        if (identical(left, typesBuilder.constantFalse)) {
          return typesBuilder.constantFalse;
        }
        if (identical(left, typesBuilder.constantTrue)) {
          return arg2;
        }
        break;
    }
    return null;
  }

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final Type left = arg1.getComputedType(computedTypes);
    if (left is EmptyType) {
      return emptyType;
    }
    switch (op) {
      case BinaryOp.Or:
        if (identical(left, typeHierarchy.constantTrue)) {
          return typeHierarchy.constantTrue;
        }
        if (identical(left, typeHierarchy.constantFalse)) {
          final Type right = arg2.getComputedType(computedTypes);
          if (right is EmptyType) {
            return emptyType;
          } else if (identical(right, typeHierarchy.constantTrue)) {
            return typeHierarchy.constantTrue;
          } else if (identical(right, typeHierarchy.constantFalse)) {
            return typeHierarchy.constantFalse;
          }
        }
        return typeHierarchy.boolType;
      case BinaryOp.And:
        if (identical(left, typeHierarchy.constantFalse)) {
          return typeHierarchy.constantFalse;
        }
        if (identical(left, typeHierarchy.constantTrue)) {
          final Type right = arg2.getComputedType(computedTypes);
          if (right is EmptyType) {
            return emptyType;
          } else if (identical(right, typeHierarchy.constantTrue)) {
            return typeHierarchy.constantTrue;
          } else if (identical(right, typeHierarchy.constantFalse)) {
            return typeHierarchy.constantFalse;
          }
        }
        return typeHierarchy.boolType;
    }
  }
}

/// Box holding the value of a variable, shared among multiple summaries.
/// Used to represent captured variables.
abstract class SharedVariable {
  Type getValue(TypeHierarchy typeHierarchy, CallHandler callHandler);
  void setValue(
      Type newValue, TypeHierarchy typeHierarchy, CallHandler callHandler);
}

abstract class SharedVariableBuilder {
  /// Returns [SharedVariable] representing captured [variable].
  SharedVariable getSharedVariable(VariableDeclaration variable);
}

/// Reads value from [variable].
class ReadVariable extends Statement {
  final SharedVariable variable;

  ReadVariable(this.variable);

  @override
  void accept(StatementVisitor visitor) => visitor.visitReadVariable(this);

  @override
  String dump() => "$label = read $variable$_conditionSuffix";

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    return variable.getValue(typeHierarchy, callHandler);
  }
}

/// Writes value [arg] to [variable].
class WriteVariable extends Statement {
  final SharedVariable variable;
  TypeExpr arg;

  WriteVariable(this.variable, this.arg);

  @override
  void accept(StatementVisitor visitor) => visitor.visitWriteVariable(this);

  @override
  String dump() => "write $variable = $arg$_conditionSuffix";

  @override
  Type apply(List<Type?> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    variable.setValue(
        arg.getComputedType(computedTypes), typeHierarchy, callHandler);
    return emptyType;
  }
}

/// Summary is a linear sequence of statements representing a type flow in
/// one member, function or initializer.
class Summary {
  final String name;
  int parameterCount;
  int positionalParameterCount;
  int requiredParameterCount;

  List<Statement> _statements = <Statement>[];
  TypeExpr result = emptyType;
  Type resultType = emptyType;

  // Analysis time of callees. Populated only if kPrintTimings.
  int calleeTime = 0;

  Summary(this.name,
      {this.parameterCount = 0,
      this.positionalParameterCount = 0,
      this.requiredParameterCount = 0});

  List<Statement> get statements => _statements;

  Statement add(Statement op) {
    op.index = _statements.length;
    op.summary = this;
    _statements.add(op);
    return op;
  }

  void reset() {
    _statements = <Statement>[];
  }

  @override
  String toString() {
    return _statements.map((op) => op.dump()).join("\n") +
        "\n" +
        "RESULT: ${result}";
  }

  /// Apply this summary to the given arguments and return the resulting type.
  Type apply(Args<Type> arguments, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final Stopwatch? timer = kPrintTimings ? (new Stopwatch()..start()) : null;
    final int oldCalleeTime = calleeTime;
    calleeTime = 0;
    final args = arguments.values;
    final positionalArgCount = arguments.positionalCount;
    final namedArgCount = arguments.namedCount;
    assert(requiredParameterCount <= positionalArgCount);
    assert(positionalArgCount <= positionalParameterCount);
    assert(namedArgCount <= parameterCount - positionalParameterCount);

    // Interpret statements sequentially, calculating the result type
    // of each statement and putting it into the 'types' list parallel
    // to `_statements`.
    //
    // After normalization, statements can only reference preceding statements
    // (they can't have forward references or loops).
    //
    // The first `parameterCount` statements are Parameters.

    List<Type?> types = new List<Type?>.filled(_statements.length, null);

    for (int i = 0; i < positionalArgCount; i++) {
      final Parameter param = _statements[i] as Parameter;
      if (args[i] is RuntimeType) {
        types[i] = args[i];
        continue;
      }
      final argType = args[i].specialize(typeHierarchy);
      param._observeArgumentType(argType, typeHierarchy);
      final staticTypeForNarrowing = param.staticTypeForNarrowing;
      if (staticTypeForNarrowing != null) {
        types[i] = argType.intersection(staticTypeForNarrowing, typeHierarchy);
      } else {
        // Narrowing is performed inside a [TypeCheck] later.
        types[i] = argType;
      }
    }

    for (int i = positionalArgCount; i < positionalParameterCount; i++) {
      types[i] = (_statements[i] as Parameter)._observeNotPassed(typeHierarchy);
    }

    final argNames = arguments.names;
    int argIndex = 0;
    for (int i = positionalParameterCount; i < parameterCount; i++) {
      final Parameter param = _statements[i] as Parameter;
      assert(param.defaultValue != null);
      if ((argIndex < namedArgCount) && (argNames[argIndex] == param.name)) {
        final argType =
            args[positionalArgCount + argIndex].specialize(typeHierarchy);
        argIndex++;
        param._observeArgumentType(argType, typeHierarchy);
        final staticTypeForNarrowing = param.staticTypeForNarrowing;
        if (staticTypeForNarrowing != null) {
          types[i] =
              argType.intersection(staticTypeForNarrowing, typeHierarchy);
        } else {
          types[i] = argType;
        }
      } else {
        assert((argIndex == namedArgCount) ||
            (param.name.compareTo(argNames[argIndex]) < 0));
        types[i] = param._observeNotPassed(typeHierarchy);
      }
    }
    assert(argIndex == namedArgCount);

    for (int i = parameterCount; i < _statements.length; i++) {
      final statement = _statements[i];
      // Test if tracing is enabled to avoid expensive message formatting.
      if (kPrintTrace) {
        tracePrint("EVAL ${statement.dump()}");
      }
      final condition = statement.condition;
      if (condition != null) {
        final cval = condition.getComputedType(types);
        if (cval is EmptyType || identical(cval, typeHierarchy.constantFalse)) {
          types[i] = emptyType;
          if (kPrintTrace) {
            tracePrint("Skipped statement");
          }
          continue;
        }
      }
      types[i] = statement.apply(types, typeHierarchy, callHandler);
      if (kPrintTrace) {
        tracePrint("RESULT ${types[i]}");
      }
    }

    Statistics.summariesAnalyzed++;

    Type computedType = result.getComputedType(types);
    resultType = resultType.union(computedType, typeHierarchy);

    if (kPrintTimings) {
      final dirtyTime = timer!.elapsedMicroseconds;
      final pureTime = dirtyTime < calleeTime ? 0 : (dirtyTime - calleeTime);
      Statistics.numSummaryApplications.add(name);
      Statistics.dirtySummaryAnalysisTime.add(name, dirtyTime);
      Statistics.pureSummaryAnalysisTime.add(name, pureTime);
    }
    calleeTime = oldCalleeTime;

    return computedType;
  }

  Args<Type> get argumentTypes {
    final argTypes = new List<Type>.filled(parameterCount, emptyType);
    final argNames =
        new List<String>.filled(parameterCount - positionalParameterCount, '');
    for (int i = 0; i < parameterCount; i++) {
      Parameter param = _statements[i] as Parameter;
      argTypes[i] = param.argumentType;
      if (i >= positionalParameterCount) {
        argNames[i - positionalParameterCount] = param.name;
      }
    }
    return new Args<Type>(argTypes, names: argNames);
  }

  Type argumentType(Member member, VariableDeclaration memberParam) {
    final int firstParamIndex =
        numTypeParams(member) + (hasReceiverArg(member) ? 1 : 0);
    final positional = member.function!.positionalParameters;
    for (int i = 0; i < positional.length; i++) {
      if (positional[i] == memberParam) {
        final Parameter param = _statements[firstParamIndex + i] as Parameter;
        assert(param.name == memberParam.name);
        return param.argumentType;
      }
    }
    for (int i = positionalParameterCount; i < parameterCount; i++) {
      final Parameter param = _statements[i] as Parameter;
      if (param.name == memberParam.name) {
        return param.argumentType;
      }
    }
    throw "Could not find argument type of parameter ${memberParam.name}";
  }

  List<VariableDeclaration> get uncheckedParameters {
    final params = <VariableDeclaration>[];
    for (Statement statement in _statements) {
      if (statement is TypeCheck &&
          statement.alwaysPass &&
          statement.isParameterCheck) {
        params.add(statement.parameterVariable);
      }
    }
    return params;
  }

  /// Update the summary parameters to reflect a signature change with moved
  /// and/or removed parameters.
  void adjustFunctionParameters(Member member) {
    // Just keep the parameters part of the summary, assuming that the rest is
    // not used in later phases. The index values in the statements will be
    // incorrect, but those are assumed to be not used either.
    final int implicit =
        (hasReceiverArg(member) ? 1 : 0) + numTypeParams(member);
    final Map<String, Parameter> paramsByName = {};
    for (int i = implicit; i < parameterCount; i++) {
      final Parameter param = statements[i] as Parameter;
      paramsByName[param.name] = param;
    }
    FunctionNode function = member.function!;
    statements.length = implicit;
    for (VariableDeclaration param in function.positionalParameters) {
      statements.add(paramsByName[param.name]!);
    }
    positionalParameterCount = statements.length;
    for (VariableDeclaration param in function.namedParameters) {
      statements.add(paramsByName[param.name]!);
    }
    parameterCount = statements.length;
    requiredParameterCount = implicit + function.requiredParameterCount;
  }
}
