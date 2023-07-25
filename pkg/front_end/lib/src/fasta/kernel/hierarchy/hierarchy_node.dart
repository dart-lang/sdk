// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/nnbd_top_merge.dart';
import 'package:kernel/src/norm.dart';
import 'package:kernel/type_algebra.dart' show Substitution;

import '../../../testing/id_testing_utils.dart' show typeToText;
import '../../builder/builder.dart';
import '../../builder/class_builder.dart';
import '../../builder/library_builder.dart';
import '../../builder/named_type_builder.dart';
import '../../builder/type_alias_builder.dart';
import '../../builder/type_builder.dart';
import '../../fasta_codes.dart';
import '../../source/source_library_builder.dart';
import '../../type_inference/type_schema.dart' show UnknownType;
import 'hierarchy_builder.dart';
import 'mixin_inferrer.dart';

class ClassHierarchyNodeBuilder {
  final ClassHierarchyBuilder hierarchy;

  final ClassBuilder classBuilder;

  bool hasNoSuchMethod = false;

  ClassHierarchyNodeBuilder(this.hierarchy, this.classBuilder);

  ClassBuilder get objectClass => hierarchy.objectClassBuilder;

  ClassHierarchyNode build() {
    assert(!classBuilder.isPatch);
    ClassHierarchyNode? supernode;
    if (objectClass != classBuilder.origin) {
      supernode =
          hierarchy.getNodeFromTypeBuilder(classBuilder.supertypeBuilder!);
      if (supernode == null) {
        supernode = hierarchy.getNodeFromClassBuilder(objectClass);
      }
    }

    List<Supertype> superclasses;
    List<Supertype> interfacesList;
    int maxInheritancePath;

    ClassHierarchyNode? mixedInNode;
    List<ClassHierarchyNode>? interfaceNodes;

    if (classBuilder.isMixinApplication) {
      mixedInNode = inferMixinApplication();
    }

    if (supernode == null) {
      // This should be Object.
      superclasses = new List<Supertype>.filled(0, dummySupertype);
      interfacesList = new List<Supertype>.filled(0, dummySupertype);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;

      superclasses = new List<Supertype>.filled(
          supernode.superclasses.length + 1, dummySupertype);
      Supertype? supertype = classBuilder.supertypeBuilder!
          .buildSupertype(classBuilder.libraryBuilder);
      if (supertype == null) {
        // If the superclass is not an interface type we use Object instead.
        // A similar normalization is performed on [supernode] above.
        supertype =
            new Supertype(hierarchy.coreTypes.objectClass, const <DartType>[]);
      }
      superclasses.setRange(0, superclasses.length - 1,
          substSupertypes(supertype, supernode.superclasses));
      superclasses[superclasses.length - 1] = supertype;
      if (!classBuilder.libraryBuilder.isNonNullableByDefault &&
          supernode.classBuilder.libraryBuilder.isNonNullableByDefault) {
        for (int i = 0; i < superclasses.length; i++) {
          superclasses[i] = legacyErasureSupertype(superclasses[i]);
        }
      }

      List<TypeBuilder>? directInterfaceBuilders =
          ignoreFunction(classBuilder.interfaceBuilders);
      if (classBuilder.isMixinApplication) {
        if (directInterfaceBuilders == null) {
          directInterfaceBuilders = <TypeBuilder>[
            classBuilder.mixedInTypeBuilder!
          ];
        } else {
          directInterfaceBuilders = <TypeBuilder>[
            classBuilder.mixedInTypeBuilder!
          ]..addAll(directInterfaceBuilders);
        }
      }

      List<Supertype> superclassInterfaces = supernode.interfaces;
      if (superclassInterfaces.isNotEmpty) {
        superclassInterfaces = substSupertypes(supertype, superclassInterfaces);
      }

      if (directInterfaceBuilders != null) {
        Map<Class, Supertype> interfaces = {};
        if (superclassInterfaces.isNotEmpty) {
          for (int i = 0; i < superclassInterfaces.length; i++) {
            addInterface(interfaces, superclasses, superclassInterfaces[i]);
          }
        }

        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          Supertype? directInterface = directInterfaceBuilders[i]
              .buildSupertype(classBuilder.libraryBuilder);
          if (directInterface != null) {
            addInterface(interfaces, superclasses, directInterface);
            ClassHierarchyNode interfaceNode =
                hierarchy.getNodeFromClass(directInterface.classNode);
            (interfaceNodes ??= []).add(interfaceNode);

            if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
              maxInheritancePath = interfaceNode.maxInheritancePath + 1;
            }

            List<Supertype> types =
                substSupertypes(directInterface, interfaceNode.superclasses);
            for (int i = 0; i < types.length; i++) {
              addInterface(interfaces, superclasses, types[i]);
            }
            if (interfaceNode.interfaces.isNotEmpty) {
              List<Supertype> types =
                  substSupertypes(directInterface, interfaceNode.interfaces);
              for (int i = 0; i < types.length; i++) {
                addInterface(interfaces, superclasses, types[i]);
              }
            }
          }
        }
        interfacesList = interfaces.values.toList();
      } else if (superclassInterfaces.isNotEmpty &&
          !classBuilder.libraryBuilder.isNonNullableByDefault &&
          supernode.classBuilder.libraryBuilder.isNonNullableByDefault) {
        Map<Class, Supertype> interfaces = {};
        for (int i = 0; i < superclassInterfaces.length; i++) {
          addInterface(interfaces, superclasses, superclassInterfaces[i]);
        }
        interfacesList = interfaces.values.toList();
      } else {
        interfacesList = superclassInterfaces;
      }
    }

    return new ClassHierarchyNode(classBuilder, supernode, mixedInNode,
        interfaceNodes, superclasses, interfacesList, maxInheritancePath);
  }

  List<Supertype> substSupertypes(
      Supertype supertype, List<Supertype> supertypes) {
    List<TypeParameter> typeVariables = supertype.classNode.typeParameters;
    if (typeVariables.isEmpty) {
      debug?.log("In ${this.classBuilder.fullNameForErrors} "
          "$supertypes aren't substed");
      return supertypes;
    }
    Map<TypeParameter, DartType> map = <TypeParameter, DartType>{};
    List<DartType> arguments = supertype.typeArguments;
    for (int i = 0; i < typeVariables.length; i++) {
      map[typeVariables[i]] = arguments[i];
    }
    Substitution substitution = Substitution.fromMap(map);
    List<Supertype>? result;
    for (int i = 0; i < supertypes.length; i++) {
      Supertype supertype = supertypes[i];
      Supertype substituted = substitution.substituteSupertype(supertype);
      if (supertype != substituted) {
        debug?.log("In ${this.classBuilder.fullNameForErrors} $supertype"
            " -> $substituted");
        result ??= supertypes.toList();
        result[i] = substituted;
      } else {
        debug?.log("In ${this.classBuilder.fullNameForErrors} "
            "$supertype isn't substed");
      }
    }
    return result ?? supertypes;
  }

  Supertype _resolveSupertypeConflict(Supertype type, Supertype superclass) {
    if (classBuilder.libraryBuilder.isNonNullableByDefault) {
      Supertype? merge = nnbdTopMergeSupertype(
          hierarchy.coreTypes,
          normSupertype(hierarchy.coreTypes, superclass),
          normSupertype(hierarchy.coreTypes, type));
      if (merge != null) {
        return merge;
      }
    } else if (type == superclass) {
      return superclass;
    }
    LibraryBuilder libraryBuilder = classBuilder.libraryBuilder;
    if (libraryBuilder is SourceLibraryBuilder) {
      libraryBuilder.addProblem(
          templateAmbiguousSupertypes.withArguments(
              classBuilder.name,
              superclass.asInterfaceType,
              type.asInterfaceType,
              libraryBuilder.isNonNullableByDefault),
          classBuilder.charOffset,
          noLength,
          classBuilder.fileUri);
    }
    return superclass;
  }

  void addInterface(Map<Class, Supertype> interfaces,
      List<Supertype> superclasses, Supertype type) {
    if (!classBuilder.libraryBuilder.isNonNullableByDefault) {
      type = legacyErasureSupertype(type);
    }
    ClassHierarchyNode node = hierarchy.getNodeFromClass(type.classNode);
    int depth = node.depth;
    int myDepth = superclasses.length;
    Supertype? superclass = depth < myDepth ? superclasses[depth] : null;
    if (superclass != null && superclass.classNode == type.classNode) {
      // This is a potential conflict.
      superclasses[depth] = _resolveSupertypeConflict(type, superclass);
      return;
    } else {
      Supertype? interface = interfaces[type.classNode];
      if (interface != null) {
        // This is a potential conflict.
        interfaces[type.classNode] = _resolveSupertypeConflict(type, interface);
        return;
      }
    }
    interfaces[type.classNode] = type;
  }

  ClassHierarchyNode? inferMixinApplication() {
    Class cls = classBuilder.cls;
    Supertype? mixedInType = cls.mixedInType;
    if (mixedInType == null) return null;
    ClassHierarchyNode? mixinNode =
        hierarchy.getNodeFromClass(mixedInType.classNode);
    List<DartType> typeArguments = mixedInType.typeArguments;
    if (typeArguments.isEmpty || typeArguments.first is! UnknownType) {
      return mixinNode;
    }
    new BuilderMixinInferrer(
            classBuilder,
            hierarchy.coreTypes,
            new TypeBuilderConstraintGatherer(
                hierarchy, mixedInType.classNode.typeParameters,
                isNonNullableByDefault:
                    cls.enclosingLibrary.isNonNullableByDefault))
        .infer(cls);
    List<TypeBuilder> inferredArguments = new List<TypeBuilder>.generate(
        typeArguments.length,
        (int i) => hierarchy.loader.computeTypeBuilder(typeArguments[i]),
        growable: false);
    NamedTypeBuilder mixedInTypeBuilder =
        classBuilder.mixedInTypeBuilder as NamedTypeBuilder;
    mixedInTypeBuilder.arguments = inferredArguments;
    return mixinNode;
  }

  /// The class Function from dart:core is supposed to be ignored when used as
  /// an interface.
  List<TypeBuilder>? ignoreFunction(List<TypeBuilder>? interfaces) {
    if (interfaces == null) return null;
    for (int i = 0; i < interfaces!.length; i++) {
      ClassBuilder? classBuilder = getClass(interfaces[i]);
      if (classBuilder != null && classBuilder.cls == hierarchy.functionClass) {
        if (interfaces.length == 1) {
          return null;
        } else {
          interfaces = interfaces.toList();
          interfaces.removeAt(i);
          return ignoreFunction(interfaces);
        }
      }
    }
    return interfaces;
  }
}

