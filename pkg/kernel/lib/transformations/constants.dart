// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.constants;

import '../kernel.dart';
import '../ast.dart';
import '../type_algebra.dart';
import 'treeshaker.dart' show findNativeName;

Program transformProgram(Program program, ConstantsBackend backend,
    {bool keepFields: false}) {
  transformLibraries(program.libraries, backend, keepFields: keepFields);
  return program;
}

void transformLibraries(List<Library> libraries, ConstantsBackend backend,
    {bool keepFields: false, bool keepVariables: false}) {
  final ConstantsTransformer constantsTransformer =
      new ConstantsTransformer(backend, keepFields, keepVariables);
  for (final Library library in libraries) {
    for (final Field field in library.fields.toList()) {
      constantsTransformer.convertField(field);
    }
    for (final Procedure procedure in library.procedures) {
      constantsTransformer.convertProcedure(procedure);
    }
    for (final Class klass in library.classes) {
      constantsTransformer.convertClassAnnotations(klass);

      for (final Field field in klass.fields.toList()) {
        constantsTransformer.convertField(field);
      }
      for (final Procedure procedure in klass.procedures) {
        constantsTransformer.convertProcedure(procedure);
      }
      for (final Constructor constructor in klass.constructors) {
        constantsTransformer.convertConstructor(constructor);
      }
    }
  }
}

class ConstantsTransformer extends Transformer {
  final ConstantEvaluator constantEvaluator;

  /// Whether to preserve constant [Field]s.  All use-sites will be rewritten.
  final bool keepFields;
  final bool keepVariables;

  ConstantsTransformer(
      ConstantsBackend backend, this.keepFields, this.keepVariables)
      : constantEvaluator = new ConstantEvaluator(backend);

  // Transform the library/class members:

  void convertClassAnnotations(Class klass) {
    constantEvaluator.withNewEnvironment(() {
      transformList(klass.annotations, this, klass);
    });
  }

  void convertProcedure(Procedure procedure) {
    constantEvaluator.withNewEnvironment(() {
      procedure.accept(this);
    });
  }

  void convertConstructor(Constructor constructor) {
    constantEvaluator.withNewEnvironment(() {
      constructor.accept(this);
    });
  }

  void convertField(Field field) {
    constantEvaluator.withNewEnvironment(() {
      if (field.accept(this) == null) field.remove();
    });
  }

  // Handle definition of constants:

  visitVariableDeclaration(VariableDeclaration node) {
    if (node.isConst) {
      final Constant constant = constantEvaluator.evaluate(node.initializer);
      constantEvaluator.env.addVariableValue(node, constant);

      if (keepVariables) {
        // So the value of the variable is still available for debugging
        // purposes we convert the constant variable to be a final variable
        // initialized to the evaluated constant expression.
        node.initializer = new ConstantExpression(constant)..parent = node;
        node.isFinal = true;
        node.isConst = false;
      } else {
        // Since we convert all use-sites of constants, the constant
        // [VariableDeclaration] is unused and we'll therefore remove it.
        return null;
      }
    }
    return super.visitVariableDeclaration(node);
  }

  visitField(Field node) {
    if (node.isConst) {
      // Since we convert all use-sites of constants, the constant [Field]
      // cannot be referenced anymore.  We therefore get rid of it if
      // [keepFields] was not specified.
      if (!keepFields) return null;

      // Otherwise we keep the constant [Field] and convert it's initializer.
      if (node.initializer != null) {
        final Constant constant = constantEvaluator.evaluate(node.initializer);
        node.initializer = new ConstantExpression(constant)..parent = node;
      }
      return node;
    }
    return super.visitField(node);
  }

  // Handle use-sites of constants (and "inline" constant expressions):

  visitStaticGet(StaticGet node) {
    final Member target = node.target;
    if (target is Field && target.isConst) {
      final Constant constant = constantEvaluator.evaluate(target.initializer);
      return new ConstantExpression(constant);
    } else if (target is Procedure && target.kind == ProcedureKind.Method) {
      final Constant constant = constantEvaluator.evaluate(node);
      return new ConstantExpression(constant);
    }
    return super.visitStaticGet(node);
  }

