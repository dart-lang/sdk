// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart' hide MapEntry;

import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution, uniteNullabilities;
import 'package:kernel/type_environment.dart';

import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/nnbd_top_merge.dart';
import 'package:kernel/src/norm.dart';
import 'package:kernel/src/types.dart' show Types;

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
        messageDeclaredMemberConflictsWithInheritedMembersCause,
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

const bool useConsolidated = true;

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

int compareClassMembers(ClassMember a, ClassMember b) {
  if (a.forSetter == b.forSetter) {
    return compareDeclarations(a, b);
  } else if (a.forSetter) {
    return 1;
  } else {
    return -1;
  }
}

bool isNameVisibleIn(Name name, LibraryBuilder libraryBuilder) {
  return !name.isPrivate || name.library == libraryBuilder.library;
}

class Tuple {
  final Name name;
  ClassMember declaredMember;
  ClassMember declaredSetter;
  ClassMember extendedMember;
  ClassMember extendedSetter;
  List<ClassMember> implementedMembers;
  List<ClassMember> implementedSetters;

  Tuple.declareMember(this.declaredMember)
      : assert(!declaredMember.forSetter),
        this.name = declaredMember.name;

  Tuple.extendMember(this.extendedMember)
      : assert(!extendedMember.forSetter),
        this.name = extendedMember.name;

  Tuple.implementMember(ClassMember implementedMember)
      : assert(!implementedMember.forSetter),
        this.name = implementedMember.name,
        implementedMembers = <ClassMember>[implementedMember];

  Tuple.declareSetter(this.declaredSetter)
      : assert(declaredSetter.forSetter),
        this.name = declaredSetter.name;

  Tuple.extendSetter(this.extendedSetter)
      : assert(extendedSetter.forSetter),
        this.name = extendedSetter.name;

  Tuple.implementSetter(ClassMember implementedSetter)
      : assert(implementedSetter.forSetter),
        this.name = implementedSetter.name,
        implementedSetters = <ClassMember>[implementedSetter];

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    String comma = '';
    sb.write('Tuple(');
    if (declaredMember != null) {
      sb.write(comma);
      sb.write('declaredMember=');
      sb.write(declaredMember);
      comma = ',';
    }
    if (declaredSetter != null) {
      sb.write(comma);
      sb.write('declaredSetter=');
      sb.write(declaredSetter);
      comma = ',';
    }
    if (extendedMember != null) {
      sb.write(comma);
      sb.write('extendedMember=');
      sb.write(extendedMember);
      comma = ',';
    }
    if (extendedSetter != null) {
      sb.write(comma);
      sb.write('extendedSetter=');
      sb.write(extendedSetter);
      comma = ',';
    }
    if (implementedMembers != null) {
      sb.write(comma);
      sb.write('implementedMembers=');
      sb.write(implementedMembers);
      comma = ',';
    }
    if (implementedSetters != null) {
      sb.write(comma);
      sb.write('implementedSetters=');
      sb.write(implementedSetters);
      comma = ',';
    }
    sb.write(')');
    return sb.toString();
  }
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
  bool get forSetter;
  bool get isSourceDeclaration;

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

  bool get needsComputation;
  bool get isSynthesized;

  // If `true` this member is not part of the interface but only part of the
  // class members.
  //
  // This is `true` for instance for synthesized fields added for the late
  // lowering.
  bool get isInternalImplementation;

  bool get isInheritableConflict;
  ClassMember withParent(ClassBuilder classBuilder);
  bool get hasDeclarations;
  List<ClassMember> get declarations;
  ClassMember get abstract;
  ClassMember get concrete;

  bool operator ==(Object other);

  void inferType(ClassHierarchyBuilder hierarchy);
  void registerOverrideDependency(ClassMember overriddenMember);
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

class ClassHierarchyBuilder implements ClassHierarchyBase {
  final Map<Class, ClassHierarchyNode> nodes = <Class, ClassHierarchyNode>{};

  final Map<ClassBuilder, Map<Class, Substitution>> substitutions =
      <ClassBuilder, Map<Class, Substitution>>{};

  final ClassBuilder objectClassBuilder;

  final Loader loader;

  final Class objectClass;

  final Class futureClass;

  final Class functionClass;

  final Class nullClass;

  final List<DelayedTypeComputation> _delayedTypeComputations =
      <DelayedTypeComputation>[];

  final List<DelayedOverrideCheck> _overrideChecks = <DelayedOverrideCheck>[];

  final List<ClassMember> _delayedMemberChecks = <ClassMember>[];

  final CoreTypes coreTypes;

  Types types;

  Map<ClassMember, Map<ClassMember, ClassMember>> inheritanceConflictCache =
      new Map.identity();

  ClassHierarchyBuilder(this.objectClassBuilder, this.loader, this.coreTypes)
      : objectClass = objectClassBuilder.cls,
        futureClass = coreTypes.futureClass,
        functionClass = coreTypes.functionClass,
        nullClass = coreTypes.nullClass {
    types = new Types(this);
  }

  void clear() {
    nodes.clear();
    substitutions.clear();
    _overrideChecks.clear();
    _delayedTypeComputations.clear();
    inheritanceConflictCache.clear();
    _delayedMemberChecks.clear();
  }

  void registerDelayedTypeComputation(DelayedTypeComputation computation) {
    _delayedTypeComputations.add(computation);
  }

  void registerOverrideCheck(
      ClassBuilder classBuilder, ClassMember a, ClassMember b) {
    _overrideChecks.add(new DelayedOverrideCheck(classBuilder, a, b));
  }

  void registerMemberCheck(ClassMember member) {
    _delayedMemberChecks.add(member);
  }

  List<DelayedTypeComputation> takeDelayedTypeComputations() {
    List<DelayedTypeComputation> list = _delayedTypeComputations.toList();
    _delayedTypeComputations.clear();
    return list;
  }

  List<DelayedOverrideCheck> takeDelayedOverrideChecks() {
    List<DelayedOverrideCheck> list = _overrideChecks.toList();
    _overrideChecks.clear();
    return list;
  }

  List<ClassMember> takeDelayedMemberChecks() {
    List<ClassMember> list = _delayedMemberChecks.toList();
    _delayedMemberChecks.clear();
    return list;
  }

  void inferFieldType(SourceFieldBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassHierarchyNodeBuilder.inferFieldType(
        this,
        declaredMember.classBuilder,
        substitutions[declaredMember.classBuilder],
        declaredMember,
        overriddenMembers);
  }