class ClassHierarchyNode {
  /// The class corresponding to this hierarchy node.
  final ClassBuilder classBuilder;

  /// The [ClassHierarchyNode] for the direct super class of [classBuilder], or
  /// `null` if this is `Object`.
  final ClassHierarchyNode? directSuperClassNode;

  /// The [ClassHierarchyNode] for the mixed in class, if [classBuilder] is a
  /// mixin application, or `null` otherwise;
  final ClassHierarchyNode? mixedInNode;

  /// The [ClassHierarchyNode]s for the direct super interfaces of
  /// [classBuilder].
  final List<ClassHierarchyNode>? directInterfaceNodes;

  /// All superclasses of [classBuilder] excluding itself. The classes are
  /// sorted by depth from the root (Object) in ascending order.
  final List<Supertype> superclasses;

  /// The list of all classes implemented by [classBuilder] and its supertypes
  /// excluding any classes from [superclasses].
  final List<Supertype> interfaces;

  /// The longest inheritance path from [classBuilder] to `Object`.
  final int maxInheritancePath;

  int get depth => superclasses.length;

  ClassHierarchyNode(
      this.classBuilder,
      this.directSuperClassNode,
      this.mixedInNode,
      this.directInterfaceNodes,
      this.superclasses,
      this.interfaces,
      this.maxInheritancePath);

