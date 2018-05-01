// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library implements a kernel2kernel constant evaluation transformation.
///
/// Even though it is expected that the frontend does not emit kernel AST which
/// contains compile-time errors, this transformation still performs some
/// valiation and throws a [ConstantEvaluationError] if there was a compile-time
/// errors.
///
/// Due to the lack information which is is only available in the front-end,
/// this validation is incomplete (e.g. whether an integer literal used the
/// hexadecimal syntax or not).
///
/// Furthermore due to the lowering of certain constructs in the front-end
/// (e.g. '??') we need to support a super-set of the normal constant expression
/// language.  Issue(http://dartbug.com/31799)
library kernel.transformations.constants;

import 'dart:io' as io;

import '../kernel.dart';
import '../ast.dart';
import '../core_types.dart';
import '../type_algebra.dart';
import '../type_environment.dart';
import '../class_hierarchy.dart';
import 'treeshaker.dart' show findNativeName;

Component transformComponent(Component component, ConstantsBackend backend,
    {bool keepFields: false,
    bool strongMode: false,
    bool enableAsserts: false,
    bool evaluateAnnotations: true,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    ErrorReporter errorReporter: const _SimpleErrorReporter()}) {
  coreTypes ??= new CoreTypes(component);
  hierarchy ??= new ClassHierarchy(component);

  final typeEnvironment =
      new TypeEnvironment(coreTypes, hierarchy, strongMode: strongMode);

  transformLibraries(component.libraries, backend, coreTypes, typeEnvironment,
      keepFields: keepFields,
      strongMode: strongMode,
      enableAsserts: enableAsserts,
      evaluateAnnotations: evaluateAnnotations,
      errorReporter: errorReporter);
  return component;
}

void transformLibraries(List<Library> libraries, ConstantsBackend backend,
    CoreTypes coreTypes, TypeEnvironment typeEnvironment,
    {bool keepFields: false,
    bool keepVariables: false,
    bool evaluateAnnotations: true,
    bool strongMode: false,
    bool enableAsserts: false,
    ErrorReporter errorReporter: const _SimpleErrorReporter()}) {
  final ConstantsTransformer constantsTransformer = new ConstantsTransformer(
      backend,
      keepFields,
      keepVariables,
      evaluateAnnotations,
      coreTypes,
      typeEnvironment,
      strongMode,
      enableAsserts,
      errorReporter);
  for (final Library library in libraries) {
    constantsTransformer.convertLibrary(library);
  }
}

class ConstantsTransformer extends Transformer {
  final ConstantEvaluator constantEvaluator;
  final CoreTypes coreTypes;
  final TypeEnvironment typeEnvironment;

  /// Whether to preserve constant [Field]s.  All use-sites will be rewritten.
  final bool keepFields;
  final bool keepVariables;
  final bool evaluateAnnotations;

  ConstantsTransformer(
      ConstantsBackend backend,
      this.keepFields,
      this.keepVariables,
      this.evaluateAnnotations,
      this.coreTypes,
      this.typeEnvironment,
      bool strongMode,
      bool enableAsserts,
      ErrorReporter errorReporter)
      : constantEvaluator = new ConstantEvaluator(backend, typeEnvironment,
            coreTypes, strongMode, enableAsserts, errorReporter);

  // Transform the library/class members:

  void convertLibrary(Library library) {
    transformAnnotations(library.annotations, library);

    transformList(library.dependencies, this, library);
    transformList(library.parts, this, library);
    transformList(library.typedefs, this, library);
    transformList(library.classes, this, library);
    transformList(library.procedures, this, library);
    transformList(library.fields, this, library);

    if (!keepFields) {
      // The transformer API does not iterate over `Library.additionalExports`,
      // so we manually delete the references to shaken nodes.
      library.additionalExports.removeWhere((Reference reference) {
        return reference.canonicalName == null;
      });
    }
  }

