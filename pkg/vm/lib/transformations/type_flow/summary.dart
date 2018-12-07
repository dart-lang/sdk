// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Type flow summary of a member, function or initializer.
library vm.transformations.type_flow.summary;

import 'dart:core' hide Type;

import 'package:kernel/ast.dart' hide Statement, StatementVisitor;

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
    assertx(type != null);
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
    assertx(argType.isSpecialized);
    _argumentType = _argumentType.union(argType, typeHierarchy);
    assertx(_argumentType.isSpecialized);
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
  String dump() => "$label = _Join [$staticType] (${values.join(", ")})";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type type = null;
    assertx(values.isNotEmpty);
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

  Call(this.selector, this.args) {
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
    final List<Type> argTypes = new List<Type>(args.values.length);
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
      _observeReceiverType(argTypes[0]);
    }
    Type result = callHandler.applyCall(
        this, selector, new Args<Type>(argTypes, names: args.names),
        isResultUsed: isResultUsed);
    if (isResultUsed) {
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

  Member _monomorphicTarget;

  Member get monomorphicTarget => _monomorphicTarget;

  bool get isMonomorphic => (_flags & kMonomorphic) != 0;

  bool get isPolymorphic => (_flags & kPolymorphic) != 0;

  bool get isNullableReceiver => (_flags & kNullableReceiver) != 0;

  bool get isResultUsed => (_flags & kResultUsed) != 0;

  bool get isReachable => (_flags & kReachable) != 0;

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

  void _observeReceiverType(Type receiver) {
    if (receiver is NullableType) {
      _flags |= kNullableReceiver;
    }
  }

  void _observeResultType(Type result, TypeHierarchy typeHierarchy) {
    assertx(result.isSpecialized);
    _resultType = _resultType.union(result, typeHierarchy);
    assertx(_resultType.isSpecialized);
  }
}

// Extract a type argument from a ConcreteType (used to extract type arguments
// from receivers of methods).
class Extract extends Statement {
  TypeExpr arg;

  final Class referenceClass;
  final int paramIndex;

  Extract(this.arg, this.referenceClass, this.paramIndex);

  @override
  void accept(StatementVisitor visitor) => visitor.visitExtract(this);

  @override
  String dump() => "$label = _Extract ($arg[$referenceClass/$paramIndex])";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type argType = arg.getComputedType(computedTypes);
    Type extractedType;

    void extractType(ConcreteType c) {
      if (c.typeArgs == null) {
        extractedType = const AnyType();
      } else {
        final interfaceOffset = typeHierarchy.genericInterfaceOffsetFor(
            c.classNode, referenceClass);
        final extract = c.typeArgs[interfaceOffset + paramIndex];
        assertx(extract is AnyType || extract is RuntimeType);
        if (extractedType == null || extract == extractedType) {
          extractedType = extract;
        } else {
          extractedType = const AnyType();
        }
      }
    }

    // TODO(sjindel/tfa): Support more types here if possible.
    if (argType is ConcreteType) {
      extractType(argType);
    } else if (argType is SetType) {
      argType.types.forEach(extractType);
    }

    return extractedType ?? const AnyType();
  }
}

// Instantiate a concrete type with type arguments. For example, used to fill in
// "T = int" in "C<T>" to create "C<int>".
//
// The type arguments are factored against the generic interfaces; for more
// details see 'ClassHierarchyCache.factoredGenericInterfacesOf'.
class CreateConcreteType extends Statement {
  final ConcreteType type;
  final List<TypeExpr> flattenedTypeArgs;

  CreateConcreteType(this.type, this.flattenedTypeArgs);

  @override
  void accept(StatementVisitor visitor) =>
      visitor.visitCreateConcreteType(this);

  @override
  String dump() {
    int numImmediateTypeArgs = type.classNode.typeParameters.length;
    return "$label = _CreateConcreteType (${type.classNode} @ "
        "${flattenedTypeArgs.take(numImmediateTypeArgs)})";
  }

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    bool hasRuntimeType = false;
    final types = new List<Type>(flattenedTypeArgs.length);
    for (int i = 0; i < types.length; ++i) {
      final computed = flattenedTypeArgs[i].getComputedType(computedTypes);
      assertx(computed is RuntimeType || computed is AnyType);
      if (computed is RuntimeType) hasRuntimeType = true;
      types[i] = computed;
    }
    return new ConcreteType(
        type.classId, type.classNode, hasRuntimeType ? types : null);
  }
}

// Similar to "CreateConcreteType", but creates a "RuntimeType" rather than a
// "ConcreteType". Unlike a "ConcreteType", none of the type arguments can be
// missing ("AnyType").
class CreateRuntimeType extends Statement {
  final Class klass;
  final List<TypeExpr> flattenedTypeArgs;

