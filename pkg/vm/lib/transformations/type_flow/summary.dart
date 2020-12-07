// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Type flow summary of a member, function or initializer.
library vm.transformations.type_flow.summary;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart' hide Statement, StatementVisitor, MapEntry;

import 'calls.dart';
import 'types.dart';
import 'utils.dart';

abstract class CallHandler {
  Type applyCall(Call callSite, Selector selector, Args<Type> args,
      {bool isResultUsed});
  void typeCheckTriggered();
}

/// Base class for all statements in a summary.
abstract class Statement extends TypeExpr {
  /// Index of this statement in the [Summary].
  int index = -1;

  @override
  Type getComputedType(List<Type> types) {
    final type = types[index];
    assert(type != null);
    return type;
  }

  String get label => "t$index";

  @override
  String toString() => label;

  /// Prints body of this statement.
  String dump();

  /// Visit this statement by calling a corresponding [visitor] method.
  void accept(StatementVisitor visitor);

  /// Execute this statement and compute its resulting type.
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler);
}

/// Statement visitor.
class StatementVisitor {
  void visitDefault(TypeExpr expr) {}

  void visitParameter(Parameter expr) => visitDefault(expr);
  void visitNarrow(Narrow expr) => visitDefault(expr);
  void visitJoin(Join expr) => visitDefault(expr);
  void visitUse(Use expr) => visitDefault(expr);
  void visitCall(Call expr) => visitDefault(expr);
  void visitExtract(Extract expr) => visitDefault(expr);
  void visitCreateConcreteType(CreateConcreteType expr) => visitDefault(expr);
  void visitCreateRuntimeType(CreateRuntimeType expr) => visitDefault(expr);
  void visitTypeCheck(TypeCheck expr) => visitDefault(expr);
}

/// Input parameter of the summary.
class Parameter extends Statement {
  final String name;

  // [staticType] is null if no narrowing should be performed. This happens for
  // type parameters and for parameters whose type is narrowed by a [TypeCheck]
  // statement.
  final Type staticTypeForNarrowing;

  Type defaultValue;
  Type _argumentType = const EmptyType();

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
    return text;
  }

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      throw 'Unable to apply _Parameter';

  Type get argumentType => _argumentType;

  void _observeArgumentType(Type argType, TypeHierarchy typeHierarchy) {
    assert(argType.isSpecialized);
    _argumentType = _argumentType.union(argType, typeHierarchy);
    assert(_argumentType.isSpecialized);
  }

  Type _observeNotPassed(TypeHierarchy typeHierarchy) {
    final Type argType = defaultValue.specialize(typeHierarchy);
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
  String dump() => "$label = _Narrow ($arg to $type)";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
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

  NarrowNotNull(TypeExpr arg) : super(arg, const AnyType());

  // Shared NarrowNotNull instances which are used when the outcome is
  // known at summary creation time.
  static final NarrowNotNull alwaysNotNull = NarrowNotNull(null)
    .._flags = canBeNotNullFlag;
  static final NarrowNotNull alwaysNull = NarrowNotNull(null)
    .._flags = canBeNullFlag;
  static final NarrowNotNull unknown = NarrowNotNull(null)
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
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      handleArgument(arg.getComputedType(computedTypes));
}

/// Joins values from multiple sources. Its type is a union of [values].
class Join extends Statement {
  final String _name;
  final DartType staticType;
  final List<TypeExpr> values = <TypeExpr>[]; // TODO(alexmarkov): Set

  Join(this._name, this.staticType);

  @override
  String get label => _name ?? super.label;

  @override
  void accept(StatementVisitor visitor) => visitor.visitJoin(this);

  @override
  String dump() => "$label = _Join [${nodeToText(staticType)}]"
      " (${values.join(", ")})";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type type = null;
    assert(values.isNotEmpty);
    for (var value in values) {
      final valueType = value.getComputedType(computedTypes);
      type = type != null ? type.union(valueType, typeHierarchy) : valueType;
    }
    return type;
  }
}

/// Artificial use of [arg]. Removed during summary normalization.
class Use extends Statement {
  TypeExpr arg;

  Use(this.arg);

  @override
  void accept(StatementVisitor visitor) => visitor.visitUse(this);

  @override
  String dump() => "$label = _Use ($arg)";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
          CallHandler callHandler) =>
      throw 'Use statements should be removed during summary normalization';
}

/// Call site.
class Call extends Statement {
  final Selector selector;
  final Args<TypeExpr> args;
  final Type staticResultType;

  Call(this.selector, this.args, this.staticResultType) {
    // TODO(sjindel/tfa): Support inferring unchecked entry-points for dynamic
    // and direct calls as well.
    if (selector is DynamicSelector || selector is DirectSelector) {
      setUseCheckedEntry();
    }
  }

  @override
  void accept(StatementVisitor visitor) => visitor.visitCall(this);