  visitLibraryPart(LibraryPart node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  visitLibraryDependency(LibraryDependency node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  visitClass(Class node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.fields, this, node);
      transformList(node.typeParameters, this, node);
      transformList(node.constructors, this, node);
      transformList(node.procedures, this, node);
      transformList(node.redirectingFactoryConstructors, this, node);
    });
    return node;
  }

  visitProcedure(Procedure node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      node.function = node.function.accept(this)..parent = node;
    });
    return node;
  }

  visitConstructor(Constructor node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.initializers, this, node);
      node.function = node.function.accept(this)..parent = node;
    });
    return node;
  }

  visitTypedef(Typedef node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
    });
    return node;
  }

  visitRedirectingFactoryConstructor(RedirectingFactoryConstructor node) {
    constantEvaluator.withNewEnvironment(() {
      transformAnnotations(node.annotations, node);
      transformList(node.typeParameters, this, node);
      transformList(node.positionalParameters, this, node);
      transformList(node.namedParameters, this, node);
    });
    return node;
  }

  visitTypeParameter(TypeParameter node) {
    transformAnnotations(node.annotations, node);
    return node;
  }

  void transformAnnotations(List<Expression> nodes, TreeNode parent) {
    if (evaluateAnnotations && nodes.length > 0) {
      constantEvaluator.withNewEnvironment(() {
        for (int i = 0; i < nodes.length; ++i) {
          nodes[i] = tryEvaluateAndTransformWithContext(parent, nodes[i])
            ..parent = parent;
        }
      });
    }
  }

  // Handle definition of constants:

  visitFunctionNode(FunctionNode node) {
    final positionalParameterCount = node.positionalParameters.length;
    for (int i = node.requiredParameterCount;
        i < positionalParameterCount;
        ++i) {
      final VariableDeclaration variable = node.positionalParameters[i];
      if (variable.initializer != null) {
        variable.initializer =
            tryEvaluateAndTransformWithContext(variable, variable.initializer)
              ..parent = node;
      }
    }
    for (final VariableDeclaration variable in node.namedParameters) {
      if (variable.initializer != null) {
        variable.initializer =
            tryEvaluateAndTransformWithContext(variable, variable.initializer)
              ..parent = node;
      }
    }
    if (node.body != null) {
      node.body = node.body.accept(this)..parent = node;
    }
    return node;
  }

  visitVariableDeclaration(VariableDeclaration node) {
    transformAnnotations(node.annotations, node);

    if (node.isConst) {
      final Constant constant = tryEvaluateWithContext(node, node.initializer);

      // If there was a constant evaluation error we will not continue and
      // simply keep the old [node].
      if (constant == null) {
        return node;
      }

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
    return constantEvaluator.withNewEnvironment(() {
      if (node.isConst) {
        // Since we convert all use-sites of constants, the constant [Field]
        // cannot be referenced anymore.  We therefore get rid of it if
        // [keepFields] was not specified.
        if (!keepFields) {
          return null;
        }

        // Otherwise we keep the constant [Field] and convert it's initializer.
        transformAnnotations(node.annotations, node);
        if (node.initializer != null) {
          node.initializer =
              tryEvaluateAndTransformWithContext(node, node.initializer)
                ..parent = node;
        }
      } else {
        transformAnnotations(node.annotations, node);
        if (node.initializer != null) {
          node.initializer = node.initializer.accept(this)..parent = node;
        }
      }
      return node;
    });
  }

  // Handle use-sites of constants (and "inline" constant expressions):

  visitStaticGet(StaticGet node) {
    final Member target = node.target;
    if (target is Field && target.isConst) {
      final Constant constant =
          tryEvaluateWithContext(node, target.initializer);
      return constant != null ? new ConstantExpression(constant) : node;
    } else if (target is Procedure && target.kind == ProcedureKind.Method) {
      return tryEvaluateAndTransformWithContext(node, node);
    }
    return super.visitStaticGet(node);
  }

  visitVariableGet(VariableGet node) {
    if (node.variable.isConst) {
      return tryEvaluateAndTransformWithContext(node, node);
    }
    return super.visitVariableGet(node);
  }

  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return tryEvaluateAndTransformWithContext(node, node);
    }
    return super.visitListLiteral(node);
  }

  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return tryEvaluateAndTransformWithContext(node, node);
    }
    return super.visitMapLiteral(node);
  }

  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      return tryEvaluateAndTransformWithContext(node, node);
    }
    return super.visitConstructorInvocation(node);
  }

  tryEvaluateAndTransformWithContext(TreeNode treeContext, Expression node) {
    final Constant constant = tryEvaluateWithContext(treeContext, node);
    return constant != null ? new ConstantExpression(constant) : node;
  }

  tryEvaluateWithContext(TreeNode treeContext, Expression node) {
    if (treeContext == node) {
      try {
        return constantEvaluator.evaluate(node);
      } on _AbortCurrentEvaluation catch (_) {
        return null;
      }
    }

    return constantEvaluator.runInsideContext(treeContext, () {
      try {
        return constantEvaluator.evaluate(node);
      } on _AbortCurrentEvaluation catch (_) {
        return null;
      }
    });
  }
}

