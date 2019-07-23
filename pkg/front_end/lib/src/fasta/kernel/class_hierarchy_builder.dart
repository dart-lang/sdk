// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        Field,
        FunctionNode,
        InterfaceType,
        InvalidType,
        Library,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        Supertype,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        LocatedMessage,
        Message,
        messageDeclaredMemberConflictsWithInheritedMember,
        messageDeclaredMemberConflictsWithInheritedMemberCause,
        messageInheritedMembersConflict,
        messageInheritedMembersConflictCause1,
        messageInheritedMembersConflictCause2,
        messageStaticAndInstanceConflict,
        messageStaticAndInstanceConflictCause,
        templateCantInferReturnTypeDueToInconsistentOverrides,
        templateCantInferTypeDueToInconsistentOverrides,
        templateCombinedMemberSignatureFailed,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateDuplicatedDeclarationUse,
        templateMissingImplementationCause,
        templateMissingImplementationNotAbstract;

import '../names.dart' show noSuchMethodName;

import '../problems.dart' show unhandled;

import '../scope.dart' show Scope;

import '../source/source_loader.dart' show SourceLoader;

import '../type_inference/standard_bounds.dart' show StandardBounds;

import '../type_inference/type_constraint_gatherer.dart'
    show TypeConstraintGatherer;

import '../type_inference/type_inferrer.dart' show MixinInferrer;

import '../type_inference/type_schema.dart' show UnknownType;

import '../type_inference/type_schema_environment.dart' show TypeConstraint;

import 'forwarding_node.dart' show ForwardingNode;

import 'kernel_builder.dart'
    show
        Declaration,
        FormalParameterBuilder,
        ImplicitFieldType,
        KernelClassBuilder,
        KernelFieldBuilder,
        KernelLibraryBuilder,
        NamedTypeBuilder,
        KernelProcedureBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MemberBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import 'types.dart' show Types;

const DebugLogger debug =
    const bool.fromEnvironment("debug.hierarchy") ? const DebugLogger() : null;

class DebugLogger {
  const DebugLogger();
  void log(Object message) => print(message);
}

int compareDeclarations(Declaration a, Declaration b) {
  return ClassHierarchy.compareMembers(a.target, b.target);
}

ProcedureKind memberKind(Member member) {
  return member is Procedure ? member.kind : null;
}

bool isNameVisibleIn(Name name, LibraryBuilder<TypeBuilder, Library> library) {
  return !name.isPrivate || name.library == library.target;
}

/// Returns true if [a] is a class member conflict with [b].  [a] is assumed to
/// be declared in the class, [b] is assumed to be inherited.
///
/// See the section named "Class Member Conflicts" in [Dart Programming
/// Language Specification](
/// ../../../../../../docs/language/dartLangSpec.tex#classMemberConflicts).
bool isInheritanceConflict(Declaration a, Declaration b) {
  if (a.isStatic) return true;
  if (memberKind(a.target) == memberKind(b.target)) return false;
  if (a.isField) return !(b.isField || b.isGetter || b.isSetter);
  if (b.isField) return !(a.isField || a.isGetter || a.isSetter);
  if (a.isSetter) return !(b.isGetter || b.isSetter);
  if (b.isSetter) return !(a.isGetter || a.isSetter);
  if (a is InterfaceConflict || b is InterfaceConflict) return false;
  return true;
}

bool impliesSetter(Declaration declaration) {
  return declaration.isField && !(declaration.isFinal || declaration.isConst);
}

bool hasSameSignature(FunctionNode a, FunctionNode b) {
  List<TypeParameter> aTypeParameters = a.typeParameters;
  List<TypeParameter> bTypeParameters = b.typeParameters;
  int typeParameterCount = aTypeParameters.length;
  if (typeParameterCount != bTypeParameters.length) return false;
  Substitution substitution;
  if (typeParameterCount != 0) {
    List<DartType> types = new List<DartType>(typeParameterCount);
    for (int i = 0; i < typeParameterCount; i++) {
      types[i] = new TypeParameterType(aTypeParameters[i]);
    }
    substitution = Substitution.fromPairs(bTypeParameters, types);
    for (int i = 0; i < typeParameterCount; i++) {
      DartType aBound = aTypeParameters[i].bound;
      DartType bBound = substitution.substituteType(bTypeParameters[i].bound);
      if (aBound != bBound) return false;
    }
  }

  if (a.requiredParameterCount != b.requiredParameterCount) return false;
  List<VariableDeclaration> aPositionalParameters = a.positionalParameters;
  List<VariableDeclaration> bPositionalParameters = b.positionalParameters;
  if (aPositionalParameters.length != bPositionalParameters.length) {
    return false;
  }
  for (int i = 0; i < aPositionalParameters.length; i++) {
    VariableDeclaration aParameter = aPositionalParameters[i];
    VariableDeclaration bParameter = bPositionalParameters[i];
    if (aParameter.isCovariant != bParameter.isCovariant) return false;
    DartType aType = aParameter.type;
    DartType bType = bParameter.type;
    if (substitution != null) {
      bType = substitution.substituteType(bType);
    }
    if (aType != bType) return false;
  }

  List<VariableDeclaration> aNamedParameters = a.namedParameters;
  List<VariableDeclaration> bNamedParameters = b.namedParameters;
  if (aNamedParameters.length != bNamedParameters.length) return false;
  for (int i = 0; i < aNamedParameters.length; i++) {
    VariableDeclaration aParameter = aNamedParameters[i];
    VariableDeclaration bParameter = bNamedParameters[i];
    if (aParameter.isCovariant != bParameter.isCovariant) return false;
    if (aParameter.name != bParameter.name) return false;
    DartType aType = aParameter.type;
    DartType bType = bParameter.type;
    if (substitution != null) {
      bType = substitution.substituteType(bType);
    }
    if (aType != bType) return false;
  }

  DartType aReturnType = a.returnType;
  DartType bReturnType = b.returnType;
  if (substitution != null) {
    bReturnType = substitution.substituteType(bReturnType);
  }

  return aReturnType == bReturnType;
}

class ClassHierarchyBuilder {
  final Map<Class, ClassHierarchyNode> nodes = <Class, ClassHierarchyNode>{};

  final KernelClassBuilder objectClass;

  final Loader<Library> loader;

  final Class objectKernelClass;

  final Class futureKernelClass;

  final Class futureOrKernelClass;

  final Class functionKernelClass;

  final Class nullKernelClass;

  final List<DelayedOverrideCheck> overrideChecks = <DelayedOverrideCheck>[];

  final List<DelayedMember> delayedMemberChecks = <DelayedMember>[];

  // TODO(ahe): Remove this.
  final CoreTypes coreTypes;

  Types types;

  ClassHierarchyBuilder(this.objectClass, this.loader, this.coreTypes)
      : objectKernelClass = objectClass.target,
        futureKernelClass = coreTypes.futureClass,
        futureOrKernelClass = coreTypes.futureOrClass,
        functionKernelClass = coreTypes.functionClass,
        nullKernelClass = coreTypes.nullClass {
    types = new Types(this);
  }

  ClassHierarchyNode getNodeFromClass(KernelClassBuilder cls) {
    return nodes[cls.target] ??=
        new ClassHierarchyNodeBuilder(this, cls).build();
  }

  ClassHierarchyNode getNodeFromType(TypeBuilder type) {
    KernelClassBuilder cls = getClass(type);
    return cls == null ? null : getNodeFromClass(cls);
  }

  ClassHierarchyNode getNodeFromKernelClass(Class cls) {
    return nodes[cls] ??
        getNodeFromClass(loader.computeClassBuilderFromTargetClass(cls));
  }

  TypeBuilder asSupertypeOf(Class cls, Class supertype) {
    ClassHierarchyNode clsNode = getNodeFromKernelClass(cls);
    if (cls == supertype) {
      return new NamedTypeBuilder(clsNode.cls.name, null)..bind(clsNode.cls);
    }
    ClassHierarchyNode supertypeNode = getNodeFromKernelClass(supertype);
    List<TypeBuilder> supertypes = clsNode.superclasses;
    int depth = supertypeNode.depth;
    Declaration supertypeDeclaration = supertypeNode.cls;
    if (depth < supertypes.length) {
      TypeBuilder asSupertypeOf = supertypes[depth];
      if (asSupertypeOf.declaration == supertypeDeclaration)
        return asSupertypeOf;
    }
    supertypes = clsNode.interfaces;
    for (int i = 0; i < supertypes.length; i++) {
      TypeBuilder type = supertypes[i];
      if (type.declaration == supertypeDeclaration) return type;
    }
    return null;
  }

  InterfaceType getKernelTypeAsInstanceOf(
      InterfaceType type, Class superclass) {
    Class kernelClass = type.classNode;
    if (kernelClass == superclass) return type;
    if (kernelClass == nullKernelClass) {
      if (superclass.typeParameters.isEmpty) {
        return superclass.rawType;
      } else {
        // This is a safe fall-back for dealing with `Null`. It will likely be
        // faster to check for `Null` before calling this method.
        return new InterfaceType(
            superclass,
            new List<DartType>.filled(
                superclass.typeParameters.length, nullKernelClass.rawType));
      }
    }
    NamedTypeBuilder supertype = asSupertypeOf(kernelClass, superclass);
    if (supertype == null) return null;
    if (supertype.arguments == null && superclass.typeParameters.isEmpty) {
      return superclass.rawType;
    }
    return Substitution.fromInterfaceType(type)
        .substituteType(supertype.build(null));
  }

  InterfaceType getKernelLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    if (type1 == type2) return type1;
    ClassHierarchyNode node1 = getNodeFromKernelClass(type1.classNode);
    ClassHierarchyNode node2 = getNodeFromKernelClass(type2.classNode);
    Set<ClassHierarchyNode> nodes1 = node1.computeAllSuperNodes(this).toSet();
    List<ClassHierarchyNode> nodes2 = node2.computeAllSuperNodes(this);
    List<ClassHierarchyNode> common = <ClassHierarchyNode>[];

    for (int i = 0; i < nodes2.length; i++) {
      ClassHierarchyNode node = nodes2[i];
      if (node == null) continue;
      if (nodes1.contains(node)) {
        DartType candidate1 = getKernelTypeAsInstanceOf(type1, node.cls.target);
        DartType candidate2 = getKernelTypeAsInstanceOf(type2, node.cls.target);
        if (candidate1 == candidate2) {
          common.add(node);
        }
      }
    }

    if (common.length == 1) return objectKernelClass.rawType;
    common.sort(ClassHierarchyNode.compareMaxInheritancePath);

