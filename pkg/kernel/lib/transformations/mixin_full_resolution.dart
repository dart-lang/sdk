// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.mixin_full_resolution;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../clone.dart';
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

    // Resolve all super call expressions and super initializers.
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        final bool hasTransformedSuperclass =
            transformedClasses.contains(class_.superclass);

        for (var procedure in class_.procedures) {
          if (procedure.containsSuperCalls) {
            new SuperCallResolutionTransformer(hierarchy, class_.superclass)
                .visit(procedure);
          }
        }
        for (var constructor in class_.constructors) {
          if (constructor.containsSuperCalls) {
            new SuperCallResolutionTransformer(hierarchy, class_.superclass)
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
    var superclassSubstitution = getSubstitutionMap(class_.supertype);
    var superclassCloner =
        new CloneVisitor(typeSubstitution: superclassSubstitution);
    for (var superclassConstructor in class_.superclass.constructors) {
      var forwardingConstructor =
          buildForwardingConstructor(superclassCloner, superclassConstructor);
      class_.constructors.add(forwardingConstructor..parent = class_);
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
  final Class lookupClass;

  SuperCallResolutionTransformer(this.hierarchy, this.lookupClass);

  TreeNode visit(TreeNode node) => node.accept(this);

  visitSuperPropertyGet(SuperPropertyGet node) {
    Member target = hierarchy.getDispatchTarget(lookupClass, node.name);
    if (target != null) {
      return new DirectPropertyGet(new ThisExpression(), target);
    } else {
      // TODO(asgerf): Invoke super.noSuchMethod.
      return new InvalidExpression();
    }
  }

  visitSuperPropertySet(SuperPropertySet node) {
    Member target =
        hierarchy.getDispatchTarget(lookupClass, node.name, setter: true);
    if (target != null) {
      return new DirectPropertySet(
          new ThisExpression(), target, visit(node.value));
    } else {
      return new InvalidExpression();
    }
  }

  visitSuperMethodInvocation(SuperMethodInvocation node) {
    Member target = hierarchy.getDispatchTarget(lookupClass, node.name);
    if (target is Procedure && !target.isAccessor) {
      return new DirectMethodInvocation(
          new ThisExpression(), target, visit(node.arguments));
    } else if (target != null) {
      return new MethodInvocation(
          new DirectPropertyGet(new ThisExpression(), target),
          new Name('call'),
          visit(node.arguments));
    } else {
      return new InvalidExpression();
    }
  }
}

class SuperInitializerResolutionTransformer extends Transformer {
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
          return;
        }
      }

      throw new Exception(
          'Could not find a generative constructor named "${constructor.name}" '
          'in lookup class "${lookupClass.name}"!');
    }
  }
}