class ConstantEvaluator extends RecursiveVisitor {
  final ConstantsBackend backend;
  final CoreTypes coreTypes;
  final TypeEnvironment typeEnvironment;
  final bool strongMode;
  final bool enableAsserts;
  final ErrorReporter errorReporter;

  final Map<Constant, Constant> canonicalizationCache;
  final Map<Node, Object> nodeCache;

  final NullConstant nullConstant = new NullConstant();
  final BoolConstant trueConstant = new BoolConstant(true);
  final BoolConstant falseConstant = new BoolConstant(false);

  final List<TreeNode> contextChain = [];

  InstanceBuilder instanceBuilder;
  EvaluationEnvironment env;

  ConstantEvaluator(this.backend, this.typeEnvironment, this.coreTypes,
      this.strongMode, this.enableAsserts,
      [this.errorReporter = const _SimpleErrorReporter()])
      : canonicalizationCache = <Constant, Constant>{},
        nodeCache = <Node, Constant>{};

  /// Evaluates [node] and possibly cache the evaluation result.
  Constant evaluate(Expression node) {
    if (node == null) return nullConstant;
    if (env.isEmpty) {
      // We only try to evaluate the same [node] *once* within an empty
      // environment.
      if (nodeCache.containsKey(node)) {
        final Constant constant = nodeCache[node];
        if (constant == null) throw const _AbortCurrentEvaluation();
        return constant;
      }

      nodeCache[node] = null;
      return nodeCache[node] = node.accept(this);
    }
    return node.accept(this);
  }

  Constant runInsideContext(TreeNode node, Constant fun()) {
    try {
      pushContext(node);
      return fun();
    } finally {
      popContext(node);
    }
  }

  pushContext(TreeNode contextNode) {
    contextChain.add(contextNode);
  }

  popContext(TreeNode contextNode) {
    assert(contextChain.last == contextNode);
    contextChain.length = contextChain.length - 1;
  }

  defaultTreeNode(Node node) {
    // Only a subset of the expression language is valid for constant
    // evaluation.
    errorReporter.unimplemented(contextChain, node,
        'Constant evaluation has no support for ${node.runtimeType} yet!');
    throw const _AbortCurrentEvaluation();
  }

  visitNullLiteral(NullLiteral node) => nullConstant;

  visitBoolLiteral(BoolLiteral node) {
    return node.value ? trueConstant : falseConstant;
  }

  visitIntLiteral(IntLiteral node) {
    // The frontend will ensure the integer literals are in signed 64-bit range
    // in strong mode.
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
    if (!node.isConst) {
      errorReporter.nonConstantLiteral(contextChain, node, 'List');
      throw const _AbortCurrentEvaluation();
    }
    final List<Constant> entries = new List<Constant>(node.expressions.length);
    for (int i = 0; i < node.expressions.length; ++i) {
      entries[i] = node.expressions[i].accept(this);
    }
    final DartType typeArgument = evaluateDartType(node.typeArgument);
    final ListConstant listConstant = new ListConstant(typeArgument, entries);
    return canonicalize(backend.lowerListConstant(listConstant));
  }

