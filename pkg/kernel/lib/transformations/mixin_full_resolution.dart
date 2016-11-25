// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.mixin_full_resolution;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../clone.dart';
import '../core_types.dart';
import '../type_algebra.dart';

Program transformProgram(Program program) {
  new MixinFullResolution().transform(program);
  return program;
}

/// Replaces all mixin applications with regular classes, cloning all fields
/// and procedures from the mixed-in class, cloning all constructors from the
/// base class.
///
/// Super calls (as well as super initializer invocations) are also resolved
/// to their targets in this pass.
class MixinFullResolution {
  ClassHierarchy hierarchy;
  CoreTypes coreTypes;

  void transform(Program program) {
    var transformedClasses = new Set<Class>();

    // Desugar all mixin application classes by copying in fields/methods from
    // the mixin and constructors from the base class.
    var processedClasses = new Set<Class>();
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        transformClass(processedClasses, transformedClasses, class_);
      }
    }

    hierarchy = new ClassHierarchy(program);
    coreTypes = new CoreTypes(program);

    // Resolve all super call expressions and super initializers.
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        final bool hasTransformedSuperclass =
            transformedClasses.contains(class_.superclass);

        for (var procedure in class_.procedures) {
          if (procedure.containsSuperCalls) {
            new SuperCallResolutionTransformer(
                    hierarchy, coreTypes, class_.superclass)
                .visit(procedure);
          }
        }
        for (var constructor in class_.constructors) {
          if (constructor.containsSuperCalls) {
            new SuperCallResolutionTransformer(
                    hierarchy, coreTypes, class_.superclass)
                .visit(constructor);
          }
          if (hasTransformedSuperclass && constructor.initializers.length > 0) {
            new SuperInitializerResolutionTransformer(class_.superclass)
                .transformInitializers(constructor.initializers);
          }
        }
      }
    }
  }

  transformClass(Set<Class> processedClasses, Set<Class> transformedClasses,
      Class class_) {
    // If this class was already handled then so were all classes up to the
    // [Object] class.
    if (!processedClasses.add(class_)) return;

    // Ensure super classes have been transformed before this class.
    if (class_.superclass != null) {
      transformClass(processedClasses, transformedClasses, class_.superclass);
    }

    // If this is not a mixin application we don't need to make forwarding
    // constructors in this class.
    if (!class_.isMixinApplication) return;

    transformedClasses.add(class_);

    // Clone fields and methods from the mixin class.
    var substitution = getSubstitutionMap(class_.mixedInType);
    var cloner = new CloneVisitor(typeSubstitution: substitution);
    for (var field in class_.mixin.fields) {
      class_.addMember(cloner.clone(field));
    }
    for (var procedure in class_.mixin.procedures) {
      class_.addMember(cloner.clone(procedure));
    }
    // For each generative constructor in the superclass we make a
    // corresponding forwarding constructor in the subclass.
    // Named mixin applications already have constructors, so only build the
    // constructors for anonymous mixin applications.
    if (class_.constructors.isEmpty) {
      var superclassSubstitution = getSubstitutionMap(class_.supertype);
      var superclassCloner =
          new CloneVisitor(typeSubstitution: superclassSubstitution);
      for (var superclassConstructor in class_.superclass.constructors) {
        var forwardingConstructor =
            buildForwardingConstructor(superclassCloner, superclassConstructor);
        class_.constructors.add(forwardingConstructor..parent = class_);
      }
    }

    // This class implements the mixin type.
    class_.implementedTypes.add(class_.mixedInType);

    // This class is now a normal class.
    class_.mixedInType = null;
  }

  Constructor buildForwardingConstructor(
      CloneVisitor cloner, Constructor superclassConstructor) {
    var superFunction = superclassConstructor.function;

    // We keep types and default values for the parameters but always mark the
    // parameters as final (since we just forward them to the super
    // constructor).
    VariableDeclaration cloneVariable(VariableDeclaration variable) {
      VariableDeclaration clone = cloner.clone(variable);
      clone.isFinal = true;
      return clone;
    }

    // Build a [FunctionNode] which has the same parameters as the one in the
    // superclass constructor.
    var positionalParameters =
        superFunction.positionalParameters.map(cloneVariable).toList();
    var namedParameters =
        superFunction.namedParameters.map(cloneVariable).toList();
    var function = new FunctionNode(new EmptyStatement(),
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: superFunction.requiredParameterCount,
        returnType: const VoidType());

    // Build a [SuperInitializer] which takes all positional/named parameters
    // and forward them to the super class constructor.
    var positionalArguments = <Expression>[];
    for (var variable in positionalParameters) {
      positionalArguments.add(new VariableGet(variable));
    }
    var namedArguments = <NamedExpression>[];
    for (var variable in namedParameters) {
      namedArguments
          .add(new NamedExpression(variable.name, new VariableGet(variable)));
    }
    var superInitializer = new SuperInitializer(superclassConstructor,
        new Arguments(positionalArguments, named: namedArguments));

    // Assemble the constructor.
    return new Constructor(function,
        name: superclassConstructor.name,
        initializers: <Initializer>[superInitializer]);
  }
}

