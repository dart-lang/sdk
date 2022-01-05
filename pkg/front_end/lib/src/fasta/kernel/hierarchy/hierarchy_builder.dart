// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchyBase;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/types.dart' show Types;
import 'package:kernel/type_algebra.dart' show Substitution, uniteNullabilities;

import '../../builder/class_builder.dart';
import '../../builder/type_builder.dart';
import '../../loader.dart' show Loader;
import '../../source/source_loader.dart' show SourceLoader;
import 'hierarchy_node.dart';

class ClassHierarchyBuilder implements ClassHierarchyBase {
  final Map<Class, ClassHierarchyNode> nodes = <Class, ClassHierarchyNode>{};

  final Map<ClassBuilder, Map<Class, Substitution>> substitutions =
      <ClassBuilder, Map<Class, Substitution>>{};

  final ClassBuilder objectClassBuilder;

  final Loader loader;

  final Class objectClass;

  final Class futureClass;

  final Class functionClass;

  @override
  final CoreTypes coreTypes;

  late Types types;

  ClassHierarchyBuilder(this.objectClassBuilder, this.loader, this.coreTypes)
      : objectClass = objectClassBuilder.cls,
        futureClass = coreTypes.futureClass,
        functionClass = coreTypes.functionClass {
    types = new Types(this);
  }

  void clear() {
    nodes.clear();
    substitutions.clear();
  }

  ClassHierarchyNode getNodeFromClassBuilder(ClassBuilder classBuilder) {
    return nodes[classBuilder.cls] ??= new ClassHierarchyNodeBuilder(
            this, classBuilder, substitutions[classBuilder] ??= {})
        .build();
  }

  ClassHierarchyNode? getNodeFromTypeBuilder(TypeBuilder type) {
    ClassBuilder? cls = getClass(type);
    return cls == null ? null : getNodeFromClassBuilder(cls);
  }

  ClassHierarchyNode getNodeFromClass(Class cls) {
    return nodes[cls] ??
        getNodeFromClassBuilder(loader.computeClassBuilderFromTargetClass(cls));
  }

  Supertype? asSupertypeOf(InterfaceType subtype, Class supertype) {
    if (subtype.classNode == supertype) {
      return new Supertype(supertype, subtype.typeArguments);
    }
    ClassHierarchyNode clsNode = getNodeFromClass(subtype.classNode);
    ClassHierarchyNode supertypeNode = getNodeFromClass(supertype);
    List<Supertype> superclasses = clsNode.superclasses;
    int depth = supertypeNode.depth;
    if (depth < superclasses.length) {
      Supertype superclass = superclasses[depth];
      if (superclass.classNode == supertype) {
        return Substitution.fromInterfaceType(subtype)
            .substituteSupertype(superclass);
      }
    }
    List<Supertype> superinterfaces = clsNode.interfaces;
    for (int i = 0; i < superinterfaces.length; i++) {
      Supertype superinterface = superinterfaces[i];
      if (superinterface.classNode == supertype) {
        return Substitution.fromInterfaceType(subtype)
            .substituteSupertype(superinterface);
      }
    }
    return null;
  }

  @override
  InterfaceType getTypeAsInstanceOf(
      InterfaceType type, Class superclass, Library clientLibrary) {
    if (type.classNode == superclass) return type;
    return asSupertypeOf(type, superclass)!
        .asInterfaceType
        .withDeclaredNullability(type.nullability);
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    if (type.classNode == superclass) return type.typeArguments;
    return asSupertypeOf(type, superclass)?.typeArguments;
  }

  @override
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2, Library clientLibrary) {
    if (type1 == type2) return type1;

    // LLUB(Null, List<dynamic>*) works differently for opt-in and opt-out
    // libraries.  In opt-out libraries the legacy behavior is preserved, so
    // LLUB(Null, List<dynamic>*) = List<dynamic>*.  In opt-out libraries the
    // rules imply that LLUB(Null, List<dynamic>*) = List<dynamic>?.
    if (!clientLibrary.isNonNullableByDefault) {
      if (type1 is NullType) {
        return type2;
      }
      if (type2 is NullType) {
        return type1;
      }
    }

    ClassHierarchyNode node1 = getNodeFromClass(type1.classNode);
    ClassHierarchyNode node2 = getNodeFromClass(type2.classNode);
    Set<ClassHierarchyNode> nodes1 = node1.computeAllSuperNodes(this).toSet();
    List<ClassHierarchyNode> nodes2 = node2.computeAllSuperNodes(this);
    List<ClassHierarchyNode> common = <ClassHierarchyNode>[];

    for (int i = 0; i < nodes2.length; i++) {
      ClassHierarchyNode node = nodes2[i];
      // ignore: unnecessary_null_comparison
      if (node == null) continue;
      if (node.classBuilder.cls.isAnonymousMixin) {
        // Never find unnamed mixin application in least upper bound.
        continue;
      }
      if (nodes1.contains(node)) {
        DartType candidate1 =
            getTypeAsInstanceOf(type1, node.classBuilder.cls, clientLibrary);
        DartType candidate2 =
            getTypeAsInstanceOf(type2, node.classBuilder.cls, clientLibrary);
        if (candidate1 == candidate2) {
          common.add(node);
        }
      }
    }

    if (common.length == 1) {
      return coreTypes.objectRawType(
          uniteNullabilities(type1.nullability, type2.nullability));
    }
    common.sort(ClassHierarchyNode.compareMaxInheritancePath);

    for (int i = 0; i < common.length - 1; i++) {
      ClassHierarchyNode node = common[i];
      if (node.maxInheritancePath != common[i + 1].maxInheritancePath) {
        return getTypeAsInstanceOf(type1, node.classBuilder.cls, clientLibrary)
            .withDeclaredNullability(
                uniteNullabilities(type1.nullability, type2.nullability));
      } else {
        do {
          i++;
        } while (node.maxInheritancePath == common[i + 1].maxInheritancePath);
      }
    }
    return coreTypes.objectRawType(
        uniteNullabilities(type1.nullability, type2.nullability));
  }

  static ClassHierarchyBuilder build(ClassBuilder objectClass,
      List<ClassBuilder> classes, SourceLoader loader, CoreTypes coreTypes) {
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, coreTypes);
    for (int i = 0; i < classes.length; i++) {
      ClassBuilder classBuilder = classes[i];
      if (!classBuilder.isPatch) {
        hierarchy.nodes[classBuilder.cls] = new ClassHierarchyNodeBuilder(
                hierarchy,
                classBuilder,
                hierarchy.substitutions[classBuilder] ??= {})
            .build();
      } else {
        // TODO(ahe): Merge the injected members of patch into the hierarchy
        // node of `cls.origin`.
      }
    }
    return hierarchy;
  }
}
