// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_environment.dart';

import 'package:kernel/src/future_or.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/nnbd_top_merge.dart';
import 'package:kernel/src/norm.dart';

import '../../testing/id_testing_utils.dart' show typeToText;

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/field_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';

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

import 'kernel_builder.dart' show ImplicitFieldType;

import 'types.dart' show Types;

const DebugLogger debug =
    const bool.fromEnvironment("debug.hierarchy") ? const DebugLogger() : null;

class DebugLogger {
  const DebugLogger();
  void log(Object message) => print(message);
}

int compareDeclarations(ClassMember a, ClassMember b) {
  if (a == b) return 0;
  return ClassHierarchy.compareNames(a.name, b.name);
}

bool isNameVisibleIn(Name name, LibraryBuilder libraryBuilder) {
  return !name.isPrivate || name.library == libraryBuilder.library;
}

abstract class ClassMember {
  Name get name;
  bool get isStatic;
  bool get isField;
  bool get isAssignable;
  bool get isSetter;
  bool get isGetter;
  bool get isFinal;
  bool get isConst;

  /// Returns `true` if this member is a regular method or operator.
  bool get isFunction;

  /// Returns `true` if this member is a field, getter or setter.
  bool get isProperty;
  Member getMember(ClassHierarchyBuilder hierarchy);
  bool get isDuplicate;
  String get fullName;
  String get fullNameForErrors;
  ClassBuilder get classBuilder;
  bool isObjectMember(ClassBuilder objectClass);
  Uri get fileUri;
  int get charOffset;
  bool get isAbstract;
  bool get hasExplicitReturnType;
  bool hasExplicitlyTypedFormalParameter(int index);
}