    for (int i = 0; i < common.length - 1; i++) {
      ClassHierarchyNode node = common[i];
      if (node.maxInheritancePath != common[i + 1].maxInheritancePath) {
        return getKernelTypeAsInstanceOf(type1, node.cls.target);
      } else {
        do {
          i++;
        } while (node.maxInheritancePath == common[i + 1].maxInheritancePath);
      }
    }
    return objectKernelClass.rawType;
  }

  Member getInterfaceMemberKernel(Class cls, Name name, bool isSetter) {
    return getNodeFromKernelClass(cls)
        .getInterfaceMember(name, isSetter)
        ?.target;
  }

  Member getDispatchTargetKernel(Class cls, Name name, bool isSetter) {
    return getNodeFromKernelClass(cls)
        .getDispatchTarget(name, isSetter)
        ?.target;
  }

  Member getCombinedMemberSignatureKernel(Class cls, Name name, bool isSetter,
      int charOffset, KernelLibraryBuilder library) {
    Declaration declaration =
        getNodeFromKernelClass(cls).getInterfaceMember(name, isSetter);
    if (declaration?.isStatic ?? true) return null;
    if (declaration.next != null) {
      library?.addProblem(
          templateDuplicatedDeclarationUse.withArguments(name.name),
          charOffset,
          name.name.length,
          library.fileUri);
      return null;
    }
    if (declaration is DelayedMember) {
      return declaration.check(this);
    } else {
      return declaration.target;
    }
  }

  static ClassHierarchyBuilder build(
      KernelClassBuilder objectClass,
      List<KernelClassBuilder> classes,
      SourceLoader loader,
      CoreTypes coreTypes) {
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, coreTypes);
    for (int i = 0; i < classes.length; i++) {
      KernelClassBuilder cls = classes[i];
      if (!cls.isPatch) {
        hierarchy.nodes[cls.target] =
            new ClassHierarchyNodeBuilder(hierarchy, cls).build();
      } else {
        // TODO(ahe): Merge the injected members of patch into the hierarchy
        // node of `cls.origin`.
      }
    }
    return hierarchy;
  }
}

class ClassHierarchyNodeBuilder {
  final ClassHierarchyBuilder hierarchy;

  final KernelClassBuilder cls;

  bool hasNoSuchMethod = false;

  List<Declaration> abstractMembers = null;

  ClassHierarchyNodeBuilder(this.hierarchy, this.cls);

  KernelClassBuilder get objectClass => hierarchy.objectClass;

  final Map<Class, Substitution> substitutions = <Class, Substitution>{};

  /// When merging `aList` and `bList`, [a] (from `aList`) and [b] (from
  /// `bList`) each have the same name.
  ///
  /// If [mergeKind] is `MergeKind.superclass`, [a] should override [b].
  ///
  /// If [mergeKind] is `MergeKind.interfaces`, we need to record them and
  /// solve the conflict later.
  ///
  /// If [mergeKind] is `MergeKind.supertypes`, [a] should implement [b], and
  /// [b] is implicitly abstract.
  Declaration handleMergeConflict(
      Declaration a, Declaration b, MergeKind mergeKind) {
    debug?.log(
        "handleMergeConflict: ${fullName(a)} ${fullName(b)} ${mergeKind}");
    // TODO(ahe): Enable this optimization, but be careful about abstract
    // methods overriding concrete methods.
    // if (cls is DillClassBuilder) return a;
    if (a == b) return a;
    if (a.next != null || b.next != null) {
      // Don't check overrides involving duplicated members.
      return a;
    }
    Declaration result = checkInheritanceConflict(a, b);
    if (result != null) return result;
    result = a;
    switch (mergeKind) {
      case MergeKind.superclassMembers:
      case MergeKind.superclassSetters:
        // [a] is a method declared in [cls]. This means it defines the
        // interface of this class regardless if its abstract.
        debug?.log(
            "superclass: checkValidOverride(${cls.fullNameForErrors}, ${fullName(a)}, ${fullName(b)})");
        checkValidOverride(
            a, AbstractMemberOverridingImplementation.selectAbstract(b));

        if (isAbstract(a)) {
          if (isAbstract(b)) {
            recordAbstractMember(a);
          } else {
            if (!cls.isAbstract) {
              // The interface of this class is [a]. But the implementation is
              // [b]. So [b] must implement [a], unless [cls] is abstract.
              checkValidOverride(b, a);
            }
            result = new AbstractMemberOverridingImplementation(
                cls,
                a,
                AbstractMemberOverridingImplementation.selectConcrete(b),
                mergeKind == MergeKind.superclassSetters,
                cls.library.loader == hierarchy.loader);
            hierarchy.delayedMemberChecks.add(result);
          }
        } else if (cls.isMixinApplication && a.parent != cls) {
          result = InheritedImplementationInterfaceConflict.combined(
              cls,
              a,
              b,
              mergeKind == MergeKind.superclassSetters,
              cls.library.loader == hierarchy.loader,
              isInheritableConflict: false);
          if (result is DelayedMember) {
            hierarchy.delayedMemberChecks.add(result);
          }
        }

        Member target = result.target;
        if (target.enclosingClass != objectClass.cls &&
            target.name == noSuchMethodName) {
          hasNoSuchMethod = true;
        }
        break;

      case MergeKind.membersWithSetters:
      case MergeKind.settersWithMembers:
        if (a.parent == cls && b.parent != cls) {
          if (a is KernelFieldBuilder) {
            if (a.isFinal && b.isSetter) {
              hierarchy.overrideChecks.add(new DelayedOverrideCheck(cls, a, b));
            } else {
              if (!inferFieldTypes(a, b)) {
                hierarchy.overrideChecks
                    .add(new DelayedOverrideCheck(cls, a, b));
              }
            }
          } else if (a is KernelProcedureBuilder) {
            if (!inferMethodTypes(a, b)) {
              hierarchy.overrideChecks.add(new DelayedOverrideCheck(cls, a, b));
            }
          }
        }
        break;

      case MergeKind.interfacesMembers:
        result = InterfaceConflict.combined(
            cls, a, b, false, cls.library.loader == hierarchy.loader);
        break;

      case MergeKind.interfacesSetters:
        result = InterfaceConflict.combined(
            cls, a, b, true, cls.library.loader == hierarchy.loader);
        break;

      case MergeKind.supertypesMembers:
      case MergeKind.supertypesSetters:
        // [b] is inherited from an interface so it is implicitly abstract.

        a = AbstractMemberOverridingImplementation.selectAbstract(a);
        b = AbstractMemberOverridingImplementation.selectAbstract(b);

        // If [a] is declared in this class, it defines the interface.
        if (a.parent == cls) {
          debug?.log(
              "supertypes: checkValidOverride(${cls.fullNameForErrors}, ${fullName(a)}, ${fullName(b)})");
          checkValidOverride(a, b);
          if (a is DelayedMember && !a.isInheritableConflict) {
            if (b is DelayedMember) {
              b.addAllDeclarationsTo(a.declarations);
            } else {
              addDeclarationIfDifferent(b, a.declarations);
            }
          }
        } else {
          if (isAbstract(a)) {
            result = InterfaceConflict.combined(
                cls,
                a,
                b,
                mergeKind == MergeKind.supertypesSetters,
                cls.library.loader == hierarchy.loader);
          } else {
            result = InheritedImplementationInterfaceConflict.combined(
                cls,
                a,
                b,
                mergeKind == MergeKind.supertypesSetters,
                cls.library.loader == hierarchy.loader);
          }
          debug?.log("supertypes: ${result}");
          if (result is DelayedMember) {
            hierarchy.delayedMemberChecks.add(result);
          }
        }
        break;
    }

    return result;
  }

  Declaration checkInheritanceConflict(Declaration a, Declaration b) {
    if (a is DelayedMember) {
      Declaration result;
      for (int i = 0; i < a.declarations.length; i++) {
        Declaration d = checkInheritanceConflict(a.declarations[i], b);
        result ??= d;
      }
      return result;
    }
    if (b is DelayedMember) {
      Declaration result;
      for (int i = 0; i < b.declarations.length; i++) {
        Declaration d = checkInheritanceConflict(a, b.declarations[i]);
        result ??= d;
      }
      return result;
    }
    if (isInheritanceConflict(a, b)) {
      reportInheritanceConflict(a, b);
      return a;
    }
    return null;
  }