  visitVariableGet(VariableGet node) {
    if (node.variable.isConst) {
      final Constant constant =
          constantEvaluator.evaluate(node.variable.initializer);
      return new ConstantExpression(constant);
    }
    return super.visitVariableGet(node);
  }

  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return new ConstantExpression(constantEvaluator.evaluate(node));
    }
    return super.visitListLiteral(node);
  }

  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return new ConstantExpression(constantEvaluator.evaluate(node));
    }
    return super.visitMapLiteral(node);
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      return new ConstantExpression(constantEvaluator.evaluate(node));
    }
    return super.visitConstructorInvocation(node);
  }
}

class ConstantEvaluator extends RecursiveVisitor {
  final ConstantsBackend backend;

  final Map<Constant, Constant> canonicalizationCache;
  final Map<Node, Constant> nodeCache;

  final NullConstant nullConstant = new NullConstant();
  final BoolConstant trueConstant = new BoolConstant(true);
  final BoolConstant falseConstant = new BoolConstant(false);

  InstanceBuilder instanceBuilder;
  EvaluationEnvironment env;

  ConstantEvaluator(this.backend)
      : canonicalizationCache = <Constant, Constant>{},
        nodeCache = <Node, Constant>{};

  /// Evaluates [node] and possibly cache the evaluation result.
  Constant evaluate(Expression node) {
    if (node == null) return nullConstant;
    if (env.isEmpty) {
      return nodeCache.putIfAbsent(node, () => node.accept(this));
    }
    return node.accept(this);
  }

  defaultTreeNode(Node node) {
    // Only a subset of the expression language is valid for constant
    // evaluation.
    throw new ConstantEvaluationError(
        'Constant evaluation has no support for ${node.runtimeType} yet!');
  }

  visitNullLiteral(NullLiteral node) => nullConstant;

  visitBoolLiteral(BoolLiteral node) {
    return node.value ? trueConstant : falseConstant;
  }

  visitIntLiteral(IntLiteral node) {
    return canonicalize(new IntConstant(node.value));
  }

  visitDoubleLiteral(DoubleLiteral node) {
    return canonicalize(new DoubleConstant(node.value));
  }

  visitStringLiteral(StringLiteral node) {
    return canonicalize(new StringConstant(node.value));
  }

  visitTypeLiteral(TypeLiteral node) {
    final DartType type = evaluateDartType(node.type);
    return canonicalize(new TypeLiteralConstant(type));
  }

  visitConstantExpression(ConstantExpression node) {
    // If there were already constants in the AST then we make sure we
    // re-canonicalize them.  After running the transformer we will therefore
    // have a fully-canonicalized constant DAG with roots coming from the
    // [ConstantExpression] nodes in the AST.
    return canonicalize(node.constant);
  }

  visitListLiteral(ListLiteral node) {
    final List<Constant> entries = new List<Constant>(node.expressions.length);
    for (int i = 0; i < node.expressions.length; ++i) {
      entries[i] = node.expressions[i].accept(this);
    }
    final DartType typeArgument = evaluateDartType(node.typeArgument);
    final ListConstant listConstant = new ListConstant(typeArgument, entries);
    return canonicalize(backend.lowerListConstant(listConstant));
  }

  visitMapLiteral(MapLiteral node) {
    final Set<Constant> usedKeys = new Set<Constant>();
    final List<ConstantMapEntry> entries =
        new List<ConstantMapEntry>(node.entries.length);
    for (int i = 0; i < node.entries.length; ++i) {
      final key = node.entries[i].key.accept(this);
      final value = node.entries[i].value.accept(this);
      if (!usedKeys.add(key)) {
        throw new ConstantEvaluationError(
            'Duplicate key "$key" in constant map literal.');
      }
      entries[i] = new ConstantMapEntry(key, value);
    }
    final DartType keyType = evaluateDartType(node.keyType);
    final DartType valueType = evaluateDartType(node.valueType);
    final MapConstant mapConstant =
        new MapConstant(keyType, valueType, entries);
    return canonicalize(backend.lowerMapConstant(mapConstant));
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    final Constructor constructor = node.target;
    final Class klass = constructor.enclosingClass;

    final typeArguments = evaluateTypeArguments(node.arguments);
    final positionals = evaluatePositionalArguments(node.arguments);
    final named = evaluateNamedArguments(node.arguments);

    // Fill in any missing type arguments with "dynamic".
    for (int i = typeArguments.length; i < klass.typeParameters.length; i++) {
      typeArguments.add(const DynamicType());
    }

    // Start building a new instance.
    return withNewInstanceBuilder(klass, typeArguments, () {
      // "Run" the constructor (and any super constructor calls), which will
      // initialize the fields of the new instance.
      handleConstructorInvocation(
          constructor, typeArguments, positionals, named);
      return canonicalize(instanceBuilder.buildInstance());
    });
  }