/// Returns true if [a] is a class member conflict with [b].  [a] is assumed to
/// be declared in the class, [b] is assumed to be inherited.
///
/// See the section named "Class Member Conflicts" in [Dart Programming
/// Language Specification](
/// ../../../../../../docs/language/dartLangSpec.tex#classMemberConflicts).
bool isInheritanceConflict(ClassMember a, ClassMember b) {
  if (a.isStatic) return true;
  return a.isProperty != b.isProperty;
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
      types[i] = new TypeParameterType.forAlphaRenaming(
          bTypeParameters[i], aTypeParameters[i]);
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

  final List<DelayedSignatureComputation> delayedSignatureComputations =
      <DelayedSignatureComputation>[];

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

  ClassHierarchyNode getNodeFromClassBuilder(ClassBuilder classBuilder) {
    return nodes[classBuilder.cls] ??=
        new ClassHierarchyNodeBuilder(this, classBuilder).build();
  }

  ClassHierarchyNode getNodeFromTypeBuilder(TypeBuilder type) {
    ClassBuilder cls = getClass(type);
    return cls == null ? null : getNodeFromClassBuilder(cls);
  }

  ClassHierarchyNode getNodeFromClass(Class cls) {
    return nodes[cls] ??
        getNodeFromClassBuilder(loader.computeClassBuilderFromTargetClass(cls));
  }

  InterfaceType asSupertypeOf(InterfaceType subtype, Class supertype) {
    if (subtype.classNode == supertype) {
      return subtype;
    }
    ClassHierarchyNode clsNode = getNodeFromClass(subtype.classNode);
    ClassHierarchyNode supertypeNode = getNodeFromClass(supertype);
    List<DartType> superclasses = clsNode.superclasses;
    int depth = supertypeNode.depth;
    if (depth < superclasses.length) {
      DartType superclass = superclasses[depth];
      if (superclass is InterfaceType && superclass.classNode == supertype) {
        return Substitution.fromInterfaceType(subtype)
            .substituteType(superclass);
      }
    }
    List<DartType> superinterfaces = clsNode.interfaces;
    for (int i = 0; i < superinterfaces.length; i++) {
      DartType superinterface = superinterfaces[i];
      if (superinterface is InterfaceType &&
          superinterface.classNode == supertype) {
        return Substitution.fromInterfaceType(subtype)
            .substituteType(superinterface);
      }
    }
    return null;
  }

  InterfaceType getKernelTypeAsInstanceOf(
      InterfaceType type, Class superclass, Library clientLibrary) {
    Class kernelClass = type.classNode;
    if (kernelClass == superclass) return type;
    if (kernelClass == nullClass) {
      if (superclass.typeParameters.isEmpty) {
        return coreTypes.rawType(superclass, clientLibrary.nullable);
      } else {
        // This is a safe fall-back for dealing with `Null`. It will likely be
        // faster to check for `Null` before calling this method.
        return new InterfaceType(
            superclass,
            clientLibrary.nullable,
            new List<DartType>.filled(
                superclass.typeParameters.length, coreTypes.nullType));
      }
    }
    return asSupertypeOf(type, superclass);
  }

  List<DartType> getKernelTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    Class kernelClass = type.classNode;
    if (kernelClass == superclass) return type.typeArguments;
    if (kernelClass == nullClass) {
      if (superclass.typeParameters.isEmpty) return const <DartType>[];
      return new List<DartType>.filled(
          superclass.typeParameters.length, coreTypes.nullType);
    }
    return asSupertypeOf(type, superclass)?.typeArguments;
  }

  InterfaceType getKernelLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2, Library clientLibrary) {
    if (type1 == type2) return type1;

    // LLUB(Null, List<dynamic>*) works differently for opt-in and opt-out
    // libraries.  In opt-out libraries the legacy behavior is preserved, so
    // LLUB(Null, List<dynamic>*) = List<dynamic>*.  In opt-out libraries the
    // rules imply that LLUB(Null, List<dynamic>*) = List<dynamic>?.
    if (!clientLibrary.isNonNullableByDefault) {
      if (type1 is InterfaceType && type1.classNode == nullClass) {
        return type2;
      }
      if (type2 is InterfaceType && type2.classNode == nullClass) {
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
      if (node == null) continue;
      if (nodes1.contains(node)) {
        DartType candidate1 = getKernelTypeAsInstanceOf(
            type1, node.classBuilder.cls, clientLibrary);
        DartType candidate2 = getKernelTypeAsInstanceOf(
            type2, node.classBuilder.cls, clientLibrary);
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
        return getKernelTypeAsInstanceOf(
                type1, node.classBuilder.cls, clientLibrary)
            .withNullability(
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

  Member getInterfaceMemberKernel(Class cls, Name name, bool isSetter) {
    return getNodeFromClass(cls)
        .getInterfaceMember(name, isSetter)
        ?.getMember(this);
  }

  Member getDispatchTargetKernel(Class cls, Name name, bool isSetter) {
    return getNodeFromClass(cls)
        .getDispatchTarget(name, isSetter)
        ?.getMember(this);
  }

  Member getCombinedMemberSignatureKernel(Class cls, Name name, bool isSetter,
      int charOffset, SourceLibraryBuilder library) {
    ClassMember declaration =
        getNodeFromClass(cls).getInterfaceMember(name, isSetter);
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
      return declaration.getMember(this);
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

    List<DelayedSignatureComputation> signatureComputations =
        hierarchy.delayedSignatureComputations.toList();
    hierarchy.delayedSignatureComputations.clear();
    for (int i = 0; i < signatureComputations.length; i++) {
      signatureComputations[i].computeSignature(hierarchy);
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

  bool get shouldModifyKernel =>
      classBuilder.library.loader == hierarchy.loader;

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
    debug?.log("handleMergeConflict: ${a.fullName} ${b.fullName} ${mergeKind}");
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
    assert(a.isProperty == b.isProperty,
        "Unexpected member combination: $a vs $b");
    result = a;
    switch (mergeKind) {
      case MergeKind.superclassMembers:
      case MergeKind.superclassSetters:
        // [a] is a method declared in [cls]. This means it defines the
        // interface of this class regardless if its abstract.
        debug?.log("superclass: checkValidOverride("
            "${classBuilder.fullNameForErrors}, "
            "${a.fullName}, ${b.fullName})");
        checkValidOverride(
            a, AbstractMemberOverridingImplementation.selectAbstract(b));

        if (a.isAbstract) {
          if (b.isAbstract) {
            recordAbstractMember(a);
          } else {
            if (!classBuilder.isAbstract) {
              // The interface of this class is [a]. But the implementation is
              // [b]. So [b] must implement [a], unless [cls] is abstract.
              checkValidOverride(b, a);
            }
            ClassMember concrete =
                AbstractMemberOverridingImplementation.selectConcrete(b);
            result = new AbstractMemberOverridingImplementation(
                classBuilder,
                a,
                concrete,
                a.isProperty,
                mergeKind.forSetters,
                shouldModifyKernel,
                concrete.isAbstract,
                concrete.name);
            hierarchy.delayedMemberChecks.add(result);
          }
        } else if (classBuilder.isMixinApplication &&
            a.classBuilder != classBuilder) {
          result = InheritedImplementationInterfaceConflict.combined(
              classBuilder, a, b, mergeKind.forSetters, shouldModifyKernel,
              isInheritableConflict: false);
          if (result is DelayedMember) {
            hierarchy.delayedMemberChecks.add(result);
          }
        }

        if (result.name == noSuchMethodName &&
            !result.isObjectMember(objectClass)) {
          hasNoSuchMethod = true;
        }
        break;

      case MergeKind.membersWithSetters:
      case MergeKind.settersWithMembers:
        if (a.classBuilder == classBuilder && b.classBuilder != classBuilder) {
          if (a is SourceFieldMember) {
            if (a.isFinal && b.isSetter) {
              hierarchy.overrideChecks
                  .add(new DelayedOverrideCheck(classBuilder, a, b));
            } else {
              hierarchy.delayedSignatureComputations
                  .add(new DelayedFieldTypeInference(this, a, b));
              // TODO(johnniwinther): Only add override check if field type
              // inference needs it.
              hierarchy.overrideChecks
                  .add(new DelayedOverrideCheck(classBuilder, a, b));
            }
          } else if (a is SourceProcedureMember) {
            hierarchy.delayedSignatureComputations
                .add(new DelayedMethodTypeInference(this, a, b));
            // TODO(johnniwinther): Only add override check if method type
            // inference needs it.
            hierarchy.overrideChecks
                .add(new DelayedOverrideCheck(classBuilder, a, b));
          }
        }
        break;

      case MergeKind.interfacesMembers:
        result = InterfaceConflict.combined(
            classBuilder, a, b, false, shouldModifyKernel);
        break;

      case MergeKind.interfacesSetters:
        result = InterfaceConflict.combined(
            classBuilder, a, b, true, shouldModifyKernel);
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
              "${a.fullName}, ${b.fullName})");
          if (a is! DelayedMember) {
            checkValidOverride(a, b);
          }
          if (a is DelayedMember) {
            if (b is DelayedMember) {
              b.addAllDeclarationsTo(a.declarations);
            } else {
              addDeclarationIfDifferent(b, a.declarations);
            }
          }
        } else {
          if (a.isAbstract) {
            result = InterfaceConflict.combined(
                classBuilder, a, b, mergeKind.forSetters, shouldModifyKernel);
          } else {
            result = InheritedImplementationInterfaceConflict.combined(
                classBuilder, a, b, mergeKind.forSetters, shouldModifyKernel);
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

  bool inferMethodTypes(
      ClassHierarchyBuilder hierarchy, SourceProcedureMember a, ClassMember b) {
    debug
        ?.log("Trying to infer types for ${a.fullName} based on ${b.fullName}");
    if (b is DelayedMember) {
      bool hasSameSignature = true;
      List<ClassMember> declarations = b.declarations;
      for (int i = 0; i < declarations.length; i++) {
        if (!inferMethodTypes(hierarchy, a, declarations[i])) {
          hasSameSignature = false;
        }
      }
      return hasSameSignature;
    }
    if (a.isGetter) {
      return inferGetterType(hierarchy, a, b);
    } else if (a.isSetter) {
      return inferSetterType(hierarchy, a, b);
    }
    bool hadTypesInferred = a.hadTypesInferred;
    ClassBuilder aClassBuilder = a.classBuilder;
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
          "No substitution found for '${classBuilder.fullNameForErrors}' as "
          "instance of '${bClassBuilder.fullNameForErrors}'. Substitutions "
          "available for: ${substitutions.keys}");
      bSubstitution = substitutions[bClassBuilder.cls];
      debug?.log("${classBuilder.fullNameForErrors} -> "
          "${bClassBuilder.fullNameForErrors} $bSubstitution");
    }
    Procedure aProcedure = a.getMember(hierarchy);
    Member bMember = b.getMember(hierarchy);
    if (bMember is! Procedure) {
      debug?.log("Giving up 1");
      return false;
    }
    Procedure bProcedure = bMember;
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
            a.classBuilder, aTypeParameters[i], bTypeParameters[i]);
      }
      List<DartType> types = new List<DartType>(typeParameterCount);
      for (int i = 0; i < typeParameterCount; i++) {
        types[i] = new TypeParameterType.forAlphaRenaming(
            bTypeParameters[i], aTypeParameters[i]);
      }
      substitution = Substitution.fromPairs(bTypeParameters, types);
      for (int i = 0; i < typeParameterCount; i++) {
        DartType aBound = aTypeParameters[i].bound;
        DartType bBound = substitution.substituteType(bTypeParameters[i].bound);
        if (!hierarchy.types
            .isSameTypeKernel(aBound, bBound)
            .isSubtypeWhenUsingNullabilities()) {
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
      if (a.classBuilder == classBuilder && a.returnType == null) {
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
      copyParameterCovariance(a.classBuilder, aParameter, bParameter);
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
      if (hierarchy
              .coreTypes.objectClass.enclosingLibrary.isNonNullableByDefault &&
          !a.classBuilder.library.isNonNullableByDefault &&
          bProcedure == hierarchy.coreTypes.objectEquals) {
        // In legacy code we special case `Object.==` to infer `dynamic` instead
        // `Object!`.
        bType = const DynamicType();
      }
      if (aType != bType) {
        if (a.classBuilder == classBuilder && a.formals[i].type == null) {
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
        copyParameterCovariance(a.classBuilder, aParameter, bParameter);
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
          if (a.classBuilder == classBuilder && parameter.type == null) {
            result = inferParameterType(
                classBuilder, a, parameter, bType, hadTypesInferred, hierarchy);
          } else {
            debug?.log("Giving up 12");
            result = false;
          }
        }
      }
    }
    debug?.log("Inferring types for ${a.fullName} based on ${b.fullName} " +
        (result ? "succeeded." : "failed."));
    return result;
  }

  bool inferGetterType(
      ClassHierarchyBuilder hierarchy, SourceProcedureMember a, ClassMember b) {
    debug?.log(
        "Inferring getter types for ${a.fullName} based on ${b.fullName}");
    Member bTarget = b.getMember(hierarchy);
    DartType bType;
    if (bTarget is Field) {
      bType = bTarget.type;
    } else if (bTarget is Procedure) {
      if (b.isSetter) {
        VariableDeclaration bParameter =
            bTarget.function.positionalParameters.single;
        bType = bParameter.type;
        if (!b.hasExplicitlyTypedFormalParameter(0)) {
          debug?.log("Giving up (type may be inferred)");
          return false;
        }
      } else if (b.isGetter) {
        bType = bTarget.function.returnType;
        if (!b.hasExplicitReturnType) {
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
    Procedure procedure = a.getMember(hierarchy);
    return procedure.function.returnType == bType;
  }

  bool inferSetterType(
      ClassHierarchyBuilder hierarchy, SourceProcedureMember a, ClassMember b) {
    debug?.log(
        "Inferring setter types for ${a.fullName} based on ${b.fullName}");
    Member bTarget = b.getMember(hierarchy);
    Procedure aProcedure = a.getMember(hierarchy);
    VariableDeclaration aParameter =
        aProcedure.function.positionalParameters.single;
    DartType bType;
    if (bTarget is Field) {
      bType = bTarget.type;
      copyParameterCovarianceFromField(a.classBuilder, aParameter, bTarget);
    }
    if (bTarget is Procedure) {
      if (b.isSetter) {
        VariableDeclaration bParameter =
            bTarget.function.positionalParameters.single;
        bType = bParameter.type;
        copyParameterCovariance(a.classBuilder, aParameter, bParameter);
        if (!b.hasExplicitlyTypedFormalParameter(0) ||
            !a.hasExplicitlyTypedFormalParameter(0)) {
          debug?.log("Giving up (type may be inferred)");
          return false;
        }
      } else if (b.isGetter) {
        bType = bTarget.function.returnType;
        if (!b.hasExplicitReturnType) {
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
        "checkValidOverride(${a.fullName}, ${b.fullName}) ${a.runtimeType}");
    if (a is SourceProcedureMember) {
      // TODO(johnniwinther): Only add override check if method type
      // inference needs it.
      hierarchy.delayedSignatureComputations
          .add(new DelayedMethodTypeInference(this, a, b));
    } else if (a.isField) {
      // TODO(johnniwinther): Only add override check if field type
      // inference needs it.
      hierarchy.delayedSignatureComputations
          .add(new DelayedFieldTypeInference(this, a, b));
    }
    // TODO(johnniwinther): Only add override check if needed.

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

  /// Infers the field type of [a] based on [b]. Returns `true` if the type of
  /// [a] is known to be a valid override of [b], meaning that no additional
  /// override checks are needed.
  bool inferFieldTypes(
      ClassHierarchyBuilder hierarchy, ClassMember a, ClassMember b) {
    debug?.log("Trying to infer field types for ${a.fullName} "
        "based on ${b.fullName}");
    if (b is DelayedMember) {
      bool hasSameSignature = true;
      List<ClassMember> declarations = b.declarations;
      for (int i = 0; i < declarations.length; i++) {
        if (!inferFieldTypes(hierarchy, a, declarations[i])) {
          hasSameSignature = false;
        }
      }
      return hasSameSignature;
    }
    Member bTarget = b.getMember(hierarchy);
    DartType inheritedType;
    if (bTarget is Procedure) {
      if (bTarget.isSetter) {
        VariableDeclaration parameter =
            bTarget.function.positionalParameters.single;
        // inheritedType = parameter.type;
        copyFieldCovarianceFromParameter(
            a.classBuilder, a.getMember(hierarchy), parameter);
        if (!b.hasExplicitlyTypedFormalParameter(0)) {
          debug?.log("Giving up (type may be inferred)");
          return false;
        }
      } else if (bTarget.isGetter) {
        if (!b.hasExplicitReturnType) return false;
        inheritedType = bTarget.function.returnType;
      }
    } else if (bTarget is Field) {
      copyFieldCovariance(a.classBuilder, a.getMember(hierarchy), bTarget);
      inheritedType = bTarget.type;
    }
    if (inheritedType == null) {
      debug?.log("Giving up (inheritedType == null)\n${StackTrace.current}");
      return false;
    }
    ClassBuilder aClassBuilder = a.classBuilder;
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
    if (inheritedType is! ImplicitFieldType) {
      if (bSubstitution != null) {
        inheritedType = bSubstitution.substituteType(inheritedType);
      }
      if (!a.classBuilder.library.isNonNullableByDefault) {
        inheritedType = legacyErasure(hierarchy.coreTypes, inheritedType);
      }
    }

    Field aField = a.getMember(hierarchy);
    DartType declaredType = aField.type;
    if (aSubstitution != null) {
      declaredType = aSubstitution.substituteType(declaredType);
    }
    if (declaredType == inheritedType) return true;

    bool isValidOverride = false;
    if (a is SourceFieldMember) {
      if (a.classBuilder == classBuilder && a.type == null) {
        DartType declaredType = a.fieldType;
        if (declaredType is ImplicitFieldType) {
          if (inheritedType is ImplicitFieldType) {
            declaredType.addOverride(inheritedType);
          } else {
            // The concrete type has already been inferred.
            a.hadTypesInferred = true;
            a.fieldType = inheritedType;
            isValidOverride = true;
          }
        } else if (a.hadTypesInferred) {
          if (inheritedType is! ImplicitFieldType) {
            // A different type has already been inferred.
            reportCantInferFieldType(classBuilder, a);
            a.fieldType = const InvalidType();
          }
        } else {
          isValidOverride = true;
          a.hadTypesInferred = true;
          a.fieldType = inheritedType;
        }
      }
    }
    return isValidOverride;
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
  ClassMember handleOnlyA(ClassMember member, MergeKind mergeKind) {
    if (mergeKind.betweenInterfaces) {
      return member;
    }
    // TODO(ahe): Enable this optimization:
    // if (cls is DillClassBuilder) return;
    // assert(mergeKind.betweenInterfaces ||
    //    member is! InterfaceConflict);
    if ((mergeKind.fromSuperclass) && member.isAbstract) {
      recordAbstractMember(member);
    }
    return member;
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
    if (mergeKind.betweenInterfaces) {
      return member;
    }
    // TODO(ahe): Enable this optimization:
    // if (cls is DillClassBuilder) return member;
    if (mergeKind.fromInterfaces ||
        (mergeKind.fromSuperclass && member.isAbstract)) {
      if (isNameVisibleIn(member.name, classBuilder.library)) {
        recordAbstractMember(member);
      }
    }
    if (mergeKind.fromSuperclass &&
        member.name == noSuchMethodName &&
        !member.isObjectMember(objectClass)) {
      hasNoSuchMethod = true;
    }
    if (!mergeKind.forMembersVsSetters &&
        member is DelayedMember &&
        member.isInheritableConflict) {
      DelayedMember delayedMember = member;
      member = delayedMember.withParent(classBuilder);
      hierarchy.delayedMemberChecks.add(member);
    }
    if (mergeKind.intoCurrentClass) {
      if (member.classBuilder.library.isNonNullableByDefault &&
          !classBuilder.library.isNonNullableByDefault) {
        if (member is! DelayedMember) {
          member = new InterfaceConflict(
              classBuilder,
              [member],
              member.isProperty,
              mergeKind.forSetters,
              shouldModifyKernel,
              member.isAbstract,
              member.name,
              isImplicitlyAbstract: member.isAbstract);
          hierarchy.delayedMemberChecks.add(member);
        }
      }
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
      supernode = hierarchy.getNodeFromTypeBuilder(classBuilder.supertype);
      if (supernode == null) {
        supernode = hierarchy.getNodeFromClassBuilder(objectClass);
      }
      assert(supernode != null);
    }

    Scope scope = classBuilder.scope;
    if (classBuilder.isMixinApplication) {
      TypeDeclarationBuilder mixin = classBuilder.mixedInType.declaration;
      inferMixinApplication();
      // recordSupertype(cls.mixedInType);
      while (mixin.isNamedMixinApplication) {
        ClassBuilder named = mixin;
        // recordSupertype(named.mixedInType);
        mixin = named.mixedInType.declaration;
      }
      if (mixin is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = mixin;
        mixin = aliasBuilder.unaliasDeclaration;
      }
      if (mixin is ClassBuilder) {
        scope = mixin.scope.computeMixinScope();
      }
    }

    /// Members (excluding setters) declared in [cls].
    List<ClassMember> localMembers = <ClassMember>[];

    /// Setters declared in [cls].
    List<ClassMember> localSetters = <ClassMember>[];

    for (MemberBuilder memberBuilder in scope.localMembers) {
      localMembers.addAll(memberBuilder.localMembers);
      localSetters.addAll(memberBuilder.localSetters);
    }

    for (MemberBuilder memberBuilder in scope.localSetters) {
      localMembers.addAll(memberBuilder.localMembers);
      localSetters.addAll(memberBuilder.localSetters);
    }

    localMembers.sort(compareDeclarations);
    localSetters.sort(compareDeclarations);

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

    List<DartType> superclasses;

    List<DartType> interfaces;

    int maxInheritancePath;

    if (supernode == null) {
      // This should be Object.
      classMembers = localMembers;
      classSetters = localSetters;
      superclasses = new List<DartType>(0);
      interfaces = new List<DartType>(0);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;

      superclasses = new List<DartType>(supernode.superclasses.length + 1);
      DartType supertype = classBuilder.supertype.build(classBuilder.library);
      if (supertype is! InterfaceType) {
        // If the superclass is not an interface type we use Object instead.
        // A similar normalization is performed on [supernode] above.
        supertype = hierarchy.coreTypes.objectNonNullableRawType;
      }
      superclasses.setRange(0, superclasses.length - 1,
          substSupertypes(supertype, supernode.superclasses));
      superclasses[superclasses.length - 1] = recordSupertype(supertype);

      List<TypeBuilder> directInterfaceBuilders =
          ignoreFunction(classBuilder.interfaces);
      if (classBuilder.isMixinApplication) {
        if (directInterfaceBuilders == null) {
          directInterfaceBuilders = <TypeBuilder>[classBuilder.mixedInType];
        } else {
          directInterfaceBuilders = <TypeBuilder>[classBuilder.mixedInType]
            ..addAll(directInterfaceBuilders);
        }
      }
      if (directInterfaceBuilders != null) {
        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          recordSupertype(
              directInterfaceBuilders[i].build(classBuilder.library));
        }
      }
      List<DartType> superclassInterfaces = supernode.interfaces;
      if (superclassInterfaces != null) {
        superclassInterfaces = substSupertypes(supertype, superclassInterfaces);
      }

      classMembers = merge(
          localMembers, supernode.classMembers, MergeKind.superclassMembers);
      classSetters = merge(
          localSetters, supernode.classSetters, MergeKind.superclassSetters);

      if (directInterfaceBuilders != null) {
        MergeResult result =
            mergeInterfaces(supernode, directInterfaceBuilders);
        interfaceMembers = result.mergedMembers;
        interfaceSetters = result.mergedSetters;
        interfaces = <DartType>[];
        if (superclassInterfaces != null) {
          for (int i = 0; i < superclassInterfaces.length; i++) {
            addInterface(interfaces, superclasses, superclassInterfaces[i]);
          }
        }

        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          DartType directInterface =
              directInterfaceBuilders[i].build(classBuilder.library);
          addInterface(interfaces, superclasses, directInterface);
          if (directInterface is InterfaceType) {
            ClassHierarchyNode interfaceNode =
                hierarchy.getNodeFromClass(directInterface.classNode);
            if (interfaceNode != null) {
              if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
                maxInheritancePath = interfaceNode.maxInheritancePath + 1;
              }

              List<DartType> types =
                  substSupertypes(directInterface, interfaceNode.superclasses);
              for (int i = 0; i < types.length; i++) {
                addInterface(interfaces, superclasses, types[i]);
              }
              if (interfaceNode.interfaces != null) {
                List<DartType> types =
                    substSupertypes(directInterface, interfaceNode.interfaces);
                for (int i = 0; i < types.length; i++) {
                  addInterface(interfaces, superclasses, types[i]);
                }
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

  DartType recordSupertype(DartType supertype) {
    debug?.log("In ${this.classBuilder.fullNameForErrors} "
        "recordSupertype(${supertype})");
    if (supertype is InterfaceType) {
      Class cls = supertype.classNode;
      if (cls.isMixinApplication) {
        recordSupertype(cls.mixedInType.asInterfaceType);
      }
      List<TypeParameter> typeVariableBuilders = cls.typeParameters;
      if (typeVariableBuilders == null) {
        substitutions[cls] = Substitution.empty;
        assert(cls.typeParameters.isEmpty);
      } else {
        List<DartType> arguments = supertype.typeArguments;
        List<DartType> typeArguments = new List<DartType>(arguments.length);
        List<TypeParameter> typeParameters =
            new List<TypeParameter>(arguments.length);
        for (int i = 0; i < arguments.length; i++) {
          typeParameters[i] = typeVariableBuilders[i];
          typeArguments[i] = arguments[i];
        }
        substitutions[cls] =
            Substitution.fromPairs(typeParameters, typeArguments);
      }
    }
    return supertype;
  }

  List<DartType> substSupertypes(
      DartType supertype, List<DartType> supertypes) {
    if (supertype is! InterfaceType) return supertypes;
    InterfaceType cls = supertype;
    List<TypeParameter> typeVariables = cls.classNode.typeParameters;
    if (typeVariables.isEmpty) {
      debug?.log("In ${this.classBuilder.fullNameForErrors} "
          "$supertypes aren't substed");
      for (int i = 0; i < supertypes.length; i++) {
        recordSupertype(supertypes[i]);
      }
      return supertypes;
    }
    Map<TypeParameter, DartType> map = <TypeParameter, DartType>{};
    List<DartType> arguments = cls.typeArguments;
    for (int i = 0; i < typeVariables.length; i++) {
      map[typeVariables[i]] = arguments[i];
    }
    Substitution substitution = Substitution.fromMap(map);
    List<DartType> result;
    for (int i = 0; i < supertypes.length; i++) {
      DartType supertype = supertypes[i];
      DartType substituted =
          recordSupertype(substitution.substituteType(supertype));
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

  List<TypeBuilder> computeDefaultTypeArguments(TypeBuilder type) {
    TypeDeclarationBuilder cls = type.declaration;
    if (cls is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = cls;
      cls = aliasBuilder.unaliasDeclaration;
    }
    if (cls is ClassBuilder) {
      List<TypeBuilder> result =
          new List<TypeBuilder>(cls.typeVariables.length);
      for (int i = 0; i < result.length; ++i) {
        TypeVariableBuilder tv = cls.typeVariables[i];
        result[i] = tv.defaultType ??
            cls.library.loader.computeTypeBuilder(tv.parameter.defaultType);
      }
      return result;
    } else {
      return unhandled("${cls.runtimeType}", "$cls", classBuilder.charOffset,
          classBuilder.fileUri);
    }
  }

  DartType addInterface(
      List<DartType> interfaces, List<DartType> superclasses, DartType type) {
    if (!classBuilder.library.isNonNullableByDefault) {
      type = legacyErasure(hierarchy.coreTypes, type);
    }
    if (type is InterfaceType) {
      ClassHierarchyNode node = hierarchy.getNodeFromClass(type.classNode);
      if (node == null) return null;
      int depth = node.depth;
      int myDepth = superclasses.length;
      DartType superclass = depth < myDepth ? superclasses[depth] : null;
      if (superclass is InterfaceType &&
          superclass.classNode == type.classNode) {
        // This is a potential conflict.
        if (classBuilder.library.isNonNullableByDefault) {
          superclass = nnbdTopMerge(
              hierarchy.coreTypes,
              norm(hierarchy.coreTypes, superclass),
              norm(hierarchy.coreTypes, type));
          if (superclass == null) {
            // This is a conflict.
            // TODO(johnniwinther): Report errors here instead of through
            // the computation of the [ClassHierarchy].
            superclass = superclasses[depth];
          } else {
            superclasses[depth] = superclass;
          }
        }
        return superclass;
      } else {
        for (int i = 0; i < interfaces.length; i++) {
          // This is a quadratic algorithm, but normally, the number of
          // interfaces is really small.
          DartType interface = interfaces[i];
          if (interface is InterfaceType &&
              interface.classNode == type.classNode) {
            // This is a potential conflict.
            if (classBuilder.library.isNonNullableByDefault) {
              interface = nnbdTopMerge(
                  hierarchy.coreTypes,
                  norm(hierarchy.coreTypes, interface),
                  norm(hierarchy.coreTypes, type));
              if (interface == null) {
                // This is a conflict.
                // TODO(johnniwinther): Report errors here instead of through
                // the computation of the [ClassHierarchy].
                interface = interfaces[i];
              } else {
                interfaces[i] = interface;
              }
            }
            return interface;
          }
        }
      }
      interfaces.add(type);
    }
    return null;
  }

  MergeResult mergeInterfaces(
      ClassHierarchyNode supernode, List<TypeBuilder> interfaceBuilders) {
    debug?.log("mergeInterfaces($classBuilder (${this.classBuilder}) "
        "${supernode.interfaces} ${interfaceBuilders}");
    List<List<ClassMember>> memberLists =
        new List<List<ClassMember>>(interfaceBuilders.length + 1);
    List<List<ClassMember>> setterLists =
        new List<List<ClassMember>>(interfaceBuilders.length + 1);
    memberLists[0] = supernode.interfaceMembers;
    setterLists[0] = supernode.interfaceSetters;
    for (int i = 0; i < interfaceBuilders.length; i++) {
      ClassHierarchyNode interfaceNode =
          hierarchy.getNodeFromTypeBuilder(interfaceBuilders[i]);
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
        if (member.isAssignable) {
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
      if (member.isAssignable) {
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
      if (isNameVisibleIn(declaration.name, classBuilder.library)) {
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
    bool changed = false;
    final List<ClassMember> result = new List<ClassMember>.filled(
        aList.length + bList.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0;
    int j = 0;
    while (i < aList.length && j < bList.length) {
      final ClassMember a = aList[i];
      final ClassMember b = bList[j];
      if (mergeKind.betweenInterfaces && a.isStatic) {
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
        changed = true;
        i++;
        j++;
      } else if (compare < 0) {
        ClassMember member = handleOnlyA(a, mergeKind);
        result[storeIndex++] = member;
        if (!identical(member, a)) {
          changed = true;
        }
        i++;
      } else {
        ClassMember member = handleOnlyB(b, mergeKind);
        result[storeIndex++] = member;
        if (!identical(member, b)) {
          changed = true;
        }
        j++;
      }
    }
    while (i < aList.length) {
      final ClassMember a = aList[i];
      if (!mergeKind.betweenInterfaces || !a.isStatic) {
        ClassMember member = handleOnlyA(a, mergeKind);
        result[storeIndex++] = member;
        if (!identical(member, a)) {
          changed = true;
        }
      }
      i++;
    }
    while (j < bList.length) {
      final ClassMember b = bList[j];
      if (!b.isStatic) {
        ClassMember member = handleOnlyB(b, mergeKind);
        result[storeIndex++] = member;
        if (!identical(member, b)) {
          changed = true;
        }
      }
      j++;
    }
    if (!changed && aList.isEmpty && storeIndex == bList.length) {
      assert(
          _equalsList(result, bList, storeIndex),
          "List mismatch: Expected: ${bList}, "
          "actual ${result.sublist(0, storeIndex)}");
      return bList;
    }
    if (!changed && bList.isEmpty && storeIndex == aList.length) {
      assert(
          _equalsList(result, aList, storeIndex),
          "List mismatch: Expected: ${aList}, "
          "actual ${result.sublist(0, storeIndex)}");
      return aList;
    }
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
            new TypeBuilderConstraintGatherer(hierarchy,
                mixedInType.classNode.typeParameters, cls.enclosingLibrary))
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
  final List<DartType> superclasses;

  /// The list of all classes implemented by [classBuilder] and its supertypes
  /// excluding any classes from [superclasses].
  final List<DartType> interfaces;

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
      DartType type = superclasses[i];
      if (type is InterfaceType) {
        result[i] = hierarchy.getNodeFromClass(type.classNode);
      }
    }
    for (int i = 0; i < interfaces.length; i++) {
      DartType type = interfaces[i];
      if (type is InterfaceType) {
        result[i + superclasses.length] =
            hierarchy.getNodeFromClass(type.classNode);
      }
    }
    return result..last = this;
  }

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
    for (DartType superclass in superclasses) {
      sb.write("  " * (depth + 2));
      if (depth != 0) sb.write("-> ");
      sb.write(typeToText(superclass));
      sb.writeln();
      depth++;
    }
    if (interfaces != null) {
      sb.write("  interfaces:");
      bool first = true;
      for (DartType i in interfaces) {
        if (!first) sb.write(",");
        sb.write(" ");
        sb.write(typeToText(i));
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
      int comparison = ClassHierarchy.compareNames(name, pivot.name);
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

class MergeKind {
  final String name;

  final bool forSetters;

  final bool betweenInterfaces;

  final bool fromSuperclass;

  final bool fromInterfaces;

  final bool forMembersVsSetters;

  final bool intoCurrentClass;

  const MergeKind(this.name,
      {this.forSetters: false,
      this.betweenInterfaces: false,
      this.fromSuperclass: false,
      this.fromInterfaces: false,
      this.forMembersVsSetters: false,
      this.intoCurrentClass: false});

  String toString() => 'MergeKind($name)';

  /// Merging superclass members with the current class.
  static const MergeKind superclassMembers = const MergeKind(
      'Merging superclass members with the current class.',
      fromSuperclass: true,
      intoCurrentClass: true);

  /// Merging superclass setters with the current class.
  static const MergeKind superclassSetters = const MergeKind(
      'Merging superclass setters with the current class.',
      fromSuperclass: true,
      intoCurrentClass: true,
      forSetters: true);

  /// Merging members of two interfaces.
  static const MergeKind interfacesMembers = const MergeKind(
      'Merging members of two interfaces.',
      betweenInterfaces: true);

  /// Merging setters of two interfaces.
  static const MergeKind interfacesSetters = const MergeKind(
      'Merging setters of two interfaces.',
      betweenInterfaces: true,
      forSetters: true);

  /// Merging class members with interface members.
  static const MergeKind supertypesMembers = const MergeKind(
      'Merging class members with interface members.',
      fromInterfaces: true,
      intoCurrentClass: true);

  /// Merging class setters with interface setters.
  static const MergeKind supertypesSetters = const MergeKind(
      'Merging class setters with interface setters.',
      fromInterfaces: true,
      intoCurrentClass: true,
      forSetters: true);

  /// Merging members with inherited setters.
  static const MergeKind membersWithSetters = const MergeKind(
      'Merging members with inherited setters.',
      forMembersVsSetters: true);

  /// Merging setters with inherited members.
  static const MergeKind settersWithMembers = const MergeKind(
      'Merging setters with inherited members.',
      forMembersVsSetters: true);
}

List<LocatedMessage> inheritedConflictContext(ClassMember a, ClassMember b) {
  int length = a.fullNameForErrors.length;
  // TODO(ahe): Delete this method when it isn't used by [InterfaceResolver].
  int compare = "${a.fileUri}".compareTo("${b.fileUri}");
  if (compare == 0) {
    compare = a.charOffset.compareTo(b.charOffset);
  }
  ClassMember first;
  ClassMember second;
  if (compare < 0) {
    first = a;
    second = b;
  } else {
    first = b;
    second = a;
  }
  return <LocatedMessage>[
    messageInheritedMembersConflictCause1.withLocation(
        first.fileUri, first.charOffset, length),
    messageInheritedMembersConflictCause2.withLocation(
        second.fileUri, second.charOffset, length),
  ];
}

class BuilderMixinInferrer extends MixinInferrer {
  final ClassBuilder cls;

  BuilderMixinInferrer(
      this.cls, CoreTypes coreTypes, TypeBuilderConstraintGatherer gatherer)
      : super(coreTypes, gatherer);

  Supertype asInstantiationOf(Supertype type, Class superclass) {
    List<DartType> arguments =
        gatherer.getTypeArgumentsAsInstanceOf(type.asInterfaceType, superclass);
    if (arguments == null) return null;
    return new Supertype(superclass, arguments);
  }

  void reportProblem(Message message, Class kernelClass) {
    int length = cls.isMixinApplication ? 1 : cls.fullNameForErrors.length;
    cls.addProblem(message, cls.charOffset, length);
  }
}

class TypeBuilderConstraintGatherer extends TypeConstraintGatherer
    with StandardBounds {
  final ClassHierarchyBuilder hierarchy;

  TypeBuilderConstraintGatherer(this.hierarchy,
      Iterable<TypeParameter> typeParameters, Library currentLibrary)
      : super.subclassing(typeParameters, currentLibrary);

  @override
  CoreTypes get coreTypes => hierarchy.coreTypes;

  @override
  Class get objectClass => hierarchy.objectClass;

  @override
  Class get functionClass => hierarchy.functionClass;

  @override
  Class get futureOrClass => hierarchy.futureOrClass;

  @override
  Class get nullClass => hierarchy.nullClass;

  @override
  void addLowerBound(
      TypeConstraint constraint, DartType lower, Library clientLibrary) {
    constraint.lower =
        getStandardUpperBound(constraint.lower, lower, clientLibrary);
  }

  @override
  void addUpperBound(
      TypeConstraint constraint, DartType upper, Library clientLibrary) {
    constraint.upper =
        getStandardLowerBound(constraint.upper, upper, clientLibrary);
  }

  @override
  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    return null;
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes) {
    return hierarchy.getKernelTypeAsInstanceOf(type, superclass, clientLibrary);
  }

  @override
  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    return hierarchy.getKernelTypeArgumentsAsInstanceOf(type, superclass);
  }

  @override
  InterfaceType futureType(DartType type, Nullability nullability) {
    return new InterfaceType(
        hierarchy.futureClass, nullability, <DartType>[type]);
  }

  @override
  bool isSubtypeOf(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    return hierarchy.types.isSubtypeOfKernel(subtype, supertype, mode);
  }

  @override
  bool areMutualSubtypes(DartType s, DartType t, SubtypeCheckMode mode) {
    return isSubtypeOf(s, t, mode) && isSubtypeOf(t, s, mode);
  }

  @override
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2, Library clientLibrary) {
    return hierarchy.getKernelLegacyLeastUpperBound(
        type1, type2, clientLibrary);
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
    debug?.log("Delayed override check of ${a.fullName} "
        "${b.fullName} wrt. ${classBuilder.fullNameForErrors}");
    Member bMember = b.getMember(hierarchy);
    if (classBuilder == a.classBuilder) {
      if (a is SourceProcedureMember) {
        if (a.isGetter && !a.hasExplicitReturnType) {
          DartType type;
          if (b.isGetter) {
            Procedure bTarget = bMember;
            type = bTarget.function.returnType;
          } else if (b.isSetter) {
            Procedure bTarget = bMember;
            type = bTarget.function.positionalParameters.single.type;
          } else if (b.isField) {
            Field bTarget = bMember;
            type = bTarget.type;
          }
          if (type != null) {
            type = Substitution.fromInterfaceType(
                    hierarchy.getKernelTypeAsInstanceOf(
                        hierarchy.coreTypes.thisInterfaceType(
                            classBuilder.cls, classBuilder.library.nonNullable),
                        bMember.enclosingClass,
                        classBuilder.library.library))
                .substituteType(type);
            if (!a.hadTypesInferred || !b.isSetter) {
              inferReturnType(
                  classBuilder, a, type, a.hadTypesInferred, hierarchy);
            }
          }
        } else if (a.isSetter && !a.hasExplicitlyTypedFormalParameter(0)) {
          DartType type;
          if (b.isGetter) {
            Procedure bTarget = bMember;
            type = bTarget.function.returnType;
          } else if (b.isSetter) {
            Procedure bTarget = bMember;
            type = bTarget.function.positionalParameters.single.type;
          } else if (b.isField) {
            Field bTarget = bMember;
            type = bTarget.type;
          }
          if (type != null) {
            type = Substitution.fromInterfaceType(
                    hierarchy.getKernelTypeAsInstanceOf(
                        hierarchy.coreTypes.thisInterfaceType(
                            classBuilder.cls, classBuilder.library.nonNullable),
                        bMember.enclosingClass,
                        classBuilder.library.library))
                .substituteType(type);
            if (!a.hadTypesInferred || !b.isGetter) {
              inferParameterType(classBuilder, a, a.formals.single, type,
                  a.hadTypesInferred, hierarchy);
            }
          }
        }
        a.hadTypesInferred = true;
      } else if (a is SourceFieldMember && a.type == null) {
        DartType type;
        if (b.isGetter) {
          Procedure bTarget = bMember;
          type = bTarget.function.returnType;
        } else if (b.isSetter) {
          Procedure bTarget = bMember;
          type = bTarget.function.positionalParameters.single.type;
        } else if (b.isField) {
          Field bTarget = bMember;
          type = bTarget.type;
        }
        if (type != null) {
          type = Substitution.fromInterfaceType(
                  hierarchy.getKernelTypeAsInstanceOf(
                      hierarchy.coreTypes.thisInterfaceType(
                          classBuilder.cls, classBuilder.library.nonNullable),
                      bMember.enclosingClass,
                      classBuilder.library.library))
              .substituteType(type);
          if (!a.classBuilder.library.isNonNullableByDefault) {
            type = legacyErasure(hierarchy.coreTypes, type);
          }
          if (type != a.fieldType) {
            if (a.hadTypesInferred) {
              if (b.isSetter &&
                  (!a.isAssignable ||
                      hierarchy.types.isSubtypeOfKernel(type, a.fieldType,
                          SubtypeCheckMode.ignoringNullabilities))) {
                type = a.fieldType;
              } else {
                reportCantInferFieldType(classBuilder, a);
                type = const InvalidType();
              }
            }
            debug?.log("Inferred type ${type} for ${a.fullName}");
            a.fieldType = type;
          }
        }
        a.hadTypesInferred = true;
      }
    }

    callback(a.getMember(hierarchy), bMember, a.isSetter);
  }
}

abstract class DelayedSignatureComputation {
  void computeSignature(ClassHierarchyBuilder hierarchy);
}

class DelayedMethodTypeInference implements DelayedSignatureComputation {
  final ClassHierarchyNodeBuilder builder;
  final SourceProcedureMember a;
  final ClassMember b;

  DelayedMethodTypeInference(this.builder, this.a, this.b);

  void computeSignature(ClassHierarchyBuilder hierarchy) {
    builder.inferMethodTypes(hierarchy, a, b);
  }
}

class DelayedFieldTypeInference implements DelayedSignatureComputation {
  final ClassHierarchyNodeBuilder builder;
  final ClassMember a;
  final ClassMember b;

  DelayedFieldTypeInference(this.builder, this.a, this.b);

  void computeSignature(ClassHierarchyBuilder hierarchy) {
    builder.inferFieldTypes(hierarchy, a, b);
  }
}

abstract class DelayedMember implements ClassMember {
  /// The class which has inherited [declarations].
  @override
  final ClassBuilder classBuilder;

  /// Conflicting declarations.
  final List<ClassMember> declarations;

  final bool isProperty;

  final bool isSetter;

  final bool modifyKernel;

  final bool isExplicitlyAbstract;

  @override
  final Name name;

  DelayedMember(this.classBuilder, this.declarations, this.isProperty,
      this.isSetter, this.modifyKernel, this.isExplicitlyAbstract, this.name);

  @override
  bool get isFunction => !isProperty;

  @override
  bool get isAbstract => isExplicitlyAbstract;

  bool get isStatic => false;
  bool get isField => false;
  bool get isGetter => false;
  bool get isFinal => false;
  bool get isConst => false;
  bool get isAssignable => false;
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
  String get fullNameForErrors =>
      declarations.map((ClassMember m) => m.fullName).join("%");

  bool get isInheritableConflict => true;

  String get fullName {
    String suffix = isSetter ? "=" : "";
    return "${fullNameForErrors}$suffix";
  }

  @override
  bool get hasExplicitReturnType {
    throw new UnsupportedError("${runtimeType}.hasExplicitReturnType");
  }

  @override
  bool hasExplicitlyTypedFormalParameter(int index) {
    throw new UnsupportedError(
        "${runtimeType}.hasExplicitlyTypedFormalParameter");
  }
}

/// This represents a concrete implementation inherited from a superclass that
/// has conflicts with methods inherited from an interface. The concrete
/// implementation is the first element of [declarations].
class InheritedImplementationInterfaceConflict extends DelayedMember {
  Member combinedMemberSignatureResult;

  @override
  final bool isInheritableConflict;

  InheritedImplementationInterfaceConflict(
      ClassBuilder parent,
      List<ClassMember> declarations,
      bool isProperty,
      bool isSetter,
      bool modifyKernel,
      bool isAbstract,
      Name name,
      {this.isInheritableConflict = true})
      : super(parent, declarations, isProperty, isSetter, modifyKernel,
            isAbstract, name);

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return declarations.first.isObjectMember(objectClass);
  }

  @override
  String toString() {
    return "InheritedImplementationInterfaceConflict("
        "${classBuilder.fullNameForErrors}, "
        "[${declarations.join(', ')}])";
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) => check(hierarchy);

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
    return combinedMemberSignatureResult = new InterfaceConflict(classBuilder,
            declarations, isProperty, isSetter, modifyKernel, isAbstract, name)
        .check(hierarchy);
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new InheritedImplementationInterfaceConflict(
            parent,
            declarations.toList(),
            isProperty,
            isSetter,
            modifyKernel,
            isAbstract,
            name);
  }

  static ClassMember combined(
      ClassBuilder parent,
      ClassMember concreteImplementation,
      ClassMember other,
      bool isSetter,
      bool createForwarders,
      {bool isInheritableConflict = true}) {
    assert(concreteImplementation.isProperty == other.isProperty,
        "Unexpected member combination: $concreteImplementation vs $other");
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
          parent,
          declarations,
          concreteImplementation.isProperty,
          isSetter,
          createForwarders,
          declarations.first.isAbstract,
          declarations.first.name,
          isInheritableConflict: isInheritableConflict);
    }
  }
}

class InterfaceConflict extends DelayedMember {
  final bool isImplicitlyAbstract;

  InterfaceConflict(
      ClassBuilder parent,
      List<ClassMember> declarations,
      bool isProperty,
      bool isSetter,
      bool modifyKernel,
      bool isAbstract,
      Name name,
      {this.isImplicitlyAbstract: true})
      : super(parent, declarations, isProperty, isSetter, modifyKernel,
            isAbstract, name);

  @override
  bool isObjectMember(ClassBuilder objectClass) =>
      declarations.first.isObjectMember(objectClass);

  @override
  bool get isAbstract => isExplicitlyAbstract || isImplicitlyAbstract;

  Member combinedMemberSignatureResult;

  @override
  String toString() {
    return "InterfaceConflict(${classBuilder.fullNameForErrors}, "
        "[${declarations.join(', ')}])";
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
        type = member.function
            .computeFunctionType(member.enclosingLibrary.nonNullable);
      }
    } else if (member is Field) {
      type = member.type;
    } else {
      unhandled("${member.runtimeType}", "$member", classBuilder.charOffset,
          classBuilder.fileUri);
    }
    InterfaceType instance = hierarchy.getKernelTypeAsInstanceOf(
        thisType, member.enclosingClass, classBuilder.library.library);
    assert(
        instance != null,
        "No instance of $thisType as ${member.enclosingClass} found for "
        "$member.");
    return Substitution.fromInterfaceType(instance).substituteType(type);
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
  Member getMember(ClassHierarchyBuilder hierarchy) => check(hierarchy);

  @override
  Member check(ClassHierarchyBuilder hierarchy) {
    if (combinedMemberSignatureResult != null) {
      return combinedMemberSignatureResult;
    }
    if (classBuilder.library is! SourceLibraryBuilder) {
      return combinedMemberSignatureResult =
          declarations.first.getMember(hierarchy);
    }
    DartType thisType = hierarchy.coreTypes
        .thisInterfaceType(classBuilder.cls, classBuilder.library.nonNullable);
    ClassMember bestSoFar;
    DartType bestTypeSoFar;
    for (int i = declarations.length - 1; i >= 0; i--) {
      ClassMember candidate = declarations[i];
      Member target = candidate.getMember(hierarchy);
      assert(target != null,
          "No member computed for ${candidate} (${candidate.runtimeType})");
      DartType candidateType = computeMemberType(hierarchy, thisType, target);
      if (bestSoFar == null) {
        bestSoFar = candidate;
        bestTypeSoFar = candidateType;
      } else {
        if (isMoreSpecific(hierarchy, candidateType, bestTypeSoFar)) {
          debug?.log("Combined Member Signature: ${candidate.fullName} "
              "${candidateType} <: ${bestSoFar.fullName} ${bestTypeSoFar}");
          bestSoFar = candidate;
          bestTypeSoFar = candidateType;
        } else {
          debug?.log("Combined Member Signature: "
              "${candidate.fullName} !<: ${bestSoFar.fullName}");
        }
      }
    }
    if (bestSoFar != null) {
      debug?.log("Combined Member Signature bestSoFar: ${bestSoFar.fullName}");
      for (int i = 0; i < declarations.length; i++) {
        ClassMember candidate = declarations[i];
        Member target = candidate.getMember(hierarchy);
        DartType candidateType = computeMemberType(hierarchy, thisType, target);
        if (!isMoreSpecific(hierarchy, bestTypeSoFar, candidateType)) {
          debug?.log("Combined Member Signature: "
              "${bestSoFar.fullName} !<: ${candidate.fullName}");

          String uri = '${classBuilder.library.importUri}';
          if (uri == 'dart:js' &&
                  classBuilder.fileUri.pathSegments.last == 'js.dart' ||
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
      // TODO(johnniwinther): Maybe we should have an invalid marker to avoid
      // cascading errors.
      return combinedMemberSignatureResult =
          declarations.first.getMember(hierarchy);
    }
    debug?.log("Combined Member Signature of ${fullNameForErrors}: "
        "${bestSoFar.fullName}");

    ProcedureKind kind = ProcedureKind.Method;
    Member bestMemberSoFar = bestSoFar.getMember(hierarchy);
    if (bestSoFar.isProperty) {
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
        Member bestMemberSoFar = bestSoFar.getMember(hierarchy);
        if (bestMemberSoFar is Procedure) {
          library.forwardersOrigins..add(stub)..add(bestMemberSoFar);
        }
        debug?.log("Combined Member Signature of ${fullNameForErrors}: "
            "added stub $stub");
        if (classBuilder.isMixinApplication) {
          return combinedMemberSignatureResult = bestMemberSoFar;
        } else {
          return combinedMemberSignatureResult = stub;
        }
      }
    }

    debug?.log(
        "Combined Member Signature of ${fullNameForErrors}: picked bestSoFar");
    return combinedMemberSignatureResult = bestSoFar.getMember(hierarchy);
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new InterfaceConflict(parent, [this], isProperty, isSetter,
            modifyKernel, isAbstract, name,
            isImplicitlyAbstract: isImplicitlyAbstract);
  }

  static ClassMember combined(ClassBuilder parent, ClassMember a, ClassMember b,
      bool isSetter, bool createForwarders) {
    assert(a.isProperty == b.isProperty,
        "Unexpected member combination: $a vs $b");
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
          parent,
          declarations,
          a.isProperty,
          isSetter,
          createForwarders,
          declarations.first.isAbstract,
          declarations.first.name);
    }
  }
}

class AbstractMemberOverridingImplementation extends DelayedMember {
  AbstractMemberOverridingImplementation(
      ClassBuilder parent,
      ClassMember abstractMember,
      ClassMember concreteImplementation,
      bool isProperty,
      bool isSetter,
      bool modifyKernel,
      bool isAbstract,
      Name name)
      : super(parent, <ClassMember>[concreteImplementation, abstractMember],
            isProperty, isSetter, modifyKernel, isAbstract, name);

  @override
  bool isObjectMember(ClassBuilder objectClass) =>
      concreteImplementation.isObjectMember(objectClass);

  ClassMember get concreteImplementation => declarations[0];

  ClassMember get abstractMember => declarations[1];

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) =>
      abstractMember.getMember(hierarchy);

  Member check(ClassHierarchyBuilder hierarchy) {
    if (!classBuilder.isAbstract &&
        !hierarchy.nodes[classBuilder.cls].hasNoSuchMethod) {
      new DelayedOverrideCheck(
              classBuilder, concreteImplementation, abstractMember)
          .check(hierarchy);
    }

    ProcedureKind kind = ProcedureKind.Method;
    if (abstractMember.isProperty) {
      kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
    }
    if (modifyKernel) {
      // This call will add a body to the abstract method if needed for
      // isGenericCovariantImpl checks.
      new ForwardingNode(
              hierarchy, classBuilder, abstractMember, declarations, kind)
          .finalize();
    }
    return abstractMember.getMember(hierarchy);
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new AbstractMemberOverridingImplementation(
            parent,
            abstractMember,
            concreteImplementation,
            isProperty,
            isSetter,
            modifyKernel,
            isAbstract,
            name);
  }

  @override
  String toString() {
    return "AbstractMemberOverridingImplementation("
        "${classBuilder.fullNameForErrors}, "
        "[${declarations.join(', ')}])";
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
    } else if (declaration is InterfaceConflict && !declaration.isAbstract) {
      return selectConcrete(declaration.declarations.first);
    } else {
      return declaration;
    }
  }
}

void addDeclarationIfDifferent(
    ClassMember declaration, List<ClassMember> declarations) {
  for (int i = 0; i < declarations.length; i++) {
    if (declaration == declarations[i]) return;
  }
  declarations.add(declaration);
}

int compareNamedParameters(VariableDeclaration a, VariableDeclaration b) {
  return a.name.compareTo(b.name);
}

bool inferParameterType(
    ClassBuilder classBuilder,
    SourceProcedureMember memberBuilder,
    FormalParameterBuilder parameterBuilder,
    DartType type,
    bool hadTypesInferred,
    ClassHierarchyBuilder hierarchy) {
  debug?.log("Inferred type ${type} for ${parameterBuilder}");

  if (classBuilder.library.isNonNullableByDefault) {
    if (hadTypesInferred) {
      type = nnbdTopMerge(
          hierarchy.coreTypes, parameterBuilder.variable.type, type);
      if (type != null) {
        // The nnbd top merge exists so [type] is the inferred type.
        parameterBuilder.variable.type = type;
        return true;
      }
      // The nnbd top merge doesn't exist. An error will be reported below.
    }
  } else {
    type = legacyErasure(hierarchy.coreTypes, type);
  }

  if (type == parameterBuilder.variable.type) return true;
  bool result = true;
  if (hadTypesInferred) {
    reportCantInferParameterType(classBuilder, parameterBuilder, hierarchy);
    type = const InvalidType();
    result = false;
  }
  parameterBuilder.variable.type = type;
  memberBuilder.hadTypesInferred = true;
  return result;
}

void reportCantInferParameterType(ClassBuilder cls,
    FormalParameterBuilder parameter, ClassHierarchyBuilder hierarchy) {
  String name = parameter.name;
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      parameter.charOffset,
      name.length,
      wasHandled: true);
}

bool inferReturnType(ClassBuilder cls, SourceProcedureMember procedureBuilder,
    DartType type, bool hadTypesInferred, ClassHierarchyBuilder hierarchy) {
  Procedure procedure = procedureBuilder.getMember(hierarchy);
  if (type == procedure.function.returnType) return true;
  bool result = true;
  if (hadTypesInferred) {
    reportCantInferReturnType(cls, procedureBuilder, hierarchy);
    type = const InvalidType();
    result = false;
  } else {
    procedureBuilder.hadTypesInferred = true;
  }
  procedure.function.returnType = type;
  return result;
}

void reportCantInferReturnType(
    ClassBuilder cls, ClassMember member, ClassHierarchyBuilder hierarchy) {
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

void reportCantInferFieldType(ClassBuilder cls, ClassMember member) {
  String name = member.fullNameForErrors;
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      member.charOffset,
      name.length,
      wasHandled: true);
}

ClassBuilder getClass(TypeBuilder type) {
  Builder declaration = type.declaration;
  if (declaration is TypeAliasBuilder) {
    TypeAliasBuilder aliasBuilder = declaration;
    declaration = aliasBuilder.unaliasDeclaration;
  }
  return declaration is ClassBuilder ? declaration : null;
}

/// Returns `true` if the first [length] elements of [a] and [b] are the same.
bool _equalsList(List<ClassMember> a, List<ClassMember> b, int length) {
  if (a.length < length || b.length < length) return false;
  for (int index = 0; index < length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