  bool inferMethodTypes(KernelProcedureBuilder a, Declaration b) {
    debug?.log(
        "Trying to infer types for ${fullName(a)} based on ${fullName(b)}");
    if (b is DelayedMember) {
      bool hasSameSignature = true;
      List<Declaration> declarations = b.declarations;
      for (int i = 0; i < declarations.length; i++) {
        if (!inferMethodTypes(a, declarations[i])) {
          hasSameSignature = false;
        }
      }
      return hasSameSignature;
    }
    if (a.isGetter) {
      return inferGetterType(a, b);
    } else if (a.isSetter) {
      return inferSetterType(a, b);
    }
    bool hadTypesInferred = a.hadTypesInferred;
    KernelClassBuilder aCls = a.parent;
    Substitution aSubstitution;
    if (cls != aCls) {
      assert(substitutions.containsKey(aCls.target),
          "${cls.fullNameForErrors} ${aCls.fullNameForErrors}");
      aSubstitution = substitutions[aCls.target];
      debug?.log(
          "${cls.fullNameForErrors} -> ${aCls.fullNameForErrors} $aSubstitution");
    }
    KernelClassBuilder bCls = b.parent;
    Substitution bSubstitution;
    if (cls != bCls) {
      assert(substitutions.containsKey(bCls.target),
          "${cls.fullNameForErrors} ${bCls.fullNameForErrors}");
      bSubstitution = substitutions[bCls.target];
      debug?.log(
          "${cls.fullNameForErrors} -> ${bCls.fullNameForErrors} $bSubstitution");
    }
    Procedure aProcedure = a.target;
    if (b.target is! Procedure) {
      debug?.log("Giving up 1");
      return false;
    }
    Procedure bProcedure = b.target;
    FunctionNode aFunction = aProcedure.function;
    FunctionNode bFunction = bProcedure.function;

    List<TypeParameter> aTypeParameters = aFunction.typeParameters;
    List<TypeParameter> bTypeParameters = bFunction.typeParameters;
    int typeParameterCount = aTypeParameters.length;
    if (typeParameterCount != bTypeParameters.length) {
      debug?.log("Giving up 2");
      return false;
    }
    Substitution substitution;
    if (typeParameterCount != 0) {
      for (int i = 0; i < typeParameterCount; i++) {
        copyTypeParameterCovariance(
            a.parent, aTypeParameters[i], bTypeParameters[i]);
      }
      List<DartType> types = new List<DartType>(typeParameterCount);
      for (int i = 0; i < typeParameterCount; i++) {
        types[i] = new TypeParameterType(aTypeParameters[i]);
      }
      substitution = Substitution.fromPairs(bTypeParameters, types);
      for (int i = 0; i < typeParameterCount; i++) {
        DartType aBound = aTypeParameters[i].bound;
        DartType bBound = substitution.substituteType(bTypeParameters[i].bound);
        if (aBound != bBound) {
          debug?.log("Giving up 3");
          return false;
        }
      }
    }

    DartType aReturnType = aFunction.returnType;
    if (aSubstitution != null) {
      aReturnType = aSubstitution.substituteType(aReturnType);
    }
    DartType bReturnType = bFunction.returnType;
    if (bSubstitution != null) {
      bReturnType = bSubstitution.substituteType(bReturnType);
    }
    if (substitution != null) {
      bReturnType = substitution.substituteType(bReturnType);
    }
    bool result = true;
    if (aFunction.requiredParameterCount > bFunction.requiredParameterCount) {
      debug?.log("Giving up 4");
      return false;
    }
    List<VariableDeclaration> aPositional = aFunction.positionalParameters;
    List<VariableDeclaration> bPositional = bFunction.positionalParameters;
    if (aPositional.length < bPositional.length) {
      debug?.log("Giving up 5");
      return false;
    }

    if (aReturnType != bReturnType) {
      if (a.parent == cls && a.returnType == null) {
        result =
            inferReturnType(cls, a, bReturnType, hadTypesInferred, hierarchy);
      } else {
        debug?.log("Giving up 6");
        result = false;
      }
    }

    for (int i = 0; i < bPositional.length; i++) {
      VariableDeclaration aParameter = aPositional[i];
      VariableDeclaration bParameter = bPositional[i];
      copyParameterCovariance(a.parent, aParameter, bParameter);
      DartType aType = aParameter.type;
      if (aSubstitution != null) {
        aType = aSubstitution.substituteType(aType);
      }
      DartType bType = bParameter.type;
      if (bSubstitution != null) {
        bType = bSubstitution.substituteType(bType);
      }
      if (substitution != null) {
        bType = substitution.substituteType(bType);
      }
      if (aType != bType) {
        if (a.parent == cls && a.formals[i].type == null) {
          result = inferParameterType(
              cls, a, a.formals[i], bType, hadTypesInferred, hierarchy);
        } else {
          debug?.log("Giving up 8");
          result = false;
        }
      }
    }

    List<VariableDeclaration> aNamed = aFunction.namedParameters;
    List<VariableDeclaration> bNamed = bFunction.namedParameters;
    named:
    if (aNamed.isNotEmpty || bNamed.isNotEmpty) {
      if (aPositional.length != bPositional.length) {
        debug?.log("Giving up 9");
        result = false;
        break named;
      }
      if (aFunction.requiredParameterCount !=
          bFunction.requiredParameterCount) {
        debug?.log("Giving up 10");
        result = false;
        break named;
      }

      aNamed = aNamed.toList()..sort(compareNamedParameters);
      bNamed = bNamed.toList()..sort(compareNamedParameters);
      int aCount = 0;
      for (int bCount = 0; bCount < bNamed.length; bCount++) {
        String name = bNamed[bCount].name;
        for (; aCount < aNamed.length; aCount++) {
          if (aNamed[aCount].name == name) break;
        }
        if (aCount == aNamed.length) {
          debug?.log("Giving up 11");
          result = false;
          break named;
        }
        VariableDeclaration aParameter = aNamed[aCount];
        VariableDeclaration bParameter = bNamed[bCount];
        copyParameterCovariance(a.parent, aParameter, bParameter);
        DartType aType = aParameter.type;
        if (aSubstitution != null) {
          aType = aSubstitution.substituteType(aType);
        }
        DartType bType = bParameter.type;
        if (bSubstitution != null) {
          bType = bSubstitution.substituteType(bType);
        }
        if (substitution != null) {
          bType = substitution.substituteType(bType);
        }
        if (aType != bType) {
          FormalParameterBuilder<TypeBuilder> parameter;
          for (int i = aPositional.length; i < a.formals.length; ++i) {
            if (a.formals[i].name == name) {
              parameter = a.formals[i];
              break;
            }
          }
          if (a.parent == cls && parameter.type == null) {
            result = inferParameterType(
                cls, a, parameter, bType, hadTypesInferred, hierarchy);
          } else {
            debug?.log("Giving up 12");
            result = false;
          }
        }
      }
    }
    debug?.log("Inferring types for ${fullName(a)} based on ${fullName(b)} " +
        (result ? "succeeded." : "failed."));
    return result;
  }

  bool inferGetterType(KernelProcedureBuilder a, Declaration b) {
    debug?.log(
        "Inferring getter types for ${fullName(a)} based on ${fullName(b)}");
    Member bTarget = b.target;
    DartType bType;
    if (bTarget is Field) {
      bType = bTarget.type;
    } else if (bTarget is Procedure) {
      if (b.isSetter) {
        VariableDeclaration bParameter =
            bTarget.function.positionalParameters.single;
        bType = bParameter.type;
        if (!hasExplicitlyTypedFormalParameter(b, 0)) {
          debug?.log("Giving up (type may be inferred)");
          return false;
        }
      } else if (b.isGetter) {
        bType = bTarget.function.returnType;
        if (!hasExplicitReturnType(b)) {
          debug?.log("Giving up (return type may be inferred)");
          return false;
        }
      } else {
        debug?.log("Giving up (not accessor: ${bTarget.kind})");
        return false;
      }
    } else {
      debug?.log("Giving up (not field/procedure: ${bTarget.runtimeType})");
      return false;
    }
    return a.target.function.returnType == bType;
  }

  bool inferSetterType(KernelProcedureBuilder a, Declaration b) {
    debug?.log(
        "Inferring setter types for ${fullName(a)} based on ${fullName(b)}");
    Member bTarget = b.target;
    Procedure aProcedure = a.target;
    VariableDeclaration aParameter =
        aProcedure.function.positionalParameters.single;
    DartType bType;
    if (bTarget is Field) {
      bType = bTarget.type;
      copyParameterCovarianceFromField(a.parent, aParameter, bTarget);
    }
    if (bTarget is Procedure) {
      if (b.isSetter) {
        VariableDeclaration bParameter =
            bTarget.function.positionalParameters.single;
        bType = bParameter.type;
        copyParameterCovariance(a.parent, aParameter, bParameter);
        if (!hasExplicitlyTypedFormalParameter(b, 0) ||
            !hasExplicitlyTypedFormalParameter(a, 0)) {
          debug?.log("Giving up (type may be inferred)");
          return false;
        }
      } else if (b.isGetter) {
        bType = bTarget.function.returnType;
        if (!hasExplicitReturnType(b)) {
          debug?.log("Giving up (return type may be inferred)");
          return false;
        }
      } else {
        debug?.log("Giving up (not accessor: ${bTarget.kind})");
        return false;
      }
    } else {
      debug?.log("Giving up (not field/procedure: ${bTarget.runtimeType})");
      return false;
    }
    return aParameter.type == bType;
  }

  void checkValidOverride(Declaration a, Declaration b) {
    debug?.log(
        "checkValidOverride(${fullName(a)}, ${fullName(b)}) ${a.runtimeType}");
    if (a is KernelProcedureBuilder) {
      if (inferMethodTypes(a, b)) return;
    } else if (a.isField) {
      if (inferFieldTypes(a, b)) return;
    }
    Member aTarget = a.target;
    Member bTarget = b.target;
    if (aTarget is Procedure && !aTarget.isAccessor && bTarget is Procedure) {
      if (hasSameSignature(aTarget.function, bTarget.function)) return;
    }

    if (b is DelayedMember) {
      for (int i = 0; i < b.declarations.length; i++) {
        hierarchy.overrideChecks
            .add(new DelayedOverrideCheck(cls, a, b.declarations[i]));
      }
    } else {
      hierarchy.overrideChecks.add(new DelayedOverrideCheck(cls, a, b));
    }
  }

  bool inferFieldTypes(MemberBuilder a, Declaration b) {
    debug?.log(
        "Trying to infer field types for ${fullName(a)} based on ${fullName(b)}");
    if (b is DelayedMember) {
      bool hasSameSignature = true;
      List<Declaration> declarations = b.declarations;
      for (int i = 0; i < declarations.length; i++) {
        if (!inferFieldTypes(a, declarations[i])) {
          hasSameSignature = false;
        }
      }
      return hasSameSignature;
    }
    Member bTarget = b.target;
    DartType inheritedType;
    if (bTarget is Procedure) {
      if (bTarget.isSetter) {
        VariableDeclaration parameter =
            bTarget.function.positionalParameters.single;
        // inheritedType = parameter.type;
        copyFieldCovarianceFromParameter(a.parent, a.target, parameter);
        if (!hasExplicitlyTypedFormalParameter(b, 0)) {
          debug?.log("Giving up (type may be inferred)");
          return false;
        }
      } else if (bTarget.isGetter) {
        if (!hasExplicitReturnType(b)) return false;
        inheritedType = bTarget.function.returnType;
      }
    } else if (bTarget is Field) {
      copyFieldCovariance(a.parent, a.target, bTarget);
      inheritedType = bTarget.type;
    }
    if (inheritedType == null) {
      debug?.log("Giving up (inheritedType == null)\n${StackTrace.current}");
      return false;
    }
    KernelClassBuilder aCls = a.parent;
    Substitution aSubstitution;
    if (cls != aCls) {
      assert(substitutions.containsKey(aCls.target),
          "${cls.fullNameForErrors} ${aCls.fullNameForErrors}");
      aSubstitution = substitutions[aCls.target];
      debug?.log(
          "${cls.fullNameForErrors} -> ${aCls.fullNameForErrors} $aSubstitution");
    }
    KernelClassBuilder bCls = b.parent;
    Substitution bSubstitution;
    if (cls != bCls) {
      assert(substitutions.containsKey(bCls.target),
          "${cls.fullNameForErrors} ${bCls.fullNameForErrors}");
      bSubstitution = substitutions[bCls.target];
      debug?.log(
          "${cls.fullNameForErrors} -> ${bCls.fullNameForErrors} $bSubstitution");
    }
    if (bSubstitution != null && inheritedType is! ImplicitFieldType) {
      inheritedType = bSubstitution.substituteType(inheritedType);
    }

    DartType declaredType = a.target.type;
    if (aSubstitution != null) {
      declaredType = aSubstitution.substituteType(declaredType);
    }
    if (declaredType == inheritedType) return true;

    bool result = false;
    if (a is KernelFieldBuilder) {
      if (a.parent == cls && a.type == null) {
        if (a.hadTypesInferred) {
          reportCantInferFieldType(cls, a);
          inheritedType = const InvalidType();
        } else {
          result = true;
          a.hadTypesInferred = true;
        }
        if (inheritedType is ImplicitFieldType) {
          KernelLibraryBuilder library = cls.library;
          (library.implicitlyTypedFields ??= <KernelFieldBuilder>[]).add(a);
        }
        a.target.type = inheritedType;
      }
    }
    return result;
  }

  void copyParameterCovariance(Declaration parent,
      VariableDeclaration aParameter, VariableDeclaration bParameter) {
    if (parent == cls) {
      if (bParameter.isCovariant) {
        aParameter.isCovariant = true;
      }
      if (bParameter.isGenericCovariantImpl) {
        aParameter.isGenericCovariantImpl = true;
      }
    }
  }

