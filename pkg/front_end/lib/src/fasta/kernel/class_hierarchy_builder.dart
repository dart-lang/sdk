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
import 'package:kernel/type_environment.dart';

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

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

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
        Builder,
        FormalParameterBuilder,
        ImplicitFieldType,
        ClassBuilder,
        FieldBuilder,
        NamedTypeBuilder,
        ProcedureBuilder,
        LibraryBuilder,
        MemberBuilder,
        NullabilityBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import 'types.dart' show Types;

const DebugLogger debug =
    const bool.fromEnvironment("debug.hierarchy") ? const DebugLogger() : null;

class DebugLogger {
  const DebugLogger();
  void log(Object message) => print(message);
}

int compareDeclarations(ClassMember a, ClassMember b) {
  return ClassHierarchy.compareMembers(a.member, b.member);
}

ProcedureKind memberKind(Member member) {
  return member is Procedure ? member.kind : null;
}

bool isNameVisibleIn(Name name, LibraryBuilder libraryBuilder) {
  return !name.isPrivate || name.library == libraryBuilder.library;
}

abstract class ClassMember {
  bool get isStatic;
  bool get isField;
  bool get isSetter;
  bool get isGetter;
  bool get isFinal;
  bool get isConst;
  Member get member;
  bool get isDuplicate;
  String get fullNameForErrors;
  ClassBuilder get classBuilder;
  Uri get fileUri;
  int get charOffset;
}

/// Returns true if [a] is a class member conflict with [b].  [a] is assumed to
/// be declared in the class, [b] is assumed to be inherited.
///
/// See the section named "Class Member Conflicts" in [Dart Programming
/// Language Specification](
/// ../../../../../../docs/language/dartLangSpec.tex#classMemberConflicts).
bool isInheritanceConflict(ClassMember a, ClassMember b) {
  if (a.isStatic) return true;
  if (memberKind(a.member) == memberKind(b.member)) return false;
  if (a.isField) return !(b.isField || b.isGetter || b.isSetter);
  if (b.isField) return !(a.isField || a.isGetter || a.isSetter);
  if (a.isSetter) return !(b.isGetter || b.isSetter);
  if (b.isSetter) return !(a.isGetter || a.isSetter);
  if (a is InterfaceConflict || b is InterfaceConflict) return false;
  return true;
}