  /// Returns `true` if [classBuilder] is a mixin application.
  ///
  /// If `true`, [mixedInNode] is non-null.
  bool get isMixinApplication => mixedInNode != null;

  /// Returns a list of all supertypes of [classBuilder], including this node.
  List<ClassHierarchyNode> computeAllSuperNodes(
      ClassHierarchyBuilder hierarchy) {
    List<ClassHierarchyNode> result = [];
    for (int i = 0; i < superclasses.length; i++) {
      Supertype type = superclasses[i];
      result.add(hierarchy.getNodeFromClass(type.classNode));
    }
    for (int i = 0; i < interfaces.length; i++) {
      Supertype type = interfaces[i];
      result.add(hierarchy.getNodeFromClass(type.classNode));
    }
    result.add(this);
    return result;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb
      ..write(classBuilder.fullNameForErrors)
      ..writeln(":");
    if (maxInheritancePath != this.depth) {
      sb
        ..write("  Longest path to Object: ")
        ..writeln(maxInheritancePath);
    }
    sb..writeln("  superclasses:");
    int depth = 0;
    for (Supertype superclass in superclasses) {
      sb.write("  " * (depth + 2));
      if (depth != 0) sb.write("-> ");
      sb.write(typeToText(superclass.asInterfaceType));
      sb.writeln();
      depth++;
    }
    if (interfaces.isNotEmpty) {
      sb.write("  interfaces:");
      bool first = true;
      for (Supertype i in interfaces) {
        if (!first) sb.write(",");
        sb.write(" ");
        sb.write(typeToText(i.asInterfaceType));
        first = false;
      }
      sb.writeln();
    }
    return "$sb";
  }

  static int compareMaxInheritancePath(
      ClassHierarchyNode a, ClassHierarchyNode b) {
    return b.maxInheritancePath.compareTo(a.maxInheritancePath);
  }
}

ClassBuilder? getClass(TypeBuilder type) {
  Builder? declaration = type.declaration;
  if (declaration is TypeAliasBuilder) {
    TypeAliasBuilder aliasBuilder = declaration;
    NamedTypeBuilder namedBuilder = type as NamedTypeBuilder;
    declaration = aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
  }
  return declaration is ClassBuilder ? declaration : null;
}

const DebugLogger? debug =
    const bool.fromEnvironment("debug.hierarchy") ? const DebugLogger() : null;

class DebugLogger {
  const DebugLogger();
  void log(Object message) => print(message);
}