  visitMapLiteral(MapLiteral node) {
    if (!node.isConst) {
      errorReporter.nonConstantLiteral(contextChain, node, 'Map');
      throw const _AbortCurrentEvaluation();
    }
    final Set<Constant> usedKeys = new Set<Constant>();
    final List<ConstantMapEntry> entries =
        new List<ConstantMapEntry>(node.entries.length);
    for (int i = 0; i < node.entries.length; ++i) {
      final key = node.entries[i].key.accept(this);
      final value = node.entries[i].value.accept(this);
      if (!usedKeys.add(key)) {
        errorReporter.duplicateKey(contextChain, node.entries[i], key);
        throw const _AbortCurrentEvaluation();
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
    if (!constructor.isConst) {
      errorReporter.nonConstConstructorInvocation(
          contextChain, node, constructor);
      throw const _AbortCurrentEvaluation();
    }
    if (constructor.function.body is! EmptyStatement) {
      errorReporter.unreachable(contextChain, node,
          'Constructor "$node" has non-trivial body "${constructor.function.body.runtimeType}".');
      throw const _AbortCurrentEvaluation();
    }
    if (klass.isAbstract) {
      errorReporter.unreachable(contextChain, node,
          'Constructor "$node" belongs to abstract class "${klass}".');
      throw const _AbortCurrentEvaluation();
    }

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

  handleConstructorInvocation(
      Constructor constructor,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments) {
    return runInsideContext(constructor, () {
      return withNewEnvironment(() {
        final Class klass = constructor.enclosingClass;
        final FunctionNode function = constructor.function;

        // We simulate now the constructor invocation.

        // Step 1) Map type arguments and normal arguments from caller to callee.
        for (int i = 0; i < klass.typeParameters.length; i++) {
          env.addTypeParameterValue(klass.typeParameters[i], typeArguments[i]);
        }
        for (int i = 0; i < function.positionalParameters.length; i++) {
          final VariableDeclaration parameter =
              function.positionalParameters[i];
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
                evaluateSuperTypeArguments(
                    constructor.enclosingClass.supertype),
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
          } else if (init is AssertInitializer) {
            if (enableAsserts) {
              final Constant condition = init.statement.condition.accept(this);

              if (condition is BoolConstant) {
                if (!condition.value) {
                  final Constant message = init.statement.message?.accept(this);
                  errorReporter.failedAssertion(
                      contextChain, init.statement.condition, message);
                  throw const _AbortCurrentEvaluation();
                }
              } else {
                errorReporter.invalidType(
                    contextChain, init.statement.condition, condition, 'bool');
                throw const _AbortCurrentEvaluation();
              }
            }
          } else {
            errorReporter.unimplemented(contextChain, init,
                'No support for handling initializer of type "${init.runtimeType}".');
            throw const _AbortCurrentEvaluation();
          }
        }
      });
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
      // TODO(http://dartbug.com/31799): Re-enable these checks.
      //ensurePrimitiveConstant(receiver);
      final right = arguments[0];
      // TODO(http://dartbug.com/31799): Re-enable these checks.
      //ensurePrimitiveConstant(right);
      return receiver == right ? trueConstant : falseConstant;
    }
    if (arguments.length == 1 && node.name.name == '!=') {
      // TODO(http://dartbug.com/31799): Re-enable these checks.
      //ensurePrimitiveConstant(receiver);
      final right = arguments[0];
      // TODO(http://dartbug.com/31799): Re-enable these checks.
      //ensurePrimitiveConstant(right);
      return receiver != right ? trueConstant : falseConstant;
    }

    // This is a white-listed set of methods we need to support on constants.
    if (receiver is StringConstant) {
      if (arguments.length == 1) {
        switch (node.name.name) {
          case '+':
            final Constant other = arguments[0];
            if (other is StringConstant) {
              return canonicalize(
                  new StringConstant(receiver.value + other.value));
            }
            errorReporter.invalidBinaryOperandType(
                contextChain, node, 'String', '+', 'String', '$other');
            throw const _AbortCurrentEvaluation();
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
        errorReporter.invalidBinaryOperandType(
            contextChain, node, 'bool', '${node.name.name}', 'bool', '$right');
        throw const _AbortCurrentEvaluation();
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
              node.name.name, receiver.value, value, node);
        }

        errorReporter.invalidBinaryOperandType(contextChain, node, 'int',
            '${node.name.name}', 'int/double', '$other');
        throw const _AbortCurrentEvaluation();
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
              node.name.name, receiver.value, value, node);
        }
        errorReporter.invalidBinaryOperandType(contextChain, node, 'double',
            '${node.name.name}', 'int/double', '$other');
        throw const _AbortCurrentEvaluation();
      }
    }
    errorReporter.invalidMethodInvocation(
        contextChain, node, receiver, node.name.name);
    throw const _AbortCurrentEvaluation();
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
          errorReporter.invalidBinaryOperandType(
              contextChain, node, 'bool', '${node.operator}', 'bool', '$right');
          throw const _AbortCurrentEvaluation();
        }
        errorReporter.invalidMethodInvocation(
            contextChain, node, left, '${node.operator}');
        throw const _AbortCurrentEvaluation();
      case '&&':
        if (left is BoolConstant) {
          if (!left.value) return falseConstant;

          final Constant right = evaluate(node.right);
          if (right is BoolConstant) {
            return right;
          }
          errorReporter.invalidBinaryOperandType(
              contextChain, node, 'bool', '${node.operator}', 'bool', '$right');
          throw const _AbortCurrentEvaluation();
        }
        errorReporter.invalidMethodInvocation(
            contextChain, node, left, '${node.operator}');
        throw const _AbortCurrentEvaluation();
      case '??':
        return (left is! NullConstant) ? left : evaluate(node.right);
      default:
        errorReporter.invalidMethodInvocation(
            contextChain, node, left, '${node.operator}');
        throw const _AbortCurrentEvaluation();
    }
  }

  visitConditionalExpression(ConditionalExpression node) {
    final Constant constant = evaluate(node.condition);
    if (constant == trueConstant) {
      return evaluate(node.then);
    } else if (constant == falseConstant) {
      return evaluate(node.otherwise);
    } else {
      errorReporter.invalidType(contextChain, node, constant, 'bool');
      throw const _AbortCurrentEvaluation();
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
    // Not every variable which a [VariableGet] refers to must be marked as
    // constant.  For example function parameters as well as constructs
    // desugared to [Let] expressions are ok.
    //
    // TODO(kustermann): The heuristic of allowing all [VariableGet]s on [Let]
    // variables might allow more than it should.
    final VariableDeclaration variable = node.variable;
    if (!variable.isConst &&
        !_isFormalParameter(variable) &&
        variable.parent is! Let) {
      errorReporter.nonConstantVariableGet(contextChain, node);
      throw const _AbortCurrentEvaluation();
    }
    return env.lookupVariable(node.variable);
  }

  visitStaticGet(StaticGet node) {
    return withNewEnvironment(() {
      final Member target = node.target;
      if (target is Field && target.isConst) {
        return runInsideContext(target, () {
          return evaluate(target.initializer);
        });
      } else if (target is Procedure) {
        if (target.kind == ProcedureKind.Method) {
          return canonicalize(new TearOffConstant(target));
        }
        errorReporter.invalidStaticInvocation(contextChain, node, target);
        throw const _AbortCurrentEvaluation();
      } else {
        errorReporter.unreachable(contextChain, node,
            'No support for ${target.runtimeType} in a static-get.');
        throw const _AbortCurrentEvaluation();
      }
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
        errorReporter.invalidStringInterpolationOperand(
            contextChain, node, constant);
        throw const _AbortCurrentEvaluation();
      }
    }).join('');
    return canonicalize(new StringConstant(value));
  }

  visitStaticInvocation(StaticInvocation node) {
    final Procedure target = node.target;
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
      if (parent is Library && parent == coreTypes.coreLibrary) {
        final positionalArguments = evaluatePositionalArguments(node.arguments);
        final Constant left = positionalArguments[0];
        // TODO(http://dartbug.com/31799): Re-enable these checks.
        //ensurePrimitiveConstant(left, node);
        final Constant right = positionalArguments[1];
        // TODO(http://dartbug.com/31799): Re-enable these checks.
        //ensurePrimitiveConstant(right, node);
        // Since we canonicalize constants during the evaluation, we can use
        // identical here.
        assert(left == right);
        return identical(left, right) ? trueConstant : falseConstant;
      }
    }
    errorReporter.invalidStaticInvocation(contextChain, node, target);
    throw const _AbortCurrentEvaluation();
  }

  visitAsExpression(AsExpression node) {
    final Constant constant = node.operand.accept(this);
    ensureIsSubtype(constant, evaluateDartType(node.type), node);
    return constant;
  }

  visitNot(Not node) {
    final Constant constant = node.operand.accept(this);
    if (constant is BoolConstant) {
      return constant == trueConstant ? falseConstant : trueConstant;
    }
    errorReporter.invalidType(contextChain, node, constant, 'bool');
    throw const _AbortCurrentEvaluation();
  }

  visitSymbolLiteral(SymbolLiteral node) {
    final value = canonicalize(new StringConstant(node.value));
    return canonicalize(backend.buildSymbolConstant(value));
  }

  visitInstantiation(Instantiation node) {
    final Constant constant = evaluate(node.expression);
    if (constant is TearOffConstant) {
      if (node.typeArguments.length ==
          constant.procedure.function.typeParameters.length) {
        return canonicalize(
            new PartialInstantiationConstant(constant, node.typeArguments));
      }
      errorReporter.unreachable(
          contextChain,
          node,
          'The number of type arguments supplied in the partial instantiation '
          'does not match the number of type arguments of the $constant.');
      throw const _AbortCurrentEvaluation();
    }
    errorReporter.unreachable(contextChain, node,
        'Only tear-off constants can be partially instantiated.');
    throw const _AbortCurrentEvaluation();
  }

  // Helper methods:

  void ensureIsSubtype(Constant constant, DartType type, TreeNode node) {
    DartType constantType;
    if (constant is NullConstant) {
      constantType = new InterfaceType(coreTypes.nullClass);
    } else if (constant is BoolConstant) {
      constantType = new InterfaceType(coreTypes.boolClass);
    } else if (constant is IntConstant) {
      constantType = new InterfaceType(coreTypes.intClass);
    } else if (constant is DoubleConstant) {
      constantType = new InterfaceType(coreTypes.doubleClass);
    } else if (constant is StringConstant) {
      constantType = new InterfaceType(coreTypes.stringClass);
    } else if (constant is MapConstant) {
      constantType = new InterfaceType(
          coreTypes.mapClass, <DartType>[constant.keyType, constant.valueType]);
    } else if (constant is ListConstant) {
      constantType = new InterfaceType(
          coreTypes.stringClass, <DartType>[constant.typeArgument]);
    } else if (constant is InstanceConstant) {
      constantType = new InterfaceType(constant.klass, constant.typeArguments);
    } else if (constant is TearOffConstant) {
      constantType = constant.procedure.function.functionType;
    } else if (constant is TypeLiteralConstant) {
      constantType = new InterfaceType(coreTypes.typeClass);
    } else {
      errorReporter.unreachable(contextChain, node,
          'No support for ${constant.runtimeType}.runtimeType');
      throw const _AbortCurrentEvaluation();
    }

    if (!typeEnvironment.isSubtypeOf(constantType, type)) {
      errorReporter.invalidType(contextChain, node, constant, '$type');
      throw const _AbortCurrentEvaluation();
    }
  }

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
    try {
      instanceBuilder = new InstanceBuilder(klass, typeArguments);
      return fn();
    } finally {
      instanceBuilder = old;
    }
  }

  withNewEnvironment(fn()) {
    final EvaluationEnvironment oldEnv = env;
    try {
      env = new EvaluationEnvironment();
      return fn();
    } finally {
      env = oldEnv;
    }
  }

  ensurePrimitiveConstant(Constant value, TreeNode node) {
    if (value is! NullConstant &&
        value is! BoolConstant &&
        value is! IntConstant &&
        value is! DoubleConstant &&
        value is! StringConstant) {
      errorReporter.invalidType(
          contextChain, node, value, 'bool/int/double/Null/String');
      throw const _AbortCurrentEvaluation();
    }
  }

  evaluateBinaryNumericOperation(String op, num a, num b, TreeNode node) {
    num result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a * b;
        break;
      case '/':
        result = a / b;
        break;
      case '~/':
        result = a ~/ b;
        break;
      case '%':
        result = a % b;
        break;
    }

    if (result != null) {
      return canonicalize(result is int
          ? new IntConstant(_wrapAroundInteger(result))
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

    errorReporter.invalidBinaryMethodInvocation(contextChain, node, op);
    throw const _AbortCurrentEvaluation();
  }

  int _wrapAroundInteger(int value) {
    if (strongMode) {
      return value.toSigned(64);
    }
    return value;
  }

  static const kMaxInt64 = (1 << 63) - 1;
  static const kMinInt64 = -(1 << 63);
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
  Constant buildSymbolConstant(StringConstant value);

  Constant lowerListConstant(ListConstant constant);
  Constant lowerMapConstant(MapConstant constant);
}