  @override
  String dump() => "$label${isResultUsed ? '*' : ''} = _Call $selector $args";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final List<Type> argTypes = new List<Type>.filled(args.values.length, null);
    for (int i = 0; i < args.values.length; i++) {
      final Type type = args.values[i].getComputedType(computedTypes);
      if (type == const EmptyType()) {
        debugPrint("Optimized call with empty arg");
        return const EmptyType();
      }
      argTypes[i] = type;
    }
    setReachable();
    if (selector is! DirectSelector) {
      _observeReceiverType(argTypes[0], typeHierarchy);
    }
    Type result = callHandler.applyCall(
        this, selector, new Args<Type>(argTypes, names: args.names),
        isResultUsed: isResultUsed);
    if (isResultUsed) {
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
  Type _resultType = const EmptyType();

  static const int kMonomorphic = (1 << 0);
  static const int kPolymorphic = (1 << 1);
  static const int kNullableReceiver = (1 << 2);
  static const int kResultUsed = (1 << 3);
  static const int kReachable = (1 << 4);
  static const int kUseCheckedEntry = (1 << 5);
  static const int kReceiverMayBeInt = (1 << 6);

  Member _monomorphicTarget;

  Member get monomorphicTarget => _monomorphicTarget;

  bool get isMonomorphic => (_flags & kMonomorphic) != 0;

  bool get isPolymorphic => (_flags & kPolymorphic) != 0;

  bool get isNullableReceiver => (_flags & kNullableReceiver) != 0;

  bool get isResultUsed => (_flags & kResultUsed) != 0;

  bool get isReachable => (_flags & kReachable) != 0;

  bool get receiverMayBeInt => (_flags & kReceiverMayBeInt) != 0;

  bool get useCheckedEntry => (_flags & kUseCheckedEntry) != 0;

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
    if (receiverIntIntersect != EmptyType() &&
        receiverIntIntersect != NullableType(EmptyType())) {
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
      "/$paramIndex]${nullability.suffix})";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type argType = arg.getComputedType(computedTypes);
    Type extractedType;

    void extractType(ConcreteType c) {
      if (c.typeArgs == null) {
        extractedType = const UnknownType();
      } else {
        final interfaceOffset = typeHierarchy.genericInterfaceOffsetFor(
            c.cls.classNode, referenceClass);
        final typeArg = c.typeArgs[interfaceOffset + paramIndex];
        Type extracted = typeArg;
        if (typeArg is RuntimeType) {
          final argNullability = typeArg.nullability;
          if (argNullability != nullability) {
            // Apply nullability of type parameter type.
            Nullability result;
            if (argNullability == Nullability.nullable ||
                nullability == Nullability.nullable) {
              result = Nullability.nullable;
            } else if (argNullability == Nullability.legacy ||
                nullability == Nullability.legacy) {
              result = Nullability.legacy;
            } else {
              result = Nullability.nonNullable;
            }
            if (argNullability != result) {
              extracted = typeArg.withNullability(result);
            }
          }
        } else {
          assert(typeArg is UnknownType);
        }
        if (extractedType == null || extracted == extractedType) {
          extractedType = extracted;
        } else {
          extractedType = const UnknownType();
        }
      }
    }

    // TODO(sjindel/tfa): Support more types here if possible.
    if (argType is ConcreteType) {
      extractType(argType);
    } else if (argType is SetType) {
      argType.types.forEach(extractType);
    }

    return extractedType ?? const UnknownType();
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
        "${flattenedTypeArgs.take(numImmediateTypeArgs)})";
  }

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    bool hasRuntimeType = false;
    final types = new List<Type>.filled(flattenedTypeArgs.length, null);
    for (int i = 0; i < types.length; ++i) {
      final computed = flattenedTypeArgs[i].getComputedType(computedTypes);
      assert(computed is RuntimeType || computed is UnknownType);
      if (computed is RuntimeType) hasRuntimeType = true;
      types[i] = computed;
    }
    return new ConcreteType(cls, hasRuntimeType ? types : null);
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
      "${nullability.suffix})";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final types = new List<RuntimeType>.filled(flattenedTypeArgs.length, null);
    for (int i = 0; i < types.length; ++i) {
      final computed = flattenedTypeArgs[i].getComputedType(computedTypes);
      assert(computed is RuntimeType || computed is UnknownType);
      if (computed is UnknownType) return const UnknownType();
      types[i] = computed;
    }
    DartType dartType;
    if (klass == typeHierarchy.coreTypes.deprecatedFutureOrClass) {
      dartType = new FutureOrType(const DynamicType(), nullability);
    } else {
      dartType = new InterfaceType(klass, nullability);
    }
    return new RuntimeType(dartType, types);
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

  // 'isTestedOnlyOnCheckedEntryPoint' is whether or not this parameter's type-check will
  // occur on the "checked" entrypoint in the VM but will be skipped on
  // "unchecked" entrypoint.
  bool isTestedOnlyOnCheckedEntryPoint;

  VariableDeclaration get parameter =>
      node is VariableDeclaration ? node : null;

  bool canAlwaysSkip = true;

  TypeCheck(this.arg, this.type, this.node, this.staticType) {
    assert(node != null);
    isTestedOnlyOnCheckedEntryPoint =
        parameter != null && !parameter.isCovariant;
  }

  @override
  void accept(StatementVisitor visitor) => visitor.visitTypeCheck(this);

  @override
  String dump() {
    String result = "$label = _TypeCheck ($arg against $type)";
    result += " (for ${nodeToText(node)})";
    return result;
  }

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type argType = arg.getComputedType(computedTypes);
    Type checkType = type.getComputedType(computedTypes);
    // TODO(sjindel/tfa): Narrow the result if possible.
    assert(checkType is UnknownType || checkType is RuntimeType);

    bool canSkip = true; // Can this check be skipped on this invocation.

    if (checkType is UnknownType) {
      // If we don't know what the RHS of the check is going to be, we can't
      // guarantee that it will pass.
      canSkip = false;
    } else if (checkType is RuntimeType) {
      canSkip = argType.isSubtypeOfRuntimeType(typeHierarchy, checkType);
      argType = argType.intersection(
          typeHierarchy.fromStaticType(checkType.representedTypeRaw, true),
          typeHierarchy);
    } else {
      throw "Cannot see $checkType on RHS of TypeCheck.";
    }

    // If this check might be skipped on an
    // unchecked entry-point, we need to signal that the call-site must be
    // checked.
    if (!canSkip) {
      canAlwaysSkip = false;
      if (isTestedOnlyOnCheckedEntryPoint) {
        callHandler.typeCheckTriggered();
      }
      if (kPrintTrace) {
        tracePrint("TypeCheck of $argType against $checkType failed.");
      }
    }

    argType = argType.intersection(staticType, typeHierarchy);

    return argType;
  }
}