bool impliesSetter(ClassMember declaration) {
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

  final ClassBuilder objectClassBuilder;

  final Loader loader;

  final Class objectClass;

  final Class futureClass;

  final Class futureOrClass;

  final Class functionClass;

  final Class nullClass;

  final List<DelayedOverrideCheck> overrideChecks = <DelayedOverrideCheck>[];

  final List<DelayedMember> delayedMemberChecks = <DelayedMember>[];

  // TODO(dmitryas): Consider removing this.
  final CoreTypes coreTypes;

  Types types;

  ClassHierarchyBuilder(this.objectClassBuilder, this.loader, this.coreTypes)
      : objectClass = objectClassBuilder.cls,
        futureClass = coreTypes.futureClass,
        futureOrClass = coreTypes.futureOrClass,
        functionClass = coreTypes.functionClass,
        nullClass = coreTypes.nullClass {
    types = new Types(this);
  }

  ClassHierarchyNode getNodeFromClass(ClassBuilder classBuilder) {
    return nodes[classBuilder.cls] ??=
        new ClassHierarchyNodeBuilder(this, classBuilder).build();
  }

  ClassHierarchyNode getNodeFromType(TypeBuilder type) {
    ClassBuilder cls = getClass(type);
    return cls == null ? null : getNodeFromClass(cls);
  }

  ClassHierarchyNode getNodeFromKernelClass(Class cls) {
    return nodes[cls] ??
        getNodeFromClass(loader.computeClassBuilderFromTargetClass(cls));
  }

  TypeBuilder asSupertypeOf(Class cls, Class supertype) {
    ClassHierarchyNode clsNode = getNodeFromKernelClass(cls);
    if (cls == supertype) {
      return new NamedTypeBuilder(
          clsNode.classBuilder.name, const NullabilityBuilder.omitted(), null)
        ..bind(clsNode.classBuilder);
    }
    ClassHierarchyNode supertypeNode = getNodeFromKernelClass(supertype);
    List<TypeBuilder> supertypes = clsNode.superclasses;
    int depth = supertypeNode.depth;
    Builder supertypeDeclaration = supertypeNode.classBuilder;
    if (depth < supertypes.length) {
      TypeBuilder asSupertypeOf = supertypes[depth];
      if (asSupertypeOf.declaration == supertypeDeclaration) {
        return asSupertypeOf;
      }
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
    if (kernelClass == nullClass) {
      if (superclass.typeParameters.isEmpty) {
        return coreTypes.legacyRawType(superclass);
      } else {
        // This is a safe fall-back for dealing with `Null`. It will likely be
        // faster to check for `Null` before calling this method.
        return new InterfaceType(
            superclass,
            new List<DartType>.filled(
                superclass.typeParameters.length, coreTypes.nullType));
      }
    }
    NamedTypeBuilder supertype = asSupertypeOf(kernelClass, superclass);
    if (supertype == null) return null;
    if (supertype.arguments == null && superclass.typeParameters.isEmpty) {
      return coreTypes.legacyRawType(superclass);
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
        DartType candidate1 =
            getKernelTypeAsInstanceOf(type1, node.classBuilder.cls);
        DartType candidate2 =
            getKernelTypeAsInstanceOf(type2, node.classBuilder.cls);
        if (candidate1 == candidate2) {
          common.add(node);
        }
      }
    }

    if (common.length == 1) return coreTypes.objectLegacyRawType;
    common.sort(ClassHierarchyNode.compareMaxInheritancePath);

    for (int i = 0; i < common.length - 1; i++) {
      ClassHierarchyNode node = common[i];
      if (node.maxInheritancePath != common[i + 1].maxInheritancePath) {
        return getKernelTypeAsInstanceOf(type1, node.classBuilder.cls);
      } else {
        do {
          i++;
        } while (node.maxInheritancePath == common[i + 1].maxInheritancePath);
      }
    }
    return coreTypes.objectLegacyRawType;
  }

  Member getInterfaceMemberKernel(Class cls, Name name, bool isSetter) {
    return getNodeFromKernelClass(cls)
        .getInterfaceMember(name, isSetter)
        ?.member;
  }

  Member getDispatchTargetKernel(Class cls, Name name, bool isSetter) {
    return getNodeFromKernelClass(cls)
        .getDispatchTarget(name, isSetter)
        ?.member;
  }

  Member getCombinedMemberSignatureKernel(Class cls, Name name, bool isSetter,
      int charOffset, SourceLibraryBuilder library) {
    ClassMember declaration =
        getNodeFromKernelClass(cls).getInterfaceMember(name, isSetter);
    if (declaration?.isStatic ?? true) return null;
    if (declaration.isDuplicate) {
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
      return declaration.member;
    }
  }

  static ClassHierarchyBuilder build(ClassBuilder objectClass,
      List<ClassBuilder> classes, SourceLoader loader, CoreTypes coreTypes) {
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, coreTypes);
    for (int i = 0; i < classes.length; i++) {
      ClassBuilder classBuilder = classes[i];
      if (!classBuilder.isPatch) {
        hierarchy.nodes[classBuilder.cls] =
            new ClassHierarchyNodeBuilder(hierarchy, classBuilder).build();
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

  final ClassBuilder classBuilder;

  bool hasNoSuchMethod = false;

  List<ClassMember> abstractMembers = null;

  ClassHierarchyNodeBuilder(this.hierarchy, this.classBuilder);

  ClassBuilder get objectClass => hierarchy.objectClassBuilder;

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
  ClassMember handleMergeConflict(
      ClassMember a, ClassMember b, MergeKind mergeKind) {
    debug?.log(
        "handleMergeConflict: ${fullName(a)} ${fullName(b)} ${mergeKind}");
    // TODO(ahe): Enable this optimization, but be careful about abstract
    // methods overriding concrete methods.
    // if (cls is DillClassBuilder) return a;
    if (a == b) return a;
    if (a.isDuplicate || b.isDuplicate) {
      // Don't check overrides involving duplicated members.
      return a;
    }
    ClassMember result = checkInheritanceConflict(a, b);
    if (result != null) return result;
    result = a;
    switch (mergeKind) {
      case MergeKind.superclassMembers:
      case MergeKind.superclassSetters:
        // [a] is a method declared in [cls]. This means it defines the
        // interface of this class regardless if its abstract.
        debug?.log("superclass: checkValidOverride("
            "${classBuilder.fullNameForErrors}, "
            "${fullName(a)}, ${fullName(b)})");
        checkValidOverride(
            a, AbstractMemberOverridingImplementation.selectAbstract(b));

        if (isAbstract(a)) {
          if (isAbstract(b)) {
            recordAbstractMember(a);
          } else {
            if (!classBuilder.isAbstract) {
              // The interface of this class is [a]. But the implementation is
              // [b]. So [b] must implement [a], unless [cls] is abstract.
              checkValidOverride(b, a);
            }
            result = new AbstractMemberOverridingImplementation(
                classBuilder,
                a,
                AbstractMemberOverridingImplementation.selectConcrete(b),
                mergeKind == MergeKind.superclassSetters,
                classBuilder.library.loader == hierarchy.loader);
            hierarchy.delayedMemberChecks.add(result);
          }
        } else if (classBuilder.isMixinApplication &&
            a.classBuilder != classBuilder) {
          result = InheritedImplementationInterfaceConflict.combined(
              classBuilder,
              a,
              b,
              mergeKind == MergeKind.superclassSetters,
              classBuilder.library.loader == hierarchy.loader,
              isInheritableConflict: false);
          if (result is DelayedMember) {
            hierarchy.delayedMemberChecks.add(result);
          }
        }

        Member target = result.member;
        if (target.enclosingClass != objectClass.cls &&
            target.name == noSuchMethodName) {
          hasNoSuchMethod = true;
        }
        break;

      case MergeKind.membersWithSetters:
      case MergeKind.settersWithMembers:
        if (a.classBuilder == classBuilder && b.classBuilder != classBuilder) {
          if (a is FieldBuilder) {
            if (a.isFinal && b.isSetter) {
              hierarchy.overrideChecks
                  .add(new DelayedOverrideCheck(classBuilder, a, b));
            } else {
              if (!inferFieldTypes(a, b)) {
                hierarchy.overrideChecks
                    .add(new DelayedOverrideCheck(classBuilder, a, b));
              }
            }
          } else if (a is ProcedureBuilder) {
            if (!inferMethodTypes(a, b)) {
              hierarchy.overrideChecks
                  .add(new DelayedOverrideCheck(classBuilder, a, b));
            }
          }
        }
        break;

      case MergeKind.interfacesMembers:
        result = InterfaceConflict.combined(classBuilder, a, b, false,
            classBuilder.library.loader == hierarchy.loader);
        break;

      case MergeKind.interfacesSetters:
        result = InterfaceConflict.combined(classBuilder, a, b, true,
            classBuilder.library.loader == hierarchy.loader);
        break;

      case MergeKind.supertypesMembers:
      case MergeKind.supertypesSetters:
        // [b] is inherited from an interface so it is implicitly abstract.

        a = AbstractMemberOverridingImplementation.selectAbstract(a);
        b = AbstractMemberOverridingImplementation.selectAbstract(b);

        // If [a] is declared in this class, it defines the interface.
        if (a.classBuilder == classBuilder) {
          debug?.log("supertypes: checkValidOverride("
              "${classBuilder.fullNameForErrors}, "
              "${fullName(a)}, ${fullName(b)})");
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
                classBuilder,
                a,
                b,
                mergeKind == MergeKind.supertypesSetters,
                classBuilder.library.loader == hierarchy.loader);
          } else {
            result = InheritedImplementationInterfaceConflict.combined(
                classBuilder,
                a,
                b,
                mergeKind == MergeKind.supertypesSetters,
                classBuilder.library.loader == hierarchy.loader);
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

  ClassMember checkInheritanceConflict(ClassMember a, ClassMember b) {
    if (a is DelayedMember) {
      ClassMember result;
      for (int i = 0; i < a.declarations.length; i++) {
        ClassMember d = checkInheritanceConflict(a.declarations[i], b);
        result ??= d;
      }
      return result;
    }
    if (b is DelayedMember) {
      ClassMember result;
      for (int i = 0; i < b.declarations.length; i++) {
        ClassMember d = checkInheritanceConflict(a, b.declarations[i]);
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

  bool inferMethodTypes(ProcedureBuilder a, ClassMember b) {
    debug?.log(
        "Trying to infer types for ${fullName(a)} based on ${fullName(b)}");
    if (b is DelayedMember) {
      bool hasSameSignature = true;
      List<ClassMember> declarations = b.declarations;
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
    ClassBuilder aClassBuilder = a.parent;
    Substitution aSubstitution;
    if (classBuilder != aClassBuilder) {
      assert(
          substitutions.containsKey(aClassBuilder.cls),
          "${classBuilder.fullNameForErrors} "
          "${aClassBuilder.fullNameForErrors}");
      aSubstitution = substitutions[aClassBuilder.cls];
      debug?.log("${classBuilder.fullNameForErrors} -> "
          "${aClassBuilder.fullNameForErrors} $aSubstitution");
    }
    ClassBuilder bClassBuilder = b.classBuilder;
    Substitution bSubstitution;
    if (classBuilder != bClassBuilder) {
      assert(
          substitutions.containsKey(bClassBuilder.cls),
          "${classBuilder.fullNameForErrors} "
          "${bClassBuilder.fullNameForErrors}");
      bSubstitution = substitutions[bClassBuilder.cls];
      debug?.log("${classBuilder.fullNameForErrors} -> "
          "${bClassBuilder.fullNameForErrors} $bSubstitution");
    }
    Procedure aProcedure = a.procedure;
    if (b.member is! Procedure) {
      debug?.log("Giving up 1");
      return false;
    }
    Procedure bProcedure = b.member;
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
      if (a.parent == classBuilder && a.returnType == null) {
        result = inferReturnType(
            classBuilder, a, bReturnType, hadTypesInferred, hierarchy);
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
        if (a.parent == classBuilder && a.formals[i].type == null) {
          result = inferParameterType(classBuilder, a, a.formals[i], bType,
              hadTypesInferred, hierarchy);
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
          FormalParameterBuilder parameter;
          for (int i = aPositional.length; i < a.formals.length; ++i) {
            if (a.formals[i].name == name) {
              parameter = a.formals[i];
              break;
            }
          }
          if (a.parent == classBuilder && parameter.type == null) {
            result = inferParameterType(
                classBuilder, a, parameter, bType, hadTypesInferred, hierarchy);
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

  bool inferGetterType(ProcedureBuilder a, ClassMember b) {
    debug?.log(
        "Inferring getter types for ${fullName(a)} based on ${fullName(b)}");
    Member bTarget = b.member;
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
    return a.procedure.function.returnType == bType;
  }

  bool inferSetterType(ProcedureBuilder a, ClassMember b) {
    debug?.log(
        "Inferring setter types for ${fullName(a)} based on ${fullName(b)}");
    Member bTarget = b.member;
    Procedure aProcedure = a.procedure;
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

  void checkValidOverride(ClassMember a, ClassMember b) {
    debug?.log(
        "checkValidOverride(${fullName(a)}, ${fullName(b)}) ${a.runtimeType}");
    if (a is ProcedureBuilder) {
      if (inferMethodTypes(a, b)) return;
    } else if (a.isField) {
      if (inferFieldTypes(a, b)) return;
    }
    Member aTarget = a.member;
    Member bTarget = b.member;
    if (aTarget is Procedure && !aTarget.isAccessor && bTarget is Procedure) {
      if (hasSameSignature(aTarget.function, bTarget.function)) return;
    }

    if (b is DelayedMember) {
      for (int i = 0; i < b.declarations.length; i++) {
        hierarchy.overrideChecks
            .add(new DelayedOverrideCheck(classBuilder, a, b.declarations[i]));
      }
    } else {
      hierarchy.overrideChecks
          .add(new DelayedOverrideCheck(classBuilder, a, b));
    }
  }

  bool inferFieldTypes(MemberBuilder a, ClassMember b) {
    debug?.log("Trying to infer field types for ${fullName(a)} "
        "based on ${fullName(b)}");
    if (b is DelayedMember) {
      bool hasSameSignature = true;
      List<ClassMember> declarations = b.declarations;
      for (int i = 0; i < declarations.length; i++) {
        if (!inferFieldTypes(a, declarations[i])) {
          hasSameSignature = false;
        }
      }
      return hasSameSignature;
    }
    Member bTarget = b.member;
    DartType inheritedType;
    if (bTarget is Procedure) {
      if (bTarget.isSetter) {
        VariableDeclaration parameter =
            bTarget.function.positionalParameters.single;
        // inheritedType = parameter.type;
        copyFieldCovarianceFromParameter(a.parent, a.member, parameter);
        if (!hasExplicitlyTypedFormalParameter(b, 0)) {
          debug?.log("Giving up (type may be inferred)");
          return false;
        }
      } else if (bTarget.isGetter) {
        if (!hasExplicitReturnType(b)) return false;
        inheritedType = bTarget.function.returnType;
      }
    } else if (bTarget is Field) {
      copyFieldCovariance(a.parent, a.member, bTarget);
      inheritedType = bTarget.type;
    }
    if (inheritedType == null) {
      debug?.log("Giving up (inheritedType == null)\n${StackTrace.current}");
      return false;
    }
    ClassBuilder aClassBuilder = a.parent;
    Substitution aSubstitution;
    if (classBuilder != aClassBuilder) {
      assert(
          substitutions.containsKey(aClassBuilder.cls),
          "${classBuilder.fullNameForErrors} "
          "${aClassBuilder.fullNameForErrors}");
      aSubstitution = substitutions[aClassBuilder.cls];
      debug?.log("${classBuilder.fullNameForErrors} -> "
          "${aClassBuilder.fullNameForErrors} $aSubstitution");
    }
    ClassBuilder bClassBuilder = b.classBuilder;
    Substitution bSubstitution;
    if (classBuilder != bClassBuilder) {
      assert(
          substitutions.containsKey(bClassBuilder.cls),
          "${classBuilder.fullNameForErrors} "
          "${bClassBuilder.fullNameForErrors}");
      bSubstitution = substitutions[bClassBuilder.cls];
      debug?.log("${classBuilder.fullNameForErrors} -> "
          "${bClassBuilder.fullNameForErrors} $bSubstitution");
    }
    if (bSubstitution != null && inheritedType is! ImplicitFieldType) {
      inheritedType = bSubstitution.substituteType(inheritedType);
    }

    Field aField = a.member;
    DartType declaredType = aField.type;
    if (aSubstitution != null) {
      declaredType = aSubstitution.substituteType(declaredType);
    }
    if (declaredType == inheritedType) return true;

    bool result = false;
    if (a is FieldBuilder) {
      if (a.parent == classBuilder && a.type == null) {
        if (a.hadTypesInferred) {
          reportCantInferFieldType(classBuilder, a);
          inheritedType = const InvalidType();
        } else {
          result = true;
          a.hadTypesInferred = true;
        }
        if (inheritedType is ImplicitFieldType) {
          SourceLibraryBuilder library = classBuilder.library;
          (library.implicitlyTypedFields ??= <FieldBuilder>[]).add(a);
        }
        a.field.type = inheritedType;
      }
    }
    return result;
  }

  void copyParameterCovariance(Builder parent, VariableDeclaration aParameter,
      VariableDeclaration bParameter) {
    if (parent == classBuilder) {
      if (bParameter.isCovariant) {
        aParameter.isCovariant = true;
      }
      if (bParameter.isGenericCovariantImpl) {
        aParameter.isGenericCovariantImpl = true;
      }
    }
  }

  void copyParameterCovarianceFromField(
      Builder parent, VariableDeclaration aParameter, Field bField) {
    if (parent == classBuilder) {
      if (bField.isCovariant) {
        aParameter.isCovariant = true;
      }
      if (bField.isGenericCovariantImpl) {
        aParameter.isGenericCovariantImpl = true;
      }
    }
  }

  void copyFieldCovariance(Builder parent, Field aField, Field bField) {
    if (parent == classBuilder) {
      if (bField.isCovariant) {
        aField.isCovariant = true;
      }
      if (bField.isGenericCovariantImpl) {
        aField.isGenericCovariantImpl = true;
      }
    }
  }

  void copyFieldCovarianceFromParameter(
      Builder parent, Field aField, VariableDeclaration bParameter) {
    if (parent == classBuilder) {
      if (bParameter.isCovariant) {
        aField.isCovariant = true;
      }
      if (bParameter.isGenericCovariantImpl) {
        aField.isGenericCovariantImpl = true;
      }
    }
  }

  void copyTypeParameterCovariance(
      Builder parent, TypeParameter aParameter, TypeParameter bParameter) {
    if (parent == classBuilder) {
      if (bParameter.isGenericCovariantImpl) {
        aParameter.isGenericCovariantImpl = true;
      }
    }
  }

  void reportInheritanceConflict(ClassMember a, ClassMember b) {
    String name = a.fullNameForErrors;
    if (a.classBuilder != b.classBuilder) {
      if (a.classBuilder == classBuilder) {
        classBuilder.addProblem(
            messageDeclaredMemberConflictsWithInheritedMember,
            a.charOffset,
            name.length,
            context: <LocatedMessage>[
              messageDeclaredMemberConflictsWithInheritedMemberCause
                  .withLocation(b.fileUri, b.charOffset, name.length)
            ]);
      } else {
        classBuilder.addProblem(messageInheritedMembersConflict,
            classBuilder.charOffset, classBuilder.fullNameForErrors.length,
            context: inheritedConflictContext(a, b));
      }
    } else if (a.isStatic != b.isStatic) {
      ClassMember staticMember;
      ClassMember instanceMember;
      if (a.isStatic) {
        staticMember = a;
        instanceMember = b;
      } else {
        staticMember = b;
        instanceMember = a;
      }
      classBuilder.library.addProblem(messageStaticAndInstanceConflict,
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
      ClassMember existing;
      ClassMember duplicate;
      assert(a.fileUri == b.fileUri);
      if (a.charOffset < b.charOffset) {
        existing = a;
        duplicate = b;
      } else {
        existing = b;
        duplicate = a;
      }
      classBuilder.library.addProblem(
          templateDuplicatedDeclaration.withArguments(name),
          duplicate.charOffset,
          name.length,
          duplicate.fileUri,
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
  void handleOnlyA(ClassMember member, MergeKind mergeKind) {
    if (mergeKind == MergeKind.interfacesMembers ||
        mergeKind == MergeKind.interfacesSetters) {
      return;
    }
    // TODO(ahe): Enable this optimization:
    // if (cls is DillClassBuilder) return;
    // assert(mergeKind == MergeKind.interfaces ||
    //    member is! InterfaceConflict);
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
  ClassMember handleOnlyB(ClassMember member, MergeKind mergeKind) {
    if (mergeKind == MergeKind.interfacesMembers ||
        mergeKind == MergeKind.interfacesSetters) {
      return member;
    }
    // TODO(ahe): Enable this optimization:
    // if (cls is DillClassBuilder) return member;
    Member target = member.member;
    if ((mergeKind == MergeKind.supertypesMembers ||
            mergeKind == MergeKind.supertypesSetters) ||
        ((mergeKind == MergeKind.superclassMembers ||
                mergeKind == MergeKind.superclassSetters) &&
            target.isAbstract)) {
      if (isNameVisibleIn(target.name, classBuilder.library)) {
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
      hierarchy.delayedMemberChecks.add(member.withParent(classBuilder));
    }
    return member;
  }

  void recordAbstractMember(ClassMember member) {
    abstractMembers ??= <ClassMember>[];
    if (member is DelayedMember) {
      abstractMembers.addAll(member.declarations);
    } else {
      abstractMembers.add(member);
    }
  }

  ClassHierarchyNode build() {
    assert(!classBuilder.isPatch);
    ClassHierarchyNode supernode;
    if (objectClass != classBuilder.origin) {
      supernode = hierarchy.getNodeFromType(classBuilder.supertype);
      if (supernode == null) {
        supernode = hierarchy.getNodeFromClass(objectClass);
      }
      assert(supernode != null);
    }

    Scope scope = classBuilder.scope;
    if (classBuilder.isMixinApplication) {
      Builder mixin = classBuilder.mixedInType.declaration;
      inferMixinApplication();
      // recordSupertype(cls.mixedInType);
      while (mixin.isNamedMixinApplication) {
        ClassBuilder named = mixin;
        // recordSupertype(named.mixedInType);
        mixin = named.mixedInType.declaration;
      }
      if (mixin is ClassBuilder) {
        scope = mixin.scope.computeMixinScope();
      }
    }

    /// Members (excluding setters) declared in [cls].
    List<ClassMember> localMembers =
        new List<ClassMember>.from(scope.local.values)
          ..sort(compareDeclarations);

    /// Setters declared in [cls].
    List<ClassMember> localSetters =
        new List<ClassMember>.from(scope.setters.values)
          ..sort(compareDeclarations);

    // Add implied setters from fields in [localMembers].
    localSetters = mergeAccessors(localMembers, localSetters);

    /// Members (excluding setters) declared in [cls] or its superclasses. This
    /// includes static methods of [cls], but not its superclasses.
    List<ClassMember> classMembers;

    /// Setters declared in [cls] or its superclasses. This includes static
    /// setters of [cls], but not its superclasses.
    List<ClassMember> classSetters;

    /// Members (excluding setters) inherited from interfaces. This contains no
    /// static members. Is null if no interfaces are implemented by this class
    /// or its superclasses.
    List<ClassMember> interfaceMembers;

    /// Setters inherited from interfaces. This contains no static setters. Is
    /// null if no interfaces are implemented by this class or its
    /// superclasses.
    List<ClassMember> interfaceSetters;

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
          substSupertypes(classBuilder.supertype, supernode.superclasses));
      superclasses[superclasses.length - 1] =
          recordSupertype(classBuilder.supertype);

      List<TypeBuilder> directInterfaces =
          ignoreFunction(classBuilder.interfaces);
      if (classBuilder.isMixinApplication) {
        if (directInterfaces == null) {
          directInterfaces = <TypeBuilder>[classBuilder.mixedInType];
        } else {
          directInterfaces = <TypeBuilder>[classBuilder.mixedInType]
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
            substSupertypes(classBuilder.supertype, superclassInterfaces);
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
    if (abstractMembers != null && !classBuilder.isAbstract) {
      if (!hasNoSuchMethod) {
        reportMissingMembers();
      } else {
        installNsmHandlers();
      }
    }
    return new ClassHierarchyNode(
      classBuilder,
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
      debug?.log("In ${this.classBuilder.fullNameForErrors} "
          "recordSupertype(${supertype.fullNameForErrors})");
      Builder declaration = supertype.declaration;
      if (declaration is! ClassBuilder) return supertype;
      ClassBuilder classBuilder = declaration;
      if (classBuilder.isMixinApplication) {
        recordSupertype(classBuilder.mixedInType);
      }
      List<TypeVariableBuilder> typeVariableBuilders =
          classBuilder.typeVariables;
      if (typeVariableBuilders == null) {
        substitutions[classBuilder.cls] = Substitution.empty;
        assert(classBuilder.cls.typeParameters.isEmpty);
      } else {
        List<TypeBuilder> arguments =
            supertype.arguments ?? computeDefaultTypeArguments(supertype);
        if (arguments.length != typeVariableBuilders.length) {
          arguments = computeDefaultTypeArguments(supertype);
        }
        List<DartType> typeArguments = new List<DartType>(arguments.length);
        List<TypeParameter> typeParameters =
            new List<TypeParameter>(arguments.length);
        for (int i = 0; i < arguments.length; i++) {
          typeParameters[i] = typeVariableBuilders[i].parameter;
          typeArguments[i] = arguments[i].build(this.classBuilder.parent);
        }
        substitutions[classBuilder.cls] =
            Substitution.fromPairs(typeParameters, typeArguments);
      }
    }
    return supertype;
  }

  List<TypeBuilder> substSupertypes(
      NamedTypeBuilder supertype, List<TypeBuilder> supertypes) {
    Builder declaration = supertype.declaration;
    if (declaration is! ClassBuilder) return supertypes;
    ClassBuilder cls = declaration;
    List<TypeVariableBuilder> typeVariables = cls.typeVariables;
    if (typeVariables == null) {
      debug?.log("In ${this.classBuilder.fullNameForErrors} "
          "$supertypes aren't substed");
      for (int i = 0; i < supertypes.length; i++) {
        recordSupertype(supertypes[i]);
      }
      return supertypes;
    }
    Map<TypeVariableBuilder, TypeBuilder> substitution =
        <TypeVariableBuilder, TypeBuilder>{};
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
        debug?.log(
            "In ${this.classBuilder.fullNameForErrors} $supertype -> $substed");
        result ??= supertypes.toList();
        result[i] = substed;
      } else {
        debug?.log("In ${this.classBuilder.fullNameForErrors} "
            "$supertype isn't substed");
      }
    }
    return result ?? supertypes;
  }

  List<TypeBuilder> computeDefaultTypeArguments(TypeBuilder type) {
    ClassBuilder cls = type.declaration;
    List<TypeBuilder> result = new List<TypeBuilder>(cls.typeVariables.length);
    for (int i = 0; i < result.length; ++i) {
      TypeVariableBuilder tv = cls.typeVariables[i];
      result[i] = tv.defaultType ??
          cls.library.loader.computeTypeBuilder(tv.parameter.defaultType);
    }
    return result;
  }

  TypeBuilder addInterface(List<TypeBuilder> interfaces,
      List<TypeBuilder> superclasses, TypeBuilder type) {
    ClassHierarchyNode node = hierarchy.getNodeFromType(type);
    if (node == null) return null;
    int depth = node.depth;
    int myDepth = superclasses.length;
    if (depth < myDepth &&
        superclasses[depth].declaration == node.classBuilder) {
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
    debug?.log("mergeInterfaces($classBuilder (${this.classBuilder}) "
        "${supernode.interfaces} ${interfaces}");
    List<List<ClassMember>> memberLists =
        new List<List<ClassMember>>(interfaces.length + 1);
    List<List<ClassMember>> setterLists =
        new List<List<ClassMember>>(interfaces.length + 1);
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

  List<ClassMember> mergeLists(
      List<List<ClassMember>> input, MergeKind mergeKind) {
    // This is a k-way merge sort (where k is `input.length + 1`). We merge the
    // lists pairwise, which reduces the number of lists to merge by half on
    // each iteration. Consequently, we perform O(log k) merges.
    while (input.length > 1) {
      List<List<ClassMember>> output = <List<ClassMember>>[];
      for (int i = 0; i < input.length - 1; i += 2) {
        List<ClassMember> first = input[i];
        List<ClassMember> second = input[i + 1];
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
  List<ClassMember> mergeAccessors(
      List<ClassMember> members, List<ClassMember> setters) {
    final List<ClassMember> mergedSetters = new List<ClassMember>.filled(
        members.length + setters.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0;
    int j = 0;
    while (i < members.length && j < setters.length) {
      final ClassMember member = members[i];
      final ClassMember setter = setters[j];
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
      final ClassMember member = members[i];
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
      ClassMember declaration = abstractMembers[i];
      Member target = declaration.member;
      if (isNameVisibleIn(target.name, classBuilder.library)) {
        String name = declaration.fullNameForErrors;
        String className = declaration.classBuilder?.fullNameForErrors;
        String displayName =
            declaration.isSetter ? "$className.$name=" : "$className.$name";
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
    classBuilder.addProblem(
        templateMissingImplementationNotAbstract.withArguments(
            classBuilder.fullNameForErrors, names),
        classBuilder.charOffset,
        classBuilder.fullNameForErrors.length,
        context: context);
  }

  void installNsmHandlers() {
    // TODO(ahe): Implement this.
  }

  List<ClassMember> merge(
      List<ClassMember> aList, List<ClassMember> bList, MergeKind mergeKind) {
    final List<ClassMember> result = new List<ClassMember>.filled(
        aList.length + bList.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0;
    int j = 0;
    while (i < aList.length && j < bList.length) {
      final ClassMember a = aList[i];
      final ClassMember b = bList[j];
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
      final ClassMember a = aList[i];
      if (!(mergeKind == MergeKind.interfacesMembers ||
              mergeKind == MergeKind.interfacesSetters) ||
          !a.isStatic) {
        handleOnlyA(a, mergeKind);
        result[storeIndex++] = a;
      }
      i++;
    }
    while (j < bList.length) {
      final ClassMember b = bList[j];
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
    Class cls = classBuilder.cls;
    Supertype mixedInType = cls.mixedInType;
    if (mixedInType == null) return;
    List<DartType> typeArguments = mixedInType.typeArguments;
    if (typeArguments.isEmpty || typeArguments.first is! UnknownType) return;
    new BuilderMixinInferrer(
            classBuilder,
            hierarchy.coreTypes,
            new TypeBuilderConstraintGatherer(
                hierarchy, mixedInType.classNode.typeParameters))
        .infer(cls);
    List<TypeBuilder> inferredArguments =
        new List<TypeBuilder>(typeArguments.length);
    for (int i = 0; i < typeArguments.length; i++) {
      inferredArguments[i] =
          hierarchy.loader.computeTypeBuilder(typeArguments[i]);
    }
    NamedTypeBuilder mixedInTypeBuilder = classBuilder.mixedInType;
    mixedInTypeBuilder.arguments = inferredArguments;
  }

  /// The class Function from dart:core is supposed to be ignored when used as
  /// an interface.
  List<TypeBuilder> ignoreFunction(List<TypeBuilder> interfaces) {
    if (interfaces == null) return null;
    for (int i = 0; i < interfaces.length; i++) {
      ClassBuilder classBuilder = getClass(interfaces[i]);
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

  /// All the members of this class including [classMembers] of its
  /// superclasses. The members are sorted by [compareDeclarations].
  final List<ClassMember> classMembers;

  /// Similar to [classMembers] but for setters.
  final List<ClassMember> classSetters;

  /// All the interface members of this class including [interfaceMembers] of
  /// its supertypes. The members are sorted by [compareDeclarations].
  ///
  /// In addition to the members of [classMembers] this also contains members
  /// from interfaces.
  ///
  /// This may be null, in which case [classMembers] is the interface members.
  final List<ClassMember> interfaceMembers;

  /// Similar to [interfaceMembers] but for setters.
  ///
  /// This may be null, in which case [classSetters] is the interface setters.
  final List<ClassMember> interfaceSetters;

  /// All superclasses of [classBuilder] excluding itself. The classes are
  /// sorted by depth from the root (Object) in ascending order.
  final List<TypeBuilder> superclasses;

  /// The list of all classes implemented by [classBuilder] and its supertypes
  /// excluding any classes from [superclasses].
  final List<TypeBuilder> interfaces;

  /// The longest inheritance path from [classBuilder] to `Object`.
  final int maxInheritancePath;

  int get depth => superclasses.length;

  final bool hasNoSuchMethod;

  ClassHierarchyNode(
      this.classBuilder,
      this.classMembers,
      this.classSetters,
      this.interfaceMembers,
      this.interfaceSetters,
      this.superclasses,
      this.interfaces,
      this.maxInheritancePath,
      this.hasNoSuchMethod);

  /// Returns a list of all supertypes of [classBuilder], including this node.
  List<ClassHierarchyNode> computeAllSuperNodes(
      ClassHierarchyBuilder hierarchy) {
    List<ClassHierarchyNode> result = new List<ClassHierarchyNode>(
        1 + superclasses.length + interfaces.length);
    for (int i = 0; i < superclasses.length; i++) {
      Builder declaration = superclasses[i].declaration;
      if (declaration is ClassBuilder) {
        result[i] = hierarchy.getNodeFromClass(declaration);
      }
    }
    for (int i = 0; i < interfaces.length; i++) {
      Builder declaration = interfaces[i].declaration;
      if (declaration is ClassBuilder) {
        result[i + superclasses.length] =
            hierarchy.getNodeFromClass(declaration);
      }
    }
    return result..last = this;
  }

  String toString([StringBuffer sb]) {
    sb ??= new StringBuffer();
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
      List<ClassMember> members, StringBuffer sb, String heading) {
    sb.write("  ");
    sb.write(heading);
    sb.writeln(":");
    for (ClassMember member in members) {
      sb
        ..write("    ")
        ..write(member.classBuilder.fullNameForErrors)
        ..write(".")
        ..write(member.fullNameForErrors)
        ..writeln();
    }
  }

  ClassMember getInterfaceMember(Name name, bool isSetter) {
    return findMember(
        name,
        isSetter
            ? interfaceSetters ?? classSetters
            : interfaceMembers ?? classMembers);
  }

  ClassMember findMember(Name name, List<ClassMember> declarations) {
    // TODO(ahe): Consider creating a map or scope. The obvious choice would be
    // to use scopes, but they don't handle private names correctly.

    // This is a copy of `ClassHierarchy.findMemberByName`.
    int low = 0, high = declarations.length - 1;
    while (low <= high) {
      int mid = low + ((high - low) >> 1);
      ClassMember pivot = declarations[mid];
      int comparison = ClassHierarchy.compareNames(name, pivot.member.name);
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

  ClassMember getDispatchTarget(Name name, bool isSetter) {
    return findMember(name, isSetter ? classSetters : classMembers);
  }

  static int compareMaxInheritancePath(
      ClassHierarchyNode a, ClassHierarchyNode b) {
    return b.maxInheritancePath.compareTo(a.maxInheritancePath);
  }
}

class MergeResult {
  final List<ClassMember> mergedMembers;

  final List<ClassMember> mergedSetters;

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

List<LocatedMessage> inheritedConflictContext(ClassMember a, ClassMember b) {
  return inheritedConflictContextKernel(
      a.member, b.member, a.fullNameForErrors.length);
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
  final ClassBuilder cls;

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
  Class get objectClass => hierarchy.objectClass;

  @override
  Class get functionClass => hierarchy.functionClass;

  @override
  Class get futureClass => hierarchy.futureClass;

  @override
  Class get futureOrClass => hierarchy.futureOrClass;

  @override
  Class get nullClass => hierarchy.nullClass;

  @override
  InterfaceType get nullType => hierarchy.coreTypes.nullType;

  @override
  InterfaceType get objectLegacyRawType =>
      hierarchy.coreTypes.objectLegacyRawType;

  @override
  InterfaceType get functionLegacyRawType =>
      hierarchy.coreTypes.functionLegacyRawType;

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
    return new InterfaceType(hierarchy.futureClass, <DartType>[type]);
  }

  @override
  bool isSubtypeOf(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    return hierarchy.types.isSubtypeOfKernel(subtype, supertype, mode);
  }

  @override
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    return hierarchy.getKernelLegacyLeastUpperBound(type1, type2);
  }
}

class DelayedOverrideCheck {
  final ClassBuilder classBuilder;
  final ClassMember a;
  final ClassMember b;

  const DelayedOverrideCheck(this.classBuilder, this.a, this.b);

  void check(ClassHierarchyBuilder hierarchy) {
    void callback(
        Member declaredMember, Member interfaceMember, bool isSetter) {
      classBuilder.checkOverride(
          hierarchy.types, declaredMember, interfaceMember, isSetter, callback,
          isInterfaceCheck: !classBuilder.isMixinApplication);
    }

    ClassMember a = this.a;
    debug?.log("Delayed override check of ${fullName(a)} "
        "${fullName(b)} wrt. ${classBuilder.fullNameForErrors}");
    if (classBuilder == a.classBuilder) {
      if (a is ProcedureBuilder) {
        if (a.isGetter && !hasExplicitReturnType(a)) {
          DartType type;
          if (b.isGetter) {
            Procedure bTarget = b.member;
            type = bTarget.function.returnType;
          } else if (b.isSetter) {
            Procedure bTarget = b.member;
            type = bTarget.function.positionalParameters.single.type;
          } else if (b.isField) {
            Field bTarget = b.member;
            type = bTarget.type;
          }
          if (type != null) {
            type = Substitution.fromInterfaceType(
                    hierarchy.getKernelTypeAsInstanceOf(
                        classBuilder.cls.thisType, b.member.enclosingClass))
                .substituteType(type);
            if (!a.hadTypesInferred || !b.isSetter) {
              inferReturnType(
                  classBuilder, a, type, a.hadTypesInferred, hierarchy);
            }
          }
        } else if (a.isSetter && !hasExplicitlyTypedFormalParameter(a, 0)) {
          DartType type;
          if (b.isGetter) {
            Procedure bTarget = b.member;
            type = bTarget.function.returnType;
          } else if (b.isSetter) {
            Procedure bTarget = b.member;
            type = bTarget.function.positionalParameters.single.type;
          } else if (b.isField) {
            Field bTarget = b.member;
            type = bTarget.type;
          }
          if (type != null) {
            type = Substitution.fromInterfaceType(
                    hierarchy.getKernelTypeAsInstanceOf(
                        classBuilder.cls.thisType, b.member.enclosingClass))
                .substituteType(type);
            if (!a.hadTypesInferred || !b.isGetter) {
              inferParameterType(classBuilder, a, a.formals.single, type,
                  a.hadTypesInferred, hierarchy);
            }
          }
        }
        a.hadTypesInferred = true;
      } else if (a is FieldBuilder && a.type == null) {
        DartType type;
        if (b.isGetter) {
          Procedure bTarget = b.member;
          type = bTarget.function.returnType;
        } else if (b.isSetter) {
          Procedure bTarget = b.member;
          type = bTarget.function.positionalParameters.single.type;
        } else if (b.isField) {
          Field bTarget = b.member;
          type = bTarget.type;
        }
        if (type != null) {
          type = Substitution.fromInterfaceType(
                  hierarchy.getKernelTypeAsInstanceOf(
                      classBuilder.cls.thisType, b.member.enclosingClass))
              .substituteType(type);
          if (type != a.field.type) {
            if (a.hadTypesInferred) {
              if (b.isSetter &&
                  (!impliesSetter(a) ||
                      hierarchy.types.isSubtypeOfKernel(type, a.field.type,
                          SubtypeCheckMode.ignoringNullabilities))) {
                type = a.field.type;
              } else {
                reportCantInferFieldType(classBuilder, a);
                type = const InvalidType();
              }
            }
            debug?.log("Inferred type ${type} for ${fullName(a)}");
            a.field.type = type;
          }
        }
        a.hadTypesInferred = true;
      }
    }

    callback(a.member, b.member, a.isSetter);
  }
}

abstract class DelayedMember implements ClassMember {
  /// The class which has inherited [declarations].
  @override
  final ClassBuilder classBuilder;

  /// Conflicting declarations.
  final List<ClassMember> declarations;

  final bool isSetter;

  final bool modifyKernel;

  DelayedMember(
      this.classBuilder, this.declarations, this.isSetter, this.modifyKernel);

  bool get isStatic => false;
  bool get isField => false;

  bool get isGetter => false;
  bool get isFinal => false;
  bool get isConst => false;
  bool get isDuplicate => false;

  void addAllDeclarationsTo(List<ClassMember> declarations) {
    for (int i = 0; i < this.declarations.length; i++) {
      addDeclarationIfDifferent(this.declarations[i], declarations);
    }
    assert(declarations.toSet().length == declarations.length);
  }

  Member check(ClassHierarchyBuilder hierarchy);

  DelayedMember withParent(ClassBuilder parent);

  @override
  Uri get fileUri => classBuilder.fileUri;

  @override
  int get charOffset => classBuilder.charOffset;

  @override
  String get fullNameForErrors => declarations.map(fullName).join("%");

  bool get isInheritableConflict => true;

  @override
  Member get member => declarations.first.member;
}

/// This represents a concrete implementation inherited from a superclass that
/// has conflicts with methods inherited from an interface. The concrete
/// implementation is the first element of [declarations].
class InheritedImplementationInterfaceConflict extends DelayedMember {
  Member combinedMemberSignatureResult;

  @override
  final bool isInheritableConflict;

  InheritedImplementationInterfaceConflict(ClassBuilder parent,
      List<ClassMember> declarations, bool isSetter, bool modifyKernel,
      {this.isInheritableConflict = true})
      : super(parent, declarations, isSetter, modifyKernel);

  @override
  String toString() {
    return "InheritedImplementationInterfaceConflict("
        "${classBuilder.fullNameForErrors}, "
        "[${declarations.map(fullName).join(', ')}])";
  }

  @override
  Member check(ClassHierarchyBuilder hierarchy) {
    if (combinedMemberSignatureResult != null) {
      return combinedMemberSignatureResult;
    }
    if (!classBuilder.isAbstract) {
      ClassMember concreteImplementation = declarations.first;
      for (int i = 1; i < declarations.length; i++) {
        new DelayedOverrideCheck(
                classBuilder, concreteImplementation, declarations[i])
            .check(hierarchy);
      }
    }
    return combinedMemberSignatureResult = new InterfaceConflict(
            classBuilder, declarations, isSetter, modifyKernel)
        .check(hierarchy);
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new InheritedImplementationInterfaceConflict(
            parent, declarations, isSetter, modifyKernel);
  }

  static ClassMember combined(
      ClassBuilder parent,
      ClassMember concreteImplementation,
      ClassMember other,
      bool isSetter,
      bool createForwarders,
      {bool isInheritableConflict = true}) {
    List<ClassMember> declarations = <ClassMember>[];
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
  InterfaceConflict(ClassBuilder parent, List<ClassMember> declarations,
      bool isSetter, bool modifyKernel)
      : super(parent, declarations, isSetter, modifyKernel);

  Member combinedMemberSignatureResult;

  @override
  String toString() {
    return "InterfaceConflict(${classBuilder.fullNameForErrors}, "
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
      unhandled("${member.runtimeType}", "$member", classBuilder.charOffset,
          classBuilder.fileUri);
    }
    return Substitution.fromInterfaceType(hierarchy.getKernelTypeAsInstanceOf(
            thisType, member.enclosingClass))
        .substituteType(type);
  }

  bool isMoreSpecific(ClassHierarchyBuilder hierarchy, DartType a, DartType b) {
    if (isSetter) {
      return hierarchy.types
          .isSubtypeOfKernel(b, a, SubtypeCheckMode.ignoringNullabilities);
    } else {
      return hierarchy.types
          .isSubtypeOfKernel(a, b, SubtypeCheckMode.ignoringNullabilities);
    }
  }

  @override
  Member check(ClassHierarchyBuilder hierarchy) {
    if (combinedMemberSignatureResult != null) {
      return combinedMemberSignatureResult;
    }
    if (classBuilder.library is! SourceLibraryBuilder) {
      return combinedMemberSignatureResult = declarations.first.member;
    }
    DartType thisType = classBuilder.cls.thisType;
    ClassMember bestSoFar;
    DartType bestTypeSoFar;
    for (int i = declarations.length - 1; i >= 0; i--) {
      ClassMember candidate = declarations[i];
      Member target = candidate.member;
      DartType candidateType = computeMemberType(hierarchy, thisType, target);
      if (bestSoFar == null) {
        bestSoFar = candidate;
        bestTypeSoFar = candidateType;
      } else {
        if (isMoreSpecific(hierarchy, candidateType, bestTypeSoFar)) {
          debug?.log("Combined Member Signature: ${fullName(candidate)} "
              "${candidateType} <: ${fullName(bestSoFar)} ${bestTypeSoFar}");
          bestSoFar = candidate;
          bestTypeSoFar = candidateType;
        } else {
          debug?.log("Combined Member Signature: "
              "${fullName(candidate)} !<: ${fullName(bestSoFar)}");
        }
      }
    }
    if (bestSoFar != null) {
      debug?.log("Combined Member Signature bestSoFar: ${fullName(bestSoFar)}");
      for (int i = 0; i < declarations.length; i++) {
        ClassMember candidate = declarations[i];
        Member target = candidate.member;
        DartType candidateType = computeMemberType(hierarchy, thisType, target);
        if (!isMoreSpecific(hierarchy, bestTypeSoFar, candidateType)) {
          debug?.log("Combined Member Signature: "
              "${fullName(bestSoFar)} !<: ${fullName(candidate)}");

          String uri = '${classBuilder.library.uri}';
          if (uri == 'dart:js' &&
                  classBuilder.fileUri.pathSegments.last == 'js_dart2js.dart' ||
              uri == 'dart:_interceptors' &&
                  classBuilder.fileUri.pathSegments.last == 'js_number.dart') {
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
      String name = classBuilder.fullNameForErrors;
      int length = classBuilder.isAnonymousMixinApplication ? 1 : name.length;
      List<LocatedMessage> context = declarations.map((ClassMember d) {
        return messageDeclaredMemberConflictsWithInheritedMemberCause
            .withLocation(d.fileUri, d.charOffset, d.fullNameForErrors.length);
      }).toList();

      classBuilder.addProblem(
          templateCombinedMemberSignatureFailed.withArguments(
              classBuilder.fullNameForErrors,
              declarations.first.fullNameForErrors),
          classBuilder.charOffset,
          length,
          context: context);
      return null;
    }
    debug?.log("Combined Member Signature of ${fullNameForErrors}: "
        "${fullName(bestSoFar)}");

    ProcedureKind kind = ProcedureKind.Method;
    Member bestMemberSoFar = bestSoFar.member;
    if (bestSoFar.isField || bestSoFar.isSetter || bestSoFar.isGetter) {
      kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
    } else if (bestMemberSoFar is Procedure &&
        bestMemberSoFar.kind == ProcedureKind.Operator) {
      kind = ProcedureKind.Operator;
    }

    if (modifyKernel) {
      debug?.log("Combined Member Signature of ${fullNameForErrors}: new "
          "ForwardingNode($classBuilder, $bestSoFar, $declarations, $kind)");
      Member stub = new ForwardingNode(
              hierarchy, classBuilder, bestSoFar, declarations, kind)
          .finalize();
      if (classBuilder.cls == stub.enclosingClass) {
        classBuilder.cls.addMember(stub);
        SourceLibraryBuilder library = classBuilder.library;
        if (bestSoFar.member is Procedure) {
          library.forwardersOrigins..add(stub)..add(bestSoFar.member);
        }
        debug?.log("Combined Member Signature of ${fullNameForErrors}: "
            "added stub $stub");
        if (classBuilder.isMixinApplication) {
          return combinedMemberSignatureResult = bestSoFar.member;
        } else {
          return combinedMemberSignatureResult = stub;
        }
      }
    }

    debug?.log(
        "Combined Member Signature of ${fullNameForErrors}: picked bestSoFar");
    return combinedMemberSignatureResult = bestSoFar.member;
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new InterfaceConflict(parent, declarations, isSetter, modifyKernel);
  }

  static ClassMember combined(ClassBuilder parent, ClassMember a, ClassMember b,
      bool isSetter, bool createForwarders) {
    List<ClassMember> declarations = <ClassMember>[];
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
      ClassBuilder parent,
      ClassMember abstractMember,
      ClassMember concreteImplementation,
      bool isSetter,
      bool modifyKernel)
      : super(parent, <ClassMember>[concreteImplementation, abstractMember],
            isSetter, modifyKernel);

  ClassMember get concreteImplementation => declarations[0];

  ClassMember get abstractMember => declarations[1];

  Member check(ClassHierarchyBuilder hierarchy) {
    if (!classBuilder.isAbstract &&
        !hierarchy.nodes[classBuilder.cls].hasNoSuchMethod) {
      new DelayedOverrideCheck(
              classBuilder, concreteImplementation, abstractMember)
          .check(hierarchy);
    }

    ProcedureKind kind = ProcedureKind.Method;
    if (abstractMember.isSetter || abstractMember.isGetter) {
      kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
    }
    if (modifyKernel) {
      // This call will add a body to the abstract method if needed for
      // isGenericCovariantImpl checks.
      new ForwardingNode(
              hierarchy, classBuilder, abstractMember, declarations, kind)
          .finalize();
    }
    return abstractMember.member;
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new AbstractMemberOverridingImplementation(parent, abstractMember,
            concreteImplementation, isSetter, modifyKernel);
  }

  static ClassMember selectAbstract(ClassMember declaration) {
    if (declaration is AbstractMemberOverridingImplementation) {
      return declaration.abstractMember;
    } else {
      return declaration;
    }
  }

  static ClassMember selectConcrete(ClassMember declaration) {
    if (declaration is AbstractMemberOverridingImplementation) {
      return declaration.concreteImplementation;
    } else {
      return declaration;
    }
  }
}

void addDeclarationIfDifferent(
    ClassMember declaration, List<ClassMember> declarations) {
  Member target = declaration.member;
  if (target is Procedure) {
    FunctionNode function = target.function;
    for (int i = 0; i < declarations.length; i++) {
      Member other = declarations[i].member;
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

String fullName(ClassMember declaration) {
  String suffix = declaration.isSetter ? "=" : "";
  if (declaration is DelayedMember) {
    return "${declaration.fullNameForErrors}$suffix";
  }
  String className = declaration.classBuilder?.fullNameForErrors;
  return className == null
      ? "${declaration.fullNameForErrors}$suffix"
      : "${className}.${declaration.fullNameForErrors}$suffix";
}

int compareNamedParameters(VariableDeclaration a, VariableDeclaration b) {
  return a.name.compareTo(b.name);
}

bool isAbstract(ClassMember declaration) {
  return declaration.member.isAbstract || declaration is InterfaceConflict;
}

bool inferParameterType(
    ClassBuilder classBuilder,
    ProcedureBuilder memberBuilder,
    FormalParameterBuilder parameterBuilder,
    DartType type,
    bool hadTypesInferred,
    ClassHierarchyBuilder hierarchy) {
  debug?.log("Inferred type ${type} for ${parameterBuilder}");
  if (type == parameterBuilder.variable.type) return true;
  bool result = true;
  if (hadTypesInferred) {
    reportCantInferParameterType(
        classBuilder, memberBuilder, parameterBuilder, hierarchy);
    type = const InvalidType();
    result = false;
  }
  parameterBuilder.variable.type = type;
  memberBuilder.hadTypesInferred = true;
  return result;
}

void reportCantInferParameterType(ClassBuilder cls, MemberBuilder member,
    FormalParameterBuilder parameter, ClassHierarchyBuilder hierarchy) {
  String name = parameter.name;
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      parameter.charOffset,
      name.length,
      wasHandled: true);
}

bool inferReturnType(ClassBuilder cls, ProcedureBuilder procedureBuilder,
    DartType type, bool hadTypesInferred, ClassHierarchyBuilder hierarchy) {
  if (type == procedureBuilder.procedure.function.returnType) return true;
  bool result = true;
  if (hadTypesInferred) {
    reportCantInferReturnType(cls, procedureBuilder, hierarchy);
    type = const InvalidType();
    result = false;
  } else {
    procedureBuilder.hadTypesInferred = true;
  }
  procedureBuilder.procedure.function.returnType = type;
  return result;
}

void reportCantInferReturnType(
    ClassBuilder cls, MemberBuilder member, ClassHierarchyBuilder hierarchy) {
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

void reportCantInferFieldType(ClassBuilder cls, FieldBuilder member) {
  String name = member.fullNameForErrors;
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      member.charOffset,
      name.length,
      wasHandled: true);
}

ClassBuilder getClass(TypeBuilder type) {
  Builder declaration = type.declaration;
  return declaration is ClassBuilder ? declaration : null;
}

bool hasExplicitReturnType(ClassMember declaration) {
  assert(declaration is ProcedureBuilder || declaration is DillMemberBuilder,
      "${declaration.runtimeType}");
  return declaration is ProcedureBuilder
      ? declaration.returnType != null
      : true;
}

bool hasExplicitlyTypedFormalParameter(ClassMember declaration, int index) {
  assert(declaration is ProcedureBuilder || declaration is DillMemberBuilder,
      "${declaration.runtimeType}");
  return declaration is ProcedureBuilder
      ? declaration.formals[index].type != null
      : true;
}
