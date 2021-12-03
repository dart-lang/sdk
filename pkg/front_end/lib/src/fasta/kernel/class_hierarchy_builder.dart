// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';

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

import '../../base/common.dart';
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
        templateMissingImplementationCause,
        templateMissingImplementationNotAbstract;

import '../names.dart' show noSuchMethodName;

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

const DebugLogger? debug =
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
  ClassMember? _declaredMember;
  ClassMember? _declaredSetter;
  ClassMember? _mixedInMember;
  ClassMember? _mixedInSetter;
  ClassMember? _extendedMember;
  ClassMember? _extendedSetter;
  List<ClassMember>? _implementedMembers;
  List<ClassMember>? _implementedSetters;

  Tuple.declareMember(ClassMember declaredMember)
      : assert(!declaredMember.forSetter),
        this._declaredMember = declaredMember,
        this.name = declaredMember.name;

  Tuple.mixInMember(ClassMember mixedInMember)
      : assert(!mixedInMember.forSetter),
        this._mixedInMember = mixedInMember,
        this.name = mixedInMember.name;

  Tuple.extendMember(ClassMember extendedMember)
      : assert(!extendedMember.forSetter),
        this._extendedMember = extendedMember,
        this.name = extendedMember.name;

  Tuple.implementMember(ClassMember implementedMember)
      : assert(!implementedMember.forSetter),
        this.name = implementedMember.name,
        _implementedMembers = <ClassMember>[implementedMember];

  Tuple.declareSetter(ClassMember declaredSetter)
      : assert(declaredSetter.forSetter),
        this._declaredSetter = declaredSetter,
        this.name = declaredSetter.name;

  Tuple.mixInSetter(ClassMember mixedInSetter)
      : assert(mixedInSetter.forSetter),
        this._mixedInSetter = mixedInSetter,
        this.name = mixedInSetter.name;

  Tuple.extendSetter(ClassMember extendedSetter)
      : assert(extendedSetter.forSetter),
        this._extendedSetter = extendedSetter,
        this.name = extendedSetter.name;

  Tuple.implementSetter(ClassMember implementedSetter)
      : assert(implementedSetter.forSetter),
        this.name = implementedSetter.name,
        _implementedSetters = <ClassMember>[implementedSetter];

  ClassMember? get declaredMember => _declaredMember;

  void set declaredMember(ClassMember? value) {
    assert(!value!.forSetter);
    assert(
        _declaredMember == null,
        "Declared member already set to $_declaredMember, "
        "trying to set it to $value.");
    _declaredMember = value;
  }

  ClassMember? get declaredSetter => _declaredSetter;

  void set declaredSetter(ClassMember? value) {
    assert(value!.forSetter);
    assert(
        _declaredSetter == null,
        "Declared setter already set to $_declaredSetter, "
        "trying to set it to $value.");
    _declaredSetter = value;
  }

  ClassMember? get extendedMember => _extendedMember;

  void set extendedMember(ClassMember? value) {
    assert(!value!.forSetter);
    assert(
        _extendedMember == null,
        "Extended member already set to $_extendedMember, "
        "trying to set it to $value.");
    _extendedMember = value;
  }

  ClassMember? get extendedSetter => _extendedSetter;

  void set extendedSetter(ClassMember? value) {
    assert(value!.forSetter);
    assert(
        _extendedSetter == null,
        "Extended setter already set to $_extendedSetter, "
        "trying to set it to $value.");
    _extendedSetter = value;
  }

  ClassMember? get mixedInMember => _mixedInMember;

  void set mixedInMember(ClassMember? value) {
    assert(!value!.forSetter);
    assert(
        _mixedInMember == null,
        "Mixed in member already set to $_mixedInMember, "
        "trying to set it to $value.");
    _mixedInMember = value;
  }

  ClassMember? get mixedInSetter => _mixedInSetter;

  void set mixedInSetter(ClassMember? value) {
    assert(value!.forSetter);
    assert(
        _mixedInSetter == null,
        "Mixed in setter already set to $_mixedInSetter, "
        "trying to set it to $value.");
    _mixedInSetter = value;
  }

  List<ClassMember>? get implementedMembers => _implementedMembers;

  void addImplementedMember(ClassMember value) {
    assert(!value.forSetter);
    _implementedMembers ??= <ClassMember>[];
    _implementedMembers!.add(value);
  }

  List<ClassMember>? get implementedSetters => _implementedSetters;

  void addImplementedSetter(ClassMember value) {
    assert(value.forSetter);
    _implementedSetters ??= <ClassMember>[];
    _implementedSetters!.add(value);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    String comma = '';
    sb.write('Tuple(');
    if (_declaredMember != null) {
      sb.write(comma);
      sb.write('declaredMember=');
      sb.write(_declaredMember);
      comma = ',';
    }
    if (_declaredSetter != null) {
      sb.write(comma);
      sb.write('declaredSetter=');
      sb.write(_declaredSetter);
      comma = ',';
    }
    if (_mixedInMember != null) {
      sb.write(comma);
      sb.write('mixedInMember=');
      sb.write(_mixedInMember);
      comma = ',';
    }
    if (_mixedInSetter != null) {
      sb.write(comma);
      sb.write('mixedInSetter=');
      sb.write(_mixedInSetter);
      comma = ',';
    }
    if (_extendedMember != null) {
      sb.write(comma);
      sb.write('extendedMember=');
      sb.write(_extendedMember);
      comma = ',';
    }
    if (_extendedSetter != null) {
      sb.write(comma);
      sb.write('extendedSetter=');
      sb.write(_extendedSetter);
      comma = ',';
    }
    if (_implementedMembers != null) {
      sb.write(comma);
      sb.write('implementedMembers=');
      sb.write(_implementedMembers);
      comma = ',';
    }
    if (_implementedSetters != null) {
      sb.write(comma);
      sb.write('implementedSetters=');
      sb.write(_implementedSetters);
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

  /// Returns `true` if this member corresponds to a declaration in the source
  /// code.
  bool get isSourceDeclaration;

  /// Returns `true` if this member is a field, getter or setter.
  bool get isProperty;

  /// Computes the [Member] node resulting from this class member.
  Member getMember(ClassHierarchyBuilder hierarchy);

  /// Returns the member [Covariance] for this class member.
  Covariance getCovariance(ClassHierarchyBuilder hierarchy);

  bool get isDuplicate;
  String get fullName;
  String get fullNameForErrors;
  ClassBuilder get classBuilder;

  /// Returns `true` if this class member is declared in Object from dart:core.
  bool isObjectMember(ClassBuilder objectClass);
  Uri get fileUri;
  int get charOffset;

  /// Returns `true` if this class member is an interface member.
  bool get isAbstract;

  /// Returns `true` if this member doesn't corresponds to a declaration in the
  /// source code.
  bool get isSynthesized;

  // If `true` this member is not part of the interface but only part of the
  // class members.
  //
  // This is `true` for instance for synthesized fields added for the late
  // lowering.
  bool get isInternalImplementation;

  /// Returns `true` if this member is composed from a list of class members
  /// accessible through [declarations].
  bool get hasDeclarations;

  /// If [hasDeclaration] is `true`, this returns the list of class members
  /// from which this class member is composed.
  ///
  /// This is used in [unfoldDeclarations] to retrieve all underlying member
  /// source declarations, and in [toSet] to retrieve all members used for
  /// this class member wrt. certain level of the hierarchy.
  /// TODO(johnniwinther): Can the use of [toSet] be replaced with a direct
  /// use of [declarations]?
  List<ClassMember> get declarations;

  /// The interface member corresponding to this member.
  ///
  /// If this member is declared on the source, the interface member is
  /// the member itself. For instance
  ///
  ///     abstract class Class {
  ///        void concreteMethod() {}
  ///        void abstractMethod();
  ///     }
  ///
  /// the interface members for `concreteMethod` and `abstractMethod` are the
  /// members themselves.
  ///
  /// If this member is a synthesized interface member, the
  /// interface member is the member itself. For instance
  ///
  ///     abstract class Interface1 {
  ///        void method() {}
  ///     }
  ///     abstract class Interface2 {
  ///        void method() {}
  ///     }
  ///     abstract class Class implements Interface1, Interface2 {}
  ///
  /// the interface member for `method` in `Class` is the synthesized interface
  /// member created for the implemented members `Interface1.method` and
  /// `Interface2.method`.
  ///
  /// If this member is a concrete member that implements an interface member,
  /// the interface member is the implemented interface member. For instance
  ///
  ///     class Super {
  ///        void method() {}
  ///     }
  ///     class Interface {
  ///        void method() {}
  ///     }
  ///     class Class extends Super implements Interface {}
  ///
  /// the interface member for `Super.method` implementing `method` in `Class`
  /// is the synthesized interface member created for the implemented members
  /// `Super.method` and `Interface.method`.
  ClassMember get interfaceMember;

  void inferType(ClassHierarchyBuilder hierarchy);
  void registerOverrideDependency(Set<ClassMember> overriddenMembers);

  /// Returns `true` if this has the same underlying declaration as [other].
  ///
  /// This is used for avoiding unnecessary checks and can this trivially
  /// return `false`.
  bool isSameDeclaration(ClassMember other);
}

bool hasSameSignature(FunctionNode a, FunctionNode b) {
  List<TypeParameter> aTypeParameters = a.typeParameters;
  List<TypeParameter> bTypeParameters = b.typeParameters;
  int typeParameterCount = aTypeParameters.length;
  if (typeParameterCount != bTypeParameters.length) {
    return false;
  }
  Substitution? substitution;
  if (typeParameterCount != 0) {
    List<DartType> types = new List<DartType>.generate(
        typeParameterCount,
        (int i) => new TypeParameterType.forAlphaRenaming(
            bTypeParameters[i], aTypeParameters[i]),
        growable: false);
    substitution = Substitution.fromPairs(bTypeParameters, types);
    for (int i = 0; i < typeParameterCount; i++) {
      DartType aBound = aTypeParameters[i].bound;
      DartType bBound = substitution.substituteType(bTypeParameters[i].bound);
      if (aBound != bBound) {
        return false;
      }
    }
  }

  if (a.requiredParameterCount != b.requiredParameterCount) {
    return false;
  }
  List<VariableDeclaration> aPositionalParameters = a.positionalParameters;
  List<VariableDeclaration> bPositionalParameters = b.positionalParameters;
  if (aPositionalParameters.length != bPositionalParameters.length) {
    return false;
  }
  for (int i = 0; i < aPositionalParameters.length; i++) {
    VariableDeclaration aParameter = aPositionalParameters[i];
    VariableDeclaration bParameter = bPositionalParameters[i];
    if (aParameter.isCovariantByDeclaration !=
        bParameter.isCovariantByDeclaration) {
      return false;
    }
    DartType aType = aParameter.type;
    DartType bType = bParameter.type;
    if (substitution != null) {
      bType = substitution.substituteType(bType);
    }
    if (aType != bType) return false;
  }

  List<VariableDeclaration> aNamedParameters = a.namedParameters;
  List<VariableDeclaration> bNamedParameters = b.namedParameters;
  if (aNamedParameters.length != bNamedParameters.length) {
    return false;
  }
  for (int i = 0; i < aNamedParameters.length; i++) {
    VariableDeclaration aParameter = aNamedParameters[i];
    VariableDeclaration bParameter = bNamedParameters[i];
    if (aParameter.isCovariantByDeclaration !=
        bParameter.isCovariantByDeclaration) {
      return false;
    }
    if (aParameter.name != bParameter.name) {
      return false;
    }
    DartType aType = aParameter.type;
    DartType bType = bParameter.type;
    if (substitution != null) {
      bType = substitution.substituteType(bType);
    }
    if (aType != bType) {
      return false;
    }
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
    _delayedChecks.clear();
    _delayedTypeComputations.clear();
    _delayedMemberComputations.clear();
  }

  void registerDelayedTypeComputation(DelayedTypeComputation computation) {
    _delayedTypeComputations.add(computation);
  }

  void registerOverrideCheck(SourceClassBuilder classBuilder,
      ClassMember declaredMember, Set<ClassMember> overriddenMembers) {
    _delayedChecks.add(new DelayedOverrideCheck(
        classBuilder, declaredMember, overriddenMembers));
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
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
  }

  void inferGetterType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassHierarchyNodeBuilder.inferGetterType(
        this,
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
  }

  void inferSetterType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassHierarchyNodeBuilder.inferSetterType(
        this,
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
  }

  void inferMethodType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassHierarchyNodeBuilder.inferMethodType(
        this,
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
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

  @override
  Member? getInterfaceMember(Class cls, Name name, {bool setter: false}) {
    return getNodeFromClass(cls)
        .getInterfaceMember(name, setter)
        ?.getMember(this);
  }

  ClassMember? getInterfaceClassMember(Class cls, Name name,
      {bool setter: false}) {
    return getNodeFromClass(cls).getInterfaceMember(name, setter);
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

  final Map<Class, Substitution> substitutions;

  ClassHierarchyNodeBuilder(
      this.hierarchy, this.classBuilder, this.substitutions);

  ClassBuilder get objectClass => hierarchy.objectClassBuilder;

  bool get shouldModifyKernel =>
      classBuilder.library.loader == hierarchy.loader;

  ClassMember? checkInheritanceConflict(ClassMember a, ClassMember b) {
    if (a.isStatic || a.isProperty != b.isProperty) {
      reportInheritanceConflict(a, b);
      return a;
    }
    return null;
  }

  static void inferMethodType(
      ClassHierarchyBuilder hierarchy,
      SourceClassBuilder classBuilder,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(!declaredMember.isGetter && !declaredMember.isSetter);
    if (declaredMember.classBuilder == classBuilder &&
        (declaredMember.returnType == null ||
            declaredMember.formals != null &&
                declaredMember.formals!
                    .any((parameter) => parameter.type == null))) {
      Procedure declaredProcedure = declaredMember.member as Procedure;
      FunctionNode declaredFunction = declaredProcedure.function;
      List<TypeParameter> declaredTypeParameters =
          declaredFunction.typeParameters;
      List<VariableDeclaration> declaredPositional =
          declaredFunction.positionalParameters;
      List<VariableDeclaration> declaredNamed =
          declaredFunction.namedParameters;
      declaredNamed = declaredNamed.toList()..sort(compareNamedParameters);

      DartType? inferredReturnType;
      Map<FormalParameterBuilder, DartType?> inferredParameterTypes = {};

      Set<ClassMember> overriddenMemberSet =
          toSet(classBuilder, overriddenMembers);
      CombinedClassMemberSignature combinedMemberSignature =
          new CombinedClassMemberSignature(
              hierarchy, classBuilder, overriddenMemberSet.toList(),
              forSetter: false);
      FunctionType? combinedMemberSignatureType = combinedMemberSignature
              .getCombinedSignatureTypeInContext(declaredTypeParameters)
          as FunctionType?;

      bool cantInferReturnType = false;
      List<FormalParameterBuilder>? cantInferParameterTypes;

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
          FormalParameterBuilder declaredParameter = declaredMember.formals![i];
          if (declaredParameter.type != null) {
            continue;
          }

          DartType? inferredParameterType;
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

        Map<String, DartType>? namedParameterTypes;
        for (int i = declaredPositional.length;
            i < declaredMember.formals!.length;
            i++) {
          FormalParameterBuilder declaredParameter = declaredMember.formals![i];
          if (declaredParameter.type != null) {
            continue;
          }

          DartType? inferredParameterType;
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
            in declaredMember.formals!) {
          if (declaredParameter.type == null) {
            DartType inferredParameterType =
                inferredParameterTypes[declaredParameter] ??
                    const DynamicType();
            declaredParameter.variable!.type = inferredParameterType;
          }
        }
      }
    }
  }

  void inferMethodSignature(ClassHierarchyBuilder hierarchy,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    assert(!declaredMember.isGetter && !declaredMember.isSetter);
    // Trigger computation of method type.
    Procedure declaredProcedure =
        declaredMember.getMember(hierarchy) as Procedure;
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
    Procedure declaredSetter = declaredMember.getMember(hierarchy) as Procedure;
    for (ClassMember overriddenMember
        in toSet(declaredMember.classBuilder, overriddenMembers)) {
      Covariance covariance = overriddenMember.getCovariance(hierarchy);
      covariance.applyCovariance(declaredSetter);
    }
  }

  static void inferGetterType(
      ClassHierarchyBuilder hierarchy,
      SourceClassBuilder classBuilder,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isGetter);
    if (declaredMember.classBuilder == classBuilder &&
        declaredMember.returnType == null) {
      DartType? inferredType;
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

      void inferFrom(List<ClassMember> members, {required bool forSetter}) {
        // ignore: unnecessary_null_comparison
        assert(forSetter != null);
        CombinedClassMemberSignature combinedMemberSignature =
            new CombinedClassMemberSignature(hierarchy, classBuilder, members,
                forSetter: forSetter);
        DartType? combinedMemberSignatureType =
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

      declaredMember.procedure.function.returnType =
          inferredType ?? const DynamicType();
    }
  }

  static void inferSetterType(
      ClassHierarchyBuilder hierarchy,
      SourceClassBuilder classBuilder,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isSetter);
    FormalParameterBuilder parameter = declaredMember.formals!.first;
    if (declaredMember.classBuilder == classBuilder && parameter.type == null) {
      DartType? inferredType;

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

      void inferFrom(List<ClassMember> members, {required bool forSetter}) {
        // ignore: unnecessary_null_comparison
        assert(forSetter != null);
        CombinedClassMemberSignature combinedMemberSignature =
            new CombinedClassMemberSignature(hierarchy, classBuilder, members,
                forSetter: forSetter);
        DartType? combinedMemberSignatureType =
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

      parameter.variable!.type = inferredType ?? const DynamicType();
    }
  }

  /// Merge the [inheritedType] with the currently [inferredType] using
  /// nnbd-top-merge or legacy-top-merge depending on whether [classBuilder] is
  /// defined in an opt-in or opt-out library. If the types could not be merged
  /// `null` is returned and an error should be reported by the caller.
  static DartType? mergeTypeInLibrary(
      ClassHierarchyBuilder hierarchy,
      ClassBuilder classBuilder,
      DartType? inferredType,
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

  /// Infers the field type of [fieldBuilder] based on [overriddenMembers].
  static void inferFieldType(
      ClassHierarchyBuilder hierarchy,
      SourceClassBuilder classBuilder,
      SourceFieldBuilder fieldBuilder,
      Iterable<ClassMember> overriddenMembers) {
    if (fieldBuilder.classBuilder == classBuilder &&
        fieldBuilder.type == null) {
      DartType? inferredType;

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

      DartType? inferFrom(List<ClassMember> members,
          {required bool forSetter}) {
        // ignore: unnecessary_null_comparison
        assert(forSetter != null);
        CombinedClassMemberSignature combinedMemberSignature =
            new CombinedClassMemberSignature(hierarchy, classBuilder, members,
                forSetter: forSetter);
        return combinedMemberSignature.combinedMemberSignatureType;
      }

      DartType? combinedMemberSignatureType;
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
        DartType? getterType = inferFrom(overriddenGetters, forSetter: false);
        DartType? setterType = inferFrom(overriddenSetters, forSetter: true);
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

      fieldBuilder.fieldType = inferredType;
    }
  }

  /// Infers the field signature of [declaredMember] based on
  /// [overriddenMembers].
  void inferFieldSignature(ClassHierarchyBuilder hierarchy,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    Field declaredField = declaredMember.getMember(hierarchy) as Field;
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
      } else if (b.classBuilder == classBuilder) {
        classBuilder.addProblem(
            messageDeclaredMemberConflictsWithInheritedMember,
            b.charOffset,
            name.length,
            context: <LocatedMessage>[
              messageDeclaredMemberConflictsWithInheritedMemberCause
                  .withLocation(a.fileUri, a.charOffset, name.length)
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

  ClassHierarchyNode build() {
    assert(!classBuilder.isPatch);
    ClassHierarchyNode? supernode;
    if (objectClass != classBuilder.origin) {
      supernode =
          hierarchy.getNodeFromTypeBuilder(classBuilder.supertypeBuilder!);
      if (supernode == null) {
        supernode = hierarchy.getNodeFromClassBuilder(objectClass);
      }
      // ignore: unnecessary_null_comparison
      assert(supernode != null);
    }

    /// Set to `true` if the class needs interfaces, that is, if it has any
    /// members where the interface member is different from its corresponding
    /// class members.
    ///
    /// This is an optimization to avoid unnecessary computation of interface
    /// members.
    bool hasInterfaces = false;

    Map<Name, Tuple> memberMap = {};

    Scope scope = classBuilder.scope;

    for (Builder builder in scope.localMembers) {
      MemberBuilder memberBuilder = builder as MemberBuilder;
      for (ClassMember classMember in memberBuilder.localMembers) {
        if (classMember.isAbstract) {
          hasInterfaces = true;
        }
        Tuple? tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareMember(classMember);
        } else {
          tuple.declaredMember = classMember;
        }
      }
      for (ClassMember classMember in memberBuilder.localSetters) {
        if (classMember.isAbstract) {
          hasInterfaces = true;
        }
        Tuple? tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareSetter(classMember);
        } else {
          tuple.declaredSetter = classMember;
        }
      }
    }

    for (MemberBuilder memberBuilder in scope.localSetters) {
      for (ClassMember classMember in memberBuilder.localMembers) {
        if (classMember.isAbstract) {
          hasInterfaces = true;
        }
        Tuple? tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareMember(classMember);
        } else {
          tuple.declaredMember = classMember;
        }
      }
      for (ClassMember classMember in memberBuilder.localSetters) {
        if (classMember.isAbstract) {
          hasInterfaces = true;
        }
        Tuple? tuple = memberMap[classMember.name];
        if (tuple == null) {
          memberMap[classMember.name] = new Tuple.declareSetter(classMember);
        } else {
          tuple.declaredSetter = classMember;
        }
      }
    }

    if (classBuilder.isMixinApplication) {
      TypeBuilder mixedInTypeBuilder = classBuilder.mixedInTypeBuilder!;
      TypeDeclarationBuilder mixin = mixedInTypeBuilder.declaration!;
      inferMixinApplication();
      while (mixin.isNamedMixinApplication) {
        ClassBuilder named = mixin as ClassBuilder;
        mixedInTypeBuilder = named.mixedInTypeBuilder!;
        mixin = mixedInTypeBuilder.declaration!;
      }
      if (mixin is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = mixin;
        NamedTypeBuilder namedBuilder = mixedInTypeBuilder as NamedTypeBuilder;
        mixin = aliasBuilder.unaliasDeclaration(namedBuilder.arguments,
            isUsedAsClass: true,
            usedAsClassCharOffset: namedBuilder.charOffset,
            usedAsClassFileUri: namedBuilder.fileUri)!;
      }
      if (mixin is ClassBuilder) {
        scope = mixin.scope.computeMixinScope();

        for (Builder builder in scope.localMembers) {
          MemberBuilder memberBuilder = builder as MemberBuilder;
          for (ClassMember classMember in memberBuilder.localMembers) {
            if (classMember.isAbstract) {
              hasInterfaces = true;
            }
            Tuple? tuple = memberMap[classMember.name];
            if (tuple == null) {
              memberMap[classMember.name] = new Tuple.mixInMember(classMember);
            } else {
              tuple.mixedInMember = classMember;
            }
          }
          for (ClassMember classMember in memberBuilder.localSetters) {
            if (classMember.isAbstract) {
              hasInterfaces = true;
            }
            Tuple? tuple = memberMap[classMember.name];
            if (tuple == null) {
              memberMap[classMember.name] = new Tuple.mixInSetter(classMember);
            } else {
              tuple.mixedInSetter = classMember;
            }
          }
        }

        for (MemberBuilder memberBuilder in scope.localSetters) {
          for (ClassMember classMember in memberBuilder.localMembers) {
            if (classMember.isAbstract) {
              hasInterfaces = true;
            }
            Tuple? tuple = memberMap[classMember.name];
            if (tuple == null) {
              memberMap[classMember.name] = new Tuple.mixInMember(classMember);
            } else {
              tuple.mixedInMember = classMember;
            }
          }
          for (ClassMember classMember in memberBuilder.localSetters) {
            if (classMember.isAbstract) {
              hasInterfaces = true;
            }
            Tuple? tuple = memberMap[classMember.name];
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

    void extend(Map<Name, ClassMember>? superClassMembers) {
      if (superClassMembers == null) return;
      for (MapEntry<Name, ClassMember> entry in superClassMembers.entries) {
        Name name = entry.key;
        ClassMember superClassMember = entry.value;
        Tuple? tuple = memberMap[name];
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

    void implement(Map<Name, ClassMember>? superInterfaceMembers) {
      if (superInterfaceMembers == null) return;
      for (MapEntry<Name, ClassMember> entry in superInterfaceMembers.entries) {
        Name name = entry.key;
        ClassMember superInterfaceMember = entry.value;
        Tuple? tuple = memberMap[name];
        if (tuple != null) {
          if (superInterfaceMember.forSetter) {
            tuple.addImplementedSetter(superInterfaceMember);
          } else {
            tuple.addImplementedMember(superInterfaceMember);
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

    if (supernode == null) {
      // This should be Object.
      superclasses = new List<Supertype>.filled(0, dummySupertype);
      interfaces = new List<Supertype>.filled(0, dummySupertype);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;

      superclasses = new List<Supertype>.filled(
          supernode.superclasses.length + 1, dummySupertype);
      Supertype? supertype = classBuilder.supertypeBuilder!.buildSupertype(
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
      // ignore: unnecessary_null_comparison
      if (superclassInterfaces != null) {
        superclassInterfaces = substSupertypes(supertype, superclassInterfaces);
      }

      extend(supernode.classMemberMap);
      extend(supernode.classSetterMap);

      if (supernode.interfaceMemberMap != null ||
          supernode.interfaceSetterMap != null) {
        hasInterfaces = true;
      }

      if (hasInterfaces) {
        implement(supernode.interfaceMemberMap ?? supernode.classMemberMap);
        implement(supernode.interfaceSetterMap ?? supernode.classSetterMap);
      }

      if (directInterfaceBuilders != null) {
        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          ClassHierarchyNode? interfaceNode =
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
        // ignore: unnecessary_null_comparison
        if (superclassInterfaces != null) {
          for (int i = 0; i < superclassInterfaces.length; i++) {
            addInterface(interfaces, superclasses, superclassInterfaces[i]);
          }
        }

        for (int i = 0; i < directInterfaceBuilders.length; i++) {
          Supertype? directInterface = directInterfaceBuilders[i]
              .buildSupertype(classBuilder.library, classBuilder.charOffset,
                  classBuilder.fileUri);
          if (directInterface != null) {
            addInterface(interfaces, superclasses, directInterface);
            ClassHierarchyNode interfaceNode =
                hierarchy.getNodeFromClass(directInterface.classNode);
            // ignore: unnecessary_null_comparison
            if (interfaceNode != null) {
              if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
                maxInheritancePath = interfaceNode.maxInheritancePath + 1;
              }

              List<Supertype> types =
                  substSupertypes(directInterface, interfaceNode.superclasses);
              for (int i = 0; i < types.length; i++) {
                addInterface(interfaces, superclasses, types[i]);
              }
              // ignore: unnecessary_null_comparison
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
        // ignore: unnecessary_null_comparison
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
    // ignore: unnecessary_null_comparison
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
    Map<Name, ClassMember>? interfaceMemberMap = {};

    /// Setters inherited from interfaces. This contains no static setters. If
    /// no interfaces are implemented by this class or its superclasses this is
    /// identical to [classSetterMap] and we do not store it in the
    /// [ClassHierarchyNode].
    Map<Name, ClassMember>? interfaceSetterMap = {};

    /// Map for members declared in this class to the members that they
    /// override. This is used for checking valid overrides and to ensure that
    /// override inference correctly propagates inferred types through the
    /// class hierarchy.
    Map<ClassMember, Set<ClassMember>> declaredOverridesMap = {};

    /// In case this class is a mixin application, this maps members declared in
    /// the mixin to the members that they override. This is used for checking
    /// valid overrides but _not_ as for [declaredOverridesMap] for override
    /// inference.
    Map<ClassMember, Set<ClassMember>> mixinApplicationOverridesMap = {};

    /// In case this class is concrete, this maps concrete members that are
    /// inherited into this class to the members they should override to validly
    /// implement the interface of this class.
    Map<ClassMember, Set<ClassMember>> inheritedImplementsMap = {};

    /// In case this class is concrete, this holds the interface members
    /// without a corresponding class member. These are either reported as
    /// missing implementations or trigger insertion of noSuchMethod forwarders.
    List<ClassMember>? abstractMembers = [];

    ClassHierarchyNodeDataForTesting? dataForTesting;
    if (retainDataForTesting) {
      dataForTesting = new ClassHierarchyNodeDataForTesting(
          abstractMembers,
          declaredOverridesMap,
          mixinApplicationOverridesMap,
          inheritedImplementsMap);
    }

    /// Registers that the current class has an interface member without a
    /// corresponding class member.
    ///
    /// This is used to report missing implementation or, in the case the class
    /// has a user defined concrete noSuchMethod, to insert noSuchMethod
    /// forwarders. (Currently, insertion of forwarders is handled elsewhere.)
    ///
    /// For instance:
    ///
    ///    abstract class Interface {
    ///      method();
    ///    }
    ///    class Class1 implements Interface {
    ///      // Missing implementation for `Interface.method`.
    ///    }
    ///    class Class2 implements Interface {
    ///      noSuchMethod(_) {}
    ///      // A noSuchMethod forwarder is added for `Interface.method`.
    ///    }
    ///
    void registerAbstractMember(ClassMember abstractMember) {
      if (!abstractMember.isInternalImplementation) {
        /// If `isInternalImplementation` is `true`, the member is synthesized
        /// implementation that does not require implementation in other
        /// classes.
        ///
        /// This is for instance used for late lowering where
        ///
        ///    class Interface {
        ///      late int? field;
        ///    }
        ///    class Class implements Interface {
        ///      int? field;
        ///    }
        ///
        /// is encoded as
        ///
        ///    class Interface {
        ///      bool _#field#isSet = false;
        ///      int? _#field = null;
        ///      int? get field => _#field#isSet ? _#field : throw ...;
        ///      void set field(int? value) { ... }
        ///    }
        ///    class Class implements Interface {
        ///      int? field;
        ///    }
        ///
        /// and `Class` should not be required to implement
        /// `Interface._#field#isSet` and `Interface._#field`.
        abstractMembers.add(abstractMember);
      }
    }

    /// Registers that [inheritedMember] should be checked to validly override
    /// [overrides].
    ///
    /// This is needed in the case where a concrete member is inherited into
    /// a concrete subclass. For instance:
    ///
    ///    class Super {
    ///      void method() {}
    ///    }
    ///    abstract class Interface {
    ///      void method();
    ///    }
    ///    class Class extends Super implements Interface {}
    ///
    /// Here `Super.method` must be checked to be a valid implementation for
    /// `Interface.method` by being a valid override of it.
    void registerInheritedImplements(
        ClassMember inheritedMember, Set<ClassMember> overrides,
        {required ClassMember aliasForTesting}) {
      if (classBuilder is SourceClassBuilder) {
        assert(
            inheritedMember.classBuilder != classBuilder,
            "Only inherited members can implement by inheritance: "
            "${inheritedMember}");
        inheritedImplementsMap[inheritedMember] = overrides;
        // ignore: unnecessary_null_comparison
        if (dataForTesting != null && aliasForTesting != null) {
          dataForTesting.aliasMap[aliasForTesting] = inheritedMember;
        }
      }
    }

    /// Returns `true` if the current class is from an opt-out library and
    /// [classMember] is from an opt-in library.
    ///
    /// In this case a member signature needs to be inserted to show the
    /// legacy erased type of the interface member. For instance:
    ///
    ///    // Opt-in library:
    ///    class Super {
    ///      int? method(int i) {}
    ///    }
    ///    // Opt-out library:
    ///    class Class extends Super {
    ///      // A member signature is inserted:
    ///      // int* method(int* i);
    ///    }
    ///
    bool needsMemberSignatureFor(ClassMember classMember) {
      return !classBuilder.library.isNonNullableByDefault &&
          classMember.classBuilder.library.isNonNullableByDefault;
    }

    memberMap.forEach((Name name, Tuple tuple) {
      /// The computation starts by sanitizing the members. Conflicts between
      /// methods and properties (getters/setters) or between static and
      /// instance members are reported. Conflicting members and members
      /// overridden by duplicates are removed.
      ///
      /// For this [definingGetable] and [definingSetable] hold the first member
      /// of its kind found among declared, mixed in, extended and implemented
      /// members.
      ///
      /// Conflicts between [definingGetable] and [definingSetable] are reported
      /// afterwards.

      ClassMember? definingGetable;
      ClassMember? definingSetable;

      ClassMember? declaredGetable = tuple.declaredMember;
      if (declaredGetable != null) {
        /// class Class {
        ///   method() {}
        /// }
        definingGetable = declaredGetable;
      }
      ClassMember? declaredSetable = tuple.declaredSetter;
      if (declaredSetable != null) {
        /// class Class {
        ///   set setter(value) {}
        /// }
        definingSetable = declaredSetable;
      }

      ClassMember? mixedInGetable;
      ClassMember? tupleMixedInMember = tuple.mixedInMember;
      if (tupleMixedInMember != null &&
          !tupleMixedInMember.isStatic &&
          !tupleMixedInMember.isDuplicate &&
          !tupleMixedInMember.isSynthesized) {
        /// We treat
        ///
        ///   opt-in:
        ///   class Interface {
        ///     method3() {}
        ///   }
        ///   opt-out:
        ///   class Mixin implements Interface {
        ///     static method1() {}
        ///     method2() {}
        ///     method2() {}
        ///     /*member-signature*/ method3() {}
        ///   }
        ///   class Class with Mixin {}
        ///
        /// as
        ///
        ///   class Mixin {}
        ///   class Class with Mixin {}
        ///
        /// Note that skipped synthetic getable 'method3' is still included
        /// in the implemented getables, but its type will not define the type
        /// when mixed in. For instance
        ///
        ///   opt-in:
        ///   abstract class Interface {
        ///     num get getter;
        ///   }
        ///   opt-out:
        ///   abstract class Super {
        ///     int get getter;
        ///   }
        ///   abstract class Mixin implements Interface {
        ///     /*member-signature*/ num get getter;
        ///   }
        ///   abstract class Class extends Super with Mixin {}
        ///
        /// Here the type of `Class.getter` should not be defined from the
        /// synthetic member signature `Mixin.getter` but as a combined member
        /// signature of `Super.getter` and `Mixin.getter`, resulting in type
        /// `int` instead of `num`.
        if (definingGetable == null) {
          /// class Mixin {
          ///   method() {}
          /// }
          /// class Class with Mixin {}
          definingGetable = mixedInGetable = tupleMixedInMember;
        } else if (!definingGetable.isDuplicate) {
          // This case is currently unreachable from source code since classes
          // cannot both declare and mix in members. From dill, this can occur
          // but should not conflicting members.
          //
          // The case is handled for consistency.
          if (definingGetable.isStatic ||
              definingGetable.isProperty != tupleMixedInMember.isProperty) {
            reportInheritanceConflict(definingGetable, tupleMixedInMember);
          } else {
            mixedInGetable = tupleMixedInMember;
          }
        }
      }
      ClassMember? mixedInSetable;
      ClassMember? tupleMixedInSetter = tuple.mixedInSetter;
      if (tupleMixedInSetter != null &&
          !tupleMixedInSetter.isStatic &&
          !tupleMixedInSetter.isDuplicate &&
          !tupleMixedInSetter.isSynthesized) {
        /// We treat
        ///
        ///   class Mixin {
        ///     static set setter1(value) {}
        ///     set setter2(value) {}
        ///     set setter2(value) {}
        ///     /*member-signature*/ setter3() {}
        ///   }
        ///   class Class with Mixin {}
        ///
        /// as
        ///
        ///   class Mixin {}
        ///   class Class with Mixin {}
        ///
        /// Note that skipped synthetic setable 'setter3' is still included
        /// in the implemented setables, but its type will not define the type
        /// when mixed in. For instance
        ///
        ///   opt-in:
        ///   abstract class Interface {
        ///     void set setter(int value);
        ///   }
        ///   opt-out:
        ///   abstract class Super {
        ///     void set setter(num value);
        ///   }
        ///   abstract class Mixin implements Interface {
        ///     /*member-signature*/ num get getter;
        ///   }
        ///   abstract class Class extends Super with Mixin {}
        ///
        /// Here the type of `Class.setter` should not be defined from the
        /// synthetic member signature `Mixin.setter` but as a combined member
        /// signature of `Super.setter` and `Mixin.setter`, resulting in type
        /// `num` instead of `int`.
        if (definingSetable == null) {
          /// class Mixin {
          ///   set setter(value) {}
          /// }
          /// class Class with Mixin {}
          definingSetable = mixedInSetable = tupleMixedInSetter;
        } else if (!definingSetable.isDuplicate) {
          if (definingSetable.isStatic ||
              definingSetable.isProperty != tupleMixedInSetter.isProperty) {
            reportInheritanceConflict(definingSetable, tupleMixedInSetter);
          } else {
            mixedInSetable = tupleMixedInSetter;
          }
        }
      }

      ClassMember? extendedGetable;
      ClassMember? tupleExtendedMember = tuple.extendedMember;
      if (tupleExtendedMember != null &&
          !tupleExtendedMember.isStatic &&
          !tupleExtendedMember.isDuplicate) {
        /// We treat
        ///
        ///   class Super {
        ///     static method1() {}
        ///     method2() {}
        ///     method2() {}
        ///   }
        ///   class Class extends Super {}
        ///
        /// as
        ///
        ///   class Super {}
        ///   class Class extends Super {}
        ///
        if (definingGetable == null) {
          /// class Super {
          ///   method() {}
          /// }
          /// class Class extends Super {}
          definingGetable = extendedGetable = tupleExtendedMember;
        } else if (!definingGetable.isDuplicate) {
          if (definingGetable.isStatic ||
              definingGetable.isProperty != tupleExtendedMember.isProperty) {
            ///   class Super {
            ///     method() {}
            ///   }
            ///   class Class extends Super {
            ///     static method() {}
            ///   }
            ///
            /// or
            ///
            ///   class Super {
            ///     method() {}
            ///   }
            ///   class Class extends Super {
            ///     get getter => 0;
            ///   }
            reportInheritanceConflict(definingGetable, tupleExtendedMember);
          } else {
            extendedGetable = tupleExtendedMember;
          }
        }
      }
      ClassMember? extendedSetable;
      ClassMember? tupleExtendedSetter = tuple.extendedSetter;
      if (tupleExtendedSetter != null &&
          !tupleExtendedSetter.isStatic &&
          !tupleExtendedSetter.isDuplicate) {
        /// We treat
        ///
        ///   class Super {
        ///     static set setter1(value) {}
        ///     set setter2(value) {}
        ///     set setter2(value) {}
        ///   }
        ///   class Class extends Super {}
        ///
        /// as
        ///
        ///   class Super {}
        ///   class Class extends Super {}
        ///
        if (definingSetable == null) {
          /// class Super {
          ///   set setter(value) {}
          /// }
          /// class Class extends Super {}
          definingSetable = extendedSetable = tupleExtendedSetter;
        } else if (!definingSetable.isDuplicate) {
          if (definingSetable.isStatic ||
              definingSetable.isProperty != tupleExtendedSetter.isProperty) {
            reportInheritanceConflict(definingSetable, tupleExtendedSetter);
          } else {
            extendedSetable = tupleExtendedSetter;
          }
        }
      }

      // TODO(johnniwinther): Remove extended and mixed in members/setters
      // from implemented members/setters. Mixin applications always implement
      // the mixin class leading to unnecessary interface members.
      List<ClassMember>? implementedGetables;
      List<ClassMember>? tupleImplementedMembers = tuple.implementedMembers;
      if (tupleImplementedMembers != null &&
          // Skip implemented members if we already have a duplicate.
          !(definingGetable != null && definingGetable.isDuplicate)) {
        for (int i = 0; i < tupleImplementedMembers.length; i++) {
          ClassMember? implementedGetable = tupleImplementedMembers[i];
          if (implementedGetable.isStatic || implementedGetable.isDuplicate) {
            /// We treat
            ///
            ///   class Interface {
            ///     static method1() {}
            ///     method2() {}
            ///     method2() {}
            ///   }
            ///   class Class implements Interface {}
            ///
            /// as
            ///
            ///   class Interface {}
            ///   class Class implements Interface {}
            ///
            implementedGetable = null;
          } else {
            if (definingGetable == null) {
              /// class Interface {
              ///   method() {}
              /// }
              /// class Class implements Interface {}
              definingGetable = implementedGetable;
            } else if (definingGetable.isStatic ||
                definingGetable.isProperty != implementedGetable.isProperty) {
              ///   class Interface {
              ///     method() {}
              ///   }
              ///   class Class implements Interface {
              ///     static method() {}
              ///   }
              ///
              /// or
              ///
              ///   class Interface {
              ///     method() {}
              ///   }
              ///   class Class implements Interface {
              ///     get getter => 0;
              ///   }
              reportInheritanceConflict(definingGetable, implementedGetable);
              implementedGetable = null;
            }
          }
          if (implementedGetable == null) {
            // On the first skipped member we add all previous.
            implementedGetables ??= tupleImplementedMembers.take(i).toList();
          } else if (implementedGetables != null) {
            // If already skipping members we add [implementedGetable]
            // explicitly.
            implementedGetables.add(implementedGetable);
          }
        }
        if (implementedGetables == null) {
          // No members were skipped so we use the full list.
          implementedGetables = tupleImplementedMembers;
        } else if (implementedGetables.isEmpty) {
          // No members were included.
          implementedGetables = null;
        }
      }

      List<ClassMember>? implementedSetables;
      List<ClassMember>? tupleImplementedSetters = tuple.implementedSetters;
      if (tupleImplementedSetters != null &&
          // Skip implemented setters if we already have a duplicate.
          !(definingSetable != null && definingSetable.isDuplicate)) {
        for (int i = 0; i < tupleImplementedSetters.length; i++) {
          ClassMember? implementedSetable = tupleImplementedSetters[i];
          if (implementedSetable.isStatic || implementedSetable.isDuplicate) {
            /// We treat
            ///
            ///   class Interface {
            ///     static set setter1(value) {}
            ///     set setter2(value) {}
            ///     set setter2(value) {}
            ///   }
            ///   class Class implements Interface {}
            ///
            /// as
            ///
            ///   class Interface {}
            ///   class Class implements Interface {}
            ///
            implementedSetable = null;
          } else {
            if (definingSetable == null) {
              /// class Interface {
              ///   set setter(value) {}
              /// }
              /// class Class implements Interface {}
              definingSetable = implementedSetable;
            } else if (definingSetable.isStatic ||
                definingSetable.isProperty != implementedSetable.isProperty) {
              /// class Interface {
              ///   set setter(value) {}
              /// }
              /// class Class implements Interface {
              ///   static set setter(value) {}
              /// }
              reportInheritanceConflict(definingSetable, implementedSetable);
              implementedSetable = null;
            }
          }
          if (implementedSetable == null) {
            // On the first skipped setter we add all previous.
            implementedSetables ??= tupleImplementedSetters.take(i).toList();
          } else if (implementedSetables != null) {
            // If already skipping setters we add [implementedSetable]
            // explicitly.
            implementedSetables.add(implementedSetable);
          }
        }
        if (implementedSetables == null) {
          // No setters were skipped so we use the full list.
          implementedSetables = tupleImplementedSetters;
        } else if (implementedSetables.isEmpty) {
          // No setters were included.
          implementedSetables = null;
        }
      }

      if (definingGetable != null && definingSetable != null) {
        if (definingGetable.isStatic != definingSetable.isStatic ||
            definingGetable.isProperty != definingSetable.isProperty) {
          reportInheritanceConflict(definingGetable, definingSetable);
          // TODO(johnniwinther): Should we remove [definingSetable]? If we
          // leave it in this conflict will also be reported in subclasses. If
          // we remove it, any write to the setable will be unresolved.
        }
      }

      // TODO(johnniwinther): Handle declared members together with mixed in
      // members. This should only occur from .dill, though.
      if (mixedInGetable != null) {
        declaredGetable = null;
      }
      if (mixedInSetable != null) {
        declaredSetable = null;
      }

      /// Set to `true` if declared members have been registered in
      /// [registerDeclaredOverride] or [registerMixedInOverride].
      bool hasDeclaredMembers = false;

      /// Declared methods, getters and setters registered in
      /// [registerDeclaredOverride].
      ClassMember? declaredMethod;
      List<ClassMember>? declaredProperties;

      /// Declared methods, getters and setters registered in
      /// [registerDeclaredOverride].
      ClassMember? mixedInMethod;
      List<ClassMember>? mixedInProperties;

      /// Registers that [declaredMember] overrides extended and implemented
      /// members.
      ///
      /// Getters and setters share overridden members so the registration
      /// of override relations is performed after the interface members have
      /// been computed.
      ///
      /// Declared members must be checked for valid override of the overridden
      /// members _and_ must register an override dependency with the overridden
      /// members so that override inference can propagate inferred types
      /// correctly. For instance:
      ///
      ///    class Super {
      ///      int get property => 42;
      ///    }
      ///    class Class extends Super {
      ///      void set property(value) {}
      ///    }
      ///
      /// Here the parameter type of the setter `Class.property` must be
      /// inferred from the type of the getter `Super.property`.
      void registerDeclaredOverride(ClassMember declaredMember,
          {ClassMember? aliasForTesting}) {
        if (classBuilder is SourceClassBuilder && !declaredMember.isStatic) {
          assert(
              declaredMember.isSourceDeclaration &&
                  declaredMember.classBuilder == classBuilder,
              "Only declared members can override: ${declaredMember}");
          hasDeclaredMembers = true;
          if (declaredMember.isProperty) {
            declaredProperties ??= [];
            declaredProperties!.add(declaredMember);
          } else {
            assert(
                declaredMethod == null,
                "Multiple methods unexpectedly declared: "
                "${declaredMethod} and ${declaredMember}.");
            declaredMethod = declaredMember;
          }
          if (dataForTesting != null && aliasForTesting != null) {
            dataForTesting.aliasMap[aliasForTesting] = declaredMember;
          }
        }
      }

      /// Registers that [mixedMember] overrides extended and implemented
      /// members through application.
      ///
      /// Getters and setters share overridden members so the registration
      /// of override relations in performed after the interface members have
      /// been computed.
      ///
      /// Declared mixed in members must be checked for valid override of the
      /// overridden members but _not_ register an override dependency with the
      /// overridden members. This is in contrast to declared members. For
      /// instance:
      ///
      ///    class Super {
      ///      int get property => 42;
      ///    }
      ///    class Mixin {
      ///      void set property(value) {}
      ///    }
      ///    class Class = Super with Mixin;
      ///
      /// Here the parameter type of the setter `Mixin.property` must _not_ be
      /// inferred from the type of the getter `Super.property`, but should
      /// instead default to `dynamic`.
      void registerMixedInOverride(ClassMember mixedInMember,
          {ClassMember? aliasForTesting}) {
        assert(mixedInMember.classBuilder != classBuilder,
            "Only mixin members can override by application: ${mixedInMember}");
        if (classBuilder is SourceClassBuilder) {
          hasDeclaredMembers = true;
          if (mixedInMember.isProperty) {
            mixedInProperties ??= [];
            mixedInProperties!.add(mixedInMember);
          } else {
            assert(
                mixedInMethod == null,
                "Multiple methods unexpectedly declared in mixin: "
                "${mixedInMethod} and ${mixedInMember}.");
            mixedInMethod = mixedInMember;
          }
          if (dataForTesting != null && aliasForTesting != null) {
            dataForTesting.aliasMap[aliasForTesting] = mixedInMember;
          }
        }
      }

      /// Computes the class and interface members for a method, getter, or
      /// setter in the current [tuple].
      ///
      /// [definingMember] is the member which defines whether the computation
      /// is for a method, a getter or a setter.
      /// [declaredMember] is the member declared in the current class, if any.
      /// [mixedInMember] is the member declared in a mixin that is mixed into
      /// the current current class, if any.
      /// [extendedMember] is the member inherited from the super class.
      /// [implementedMembers] are the members inherited from the super
      /// interfaces, if none this is `null`.
      ///
      /// The computed class and interface members are added to [classMemberMap]
      /// and [interfaceMemberMap], respectively.
      ClassMember? computeMembers(
          {required ClassMember definingMember,
          required ClassMember? declaredMember,
          required ClassMember? mixedInMember,
          required ClassMember? extendedMember,
          required List<ClassMember>? implementedMembers,
          required Map<Name, ClassMember> classMemberMap,
          required Map<Name, ClassMember>? interfaceMemberMap}) {
        ClassMember? classMember;
        ClassMember? interfaceMember;

        if (mixedInMember != null) {
          if (mixedInMember.isAbstract) {
            ///    class Mixin {
            ///      method();
            ///    }
            ///    class Class = Object with Mixin;

            /// Interface members from the extended, mixed in, and implemented
            /// members define the combined member signature.
            Set<ClassMember> interfaceMembers = {};

            if (extendedMember != null) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Mixin {
              ///      method();
              ///    }
              ///    class Class = Super with Mixin;
              interfaceMembers.add(extendedMember.interfaceMember);
            }

            interfaceMembers.add(mixedInMember);

            if (implementedMembers != null) {
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Mixin {
              ///      method();
              ///    }
              ///    class Class = Object with Mixin implements Interface;
              interfaceMembers.addAll(implementedMembers);
            }

            /// We always create a synthesized interface member, even in the
            /// case of [interfaceMembers] being a singleton, to insert the
            /// abstract mixin stub.
            interfaceMember = new SynthesizedInterfaceMember(
                classBuilder, name, interfaceMembers.toList(),
                superClassMember: extendedMember,
                // [definingMember] and [mixedInMember] are always the same
                // here. Use the latter here and the former below to show the
                // the member is canonical _because_ its the mixed in member and
                // it defines the isProperty/forSetter properties _because_ it
                // is the defining member.
                canonicalMember: mixedInMember,
                mixedInMember: mixedInMember,
                isProperty: definingMember.isProperty,
                forSetter: definingMember.forSetter,
                shouldModifyKernel: shouldModifyKernel);
            hierarchy.registerMemberComputation(interfaceMember);

            if (extendedMember != null) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Mixin {
              ///      method();
              ///    }
              ///    class Class = Super with Mixin;
              ///
              /// The concrete extended member is the class member but might
              /// be overwritten by a concrete forwarding stub:
              ///
              ///    class Super {
              ///      method(int i) {}
              ///    }
              ///    class Interface {
              ///      method(covariant int i) {}
              ///    }
              ///    class Mixin {
              ///      method(int i);
              ///    }
              ///    // A concrete forwarding stub
              ///    //   method(covariant int i) => super.method(i);
              ///    // will be inserted.
              ///    class Class = Super with Mixin implements Interface;
              ///
              classMember = new InheritedClassMemberImplementsInterface(
                  classBuilder, name,
                  inheritedClassMember: extendedMember,
                  implementedInterfaceMember: interfaceMember,
                  forSetter: definingMember.forSetter,
                  isProperty: definingMember.isProperty);
              hierarchy.registerMemberComputation(classMember);
              if (!classBuilder.isAbstract) {
                registerInheritedImplements(extendedMember, {interfaceMember},
                    aliasForTesting: classMember);
              }
            } else if (!classBuilder.isAbstract) {
              ///    class Mixin {
              ///      method(); // Missing implementation.
              ///    }
              ///    class Class = Object with Mixin;
              registerAbstractMember(interfaceMember);
            }

            assert(!mixedInMember.isSynthesized);
            if (!mixedInMember.isSynthesized) {
              /// Members declared in the mixin must override extended and
              /// implemented members.
              ///
              /// When loading from .dill the mixed in member might be
              /// synthesized, for instance a member signature or forwarding
              /// stub, and this should not be checked to override the extended
              /// and implemented members:
              ///
              ///    // Opt-out library, from source:
              ///    class Mixin {}
              ///    // Opt-out library, from .dill:
              ///    class Mixin {
              ///      ...
              ///      String* toString(); // member signature
              ///    }
              ///    // Opt-out library, from source:
              ///    class Class = Object with Mixin;
              ///    // Mixin.toString should not be checked to override
              ///    // Object.toString.
              ///
              registerMixedInOverride(mixedInMember,
                  aliasForTesting: interfaceMember);
            }
          } else {
            assert(!mixedInMember.isAbstract);

            ///    class Mixin {
            ///      method() {}
            ///    }
            ///    class Class = Object with Mixin;
            ///

            /// Interface members from the extended, mixed in, and implemented
            /// members define the combined member signature.
            Set<ClassMember> interfaceMembers = {};

            if (extendedMember != null) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Mixin {
              ///      method() {}
              ///    }
              ///    class Class = Super with Mixin;
              interfaceMembers.add(extendedMember.interfaceMember);
            }

            interfaceMembers.add(mixedInMember);

            if (implementedMembers != null) {
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Mixin {
              ///      method() {}
              ///    }
              ///    class Class = Object with Mixin implements Interface;
              interfaceMembers.addAll(implementedMembers);
            }

            /// We always create a synthesized interface member, even in the
            /// case of [interfaceMembers] being a singleton, to insert the
            /// concrete mixin stub.
            interfaceMember = new SynthesizedInterfaceMember(
                classBuilder, name, interfaceMembers.toList(),
                superClassMember: mixedInMember,
                // [definingMember] and [mixedInMember] are always the same
                // here. Use the latter here and the former below to show the
                // the member is canonical _because_ its the mixed in member and
                // it defines the isProperty/forSetter properties _because_ it
                // is the defining member.
                canonicalMember: mixedInMember,
                mixedInMember: mixedInMember,
                isProperty: definingMember.isProperty,
                forSetter: definingMember.forSetter,
                shouldModifyKernel: shouldModifyKernel);
            hierarchy.registerMemberComputation(interfaceMember);

            /// The concrete mixed in member is the class member but will
            /// be overwritten by a concrete mixin stub:
            ///
            ///    class Mixin {
            ///       method() {}
            ///    }
            ///    // A concrete mixin stub
            ///    //   method() => super.method();
            ///    // will be inserted.
            ///    class Class = Object with Mixin;
            ///
            classMember = new InheritedClassMemberImplementsInterface(
                classBuilder, name,
                inheritedClassMember: mixedInMember,
                implementedInterfaceMember: interfaceMember,
                forSetter: definingMember.forSetter,
                isProperty: definingMember.isProperty);
            hierarchy.registerMemberComputation(classMember);

            if (!classBuilder.isAbstract) {
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Mixin {
              ///      method() {}
              ///    }
              ///    class Class = Object with Mixin;
              ///
              /// [mixinMember] must implemented interface member.
              registerInheritedImplements(mixedInMember, {interfaceMember},
                  aliasForTesting: classMember);
            }
            assert(!mixedInMember.isSynthesized);
            if (!mixedInMember.isSynthesized) {
              /// Members declared in the mixin must override extended and
              /// implemented members.
              ///
              /// When loading from .dill the mixed in member might be
              /// synthesized, for instance a member signature or forwarding
              /// stub, and this should not be checked to override the extended
              /// and implemented members.
              ///
              /// These synthesized mixed in members should always be abstract
              /// and therefore not be handled here, but we handled them here
              /// for consistency.
              registerMixedInOverride(mixedInMember);
            }
          }
        } else if (declaredMember != null) {
          if (declaredMember.isAbstract) {
            ///    class Class {
            ///      method();
            ///    }
            interfaceMember = declaredMember;

            /// Interface members from the declared, extended, and implemented
            /// members define the combined member signature.
            Set<ClassMember> interfaceMembers = {};

            if (extendedMember != null) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Class extends Super {
              ///      method();
              ///    }
              interfaceMembers.add(extendedMember);
            }

            interfaceMembers.add(declaredMember);

            if (implementedMembers != null) {
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Class implements Interface {
              ///      method();
              ///    }
              interfaceMembers.addAll(implementedMembers);
            }

            /// If only one member defines the interface member there is no
            /// need for a synthesized interface member, since its result will
            /// simply be that one member.
            if (interfaceMembers.length > 1) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Class extends Super implements Interface {
              ///      method();
              ///    }
              interfaceMember = new SynthesizedInterfaceMember(
                  classBuilder, name, interfaceMembers.toList(),
                  superClassMember: extendedMember,
                  // [definingMember] and [declaredMember] are always the same
                  // here. Use the latter here and the former below to show the
                  // the member is canonical _because_ its the declared member
                  // and it defines the isProperty/forSetter properties
                  // _because_ it is the defining member.
                  canonicalMember: declaredMember,
                  isProperty: definingMember.isProperty,
                  forSetter: definingMember.forSetter,
                  shouldModifyKernel: shouldModifyKernel);
              hierarchy.registerMemberComputation(interfaceMember);
            }

            if (extendedMember != null) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Class extends Super {
              ///      method();
              ///    }
              ///
              /// The concrete extended member is the class member but might
              /// be overwritten by a concrete forwarding stub:
              ///
              ///    class Super {
              ///      method(int i) {}
              ///    }
              ///    class Interface {
              ///      method(covariant int i) {}
              ///    }
              ///    class Class extends Super implements Interface {
              ///      // This will be turned into the concrete forwarding stub
              ///      //    method(covariant int i) => super.method(i);
              ///      method(int i);
              ///    }
              ///
              classMember = new InheritedClassMemberImplementsInterface(
                  classBuilder, name,
                  inheritedClassMember: extendedMember,
                  implementedInterfaceMember: interfaceMember,
                  forSetter: definingMember.forSetter,
                  isProperty: definingMember.isProperty);
              hierarchy.registerMemberComputation(classMember);

              if (!classBuilder.isAbstract) {
                ///    class Super {
                ///      method() {}
                ///    }
                ///    class Class extends Super {
                ///      method();
                ///    }
                ///
                /// [extendedMember] must implemented interface member.
                registerInheritedImplements(extendedMember, {interfaceMember},
                    aliasForTesting: classMember);
              }
            } else if (!classBuilder.isAbstract) {
              ///    class Class {
              ///      method(); // Missing implementation.
              ///    }
              registerAbstractMember(declaredMember);
            }

            /// The declared member must override extended and implemented
            /// members.
            registerDeclaredOverride(declaredMember,
                aliasForTesting: interfaceMember);
          } else {
            assert(!declaredMember.isAbstract);

            ///    class Class {
            ///      method() {}
            ///    }
            classMember = declaredMember;

            /// The declared member must override extended and implemented
            /// members.
            registerDeclaredOverride(declaredMember);
          }
        } else if (extendedMember != null) {
          ///    class Super {
          ///      method() {}
          ///    }
          ///    class Class extends Super {}
          assert(!extendedMember.isAbstract,
              "Abstract extended member: ${extendedMember}");

          classMember = extendedMember;

          if (implementedMembers != null) {
            ///    class Super {
            ///      method() {}
            ///    }
            ///    class Interface {
            ///      method() {}
            ///    }
            ///    class Class extends Super implements Interface {}
            ClassMember extendedInterfaceMember =
                extendedMember.interfaceMember;

            /// Interface members from the extended and implemented
            /// members define the combined member signature.
            Set<ClassMember> interfaceMembers = {extendedInterfaceMember};

            // TODO(johnniwinther): The extended member might be included in
            // a synthesized implemented member. For instance:
            //
            //    class Super {
            //      void method() {}
            //    }
            //    class Interface {
            //      void method() {}
            //    }
            //    abstract class Class extends Super implements Interface {
            //      // Synthesized interface member of
            //      //   {Super.method, Interface.method}
            //    }
            //    class Sub extends Class {
            //      // Super.method implements Class.method =
            //      //   {Super.method, Interface.method}
            //      // Synthesized interface member of
            //      //   {Super.method, Class.method}
            //    }
            //
            // Maybe we should recognize this.
            interfaceMembers.addAll(implementedMembers);

            /// Normally, if only one member defines the interface member there
            /// is no need for a synthesized interface member, since its result
            /// will simply be that one member, but if the extended member is
            /// from an opt-in library and the current class is from an opt-out
            /// library we need to create a member signature:
            ///
            ///    // Opt-in:
            ///    class Super {
            ///      int? method() => null;
            ///    }
            ///    class Interface implements Super {}
            ///    // Opt-out:
            ///    class Class extends Super implements Interface {
            ///      // Member signature added:
            ///      int* method();
            ///    }
            ///
            if (interfaceMembers.length == 1 &&
                !needsMemberSignatureFor(extendedInterfaceMember)) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Interface implements Super {}
              ///    class Class extends Super implements Interface {}
              interfaceMember = interfaceMembers.first;
            } else {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Class extends Super implements Interface {}
              interfaceMember = new SynthesizedInterfaceMember(
                  classBuilder, name, interfaceMembers.toList(),
                  superClassMember: extendedMember,
                  isProperty: definingMember.isProperty,
                  forSetter: definingMember.forSetter,
                  shouldModifyKernel: shouldModifyKernel);
              hierarchy.registerMemberComputation(interfaceMember);
            }
            if (interfaceMember == classMember) {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Interface implements Super {}
              ///    class Class extends Super implements Interface {}
              ///
              /// We keep track of whether a class needs interfaces, that is,
              /// whether is has any members that have an interface member
              /// different from its corresponding class member, so we set
              /// [interfaceMember] to `null` so show that the interface member
              /// is not needed.
              interfaceMember = null;
            } else {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Class extends Super implements Interface {}
              ///
              /// The concrete extended member is the class member but might
              /// be overwritten by a concrete forwarding stub:
              ///
              ///    class Super {
              ///      method(int i) {}
              ///    }
              ///    class Interface {
              ///      method(covariant int i) {}
              ///    }
              ///    class Class extends Super implements Interface {
              ///      // A concrete forwarding stub will be created:
              ///      //    method(covariant int i) => super.method(i);
              ///    }
              ///
              classMember = new InheritedClassMemberImplementsInterface(
                  classBuilder, name,
                  inheritedClassMember: extendedMember,
                  implementedInterfaceMember: interfaceMember,
                  isProperty: definingMember.isProperty,
                  forSetter: definingMember.forSetter);
              hierarchy.registerMemberComputation(classMember);
              if (!classBuilder.isAbstract) {
                ///    class Super {
                ///      method() {}
                ///    }
                ///    class Interface {
                ///      method() {}
                ///    }
                ///    class Class extends Super implements Interface {}
                registerInheritedImplements(extendedMember, {interfaceMember},
                    aliasForTesting: classMember);
              }
            }
          } else if (needsMemberSignatureFor(extendedMember)) {
            ///    // Opt-in library:
            ///    class Super {
            ///      method() {}
            ///    }
            ///    // opt-out library:
            ///    class Class extends Super {}
            interfaceMember = new SynthesizedInterfaceMember(
                classBuilder, name, [extendedMember],
                superClassMember: extendedMember,
                isProperty: definingMember.isProperty,
                forSetter: definingMember.forSetter,
                shouldModifyKernel: shouldModifyKernel);
            hierarchy.registerMemberComputation(interfaceMember);

            /// The concrete extended member is the class member and should
            /// be able to be overwritten by a synthesized concrete member here,
            /// but we handle the case for consistency.
            classMember = new InheritedClassMemberImplementsInterface(
                classBuilder, name,
                inheritedClassMember: extendedMember,
                implementedInterfaceMember: interfaceMember,
                isProperty: definingMember.isProperty,
                forSetter: definingMember.forSetter);
            hierarchy.registerMemberComputation(classMember);
          }
        } else if (implementedMembers != null) {
          ///    class Interface {
          ///      method() {}
          ///    }
          ///    class Class implements Interface {}
          Set<ClassMember> interfaceMembers = implementedMembers.toSet();
          if (interfaceMembers.isNotEmpty) {
            /// Normally, if only one member defines the interface member there
            /// is no need for a synthesized interface member, since its result
            /// will simply be that one member, but if the implemented member is
            /// from an opt-in library and the current class is from an opt-out
            /// library we need to create a member signature:
            ///
            ///    // Opt-in:
            ///    class Interface {
            ///      int? method() => null;
            ///    }
            ///    // Opt-out:
            ///    class Class implements Interface {
            ///      // Member signature added:
            ///      int* method();
            ///    }
            ///
            if (interfaceMembers.length == 1 &&
                !needsMemberSignatureFor(interfaceMembers.first)) {
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Class implements Interface {}
              interfaceMember = interfaceMembers.first;
            } else {
              ///    class Interface1 {
              ///      method() {}
              ///    }
              ///    class Interface2 {
              ///      method() {}
              ///    }
              ///    class Class implements Interface1, Interface2 {}
              interfaceMember = new SynthesizedInterfaceMember(
                  classBuilder, name, interfaceMembers.toList(),
                  isProperty: definingMember.isProperty,
                  forSetter: definingMember.forSetter,
                  shouldModifyKernel: shouldModifyKernel);
              hierarchy.registerMemberComputation(interfaceMember);
            }
            if (!classBuilder.isAbstract) {
              ///    class Interface {
              ///      method() {}
              ///    }
              ///    class Class implements Interface {}
              for (ClassMember abstractMember in interfaceMembers) {
                registerAbstractMember(abstractMember);
              }
            }
          }
        }

        if (interfaceMember != null) {
          // We have an explicit interface.
          hasInterfaces = true;
        }
        if (classMember != null) {
          if (name == noSuchMethodName &&
              !classMember.isObjectMember(objectClass)) {
            hasNoSuchMethod = true;
          }
          classMemberMap[name] = classMember;
          interfaceMember ??= classMember.interfaceMember;
        }
        if (interfaceMember != null) {
          interfaceMemberMap![name] = interfaceMember;
        }
        return interfaceMember;
      }

      ClassMember? interfaceGetable;
      if (definingGetable != null) {
        interfaceGetable = computeMembers(
            definingMember: definingGetable,
            declaredMember: declaredGetable,
            mixedInMember: mixedInGetable,
            extendedMember: extendedGetable,
            implementedMembers: implementedGetables,
            classMemberMap: classMemberMap,
            interfaceMemberMap: interfaceMemberMap);
      }
      ClassMember? interfaceSetable;
      if (definingSetable != null) {
        interfaceSetable = computeMembers(
            definingMember: definingSetable,
            declaredMember: declaredSetable,
            mixedInMember: mixedInSetable,
            extendedMember: extendedSetable,
            implementedMembers: implementedSetables,
            classMemberMap: classSetterMap,
            interfaceMemberMap: interfaceSetterMap);
      }
      if (classBuilder is SourceClassBuilder) {
        if (interfaceGetable != null &&
            interfaceSetable != null &&
            interfaceGetable.isProperty &&
            interfaceSetable.isProperty &&
            interfaceGetable.isStatic == interfaceSetable.isStatic &&
            !interfaceGetable.isSameDeclaration(interfaceSetable)) {
          /// We need to check that the getter type is a subtype of the setter
          /// type. For instance
          ///
          ///    class Super {
          ///       int get property1 => null;
          ///       num get property2 => null;
          ///    }
          ///    class Mixin {
          ///       void set property1(num value) {}
          ///       void set property2(int value) {}
          ///    }
          ///    class Class = Super with Mixin;
          ///
          /// Here `Super.property1` and `Mixin.property1` form a valid getter/
          /// setter pair in `Class` because the type of the getter
          /// `Super.property1` is a subtype of the setter `Mixin.property1`.
          ///
          /// In contrast the pair `Super.property2` and `Mixin.property2` is
          /// not a valid getter/setter in `Class` because the type of the getter
          /// `Super.property2` is _not_ a subtype of the setter
          /// `Mixin.property1`.
          hierarchy.registerGetterSetterCheck(
              classBuilder as SourceClassBuilder,
              interfaceGetable,
              interfaceSetable);
        }
      }
      if (hasDeclaredMembers) {
        Set<ClassMember> getableOverrides = {};
        Set<ClassMember> setableOverrides = {};
        if (extendedGetable != null) {
          ///    (abstract) class Super {
          ///      method() {}
          ///      int get property => 0;
          ///    }
          ///    (abstract) class Class extends Super {
          ///      method() {}
          ///      set property(int value) {}
          ///    }
          getableOverrides.add(extendedGetable.interfaceMember);
        }
        if (extendedSetable != null) {
          ///    (abstract) class Super {
          ///      set setter(int value) {}
          ///      set property(int value) {}
          ///    }
          ///    (abstract) class Class extends Super {
          ///      set setter(int value) {}
          ///      int get property => 0;
          ///    }
          setableOverrides.add(extendedSetable.interfaceMember);
        }
        if (implementedGetables != null) {
          ///    (abstract) class Interface {
          ///      method() {}
          ///      int get property => 0;
          ///    }
          ///    (abstract) class Class implements Interface {
          ///      method() {}
          ///      set property(int value) {}
          ///    }
          getableOverrides.addAll(implementedGetables);
        }
        if (implementedSetables != null) {
          ///    (abstract) class Interface {
          ///      set setter(int value) {}
          ///      set property(int value) {}
          ///    }
          ///    (abstract) class Class implements Interface {
          ///      set setter(int value) {}
          ///      int get property => 0;
          ///    }
          setableOverrides.addAll(implementedSetables);
        }
        if (getableOverrides.isNotEmpty || setableOverrides.isNotEmpty) {
          if (declaredMethod != null && getableOverrides.isNotEmpty) {
            ///    class Super {
            ///      method() {}
            ///    }
            ///    class Class extends Super {
            ///      method() {}
            ///    }
            declaredOverridesMap[declaredMethod!] = getableOverrides;
          }
          if (declaredProperties != null) {
            Set<ClassMember> overrides;
            if (declaredMethod != null) {
              ///    class Super {
              ///      set setter() {}
              ///    }
              ///    class Class extends Super {
              ///      method() {}
              ///    }
              overrides = setableOverrides;
            } else {
              ///    class Super {
              ///      get property => null
              ///      void set property(value) {}
              ///    }
              ///    class Class extends Super {
              ///      get property => null
              ///      void set property(value) {}
              ///    }
              overrides = {...getableOverrides, ...setableOverrides};
            }
            if (overrides.isNotEmpty) {
              for (ClassMember declaredMember in declaredProperties!) {
                declaredOverridesMap[declaredMember] = overrides;
              }
            }
          }
          if (mixedInMethod != null && getableOverrides.isNotEmpty) {
            ///    class Super {
            ///      method() {}
            ///    }
            ///    class Mixin {
            ///      method() {}
            ///    }
            ///    class Class = Super with Mixin;
            mixinApplicationOverridesMap[mixedInMethod!] = getableOverrides;
          }
          if (mixedInProperties != null) {
            Set<ClassMember> overrides;
            if (mixedInMethod != null) {
              ///    class Super {
              ///      set setter() {}
              ///    }
              ///    class Mixin {
              ///      method() {}
              ///    }
              ///    class Class = Super with Mixin;
              overrides = setableOverrides;
            } else {
              ///    class Super {
              ///      method() {}
              ///    }
              ///    class Mixin extends Super {
              ///      method() {}
              ///    }
              overrides = {...getableOverrides, ...setableOverrides};
            }
            if (overrides.isNotEmpty) {
              for (ClassMember mixedInMember in mixedInProperties!) {
                mixinApplicationOverridesMap[mixedInMember] = overrides;
              }
            }
          }
        }
      }
    });

    if (classBuilder is SourceClassBuilder) {
      // TODO(johnniwinther): Avoid duplicate override check computations
      //  between [declaredOverridesMap], [mixinApplicationOverridesMap] and
      //  [inheritedImplementsMap].

      // TODO(johnniwinther): Ensure that a class member is only checked to
      // validly override another member once. Currently it can happen multiple
      // times as an inherited implementation.

      declaredOverridesMap.forEach(
          (ClassMember classMember, Set<ClassMember> overriddenMembers) {
        /// A declared member can inherit its type from the overridden members.
        ///
        /// We register this with the class member itself so the it can force
        /// computation of type on the overridden members before determining its
        /// own type.
        ///
        /// Member types can be queried at arbitrary points during top level
        /// inference so we need to ensure that types are computed in dependency
        /// order.
        classMember.registerOverrideDependency(overriddenMembers);

        /// Not all member type are queried during top level inference so we
        /// register delayed computation to ensure that all types have been
        /// computed before override checks are performed.
        DelayedTypeComputation computation =
            new DelayedTypeComputation(this, classMember, overriddenMembers);
        hierarchy.registerDelayedTypeComputation(computation);

        /// Declared members must be checked to validly override the
        /// overridden members.
        hierarchy.registerOverrideCheck(
            classBuilder as SourceClassBuilder, classMember, overriddenMembers);
      });

      mixinApplicationOverridesMap.forEach(
          (ClassMember classMember, Set<ClassMember> overriddenMembers) {
        /// Declared mixed in members must be checked to validly override the
        /// overridden members.
        hierarchy.registerOverrideCheck(
            classBuilder as SourceClassBuilder, classMember, overriddenMembers);
      });

      inheritedImplementsMap.forEach(
          (ClassMember classMember, Set<ClassMember> overriddenMembers) {
        /// Concrete members must be checked to validly override the overridden
        /// members in concrete classes.
        hierarchy.registerOverrideCheck(
            classBuilder as SourceClassBuilder, classMember, overriddenMembers);
      });
    }

    if (!hasInterfaces) {
      /// All interface members also class members to we don't need to store
      /// the interface members separately.
      assert(
          classMemberMap.length == interfaceMemberMap.length,
          "Class/interface member mismatch. Class members: "
          "$classMemberMap, interface members: $interfaceMemberMap.");
      assert(
          classSetterMap.length == interfaceSetterMap.length,
          "Class/interface setter mismatch. Class setters: "
          "$classSetterMap, interface setters: $interfaceSetterMap.");
      assert(
          classMemberMap.keys.every((Name name) =>
              identical(classMemberMap[name], interfaceMemberMap?[name])),
          "Class/interface member mismatch. Class members: "
          "$classMemberMap, interface members: $interfaceMemberMap.");
      assert(
          classSetterMap.keys.every((Name name) =>
              identical(classSetterMap[name], interfaceSetterMap?[name])),
          "Class/interface setter mismatch. Class setters: "
          "$classSetterMap, interface setters: $interfaceSetterMap.");
      interfaceMemberMap = null;
      interfaceSetterMap = null;
    }

    // ignore: unnecessary_null_comparison
    if (abstractMembers != null && !classBuilder.isAbstract) {
      if (!hasNoSuchMethod) {
        reportMissingMembers(abstractMembers);
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
        dataForTesting);
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
          new List<DartType>.filled(arguments.length, dummyDartType);
      List<TypeParameter> typeParameters =
          new List<TypeParameter>.filled(arguments.length, dummyTypeParameter);
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

  void addInterface(List<Supertype> interfaces, List<Supertype> superclasses,
      Supertype type) {
    // ignore: unnecessary_null_comparison
    if (type == null) return null;
    if (!classBuilder.library.isNonNullableByDefault) {
      type = legacyErasureSupertype(type);
    }
    ClassHierarchyNode node = hierarchy.getNodeFromClass(type.classNode);
    // ignore: unnecessary_null_comparison
    if (node == null) return null;
    int depth = node.depth;
    int myDepth = superclasses.length;
    Supertype? superclass = depth < myDepth ? superclasses[depth] : null;
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
        Supertype? interface = interfaces[i];
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

  void reportMissingMembers(List<ClassMember> abstractMembers) {
    Map<String, LocatedMessage> contextMap = <String, LocatedMessage>{};
    for (ClassMember declaration in unfoldDeclarations(abstractMembers)) {
      if (isNameVisibleIn(declaration.name, classBuilder.library)) {
        String name = declaration.fullNameForErrors;
        String className = declaration.classBuilder.fullNameForErrors;
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
      context.add(contextMap[names[i]]!);
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
    Supertype? mixedInType = cls.mixedInType;
    if (mixedInType == null) return;
    List<DartType> typeArguments = mixedInType.typeArguments;
    if (typeArguments.isEmpty || typeArguments.first is! UnknownType) return;
    new BuilderMixinInferrer(
            classBuilder,
            hierarchy.coreTypes,
            new TypeBuilderConstraintGatherer(hierarchy,
                mixedInType.classNode.typeParameters, cls.enclosingLibrary))
        .infer(cls);
    List<TypeBuilder> inferredArguments = new List<TypeBuilder>.generate(
        typeArguments.length,
        (int i) => hierarchy.loader.computeTypeBuilder(typeArguments[i]),
        growable: false);
    NamedTypeBuilder mixedInTypeBuilder =
        classBuilder.mixedInTypeBuilder as NamedTypeBuilder;
    mixedInTypeBuilder.arguments = inferredArguments;
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
  final Map<Name, ClassMember>? interfaceMemberMap;

  /// Similar to [interfaceMembers] but for setters.
  ///
  /// This may be null, in which case [classSetters] is the interface setters.
  final Map<Name, ClassMember>? interfaceSetterMap;

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

  final ClassHierarchyNodeDataForTesting? dataForTesting;

  ClassHierarchyNode(
      this.classBuilder,
      this.classMemberMap,
      this.classSetterMap,
      this.interfaceMemberMap,
      this.interfaceSetterMap,
      this.superclasses,
      this.interfaces,
      this.maxInheritancePath,
      this.hasNoSuchMethod,
      this.dataForTesting);

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
    // ignore: unnecessary_null_comparison
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
      printMemberMap(interfaceMemberMap!, sb, "interfaceMembers");
    }
    if (interfaceSetterMap != null) {
      printMemberMap(interfaceSetterMap!, sb, "interfaceSetters");
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

  ClassMember? getInterfaceMember(Name name, bool isSetter) {
    return isSetter
        ? (interfaceSetterMap ?? classSetterMap)[name]
        : (interfaceMemberMap ?? classMemberMap)[name];
  }

  ClassMember? findMember(Name name, List<ClassMember> declarations) {
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

  ClassMember? getDispatchTarget(Name name, bool isSetter) {
    return isSetter ? classSetterMap[name] : classMemberMap[name];
  }

  static int compareMaxInheritancePath(
      ClassHierarchyNode a, ClassHierarchyNode b) {
    return b.maxInheritancePath.compareTo(a.maxInheritancePath);
  }
}

class ClassHierarchyNodeDataForTesting {
  final List<ClassMember> abstractMembers;
  final Map<ClassMember, Set<ClassMember>> declaredOverrides;
  final Map<ClassMember, Set<ClassMember>> mixinApplicationOverrides;
  final Map<ClassMember, Set<ClassMember>> inheritedImplements;
  final Map<ClassMember, ClassMember> aliasMap = {};

  ClassHierarchyNodeDataForTesting(this.abstractMembers, this.declaredOverrides,
      this.mixinApplicationOverrides, this.inheritedImplements);
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

  @override
  Supertype? asInstantiationOf(Supertype type, Class superclass) {
    List<DartType>? arguments =
        gatherer.getTypeArgumentsAsInstanceOf(type.asInterfaceType, superclass);
    if (arguments == null) return null;
    return new Supertype(superclass, arguments);
  }

  @override
  void reportProblem(Message message, Class kernelClass) {
    int length = cls.isMixinApplication ? 1 : cls.fullNameForErrors.length;
    cls.addProblem(message, cls.charOffset, length);
  }
}

class TypeBuilderConstraintGatherer extends TypeConstraintGatherer
    with StandardBounds, TypeSchemaStandardBounds {
  @override
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
  Member? getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    return null;
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes) {
    return hierarchy.getTypeAsInstanceOf(type, superclass, clientLibrary);
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
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
  final SourceClassBuilder _classBuilder;
  final ClassMember _declaredMember;
  final Set<ClassMember> _overriddenMembers;

  DelayedOverrideCheck(
      this._classBuilder, this._declaredMember, this._overriddenMembers);

  @override
  void check(ClassHierarchyBuilder hierarchy) {
    Member declaredMember = _declaredMember.getMember(hierarchy);

    /// If [_declaredMember] is a class member that is declared in an opt-in
    /// library but inherited to [_classBuilder] through an opt-out class then
    /// we need to apply legacy erasure to the declared type to get the
    /// inherited type.
    ///
    /// For interface members this is handled by member signatures but since
    /// these are abstract they will never be the inherited class member.
    ///
    /// For instance:
    ///
    ///    // Opt in:
    ///    class Super {
    ///      int extendedMethod(int i, {required int j}) => i;
    ///    }
    ///    class Mixin {
    ///      int mixedInMethod(int i, {required int j}) => i;
    ///    }
    ///    // Opt out:
    ///    class Legacy extends Super with Mixin {}
    ///    // Opt in:
    ///    class Class extends Legacy {
    ///      // Valid overrides since the type of `Legacy.extendedMethod` is
    ///      // `int* Function(int*, {int* j})`.
    ///      int? extendedMethod(int? i, {int? j}) => i;
    ///      // Valid overrides since the type of `Legacy.mixedInMethod` is
    ///      // `int* Function(int*, {int* j})`.
    ///      int? mixedInMethod(int? i, {int? j}) => i;
    ///    }
    ///
    bool declaredNeedsLegacyErasure =
        needsLegacyErasure(_classBuilder.cls, declaredMember.enclosingClass!);
    void callback(Member interfaceMember, bool isSetter) {
      _classBuilder.checkOverride(
          hierarchy.types, declaredMember, interfaceMember, isSetter, callback,
          isInterfaceCheck: !_classBuilder.isMixinApplication,
          declaredNeedsLegacyErasure: declaredNeedsLegacyErasure);
    }

    for (ClassMember overriddenMember in _overriddenMembers) {
      callback(overriddenMember.getMember(hierarchy), _declaredMember.isSetter);
    }
  }
}

class DelayedGetterSetterCheck implements DelayedCheck {
  final SourceClassBuilder classBuilder;
  final ClassMember getter;
  final ClassMember setter;

  const DelayedGetterSetterCheck(this.classBuilder, this.getter, this.setter);

  @override
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

int compareNamedParameters(VariableDeclaration a, VariableDeclaration b) {
  return a.name!.compareTo(b.name!);
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

ClassBuilder? getClass(TypeBuilder type) {
  Builder? declaration = type.declaration;
  if (declaration is TypeAliasBuilder) {
    TypeAliasBuilder aliasBuilder = declaration;
    NamedTypeBuilder namedBuilder = type as NamedTypeBuilder;
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

Set<ClassMember> unfoldDeclarations(Iterable<ClassMember> members) {
  Set<ClassMember> result = <ClassMember>{};
  _unfoldDeclarations(members, result);
  return result;
}

void _unfoldDeclarations(
    Iterable<ClassMember> members, Set<ClassMember> result) {
  for (ClassMember member in members) {
    if (member.hasDeclarations) {
      _unfoldDeclarations(member.declarations, result);
    } else {
      result.add(member);
    }
  }
}

abstract class SynthesizedMember extends ClassMember {
  @override
  final ClassBuilder classBuilder;

  @override
  final Name name;

  @override
  final bool forSetter;

  @override
  final bool isProperty;

  SynthesizedMember(this.classBuilder, this.name,
      {required this.forSetter, required this.isProperty})
      // ignore: unnecessary_null_comparison
      : assert(forSetter != null),
        // ignore: unnecessary_null_comparison
        assert(isProperty != null);

  @override
  List<ClassMember> get declarations => throw new UnimplementedError();

  @override
  void inferType(ClassHierarchyBuilder hierarchy) {}

  @override
  bool get isAssignable => throw new UnimplementedError();

  @override
  bool get isConst => throw new UnimplementedError();

  @override
  bool get isDuplicate => false;

  @override
  bool get isField => throw new UnimplementedError();

  @override
  bool get isFinal => throw new UnimplementedError();

  @override
  bool get isGetter => throw new UnimplementedError();

  @override
  bool get isInternalImplementation => false;

  @override
  bool get isSetter => forSetter;

  @override
  bool get isSourceDeclaration => false;

  @override
  bool get isStatic => false;

  @override
  bool get isSynthesized => true;

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {}
}

/// Class member for a set of interface members.
///
/// This is used to compute combined member signature of a set of interface
/// members inherited into the same class, and to insert forwarding stubs,
/// mixin stubs, and member signatures where needed.
class SynthesizedInterfaceMember extends SynthesizedMember {
  @override
  final List<ClassMember> declarations;

  /// The concrete member in the super class overridden by [declarations], if
  /// any.
  ///
  /// This is used to as the target when creating concrete forwarding and mixin
  /// stub. For instance:
  ///
  ///    class Super {
  ///      method(int i) {}
  ///    }
  ///    class Interface {
  ///      method(covariant int i) {}
  ///    }
  ///    class Class extends Super implements Interface {
  ///      // Concrete forwarding stub calling [_superClassMember]:
  ///      method(covariant int i) => super.method(i);
  ///
  final ClassMember? _superClassMember;

  /// The canonical member of the combined member signature if it is known by
  /// construction. The canonical member defines the type of combined member
  /// signature.
  ///
  /// This is used when a declared member is part of a set of implemented
  /// members. For instance
  ///
  ///     class Super {
  ///       method(int i) {}
  ///     }
  ///     class Interface {
  ///       method(covariant num i) {}
  ///     }
  ///     class Class implements Interface {
  ///       // This member is updated to be a concrete forwarding stub with an
  ///       // covariant parameter but with its declared parameter type:
  ///       //    method(covariant int i) => super.method(i);
  ///       method(int i);
  ///     }
  final ClassMember? _canonicalMember;

  /// The member in [declarations] that is mixed in, if any.
  ///
  /// This is used to create mixin stubs. If the mixed in member is abstract,
  /// an abstract mixin stub is created:
  ///
  ///    class Super {
  ///      void method() {}
  ///    }
  ///    class Mixin {
  ///      void method();
  ///    }
  ///    // Abstract mixin stub with `Mixin.method` as target inserted:
  ///    //   void method();
  ///    class Class = Super with Mixin;
  ///
  /// If the mixed in member is concrete, a concrete mixin member is created:
  ///
  ///    class Super {
  ///      void method() {}
  ///    }
  ///    class Mixin {
  ///      void method() {}
  ///    }
  ///    // Concrete mixin stub with `Mixin.method` as target inserted:
  ///    //   void method() => super.method();
  ///    class Class = Super with Mixin;
  ///
  /// If a forwarding stub is needed, the created stub will be a possibly
  /// concrete forwarding stub:
  ///
  ///    class Super {
  ///      void method(int i) {}
  ///    }
  ///    class Interface {
  ///      void method(covariant num i) {}
  ///    }
  ///    class Mixin {
  ///      void method(int i);
  ///    }
  ///    // Concrete forwarding stub with `Super.method` as target inserted:
  ///    //   void method(covariant int i) => super.method(i);
  ///    class Class = Super with Mixin implements Interface;
  ///
  final ClassMember? _mixedInMember;

  /// If `true`, a stub should be inserted, if needed.
  final bool _shouldModifyKernel;

  Member? _member;
  Covariance? _covariance;

  SynthesizedInterfaceMember(
      ClassBuilder classBuilder, Name name, this.declarations,
      {ClassMember? superClassMember,
      ClassMember? canonicalMember,
      ClassMember? mixedInMember,
      required bool isProperty,
      required bool forSetter,
      required bool shouldModifyKernel})
      : this._superClassMember = superClassMember,
        this._canonicalMember = canonicalMember,
        this._mixedInMember = mixedInMember,
        this._shouldModifyKernel = shouldModifyKernel,
        super(classBuilder, name, isProperty: isProperty, forSetter: forSetter);

  @override
  bool get hasDeclarations => true;

  void _ensureMemberAndCovariance(ClassHierarchyBuilder hierarchy) {
    if (_member != null) {
      return;
    }
    if (classBuilder.library is! SourceLibraryBuilder) {
      if (_canonicalMember != null) {
        _member = _canonicalMember!.getMember(hierarchy);
        _covariance = _canonicalMember!.getCovariance(hierarchy);
      } else {
        _member = declarations.first.getMember(hierarchy);
        _covariance = declarations.first.getCovariance(hierarchy);
      }
      return;
    }
    CombinedClassMemberSignature combinedMemberSignature;
    if (_canonicalMember != null) {
      combinedMemberSignature = new CombinedClassMemberSignature.internal(
          hierarchy,
          classBuilder as SourceClassBuilder,
          declarations.indexOf(_canonicalMember!),
          declarations,
          forSetter: isSetter);
    } else {
      combinedMemberSignature = new CombinedClassMemberSignature(
          hierarchy, classBuilder as SourceClassBuilder, declarations,
          forSetter: isSetter);

      if (combinedMemberSignature.canonicalMember == null) {
        String name = classBuilder.fullNameForErrors;
        int length = classBuilder.isAnonymousMixinApplication ? 1 : name.length;
        List<LocatedMessage> context = declarations.map((ClassMember d) {
          return messageDeclaredMemberConflictsWithOverriddenMembersCause
              .withLocation(
                  d.fileUri, d.charOffset, d.fullNameForErrors.length);
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
    }

    if (_shouldModifyKernel) {
      ProcedureKind kind = ProcedureKind.Method;
      Member canonicalMember =
          combinedMemberSignature.canonicalMember!.getMember(hierarchy);
      if (combinedMemberSignature.canonicalMember!.isProperty) {
        kind = isSetter ? ProcedureKind.Setter : ProcedureKind.Getter;
      } else if (canonicalMember is Procedure &&
          canonicalMember.kind == ProcedureKind.Operator) {
        kind = ProcedureKind.Operator;
      }

      Procedure? stub = new ForwardingNode(
              combinedMemberSignature, kind, _superClassMember, _mixedInMember)
          .finalize();
      if (stub != null) {
        assert(classBuilder.cls == stub.enclosingClass);
        assert(stub != canonicalMember);
        classBuilder.cls.addProcedure(stub);
        SourceLibraryBuilder library =
            classBuilder.library as SourceLibraryBuilder;
        if (canonicalMember is Procedure) {
          library.forwardersOrigins
            ..add(stub)
            ..add(canonicalMember);
        }
        _member = stub;
        _covariance = combinedMemberSignature.combinedMemberSignatureCovariance;
        assert(
            _covariance ==
                new Covariance.fromMember(_member!, forSetter: forSetter),
            "Unexpected covariance for combined members signature "
            "$_member. Found $_covariance, expected "
            "${new Covariance.fromMember(_member!, forSetter: forSetter)}.");
        return;
      }
    }

    _member = combinedMemberSignature.canonicalMember!.getMember(hierarchy);
    _covariance = combinedMemberSignature.combinedMemberSignatureCovariance;
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _member!;
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _covariance!;
  }

  @override
  ClassMember get interfaceMember => this;

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return false;
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    // TODO(johnniwinther): Optimize this.
    return false;
  }

  @override
  int get charOffset => declarations.first.charOffset;

  @override
  Uri get fileUri => declarations.first.fileUri;

  @override
  bool get isAbstract => true;

  @override
  String get fullNameForErrors =>
      declarations.map((ClassMember m) => m.fullName).join("%");

  @override
  String get fullName {
    String suffix = isSetter ? "=" : "";
    return "${fullNameForErrors}$suffix";
  }

  @override
  String toString() => 'SynthesizedInterfaceMember($classBuilder,$name,'
      '$declarations,forSetter=$forSetter)';
}

/// Class member for an inherited concrete member that implements an interface
/// member.
///
/// This is used to ensure that both the inherited concrete member and the
/// interface member is taken into account when computing the resulting [Member]
/// node.
///
/// This is needed because an interface member, though initially abstract, can
/// result in a concrete stub that overrides the concrete member. For instance
///
///    class Super {
///      method(int i) {}
///    }
///    class Interface {
///      method(covariant int i) {}
///    }
///    class Class extends Super implements Interface {
///      // A concrete forwarding stub is inserted:
///      method(covariant int i) => super.method(i);
///    }
///    class Sub extends Class implements Interface {
///      // No forwarding stub should be inserted since `Class.method` is
///      // adequate.
///    }
///
///
///  Here the create stub `Class.method` overrides `Super.method` and should
///  be used to determine whether to insert a forwarding stub in subclasses.
class InheritedClassMemberImplementsInterface extends SynthesizedMember {
  final ClassMember inheritedClassMember;
  final ClassMember implementedInterfaceMember;

  Member? _member;
  Covariance? _covariance;

  InheritedClassMemberImplementsInterface(ClassBuilder classBuilder, Name name,
      {required this.inheritedClassMember,
      required this.implementedInterfaceMember,
      required bool isProperty,
      required bool forSetter})
      // ignore: unnecessary_null_comparison
      : assert(inheritedClassMember != null),
        // ignore: unnecessary_null_comparison
        assert(implementedInterfaceMember != null),
        super(classBuilder, name, isProperty: isProperty, forSetter: forSetter);

  void _ensureMemberAndCovariance(ClassHierarchyBuilder hierarchy) {
    if (_member == null) {
      Member classMember = inheritedClassMember.getMember(hierarchy);
      Member interfaceMember = implementedInterfaceMember.getMember(hierarchy);
      if (!interfaceMember.isAbstract &&
          interfaceMember.enclosingClass == classBuilder.cls) {
        /// The interface member resulted in a concrete stub being inserted.
        /// For instance for `method1` but _not_ for `method2` here:
        ///
        ///    class Super {
        ///      method1(int i) {}
        ///      method2(covariant int i) {}
        ///    }
        ///    class Interface {
        ///      method1(covariant int i) {}
        ///      method2(int i) {}
        ///    }
        ///    class Class extends Super implements Interface {
        ///      // A concrete forwarding stub is inserted for `method1` since
        ///      // the parameter on `Super.method1` is _not_ marked as
        ///      // covariant:
        ///      method1(covariant int i) => super.method(i);
        ///      // No concrete forwarding stub is inserted for `method2` since
        ///      // the parameter on `Super.method2` is already marked as
        ///      // covariant.
        ///    }
        ///
        /// The inserted stub should be used as the resulting member.
        _member = interfaceMember;
        _covariance = implementedInterfaceMember.getCovariance(hierarchy);
      } else {
        /// The interface member did not result in an inserted stub or the
        /// inserted stub was abstract. For instance:
        ///
        ///    // Opt-in:
        ///    class Super {
        ///      method(int? i) {}
        ///    }
        ///    // Opt-out:
        ///    class Class extends Super {
        ///      // An abstract member signature stub is inserted:
        ///      method(int* i);
        ///    }
        ///
        /// The inserted stub should _not_ be used as the resulting member
        /// since it is abstract and therefore not a class member.
        _member = classMember;
        _covariance = inheritedClassMember.getCovariance(hierarchy);
      }
    }
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _member!;
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    _ensureMemberAndCovariance(hierarchy);
    return _covariance!;
  }

  @override
  ClassMember get interfaceMember => implementedInterfaceMember;

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return inheritedClassMember.isObjectMember(objectClass);
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    // TODO(johnniwinther): Optimize this.
    return false;
  }

  @override
  int get charOffset => inheritedClassMember.charOffset;

  @override
  Uri get fileUri => inheritedClassMember.fileUri;

  @override
  bool get hasDeclarations => false;

  @override
  bool get isAbstract => false;

  @override
  String get fullNameForErrors => inheritedClassMember.fullNameForErrors;

  @override
  String get fullName => inheritedClassMember.fullName;

  @override
  String toString() =>
      'InheritedClassMemberImplementsInterface($classBuilder,$name,'
      'inheritedClassMember=$inheritedClassMember,'
      'implementedInterfaceMember=$implementedInterfaceMember,'
      'forSetter=$forSetter)';
}