/// Summary is a linear sequence of statements representing a type flow in
/// one member, function or initializer.
class Summary {
  int parameterCount;
  int positionalParameterCount;
  int requiredParameterCount;

  List<Statement> _statements = <Statement>[];
  TypeExpr result = null;
  Type resultType = EmptyType();

  Summary(
      {this.parameterCount: 0,
      this.positionalParameterCount: 0,
      this.requiredParameterCount: 0});

  List<Statement> get statements => _statements;

  Statement add(Statement op) {
    op.index = _statements.length;
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

    List<Type> types = new List<Type>.filled(_statements.length, null);

    for (int i = 0; i < positionalArgCount; i++) {
      final Parameter param = _statements[i] as Parameter;
      if (args[i] is RuntimeType) {
        types[i] = args[i];
        continue;
      }
      final argType = args[i].specialize(typeHierarchy);
      param._observeArgumentType(argType, typeHierarchy);
      if (param.staticTypeForNarrowing != null) {
        types[i] =
            argType.intersection(param.staticTypeForNarrowing, typeHierarchy);
      } else {
        // TODO(sjindel/tfa): Narrowing is performed inside a [TypeCheck] later.
        types[i] = args[i];
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
        if (param.staticTypeForNarrowing != null) {
          types[i] =
              argType.intersection(param.staticTypeForNarrowing, typeHierarchy);
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
      // Test if tracing is enabled to avoid expensive message formatting.
      if (kPrintTrace) {
        tracePrint("EVAL ${_statements[i].dump()}");
      }
      types[i] = _statements[i].apply(types, typeHierarchy, callHandler);
      if (kPrintTrace) {
        tracePrint("RESULT ${types[i]}");
      }
    }

    Statistics.summariesAnalyzed++;

    Type computedType = result.getComputedType(types);
    resultType = resultType.union(computedType, typeHierarchy);
    return computedType;
  }

  Args<Type> get argumentTypes {
    final argTypes = new List<Type>.filled(parameterCount, null);
    final argNames = new List<String>.filled(
        parameterCount - positionalParameterCount, null);
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
    final positional = member.function.positionalParameters;
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
          statement.canAlwaysSkip &&
          statement.parameter != null) {
        params.add(statement.parameter);
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
      final Parameter param = statements[i];
      paramsByName[param.name] = param;
    }
    FunctionNode function = member.function;
    statements.length = implicit;
    for (VariableDeclaration param in function.positionalParameters) {
      statements.add(paramsByName[param.name]);
    }
    positionalParameterCount = statements.length;
    for (VariableDeclaration param in function.namedParameters) {
      statements.add(paramsByName[param.name]);
    }
    parameterCount = statements.length;
    requiredParameterCount = implicit + function.requiredParameterCount;
  }
}