// Used as control-flow to abort the current evaluation.
class _AbortCurrentEvaluation {
  const _AbortCurrentEvaluation();
}

abstract class ErrorReporter {
  const ErrorReporter();

  invalidType(List<TreeNode> context, TreeNode node, Constant receiver,
      String expectedType);
  invalidBinaryOperandType(List<TreeNode> context, TreeNode node,
      String receiverType, String op, String expectedType, String actualType);
  invalidBinaryMethodInvocation(
      List<TreeNode> context, TreeNode node, String op);
  invalidMethodInvocation(
      List<TreeNode> context, TreeNode node, Constant receiver, String op);
  invalidStaticInvocation(
      List<TreeNode> context, TreeNode node, Procedure target);
  invalidStringInterpolationOperand(
      List<TreeNode> context, TreeNode node, Constant constant);
  duplicateKey(List<TreeNode> context, TreeNode node, Constant key);
  nonConstantLiteral(List<TreeNode> context, TreeNode node, String literalType);
  nonConstantVariableGet(List<TreeNode> context, VariableGet node);
  nonConstConstructorInvocation(
      List<TreeNode> context, TreeNode node, Constructor target);
  failedAssertion(List<TreeNode> context, TreeNode node, Constant message);
  unimplemented(List<TreeNode> context, TreeNode node, String message);
  unreachable(List<TreeNode> context, TreeNode node, String message);
}