  void inferGetterType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassHierarchyNodeBuilder.inferGetterType(
        this,
        declaredMember.classBuilder,
        substitutions[declaredMember.classBuilder],
        declaredMember,
        overriddenMembers);
  }

  void inferSetterType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassHierarchyNodeBuilder.inferSetterType(
        this,
        declaredMember.classBuilder,
        substitutions[declaredMember.classBuilder],
        declaredMember,
        overriddenMembers);
  }

  void inferMethodType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassHierarchyNodeBuilder.inferMethodType(
        this,
        declaredMember.classBuilder,
        substitutions[declaredMember.classBuilder],
        declaredMember,
        overriddenMembers);
  }

  ClassHierarchyNode getNodeFromClassBuilder(ClassBuilder classBuilder) {
    return nodes[classBuilder.cls] ??= new ClassHierarchyNodeBuilder(
            this, classBuilder, substitutions[classBuilder] ??= {})
        .build();
  }

  ClassHierarchyNode getNodeFromTypeBuilder(TypeBuilder type) {
    ClassBuilder cls = getClass(type);
    return cls == null ? null : getNodeFromClassBuilder(cls);
  }

  ClassHierarchyNode getNodeFromClass(Class cls) {
    return nodes[cls] ??
        getNodeFromClassBuilder(loader.computeClassBuilderFromTargetClass(cls));
  }

  Supertype asSupertypeOf(InterfaceType subtype, Class supertype) {
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

  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes) {
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
    return asSupertypeOf(type, superclass)
        .asInterfaceType
        .withDeclaredNullability(type.nullability);
  }

  List<DartType> getTypeArgumentsAsInstanceOf(
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
        DartType candidate1 = getTypeAsInstanceOf(
            type1, node.classBuilder.cls, clientLibrary, coreTypes);
        DartType candidate2 = getTypeAsInstanceOf(
            type2, node.classBuilder.cls, clientLibrary, coreTypes);
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
        return getTypeAsInstanceOf(
                type1, node.classBuilder.cls, clientLibrary, coreTypes)
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

  Member getInterfaceMember(Class cls, Name name, {bool setter: false}) {
    return getNodeFromClass(cls)
        .getInterfaceMember(name, setter)
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
    return declaration.getMember(this);
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

  void computeTypes() {
    List<DelayedTypeComputation> typeComputations =
        takeDelayedTypeComputations();
    for (int i = 0; i < typeComputations.length; i++) {
      typeComputations[i].compute(this);
    }
  }
}

class ClassHierarchyNodeBuilder {
  final ClassHierarchyBuilder hierarchy;

  final ClassBuilder classBuilder;

  bool hasNoSuchMethod = false;

  List<ClassMember> abstractMembers = null;

  final Map<Class, Substitution> substitutions;

  ClassHierarchyNodeBuilder(
      this.hierarchy, this.classBuilder, this.substitutions);

  ClassBuilder get objectClass => hierarchy.objectClassBuilder;

  bool get shouldModifyKernel =>
      classBuilder.library.loader == hierarchy.loader;

  ClassMember checkInheritanceConflict(ClassMember a, ClassMember b) {
    hierarchy.inheritanceConflictCache[a] ??= new Map.identity();
    if (hierarchy.inheritanceConflictCache[a].containsKey(b)) {
      return hierarchy.inheritanceConflictCache[a][b];
    }

    if (a.hasDeclarations) {
      ClassMember result;
      for (int i = 0; i < a.declarations.length; i++) {
        ClassMember d = checkInheritanceConflict(a.declarations[i], b);
        result ??= d;
      }
      hierarchy.inheritanceConflictCache[a][b] = result;
      return result;
    }
    if (b.hasDeclarations) {
      ClassMember result;
      for (int i = 0; i < b.declarations.length; i++) {
        ClassMember d = checkInheritanceConflict(a, b.declarations[i]);
        result ??= d;
      }
      hierarchy.inheritanceConflictCache[a][b] = result;
      return result;
    }
    if (isInheritanceConflict(a, b)) {
      reportInheritanceConflict(a, b);
      hierarchy.inheritanceConflictCache[a][b] = a;
      return a;
    }
    hierarchy.inheritanceConflictCache[a][b] = null;
    return null;
  }

  static void inferMethodType(
      ClassHierarchyBuilder hierarchy,
      ClassBuilder classBuilder,
      Map<Class, Substitution> substitutions,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(!declaredMember.isGetter && !declaredMember.isSetter);
    if (declaredMember.classBuilder == classBuilder &&
        (declaredMember.returnType == null ||
            declaredMember.formals != null &&
                declaredMember.formals
                    .any((parameter) => parameter.type == null))) {
      Procedure declaredProcedure = declaredMember.member;
      FunctionNode declaredFunction = declaredProcedure.function;
      List<TypeParameter> declaredTypeParameters =
          declaredFunction.typeParameters;
      List<VariableDeclaration> declaredPositional =
          declaredFunction.positionalParameters;
      List<VariableDeclaration> declaredNamed =
          declaredFunction.namedParameters;
      declaredNamed = declaredNamed.toList()..sort(compareNamedParameters);

      DartType inferredReturnType;
      Map<FormalParameterBuilder, DartType> inferredParameterTypes = {};

      for (ClassMember classMember
          in toSet(declaredMember.classBuilder, overriddenMembers)) {
        assert(useConsolidated || !classMember.hasDeclarations);
        Member overriddenMember = classMember.getMember(hierarchy);
        Substitution classSubstitution;
        if (classBuilder.cls != overriddenMember.enclosingClass) {
          assert(
              substitutions.containsKey(overriddenMember.enclosingClass),
              "No substitution found for '${classBuilder.fullNameForErrors}' "
              "as instance of '${overriddenMember.enclosingClass.name}'. "
              "Substitutions available for: ${substitutions.keys}");
          classSubstitution = substitutions[overriddenMember.enclosingClass];
          debug?.log("${classBuilder.fullNameForErrors} -> "
              "${overriddenMember.enclosingClass.name} $classSubstitution");
        }
        if (overriddenMember is! Procedure) {
          debug?.log("Giving up 1");
          continue;
        }
        Procedure overriddenProcedure = overriddenMember;
        FunctionNode overriddenFunction = overriddenProcedure.function;

        List<TypeParameter> overriddenTypeParameters =
            overriddenFunction.typeParameters;
        int typeParameterCount = declaredTypeParameters.length;
        if (typeParameterCount != overriddenTypeParameters.length) {
          debug?.log("Giving up 2");
          continue;
        }
        Substitution methodSubstitution;
        if (typeParameterCount != 0) {
          List<DartType> types = new List<DartType>(typeParameterCount);
          for (int i = 0; i < typeParameterCount; i++) {
            types[i] = new TypeParameterType.forAlphaRenaming(
                overriddenTypeParameters[i], declaredTypeParameters[i]);
          }
          methodSubstitution =
              Substitution.fromPairs(overriddenTypeParameters, types);
          for (int i = 0; i < typeParameterCount; i++) {
            DartType declaredBound = declaredTypeParameters[i].bound;
            DartType overriddenBound = methodSubstitution
                .substituteType(overriddenTypeParameters[i].bound);
            if (!hierarchy.types
                .performNullabilityAwareMutualSubtypesCheck(
                    declaredBound, overriddenBound)
                .isSubtypeWhenUsingNullabilities()) {
              debug?.log("Giving up 3");
              continue;
            }
          }
        }

        DartType inheritedReturnType = overriddenFunction.returnType;
        if (classSubstitution != null) {
          inheritedReturnType =
              classSubstitution.substituteType(inheritedReturnType);
        }
        if (methodSubstitution != null) {
          inheritedReturnType =
              methodSubstitution.substituteType(inheritedReturnType);
        }
        if (declaredMember.returnType == null &&
            inferredReturnType is! InvalidType) {
          inferredReturnType = mergeTypeInLibrary(
              hierarchy, classBuilder, inferredReturnType, inheritedReturnType);
          if (inferredReturnType == null) {
            // A different type has already been inferred.
            inferredReturnType = const InvalidType();
            reportCantInferReturnType(
                classBuilder, declaredMember, hierarchy, overriddenMembers);
          }
        }
        if (declaredFunction.requiredParameterCount >
            overriddenFunction.requiredParameterCount) {
          debug?.log("Giving up 4");
          continue;
        }
        List<VariableDeclaration> overriddenPositional =
            overriddenFunction.positionalParameters;
        if (declaredPositional.length < overriddenPositional.length) {
          debug?.log("Giving up 5");
          continue;
        }

        for (int i = 0; i < overriddenPositional.length; i++) {
          FormalParameterBuilder declaredParameter = declaredMember.formals[i];
          if (declaredParameter.type != null) continue;

          VariableDeclaration overriddenParameter = overriddenPositional[i];
          DartType inheritedParameterType = overriddenParameter.type;
          if (classSubstitution != null) {
            inheritedParameterType =
                classSubstitution.substituteType(inheritedParameterType);
          }
          if (methodSubstitution != null) {
            inheritedParameterType =
                methodSubstitution.substituteType(inheritedParameterType);
          }
          if (hierarchy.coreTypes.objectClass.enclosingLibrary
                  .isNonNullableByDefault &&
              !declaredMember.classBuilder.library.isNonNullableByDefault &&
              overriddenProcedure == hierarchy.coreTypes.objectEquals) {
            // In legacy code we special case `Object.==` to infer `dynamic`
            // instead `Object!`.
            inheritedParameterType = const DynamicType();
          }
          DartType inferredParameterType =
              inferredParameterTypes[declaredParameter];
          inferredParameterType = mergeTypeInLibrary(hierarchy, classBuilder,
              inferredParameterType, inheritedParameterType);
          if (inferredParameterType == null) {
            // A different type has already been inferred.
            inferredParameterType = const InvalidType();
            reportCantInferParameterType(
                classBuilder, declaredParameter, hierarchy, overriddenMembers);
          }
          inferredParameterTypes[declaredParameter] = inferredParameterType;
        }

        List<VariableDeclaration> overriddenNamed =
            overriddenFunction.namedParameters;
        named:
        if (declaredNamed.isNotEmpty || overriddenNamed.isNotEmpty) {
          if (declaredPositional.length != overriddenPositional.length) {
            debug?.log("Giving up 9");
            break named;
          }
          if (declaredFunction.requiredParameterCount !=
              overriddenFunction.requiredParameterCount) {
            debug?.log("Giving up 10");
            break named;
          }

          overriddenNamed = overriddenNamed.toList()
            ..sort(compareNamedParameters);
          int declaredIndex = 0;
          for (int overriddenIndex = 0;
              overriddenIndex < overriddenNamed.length;
              overriddenIndex++) {
            String name = overriddenNamed[overriddenIndex].name;
            for (; declaredIndex < declaredNamed.length; declaredIndex++) {
              if (declaredNamed[declaredIndex].name == name) break;
            }
            if (declaredIndex == declaredNamed.length) {
              debug?.log("Giving up 11");
              break named;
            }
            FormalParameterBuilder declaredParameter;
            for (int i = declaredPositional.length;
                i < declaredMember.formals.length;
                ++i) {
              if (declaredMember.formals[i].name == name) {
                declaredParameter = declaredMember.formals[i];
                break;
              }
            }
            if (declaredParameter.type != null) continue;
            VariableDeclaration overriddenParameter =
                overriddenNamed[overriddenIndex];

            DartType inheritedParameterType = overriddenParameter.type;
            if (classSubstitution != null) {
              inheritedParameterType =
                  classSubstitution.substituteType(inheritedParameterType);
            }
            if (methodSubstitution != null) {
              inheritedParameterType =
                  methodSubstitution.substituteType(inheritedParameterType);
            }
            DartType inferredParameterType =
                inferredParameterTypes[declaredParameter];
            inferredParameterType = mergeTypeInLibrary(hierarchy, classBuilder,
                inferredParameterType, inheritedParameterType);
            if (inferredParameterType == null) {
              // A different type has already been inferred.
              inferredParameterType = const InvalidType();
              reportCantInferParameterType(classBuilder, declaredParameter,
                  hierarchy, overriddenMembers);
            }
            inferredParameterTypes[declaredParameter] = inferredParameterType;
          }
        }
      }
      if (declaredMember.returnType == null) {
        inferredReturnType ??= const DynamicType();
        declaredFunction.returnType = inferredReturnType;
      }
      if (declaredMember.formals != null) {
        for (FormalParameterBuilder declaredParameter
            in declaredMember.formals) {
          if (declaredParameter.type == null) {
            DartType inferredParameterType =
                inferredParameterTypes[declaredParameter] ??
                    const DynamicType();
            declaredParameter.variable.type = inferredParameterType;
          }
        }
      }
    }
  }

  void inferMethodSignature(ClassHierarchyBuilder hierarchy,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    assert(!declaredMember.isGetter && !declaredMember.isSetter);
    // Trigger computation of method type.
    Procedure declaredProcedure = declaredMember.getMember(hierarchy);
    FunctionNode declaredFunction = declaredProcedure.function;
    List<TypeParameter> declaredTypeParameters =
        declaredFunction.typeParameters;
    List<VariableDeclaration> declaredPositional =
        declaredFunction.positionalParameters;
    List<VariableDeclaration> declaredNamed = declaredFunction.namedParameters;
    for (ClassMember overriddenMember
        in toSet(declaredMember.classBuilder, overriddenMembers)) {
      assert(useConsolidated || !overriddenMember.hasDeclarations);
      Member bMember = overriddenMember.getMember(hierarchy);
      if (bMember is! Procedure) {
        debug?.log("Giving up 1");
        continue;
      }
      Procedure bProcedure = bMember;
      FunctionNode bFunction = bProcedure.function;

      List<TypeParameter> bTypeParameters = bFunction.typeParameters;
      int typeParameterCount = declaredTypeParameters.length;
      if (typeParameterCount != bTypeParameters.length) {
        debug?.log("Giving up 2");
        continue;
      }
      if (typeParameterCount != 0) {
        for (int i = 0; i < typeParameterCount; i++) {
          copyTypeParameterCovariance(declaredMember.classBuilder,
              declaredTypeParameters[i], bTypeParameters[i]);
        }
      }

      if (declaredFunction.requiredParameterCount >
          bFunction.requiredParameterCount) {
        debug?.log("Giving up 4");
        continue;
      }
      List<VariableDeclaration> bPositional = bFunction.positionalParameters;
      if (declaredPositional.length < bPositional.length) {
        debug?.log("Giving up 5");
        continue;
      }

      for (int i = 0; i < bPositional.length; i++) {
        VariableDeclaration aParameter = declaredPositional[i];
        VariableDeclaration bParameter = bPositional[i];
        copyParameterCovariance(
            declaredMember.classBuilder, aParameter, bParameter);
      }

      List<VariableDeclaration> bNamed = bFunction.namedParameters;
      named:
      if (declaredNamed.isNotEmpty || bNamed.isNotEmpty) {
        if (declaredPositional.length != bPositional.length) {
          debug?.log("Giving up 9");
          break named;
        }
        if (declaredFunction.requiredParameterCount !=
            bFunction.requiredParameterCount) {
          debug?.log("Giving up 10");
          break named;
        }

        declaredNamed = declaredNamed.toList()..sort(compareNamedParameters);
        bNamed = bNamed.toList()..sort(compareNamedParameters);
        int aCount = 0;
        for (int bCount = 0; bCount < bNamed.length; bCount++) {
          String name = bNamed[bCount].name;
          for (; aCount < declaredNamed.length; aCount++) {
            if (declaredNamed[aCount].name == name) break;
          }
          if (aCount == declaredNamed.length) {
            debug?.log("Giving up 11");
            break named;
          }
          VariableDeclaration aParameter = declaredNamed[aCount];
          VariableDeclaration bParameter = bNamed[bCount];
          copyParameterCovariance(
              declaredMember.classBuilder, aParameter, bParameter);
        }
      }
    }
  }

  void inferGetterSignature(ClassHierarchyBuilder hierarchy,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isGetter);
    // Trigger computation of the getter type.
    declaredMember.getMember(hierarchy);
    // Otherwise nothing to do. Getters have no variance.
  }

  void inferSetterSignature(ClassHierarchyBuilder hierarchy,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isSetter);
    // Trigger computation of the getter type.
    Procedure declaredSetter = declaredMember.getMember(hierarchy);
    VariableDeclaration setterParameter =
        declaredSetter.function.positionalParameters.single;
    for (ClassMember overriddenMember
        in toSet(declaredMember.classBuilder, overriddenMembers)) {
      Member bTarget = overriddenMember.getMember(hierarchy);
      if (bTarget is Field) {
        copyParameterCovarianceFromField(
            declaredMember.classBuilder, setterParameter, bTarget);
      } else if (bTarget is Procedure) {
        if (overriddenMember.isSetter) {
          VariableDeclaration bParameter =
              bTarget.function.positionalParameters.single;
          copyParameterCovariance(
              declaredMember.classBuilder, setterParameter, bParameter);
        } else if (overriddenMember.isGetter) {
          // No variance to copy from getter.
        } else {
          debug?.log("Giving up (not accessor: ${bTarget.kind})");
          continue;
        }
      } else {
        debug?.log("Giving up (not field/procedure: ${bTarget.runtimeType})");
        return;
      }
    }
  }

  static void inferGetterType(
      ClassHierarchyBuilder hierarchy,
      ClassBuilder classBuilder,
      Map<Class, Substitution> substitutions,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isGetter);
    if (declaredMember.classBuilder == classBuilder &&
        declaredMember.returnType == null) {
      DartType inferredType;

      void inferFrom(ClassMember classMember) {
        if (inferredType is InvalidType) return;

        Member overriddenMember = classMember.getMember(hierarchy);
        Substitution substitution;
        if (classBuilder.cls != overriddenMember.enclosingClass) {
          assert(
              substitutions.containsKey(overriddenMember.enclosingClass),
              "No substitution found for '${classBuilder.fullNameForErrors}' "
              "as instance of '${overriddenMember.enclosingClass.name}'. "
              "Substitutions available for: ${substitutions.keys}");
          substitution = substitutions[overriddenMember.enclosingClass];
        }
        DartType inheritedType;
        if (overriddenMember is Field) {
          inheritedType = overriddenMember.type;
          assert(inheritedType is! ImplicitFieldType);
        } else if (overriddenMember is Procedure) {
          if (overriddenMember.kind == ProcedureKind.Setter) {
            VariableDeclaration bParameter =
                overriddenMember.function.positionalParameters.single;
            inheritedType = bParameter.type;
          } else if (overriddenMember.kind == ProcedureKind.Getter) {
            inheritedType = overriddenMember.function.returnType;
          } else {
            debug?.log("Giving up (not accessor: ${overriddenMember.kind})");
            return;
          }
        } else {
          debug?.log(
              "Giving up (not field/procedure: ${overriddenMember.runtimeType})");
          return;
        }
        if (substitution != null) {
          inheritedType = substitution.substituteType(inheritedType);
        }
        inferredType = mergeTypeInLibrary(
            hierarchy, classBuilder, inferredType, inheritedType);

        if (inferredType == null) {
          // A different type has already been inferred.
          inferredType = const InvalidType();
          reportCantInferReturnType(
              classBuilder, declaredMember, hierarchy, overriddenMembers);
        }
      }

      overriddenMembers = toSet(classBuilder, overriddenMembers);
      // The getter type must be inferred from getters first.
      for (ClassMember overriddenMember in overriddenMembers) {
        if (!overriddenMember.forSetter) {
          inferFrom(overriddenMember);
        }
      }
      if (inferredType == null) {
        // The getter type must be inferred from setters if no type was
        // inferred from getters.
        for (ClassMember overriddenMember in overriddenMembers) {
          if (overriddenMember.forSetter) {
            inferFrom(overriddenMember);
          }
        }
      }

      inferredType ??= const DynamicType();
      declaredMember.procedure.function.returnType = inferredType;
    }
  }

  static void inferSetterType(
      ClassHierarchyBuilder hierarchy,
      ClassBuilder classBuilder,
      Map<Class, Substitution> substitutions,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isSetter);
    FormalParameterBuilder parameter = declaredMember.formals.first;
    if (declaredMember.classBuilder == classBuilder && parameter.type == null) {
      DartType inferredType;

      void inferFrom(ClassMember classMember) {
        if (inferredType is InvalidType) return;

        Member overriddenMember = classMember.getMember(hierarchy);
        Substitution substitution;
        if (classBuilder.cls != overriddenMember.enclosingClass) {
          assert(
              substitutions.containsKey(overriddenMember.enclosingClass),
              "No substitution found for '${classBuilder.fullNameForErrors}' "
              "as instance of '${overriddenMember.enclosingClass.name}'. "
              "Substitutions available for: ${substitutions.keys}");
          substitution = substitutions[overriddenMember.enclosingClass];
        }
        DartType inheritedType;
        if (overriddenMember is Field) {
          inheritedType = overriddenMember.type;
          assert(inheritedType is! ImplicitFieldType);
        } else if (overriddenMember is Procedure) {
          if (classMember.isSetter) {
            VariableDeclaration bParameter =
                overriddenMember.function.positionalParameters.single;
            inheritedType = bParameter.type;
          } else if (classMember.isGetter) {
            inheritedType = overriddenMember.function.returnType;
          } else {
            debug?.log("Giving up (not accessor: ${overriddenMember.kind})");
            return;
          }
        } else {
          debug?.log(
              "Giving up (not field/procedure: ${overriddenMember.runtimeType})");
          return;
        }
        if (substitution != null) {
          inheritedType = substitution.substituteType(inheritedType);
        }
        inferredType = mergeTypeInLibrary(
            hierarchy, classBuilder, inferredType, inheritedType);
        if (inferredType == null) {
          // A different type has already been inferred.
          inferredType = const InvalidType();
          reportCantInferParameterType(
              classBuilder, parameter, hierarchy, overriddenMembers);
        }
      }

      overriddenMembers = toSet(classBuilder, overriddenMembers);
      // The setter type must be inferred from setters first.
      for (ClassMember overriddenMember in overriddenMembers) {
        if (overriddenMember.forSetter) {
          inferFrom(overriddenMember);
        }
      }
      if (inferredType == null) {
        // The setter type must be inferred from getters if no type was
        // inferred from setters.
        for (ClassMember overriddenMember in overriddenMembers) {
          if (!overriddenMember.forSetter) {
            inferFrom(overriddenMember);
          }
        }
      }

      inferredType ??= const DynamicType();
      parameter.variable.type = inferredType;
    }
  }

  /// Merge the [inheritedType] with the currently [inferredType] using
  /// nnbd-top-merge or legacy-top-merge depending on whether [classBuilder] is
  /// defined in an opt-in or opt-out library. If the types could not be merged
  /// `null` is returned and an error should be reported by the caller.
  static DartType mergeTypeInLibrary(
      ClassHierarchyBuilder hierarchy,
      ClassBuilder classBuilder,
      DartType inferredType,
      DartType inheritedType) {
    if (classBuilder.library.isNonNullableByDefault) {
      if (inferredType == null) {
        return inheritedType;
      } else {
        return nnbdTopMerge(
            hierarchy.coreTypes,
            norm(hierarchy.coreTypes, inferredType),
            norm(hierarchy.coreTypes, inheritedType));
      }
    } else {
      inheritedType = legacyErasure(hierarchy.coreTypes, inheritedType);
      if (inferredType == null) {
        return inheritedType;
      } else {
        if (inferredType is DynamicType &&
            inheritedType == hierarchy.coreTypes.objectLegacyRawType) {
          return inferredType;
        } else if (inheritedType is DynamicType &&
            inferredType == hierarchy.coreTypes.objectLegacyRawType) {
          return inheritedType;
        }
        if (inferredType != inheritedType) {
          return null;
        }
        return inferredType;
      }
    }
  }

  /// Infers the field type of [declaredMember] based on [overriddenMembers].
  static void inferFieldType(
      ClassHierarchyBuilder hierarchy,
      ClassBuilder classBuilder,
      Map<Class, Substitution> substitutions,
      SourceFieldBuilder fieldBuilder,
      Iterable<ClassMember> overriddenMembers) {
    if (fieldBuilder.classBuilder == classBuilder &&
        fieldBuilder.type == null) {
      DartType inferredType;

      void inferFrom(ClassMember classMember) {
        if (inferredType is InvalidType) return;

        assert(useConsolidated || !classMember.hasDeclarations);
        Member overriddenMember = classMember.getMember(hierarchy);
        DartType inheritedType;
        if (overriddenMember is Procedure) {
          if (overriddenMember.isSetter) {
            VariableDeclaration parameter =
                overriddenMember.function.positionalParameters.single;
            inheritedType = parameter.type;
          } else if (overriddenMember.isGetter) {
            inheritedType = overriddenMember.function.returnType;
          }
        } else if (overriddenMember is Field) {
          inheritedType = overriddenMember.type;
        }
        if (inheritedType == null) {
          debug
              ?.log("Giving up (inheritedType == null)\n${StackTrace.current}");
          return;
        }
        Substitution substitution;
        if (classBuilder.cls != overriddenMember.enclosingClass) {
          assert(
              substitutions.containsKey(overriddenMember.enclosingClass),
              "${classBuilder.fullNameForErrors} "
              "${overriddenMember.enclosingClass.name}");
          substitution = substitutions[overriddenMember.enclosingClass];
          debug?.log("${classBuilder.fullNameForErrors} -> "
              "${overriddenMember.enclosingClass.name} $substitution");
        }
        assert(inheritedType is! ImplicitFieldType);
        if (substitution != null) {
          inheritedType = substitution.substituteType(inheritedType);
        }
        inferredType = mergeTypeInLibrary(
            hierarchy, classBuilder, inferredType, inheritedType);
        if (inferredType == null) {
          // A different type has already been inferred.
          inferredType = const InvalidType();
          reportCantInferFieldType(
              classBuilder, fieldBuilder, overriddenMembers);
        }
      }

      overriddenMembers = toSet(classBuilder, overriddenMembers);
      if (fieldBuilder.isAssignable) {
        // The field type must be inferred from both getters and setters.
        for (ClassMember overriddenMember in overriddenMembers) {
          inferFrom(overriddenMember);
        }
      } else {
        // The field type must be inferred from getters first.
        for (ClassMember overriddenMember in overriddenMembers) {
          if (!overriddenMember.forSetter) {
            inferFrom(overriddenMember);
          }
        }
        if (inferredType == null) {
          // The field type must be inferred from setters if no type was
          // inferred from getters.
          for (ClassMember overriddenMember in overriddenMembers) {
            if (overriddenMember.forSetter) {
              inferFrom(overriddenMember);
            }
          }
        }
      }

      inferredType ??= const DynamicType();
      fieldBuilder.fieldType = inferredType;
    }
  }

  /// Infers the field signature of [declaredMember] based on
  /// [overriddenMembers].
  void inferFieldSignature(ClassHierarchyBuilder hierarchy,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    Field declaredField = declaredMember.getMember(hierarchy);
    for (ClassMember overriddenMember
        in toSet(declaredMember.classBuilder, overriddenMembers)) {
      assert(useConsolidated || !overriddenMember.hasDeclarations);
      Member bTarget = overriddenMember.getMember(hierarchy);
      if (bTarget is Procedure) {
        if (bTarget.isSetter) {
          VariableDeclaration parameter =
              bTarget.function.positionalParameters.single;
          copyFieldCovarianceFromParameter(
              declaredMember.classBuilder, declaredField, parameter);
        }
      } else if (bTarget is Field) {
        copyFieldCovariance(
            declaredMember.classBuilder, declaredField, bTarget);
      }
    }
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
            context: _inheritedConflictContext(a, b));
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

  void recordAbstractMember(ClassMember member) {
    abstractMembers ??= <ClassMember>[];
    if (member.hasDeclarations &&
        (!useConsolidated || classBuilder == member.classBuilder)) {
      abstractMembers.addAll(member.declarations);
    } else {
      abstractMembers.add(member);
    }
  }

  ClassHierarchyNode build() {
    assert(!classBuilder.isPatch);
    ClassHierarchyNode supernode;
    if (objectClass != classBuilder.origin) {
      supernode =
          hierarchy.getNodeFromTypeBuilder(classBuilder.supertypeBuilder);
      if (supernode == null) {
        supernode = hierarchy.getNodeFromClassBuilder(objectClass);
      }
      assert(supernode != null);
    }

    Scope scope = classBuilder.scope;
    if (classBuilder.isMixinApplication) {
      TypeBuilder mixedInTypeBuilder = classBuilder.mixedInTypeBuilder;
      TypeDeclarationBuilder mixin = mixedInTypeBuilder.declaration;
      inferMixinApplication();
      while (mixin.isNamedMixinApplication) {
        ClassBuilder named = mixin;
        mixedInTypeBuilder = named.mixedInTypeBuilder;
        mixin = mixedInTypeBuilder.declaration;
      }
      if (mixin is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = mixin;
        NamedTypeBuilder namedBuilder = mixedInTypeBuilder;
        mixin = aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
      }
      if (mixin is ClassBuilder) {
        scope = mixin.scope.computeMixinScope();
      }
    }

    Map<Name, Tuple> memberMap = {};

    for (MemberBuilder memberBuilder in scope.localMembers) {
      for (ClassMember classMember in memberBuilder.localMembers) {
        Tuple tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareMember(classMember);
        } else {
          tuple.declaredMember = classMember;
        }
      }
      for (ClassMember classMember in memberBuilder.localSetters) {
        Tuple tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareSetter(classMember);
        } else {
          tuple.declaredSetter = classMember;
        }
      }
    }

    for (MemberBuilder memberBuilder in scope.localSetters) {
      for (ClassMember classMember in memberBuilder.localMembers) {
        Tuple tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareMember(classMember);
        } else {
          tuple.declaredMember = classMember;
        }
      }
      for (ClassMember classMember in memberBuilder.localSetters) {
        Tuple tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareSetter(classMember);
        } else {
          tuple.declaredSetter = classMember;
        }
      }
    }

    List<Supertype> superclasses;

    List<Supertype> interfaces;

    int maxInheritancePath;

    void extend(Map<Name, ClassMember> superClassMembers) {
      if (superClassMembers == null) return;
      for (Name name in superClassMembers.keys) {
        ClassMember superClassMember = superClassMembers[name];
        Tuple tuple = memberMap[name];
        if (tuple != null) {
          if (superClassMember.forSetter) {
            tuple.extendedSetter = superClassMember;
          } else {
            tuple.extendedMember = superClassMember;
          }
        } else {
          if (superClassMember.forSetter) {
            memberMap[name] = new Tuple.extendSetter(superClassMember);
          } else {
            memberMap[name] = new Tuple.extendMember(superClassMember);
          }
        }
      }
    }

    void implement(Map<Name, ClassMember> superInterfaceMembers) {
      if (superInterfaceMembers == null) return;
      for (Name name in superInterfaceMembers.keys) {
        ClassMember superInterfaceMember = superInterfaceMembers[name];
        Tuple tuple = memberMap[name];
        if (tuple != null) {
          if (superInterfaceMember.forSetter) {
            (tuple.implementedSetters ??= <ClassMember>[])
                .add(superInterfaceMember);
          } else {
            (tuple.implementedMembers ??= <ClassMember>[])
                .add(superInterfaceMember);
          }
        } else {
          if (superInterfaceMember.forSetter) {
            memberMap[superInterfaceMember.name] =
                new Tuple.implementSetter(superInterfaceMember);
          } else {
            memberMap[superInterfaceMember.name] =
                new Tuple.implementMember(superInterfaceMember);
          }
        }
      }
    }

    bool hasInterfaces = false;
    if (supernode == null) {
      // This should be Object.
      superclasses = new List<Supertype>(0);
      interfaces = new List<Supertype>(0);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;

      superclasses = new List<Supertype>(supernode.superclasses.length + 1);
      Supertype supertype = classBuilder.supertypeBuilder.buildSupertype(
          classBuilder.library, classBuilder.charOffset, classBuilder.fileUri);
      if (supertype == null) {
        // If the superclass is not an interface type we use Object instead.
        // A similar normalization is performed on [supernode] above.
        supertype =
            new Supertype(hierarchy.coreTypes.objectClass, const <DartType>[]);
      }
      superclasses.setRange(0, superclasses.length - 1,
          substSupertypes(supertype, supernode.superclasses));
      superclasses[superclasses.length - 1] = supertype;
      if (!classBuilder.library.isNonNullableByDefault &&
          supernode.classBuilder.library.isNonNullableByDefault) {
        for (int i = 0; i < superclasses.length; i++) {
          superclasses[i] =
              legacyErasureSupertype(hierarchy.coreTypes, superclasses[i]);
        }
      }

      List<TypeBuilder> directInterfaceBuilders =
          ignoreFunction(classBuilder.interfaceBuilders);
      if (classBuilder.isMixinApplication) {
        if (directInterfaceBuilders == null) {
          directInterfaceBuilders = <TypeBuilder>[
            classBuilder.mixedInTypeBuilder
          ];
        } else {
          directInterfaceBuilders = <TypeBuilder>[
            classBuilder.mixedInTypeBuilder
          ]..addAll(directInterfaceBuilders);
        }
      }

      List<Supertype> superclassInterfaces = supernode.interfaces;
      if (superclassInterfaces != null) {
        superclassInterfaces = substSupertypes(supertype, superclassInterfaces);
      }

      extend(supernode.classMemberMap);
      extend(supernode.classSetterMap);

      if (supernode.interfaceMemberMap != null ||
          supernode.interfaceSetterMap != null) {
        hasInterfaces = true;
      }

      implement(supernode.interfaceMemberMap);
      implement(supernode.interfaceSetterMap);

      if (directInterfaceBuilders != null) {
        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          ClassHierarchyNode interfaceNode =
              hierarchy.getNodeFromTypeBuilder(directInterfaceBuilders[i]);
          if (interfaceNode != null) {
            hasInterfaces = true;

            implement(interfaceNode.interfaceMemberMap ??
                interfaceNode.classMemberMap);
            implement(interfaceNode.interfaceSetterMap ??
                interfaceNode.classSetterMap);
          }
        }

        interfaces = <Supertype>[];
        if (superclassInterfaces != null) {
          for (int i = 0; i < superclassInterfaces.length; i++) {
            addInterface(interfaces, superclasses, superclassInterfaces[i]);
          }
        }

        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          Supertype directInterface = directInterfaceBuilders[i].buildSupertype(
              classBuilder.library,
              classBuilder.charOffset,
              classBuilder.fileUri);
          if (directInterface != null) {
            addInterface(interfaces, superclasses, directInterface);
            ClassHierarchyNode interfaceNode =
                hierarchy.getNodeFromClass(directInterface.classNode);
            if (interfaceNode != null) {
              if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
                maxInheritancePath = interfaceNode.maxInheritancePath + 1;
              }

              List<Supertype> types =
                  substSupertypes(directInterface, interfaceNode.superclasses);
              for (int i = 0; i < types.length; i++) {
                addInterface(interfaces, superclasses, types[i]);
              }
              if (interfaceNode.interfaces != null) {
                List<Supertype> types =
                    substSupertypes(directInterface, interfaceNode.interfaces);
                for (int i = 0; i < types.length; i++) {
                  addInterface(interfaces, superclasses, types[i]);
                }
              }
            }
          }
        }
      } else if (superclassInterfaces != null &&
          !classBuilder.library.isNonNullableByDefault &&
          supernode.classBuilder.library.isNonNullableByDefault) {
        interfaces = <Supertype>[];
        for (int i = 0; i < superclassInterfaces.length; i++) {
          addInterface(interfaces, superclasses, superclassInterfaces[i]);
        }
      } else {
        interfaces = superclassInterfaces;
      }
    }

    for (Supertype superclass in superclasses) {
      recordSupertype(superclass);
    }
    if (interfaces != null) {
      for (Supertype superinterface in interfaces) {
        recordSupertype(superinterface);
      }
    }

    /// Members (excluding setters) declared in [cls] or its superclasses. This
    /// includes static methods of [cls], but not its superclasses.
    Map<Name, ClassMember> classMemberMap = {};

    /// Setters declared in [cls] or its superclasses. This includes static
    /// setters of [cls], but not its superclasses.
    Map<Name, ClassMember> classSetterMap = {};

    /// Members (excluding setters) inherited from interfaces. This contains no
    /// static members. If no interfaces are implemented by this class or its
    /// superclasses this is identical to [classMemberMap] and we do not store
    /// it in the [ClassHierarchyNode].
    Map<Name, ClassMember> interfaceMemberMap = {};

    /// Setters inherited from interfaces. This contains no static setters. If
    /// no interfaces are implemented by this class or its superclasses this is
    /// identical to [classSetterMap] and we do not store it in the
    /// [ClassHierarchyNode].
    Map<Name, ClassMember> interfaceSetterMap = {};

    Map<ClassMember, Set<ClassMember>> overrideDependencies = {};

    // TODO(johnniwinther): Make these non-local and ensure that each
    // underlying declaration has only on delayed type, signature, and
    // override computation. Currently fields get one as a getter and as a
    // setter.

    void registerOverrideDependency(
        ClassMember member, ClassMember overriddenMember) {
      if (classBuilder == member.classBuilder && member.isSourceDeclaration) {
        Set<ClassMember> dependencies =
            overrideDependencies[member] ??= <ClassMember>{};
        dependencies.add(overriddenMember);
        member.registerOverrideDependency(overriddenMember);
      }
    }

    void registerOverrideCheck(
        ClassMember member, ClassMember overriddenMember) {
      if (overriddenMember.hasDeclarations &&
          (!useConsolidated || classBuilder == overriddenMember.classBuilder)) {
        for (int i = 0; i < overriddenMember.declarations.length; i++) {
          hierarchy.registerOverrideCheck(
              classBuilder, member, overriddenMember.declarations[i]);
        }
      } else {
        hierarchy.registerOverrideCheck(classBuilder, member, overriddenMember);
      }
    }

    memberMap.forEach((Name name, Tuple tuple) {
      ClassMember computeClassMember(ClassMember declaredMember,
          ClassMember extendedMember, bool forSetter) {
        if (declaredMember != null) {
          if (extendedMember != null && !extendedMember.isStatic) {
            if (declaredMember == extendedMember) return declaredMember;
            if (declaredMember.isDuplicate || extendedMember.isDuplicate) {
              // Don't check overrides involving duplicated members.
              return declaredMember;
            }
            ClassMember result =
                checkInheritanceConflict(declaredMember, extendedMember);
            if (result != null) return result;
            assert(
                declaredMember.isProperty == extendedMember.isProperty,
                "Unexpected member combination: "
                "$declaredMember vs $extendedMember");
            result = declaredMember;

            // [declaredMember] is a method declared in [cls]. This means it
            // defines the interface of this class regardless if its abstract.
            if (!declaredMember.isSynthesized) {
              registerOverrideDependency(
                  declaredMember, extendedMember.abstract);
              registerOverrideCheck(declaredMember, extendedMember.abstract);
            }

            if (declaredMember.isAbstract) {
              if (extendedMember.isAbstract) {
                recordAbstractMember(declaredMember);
              } else {
                if (!classBuilder.isAbstract) {
                  // The interface of this class is [declaredMember]. But the
                  // implementation is [extendedMember]. So [extendedMember]
                  // must implement [declaredMember], unless [cls] is abstract.
                  registerOverrideCheck(extendedMember, declaredMember);
                }
                ClassMember concrete = extendedMember.concrete;
                result = new AbstractMemberOverridingImplementation(
                    classBuilder,
                    declaredMember,
                    concrete,
                    declaredMember.isProperty,
                    forSetter,
                    shouldModifyKernel,
                    concrete.isAbstract,
                    concrete.name);
                hierarchy.registerMemberCheck(result);
              }
            } else if (classBuilder.isMixinApplication &&
                declaredMember.classBuilder != classBuilder) {
              result = InheritedImplementationInterfaceConflict.combined(
                  classBuilder,
                  declaredMember,
                  extendedMember,
                  forSetter,
                  shouldModifyKernel,
                  isInheritableConflict: false);
              if (result.needsComputation) {
                hierarchy.registerMemberCheck(result);
              }
            }

            if (result.name == noSuchMethodName &&
                !result.isObjectMember(objectClass)) {
              hasNoSuchMethod = true;
            }
            return result;
          } else {
            if (declaredMember.isAbstract) {
              recordAbstractMember(declaredMember);
            }
            return declaredMember;
          }
        } else if (extendedMember != null && !extendedMember.isStatic) {
          if (extendedMember.isAbstract) {
            if (isNameVisibleIn(extendedMember.name, classBuilder.library)) {
              recordAbstractMember(extendedMember);
            }
          }
          if (extendedMember.name == noSuchMethodName &&
              !extendedMember.isObjectMember(objectClass)) {
            hasNoSuchMethod = true;
          }
          if (extendedMember.isInheritableConflict) {
            extendedMember = extendedMember.withParent(classBuilder);
            hierarchy.registerMemberCheck(extendedMember);
          }
          if (extendedMember.classBuilder.library.isNonNullableByDefault &&
              !classBuilder.library.isNonNullableByDefault) {
            if (!extendedMember.isSynthesized) {
              extendedMember = new InterfaceConflict(
                  classBuilder,
                  [extendedMember],
                  extendedMember.isProperty,
                  forSetter,
                  shouldModifyKernel,
                  extendedMember.isAbstract,
                  extendedMember.name,
                  isImplicitlyAbstract: extendedMember.isAbstract);
              hierarchy.registerMemberCheck(extendedMember);
            }
          }
          return extendedMember;
        }
        return null;
      }

      ClassMember computeInterfaceMember(ClassMember classMember,
          List<ClassMember> implementedMembers, bool forSetter) {
        ClassMember interfaceMember;
        if (implementedMembers != null) {
          for (ClassMember member in implementedMembers) {
            if (member.isStatic) continue;
            if (interfaceMember == null) {
              interfaceMember = member;
            } else {
              ClassMember handleMergeConflict(ClassMember a, ClassMember b) {
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
                result = InterfaceConflict.combined(
                    classBuilder, a, b, forSetter, shouldModifyKernel);
                return result;
              }

              interfaceMember = handleMergeConflict(interfaceMember, member);
            }
          }
        }
        if (hasInterfaces) {
          if (interfaceMember != null) {
            if (classMember != null) {
              if (classMember == interfaceMember) return classMember;
              if (classMember.isDuplicate || interfaceMember.isDuplicate) {
                // Don't check overrides involving duplicated members.
                return classMember;
              }
              ClassMember result =
                  checkInheritanceConflict(classMember, interfaceMember);
              if (result != null) return result;
              assert(
                  classMember.isProperty == interfaceMember.isProperty,
                  "Unexpected member combination: "
                  "$classMember vs $interfaceMember");
              result = classMember;

              // [interfaceMember] is inherited from an interface so it is
              // implicitly abstract.
              classMember = classMember.abstract;
              interfaceMember = interfaceMember.abstract;

              // If [classMember] is declared in this class, it defines the
              // interface.
              if (classMember.classBuilder == classBuilder) {
                if (!classMember.isSynthesized) {
                  registerOverrideDependency(classMember, interfaceMember);
                  registerOverrideCheck(classMember, interfaceMember);
                }
                if (classMember.hasDeclarations) {
                  if (interfaceMember.hasDeclarations &&
                      (!useConsolidated ||
                          interfaceMember.classBuilder == classBuilder)) {
                    addAllDeclarationsTo(
                        interfaceMember, classMember.declarations);
                  } else {
                    addDeclarationIfDifferent(
                        interfaceMember, classMember.declarations);
                  }
                }
              } else {
                if (classMember.isAbstract) {
                  result = InterfaceConflict.combined(classBuilder, classMember,
                      interfaceMember, forSetter, shouldModifyKernel);
                } else {
                  result = InheritedImplementationInterfaceConflict.combined(
                      classBuilder,
                      classMember,
                      interfaceMember,
                      forSetter,
                      shouldModifyKernel);
                }
                if (result.needsComputation) {
                  hierarchy.registerMemberCheck(result);
                }
              }

              return result;
            } else {
              if (isNameVisibleIn(interfaceMember.name, classBuilder.library)) {
                if (!interfaceMember.isInternalImplementation) {
                  recordAbstractMember(interfaceMember);
                }
              }
              if (interfaceMember.isInheritableConflict) {
                interfaceMember = interfaceMember.withParent(classBuilder);
                hierarchy.registerMemberCheck(interfaceMember);
              }
              if (interfaceMember.classBuilder.library.isNonNullableByDefault &&
                  !classBuilder.library.isNonNullableByDefault) {
                if (!interfaceMember.isSynthesized) {
                  interfaceMember = new InterfaceConflict(
                      classBuilder,
                      [interfaceMember],
                      interfaceMember.isProperty,
                      forSetter,
                      shouldModifyKernel,
                      interfaceMember.isAbstract,
                      interfaceMember.name,
                      isImplicitlyAbstract: interfaceMember.isAbstract);
                  hierarchy.registerMemberCheck(interfaceMember);
                }
              }
              return interfaceMember;
            }
          } else if (classMember != null) {
            return classMember;
          }
        }
        return interfaceMember;
      }

      void checkMemberVsSetter(
          ClassMember member, ClassMember overriddenMember) {
        if (overriddenMember.isStatic) return;
        if (member == overriddenMember) return;
        if (member.isDuplicate || overriddenMember.isDuplicate) {
          // Don't check overrides involving duplicated members.
          return;
        }
        ClassMember result = checkInheritanceConflict(member, overriddenMember);
        if (result != null) return;
        assert(member.isProperty == overriddenMember.isProperty,
            "Unexpected member combination: $member vs $overriddenMember");
        if (member.classBuilder == classBuilder &&
            overriddenMember.classBuilder != classBuilder) {
          if (member is SourceFieldMember) {
            if (member.isFinal && overriddenMember.isSetter) {
              registerOverrideDependency(member, overriddenMember);
              hierarchy.registerOverrideCheck(
                  classBuilder, member, overriddenMember);
            } else {
              registerOverrideDependency(member, overriddenMember);
              hierarchy.registerOverrideCheck(
                  classBuilder, member, overriddenMember);
            }
          } else if (member is SourceProcedureMember) {
            registerOverrideDependency(member, overriddenMember);
            hierarchy.registerOverrideCheck(
                classBuilder, member, overriddenMember);
          }
        }
      }

      ClassMember classMember =
          computeClassMember(tuple.declaredMember, tuple.extendedMember, false);
      ClassMember interfaceMember =
          computeInterfaceMember(classMember, tuple.implementedMembers, false);
      ClassMember classSetter =
          computeClassMember(tuple.declaredSetter, tuple.extendedSetter, true);
      ClassMember interfaceSetter =
          computeInterfaceMember(classSetter, tuple.implementedSetters, true);

      if (tuple.declaredMember != null && classSetter != null) {
        checkMemberVsSetter(tuple.declaredMember, classSetter);
      }
      if (tuple.declaredSetter != null && classMember != null) {
        checkMemberVsSetter(tuple.declaredSetter, classMember);
      }
      if (classMember != null && interfaceSetter != null) {
        checkMemberVsSetter(classMember, interfaceSetter);
      }
      if (classSetter != null && interfaceMember != null) {
        checkMemberVsSetter(classSetter, interfaceMember);
      }

      if (classMember != null) {
        classMemberMap[name] = classMember;
      }
      if (interfaceMember != null) {
        interfaceMemberMap[name] = interfaceMember;
      }
      if (classSetter != null) {
        classSetterMap[name] = classSetter;
      }
      if (interfaceSetter != null) {
        interfaceSetterMap[name] = interfaceSetter;
      }
    });

    overrideDependencies
        .forEach((ClassMember member, Set<ClassMember> overriddenMembers) {
      assert(
          member == memberMap[member.name].declaredMember ||
              member == memberMap[member.name].declaredSetter,
          "Unexpected method type inference for ${memberMap[member.name]}: "
          "${member} -> ${overriddenMembers}");
      DelayedTypeComputation computation =
          new DelayedTypeComputation(this, member, overriddenMembers);
      hierarchy.registerDelayedTypeComputation(computation);
    });

    if (!hasInterfaces) {
      interfaceMemberMap = null;
      interfaceSetterMap = null;
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
      classMemberMap,
      classSetterMap,
      interfaceMemberMap,
      interfaceSetterMap,
      superclasses,
      interfaces,
      maxInheritancePath,
      hasNoSuchMethod,
    );
  }

  Supertype recordSupertype(Supertype supertype) {
    debug?.log("In ${this.classBuilder.fullNameForErrors} "
        "recordSupertype(${supertype})");
    Class cls = supertype.classNode;
    List<TypeParameter> supertypeTypeParameters = cls.typeParameters;
    if (supertypeTypeParameters.isEmpty) {
      substitutions[cls] = Substitution.empty;
    } else {
      List<DartType> arguments = supertype.typeArguments;
      List<DartType> typeArguments = new List<DartType>(arguments.length);
      List<TypeParameter> typeParameters =
          new List<TypeParameter>(arguments.length);
      for (int i = 0; i < arguments.length; i++) {
        typeParameters[i] = supertypeTypeParameters[i];
        typeArguments[i] = arguments[i];
      }
      substitutions[cls] =
          Substitution.fromPairs(typeParameters, typeArguments);
    }
    return supertype;
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
    List<Supertype> result;
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

  List<TypeBuilder> computeDefaultTypeArguments(TypeBuilder type) {
    TypeDeclarationBuilder decl = type.declaration;
    List<TypeVariableBuilder> typeVariables;
    LibraryBuilder library;
    if (decl is TypeAliasBuilder) {
      typeVariables = decl.typeVariables;
      library = decl.library;
    } else if (decl is ClassBuilder) {
      typeVariables = decl.typeVariables;
      library = decl.library;
    } else {
      return unhandled("${decl.runtimeType}", "$decl", classBuilder.charOffset,
          classBuilder.fileUri);
    }
    List<TypeBuilder> result = new List<TypeBuilder>(typeVariables.length);
    for (int i = 0; i < result.length; ++i) {
      TypeVariableBuilder tv = typeVariables[i];
      result[i] = tv.defaultType ??
          library.loader.computeTypeBuilder(tv.parameter.defaultType);
    }
    return result;
  }

  void addInterface(List<Supertype> interfaces, List<Supertype> superclasses,
      Supertype type) {
    if (type == null) return null;
    if (!classBuilder.library.isNonNullableByDefault) {
      type = legacyErasureSupertype(hierarchy.coreTypes, type);
    }
    ClassHierarchyNode node = hierarchy.getNodeFromClass(type.classNode);
    if (node == null) return null;
    int depth = node.depth;
    int myDepth = superclasses.length;
    Supertype superclass = depth < myDepth ? superclasses[depth] : null;
    if (superclass != null && superclass.classNode == type.classNode) {
      // This is a potential conflict.
      if (classBuilder.library.isNonNullableByDefault) {
        superclass = nnbdTopMergeSupertype(
            hierarchy.coreTypes,
            normSupertype(hierarchy.coreTypes, superclass),
            normSupertype(hierarchy.coreTypes, type));
        if (superclass == null) {
          // This is a conflict.
          // TODO(johnniwinther): Report errors here instead of through
          // the computation of the [ClassHierarchy].
          superclass = superclasses[depth];
        } else {
          superclasses[depth] = superclass;
        }
      }
      return;
    } else {
      for (int i = 0; i < interfaces.length; i++) {
        // This is a quadratic algorithm, but normally, the number of
        // interfaces is really small.
        Supertype interface = interfaces[i];
        if (interface.classNode == type.classNode) {
          // This is a potential conflict.
          if (classBuilder.library.isNonNullableByDefault) {
            interface = nnbdTopMergeSupertype(
                hierarchy.coreTypes,
                normSupertype(hierarchy.coreTypes, interface),
                normSupertype(hierarchy.coreTypes, type));
            if (interface == null) {
              // This is a conflict.
              // TODO(johnniwinther): Report errors here instead of through
              // the computation of the [ClassHierarchy].
              interface = interfaces[i];
            } else {
              interfaces[i] = interface;
            }
          }
          return;
        }
      }
    }
    interfaces.add(type);
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
    NamedTypeBuilder mixedInTypeBuilder = classBuilder.mixedInTypeBuilder;
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
  final Map<Name, ClassMember> classMemberMap;

  /// Similar to [classMembers] but for setters.
  final Map<Name, ClassMember> classSetterMap;

  /// All the interface members of this class including [interfaceMembers] of
  /// its supertypes. The members are sorted by [compareDeclarations].
  ///
  /// In addition to the members of [classMembers] this also contains members
  /// from interfaces.
  ///
  /// This may be null, in which case [classMembers] is the interface members.
  final Map<Name, ClassMember> interfaceMemberMap;

  /// Similar to [interfaceMembers] but for setters.
  ///
  /// This may be null, in which case [classSetters] is the interface setters.
  final Map<Name, ClassMember> interfaceSetterMap;

  /// All superclasses of [classBuilder] excluding itself. The classes are
  /// sorted by depth from the root (Object) in ascending order.
  final List<Supertype> superclasses;

  /// The list of all classes implemented by [classBuilder] and its supertypes
  /// excluding any classes from [superclasses].
  final List<Supertype> interfaces;

  /// The longest inheritance path from [classBuilder] to `Object`.
  final int maxInheritancePath;

  int get depth => superclasses.length;

  final bool hasNoSuchMethod;

  ClassHierarchyNode(
      this.classBuilder,
      this.classMemberMap,
      this.classSetterMap,
      this.interfaceMemberMap,
      this.interfaceSetterMap,
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
      Supertype type = superclasses[i];
      result[i] = hierarchy.getNodeFromClass(type.classNode);
    }
    for (int i = 0; i < interfaces.length; i++) {
      Supertype type = interfaces[i];
      result[i + superclasses.length] =
          hierarchy.getNodeFromClass(type.classNode);
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
    for (Supertype superclass in superclasses) {
      sb.write("  " * (depth + 2));
      if (depth != 0) sb.write("-> ");
      sb.write(typeToText(superclass.asInterfaceType));
      sb.writeln();
      depth++;
    }
    if (interfaces != null) {
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
    printMemberMap(classMemberMap, sb, "classMembers");
    printMemberMap(classSetterMap, sb, "classSetters");
    if (interfaceMemberMap != null) {
      printMemberMap(interfaceMemberMap, sb, "interfaceMembers");
    }
    if (interfaceSetterMap != null) {
      printMemberMap(interfaceSetterMap, sb, "interfaceSetters");
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

  void printMemberMap(
      Map<Name, ClassMember> memberMap, StringBuffer sb, String heading) {
    List<ClassMember> members = memberMap.values.toList();
    members.sort(compareDeclarations);
    printMembers(members, sb, heading);
  }

  ClassMember getInterfaceMember(Name name, bool isSetter) {
    return isSetter
        ? (interfaceSetterMap ?? classSetterMap)[name]
        : (interfaceMemberMap ?? classMemberMap)[name];
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
    return isSetter ? classSetterMap[name] : classMemberMap[name];
  }

  static int compareMaxInheritancePath(
      ClassHierarchyNode a, ClassHierarchyNode b) {
    return b.maxInheritancePath.compareTo(a.maxInheritancePath);
  }
}

List<LocatedMessage> _inheritedConflictContext(ClassMember a, ClassMember b) {
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
    return hierarchy.getTypeAsInstanceOf(
        type, superclass, clientLibrary, coreTypes);
  }

  @override
  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    return hierarchy.getTypeArgumentsAsInstanceOf(type, superclass);
  }

  @override
  InterfaceType futureType(DartType type, Nullability nullability) {
    return new InterfaceType(
        hierarchy.futureClass, nullability, <DartType>[type]);
  }

  @override
  bool isSubtypeOf(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    return hierarchy.types.isSubtypeOf(subtype, supertype, mode);
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
  final ClassMember declaredMember;
  final ClassMember overriddenMember;

  const DelayedOverrideCheck(
      this.classBuilder, this.declaredMember, this.overriddenMember);

  void check(ClassHierarchyBuilder hierarchy) {
    void callback(
        Member declaredMember, Member interfaceMember, bool isSetter) {
      classBuilder.checkOverride(
          hierarchy.types, declaredMember, interfaceMember, isSetter, callback,
          isInterfaceCheck: !classBuilder.isMixinApplication);
    }

    debug?.log("Delayed override check of ${declaredMember.fullName} "
        "${overriddenMember.fullName} wrt. ${classBuilder.fullNameForErrors}");
    callback(declaredMember.getMember(hierarchy),
        overriddenMember.getMember(hierarchy), declaredMember.isSetter);
  }
}

class DelayedTypeComputation {
  final ClassHierarchyNodeBuilder builder;
  final ClassMember declaredMember;
  final Set<ClassMember> overriddenMembers;
  bool _computed = false;

  DelayedTypeComputation(
      this.builder, this.declaredMember, this.overriddenMembers)
      : assert(declaredMember.isSourceDeclaration);

  void compute(ClassHierarchyBuilder hierarchy) {
    if (_computed) return;
    declaredMember.inferType(hierarchy);
    _computed = true;
    if (declaredMember.isField) {
      builder.inferFieldSignature(hierarchy, declaredMember, overriddenMembers);
    } else if (declaredMember.isGetter) {
      builder.inferGetterSignature(
          hierarchy, declaredMember, overriddenMembers);
    } else if (declaredMember.isSetter) {
      builder.inferSetterSignature(
          hierarchy, declaredMember, overriddenMembers);
    } else {
      builder.inferMethodSignature(
          hierarchy, declaredMember, overriddenMembers);
    }
  }

  @override
  String toString() => 'DelayedTypeComputation('
      '${builder.classBuilder.name},$declaredMember,$overriddenMembers)';
}

abstract class DelayedMember implements ClassMember {
  /// The class which has inherited [declarations].
  @override
  final ClassBuilder classBuilder;

  bool get hasDeclarations => true;

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
  bool get isSourceDeclaration => false;

  @override
  bool get needsComputation => true;

  @override
  bool get isSynthesized => true;

  @override
  bool get isInternalImplementation => false;

  @override
  bool get forSetter => isSetter;

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

  DelayedMember withParent(ClassBuilder parent);

  @override
  ClassMember get abstract => this;

  @override
  ClassMember get concrete => this;

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
  void inferType(ClassHierarchyBuilder hierarchy) {
    // Do nothing; this is only for declared members.
  }

  @override
  void registerOverrideDependency(ClassMember overriddenMember) {
    // Do nothing; this is only for declared members.
  }

  @override
  int get hashCode {
    int hash = classBuilder.hashCode * 13 +
        isSetter.hashCode * 17 +
        isProperty.hashCode * 19 +
        modifyKernel.hashCode * 23 +
        name.hashCode * 29;
    for (ClassMember declaration in declarations) {
      hash ^= declaration.hashCode;
    }
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DelayedMember &&
        classBuilder == other.classBuilder &&
        isSetter == other.isSetter &&
        isProperty == other.isProperty &&
        modifyKernel == other.modifyKernel &&
        name == other.name &&
        declarations.length == other.declarations.length &&
        _equalsList(declarations, other.declarations, declarations.length);
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
  int get hashCode => super.hashCode + isInheritableConflict.hashCode * 11;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return super == other &&
        other is InheritedImplementationInterfaceConflict &&
        isInheritableConflict == other.isInheritableConflict;
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
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
        .getMember(hierarchy);
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
    if (concreteImplementation.hasDeclarations &&
        concreteImplementation.classBuilder == parent) {
      addAllDeclarationsTo(concreteImplementation, declarations);
    } else {
      declarations.add(concreteImplementation);
    }
    if (other.hasDeclarations && other.classBuilder == parent) {
      addAllDeclarationsTo(other, declarations);
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

  @override
  int get hashCode {
    int hash = super.hashCode;
    hash ^= isImplicitlyAbstract.hashCode;
    for (ClassMember declaration in declarations) {
      hash ^= declaration.hashCode;
    }
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return super == other &&
        other is InterfaceConflict &&
        isImplicitlyAbstract == other.isImplicitlyAbstract;
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
    InterfaceType instance = hierarchy.getTypeAsInstanceOf(
        thisType,
        member.enclosingClass,
        classBuilder.library.library,
        hierarchy.coreTypes);
    assert(
        instance != null,
        "No instance of $thisType as ${member.enclosingClass} found for "
        "$member.");
    return Substitution.fromInterfaceType(instance).substituteType(type);
  }

  bool isMoreSpecific(ClassHierarchyBuilder hierarchy, DartType a, DartType b) {
    if (isSetter) {
      return hierarchy.types
          .isSubtypeOf(b, a, SubtypeCheckMode.withNullabilities);
    } else {
      return hierarchy.types
          .isSubtypeOf(a, b, SubtypeCheckMode.withNullabilities);
    }
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    if (combinedMemberSignatureResult != null) {
      return combinedMemberSignatureResult;
    }
    if (classBuilder.library is! SourceLibraryBuilder) {
      return combinedMemberSignatureResult =
          declarations.first.getMember(hierarchy);
    }
    bool isNonNullableByDefault = classBuilder.library.isNonNullableByDefault;
    DartType thisType = hierarchy.coreTypes
        .thisInterfaceType(classBuilder.cls, classBuilder.library.nonNullable);
    List<DartType> candidateTypes = new List<DartType>(declarations.length);
    ClassMember bestSoFar;
    int bestSoFarIndex;
    DartType bestTypeSoFar;
    Map<DartType, int> mutualSubtypes;
    for (int candidateIndex = declarations.length - 1;
        candidateIndex >= 0;
        candidateIndex--) {
      ClassMember candidate = declarations[candidateIndex];
      Member target = candidate.getMember(hierarchy);
      assert(target != null,
          "No member computed for ${candidate} (${candidate.runtimeType})");
      DartType candidateType = computeMemberType(hierarchy, thisType, target);
      if (!isNonNullableByDefault) {
        candidateType = legacyErasure(hierarchy.coreTypes, candidateType);
      }
      candidateTypes[candidateIndex] = candidateType;
      if (bestSoFar == null) {
        bestSoFar = candidate;
        bestTypeSoFar = candidateType;
        bestSoFarIndex = candidateIndex;
      } else {
        if (isMoreSpecific(hierarchy, candidateType, bestTypeSoFar)) {
          debug?.log("Combined Member Signature: ${candidate.fullName} "
              "${candidateType} <: ${bestSoFar.fullName} ${bestTypeSoFar}");
          if (isNonNullableByDefault &&
              isMoreSpecific(hierarchy, bestTypeSoFar, candidateType)) {
            if (mutualSubtypes == null) {
              mutualSubtypes = {
                bestTypeSoFar: bestSoFarIndex,
                candidateType: candidateIndex
              };
            } else {
              mutualSubtypes[candidateType] = candidateIndex;
            }
          } else {
            mutualSubtypes = null;
          }
          bestSoFarIndex = candidateIndex;
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
      for (int candidateIndex = 0;
          candidateIndex < declarations.length;
          candidateIndex++) {
        ClassMember candidate = declarations[candidateIndex];
        DartType candidateType = candidateTypes[candidateIndex];
        if (!isMoreSpecific(hierarchy, bestTypeSoFar, candidateType)) {
          debug?.log("Combined Member Signature: "
              "${bestSoFar.fullName} !<: ${candidate.fullName}");

          if (!shouldOverrideProblemBeOverlooked(classBuilder)) {
            bestSoFar = null;
            bestTypeSoFar = null;
            mutualSubtypes = null;
          }
          break;
        }
      }
    }
    if (bestSoFar == null) {
      String name = classBuilder.fullNameForErrors;
      int length = classBuilder.isAnonymousMixinApplication ? 1 : name.length;
      List<LocatedMessage> context = declarations.map((ClassMember d) {
        return messageDeclaredMemberConflictsWithInheritedMembersCause
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
              hierarchy,
              classBuilder,
              bestSoFar,
              bestSoFarIndex,
              declarations,
              kind,
              mutualSubtypes?.values?.toSet())
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
        return combinedMemberSignatureResult = stub;
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
    if (a.hasDeclarations && a.classBuilder == parent) {
      addAllDeclarationsTo(a, declarations);
    } else {
      declarations.add(a);
    }
    if (b.hasDeclarations && b.classBuilder == parent) {
      addAllDeclarationsTo(b, declarations);
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

  @override
  ClassMember get concrete {
    if (isAbstract) {
      return declarations.first.concrete;
    }
    return this;
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

  bool _isChecked = false;

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    if (!_isChecked) {
      _isChecked = true;
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
        new ForwardingNode(hierarchy, classBuilder, abstractMember, 1,
                declarations, kind, null)
            .finalize();
      }
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return super == other && other is AbstractMemberOverridingImplementation;
  }

  @override
  ClassMember get abstract => abstractMember;

  @override
  ClassMember get concrete => concreteImplementation;
}

void addDeclarationIfDifferent(
    ClassMember declaration, List<ClassMember> declarations) {
  for (int i = 0; i < declarations.length; i++) {
    if (declaration == declarations[i]) return;
  }
  declarations.add(declaration);
}

void addAllDeclarationsTo(ClassMember member, List<ClassMember> declarations) {
  assert(member.hasDeclarations);
  for (int i = 0; i < member.declarations.length; i++) {
    addDeclarationIfDifferent(member.declarations[i], declarations);
  }
  assert(declarations.toSet().length == declarations.length);
}

int compareNamedParameters(VariableDeclaration a, VariableDeclaration b) {
  return a.name.compareTo(b.name);
}

void reportCantInferParameterType(
    ClassBuilder cls,
    FormalParameterBuilder parameter,
    ClassHierarchyBuilder hierarchy,
    Iterable<ClassMember> overriddenMembers) {
  String name = parameter.name;
  List<LocatedMessage> context = overriddenMembers
      .map((ClassMember overriddenMember) {
        return messageDeclaredMemberConflictsWithInheritedMembersCause
            .withLocation(overriddenMember.fileUri, overriddenMember.charOffset,
                overriddenMember.fullNameForErrors.length);
      })
      // Call toSet to avoid duplicate context for instance of fields that are
      // overridden both as getters and setters.
      .toSet()
      .toList();
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      parameter.charOffset,
      name.length,
      wasHandled: true,
      context: context);
}

void reportCantInferReturnType(ClassBuilder cls, SourceProcedureBuilder member,
    ClassHierarchyBuilder hierarchy, Iterable<ClassMember> overriddenMembers) {
  String name = member.fullNameForErrors;
  List<LocatedMessage> context = overriddenMembers
      .map((ClassMember overriddenMember) {
        return messageDeclaredMemberConflictsWithInheritedMembersCause
            .withLocation(overriddenMember.fileUri, overriddenMember.charOffset,
                overriddenMember.fullNameForErrors.length);
      })
      // Call toSet to avoid duplicate context for instance of fields that are
      // overridden both as getters and setters.
      .toSet()
      .toList();
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

void reportCantInferFieldType(ClassBuilder cls, SourceFieldBuilder member,
    Iterable<ClassMember> overriddenMembers) {
  List<LocatedMessage> context = overriddenMembers
      .map((ClassMember overriddenMember) {
        return messageDeclaredMemberConflictsWithInheritedMembersCause
            .withLocation(overriddenMember.fileUri, overriddenMember.charOffset,
                overriddenMember.fullNameForErrors.length);
      })
      // Call toSet to avoid duplicate context for instance of fields that are
      // overridden both as getters and setters.
      .toSet()
      .toList();
  String name = member.fullNameForErrors;
  cls.addProblem(
      templateCantInferTypeDueToInconsistentOverrides.withArguments(name),
      member.charOffset,
      name.length,
      wasHandled: true,
      context: context);
}

ClassBuilder getClass(TypeBuilder type) {
  Builder declaration = type.declaration;
  if (declaration is TypeAliasBuilder) {
    TypeAliasBuilder aliasBuilder = declaration;
    NamedTypeBuilder namedBuilder = type;
    declaration = aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
  }
  return declaration is ClassBuilder ? declaration : null;
}

/// Returns `true` if the first [length] elements of [a] and [b] are the same.
bool _equalsList<T>(List<T> a, List<T> b, int length) {
  if (a.length < length || b.length < length) return false;
  for (int index = 0; index < length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

Set<ClassMember> toSet(
    ClassBuilder classBuilder, Iterable<ClassMember> members) {
  Set<ClassMember> result = <ClassMember>{};
  _toSet(classBuilder, members, result);
  return result;
}

void _toSet(ClassBuilder classBuilder, Iterable<ClassMember> members,
    Set<ClassMember> result) {
  for (ClassMember member in members) {
    if (member.hasDeclarations &&
        (!useConsolidated || classBuilder == member.classBuilder)) {
      _toSet(classBuilder, member.declarations, result);
    } else {
      result.add(member);
    }
  }
}