  void handleConstructorInvocation(
      Constructor constructor,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments) {
    return withNewEnvironment(() {
      final Class klass = constructor.enclosingClass;
      final FunctionNode function = constructor.function;

      // We simulate now the constructor invocation.

      // Step 1) Map type arguments and normal arguments from caller to callee.
      for (int i = 0; i < klass.typeParameters.length; i++) {
        env.addTypeParameterValue(klass.typeParameters[i], typeArguments[i]);
      }
      for (int i = 0; i < function.positionalParameters.length; i++) {
        final VariableDeclaration parameter = function.positionalParameters[i];
        final Constant value = (i < positionalArguments.length)
            ? positionalArguments[i]
            : evaluate(parameter.initializer);
        env.addVariableValue(parameter, value);
      }
      for (final VariableDeclaration parameter in function.namedParameters) {
        final Constant value =
            namedArguments[parameter.name] ?? evaluate(parameter.initializer);
        env.addVariableValue(parameter, value);
      }

      // Step 2) Run all initializers (including super calls) with environment setup.
      for (final Field field in klass.fields) {
        if (!field.isStatic) {
          instanceBuilder.setFieldValue(field, evaluate(field.initializer));
        }
      }
      for (final Initializer init in constructor.initializers) {
        if (init is FieldInitializer) {
          instanceBuilder.setFieldValue(init.field, evaluate(init.value));
        } else if (init is LocalInitializer) {
          final VariableDeclaration variable = init.variable;
          env.addVariableValue(variable, evaluate(variable.initializer));
        } else if (init is SuperInitializer) {
          handleConstructorInvocation(
              init.target,
              evaluateSuperTypeArguments(constructor.enclosingClass.supertype),
              evaluatePositionalArguments(init.arguments),
              evaluateNamedArguments(init.arguments));
        } else if (init is RedirectingInitializer) {
          // Since a redirecting constructor targets a constructor of the same
          // class, we pass the same [typeArguments].
          handleConstructorInvocation(
              init.target,
              typeArguments,
              evaluatePositionalArguments(init.arguments),
              evaluateNamedArguments(init.arguments));
        } else {
          throw new ConstantEvaluationError(
              'Cannot evaluate constant with [${init.runtimeType}].');
        }
      }
    });
  }

