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
import 'package:kernel/src/standard_bounds.dart';
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

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        LocatedMessage,
        Message,
        messageDeclaredMemberConflictsWithInheritedMember,
        messageDeclaredMemberConflictsWithInheritedMemberCause,
        messageDeclaredMemberConflictsWithOverriddenMembersCause,
        messageInheritedMembersConflict,
        messageInheritedMembersConflictCause1,
        messageInheritedMembersConflictCause2,
        messageStaticAndInstanceConflict,
        messageStaticAndInstanceConflictCause,
        templateCantInferTypesDueToNoCombinedSignature,
        templateCantInferReturnTypeDueToNoCombinedSignature,
        templateCantInferTypeDueToNoCombinedSignature,
        templateCombinedMemberSignatureFailed,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateDuplicatedDeclarationUse,
        templateMissingImplementationCause,
        templateMissingImplementationNotAbstract;

import '../names.dart' show noSuchMethodName;

import '../problems.dart';
import '../scope.dart' show Scope;

import '../source/source_class_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/source_loader.dart' show SourceLoader;

import '../type_inference/standard_bounds.dart' show TypeSchemaStandardBounds;

import '../type_inference/type_constraint_gatherer.dart'
    show TypeConstraintGatherer;

import '../type_inference/type_inferrer.dart' show MixinInferrer;

import '../type_inference/type_schema.dart' show UnknownType;

import '../type_inference/type_schema_environment.dart' show TypeConstraint;

import 'combined_member_signature.dart';

import 'member_covariance.dart';

import 'forwarding_node.dart' show ForwardingNode;

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
  ClassMember mixedInMember;
  ClassMember mixedInSetter;
  ClassMember extendedMember;
  ClassMember extendedSetter;
  List<ClassMember> implementedMembers;
  List<ClassMember> implementedSetters;

  Tuple.declareMember(this.declaredMember)
      : assert(!declaredMember.forSetter),
        this.name = declaredMember.name;

  Tuple.mixInMember(this.mixedInMember)
      : assert(!mixedInMember.forSetter),
        this.name = mixedInMember.name;

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

  Tuple.mixInSetter(this.mixedInSetter)
      : assert(mixedInSetter.forSetter),
        this.name = mixedInSetter.name;

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
    if (mixedInMember != null) {
      sb.write(comma);
      sb.write('mixedInMember=');
      sb.write(mixedInMember);
      comma = ',';
    }
    if (mixedInSetter != null) {
      sb.write(comma);
      sb.write('mixedInSetter=');
      sb.write(mixedInSetter);
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

  /// Returns the member [Covariance] for this class member.
  Covariance getCovariance(ClassHierarchyBuilder hierarchy);

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

  void inferType(ClassHierarchyBuilder hierarchy);
  void registerOverrideDependency(Set<ClassMember> overriddenMembers);

  /// Returns `true` if this has the same underlying declaration as [other].
  bool isSameDeclaration(ClassMember other);
}

