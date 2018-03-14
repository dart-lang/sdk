// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.mixin_full_resolution;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../clone.dart';
import '../core_types.dart';
import '../target/targets.dart' show Target;
import '../type_algebra.dart';

void transformLibraries(Target targetInfo, CoreTypes coreTypes,
    ClassHierarchy hierarchy, List<Library> libraries,
    {bool doSuperResolution: true}) {
  new MixinFullResolution(targetInfo, coreTypes, hierarchy,
          doSuperResolution: doSuperResolution)
      .transform(libraries);
}

/// Replaces all mixin applications with regular classes, cloning all fields
/// and procedures from the mixed-in class, cloning all constructors from the
/// base class.
///
/// When [doSuperResolution] constructor parameter is [true], super calls
/// (as well as super initializer invocations) are also resolved to their
/// targets in this pass.
class MixinFullResolution {
  final Target targetInfo;
  final CoreTypes coreTypes;

  /// The [ClassHierarchy] that should be used after applying this transformer.
  /// If any class was updated, in general we need to create a new
  /// [ClassHierarchy] instance, with new dispatch targets; or at least let
  /// the existing instance know that some of its dispatch tables are not
  /// valid anymore.
  ClassHierarchy hierarchy;

  // This enables `super` resolution transformation, which is not compatible
  // with Dart VM's requirements around incremental compilation and has been
  // moved to Dart VM itself.
  final bool doSuperResolution;

  MixinFullResolution(this.targetInfo, this.coreTypes, this.hierarchy,
      {this.doSuperResolution: true});