class SuperCallResolutionTransformer extends Transformer {
  final ClassHierarchy hierarchy;
  final CoreTypes coreTypes;
  final Class lookupClass;
  Constructor _invocationMirrorConstructor; // cached
  Procedure _listFrom; // cached

  SuperCallResolutionTransformer(
      this.hierarchy, this.coreTypes, this.lookupClass);

  TreeNode visit(TreeNode node) => node.accept(this);

  visitSuperPropertyGet(SuperPropertyGet node) {
    Member target = hierarchy.getDispatchTarget(lookupClass, node.name);
    if (target != null) {
      return new DirectPropertyGet(new ThisExpression(), target);
    } else {
      return _callNoSuchMethod(node.name.name, new Arguments.empty(), node,
          isGetter: true);
    }
  }

  visitSuperPropertySet(SuperPropertySet node) {
    Member target =
        hierarchy.getDispatchTarget(lookupClass, node.name, setter: true);
    if (target != null) {
      return new DirectPropertySet(
          new ThisExpression(), target, visit(node.value));
    } else {
      // Call has to return right-hand-side.
      VariableDeclaration rightHandSide =
          new VariableDeclaration.forValue(visit(node.value));
      Expression result = _callNoSuchMethod(
          node.name.name, new Arguments([new VariableGet(rightHandSide)]), node,
          isSetter: true);
      VariableDeclaration call = new VariableDeclaration.forValue(result);
      return new Let(
          rightHandSide, new Let(call, new VariableGet(rightHandSide)));
    }
  }

  visitSuperMethodInvocation(SuperMethodInvocation node) {
    Member target = hierarchy.getDispatchTarget(lookupClass, node.name);
    Arguments visitedArguments = visit(node.arguments);
    if (target is Procedure &&
        !target.isAccessor &&
        _callIsLegal(target.function, visitedArguments)) {
      return new DirectMethodInvocation(
          new ThisExpression(), target, visitedArguments)
        ..fileOffset = node.fileOffset;
    } else if (target == null || (target is Procedure && !target.isAccessor)) {
      // Target not found at all, or call was illegal.
      return _callNoSuchMethod(node.name.name, visitedArguments, node,
          isSuper: true);
    } else if (target != null) {
      return new MethodInvocation(
          new DirectPropertyGet(new ThisExpression(), target),
          new Name('call'),
          visitedArguments)..fileOffset = node.fileOffset;
    }
  }

  /// Create a call to no such method.
  Expression _callNoSuchMethod(
      String methodName, Arguments methodArguments, TreeNode node,
      {isSuper: false, isGetter: false, isSetter: false}) {
    Member noSuchMethod =
        hierarchy.getDispatchTarget(lookupClass, new Name("noSuchMethod"));
    String methodNameUsed = (isGetter)
        ? "get:$methodName"
        : (isSetter) ? "set:$methodName" : methodName;
    if (noSuchMethod != null &&
        noSuchMethod.function.positionalParameters.length == 1 &&
        noSuchMethod.function.namedParameters.isEmpty) {
      // We have a correct noSuchMethod method.
      ConstructorInvocation invocation = _createInvocation(
          methodNameUsed, methodArguments, isSuper, new ThisExpression());
      return new DirectMethodInvocation(
          new ThisExpression(), noSuchMethod, new Arguments([invocation]))
        ..fileOffset = node.fileOffset;
    } else {
      // Incorrect noSuchMethod method: Call noSuchMethod on Object
      // with Invocation of noSuchMethod as the method that did not exist.
      noSuchMethod = hierarchy.getDispatchTarget(
          hierarchy.rootClass, new Name("noSuchMethod"));
      ConstructorInvocation invocation = _createInvocation(
          methodNameUsed, methodArguments, isSuper, new ThisExpression());
      ConstructorInvocation invocationPrime = _createInvocation("noSuchMethod",
          new Arguments([invocation]), false, new ThisExpression());
      return new DirectMethodInvocation(
          new ThisExpression(), noSuchMethod, new Arguments([invocationPrime]))
        ..fileOffset = node.fileOffset;
    }
  }