  visitMethodInvocation(MethodInvocation node) {
    // We have no support for generic method invocation atm.
    assert(node.arguments.named.isEmpty);

    final Constant receiver = evaluate(node.receiver);
    final List<Constant> arguments =
        evaluatePositionalArguments(node.arguments);

    // Handle == and != first (it's common between all types).
    if (arguments.length == 1 && node.name.name == '==') {
      ensurePrimitiveConstant(receiver);
      final right = arguments[0];
      ensurePrimitiveConstant(right);
      return receiver == right ? trueConstant : falseConstant;
    }
    if (arguments.length == 1 && node.name.name == '!=') {
      ensurePrimitiveConstant(receiver);
      final right = arguments[0];
      ensurePrimitiveConstant(right);
      return receiver != right ? trueConstant : falseConstant;
    }

    // This is a white-listed set of methods we need to support on constants.
    if (receiver is StringConstant) {
      if (arguments.length == 1) {
        switch (node.name.name) {
          case '+':
            final StringConstant other = arguments[0];
            return canonicalize(
                new StringConstant(receiver.value + other.value));
        }
      }
    } else if (receiver is BoolConstant) {
      if (arguments.length == 1) {
        switch (node.name.name) {
          case '!':
            return !receiver.value ? trueConstant : falseConstant;
        }
      } else if (arguments.length == 2) {
        final right = arguments[0];
        if (right is BoolConstant) {
          switch (node.name.name) {
            case '&&':
              return (receiver.value && right.value)
                  ? trueConstant
                  : falseConstant;
            case '||':
              return (receiver.value || right.value)
                  ? trueConstant
                  : falseConstant;
          }
        }
        throw new ConstantEvaluationError(
            'Method "${node.name}" is only allowed with boolean arguments.');
      }
    } else if (receiver is IntConstant) {
      if (arguments.length == 0) {
        switch (node.name.name) {
          case 'unary-':
            return canonicalize(new IntConstant(-receiver.value));
          case '~':
            return canonicalize(new IntConstant(~receiver.value));
        }
      } else if (arguments.length == 1) {
        final Constant other = arguments[0];
        if (other is IntConstant) {
          switch (node.name.name) {
            case '|':
              return canonicalize(
                  new IntConstant(receiver.value | other.value));
            case '&':
              return canonicalize(
                  new IntConstant(receiver.value & other.value));
            case '^':
              return canonicalize(
                  new IntConstant(receiver.value ^ other.value));
            case '<<':
              return canonicalize(
                  new IntConstant(receiver.value << other.value));
            case '>>':
              return canonicalize(
                  new IntConstant(receiver.value >> other.value));
          }
        }

        if (other is IntConstant || other is DoubleConstant) {
          final num value = (other is IntConstant)
              ? other.value
              : (other as DoubleConstant).value;
          return evaluateBinaryNumericOperation(
              node.name.name, receiver.value, value);
        }
      }
    } else if (receiver is DoubleConstant) {
      if (arguments.length == 0) {
        switch (node.name.name) {
          case 'unary-':
            return canonicalize(new DoubleConstant(-receiver.value));
        }
      } else if (arguments.length == 1) {
        final Constant other = arguments[0];

        if (other is IntConstant || other is DoubleConstant) {
          final num value = (other is IntConstant)
              ? other.value
              : (other as DoubleConstant).value;
          return evaluateBinaryNumericOperation(
              node.name.name, receiver.value, value);
        }
      }
    }

    throw new ConstantEvaluationError(
        'Cannot evaluate general method invocation: '
        'receiver: $receiver, method: ${node.name}, arguments: $arguments!');
  }

  visitLogicalExpression(LogicalExpression node) {
    final Constant left = evaluate(node.left);
    switch (node.operator) {
      case '||':
        if (left is BoolConstant) {
          if (left.value) return trueConstant;

          final Constant right = evaluate(node.right);
          if (right is BoolConstant) {
            return right;
          }
          throw new ConstantEvaluationError(
              '"$right" is not bool constant and is disallowed with "||".');
        }
        throw new ConstantEvaluationError(
            '"$left" is not bool constant and is disallowed with "||".');
      case '&&':
        if (left is BoolConstant) {
          if (!left.value) return falseConstant;

          final Constant right = evaluate(node.right);
          if (right is BoolConstant) {
            return right;
          }
          throw new ConstantEvaluationError(
              '"$right" is not bool constant and is disallowed with "&&".');
        }
        throw new ConstantEvaluationError(
            '"$left" is not bool constant and is disallowed with "&&".');
      case '??':
        return (left is! NullConstant) ? left : evaluate(node.right);
      default:
        throw new ConstantEvaluationError(
            'No support for logical operator ${node.operator}.');
    }
  }

  visitConditionalExpression(ConditionalExpression node) {
    final BoolConstant constant = evaluate(node.condition);
    if (constant == trueConstant) {
      return evaluate(node.then);
    } else {
      assert(constant == falseConstant);
      return evaluate(node.otherwise);
    }
  }