  /// Transform the given new [libraries].  It is expected that all other
  /// libraries have already been transformed.
  void transform(List<Library> libraries) {
    if (libraries.isEmpty) return;

    var transformedClasses = new Set<Class>();

    // Desugar all mixin application classes by copying in fields/methods from
    // the mixin and constructors from the base class.
    var processedClasses = new Set<Class>();
    for (var library in libraries) {
      if (library.isExternal) continue;

      for (var class_ in library.classes) {
        transformClass(libraries, processedClasses, transformedClasses, class_);
      }
    }

    // We might need to update the class hierarchy.
    hierarchy = hierarchy.applyChanges(transformedClasses);

    if (!doSuperResolution) {
      return;
    }
    // Resolve all super call expressions and super initializers.
    for (var library in libraries) {
      if (library.isExternal) continue;

      for (var class_ in library.classes) {
        final bool hasTransformedSuperclass =
            transformedClasses.contains(class_.superclass);

        for (var procedure in class_.procedures) {
          if (procedure.containsSuperCalls) {
            new SuperCallResolutionTransformer(
                    hierarchy, coreTypes, class_.superclass, targetInfo)
                .visit(procedure);
          }
        }
        for (var constructor in class_.constructors) {
          if (constructor.containsSuperCalls) {
            new SuperCallResolutionTransformer(
                    hierarchy, coreTypes, class_.superclass, targetInfo)
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

  transformClass(
      List<Library> librariesToBeTransformed,
      Set<Class> processedClasses,
      Set<Class> transformedClasses,
      Class class_) {
    // If this class was already handled then so were all classes up to the
    // [Object] class.
    if (!processedClasses.add(class_)) return;

    if (!librariesToBeTransformed.contains(class_.enclosingLibrary) &&
        class_.enclosingLibrary.importUri?.scheme == "dart") {
      // If we're not asked to transform the platform libraries then we expect
      // that they will be already transformed.
      return;
    }

    // Ensure super classes have been transformed before this class.
    if (class_.superclass != null &&
        class_.superclass.level.index >= ClassLevel.Mixin.index) {
      transformClass(librariesToBeTransformed, processedClasses,
          transformedClasses, class_.superclass);
    }

    // If this is not a mixin application we don't need to make forwarding
    // constructors in this class.
    if (!class_.isMixinApplication) return;
    assert(librariesToBeTransformed.contains(class_.enclosingLibrary));

    if (class_.mixedInClass.level.index < ClassLevel.Mixin.index) {
      throw new Exception(
          'Class "${class_.name}" mixes in "${class_.mixedInClass.name}" from'
          ' an external library.  Did you forget --link?');
    }

    transformedClasses.add(class_);

    // Clone fields and methods from the mixin class.
    var substitution = getSubstitutionMap(class_.mixedInType);
    var cloner = new CloneVisitor(typeSubstitution: substitution);

    // When we copy a field from the mixed in class, we remove any
    // forwarding-stub getters/setters from the superclass, but copy their
    // covariance-bits onto the new field.
    var nonSetters = <Name, Procedure>{};
    var setters = <Name, Procedure>{};
    for (var procedure in class_.procedures) {
      if (procedure.isSetter) {
        setters[procedure.name] = procedure;
      } else {
        nonSetters[procedure.name] = procedure;
      }
    }
    for (var field in class_.mixin.fields) {
      Field clone = cloner.clone(field);
      Procedure setter = setters[field.name];
      if (setter != null) {
        setters.remove(field.name);
        VariableDeclaration parameter =
            setter.function.positionalParameters.first;
        clone.isGenericCovariantImpl = parameter.isGenericCovariantImpl;
        clone.isGenericCovariantInterface =
            parameter.isGenericCovariantInterface;
      }
      nonSetters.remove(field.name);
      class_.addMember(clone);
    }
    class_.procedures.clear();
    class_.procedures..addAll(nonSetters.values)..addAll(setters.values);

    // Existing procedures in the class should only be forwarding stubs.
    // Replace them with methods from the mixin class if they have the same
    // name, but keep their parameter flags.
    int originalLength = class_.procedures.length;
    outer:
    for (var procedure in class_.mixin.procedures) {
      // Forwarding stubs in the mixin class are used when calling through the
      // mixin class's interface, not when calling through the mixin
      // application.  They should not be copied.
      if (procedure.isForwardingStub) continue;

      // Factory constructors are not cloned.
      if (procedure.isFactory) continue;

      Procedure clone = cloner.clone(procedure);
      // Linear search for a forwarding stub with the same name.
      for (int i = 0; i < originalLength; ++i) {
        var originalProcedure = class_.procedures[i];
        if (originalProcedure.name == clone.name &&
            originalProcedure.kind == clone.kind) {
          FunctionNode src = originalProcedure.function;
          FunctionNode dst = clone.function;

          if (src.positionalParameters.length !=
                  dst.positionalParameters.length ||
              src.namedParameters.length != dst.namedParameters.length) {
            // A compile time error has already occured, but don't crash below,
            // and don't add several procedures with the same name to the class.
            continue outer;
          }

          assert(src.typeParameters.length == dst.typeParameters.length);
          for (int j = 0; j < src.typeParameters.length; ++j) {
            dst.typeParameters[j].flags = src.typeParameters[i].flags;
          }
          for (int j = 0; j < src.positionalParameters.length; ++j) {
            dst.positionalParameters[j].flags =
                src.positionalParameters[j].flags;
          }
          // TODO(kernel team): The named parameters are not sorted,
          // this might not be correct.
          for (int j = 0; j < src.namedParameters.length; ++j) {
            dst.namedParameters[j].flags = src.namedParameters[j].flags;
          }

          class_.procedures[i] = clone;
          continue outer;
        }
      }
      class_.addMember(clone);
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
        class_.addMember(forwardingConstructor);
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
        initializers: <Initializer>[superInitializer],
        isSynthetic: true);
  }
}

class SuperCallResolutionTransformer extends Transformer {
  final ClassHierarchy hierarchy;
  final CoreTypes coreTypes;
  final Class lookupClass;
  final Target targetInfo;

  SuperCallResolutionTransformer(
      this.hierarchy, this.coreTypes, this.lookupClass, this.targetInfo);

  TreeNode visit(TreeNode node) => node.accept(this);

  visitSuperPropertyGet(SuperPropertyGet node) {
    Member target = hierarchy.getDispatchTarget(lookupClass, node.name);
    if (target != null) {
      return new DirectPropertyGet(new ThisExpression(), target)
        ..fileOffset = node.fileOffset;
    } else {
      return _callNoSuchMethod(node.name.name, new Arguments.empty(), node,
          isGetter: true, isSuper: true);
    }
  }

  visitSuperPropertySet(SuperPropertySet node) {
    Member target =
        hierarchy.getDispatchTarget(lookupClass, node.name, setter: true);
    if (target != null) {
      return new DirectPropertySet(
          new ThisExpression(), target, visit(node.value))
        ..fileOffset = node.fileOffset;
    } else {
      // Call has to return right-hand-side.
      VariableDeclaration rightHandSide =
          new VariableDeclaration.forValue(visit(node.value));
      Expression result = _callNoSuchMethod(
          node.name.name, new Arguments([new VariableGet(rightHandSide)]), node,
          isSetter: true, isSuper: true);
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
          visitedArguments)
        ..fileOffset = node.fileOffset;
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
          coreTypes.objectClass, new Name("noSuchMethod"));
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
    return targetInfo.instantiateInvocation(
        coreTypes, receiver, methodName, callArguments, -1, isSuperInvocation);
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
