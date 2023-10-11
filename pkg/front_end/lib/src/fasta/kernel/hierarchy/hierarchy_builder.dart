// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchyBase, ClassHierarchyExtensionTypeMixin;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/types.dart' show Types;
import 'package:kernel/type_algebra.dart' show Substitution, uniteNullabilities;

import '../../builder/declaration_builders.dart';
import '../../loader.dart' show Loader;
import '../../source/source_class_builder.dart';
import '../../source/source_extension_type_declaration_builder.dart';
import '../../source/source_loader.dart' show SourceLoader;
import 'hierarchy_node.dart';

class ClassHierarchyBuilder
    with ClassHierarchyExtensionTypeMixin
    implements ClassHierarchyBase {
  final Map<Class, ClassHierarchyNode> classNodes = {};

  final Map<ExtensionTypeDeclaration, ExtensionTypeHierarchyNode>
      extensionTypeNodes = {};

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
    classNodes.clear();
    extensionTypeNodes.clear();
  }

  ClassHierarchyNode getNodeFromClassBuilder(ClassBuilder classBuilder) {
    return classNodes[classBuilder.cls] ??=
        new ClassHierarchyNodeBuilder(this, classBuilder).build();
  }

  ClassHierarchyNode getNodeFromClass(Class cls) {
    return classNodes[cls] ??
        getNodeFromClassBuilder(loader.computeClassBuilderFromTargetClass(cls));
  }

  ExtensionTypeHierarchyNode getNodeFromExtensionTypeDeclarationBuilder(
      ExtensionTypeDeclarationBuilder extensionTypeBuilder) {
    return extensionTypeNodes[extensionTypeBuilder.extensionTypeDeclaration] ??=
        new ExtensionTypeHierarchyNodeBuilder(this, extensionTypeBuilder)
            .build();
  }

  ExtensionTypeHierarchyNode getNodeFromExtensionType(
      ExtensionTypeDeclaration extensionType) {
    return extensionTypeNodes[extensionType] ??
        getNodeFromExtensionTypeDeclarationBuilder(loader
            .computeExtensionTypeBuilderFromTargetExtensionType(extensionType));
  }

  Supertype? asSupertypeOf(InterfaceType subtype, Class supertype) {
    if (subtype.classNode == supertype) {
      return new Supertype(supertype, subtype.typeArguments);
    }
    Supertype? cls = getClassAsInstanceOf(subtype.classNode, supertype);
    if (cls != null) {
      return Substitution.fromInterfaceType(subtype).substituteSupertype(cls);
    }
    return null;
  }

  @override
  Supertype? getClassAsInstanceOf(Class subclass, Class superclass) {
    if (identical(subclass, superclass)) return subclass.asThisSupertype;
    ClassHierarchyNode clsNode = getNodeFromClass(subclass);
    ClassHierarchyNode supertypeNode = getNodeFromClass(superclass);
    List<Supertype> superclasses = clsNode.superclasses;
    int depth = supertypeNode.depth;
    if (depth < superclasses.length) {
      Supertype cls = superclasses[depth];
      if (cls.classNode == superclass) {
        return cls;
      }
    }
    List<Supertype> superinterfaces = clsNode.interfaces;
    for (int i = 0; i < superinterfaces.length; i++) {
      Supertype interface = superinterfaces[i];
      if (interface.classNode == superclass) {
        return interface;
      }
    }
    return null;
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      {required bool isNonNullableByDefault}) {
    if (type.classNode == superclass) return type;
    return asSupertypeOf(type, superclass)!
        .asInterfaceType
        .withDeclaredNullability(type.nullability);
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    if (type.classReference == superclass.reference) return type.typeArguments;
    return asSupertypeOf(type, superclass)?.typeArguments;
  }

  @override
  bool isSubtypeOf(Class subtype, Class superclass) {
    return getClassAsInstanceOf(subtype, superclass) != null;
  }

  @override
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2,
      {required bool isNonNullableByDefault}) {
    if (type1 == type2) return type1;

    // LLUB(Null, List<dynamic>*) works differently for opt-in and opt-out
    // libraries.  In opt-out libraries the legacy behavior is preserved, so
    // LLUB(Null, List<dynamic>*) = List<dynamic>*.  In opt-out libraries the
    // rules imply that LLUB(Null, List<dynamic>*) = List<dynamic>?.
    if (!isNonNullableByDefault) {
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
      if (node.classBuilder.cls.isAnonymousMixin) {
        // Never find unnamed mixin application in least upper bound.
        continue;
      }
      if (nodes1.contains(node)) {
        DartType candidate1 = getTypeAsInstanceOf(type1, node.classBuilder.cls,
            isNonNullableByDefault: isNonNullableByDefault);
        DartType candidate2 = getTypeAsInstanceOf(type2, node.classBuilder.cls,
            isNonNullableByDefault: isNonNullableByDefault);
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
        return getTypeAsInstanceOf(type1, node.classBuilder.cls,
                isNonNullableByDefault: isNonNullableByDefault)
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

  static ClassHierarchyBuilder build(
      ClassBuilder objectClass,
      List<SourceClassBuilder> classes,
      List<SourceExtensionTypeDeclarationBuilder> extensionTypes,
      SourceLoader loader,
      CoreTypes coreTypes) {
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, coreTypes);
    for (int i = 0; i < classes.length; i++) {
      SourceClassBuilder classBuilder = classes[i];
      assert(!classBuilder.isPatch);
      hierarchy.classNodes[classBuilder.cls] =
          new ClassHierarchyNodeBuilder(hierarchy, classBuilder).build();
    }
    for (int i = 0; i < extensionTypes.length; i++) {
      SourceExtensionTypeDeclarationBuilder extensionTypeBuilder =
          extensionTypes[i];
      assert(!extensionTypeBuilder.isPatch);
      hierarchy.extensionTypeNodes[
              extensionTypeBuilder.extensionTypeDeclaration] =
          new ExtensionTypeHierarchyNodeBuilder(hierarchy, extensionTypeBuilder)
              .build();
    }
    return hierarchy;
  }
}