abstract class ErrorReporterBase implements ErrorReporter {
  const ErrorReporterBase();

  report(List<TreeNode> context, String message, TreeNode node);

  getFileUri(TreeNode node) {
    while (node is! FileUriNode) {
      node = node.parent;
    }
    return (node as FileUriNode).fileUri;
  }

  getFileOffset(TreeNode node) {
    while (node.fileOffset == TreeNode.noOffset) {
      node = node.parent;
    }
    return node == null ? TreeNode.noOffset : node.fileOffset;
  }

  invalidType(List<TreeNode> context, TreeNode node, Constant receiver,
      String expectedType) {
    report(
        context,
        'Expected expression to evaluate to "$expectedType" but got "$receiver.',
        node);
  }

  invalidBinaryOperandType(List<TreeNode> context, TreeNode node,
      String receiverType, String op, String expectedType, String actualType) {
    report(
        context,
        'Calling "$op" on "$receiverType" needs operand of type '
        '"$expectedType" (but got "$actualType")',
        node);
  }

  invalidBinaryMethodInvocation(
      List<TreeNode> context, TreeNode node, String op) {
    report(context, 'Cannot call "$op" on a numeric constant receiver', node);
  }

  invalidMethodInvocation(
      List<TreeNode> context, TreeNode node, Constant receiver, String op) {
    report(context, 'Cannot call "$op" on "$receiver" in constant expression',
        node);
  }