bool hasSameSignature(FunctionNode a, FunctionNode b) {
  List<TypeParameter> aTypeParameters = a.typeParameters;
  List<TypeParameter> bTypeParameters = b.typeParameters;
  int typeParameterCount = aTypeParameters.length;
  if (typeParameterCount != bTypeParameters.length) return false;
  Substitution substitution;
  if (typeParameterCount != 0) {
    List<DartType> types = new List<DartType>.filled(typeParameterCount, null);
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

  final List<DelayedTypeComputation> _delayedTypeComputations =
      <DelayedTypeComputation>[];

  final List<DelayedCheck> _delayedChecks = <DelayedCheck>[];

  final List<ClassMember> _delayedMemberComputations = <ClassMember>[];

  final CoreTypes coreTypes;

  Types types;

  ClassHierarchyBuilder(this.objectClassBuilder, this.loader, this.coreTypes)
      : objectClass = objectClassBuilder.cls,
        futureClass = coreTypes.futureClass,
        functionClass = coreTypes.functionClass {
    types = new Types(this);
  }

  void clear() {
    nodes.clear();
    substitutions.clear();
    _delayedChecks.clear();
    _delayedTypeComputations.clear();
    _delayedMemberComputations.clear();
  }

  void registerDelayedTypeComputation(DelayedTypeComputation computation) {
    _delayedTypeComputations.add(computation);
  }

  void registerOverrideCheck(
      SourceClassBuilder classBuilder, ClassMember a, ClassMember b) {
    _delayedChecks.add(new DelayedOverrideCheck(classBuilder, a, b));
  }

  void registerGetterSetterCheck(
      SourceClassBuilder classBuilder, ClassMember getter, ClassMember setter) {
    _delayedChecks
        .add(new DelayedGetterSetterCheck(classBuilder, getter, setter));
  }

  void registerMemberComputation(ClassMember member) {
    _delayedMemberComputations.add(member);
  }

  List<DelayedTypeComputation> takeDelayedTypeComputations() {
    List<DelayedTypeComputation> list = _delayedTypeComputations.toList();
    _delayedTypeComputations.clear();
    return list;
  }

  List<DelayedCheck> takeDelayedChecks() {
    List<DelayedCheck> list = _delayedChecks.toList();
    _delayedChecks.clear();
    return list;
  }

  List<ClassMember> takeDelayedMemberComputations() {
    List<ClassMember> list = _delayedMemberComputations.toList();
    _delayedMemberComputations.clear();
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

  InterfaceType getTypeAsInstanceOf(
      InterfaceType type, Class superclass, Library clientLibrary) {
    if (type.classNode == superclass) return type;
    return asSupertypeOf(type, superclass)
        .asInterfaceType
        .withDeclaredNullability(type.nullability);
  }

  List<DartType> getTypeArgumentsAsInstanceOf(
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

  Member getInterfaceMember(Class cls, Name name, {bool setter: false}) {
    return getNodeFromClass(cls)
        .getInterfaceMember(name, setter)
        ?.getMember(this);
  }

  Member getDispatchTargetKernel(Class cls, Name name, bool isSetter) {
    ClassMember classMember =
        getNodeFromClass(cls).getDispatchTarget(name, isSetter);
    Member member = classMember?.getMember(this);
    if (member != null && member.isAbstract) {
      if (cls.superclass != null) {
        return getDispatchTargetKernel(cls.superclass, name, isSetter);
      } else {
        return null;
      }
    }
    return member;
  }

  Member getCombinedMemberSignatureKernel(Class cls, Name name, bool isSetter,
      int charOffset, SourceLibraryBuilder library) {
    ClassMember declaration =
        getNodeFromClass(cls).getInterfaceMember(name, isSetter);
    if (declaration?.isStatic ?? true) return null;
    if (declaration.isDuplicate) {
      library?.addProblem(
          templateDuplicatedDeclarationUse.withArguments(name.text),
          charOffset,
          name.text.length,
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
    if (a.isStatic || a.isProperty != b.isProperty) {
      reportInheritanceConflict(a, b);
      return a;
    }
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

      Set<ClassMember> overriddenMemberSet =
          toSet(declaredMember.classBuilder, overriddenMembers);
      CombinedClassMemberSignature combinedMemberSignature =
          new CombinedClassMemberSignature(
              hierarchy, classBuilder, overriddenMemberSet.toList(),
              forSetter: false);
      FunctionType combinedMemberSignatureType = combinedMemberSignature
          .getCombinedSignatureTypeInContext(declaredTypeParameters);

      bool cantInferReturnType = false;
      List<FormalParameterBuilder> cantInferParameterTypes;

      if (declaredMember.returnType == null) {
        if (combinedMemberSignatureType == null) {
          inferredReturnType = const InvalidType();
          cantInferReturnType = true;
        } else {
          inferredReturnType = combinedMemberSignatureType.returnType;
        }
      }
      if (declaredMember.formals != null) {
        for (int i = 0; i < declaredPositional.length; i++) {
          FormalParameterBuilder declaredParameter = declaredMember.formals[i];
          if (declaredParameter.type != null) {
            continue;
          }

          DartType inferredParameterType;
          if (combinedMemberSignatureType == null) {
            inferredParameterType = const InvalidType();
            cantInferParameterTypes ??= [];
            cantInferParameterTypes.add(declaredParameter);
          } else if (i <
              combinedMemberSignatureType.positionalParameters.length) {
            inferredParameterType =
                combinedMemberSignatureType.positionalParameters[i];
          }
          inferredParameterTypes[declaredParameter] = inferredParameterType;
        }

        Map<String, DartType> namedParameterTypes;
        for (int i = declaredPositional.length;
            i < declaredMember.formals.length;
            i++) {
          FormalParameterBuilder declaredParameter = declaredMember.formals[i];
          if (declaredParameter.type != null) {
            continue;
          }

          DartType inferredParameterType;
          if (combinedMemberSignatureType == null) {
            inferredParameterType = const InvalidType();
            cantInferParameterTypes ??= [];
            cantInferParameterTypes.add(declaredParameter);
          } else {
            if (namedParameterTypes == null) {
              namedParameterTypes = {};
              for (NamedType namedType
                  in combinedMemberSignatureType.namedParameters) {
                namedParameterTypes[namedType.name] = namedType.type;
              }
            }
            inferredParameterType = namedParameterTypes[declaredParameter.name];
          }
          inferredParameterTypes[declaredParameter] = inferredParameterType;
        }
      }

      if ((cantInferReturnType && cantInferParameterTypes != null) ||
          (cantInferParameterTypes != null &&
              cantInferParameterTypes.length > 1)) {
        reportCantInferTypes(
            classBuilder, declaredMember, hierarchy, overriddenMembers);
      } else if (cantInferReturnType) {
        reportCantInferReturnType(
            classBuilder, declaredMember, hierarchy, overriddenMembers);
      } else if (cantInferParameterTypes != null) {
        reportCantInferParameterType(classBuilder,
            cantInferParameterTypes.single, hierarchy, overriddenMembers);
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
    for (ClassMember overriddenMember
        in toSet(declaredMember.classBuilder, overriddenMembers)) {
      Covariance covariance = overriddenMember.getCovariance(hierarchy);
      covariance.applyCovariance(declaredProcedure);
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
    for (ClassMember overriddenMember
        in toSet(declaredMember.classBuilder, overriddenMembers)) {
      Covariance covariance = overriddenMember.getCovariance(hierarchy);
      covariance.applyCovariance(declaredSetter);
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
      overriddenMembers = toSet(classBuilder, overriddenMembers);

      List<ClassMember> overriddenGetters = [];
      List<ClassMember> overriddenSetters = [];
      for (ClassMember overriddenMember in overriddenMembers) {
        if (overriddenMember.forSetter) {
          overriddenSetters.add(overriddenMember);
        } else {
          overriddenGetters.add(overriddenMember);
        }
      }

      void inferFrom(List<ClassMember> members, {bool forSetter}) {
        assert(forSetter != null);
        CombinedClassMemberSignature combinedMemberSignature =
            new CombinedClassMemberSignature(hierarchy, classBuilder, members,
                forSetter: forSetter);
        DartType combinedMemberSignatureType =
            combinedMemberSignature.combinedMemberSignatureType;
        if (combinedMemberSignatureType == null) {
          inferredType = const InvalidType();
          reportCantInferReturnType(
              classBuilder, declaredMember, hierarchy, members);
        } else {
          inferredType = combinedMemberSignatureType;
        }
      }

      if (overriddenGetters.isNotEmpty) {
        // 1) The return type of a getter, parameter type of a setter or type
        // of a field which overrides/implements only one or more getters is
        // inferred to be the return type of the combined member signature of
        // said getter in the direct superinterfaces.

        // 2) The return type of a getter which overrides/implements both a
        // setter and a getter is inferred to be the return type of the
        // combined member signature of said getter in the direct
        // superinterfaces.
        inferFrom(overriddenGetters, forSetter: false);
      } else {
        // The return type of a getter, parameter type of a setter or type of
        // a field which overrides/implements only one or more setters is
        // inferred to be the parameter type of the combined member signature
        // of said setter in the direct superinterfaces.
        inferFrom(overriddenSetters, forSetter: true);
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

      overriddenMembers = toSet(classBuilder, overriddenMembers);

      List<ClassMember> overriddenGetters = [];
      List<ClassMember> overriddenSetters = [];
      for (ClassMember overriddenMember in overriddenMembers) {
        if (overriddenMember.forSetter) {
          overriddenSetters.add(overriddenMember);
        } else {
          overriddenGetters.add(overriddenMember);
        }
      }

      void inferFrom(List<ClassMember> members, {bool forSetter}) {
        assert(forSetter != null);
        CombinedClassMemberSignature combinedMemberSignature =
            new CombinedClassMemberSignature(hierarchy, classBuilder, members,
                forSetter: forSetter);
        DartType combinedMemberSignatureType =
            combinedMemberSignature.combinedMemberSignatureType;
        if (combinedMemberSignatureType == null) {
          inferredType = const InvalidType();
          reportCantInferReturnType(
              classBuilder, declaredMember, hierarchy, members);
        } else {
          inferredType = combinedMemberSignatureType;
        }
      }

      if (overriddenSetters.isNotEmpty) {
        // 1) The return type of a getter, parameter type of a setter or type
        // of a field which overrides/implements only one or more setters is
        // inferred to be the parameter type of the combined member signature
        // of said setter in the direct superinterfaces.
        //
        // 2) The parameter type of a setter which overrides/implements both a
        // setter and a getter is inferred to be the parameter type of the
        // combined member signature of said setter in the direct
        // superinterfaces.
        inferFrom(overriddenSetters, forSetter: true);
      } else {
        // The return type of a getter, parameter type of a setter or type of
        // a field which overrides/implements only one or more getters is
        // inferred to be the return type of the combined member signature of
        // said getter in the direct superinterfaces.
        inferFrom(overriddenGetters, forSetter: false);
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
      inheritedType = legacyErasure(inheritedType);
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

      overriddenMembers = toSet(classBuilder, overriddenMembers);
      List<ClassMember> overriddenGetters = [];
      List<ClassMember> overriddenSetters = [];
      for (ClassMember overriddenMember in overriddenMembers) {
        if (overriddenMember.forSetter) {
          overriddenSetters.add(overriddenMember);
        } else {
          overriddenGetters.add(overriddenMember);
        }
      }

      DartType inferFrom(List<ClassMember> members, {bool forSetter}) {
        assert(forSetter != null);
        CombinedClassMemberSignature combinedMemberSignature =
            new CombinedClassMemberSignature(hierarchy, classBuilder, members,
                forSetter: forSetter);
        return combinedMemberSignature.combinedMemberSignatureType;
      }

      DartType combinedMemberSignatureType;
      if (fieldBuilder.isAssignable &&
          overriddenGetters.isNotEmpty &&
          overriddenSetters.isNotEmpty) {
        // The type of a non-final field which overrides/implements both a
        // setter and a getter is inferred to be the parameter type of the
        // combined member signature of said setter in the direct
        // superinterfaces, if this type is the same as the return type of the
        // combined member signature of said getter in the direct
        // superinterfaces. If the types are not the same then inference fails
        // with an error.
        DartType getterType = inferFrom(overriddenGetters, forSetter: false);
        DartType setterType = inferFrom(overriddenSetters, forSetter: true);
        if (getterType == setterType) {
          combinedMemberSignatureType = getterType;
        }
      } else if (overriddenGetters.isNotEmpty) {
        // 1) The return type of a getter, parameter type of a setter or type
        // of a field which overrides/implements only one or more getters is
        // inferred to be the return type of the combined member signature of
        // said getter in the direct superinterfaces.
        //
        // 2) The type of a final field which overrides/implements both a
        // setter and a getter is inferred to be the return type of the
        // combined member signature of said getter in the direct
        // superinterfaces.
        combinedMemberSignatureType =
            inferFrom(overriddenGetters, forSetter: false);
      } else {
        // The return type of a getter, parameter type of a setter or type of
        // a field which overrides/implements only one or more setters is
        // inferred to be the parameter type of the combined member signature
        // of said setter in the direct superinterfaces.
        combinedMemberSignatureType =
            inferFrom(overriddenSetters, forSetter: true);
      }

      if (combinedMemberSignatureType == null) {
        inferredType = const InvalidType();
        reportCantInferFieldType(classBuilder, fieldBuilder, overriddenMembers);
      } else {
        inferredType = combinedMemberSignatureType;
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
      Covariance covariance = overriddenMember.getCovariance(hierarchy);
      covariance.applyCovariance(declaredField);
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
    if (member.hasDeclarations && classBuilder == member.classBuilder) {
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

    Map<Name, Tuple> memberMap = {};

    Scope scope = classBuilder.scope;

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

        for (MemberBuilder memberBuilder in scope.localMembers) {
          for (ClassMember classMember in memberBuilder.localMembers) {
            Tuple tuple = memberMap[classMember.name];
            if (tuple == null) {
              memberMap[classMember.name] = new Tuple.mixInMember(classMember);
            } else {
              tuple.mixedInMember = classMember;
            }
          }
          for (ClassMember classMember in memberBuilder.localSetters) {
            Tuple tuple = memberMap[classMember.name];
            if (tuple == null) {
              memberMap[classMember.name] = new Tuple.mixInSetter(classMember);
            } else {
              tuple.mixedInSetter = classMember;
            }
          }
        }

        for (MemberBuilder memberBuilder in scope.localSetters) {
          for (ClassMember classMember in memberBuilder.localMembers) {
            Tuple tuple = memberMap[classMember.name];
            if (tuple == null) {
              memberMap[classMember.name] = new Tuple.mixInMember(classMember);
            } else {
              tuple.mixedInMember = classMember;
            }
          }
          for (ClassMember classMember in memberBuilder.localSetters) {
            Tuple tuple = memberMap[classMember.name];
            if (tuple == null) {
              memberMap[classMember.name] = new Tuple.mixInSetter(classMember);
            } else {
              tuple.mixedInSetter = classMember;
            }
          }
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
      superclasses = new List<Supertype>.filled(0, null);
      interfaces = new List<Supertype>.filled(0, null);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;

      superclasses =
          new List<Supertype>.filled(supernode.superclasses.length + 1, null);
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
          superclasses[i] = legacyErasureSupertype(superclasses[i]);
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

    void registerOverrideCheck(
        ClassMember member, ClassMember overriddenMember) {
      if (classBuilder is SourceClassBuilder) {
        if (overriddenMember.hasDeclarations &&
            classBuilder == overriddenMember.classBuilder) {
          for (int i = 0; i < overriddenMember.declarations.length; i++) {
            hierarchy.registerOverrideCheck(
                classBuilder, member, overriddenMember.declarations[i]);
          }
        } else {
          hierarchy.registerOverrideCheck(
              classBuilder, member, overriddenMember);
        }
      }
    }

    memberMap.forEach((Name name, Tuple tuple) {
      Set<ClassMember> overriddenMembers = {};

      void registerOverrideDependency(
          ClassMember member, ClassMember overriddenMember) {
        if (classBuilder == member.classBuilder && member.isSourceDeclaration) {
          if (overriddenMember.hasDeclarations &&
              classBuilder == overriddenMember.classBuilder) {
            for (int i = 0; i < overriddenMember.declarations.length; i++) {
              registerOverrideDependency(
                  member, overriddenMember.declarations[i]);
            }
          } else {
            overriddenMembers.add(overriddenMember);
          }
        }
      }

      ClassMember computeClassMember(
          ClassMember declaredMember,
          ClassMember mixedInMember,
          ClassMember extendedMember,
          bool forSetter) {
        if (mixedInMember != null) {
          // TODO(johnniwinther): Handle members declared in mixin applications
          // correctly.
          declaredMember = null;
        }
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
                hierarchy.registerMemberComputation(result);
              }
            }
            assert(
                !(classBuilder.isMixinApplication &&
                    declaredMember.classBuilder != classBuilder),
                "Unexpected declared member ${declaredMember} in "
                "${classBuilder} from foreign class.");

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
        } else if (mixedInMember != null) {
          if (extendedMember != null && !extendedMember.isStatic) {
            if (mixedInMember == extendedMember) return mixedInMember;
            if (mixedInMember.isDuplicate || extendedMember.isDuplicate) {
              // Don't check overrides involving duplicated members.
              return mixedInMember;
            }
            ClassMember result =
                checkInheritanceConflict(mixedInMember, extendedMember);
            if (result != null) return result;
            assert(
                mixedInMember.isProperty == extendedMember.isProperty,
                "Unexpected member combination: "
                "$mixedInMember vs $extendedMember");
            result = mixedInMember;

            // [declaredMember] is a method declared in [cls]. This means it
            // defines the interface of this class regardless if its abstract.
            if (!mixedInMember.isSynthesized) {
              registerOverrideDependency(
                  mixedInMember, extendedMember.abstract);
              registerOverrideCheck(mixedInMember, extendedMember.abstract);
            }

            if (mixedInMember.isAbstract) {
              if (extendedMember.isAbstract) {
                recordAbstractMember(mixedInMember);
              } else {
                if (!classBuilder.isAbstract) {
                  // The interface of this class is [declaredMember]. But the
                  // implementation is [extendedMember]. So [extendedMember]
                  // must implement [declaredMember], unless [cls] is abstract.
                  registerOverrideCheck(extendedMember, mixedInMember);
                }
                ClassMember concrete = extendedMember.concrete;
                result = new AbstractMemberOverridingImplementation(
                    classBuilder,
                    mixedInMember,
                    concrete,
                    mixedInMember.isProperty,
                    forSetter,
                    shouldModifyKernel,
                    concrete.isAbstract,
                    concrete.name);
                hierarchy.registerMemberComputation(result);
              }
            } else {
              assert(
                  (classBuilder.isMixinApplication &&
                      mixedInMember.classBuilder != classBuilder),
                  "Unexpected mixed in member ${mixedInMember} in "
                  "${classBuilder} from the current class.");
              result = InheritedImplementationInterfaceConflict.combined(
                  classBuilder,
                  mixedInMember,
                  extendedMember,
                  forSetter,
                  shouldModifyKernel,
                  isInheritableConflict: false);
              if (result.needsComputation) {
                hierarchy.registerMemberComputation(result);
              }
            }

            if (result.name == noSuchMethodName &&
                !result.isObjectMember(objectClass)) {
              hasNoSuchMethod = true;
            }
            return result;
          } else {
            if (mixedInMember.isAbstract) {
              recordAbstractMember(mixedInMember);
            }
            return mixedInMember;
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
            hierarchy.registerMemberComputation(extendedMember);
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
              hierarchy.registerMemberComputation(extendedMember);
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
                      interfaceMember.classBuilder == classBuilder) {
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
                  hierarchy.registerMemberComputation(result);
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
                hierarchy.registerMemberComputation(interfaceMember);
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
                  hierarchy.registerMemberComputation(interfaceMember);
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
        if (overriddenMember.classBuilder == classBuilder &&
            overriddenMember.hasDeclarations) {
          for (ClassMember declaration in overriddenMember.declarations) {
            checkMemberVsSetter(member, declaration);
          }
          return;
        }

        if (classBuilder is! SourceClassBuilder) return;
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
            registerOverrideDependency(member, overriddenMember);
            hierarchy.registerOverrideCheck(
                classBuilder, member, overriddenMember);
          } else if (member is SourceProcedureMember) {
            registerOverrideDependency(member, overriddenMember);
            hierarchy.registerOverrideCheck(
                classBuilder, member, overriddenMember);
          }
        }
      }

      ClassMember classMember = computeClassMember(tuple.declaredMember,
          tuple.mixedInMember, tuple.extendedMember, false);
      ClassMember interfaceMember =
          computeInterfaceMember(classMember, tuple.implementedMembers, false);
      ClassMember classSetter = computeClassMember(tuple.declaredSetter,
          tuple.mixedInSetter, tuple.extendedSetter, true);
      ClassMember interfaceSetter =
          computeInterfaceMember(classSetter, tuple.implementedSetters, true);

      if ((tuple.mixedInMember != null || tuple.declaredMember != null) &&
          classSetter != null) {
        checkMemberVsSetter(
            tuple.mixedInMember ?? tuple.declaredMember, classSetter);
      }
      if ((tuple.mixedInSetter != null || tuple.declaredSetter != null) &&
          classMember != null) {
        checkMemberVsSetter(
            tuple.mixedInSetter ?? tuple.declaredSetter, classMember);
      }
      if (classMember != null && interfaceSetter != null) {
        checkMemberVsSetter(classMember, interfaceSetter);
      }
      if (classSetter != null && interfaceMember != null) {
        checkMemberVsSetter(classSetter, interfaceMember);
      }

      if (classMember != null &&
          interfaceMember != null &&
          classMember != interfaceMember) {
        if (classMember.isAbstract == interfaceMember.isAbstract) {
          // TODO(johnniwinther): Ensure that we don't have both class and
          //  interface members that can give rise to a forwarding stub in
          //  the current class. We might already have registered a delayed
          //  member computation for the [classMember] that we're replacing
          //  and therefore create two stubs for this member.
          classMember = interfaceMember;
        }
      }
      if (classSetter != null &&
          interfaceSetter != null &&
          classSetter != interfaceSetter) {
        if (classSetter.isAbstract == interfaceSetter.isAbstract) {
          // TODO(johnniwinther): Ensure that we don't have both class and
          //  interface members that can give rise to a forwarding stub in
          //  the current class. We might already have registered a delayed
          //  member computation for the [classMember] that we're replacing
          //  and therefore create two stubs for this member.
          classSetter = interfaceSetter;
        }
      }
      if (classBuilder is SourceClassBuilder) {
        ClassMember member = interfaceMember ?? classMember;
        ClassMember setter = interfaceSetter ?? classSetter;
        if (member != null &&
            setter != null &&
            member.isProperty &&
            setter.isProperty &&
            member.isStatic == setter.isStatic &&
            !member.isSameDeclaration(setter)) {
          hierarchy.registerGetterSetterCheck(classBuilder, member, setter);
        }
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
      if (overriddenMembers.isNotEmpty) {
        void registerOverrideDependencies(ClassMember member) {
          if (member != null &&
              member.classBuilder == classBuilder &&
              member.isSourceDeclaration) {
            member.registerOverrideDependency(overriddenMembers);
            DelayedTypeComputation computation =
                new DelayedTypeComputation(this, member, overriddenMembers);
            hierarchy.registerDelayedTypeComputation(computation);
          }
        }

        registerOverrideDependencies(
            tuple.mixedInMember ?? tuple.declaredMember);
        registerOverrideDependencies(
            tuple.mixedInSetter ?? tuple.declaredSetter);
      }
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
      List<DartType> typeArguments =
          new List<DartType>.filled(arguments.length, null);
      List<TypeParameter> typeParameters =
          new List<TypeParameter>.filled(arguments.length, null);
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

  void addInterface(List<Supertype> interfaces, List<Supertype> superclasses,
      Supertype type) {
    if (type == null) return null;
    if (!classBuilder.library.isNonNullableByDefault) {
      type = legacyErasureSupertype(type);
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
        new List<TypeBuilder>.filled(typeArguments.length, null);
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
    List<ClassHierarchyNode> result = new List<ClassHierarchyNode>.filled(
        1 + superclasses.length + interfaces.length, null);
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
    with StandardBounds, TypeSchemaStandardBounds {
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
    return hierarchy.getTypeAsInstanceOf(type, superclass, clientLibrary);
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
}

abstract class DelayedCheck {
  void check(ClassHierarchyBuilder hierarchy);
}

class DelayedOverrideCheck implements DelayedCheck {
  final SourceClassBuilder classBuilder;
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

class DelayedGetterSetterCheck implements DelayedCheck {
  final SourceClassBuilder classBuilder;
  final ClassMember getter;
  final ClassMember setter;

  const DelayedGetterSetterCheck(this.classBuilder, this.getter, this.setter);

  void check(ClassHierarchyBuilder hierarchy) {
    classBuilder.checkGetterSetter(hierarchy.types, getter.getMember(hierarchy),
        setter.getMember(hierarchy));
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
      this.isSetter, this.modifyKernel, this.isExplicitlyAbstract, this.name) {
    assert(declarations.every((element) => element.isProperty == isProperty),
        "isProperty mismatch for $this");
  }

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
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    // Do nothing; this is only for declared members.
  }
}

/// This represents a concrete implementation inherited from a superclass that
/// has conflicts with methods inherited from an interface. The concrete
/// implementation is the first element of [declarations].
class InheritedImplementationInterfaceConflict extends DelayedMember {
  Member _member;
  Covariance _covariance;
  final ClassMember concreteMember;

  @override
  final bool isInheritableConflict;

  InheritedImplementationInterfaceConflict(
      ClassBuilder parent,
      this.concreteMember,
      List<ClassMember> declarations,
      bool isProperty,
      bool isSetter,
      bool modifyKernel,
      bool isAbstract,
      Name name,
      {this.isInheritableConflict = true})
      : assert(!concreteMember.isAbstract),
        super(parent, declarations, isProperty, isSetter, modifyKernel,
            isAbstract, name);

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return concreteMember.isObjectMember(objectClass);
  }

  @override
  String toString() {
    return "InheritedImplementationInterfaceConflict("
        "${classBuilder.fullNameForErrors}, $concreteMember, "
        "[${declarations.join(', ')}])";
  }

  void _ensureMemberAndCovariance(ClassHierarchyBuilder hierarchy) {
    if (_member == null) {
      if (!classBuilder.isAbstract) {
        if (classBuilder is SourceClassBuilder) {
          for (int i = 0; i < declarations.length; i++) {
            if (concreteMember != declarations[i]) {
              new DelayedOverrideCheck(
                      classBuilder, concreteMember, declarations[i])
                  .check(hierarchy);
            }
          }
        }
      }
      InterfaceConflict interfaceConflict = new InterfaceConflict(classBuilder,
          declarations, isProperty, isSetter, modifyKernel, isAbstract, name);
      _member = interfaceConflict.getMember(hierarchy);
      _covariance = interfaceConflict.getCovariance(hierarchy);
    }
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _member;
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _covariance;
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new InheritedImplementationInterfaceConflict(parent, concreteMember,
            [this], isProperty, isSetter, modifyKernel, isAbstract, name);
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    // This could be more precise but it currently has no benefit.
    return identical(this, other);
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
          concreteImplementation.concrete,
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

  Member _member;
  Covariance _covariance;

  @override
  String toString() {
    return "InterfaceConflict(${classBuilder.fullNameForErrors}, "
        "[${declarations.join(', ')}])";
  }

  void _ensureMemberAndCovariance(ClassHierarchyBuilder hierarchy) {
    if (_member != null) {
      return;
    }
    if (classBuilder.library is! SourceLibraryBuilder) {
      _member = declarations.first.getMember(hierarchy);
      _covariance = declarations.first.getCovariance(hierarchy);
      return;
    }

    CombinedClassMemberSignature combinedMemberSignature =
        new CombinedClassMemberSignature(hierarchy, classBuilder, declarations,
            forSetter: isSetter);

    if (combinedMemberSignature.canonicalMember == null) {
      String name = classBuilder.fullNameForErrors;
      int length = classBuilder.isAnonymousMixinApplication ? 1 : name.length;
      List<LocatedMessage> context = declarations.map((ClassMember d) {
        return messageDeclaredMemberConflictsWithOverriddenMembersCause
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
      _member = declarations.first.getMember(hierarchy);
      _covariance = declarations.first.getCovariance(hierarchy);
      return;
    }
    debug?.log("Combined Member Signature of ${fullNameForErrors}: "
        "${combinedMemberSignature.canonicalMember.fullName}");

    if (modifyKernel) {
      ProcedureKind kind = ProcedureKind.Method;
      Member bestMemberSoFar =
          combinedMemberSignature.canonicalMember.getMember(hierarchy);
      if (combinedMemberSignature.canonicalMember.isProperty) {
        kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
      } else if (bestMemberSoFar is Procedure &&
          bestMemberSoFar.kind == ProcedureKind.Operator) {
        kind = ProcedureKind.Operator;
      }

      debug?.log("Combined Member Signature of ${fullNameForErrors}: new "
          "ForwardingNode($classBuilder, "
          "${combinedMemberSignature.canonicalMember}, "
          "$declarations, $kind)");
      Member stub =
          new ForwardingNode(combinedMemberSignature, kind).finalize();
      if (stub != null && classBuilder.cls == stub.enclosingClass) {
        if (stub is Procedure) {
          classBuilder.cls.addProcedure(stub);
        } else if (stub is Field) {
          classBuilder.cls.addField(stub);
        } else if (stub is Constructor) {
          classBuilder.cls.addConstructor(stub);
        } else if (stub is RedirectingFactoryConstructor) {
          classBuilder.cls.addRedirectingFactoryConstructor(stub);
        } else {
          unhandled("${stub.runtimeType}", "getMember", stub.fileOffset,
              stub.fileUri);
        }
        SourceLibraryBuilder library = classBuilder.library;
        Member bestMemberSoFar =
            combinedMemberSignature.canonicalMember.getMember(hierarchy);
        if (bestMemberSoFar is Procedure) {
          library.forwardersOrigins..add(stub)..add(bestMemberSoFar);
        }
        debug?.log("Combined Member Signature of ${fullNameForErrors}: "
            "added stub $stub");
        _member = stub;
        _covariance = combinedMemberSignature.combinedMemberSignatureCovariance;
        assert(
            _covariance ==
                new Covariance.fromMember(_member, forSetter: forSetter),
            "Unexpected covariance for combined members signature "
            "$_member. Found $_covariance, expected "
            "${new Covariance.fromMember(_member, forSetter: forSetter)}.");
        return;
      }
    }

    debug?.log(
        "Combined Member Signature of ${fullNameForErrors}: picked bestSoFar");
    _member = combinedMemberSignature.canonicalMember.getMember(hierarchy);
    _covariance = combinedMemberSignature.combinedMemberSignatureCovariance;
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _member;
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _covariance;
  }

  @override
  DelayedMember withParent(ClassBuilder parent) {
    return parent == this.classBuilder
        ? this
        : new InterfaceConflict(parent, [this], isProperty, isSetter,
            modifyKernel, isAbstract, name,
            isImplicitlyAbstract: isImplicitlyAbstract);
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    // This could be more precise but it currently has no benefit.
    return identical(this, other);
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

  void _ensureMemberAndCovariance(ClassHierarchyBuilder hierarchy) {
    if (!_isChecked) {
      _isChecked = true;
      if (!classBuilder.isAbstract &&
          !hierarchy.nodes[classBuilder.cls].hasNoSuchMethod) {
        if (classBuilder is SourceClassBuilder) {
          new DelayedOverrideCheck(
                  classBuilder, concreteImplementation, abstractMember)
              .check(hierarchy);
        }
      }

      ProcedureKind kind = ProcedureKind.Method;
      if (abstractMember.isProperty) {
        kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
      }
      if (modifyKernel) {
        // This call will add a body to the abstract method if needed for
        // isGenericCovariantImpl checks.
        new ForwardingNode(
                new CombinedClassMemberSignature.internal(
                    hierarchy, classBuilder, 1, declarations,
                    forSetter: isSetter),
                kind)
            .finalize();
      }
    }
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return abstractMember.getMember(hierarchy);
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return abstractMember.getCovariance(hierarchy);
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
  ClassMember get abstract => abstractMember;

  @override
  ClassMember get concrete => concreteImplementation;

  @override
  bool isSameDeclaration(ClassMember other) {
    if (identical(this, other)) return false;
    return other is AbstractMemberOverridingImplementation &&
        classBuilder == other.classBuilder &&
        abstract.isSameDeclaration(other.abstract) &&
        concrete.isSameDeclaration(other.concrete);
  }
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
        return messageDeclaredMemberConflictsWithOverriddenMembersCause
            .withLocation(overriddenMember.fileUri, overriddenMember.charOffset,
                overriddenMember.fullNameForErrors.length);
      })
      // Call toSet to avoid duplicate context for instance of fields that are
      // overridden both as getters and setters.
      .toSet()
      .toList();
  cls.addProblem(
      templateCantInferTypeDueToNoCombinedSignature.withArguments(name),
      parameter.charOffset,
      name.length,
      wasHandled: true,
      context: context);
}

void reportCantInferTypes(ClassBuilder cls, SourceProcedureBuilder member,
    ClassHierarchyBuilder hierarchy, Iterable<ClassMember> overriddenMembers) {
  String name = member.fullNameForErrors;
  List<LocatedMessage> context = overriddenMembers
      .map((ClassMember overriddenMember) {
        return messageDeclaredMemberConflictsWithOverriddenMembersCause
            .withLocation(overriddenMember.fileUri, overriddenMember.charOffset,
                overriddenMember.fullNameForErrors.length);
      })
      // Call toSet to avoid duplicate context for instance of fields that are
      // overridden both as getters and setters.
      .toSet()
      .toList();
  cls.addProblem(
      templateCantInferTypesDueToNoCombinedSignature.withArguments(name),
      member.charOffset,
      name.length,
      wasHandled: true,
      context: context);
}

void reportCantInferReturnType(ClassBuilder cls, SourceProcedureBuilder member,
    ClassHierarchyBuilder hierarchy, Iterable<ClassMember> overriddenMembers) {
  String name = member.fullNameForErrors;
  List<LocatedMessage> context = overriddenMembers
      .map((ClassMember overriddenMember) {
        return messageDeclaredMemberConflictsWithOverriddenMembersCause
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
      templateCantInferReturnTypeDueToNoCombinedSignature.withArguments(name),
      member.charOffset,
      name.length,
      wasHandled: true,
      context: context);
}

void reportCantInferFieldType(ClassBuilder cls, SourceFieldBuilder member,
    Iterable<ClassMember> overriddenMembers) {
  List<LocatedMessage> context = overriddenMembers
      .map((ClassMember overriddenMember) {
        return messageDeclaredMemberConflictsWithOverriddenMembersCause
            .withLocation(overriddenMember.fileUri, overriddenMember.charOffset,
                overriddenMember.fullNameForErrors.length);
      })
      // Call toSet to avoid duplicate context for instance of fields that are
      // overridden both as getters and setters.
      .toSet()
      .toList();
  String name = member.fullNameForErrors;
  cls.addProblem(
      templateCantInferTypeDueToNoCombinedSignature.withArguments(name),
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

Set<ClassMember> toSet(
    ClassBuilder classBuilder, Iterable<ClassMember> members) {
  Set<ClassMember> result = <ClassMember>{};
  _toSet(classBuilder, members, result);
  return result;
}

void _toSet(ClassBuilder classBuilder, Iterable<ClassMember> members,
    Set<ClassMember> result) {
  for (ClassMember member in members) {
    if (member.hasDeclarations && classBuilder == member.classBuilder) {
      _toSet(classBuilder, member.declarations, result);
    } else {
      result.add(member);
    }
  }
}
