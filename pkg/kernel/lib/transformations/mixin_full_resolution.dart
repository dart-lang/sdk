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
/// and procedures from the mixed-in class.
///
/// Super calls are also resolved to their targets in this pass.
class MixinFullResolution {
  ClassHierarchy hierarchy;

  void transform(Program program) {
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
        if (class_.isMixinApplication) {
          var substitution = getSubstitutionMap(class_.mixedInType);
          var cloner = new CloneVisitor(typeSubstitution: substitution);
          for (var field in class_.mixin.fields) {
            class_.addMember(cloner.clone(field));
          }
          for (var procedure in class_.mixin.procedures) {
            class_.addMember(cloner.clone(procedure));
          }
          class_.implementedTypes.add(class_.mixedInType);
          class_.mixedInType = null;
          if (class_.constructors.isEmpty) {
            // The Dart VM does not like classes without any members, so
            // make sure there is at least one member.
            class_.addMember(
                new Constructor(new FunctionNode(new EmptyStatement())));
          }
        }
      }
    }

    hierarchy = new ClassHierarchy(program);

    // Resolve super calls.
    for (var library in program.libraries) {
      for (var class_ in library.classes) {
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
        }
      }
    }
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