  void copyParameterCovarianceFromField(
      Declaration parent, VariableDeclaration aParameter, Field bField) {
    if (parent == cls) {
      if (bField.isCovariant) {
        aParameter.isCovariant = true;
      }
      if (bField.isGenericCovariantImpl) {
        aParameter.isGenericCovariantImpl = true;
      }
    }
  }

  void copyFieldCovariance(Declaration parent, Field aField, Field bField) {
    if (parent == cls) {
      if (bField.isCovariant) {
        aField.isCovariant = true;
      }
      if (bField.isGenericCovariantImpl) {
        aField.isGenericCovariantImpl = true;
      }
    }
  }

  void copyFieldCovarianceFromParameter(
      Declaration parent, Field aField, VariableDeclaration bParameter) {
    if (parent == cls) {
      if (bParameter.isCovariant) {
        aField.isCovariant = true;
      }
      if (bParameter.isGenericCovariantImpl) {
        aField.isGenericCovariantImpl = true;
      }
    }
  }

  void copyTypeParameterCovariance(
      Declaration parent, TypeParameter aParameter, TypeParameter bParameter) {
    if (parent == cls) {
      if (bParameter.isGenericCovariantImpl) {
        aParameter.isGenericCovariantImpl = true;
      }
    }
  }

  void reportInheritanceConflict(Declaration a, Declaration b) {
    String name = a.fullNameForErrors;
    if (a.parent != b.parent) {
      if (a.parent == cls) {
        cls.addProblem(messageDeclaredMemberConflictsWithInheritedMember,
            a.charOffset, name.length,
            context: <LocatedMessage>[
              messageDeclaredMemberConflictsWithInheritedMemberCause
                  .withLocation(b.fileUri, b.charOffset, name.length)
            ]);
      } else {
        cls.addProblem(messageInheritedMembersConflict, cls.charOffset,
            cls.fullNameForErrors.length,
            context: inheritedConflictContext(a, b));
      }
    } else if (a.isStatic != b.isStatic) {
      Declaration staticMember;
      Declaration instanceMember;
      if (a.isStatic) {
        staticMember = a;
        instanceMember = b;
      } else {
        staticMember = b;
        instanceMember = a;
      }
      cls.library.addProblem(messageStaticAndInstanceConflict,
          staticMember.charOffset, name.length, staticMember.fileUri,
          context: <LocatedMessage>[
            messageStaticAndInstanceConflictCause.withLocation(
                instanceMember.fileUri, instanceMember.charOffset, name.length)
          ]);
    } else {
      // This message can be reported twice (when merging localMembers with
      // classSetters, or localSetters with classMembers). By ensuring that
      // we always report the one with higher charOffset as the duplicate,
      // the message duplication logic ensures that we only report this
      // problem once.
      Declaration existing;
      Declaration duplicate;
      assert(a.fileUri == b.fileUri);
      if (a.charOffset < b.charOffset) {
        existing = a;
        duplicate = b;
      } else {
        existing = b;
        duplicate = a;
      }
      cls.library.addProblem(templateDuplicatedDeclaration.withArguments(name),
          duplicate.charOffset, name.length, duplicate.fileUri,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause.withArguments(name).withLocation(
                existing.fileUri, existing.charOffset, name.length)
          ]);
    }
  }

  /// When merging `aList` and `bList`, [member] was only found in `aList`.
  ///
  /// If [mergeKind] is `MergeKind.superclass` [member] is declared in current
  /// class, and isn't overriding a method from the superclass.
  ///
  /// If [mergeKind] is `MergeKind.interfaces`, [member] is ignored for now.
  ///
  /// If [mergeKind] is `MergeKind.supertypes`, [member] isn't
  /// implementing/overriding anything.
  void handleOnlyA(Declaration member, MergeKind mergeKind) {
    if (mergeKind == MergeKind.interfacesMembers ||
        mergeKind == MergeKind.interfacesSetters) {
      return;
    }
    // TODO(ahe): Enable this optimization:
    // if (cls is DillClassBuilder) return;
    // assert(mergeKind == MergeKind.interfaces || member is! InterfaceConflict);
    if ((mergeKind == MergeKind.superclassMembers ||
            mergeKind == MergeKind.superclassSetters) &&
        isAbstract(member)) {
      recordAbstractMember(member);
    }
  }

  /// When merging `aList` and `bList`, [member] was only found in `bList`.
  ///
  /// If [mergeKind] is `MergeKind.superclass` [member] is being inherited from
  /// a superclass.
  ///
  /// If [mergeKind] is `MergeKind.interfaces`, [member] is ignored for now.
  ///
  /// If [mergeKind] is `MergeKind.supertypes`, [member] is implicitly
  /// abstract, and not implemented.
  Declaration handleOnlyB(Declaration member, MergeKind mergeKind) {
    if (mergeKind == MergeKind.interfacesMembers ||
        mergeKind == MergeKind.interfacesSetters) {
      return member;
    }
    // TODO(ahe): Enable this optimization:
    // if (cls is DillClassBuilder) return member;
    Member target = member.target;
    if ((mergeKind == MergeKind.supertypesMembers ||
            mergeKind == MergeKind.supertypesSetters) ||
        ((mergeKind == MergeKind.superclassMembers ||
                mergeKind == MergeKind.superclassSetters) &&
            target.isAbstract)) {
      if (isNameVisibleIn(target.name, cls.library)) {
        recordAbstractMember(member);
      }
    }
    if (mergeKind == MergeKind.superclassMembers &&
        target.enclosingClass != objectClass.cls &&
        target.name == noSuchMethodName) {
      hasNoSuchMethod = true;
    }
    if (mergeKind != MergeKind.membersWithSetters &&
        mergeKind != MergeKind.settersWithMembers &&
        member is DelayedMember &&
        member.isInheritableConflict) {
      hierarchy.delayedMemberChecks.add(member.withParent(cls));
    }
    return member;
  }

  void recordAbstractMember(Declaration member) {
    abstractMembers ??= <Declaration>[];
    if (member is DelayedMember) {
      abstractMembers.addAll(member.declarations);
    } else {
      abstractMembers.add(member);
    }
  }

  ClassHierarchyNode build() {
    assert(!cls.isPatch);
    ClassHierarchyNode supernode;
    if (objectClass != cls.origin) {
      supernode = hierarchy.getNodeFromType(cls.supertype);
      if (supernode == null) {
        supernode = hierarchy.getNodeFromClass(objectClass);
      }
      assert(supernode != null);
    }

    Scope scope = cls.scope;
    if (cls.isMixinApplication) {
      Declaration mixin = cls.mixedInType.declaration;
      inferMixinApplication();
      // recordSupertype(cls.mixedInType);
      while (mixin.isNamedMixinApplication) {
        KernelClassBuilder named = mixin;
        // recordSupertype(named.mixedInType);
        mixin = named.mixedInType.declaration;
      }
      if (mixin is KernelClassBuilder) {
        scope = mixin.scope.computeMixinScope();
      }
    }

    /// Members (excluding setters) declared in [cls].
    List<Declaration> localMembers =
        new List<Declaration>.from(scope.local.values)
          ..sort(compareDeclarations);

    /// Setters declared in [cls].
    List<Declaration> localSetters =
        new List<Declaration>.from(scope.setters.values)
          ..sort(compareDeclarations);

    // Add implied setters from fields in [localMembers].
    localSetters = mergeAccessors(localMembers, localSetters);

    /// Members (excluding setters) declared in [cls] or its superclasses. This
    /// includes static methods of [cls], but not its superclasses.
    List<Declaration> classMembers;

    /// Setters declared in [cls] or its superclasses. This includes static
    /// setters of [cls], but not its superclasses.
    List<Declaration> classSetters;

    /// Members (excluding setters) inherited from interfaces. This contains no static
    /// members. Is null if no interfaces are implemented by this class or its
    /// superclasses.
    List<Declaration> interfaceMembers;

    /// Setters inherited from interfaces. This contains no static setters. Is
    /// null if no interfaces are implemented by this class or its
    /// superclasses.
    List<Declaration> interfaceSetters;

    List<TypeBuilder> superclasses;

    List<TypeBuilder> interfaces;

    int maxInheritancePath;

    if (supernode == null) {
      // This should be Object.
      classMembers = localMembers;
      classSetters = localSetters;
      superclasses = new List<TypeBuilder>(0);
      interfaces = new List<TypeBuilder>(0);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;
      superclasses = new List<TypeBuilder>(supernode.superclasses.length + 1);
      superclasses.setRange(0, superclasses.length - 1,
          substSupertypes(cls.supertype, supernode.superclasses));
      superclasses[superclasses.length - 1] = recordSupertype(cls.supertype);

      List<TypeBuilder> directInterfaces = ignoreFunction(cls.interfaces);
      if (cls.isMixinApplication) {
        if (directInterfaces == null) {
          directInterfaces = <TypeBuilder>[cls.mixedInType];
        } else {
          directInterfaces = <TypeBuilder>[cls.mixedInType]
            ..addAll(directInterfaces);
        }
      }
      if (directInterfaces != null) {
        for (int i = 0; i < directInterfaces.length; i++) {
          recordSupertype(directInterfaces[i]);
        }
      }
      List<TypeBuilder> superclassInterfaces = supernode.interfaces;
      if (superclassInterfaces != null) {
        superclassInterfaces =
            substSupertypes(cls.supertype, superclassInterfaces);
      }

      classMembers = merge(
          localMembers, supernode.classMembers, MergeKind.superclassMembers);
      classSetters = merge(
          localSetters, supernode.classSetters, MergeKind.superclassSetters);

      if (directInterfaces != null) {
        MergeResult result = mergeInterfaces(supernode, directInterfaces);
        interfaceMembers = result.mergedMembers;
        interfaceSetters = result.mergedSetters;
        interfaces = <TypeBuilder>[];
        if (superclassInterfaces != null) {
          for (int i = 0; i < superclassInterfaces.length; i++) {
            addInterface(interfaces, superclasses, superclassInterfaces[i]);
          }
        }
        for (int i = 0; i < directInterfaces.length; i++) {
          TypeBuilder directInterface = directInterfaces[i];
          addInterface(interfaces, superclasses, directInterface);
          ClassHierarchyNode interfaceNode =
              hierarchy.getNodeFromType(directInterface);
          if (interfaceNode != null) {
            if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
              maxInheritancePath = interfaceNode.maxInheritancePath + 1;
            }
            List<TypeBuilder> types =
                substSupertypes(directInterface, interfaceNode.superclasses);
            for (int i = 0; i < types.length; i++) {
              addInterface(interfaces, superclasses, types[i]);
            }

            if (interfaceNode.interfaces != null) {
              List<TypeBuilder> types =
                  substSupertypes(directInterface, interfaceNode.interfaces);
              for (int i = 0; i < types.length; i++) {
                addInterface(interfaces, superclasses, types[i]);
              }
            }
          }
        }
      } else {
        interfaceMembers = supernode.interfaceMembers;
        interfaceSetters = supernode.interfaceSetters;
        interfaces = superclassInterfaces;
      }

      // Check if local members conflict with inherited setters. This check has
      // already been performed in the superclass, so we only need to check the
      // local members. These checks have to occur late to enable inferring
      // types between setters and getters, or from a setter to a final field.
      merge(localMembers, classSetters, MergeKind.membersWithSetters);

      // Check if local setters conflict with inherited members. As above, we
      // only need to check the local setters.
      merge(localSetters, classMembers, MergeKind.settersWithMembers);

      if (interfaceMembers != null) {
        interfaceMembers =
            merge(classMembers, interfaceMembers, MergeKind.supertypesMembers);

        // Check if class setters conflict with members inherited from
        // interfaces.
        merge(classSetters, interfaceMembers, MergeKind.settersWithMembers);
      }
      if (interfaceSetters != null) {
        interfaceSetters =
            merge(classSetters, interfaceSetters, MergeKind.supertypesSetters);

        // Check if class members conflict with setters inherited from
        // interfaces.
        merge(classMembers, interfaceSetters, MergeKind.membersWithSetters);
      }
    }
    if (abstractMembers != null && !cls.isAbstract) {
      if (!hasNoSuchMethod) {
        reportMissingMembers();
      } else {
        installNsmHandlers();
      }
    }
    return new ClassHierarchyNode(
      cls,
      classMembers,
      classSetters,
      interfaceMembers,
      interfaceSetters,
      superclasses,
      interfaces,
      maxInheritancePath,
      hasNoSuchMethod,
    );
  }

  TypeBuilder recordSupertype(TypeBuilder supertype) {
    if (supertype is NamedTypeBuilder) {
      debug?.log(
          "In ${this.cls.fullNameForErrors} recordSupertype(${supertype.fullNameForErrors})");
      Declaration declaration = supertype.declaration;
      if (declaration is! KernelClassBuilder) return supertype;
      KernelClassBuilder cls = declaration;
      if (cls.isMixinApplication) {
        recordSupertype(cls.mixedInType);
      }
      List<TypeVariableBuilder<TypeBuilder, Object>> typeVariables =
          cls.typeVariables;
      if (typeVariables == null) {
        substitutions[cls.target] = Substitution.empty;
        assert(cls.target.typeParameters.isEmpty);
      } else {
        List<TypeBuilder> arguments =
            supertype.arguments ?? computeDefaultTypeArguments(supertype);
        if (arguments.length != typeVariables.length) {
          arguments = computeDefaultTypeArguments(supertype);
        }
        List<DartType> kernelArguments = new List<DartType>(arguments.length);
        List<TypeParameter> kernelParameters =
            new List<TypeParameter>(arguments.length);
        for (int i = 0; i < arguments.length; i++) {
          kernelParameters[i] = typeVariables[i].target;
          kernelArguments[i] = arguments[i].build(this.cls.parent);
        }
        substitutions[cls.target] =
            Substitution.fromPairs(kernelParameters, kernelArguments);
      }
    }
    return supertype;
  }

  List<TypeBuilder> substSupertypes(
      NamedTypeBuilder supertype, List<TypeBuilder> supertypes) {
    Declaration declaration = supertype.declaration;
    if (declaration is! KernelClassBuilder) return supertypes;
    KernelClassBuilder cls = declaration;
    List<TypeVariableBuilder<TypeBuilder, Object>> typeVariables =
        cls.typeVariables;
    if (typeVariables == null) {
      debug?.log("In ${this.cls.fullNameForErrors} $supertypes aren't substed");
      for (int i = 0; i < supertypes.length; i++) {
        recordSupertype(supertypes[i]);
      }
      return supertypes;
    }
    Map<TypeVariableBuilder<TypeBuilder, Object>, TypeBuilder> substitution =
        <TypeVariableBuilder<TypeBuilder, Object>, TypeBuilder>{};
    List<TypeBuilder> arguments =
        supertype.arguments ?? computeDefaultTypeArguments(supertype);
    for (int i = 0; i < typeVariables.length; i++) {
      substitution[typeVariables[i]] = arguments[i];
    }
    List<TypeBuilder> result;
    for (int i = 0; i < supertypes.length; i++) {
      TypeBuilder supertype = supertypes[i];
      TypeBuilder substed = recordSupertype(supertype.subst(substitution));
      if (supertype != substed) {
        debug?.log("In ${this.cls.fullNameForErrors} $supertype -> $substed");
        result ??= supertypes.toList();
        result[i] = substed;
      } else {
        debug?.log("In ${this.cls.fullNameForErrors} $supertype isn't substed");
      }
    }
    return result ?? supertypes;
  }

  List<TypeBuilder> computeDefaultTypeArguments(TypeBuilder type) {
    KernelClassBuilder cls = type.declaration;
    List<TypeBuilder> result = new List<TypeBuilder>(cls.typeVariables.length);
    for (int i = 0; i < result.length; ++i) {
      KernelTypeVariableBuilder tv = cls.typeVariables[i];
      result[i] = tv.defaultType ??
          cls.library.loader.computeTypeBuilder(tv.target.defaultType);
    }
    return result;
  }

  TypeBuilder addInterface(List<TypeBuilder> interfaces,
      List<TypeBuilder> superclasses, TypeBuilder type) {
    ClassHierarchyNode node = hierarchy.getNodeFromType(type);
    if (node == null) return null;
    int depth = node.depth;
    int myDepth = superclasses.length;
    if (depth < myDepth && superclasses[depth].declaration == node.cls) {
      // This is a potential conflict.
      return superclasses[depth];
    } else {
      for (int i = 0; i < interfaces.length; i++) {
        // This is a quadratic algorithm, but normally, the number of
        // interfaces is really small.
        if (interfaces[i].declaration == type.declaration) {
          // This is a potential conflict.
          return interfaces[i];
        }
      }
    }
    interfaces.add(type);
    return null;
  }

  MergeResult mergeInterfaces(
      ClassHierarchyNode supernode, List<TypeBuilder> interfaces) {
    debug?.log(
        "mergeInterfaces($cls (${this.cls}) ${supernode.interfaces} ${interfaces}");
    List<List<Declaration>> memberLists =
        new List<List<Declaration>>(interfaces.length + 1);
    List<List<Declaration>> setterLists =
        new List<List<Declaration>>(interfaces.length + 1);
    memberLists[0] = supernode.interfaceMembers;
    setterLists[0] = supernode.interfaceSetters;
    for (int i = 0; i < interfaces.length; i++) {
      ClassHierarchyNode interfaceNode =
          hierarchy.getNodeFromType(interfaces[i]);
      if (interfaceNode == null) {
        memberLists[i + 1] = null;
        setterLists[i + 1] = null;
      } else {
        memberLists[i + 1] =
            interfaceNode.interfaceMembers ?? interfaceNode.classMembers;
        setterLists[i + 1] =
            interfaceNode.interfaceSetters ?? interfaceNode.classSetters;
      }
    }
    return new MergeResult(mergeLists(memberLists, MergeKind.interfacesMembers),
        mergeLists(setterLists, MergeKind.interfacesSetters));
  }

  List<Declaration> mergeLists(
      List<List<Declaration>> input, MergeKind mergeKind) {
    // This is a k-way merge sort (where k is `input.length + 1`). We merge the
    // lists pairwise, which reduces the number of lists to merge by half on
    // each iteration. Consequently, we perform O(log k) merges.
    while (input.length > 1) {
      List<List<Declaration>> output = <List<Declaration>>[];
      for (int i = 0; i < input.length - 1; i += 2) {
        List<Declaration> first = input[i];
        List<Declaration> second = input[i + 1];
        if (first == null) {
          output.add(second);
        } else if (second == null) {
          output.add(first);
        } else {
          output.add(merge(first, second, mergeKind));
        }
      }
      if (input.length.isOdd) {
        output.add(input.last);
      }
      input = output;
    }
    return input.single;
  }

  /// Merge [and check] accessors. This entails copying mutable fields to
  /// setters to simulate implied setters, and checking that setters don't
  /// override regular methods.
  List<Declaration> mergeAccessors(
      List<Declaration> members, List<Declaration> setters) {
    final List<Declaration> mergedSetters = new List<Declaration>.filled(
        members.length + setters.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0;
    int j = 0;
    while (i < members.length && j < setters.length) {
      final Declaration member = members[i];
      final Declaration setter = setters[j];
      final int compare = compareDeclarations(member, setter);
      if (compare == 0) {
        mergedSetters[storeIndex++] = setter;
        i++;
        j++;
      } else if (compare < 0) {
        if (impliesSetter(member)) {
          mergedSetters[storeIndex++] = member;
        }
        i++;
      } else {
        mergedSetters[storeIndex++] = setters[j];
        j++;
      }
    }
    while (i < members.length) {
      final Declaration member = members[i];
      if (impliesSetter(member)) {
        mergedSetters[storeIndex++] = member;
      }
      i++;
    }
    while (j < setters.length) {
      mergedSetters[storeIndex++] = setters[j];
      j++;
    }

    if (storeIndex == j) {
      return setters;
    } else {
      return mergedSetters..length = storeIndex;
    }
  }

  void reportMissingMembers() {
    Map<String, LocatedMessage> contextMap = <String, LocatedMessage>{};
    for (int i = 0; i < abstractMembers.length; i++) {
      Declaration declaration = abstractMembers[i];
      Member target = declaration.target;
      if (isNameVisibleIn(target.name, cls.library)) {
        String name = declaration.fullNameForErrors;
        String parentName = declaration.parent.fullNameForErrors;
        String displayName =
            declaration.isSetter ? "$parentName.$name=" : "$parentName.$name";
        contextMap[displayName] = templateMissingImplementationCause
            .withArguments(displayName)
            .withLocation(
                declaration.fileUri, declaration.charOffset, name.length);
      }
    }
    if (contextMap.isEmpty) return;
    List<String> names = new List<String>.from(contextMap.keys)..sort();
    List<LocatedMessage> context = <LocatedMessage>[];
    for (int i = 0; i < names.length; i++) {
      context.add(contextMap[names[i]]);
    }
    cls.addProblem(
        templateMissingImplementationNotAbstract.withArguments(
            cls.fullNameForErrors, names),
        cls.charOffset,
        cls.fullNameForErrors.length,
        context: context);
  }

  void installNsmHandlers() {
    // TOOD(ahe): Implement this.
  }

  List<Declaration> merge(
      List<Declaration> aList, List<Declaration> bList, MergeKind mergeKind) {
    final List<Declaration> result = new List<Declaration>.filled(
        aList.length + bList.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0;
    int j = 0;
    while (i < aList.length && j < bList.length) {
      final Declaration a = aList[i];
      final Declaration b = bList[j];
      if ((mergeKind == MergeKind.interfacesMembers ||
              mergeKind == MergeKind.interfacesSetters) &&
          a.isStatic) {
        i++;
        continue;
      }
      if (b.isStatic) {
        j++;
        continue;
      }
      final int compare = compareDeclarations(a, b);
      if (compare == 0) {
        result[storeIndex++] = handleMergeConflict(a, b, mergeKind);
        i++;
        j++;
      } else if (compare < 0) {
        handleOnlyA(a, mergeKind);
        result[storeIndex++] = a;
        i++;
      } else {
        result[storeIndex++] = handleOnlyB(b, mergeKind);
        j++;
      }
    }
    while (i < aList.length) {
      final Declaration a = aList[i];
      if (!(mergeKind == MergeKind.interfacesMembers ||
              mergeKind == MergeKind.interfacesSetters) ||
          !a.isStatic) {
        handleOnlyA(a, mergeKind);
        result[storeIndex++] = a;
      }
      i++;
    }
    while (j < bList.length) {
      final Declaration b = bList[j];
      if (!b.isStatic) {
        result[storeIndex++] = handleOnlyB(b, mergeKind);
      }
      j++;
    }
    if (aList.isEmpty && storeIndex == bList.length) return bList;
    if (bList.isEmpty && storeIndex == aList.length) return aList;
    return result..length = storeIndex;
  }

  void inferMixinApplication() {
    Class kernelClass = cls.target;
    Supertype kernelMixedInType = kernelClass.mixedInType;
    if (kernelMixedInType == null) return;
    List<DartType> typeArguments = kernelMixedInType.typeArguments;
    if (typeArguments.isEmpty || typeArguments.first is! UnknownType) return;
    new BuilderMixinInferrer(
            cls,
            hierarchy.coreTypes,
            new TypeBuilderConstraintGatherer(
                hierarchy, kernelMixedInType.classNode.typeParameters))
        .infer(kernelClass);
    List<TypeBuilder> inferredArguments =
        new List<TypeBuilder>(typeArguments.length);
    for (int i = 0; i < typeArguments.length; i++) {
      inferredArguments[i] =
          hierarchy.loader.computeTypeBuilder(typeArguments[i]);
    }
    NamedTypeBuilder mixedInType = cls.mixedInType;
    mixedInType.arguments = inferredArguments;
  }

  /// The class Function from dart:core is supposed to be ignored when used as
  /// an interface.
  List<TypeBuilder> ignoreFunction(List<TypeBuilder> interfaces) {
    if (interfaces == null) return null;
    for (int i = 0; i < interfaces.length; i++) {
      KernelClassBuilder cls = getClass(interfaces[i]);
      if (cls != null && cls.target == hierarchy.functionKernelClass) {
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
  final KernelClassBuilder cls;

  /// All the members of this class including [classMembers] of its
  /// superclasses. The members are sorted by [compareDeclarations].
  final List<Declaration> classMembers;

  /// Similar to [classMembers] but for setters.
  final List<Declaration> classSetters;

  /// All the interface members of this class including [interfaceMembers] of
  /// its supertypes. The members are sorted by [compareDeclarations].
  ///
  /// In addition to the members of [classMembers] this also contains members
  /// from interfaces.
  ///
  /// This may be null, in which case [classMembers] is the interface members.
  final List<Declaration> interfaceMembers;

  /// Similar to [interfaceMembers] but for setters.
  ///
  /// This may be null, in which case [classSetters] is the interface setters.
  final List<Declaration> interfaceSetters;

  /// All superclasses of [cls] excluding itself. The classes are sorted by
  /// depth from the root (Object) in ascending order.
  final List<TypeBuilder> superclasses;

  /// The list of all classes implemented by [cls] and its supertypes excluding
  /// any classes from [superclasses].
  final List<TypeBuilder> interfaces;

  /// The longest inheritance path from [cls] to `Object`.
  final int maxInheritancePath;

  int get depth => superclasses.length;

  final bool hasNoSuchMethod;

  ClassHierarchyNode(
      this.cls,
      this.classMembers,
      this.classSetters,
      this.interfaceMembers,
      this.interfaceSetters,
      this.superclasses,
      this.interfaces,
      this.maxInheritancePath,
      this.hasNoSuchMethod);

  /// Returns a list of all supertypes of [cls], including this node.
  List<ClassHierarchyNode> computeAllSuperNodes(
      ClassHierarchyBuilder hierarchy) {
    List<ClassHierarchyNode> result = new List<ClassHierarchyNode>(
        1 + superclasses.length + interfaces.length);
    for (int i = 0; i < superclasses.length; i++) {
      Declaration declaration = superclasses[i].declaration;
      if (declaration is KernelClassBuilder) {
        result[i] = hierarchy.getNodeFromClass(declaration);
      }
    }
    for (int i = 0; i < interfaces.length; i++) {
      Declaration declaration = interfaces[i].declaration;
      if (declaration is KernelClassBuilder) {
        result[i + superclasses.length] =
            hierarchy.getNodeFromClass(declaration);
      }
    }
    return result..last = this;
  }

  String toString([StringBuffer sb]) {
    sb ??= new StringBuffer();
    sb
      ..write(cls.fullNameForErrors)
      ..writeln(":");
    if (maxInheritancePath != this.depth) {
      sb
        ..write("  Longest path to Object: ")
        ..writeln(maxInheritancePath);
    }
    sb..writeln("  superclasses:");
    int depth = 0;
    for (TypeBuilder superclass in superclasses) {
      sb.write("  " * (depth + 2));
      if (depth != 0) sb.write("-> ");
      superclass.printOn(sb);
      sb.writeln();
      depth++;
    }
    if (interfaces != null) {
      sb.write("  interfaces:");
      bool first = true;
      for (TypeBuilder i in interfaces) {
        if (!first) sb.write(",");
        sb.write(" ");
        i.printOn(sb);
        first = false;
      }
      sb.writeln();
    }
    printMembers(classMembers, sb, "classMembers");
    printMembers(classSetters, sb, "classSetters");
    if (interfaceMembers != null) {
      printMembers(interfaceMembers, sb, "interfaceMembers");
    }
    if (interfaceSetters != null) {
      printMembers(interfaceSetters, sb, "interfaceSetters");
    }
    return "$sb";
  }

  void printMembers(
      List<Declaration> members, StringBuffer sb, String heading) {
    sb.write("  ");
    sb.write(heading);
    sb.writeln(":");
    for (Declaration member in members) {
      sb
        ..write("    ")
        ..write(member.parent.fullNameForErrors)
        ..write(".")
        ..write(member.fullNameForErrors)
        ..writeln();
    }
  }

  Declaration getInterfaceMember(Name name, bool isSetter) {
    return findMember(
        name,
        isSetter
            ? interfaceSetters ?? classSetters
            : interfaceMembers ?? classMembers);
  }

  Declaration findMember(Name name, List<Declaration> declarations) {
    // TODO(ahe): Consider creating a map or scope. The obvious choice would be
    // to use scopes, but they don't handle private names correctly.

    // This is a copy of `ClassHierarchy.findMemberByName`.
    int low = 0, high = declarations.length - 1;
    while (low <= high) {
      int mid = low + ((high - low) >> 1);
      Declaration pivot = declarations[mid];
      int comparison = ClassHierarchy.compareNames(name, pivot.target.name);
      if (comparison < 0) {
        high = mid - 1;
      } else if (comparison > 0) {
        low = mid + 1;
      } else if (high != mid) {
        // Ensure we find the first element of the given name.
        high = mid;
      } else {
        return pivot;
      }
    }
    return null;
  }

  Declaration getDispatchTarget(Name name, bool isSetter) {
    return findMember(name, isSetter ? classSetters : classMembers);
  }

  static int compareMaxInheritancePath(
      ClassHierarchyNode a, ClassHierarchyNode b) {
    return b.maxInheritancePath.compareTo(a.maxInheritancePath);
  }
}

class MergeResult {
  final List<Declaration> mergedMembers;

  final List<Declaration> mergedSetters;

  MergeResult(this.mergedMembers, this.mergedSetters);
}

enum MergeKind {
  /// Merging superclass members with the current class.
  superclassMembers,

  /// Merging superclass setters with the current class.
  superclassSetters,

  /// Merging members of two interfaces.
  interfacesMembers,

  /// Merging setters of two interfaces.
  interfacesSetters,

  /// Merging class members with interface members.
  supertypesMembers,

  /// Merging class setters with interface setters.
  supertypesSetters,

  /// Merging members with inherited setters.
  membersWithSetters,

  /// Merging setters with inherited members.
  settersWithMembers,
}

List<LocatedMessage> inheritedConflictContext(Declaration a, Declaration b) {
  return inheritedConflictContextKernel(
      a.target, b.target, a.fullNameForErrors.length);
}

List<LocatedMessage> inheritedConflictContextKernel(
    Member a, Member b, int length) {
  // TODO(ahe): Delete this method when it isn't used by [InterfaceResolver].
  int compare = "${a.fileUri}".compareTo("${b.fileUri}");
  if (compare == 0) {
    compare = a.fileOffset.compareTo(b.fileOffset);
  }
  Member first;
  Member second;
  if (compare < 0) {
    first = a;
    second = b;
  } else {
    first = b;
    second = a;
  }
  return <LocatedMessage>[
    messageInheritedMembersConflictCause1.withLocation(
        first.fileUri, first.fileOffset, length),
    messageInheritedMembersConflictCause2.withLocation(
        second.fileUri, second.fileOffset, length),
  ];
}

class BuilderMixinInferrer extends MixinInferrer {
  final KernelClassBuilder cls;

  BuilderMixinInferrer(
      this.cls, CoreTypes coreTypes, TypeBuilderConstraintGatherer gatherer)
      : super(coreTypes, gatherer);

  Supertype asInstantiationOf(Supertype type, Class superclass) {
    InterfaceType interfaceType =
        gatherer.getTypeAsInstanceOf(type.asInterfaceType, superclass);
    if (interfaceType == null) return null;
    return new Supertype(interfaceType.classNode, interfaceType.typeArguments);
  }

  void reportProblem(Message message, Class kernelClass) {
    int length = cls.isMixinApplication ? 1 : cls.fullNameForErrors.length;
    cls.addProblem(message, cls.charOffset, length);
  }
}

class TypeBuilderConstraintGatherer extends TypeConstraintGatherer
    with StandardBounds {
  final ClassHierarchyBuilder hierarchy;

  TypeBuilderConstraintGatherer(
      this.hierarchy, Iterable<TypeParameter> typeParameters)
      : super.subclassing(typeParameters);

  @override
  Class get objectClass => hierarchy.objectKernelClass;

  @override
  Class get functionClass => hierarchy.functionKernelClass;

  @override
  Class get futureOrClass => hierarchy.futureOrKernelClass;

  @override
  Class get nullClass => hierarchy.nullKernelClass;

  @override
  InterfaceType get nullType => nullClass.rawType;

  @override
  InterfaceType get objectType => objectClass.rawType;

  @override
  InterfaceType get rawFunctionType => functionClass.rawType;

  @override
  void addLowerBound(TypeConstraint constraint, DartType lower) {
    constraint.lower = getStandardUpperBound(constraint.lower, lower);
  }

  @override
  void addUpperBound(TypeConstraint constraint, DartType upper) {
    constraint.upper = getStandardLowerBound(constraint.upper, upper);
  }

  @override
  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    return null;
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass) {
    return hierarchy.getKernelTypeAsInstanceOf(type, superclass);
  }

  @override
  InterfaceType futureType(DartType type) {
    return new InterfaceType(hierarchy.futureKernelClass, <DartType>[type]);
  }

  @override
  bool isSubtypeOf(DartType subtype, DartType supertype) {
    return hierarchy.types.isSubtypeOfKernel(subtype, supertype);
  }

  @override
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    return hierarchy.getKernelLegacyLeastUpperBound(type1, type2);
  }
}

class DelayedOverrideCheck {
  final KernelClassBuilder cls;
  final Declaration a;
  final Declaration b;

  const DelayedOverrideCheck(this.cls, this.a, this.b);

  void check(ClassHierarchyBuilder hierarchy) {
    void callback(
        Member declaredMember, Member interfaceMember, bool isSetter) {
      cls.checkOverride(
          hierarchy.types, declaredMember, interfaceMember, isSetter, callback,
          isInterfaceCheck: !cls.isMixinApplication);
    }

    Declaration a = this.a;
    debug?.log(
        "Delayed override check of ${fullName(a)} ${fullName(b)} wrt. ${cls.fullNameForErrors}");
    if (cls == a.parent) {
      if (a is KernelProcedureBuilder) {
        if (a.isGetter && !hasExplicitReturnType(a)) {
          DartType type;
          if (b.isGetter) {
            Procedure bTarget = b.target;
            type = bTarget.function.returnType;
          } else if (b.isSetter) {
            Procedure bTarget = b.target;
            type = bTarget.function.positionalParameters.single.type;
          } else if (b.isField) {
            Field bTarget = b.target;
            type = bTarget.type;
          }
          if (type != null) {
            type = Substitution.fromInterfaceType(
                    hierarchy.getKernelTypeAsInstanceOf(
                        cls.cls.thisType, b.target.enclosingClass))
                .substituteType(type);
            if (!a.hadTypesInferred || !b.isSetter) {
              inferReturnType(cls, a, type, a.hadTypesInferred, hierarchy);
            }
          }
        } else if (a.isSetter && !hasExplicitlyTypedFormalParameter(a, 0)) {
          DartType type;
          if (b.isGetter) {
            Procedure bTarget = b.target;
            type = bTarget.function.returnType;
          } else if (b.isSetter) {
            Procedure bTarget = b.target;
            type = bTarget.function.positionalParameters.single.type;
          } else if (b.isField) {
            Field bTarget = b.target;
            type = bTarget.type;
          }
          if (type != null) {
            type = Substitution.fromInterfaceType(
                    hierarchy.getKernelTypeAsInstanceOf(
                        cls.cls.thisType, b.target.enclosingClass))
                .substituteType(type);
            if (!a.hadTypesInferred || !b.isGetter) {
              inferParameterType(cls, a, a.formals.single, type,
                  a.hadTypesInferred, hierarchy);
            }
          }
        }
        a.hadTypesInferred = true;
      } else if (a is KernelFieldBuilder && a.type == null) {
        DartType type;
        if (b.isGetter) {
          Procedure bTarget = b.target;
          type = bTarget.function.returnType;
        } else if (b.isSetter) {
          Procedure bTarget = b.target;
          type = bTarget.function.positionalParameters.single.type;
        } else if (b.isField) {
          Field bTarget = b.target;
          type = bTarget.type;
        }
        if (type != null) {
          type = Substitution.fromInterfaceType(
                  hierarchy.getKernelTypeAsInstanceOf(
                      cls.cls.thisType, b.target.enclosingClass))
              .substituteType(type);
          if (type != a.target.type) {
            if (a.hadTypesInferred) {
              if (b.isSetter &&
                  (!impliesSetter(a) ||
                      hierarchy.types.isSubtypeOfKernel(type, a.target.type))) {
                type = a.target.type;
              } else {
                reportCantInferFieldType(cls, a);
                type = const InvalidType();
              }
            }
            debug?.log("Inferred type ${type} for ${fullName(a)}");
            a.target.type = type;
          }
        }
        a.hadTypesInferred = true;
      }
    }

    callback(a.target, b.target, a.isSetter);
  }
}

abstract class DelayedMember extends Declaration {
  /// The class which has inherited [declarations].
  @override
  final KernelClassBuilder parent;

  /// Conflicting declarations.
  final List<Declaration> declarations;

  final isSetter;

  final bool modifyKernel;

  DelayedMember(
      this.parent, this.declarations, this.isSetter, this.modifyKernel);

  void addAllDeclarationsTo(List<Declaration> declarations) {
    for (int i = 0; i < this.declarations.length; i++) {
      addDeclarationIfDifferent(this.declarations[i], declarations);
    }
    assert(declarations.toSet().length == declarations.length);
  }

  Member check(ClassHierarchyBuilder hierarchy);

  DelayedMember withParent(KernelClassBuilder parent);

  @override
  Uri get fileUri => parent.fileUri;

  @override
  int get charOffset => parent.charOffset;

  @override
  String get fullNameForErrors => declarations.map(fullName).join("%");

  bool get isInheritableConflict => true;

  @override
  Member get target => declarations.first.target;
}

/// This represents a concrete implementation inherited from a superclass that
/// has conflicts with methods inherited from an interface. The concrete
/// implementation is the first element of [declarations].
class InheritedImplementationInterfaceConflict extends DelayedMember {
  Member combinedMemberSignatureResult;

  @override
  final bool isInheritableConflict;

  InheritedImplementationInterfaceConflict(KernelClassBuilder parent,
      List<Declaration> declarations, bool isSetter, bool modifyKernel,
      {this.isInheritableConflict = true})
      : super(parent, declarations, isSetter, modifyKernel);

  @override
  String toString() {
    return "InheritedImplementationInterfaceConflict("
        "${parent.fullNameForErrors}, "
        "[${declarations.map(fullName).join(', ')}])";
  }

  @override
  Member check(ClassHierarchyBuilder hierarchy) {
    if (combinedMemberSignatureResult != null) {
      return combinedMemberSignatureResult;
    }
    if (!parent.isAbstract) {
      Declaration concreteImplementation = declarations.first;
      for (int i = 1; i < declarations.length; i++) {
        new DelayedOverrideCheck(
                parent, concreteImplementation, declarations[i])
            .check(hierarchy);
      }
    }
    return combinedMemberSignatureResult =
        new InterfaceConflict(parent, declarations, isSetter, modifyKernel)
            .check(hierarchy);
  }

  @override
  DelayedMember withParent(KernelClassBuilder parent) {
    return parent == this.parent
        ? this
        : new InheritedImplementationInterfaceConflict(
            parent, declarations, isSetter, modifyKernel);
  }

  static Declaration combined(
      KernelClassBuilder parent,
      Declaration concreteImplementation,
      Declaration other,
      bool isSetter,
      bool createForwarders,
      {bool isInheritableConflict = true}) {
    List<Declaration> declarations = <Declaration>[];
    if (concreteImplementation is DelayedMember) {
      concreteImplementation.addAllDeclarationsTo(declarations);
    } else {
      declarations.add(concreteImplementation);
    }
    if (other is DelayedMember) {
      other.addAllDeclarationsTo(declarations);
    } else {
      addDeclarationIfDifferent(other, declarations);
    }
    if (declarations.length == 1) {
      return declarations.single;
    } else {
      return new InheritedImplementationInterfaceConflict(
          parent, declarations, isSetter, createForwarders,
          isInheritableConflict: isInheritableConflict);
    }
  }
}

class InterfaceConflict extends DelayedMember {
  InterfaceConflict(KernelClassBuilder parent, List<Declaration> declarations,
      bool isSetter, bool modifyKernel)
      : super(parent, declarations, isSetter, modifyKernel);

  Member combinedMemberSignatureResult;

  @override
  String toString() {
    return "InterfaceConflict(${parent.fullNameForErrors}, "
        "[${declarations.map(fullName).join(', ')}])";
  }

  DartType computeMemberType(
      ClassHierarchyBuilder hierarchy, DartType thisType, Member member) {
    DartType type;
    if (member is Procedure) {
      if (member.isGetter) {
        type = member.getterType;
      } else if (member.isSetter) {
        type = member.setterType;
      } else {
        type = member.function.functionType;
      }
    } else if (member is Field) {
      type = member.type;
    } else {
      unhandled("${member.runtimeType}", "$member", parent.charOffset,
          parent.fileUri);
    }
    return Substitution.fromInterfaceType(hierarchy.getKernelTypeAsInstanceOf(
            thisType, member.enclosingClass))
        .substituteType(type);
  }

  bool isMoreSpecific(ClassHierarchyBuilder hierarchy, DartType a, DartType b) {
    if (isSetter) {
      return hierarchy.types.isSubtypeOfKernel(b, a);
    } else {
      return hierarchy.types.isSubtypeOfKernel(a, b);
    }
  }

  @override
  Member check(ClassHierarchyBuilder hierarchy) {
    if (combinedMemberSignatureResult != null) {
      return combinedMemberSignatureResult;
    }
    if (parent.library is! KernelLibraryBuilder) {
      return combinedMemberSignatureResult = declarations.first.target;
    }
    DartType thisType = parent.cls.thisType;
    Declaration bestSoFar;
    DartType bestTypeSoFar;
    for (int i = declarations.length - 1; i >= 0; i--) {
      Declaration candidate = declarations[i];
      Member target = candidate.target;
      DartType candidateType = computeMemberType(hierarchy, thisType, target);
      if (bestSoFar == null) {
        bestSoFar = candidate;
        bestTypeSoFar = candidateType;
      } else {
        if (isMoreSpecific(hierarchy, candidateType, bestTypeSoFar)) {
          debug?.log(
              "Combined Member Signature: ${fullName(candidate)} ${candidateType} <: ${fullName(bestSoFar)} ${bestTypeSoFar}");
          bestSoFar = candidate;
          bestTypeSoFar = candidateType;
        } else {
          debug?.log(
              "Combined Member Signature: ${fullName(candidate)} !<: ${fullName(bestSoFar)}");
        }
      }
    }
    if (bestSoFar != null) {
      debug?.log("Combined Member Signature bestSoFar: ${fullName(bestSoFar)}");
      for (int i = 0; i < declarations.length; i++) {
        Declaration candidate = declarations[i];
        Member target = candidate.target;
        DartType candidateType = computeMemberType(hierarchy, thisType, target);
        if (!isMoreSpecific(hierarchy, bestTypeSoFar, candidateType)) {
          debug?.log(
              "Combined Member Signature: ${fullName(bestSoFar)} !<: ${fullName(candidate)}");

          String uri = '${parent.library.uri}';
          if (uri == 'dart:js' &&
                  parent.fileUri.pathSegments.last == 'js_dart2js.dart' ||
              uri == 'dart:_interceptors' &&
                  parent.fileUri.pathSegments.last == 'js_number.dart') {
            // TODO(johnniwinther): Fix the dart2js libraries and remove the
            // above URIs.
          } else {
            bestSoFar = null;
            bestTypeSoFar = null;
          }
          break;
        }
      }
    }
    if (bestSoFar == null) {
      String name = parent.fullNameForErrors;
      int length = parent.isAnonymousMixinApplication ? 1 : name.length;
      List<LocatedMessage> context = declarations.map((Declaration d) {
        return messageDeclaredMemberConflictsWithInheritedMemberCause
            .withLocation(d.fileUri, d.charOffset, d.fullNameForErrors.length);
      }).toList();

      parent.addProblem(
          templateCombinedMemberSignatureFailed.withArguments(
              parent.fullNameForErrors, declarations.first.fullNameForErrors),
          parent.charOffset,
          length,
          context: context);
      return null;
    }
    debug?.log(
        "Combined Member Signature of ${fullNameForErrors}: ${fullName(bestSoFar)}");

    ProcedureKind kind = ProcedureKind.Method;
    if (bestSoFar.isField || bestSoFar.isSetter || bestSoFar.isGetter) {
      kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
    } else if (bestSoFar.target is Procedure &&
        bestSoFar.target.kind == ProcedureKind.Operator) {
      kind = ProcedureKind.Operator;
    }

    if (modifyKernel) {
      debug?.log(
          "Combined Member Signature of ${fullNameForErrors}: new ForwardingNode($parent, $bestSoFar, $declarations, $kind)");
      Member stub =
          new ForwardingNode(hierarchy, parent, bestSoFar, declarations, kind)
              .finalize();
      if (parent.cls == stub.enclosingClass) {
        parent.cls.addMember(stub);
        KernelLibraryBuilder library = parent.library;
        if (bestSoFar.target is Procedure) {
          library.forwardersOrigins..add(stub)..add(bestSoFar.target);
        }
        debug?.log(
            "Combined Member Signature of ${fullNameForErrors}: added stub $stub");
        if (parent.isMixinApplication) {
          return combinedMemberSignatureResult = bestSoFar.target;
        } else {
          return combinedMemberSignatureResult = stub;
        }
      }
    }

    debug?.log(
        "Combined Member Signature of ${fullNameForErrors}: picked bestSoFar");
    return combinedMemberSignatureResult = bestSoFar.target;
  }

  @override
  DelayedMember withParent(KernelClassBuilder parent) {
    return parent == this.parent
        ? this
        : new InterfaceConflict(parent, declarations, isSetter, modifyKernel);
  }

  static Declaration combined(KernelClassBuilder parent, Declaration a,
      Declaration b, bool isSetter, bool createForwarders) {
    List<Declaration> declarations = <Declaration>[];
    if (a is DelayedMember) {
      a.addAllDeclarationsTo(declarations);
    } else {
      declarations.add(a);
    }
    if (b is DelayedMember) {
      b.addAllDeclarationsTo(declarations);
    } else {
      addDeclarationIfDifferent(b, declarations);
    }
    if (declarations.length == 1) {
      return declarations.single;
    } else {
      return new InterfaceConflict(
          parent, declarations, isSetter, createForwarders);
    }
  }
}

class AbstractMemberOverridingImplementation extends DelayedMember {
  AbstractMemberOverridingImplementation(
      KernelClassBuilder parent,
      Declaration abstractMember,
      Declaration concreteImplementation,
      bool isSetter,
      bool modifyKernel)
      : super(parent, <Declaration>[concreteImplementation, abstractMember],
            isSetter, modifyKernel);

  Declaration get concreteImplementation => declarations[0];

  Declaration get abstractMember => declarations[1];

  Member check(ClassHierarchyBuilder hierarchy) {
    if (!parent.isAbstract && !hierarchy.nodes[parent.cls].hasNoSuchMethod) {
      new DelayedOverrideCheck(parent, concreteImplementation, abstractMember)
          .check(hierarchy);
    }

    ProcedureKind kind = ProcedureKind.Method;
    if (abstractMember.isSetter || abstractMember.isGetter) {
      kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
    }
    if (modifyKernel) {
      // This call will add a body to the abstract method if needed for
      // isGenericCovariantImpl checks.
      new ForwardingNode(hierarchy, parent, abstractMember, declarations, kind)
          .finalize();
    }
    return abstractMember.target;
  }

  @override
  DelayedMember withParent(KernelClassBuilder parent) {
    return parent == this.parent
        ? this
        : new AbstractMemberOverridingImplementation(parent, abstractMember,
            concreteImplementation, isSetter, modifyKernel);
  }

  static Declaration selectAbstract(Declaration declaration) {
    if (declaration is AbstractMemberOverridingImplementation) {
      return declaration.abstractMember;
    } else {
      return declaration;
    }
  }

  static Declaration selectConcrete(Declaration declaration) {
    if (declaration is AbstractMemberOverridingImplementation) {
      return declaration.concreteImplementation;
    } else {
      return declaration;
    }
  }
}

void addDeclarationIfDifferent(
    Declaration declaration, List<Declaration> declarations) {
  Member target = declaration.target;
  if (target is Procedure) {
    FunctionNode function = target.function;
    for (int i = 0; i < declarations.length; i++) {
      Member other = declarations[i].target;
      if (other is Procedure) {
        if (hasSameSignature(function, other.function)) return;
      }
    }
  } else {
    for (int i = 0; i < declarations.length; i++) {
      if (declaration == declarations[i]) return;
    }
  }
  declarations.add(declaration);
}

String fullName(Declaration declaration) {
  String suffix = declaration.isSetter ? "=" : "";
  if (declaration is DelayedMember) {
    return "${declaration.fullNameForErrors}$suffix";
  }
  Declaration parent = declaration.parent;
  return parent == null
      ? "${declaration.fullNameForErrors}$suffix"
      : "${parent.fullNameForErrors}.${declaration.fullNameForErrors}$suffix";
}

int compareNamedParameters(VariableDeclaration a, VariableDeclaration b) {
  return a.name.compareTo(b.name);
}

bool isAbstract(Declaration declaration) {
  return declaration.target.isAbstract || declaration is InterfaceConflict;
}

bool inferParameterType(
    KernelClassBuilder cls,
    KernelProcedureBuilder member,
    FormalParameterBuilder<TypeBuilder> parameter,
    DartType type,
    bool hadTypesInferred,
    ClassHierarchyBuilder hierarchy) {
  debug?.log("Inferred type ${type} for ${parameter}");
  if (type == parameter.target.type) return true;
  bool result = true;
  if (hadTypesInferred) {
    reportCantInferParameterType(cls, member, parameter, hierarchy);
    type = const InvalidType();
    result = false;
  }
  parameter.target.type = type;
  member.hadTypesInferred = true;
  return result;
}

void reportCantInferParameterType(
    KernelClassBuilder cls,
    MemberBuilder member,
    FormalParameterBuilder<TypeBuilder> parameter,
    ClassHierarchyBuilder hierarchy) {
  String name = parameter.name;
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      parameter.charOffset,
      name.length,
      wasHandled: true);
}

bool inferReturnType(KernelClassBuilder cls, KernelProcedureBuilder member,
    DartType type, bool hadTypesInferred, ClassHierarchyBuilder hierarchy) {
  if (type == member.target.function.returnType) return true;
  bool result = true;
  if (hadTypesInferred) {
    reportCantInferReturnType(cls, member, hierarchy);
    type = const InvalidType();
    result = false;
  } else {
    member.hadTypesInferred = true;
  }
  member.target.function.returnType = type;
  return result;
}

void reportCantInferReturnType(KernelClassBuilder cls, MemberBuilder member,
    ClassHierarchyBuilder hierarchy) {
  String name = member.fullNameForErrors;
  List<LocatedMessage> context;
  // // TODO(ahe): The following is for debugging, but could be cleaned up and
  // // used to improve this error message in general.
  //
  // context = <LocatedMessage>[];
  // ClassHierarchyNode supernode = hierarchy.getNodeFromType(cls.supertype);
  // // TODO(ahe): Wrong template.
  // Template<Message Function(String)> template =
  //     templateMissingImplementationCause;
  // if (supernode != null) {
  //   Declaration superMember =
  //       supernode.getInterfaceMember(new Name(name), false);
  //   if (superMember != null) {
  //     context.add(template
  //         .withArguments(name)
  //         .withLocation(
  //             superMember.fileUri, superMember.charOffset, name.length));
  //   }
  //   superMember = supernode.getInterfaceMember(new Name(name), true);
  //   if (superMember != null) {
  //     context.add(template
  //         .withArguments(name)
  //         .withLocation(
  //             superMember.fileUri, superMember.charOffset, name.length));
  //   }
  // }
  // List<TypeBuilder> directInterfaces = cls.interfaces;
  // for (int i = 0; i < directInterfaces.length; i++) {
  //   ClassHierarchyNode supernode =
  //       hierarchy.getNodeFromType(directInterfaces[i]);
  //   if (supernode != null) {
  //     Declaration superMember =
  //         supernode.getInterfaceMember(new Name(name), false);
  //     if (superMember != null) {
  //       context.add(template
  //           .withArguments(name)
  //           .withLocation(
  //               superMember.fileUri, superMember.charOffset, name.length));
  //     }
  //     superMember = supernode.getInterfaceMember(new Name(name), true);
  //     if (superMember != null) {
  //       context.add(template
  //           .withArguments(name)
  //           .withLocation(
  //               superMember.fileUri, superMember.charOffset, name.length));
  //     }
  //   }
  // }
  cls.addProblem(
      templateCantInferReturnTypeDueToInconsistentOverrides.withArguments(name),
      member.charOffset,
      name.length,
      wasHandled: true,
      context: context);
}

void reportCantInferFieldType(
    KernelClassBuilder cls, KernelFieldBuilder member) {
  String name = member.fullNameForErrors;
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      member.charOffset,
      name.length,
      wasHandled: true);
}

KernelClassBuilder getClass(TypeBuilder type) {
  Declaration declaration = type.declaration;
  return declaration is KernelClassBuilder ? declaration : null;
}

bool hasExplicitReturnType(Declaration declaration) {
  assert(
      declaration is KernelProcedureBuilder || declaration is DillMemberBuilder,
      "${declaration.runtimeType}");
  return declaration is KernelProcedureBuilder
      ? declaration.returnType != null
      : true;
}

bool hasExplicitlyTypedFormalParameter(Declaration declaration, int index) {
  assert(
      declaration is KernelProcedureBuilder || declaration is DillMemberBuilder,
      "${declaration.runtimeType}");
  return declaration is KernelProcedureBuilder
      ? declaration.formals[index].type != null
      : true;
}