  invalidStaticInvocation(
      List<TreeNode> context, TreeNode node, Procedure target) {
    report(
        context, 'Cannot invoke "$target" inside a constant expression', node);
  }

  invalidStringInterpolationOperand(
      List<TreeNode> context, TreeNode node, Constant constant) {
    report(
        context,
        'Only null/bool/int/double/String values are allowed as string '
        'interpolation expressions during constant evaluation (was: "$constant").',
        node);
  }

  duplicateKey(List<TreeNode> context, TreeNode node, Constant key) {
    report(
        context,
        'Duplicate keys are not allowed in constant maps (found duplicate key "$key")',
        node);
  }

  nonConstantLiteral(
      List<TreeNode> context, TreeNode node, String literalType) {
    report(
        context,
        '"$literalType" literals inside constant expressions are required to '
        'be constant.',
        node);
  }

  nonConstantVariableGet(List<TreeNode> context, VariableGet node) {
    report(
        context,
        'The variable "${node.variable.name}" is non-const and '
        'can therefore not be used inside a constant expression.'
        ' (${node}, ${node.parent.parent}, )',
        node);
  }

  nonConstConstructorInvocation(
      List<TreeNode> context, TreeNode node, Constructor target) {
    report(
        context,
        'The non-const constructor "$target" cannot be called inside a '
        'constant expression',
        node);
  }

  failedAssertion(List<TreeNode> context, TreeNode node, Constant message) {
    report(
        context,
        'The assertion condition evaluated to "false" with message "$message"',
        node);
  }

  unimplemented(List<TreeNode> context, TreeNode node, String message) {
    report(context, 'Unimplemented: $message', node);
  }

  unreachable(List<TreeNode> context, TreeNode node, String message) {
    report(context, 'Unreachable: $message', node);
  }
}

class _SimpleErrorReporter extends ErrorReporterBase {
  const _SimpleErrorReporter();

  report(List<TreeNode> context, String message, TreeNode node) {
    io.exitCode = 42;
    final Uri uri = getFileUri(node);
    final int fileOffset = getFileOffset(node);

    io.stderr.writeln('$uri:$fileOffset Constant evaluation error: $message');
  }
}

bool _isFormalParameter(VariableDeclaration variable) {
  final parent = variable.parent;
  if (parent is FunctionNode) {
    return parent.positionalParameters.contains(variable) ||
        parent.namedParameters.contains(variable);
  }
  return false;
}