  CreateRuntimeType(this.klass, this.flattenedTypeArgs);

  @override
  void accept(StatementVisitor visitor) => visitor.visitCreateRuntimeType(this);

  @override
  String dump() => "$label = _CreateRuntimeType ($klass @ "
      "${flattenedTypeArgs.take(klass.typeParameters.length)})";

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    final types = new List<RuntimeType>(flattenedTypeArgs.length);
    for (int i = 0; i < types.length; ++i) {
      final computed = flattenedTypeArgs[i].getComputedType(computedTypes);
      assertx(computed is RuntimeType || computed is AnyType);
      if (computed is AnyType) return const AnyType();
      types[i] = computed;
    }
    return new RuntimeType(new InterfaceType(klass), types);
  }
}

// Used to simulate a runtime type-check, to determine when it can be skipped.
// TODO(sjindel/tfa): Unify with Narrow.
class TypeCheck extends Statement {
  TypeExpr arg;
  TypeExpr type;

  final VariableDeclaration parameter;

  TypeCheck(this.arg, this.type, this.parameter);

  @override
  void accept(StatementVisitor visitor) => visitor.visitTypeCheck(this);

  @override
  String dump() {
    String result = "$label = _TypeCheck ($arg against $type)";
    if (parameter != null) {
      result += " (for parameter ${parameter.name})";
    }
    return result;
  }

  @override
  Type apply(List<Type> computedTypes, TypeHierarchy typeHierarchy,
      CallHandler callHandler) {
    Type argType = arg.getComputedType(computedTypes);
    Type checkType = type.getComputedType(computedTypes);
    // TODO(sjindel/tfa): Narrow the result if possible.
    assertx(checkType is AnyType || checkType is RuntimeType);

    if (checkType is AnyType) {
      // If we don't know what the RHS of the check is going to be, we can't
      // guarantee that it will pass.
      callHandler.typeCheckTriggered();
      if (kPrintTrace) {
        tracePrint("TypeCheck failed, type is unknown");
      }
    } else if (checkType is RuntimeType) {
      final bool canSkip =
          argType.isSubtypeOfRuntimeType(typeHierarchy, checkType);
      if (!canSkip) {
        callHandler.typeCheckTriggered();
        if (kPrintTrace) {
          tracePrint("TypeCheck of $argType against $checkType failed.");
        }
      }
      argType = argType.intersection(
          Type.fromStatic(checkType.representedTypeRaw), typeHierarchy);
    } else {
      assertx(false, details: "Cannot see $checkType on RHS of TypeCheck.");
    }

    if (parameter != null) {
      argType =
          argType.intersection(Type.fromStatic(parameter.type), typeHierarchy);
    }

    return argType;
  }
}

/// Summary is a linear sequence of statements representing a type flow in
/// one member, function or initializer.
class Summary {
  final int parameterCount;
  final int positionalParameterCount;
  final int requiredParameterCount;

  List<Statement> _statements = <Statement>[];
  TypeExpr result = null;

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
    assertx(requiredParameterCount <= positionalArgCount);
    assertx(positionalArgCount <= positionalParameterCount);
    assertx(namedArgCount <= parameterCount - positionalParameterCount);

    // Interpret statements sequentially, calculating the result type
    // of each statement and putting it into the 'types' list parallel
    // to `_statements`.
    //
    // After normalization, statements can only reference preceding statements
    // (they can't have forward references or loops).
    //
    // The first `parameterCount` statements are Parameters.

    List<Type> types = new List<Type>(_statements.length);

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
      final Parameter param = _statements[i] as Parameter;
      final argType = param.defaultValue.specialize(typeHierarchy);
      param._observeArgumentType(argType, typeHierarchy);
      types[i] = argType;
    }

    final argNames = arguments.names;
    int argIndex = 0;
    for (int i = positionalParameterCount; i < parameterCount; i++) {
      final Parameter param = _statements[i] as Parameter;
      assertx(param.defaultValue != null);
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
        assertx((argIndex == namedArgCount) ||
            (param.name.compareTo(argNames[argIndex]) < 0));
        final argType = param.defaultValue.specialize(typeHierarchy);
        param._observeArgumentType(argType, typeHierarchy);
        types[i] = argType;
      }
    }
    assertx(argIndex == namedArgCount);

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

    return result.getComputedType(types);
  }

  Args<Type> get argumentTypes {
    final argTypes = new List<Type>(parameterCount);
    final argNames =
        new List<String>(parameterCount - positionalParameterCount);
    for (int i = 0; i < parameterCount; i++) {
      Parameter param = _statements[i] as Parameter;
      argTypes[i] = param.argumentType;
      if (i >= positionalParameterCount) {
        argNames[i - positionalParameterCount] = param.name;
      }
    }
    return new Args<Type>(argTypes, names: argNames);
  }
}