  /// Creates an "new _InvocationMirror(...)" invocation.
  ConstructorInvocation _createInvocation(String methodName,
      Arguments callArguments, bool isSuperInvocation, Expression receiver) {
    if (_invocationMirrorConstructor == null) {
      Class clazz = coreTypes.getCoreClass('dart:core', '_InvocationMirror');
      _invocationMirrorConstructor = clazz.constructors[0];
    }

    // The _InvocationMirror constructor takes the following arguments:
    // * Method name (a string).
    // * An arguments descriptor - a list consisting of:
    //   - number of arguments (including receiver).
    //   - number of positional arguments (including receiver).
    //   - pairs (2 entries in the list) of
    //     * named arguments name.
    //     * index of named argument in arguments list.
    // * A list of arguments, where the first ones are the positional arguments.
    // * Whether it's a super invocation or not.

    int numPositionalArguments = callArguments.positional.length + 1;
    int numArguments = numPositionalArguments + callArguments.named.length;
    List<Expression> argumentsDescriptor = [
      new IntLiteral(numArguments),
      new IntLiteral(numPositionalArguments)
    ];
    List<Expression> arguments = [];
    arguments.add(receiver);
    for (Expression pos in callArguments.positional) {
      arguments.add(pos);
    }
    for (NamedExpression named in callArguments.named) {
      argumentsDescriptor.add(new StringLiteral(named.name));
      argumentsDescriptor.add(new IntLiteral(arguments.length));
      arguments.add(named.value);
    }

    return new ConstructorInvocation(
        _invocationMirrorConstructor,
        new Arguments([
          new StringLiteral(methodName),
          _fixedLengthList(argumentsDescriptor),
          _fixedLengthList(arguments),
          new BoolLiteral(isSuperInvocation)
        ]));
  }

  /// Create a fixed length list containing given expressions.
  Expression _fixedLengthList(List<Expression> list) {
    if (_listFrom == null) {
      Class clazz = coreTypes.getCoreClass('dart:core', 'List');
      _listFrom = clazz.procedures.firstWhere((c) => c.name.name == "from");
    }
    return new StaticInvocation(
        _listFrom,
        new Arguments([new ListLiteral(list)],
            named: [new NamedExpression("growable", new BoolLiteral(false))]));
  }

  /// Check that a call to the targetFunction is legal given the arguments.
  ///
  /// I.e. check that the number of positional parameters and the names of the
  /// given named parameters represents a valid call to the function.
  bool _callIsLegal(FunctionNode targetFunction, Arguments arguments) {
    if ((targetFunction.requiredParameterCount > arguments.positional.length) ||
        (targetFunction.positionalParameters.length <
            arguments.positional.length)) {
      // Given too few or too many positional arguments
      return false;
    }

    // Do we give named that we don't take?
    Set<String> givenNamed = arguments.named.map((v) => v.name).toSet();
    Set<String> takenNamed =
        targetFunction.namedParameters.map((v) => v.name).toSet();
    givenNamed.removeAll(takenNamed);
    return givenNamed.isEmpty;
  }
}

class SuperInitializerResolutionTransformer extends InitializerVisitor {
  final Class lookupClass;

  SuperInitializerResolutionTransformer(this.lookupClass);

  transformInitializers(List<Initializer> initializers) {
    for (var initializer in initializers) {
      initializer.accept(this);
    }
  }

  visitSuperInitializer(SuperInitializer node) {
    Constructor constructor = node.target;
    if (constructor.enclosingClass != lookupClass) {
      // If [node] refers to a constructor target which is not directly the
      // superclass but some indirect base class then this is because classes in
      // the middle are mixin applications.  These mixin applications will have
      // received a forwarding constructor which we are required to use instead.
      for (var replacement in lookupClass.constructors) {
        if (constructor.name == replacement.name) {
          node.target = replacement;
          return null;
        }
      }

      throw new Exception(
          'Could not find a generative constructor named "${constructor.name}" '
          'in lookup class "${lookupClass.name}"!');
    }
  }
}