  visitPropertyGet(PropertyGet node) {
    if (node.receiver is ThisExpression) {
      // Access "this" during instance creation.
      for (final Field field in instanceBuilder.fields.keys) {
        if (field.name == node.name) {
          return instanceBuilder.fields[field];
        }
      }
      throw 'Could not evaluate field get ${node.name} on incomplete instance';
    }

    final Constant receiver = evaluate(node.receiver);
    if (receiver is StringConstant && node.name.name == 'length') {
      return canonicalize(new IntConstant(receiver.value.length));
    } else if (receiver is InstanceConstant) {
      for (final Reference fieldRef in receiver.fieldValues.keys) {
        if (fieldRef.asField.name == node.name) {
          return receiver.fieldValues[fieldRef];
        }
      }
    }

    throw 'Could not evaluate property get on $receiver.';
  }

  visitLet(Let node) {
    env.addVariableValue(node.variable, evaluate(node.variable.initializer));
    return node.body.accept(this);
  }

  visitVariableGet(VariableGet node) {
    return env.lookupVariable(node.variable);
  }

  visitStaticGet(StaticGet node) {
    return withNewEnvironment(() {
      final Member target = node.target;
      if (target is Field && target.isConst) {
        return evaluate(target.initializer);
      } else if (target is Procedure) {
        return canonicalize(new TearOffConstant(target));
      }
      throw 'Could not handle static get of $target.';
    });
  }

  visitStringConcatenation(StringConcatenation node) {
    final String value = node.expressions.map((Expression node) {
      final Constant constant = node.accept(this);

      if (constant is NullConstant) {
        return 'null';
      } else if (constant is BoolConstant) {
        return constant.value ? 'true' : 'false';
      } else if (constant is IntConstant) {
        return constant.value.toString();
      } else if (constant is DoubleConstant) {
        return constant.value.toString();
      } else if (constant is StringConstant) {
        return constant.value;
      } else {
        throw new ConstantEvaluationError(
            'Only null/bool/int/double/String values are allowed as string '
            'interpolation expressions during constant evaluation.');
      }
    }).join('');
    return canonicalize(new StringConstant(value));
  }

  visitStaticInvocation(StaticInvocation node) {
    final Member target = node.target;
    if (target is Procedure) {
      if (target.kind == ProcedureKind.Factory) {
        final String nativeName = findNativeName(target);
        if (nativeName != null) {
          final Constant constant = backend.buildConstantForNative(
              nativeName,
              evaluateTypeArguments(node.arguments),
              evaluatePositionalArguments(node.arguments),
              evaluateNamedArguments(node.arguments));
          assert(constant != null);
          return canonicalize(constant);
        }
      } else if (target.name.name == 'identical') {
        // Ensure the "identical()" function comes from dart:core.
        final parent = target.parent;
        if (parent is Library && parent.importUri == 'dart:core') {
          final positionalArguments =
              evaluatePositionalArguments(node.arguments);
          final left = positionalArguments[0];
          ensurePrimitiveConstant(left);
          final right = positionalArguments[1];
          ensurePrimitiveConstant(right);
          return left == right ? trueConstant : falseConstant;
        }
      }
    }

    throw new ConstantEvaluationError(
        'Calling "$target" during constant evaluation is disallowed.');
  }

  // Helper methods:

  List<DartType> evaluateTypeArguments(Arguments arguments) {
    return evaluateDartTypes(arguments.types);
  }

  List<DartType> evaluateSuperTypeArguments(Supertype type) {
    return evaluateDartTypes(type.typeArguments);
  }

  List<DartType> evaluateDartTypes(List<DartType> types) {
    if (env.isEmpty) return types;
    return types.map(evaluateDartType).toList();
  }

  DartType evaluateDartType(DartType type) {
    return env.subsituteType(type);
  }

  List<Constant> evaluatePositionalArguments(Arguments arguments) {
    return arguments.positional.map((Expression node) {
      return node.accept(this);
    }).toList();
  }

  Map<String, Constant> evaluateNamedArguments(Arguments arguments) {
    if (arguments.named.isEmpty) return const <String, Constant>{};

    final Map<String, Constant> named = {};
    arguments.named.forEach((NamedExpression pair) {
      named[pair.name] = pair.value.accept(this);
    });
    return named;
  }

  canonicalize(Constant constant) {
    return canonicalizationCache.putIfAbsent(constant, () => constant);
  }

  withNewInstanceBuilder(Class klass, List<DartType> typeArguments, fn()) {
    InstanceBuilder old = instanceBuilder;
    instanceBuilder = new InstanceBuilder(klass, typeArguments);
    final result = fn();
    instanceBuilder = old;
    return result;
  }

  withNewEnvironment(fn()) {
    final EvaluationEnvironment oldEnv = env;
    env = new EvaluationEnvironment();
    final result = fn();
    env = oldEnv;
    return result;
  }

  ensurePrimitiveConstant(Constant value) {
    if (value is! NullConstant &&
        value is! BoolConstant &&
        value is! IntConstant &&
        value is! DoubleConstant &&
        value is! StringConstant) {
      throw new ConstantEvaluationError(
          '"$value" is not a primitive constant (null/bool/int/double/string) '
          ' and is disallowed in this context.');
    }
  }

  evaluateBinaryNumericOperation(String op, num a, num b) {
    num result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a - b;
        break;
      case '/':
        result = a / b;
        break;
      case '~/':
        result = a ~/ b;
        break;
      case '%':
        result = a ~/ b;
        break;
    }

    if (result != null) {
      return canonicalize(result is int
          ? new IntConstant(result)
          : new DoubleConstant(result as double));
    }

    switch (op) {
      case '<':
        return a < b ? trueConstant : falseConstant;
      case '<=':
        return a <= b ? trueConstant : falseConstant;
      case '>=':
        return a >= b ? trueConstant : falseConstant;
      case '>':
        return a > b ? trueConstant : falseConstant;
    }

    throw new ConstantEvaluationError(
        'Binary operation "$op" on num is disallowed.');
  }
}

/// Holds the necessary information for a constant object, namely
///   * the [klass] being instantiated
///   * the [typeArguments] used for the instantiation
///   * the [fields] the instance will obtain (all fields from the
///     instantiated [klass] up to the [Object] klass).
class InstanceBuilder {
  /// The class of the new instance.
  final Class klass;

  /// The values of the type parameters of the new instance.
  final List<DartType> typeArguments;

  /// The field values of the new instance.
  final Map<Field, Constant> fields = <Field, Constant>{};

  InstanceBuilder(this.klass, this.typeArguments);

  void setFieldValue(Field field, Constant constant) {
    fields[field] = constant;
  }

  InstanceConstant buildInstance() {
    final Map<Reference, Constant> fieldValues = <Reference, Constant>{};
    fields.forEach((Field field, Constant value) {
      fieldValues[field.reference] = value;
    });
    return new InstanceConstant(klass.reference, typeArguments, fieldValues);
  }
}

/// Holds an environment of type parameters, parameters and variables.
class EvaluationEnvironment {
  /// The values of the type parameters in scope.
  final Map<TypeParameter, DartType> _typeVariables =
      <TypeParameter, DartType>{};

  /// The values of the parameters/variables in scope.
  final Map<VariableDeclaration, Constant> _variables =
      <VariableDeclaration, Constant>{};

  /// Whether the current environment is empty.
  bool get isEmpty => _typeVariables.isEmpty && _variables.isEmpty;

  void addTypeParameterValue(TypeParameter parameter, DartType value) {
    assert(!_typeVariables.containsKey(parameter));
    _typeVariables[parameter] = value;
  }

  void addVariableValue(VariableDeclaration variable, Constant value) {
    assert(!_variables.containsKey(variable));
    _variables[variable] = value;
  }

  DartType lookupParameterValue(TypeParameter parameter) {
    final DartType value = _typeVariables[parameter];
    assert(value != null);
    return value;
  }

  Constant lookupVariable(VariableDeclaration variable) {
    final Constant value = _variables[variable];
    assert(value != null);
    return value;
  }

  DartType subsituteType(DartType type) {
    if (_typeVariables.isEmpty) return type;
    return substitute(type, _typeVariables);
  }
}

abstract class ConstantsBackend {
  Constant buildConstantForNative(
      String nativeName,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments);

  Constant lowerListConstant(ListConstant constant);
  Constant lowerMapConstant(MapConstant constant);
}

/// Represents a compile-time error reported during constant evaluation.
class ConstantEvaluationError {
  final String message;

  ConstantEvaluationError(this.message);

  String toString() => 'Error during constant evaluation: $message';
}
