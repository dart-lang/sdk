// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/nnbd_top_merge.dart';
import 'package:kernel/src/norm.dart';

import '../../../base/common.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/library_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../messages.dart'
    show
        LocatedMessage,
        messageDeclaredMemberConflictsWithInheritedMember,
        messageDeclaredMemberConflictsWithInheritedMemberCause,
        messageDeclaredMemberConflictsWithOverriddenMembersCause,
        messageEnumAbstractMember,
        messageInheritedMembersConflict,
        messageInheritedMembersConflictCause1,
        messageInheritedMembersConflictCause2,
        messageStaticAndInstanceConflict,
        messageStaticAndInstanceConflictCause,
        templateCantInferTypesDueToNoCombinedSignature,
        templateCantInferReturnTypeDueToNoCombinedSignature,
        templateCantInferTypeDueToNoCombinedSignature,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateInstanceAndSynthesizedStaticConflict,
        templateMissingImplementationCause,
        templateMissingImplementationNotAbstract;
import '../../names.dart' show noSuchMethodName;
import '../../source/source_class_builder.dart';
import '../../source/source_field_builder.dart';
import '../../source/source_procedure_builder.dart';
import '../combined_member_signature.dart';
import '../member_covariance.dart';
import 'class_member.dart';
import 'delayed.dart';
import 'hierarchy_builder.dart';
import 'hierarchy_node.dart';
import 'members_builder.dart';

abstract class MembersNodeBuilder {
  DeclarationBuilder get declarationBuilder;

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

  void reportInheritanceConflict(ClassMember a, ClassMember b) {
    String name = a.fullNameForErrors;
    while (a.hasDeclarations) {
      a = a.declarations.first;
    }
    while (b.hasDeclarations) {
      b = b.declarations.first;
    }
    if (a.declarationBuilder != b.declarationBuilder) {
      if (a.declarationBuilder == declarationBuilder) {
        declarationBuilder.addProblem(
            messageDeclaredMemberConflictsWithInheritedMember,
            a.charOffset,
            name.length,
            context: <LocatedMessage>[
              messageDeclaredMemberConflictsWithInheritedMemberCause
                  .withLocation(b.fileUri, b.charOffset, name.length)
            ]);
      } else if (b.declarationBuilder == declarationBuilder) {
        declarationBuilder.addProblem(
            messageDeclaredMemberConflictsWithInheritedMember,
            b.charOffset,
            name.length,
            context: <LocatedMessage>[
              messageDeclaredMemberConflictsWithInheritedMemberCause
                  .withLocation(a.fileUri, a.charOffset, name.length)
            ]);
      } else {
        declarationBuilder.addProblem(
            messageInheritedMembersConflict,
            declarationBuilder.charOffset,
            declarationBuilder.fullNameForErrors.length,
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
      if (!staticMember.isSynthesized) {
        declarationBuilder.libraryBuilder.addProblem(
            messageStaticAndInstanceConflict,
            staticMember.charOffset,
            name.length,
            staticMember.fileUri,
            context: <LocatedMessage>[
              messageStaticAndInstanceConflictCause.withLocation(
                  instanceMember.fileUri,
                  instanceMember.charOffset,
                  name.length)
            ]);
      } else {
        declarationBuilder.libraryBuilder.addProblem(
            templateInstanceAndSynthesizedStaticConflict
                .withArguments(staticMember.name.text),
            instanceMember.charOffset,
            name.length,
            instanceMember.fileUri);
      }
    } else {
      // This message can be reported twice (when merging localMembers with
      // classSetters, or localSetters with classMembers). By ensuring that
      // we always report the one with higher charOffset as the duplicate,
      // the message duplication logic ensures that we only report this
      // problem once.
      ClassMember existing;
      ClassMember duplicate;
      assert(a.fileUri == b.fileUri ||
          a.name.text == "toString" &&
              (a.fileUri.isScheme("org-dartlang-sdk") &&
                      a.fileUri.pathSegments.isNotEmpty &&
                      a.fileUri.pathSegments.last == "enum.dart" ||
                  b.fileUri.isScheme("org-dartlang-sdk") &&
                      b.fileUri.pathSegments.isNotEmpty &&
                      b.fileUri.pathSegments.last == "enum.dart"));

      if (a.fileUri != b.fileUri) {
        if (a.fileUri.isScheme("org-dartlang-sdk")) {
          existing = a;
          duplicate = b;
        } else {
          assert(b.fileUri.isScheme("org-dartlang-sdk"));
          existing = b;
          duplicate = a;
        }
      } else {
        if (a.charOffset < b.charOffset) {
          existing = a;
          duplicate = b;
        } else {
          existing = b;
          duplicate = a;
        }
      }
      declarationBuilder.libraryBuilder.addProblem(
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
}

class ClassMembersNodeBuilder extends MembersNodeBuilder {
  final ClassHierarchyNode _hierarchyNode;
  final ClassMembersBuilder _membersBuilder;

  ClassMembersNodeBuilder(this._membersBuilder, this._hierarchyNode);

  ClassHierarchyBuilder get hierarchy => _membersBuilder.hierarchyBuilder;

  ClassBuilder get objectClass => hierarchy.objectClassBuilder;

  ClassBuilder get classBuilder => _hierarchyNode.classBuilder;

  @override
  DeclarationBuilder get declarationBuilder => classBuilder;

  bool get shouldModifyKernel =>
      classBuilder.libraryBuilder.loader == hierarchy.loader;

  static void inferMethodType(
      ClassHierarchyBuilder hierarchyBuilder,
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder classBuilder,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(!declaredMember.isGetter && !declaredMember.isSetter);
    if (declaredMember.classBuilder == classBuilder &&
        (declaredMember.returnType is InferableTypeBuilder ||
            declaredMember.formals != null &&
                declaredMember.formals!.any(
                    (parameter) => parameter.type is InferableTypeBuilder))) {
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
      CombinedMemberSignatureBase combinedMemberSignature =
          new CombinedClassMemberSignature(
              membersBuilder, classBuilder, overriddenMemberSet.toList(),
              forSetter: false);
      FunctionType? combinedMemberSignatureType = combinedMemberSignature
              .getCombinedSignatureTypeInContext(declaredTypeParameters)
          as FunctionType?;

      bool cantInferReturnType = false;
      List<FormalParameterBuilder>? cantInferParameterTypes;

      if (declaredMember.returnType is InferableTypeBuilder) {
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
          if (declaredParameter.type is! InferableTypeBuilder) {
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
          if (declaredParameter.type is! InferableTypeBuilder) {
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
        reportCantInferTypes(classBuilder, declaredMember, overriddenMembers);
      } else if (cantInferReturnType) {
        reportCantInferReturnType(
            classBuilder, declaredMember, overriddenMembers);
      } else if (cantInferParameterTypes != null) {
        reportCantInferParameterType(
            classBuilder, cantInferParameterTypes.single, overriddenMembers);
      }

      if (declaredMember.returnType is InferableTypeBuilder) {
        inferredReturnType ??= const DynamicType();
        declaredMember.returnType.registerInferredType(inferredReturnType);
      }
      if (declaredMember.formals != null) {
        for (FormalParameterBuilder declaredParameter
            in declaredMember.formals!) {
          if (declaredParameter.type is InferableTypeBuilder) {
            DartType inferredParameterType =
                inferredParameterTypes[declaredParameter] ??
                    const DynamicType();
            declaredParameter.type.registerInferredType(inferredParameterType);
          }
        }
      }
    }
  }

  void inferMethodSignature(ClassMembersBuilder membersBuilder,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    assert(!declaredMember.isGetter && !declaredMember.isSetter);
    // Trigger computation of method type.
    Procedure declaredProcedure =
        declaredMember.getMember(membersBuilder) as Procedure;
    for (ClassMember overriddenMember
        in toSet(declaredMember.declarationBuilder, overriddenMembers)) {
      Covariance covariance = overriddenMember.getCovariance(membersBuilder);
      covariance.applyCovariance(declaredProcedure);
    }
  }

  void inferGetterSignature(ClassMembersBuilder membersBuilder,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isGetter);
    // Trigger computation of the getter type.
    declaredMember.getMember(membersBuilder);
    // Otherwise nothing to do. Getters have no variance.
  }

  void inferSetterSignature(ClassMembersBuilder membersBuilder,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isSetter);
    // Trigger computation of the getter type.
    Procedure declaredSetter =
        declaredMember.getMember(membersBuilder) as Procedure;
    for (ClassMember overriddenMember
        in toSet(declaredMember.declarationBuilder, overriddenMembers)) {
      Covariance covariance = overriddenMember.getCovariance(membersBuilder);
      covariance.applyCovariance(declaredSetter);
    }
  }

  static void inferGetterType(
      ClassHierarchyBuilder hierarchyBuilder,
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder classBuilder,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isGetter);
    if (declaredMember.classBuilder == classBuilder &&
        declaredMember.returnType is InferableTypeBuilder) {
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
        CombinedMemberSignatureBase combinedMemberSignature =
            new CombinedClassMemberSignature(
                membersBuilder, classBuilder, members,
                forSetter: forSetter);
        DartType? combinedMemberSignatureType =
            combinedMemberSignature.combinedMemberSignatureType;
        if (combinedMemberSignatureType == null) {
          inferredType = const InvalidType();
          reportCantInferReturnType(classBuilder, declaredMember, members);
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

      declaredMember.returnType
          .registerInferredType(inferredType ?? const DynamicType());
    }
  }

  static void inferSetterType(
      ClassHierarchyBuilder hierarchyBuilder,
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder classBuilder,
      SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    assert(declaredMember.isSetter);
    List<FormalParameterBuilder>? formals = declaredMember.formals;
    if (formals == null) {
      // Erroneous case.
      return;
    }
    FormalParameterBuilder parameter = formals.first;
    if (declaredMember.classBuilder == classBuilder &&
        parameter.type is InferableTypeBuilder) {
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
        CombinedMemberSignatureBase combinedMemberSignature =
            new CombinedClassMemberSignature(
                membersBuilder, classBuilder, members,
                forSetter: forSetter);
        DartType? combinedMemberSignatureType =
            combinedMemberSignature.combinedMemberSignatureType;
        if (combinedMemberSignatureType == null) {
          inferredType = const InvalidType();
          reportCantInferReturnType(classBuilder, declaredMember, members);
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

      parameter.type.registerInferredType(inferredType ?? const DynamicType());
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
    if (classBuilder.libraryBuilder.isNonNullableByDefault) {
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
      ClassHierarchyBuilder hierarchyBuilder,
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder classBuilder,
      SourceFieldBuilder fieldBuilder,
      Iterable<ClassMember> overriddenMembers) {
    if (fieldBuilder.classBuilder == classBuilder &&
        fieldBuilder.type is InferableTypeBuilder) {
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
        CombinedMemberSignatureBase combinedMemberSignature =
            new CombinedClassMemberSignature(
                membersBuilder, classBuilder, members,
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

      fieldBuilder.type.registerInferredType(inferredType);
    }
  }

  /// Infers the field signature of [declaredMember] based on
  /// [overriddenMembers].
  void inferFieldSignature(ClassMembersBuilder membersBuilder,
      ClassMember declaredMember, Iterable<ClassMember> overriddenMembers) {
    Field declaredField = declaredMember.getMember(membersBuilder) as Field;
    for (ClassMember overriddenMember
        in toSet(declaredMember.declarationBuilder, overriddenMembers)) {
      Covariance covariance = overriddenMember.getCovariance(membersBuilder);
      covariance.applyCovariance(declaredField);
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
    return !classBuilder.libraryBuilder.isNonNullableByDefault &&
        classMember.declarationBuilder.libraryBuilder.isNonNullableByDefault;
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
  void registerAbstractMember(
      List<ClassMember> abstractMembers, ClassMember abstractMember) {
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

  /// Set to `true` during [build] if the class needs interfaces, that is, if it
  /// has any members where the interface member is different from its
  /// corresponding class members.
  ///
  /// This is an optimization to avoid unnecessary computation of interface
  /// members.
  bool _hasInterfaces = false;

  ClassMembersNode build() {
    ClassMembersNode? supernode = _hierarchyNode.directSuperClassNode != null
        ? _membersBuilder.getNodeFromClassBuilder(
            _hierarchyNode.directSuperClassNode!.classBuilder)
        : null;
    List<ClassHierarchyNode>? interfaceNodes =
        _hierarchyNode.directInterfaceNodes;

    /// Concrete user defined `noSuchMethod` member, declared or inherited. I.e.
    /// concrete `noSuchMethod` class member that is _not_
    /// `Object.noSuchMethod`.
    ClassMember? userNoSuchMethodMember;

    Map<Name, _Tuple> memberMap = {};

    Iterator<MemberBuilder> iterator =
        classBuilder.fullMemberIterator<MemberBuilder>();
    while (iterator.moveNext()) {
      MemberBuilder memberBuilder = iterator.current;
      for (ClassMember classMember in memberBuilder.localMembers) {
        Name name = classMember.name;
        if (classMember.isAbstract) {
          _hasInterfaces = true;
        }
        _Tuple? tuple = memberMap[name];
        if (tuple == null) {
          memberMap[name] = new _Tuple.declareMember(classMember);
        } else {
          tuple.declaredMember = classMember;
        }
        if (name == noSuchMethodName &&
            !classMember.isAbstract &&
            !classMember.isObjectMember(objectClass)) {
          userNoSuchMethodMember = classMember;
        }
      }
      for (ClassMember classMember in memberBuilder.localSetters) {
        Name name = classMember.name;
        if (classMember.isAbstract) {
          _hasInterfaces = true;
        }
        _Tuple? tuple = memberMap[name];
        if (tuple == null) {
          memberMap[name] = new _Tuple.declareSetter(classMember);
        } else {
          tuple.declaredSetter = classMember;
        }
      }
    }

    if (classBuilder.isMixinApplication) {
      TypeBuilder mixedInTypeBuilder = classBuilder.mixedInTypeBuilder!;
      TypeDeclarationBuilder mixin = mixedInTypeBuilder.declaration!;
      while (mixin.isNamedMixinApplication) {
        ClassBuilder named = mixin as ClassBuilder;
        mixedInTypeBuilder = named.mixedInTypeBuilder!;
        mixin = mixedInTypeBuilder.declaration!;
      }
      if (mixin is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = mixin;
        NamedTypeBuilder namedBuilder = mixedInTypeBuilder as NamedTypeBuilder;
        mixin = aliasBuilder.unaliasDeclaration(namedBuilder.typeArguments,
            isUsedAsClass: true,
            usedAsClassCharOffset: namedBuilder.charOffset,
            usedAsClassFileUri: namedBuilder.fileUri)!;
      }
      if (mixin is ClassBuilder) {
        Iterator<MemberBuilder> iterator =
            mixin.fullMemberIterator<MemberBuilder>();
        while (iterator.moveNext()) {
          MemberBuilder memberBuilder = iterator.current;
          if (memberBuilder.isStatic) {
            continue;
          }
          for (ClassMember classMember in memberBuilder.localMembers) {
            Name name = classMember.name;
            if (classMember.isAbstract || classMember.isNoSuchMethodForwarder) {
              _hasInterfaces = true;
            }
            _Tuple? tuple = memberMap[name];
            if (tuple == null) {
              memberMap[name] = new _Tuple.mixInMember(classMember);
            } else {
              tuple.mixedInMember = classMember;
            }
            if (name == noSuchMethodName &&
                !classMember.isAbstract &&
                !classMember.isObjectMember(objectClass)) {
              userNoSuchMethodMember ??= classMember;
            }
          }
          for (ClassMember classMember in memberBuilder.localSetters) {
            Name name = classMember.name;
            if (classMember.isAbstract || classMember.isNoSuchMethodForwarder) {
              _hasInterfaces = true;
            }
            _Tuple? tuple = memberMap[name];
            if (tuple == null) {
              memberMap[name] = new _Tuple.mixInSetter(classMember);
            } else {
              tuple.mixedInSetter = classMember;
            }
          }
        }
      }
    }

    void extend(Map<Name, ClassMember>? superClassMembers) {
      if (superClassMembers == null) return;
      for (MapEntry<Name, ClassMember> entry in superClassMembers.entries) {
        Name name = entry.key;
        ClassMember superClassMember = entry.value;
        _Tuple? tuple = memberMap[name];
        if (tuple != null) {
          if (superClassMember.forSetter) {
            tuple.extendedSetter = superClassMember;
          } else {
            tuple.extendedMember = superClassMember;
          }
        } else {
          if (superClassMember.forSetter) {
            memberMap[name] = new _Tuple.extendSetter(superClassMember);
          } else {
            memberMap[name] = new _Tuple.extendMember(superClassMember);
          }
        }
      }
    }

    void implement(Map<Name, ClassMember>? superInterfaceMembers) {
      if (superInterfaceMembers == null) return;
      for (MapEntry<Name, ClassMember> entry in superInterfaceMembers.entries) {
        Name name = entry.key;
        ClassMember superInterfaceMember = entry.value;
        _Tuple? tuple = memberMap[name];
        if (tuple != null) {
          if (superInterfaceMember.forSetter) {
            tuple.addImplementedSetter(superInterfaceMember);
          } else {
            tuple.addImplementedMember(superInterfaceMember);
          }
        } else {
          if (superInterfaceMember.forSetter) {
            memberMap[superInterfaceMember.name] =
                new _Tuple.implementSetter(superInterfaceMember);
          } else {
            memberMap[superInterfaceMember.name] =
                new _Tuple.implementMember(superInterfaceMember);
          }
        }
      }
    }

    if (supernode == null) {
      // This should be Object.
    } else {
      userNoSuchMethodMember ??= supernode.userNoSuchMethodMember;

      extend(supernode.classMemberMap);
      extend(supernode.classSetterMap);

      if (supernode.interfaceMemberMap != null ||
          supernode.interfaceSetterMap != null) {
        _hasInterfaces = true;
      }

      if (_hasInterfaces) {
        implement(supernode.interfaceMemberMap ?? supernode.classMemberMap);
        implement(supernode.interfaceSetterMap ?? supernode.classSetterMap);
      }

      if (interfaceNodes != null) {
        for (int i = 0; i < interfaceNodes.length; i++) {
          ClassMembersNode? interfaceNode = _membersBuilder
              .getNodeFromClassBuilder(interfaceNodes[i].classBuilder);
          _hasInterfaces = true;

          implement(
              interfaceNode.interfaceMemberMap ?? interfaceNode.classMemberMap);
          implement(
              interfaceNode.interfaceSetterMap ?? interfaceNode.classSetterMap);
        }
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

    ClassMember? noSuchMethodMember;

    ClassHierarchyNodeDataForTesting? dataForTesting;
    if (retainDataForTesting) {
      dataForTesting = new ClassHierarchyNodeDataForTesting(
          abstractMembers,
          declaredOverridesMap,
          mixinApplicationOverridesMap,
          inheritedImplementsMap);
    }

    void computeClassInterfaceMember(Name name, _Tuple tuple) {
      /// The computation starts by sanitizing the members. Conflicts between
      /// methods and properties (getters/setters) or between static and
      /// instance members are reported. Conflicting members and members
      /// overridden by duplicates are removed.
      ///
      /// Conflicts between the getable and setable are reported afterwards.
      var (_SanitizedMember? getable, _SanitizedMember? setable) =
          tuple.sanitize(this);

      _Overrides overrides = new _Overrides(
          classBuilder: classBuilder,
          inheritedImplementsMap: inheritedImplementsMap,
          dataForTesting: dataForTesting);

      ClassMember? interfaceGetable;
      if (getable != null) {
        interfaceGetable = getable.computeMembers(this, overrides,
            noSuchMethodMember: noSuchMethodMember,
            userNoSuchMethodMember: userNoSuchMethodMember,
            abstractMembers: abstractMembers,
            classMemberMap: classMemberMap,
            interfaceMemberMap: interfaceMemberMap,
            dataForTesting: dataForTesting);
      }
      ClassMember? interfaceSetable;
      if (setable != null) {
        interfaceSetable = setable.computeMembers(this, overrides,
            noSuchMethodMember: noSuchMethodMember,
            userNoSuchMethodMember: userNoSuchMethodMember,
            abstractMembers: abstractMembers,
            classMemberMap: classSetterMap,
            interfaceMemberMap: interfaceSetterMap,
            dataForTesting: dataForTesting);
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
          _membersBuilder.registerGetterSetterCheck(
              new DelayedClassGetterSetterCheck(
                  classBuilder as SourceClassBuilder,
                  name,
                  interfaceGetable,
                  interfaceSetable));
        }
      }
      overrides.collectOverrides(
          getable: getable,
          setable: setable,
          mixinApplicationOverridesMap: mixinApplicationOverridesMap,
          declaredOverridesMap: declaredOverridesMap);
    }

    // Compute the 'noSuchMethod' member first so we know the target for
    // noSuchMethod forwarders.
    _Tuple? noSuchMethod = memberMap.remove(noSuchMethodName);
    if (noSuchMethod != null) {
      // The noSuchMethod is always available - unless Object is not valid.
      // See for instance pkg/front_end/test/fasta/object_supertype_test.dart
      computeClassInterfaceMember(noSuchMethodName, noSuchMethod);
    }
    noSuchMethodMember = interfaceMemberMap[noSuchMethodName] ??
        classMemberMap[noSuchMethodName];

    memberMap.forEach(computeClassInterfaceMember);

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
        _membersBuilder.registerDelayedTypeComputation(computation);

        /// Declared members must be checked to validly override the
        /// overridden members.
        _membersBuilder.registerOverrideCheck(
            classBuilder as SourceClassBuilder, classMember, overriddenMembers);
      });

      mixinApplicationOverridesMap.forEach(
          (ClassMember classMember, Set<ClassMember> overriddenMembers) {
        /// Declared mixed in members must be checked to validly override the
        /// overridden members.
        _membersBuilder.registerOverrideCheck(
            classBuilder as SourceClassBuilder, classMember, overriddenMembers);
      });

      inheritedImplementsMap.forEach(
          (ClassMember classMember, Set<ClassMember> overriddenMembers) {
        /// Concrete members must be checked to validly override the overridden
        /// members in concrete classes.
        _membersBuilder.registerOverrideCheck(
            classBuilder as SourceClassBuilder, classMember, overriddenMembers);
      });
    }

    if (!_hasInterfaces) {
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

    reportMissingMembers(abstractMembers);

    return new ClassMembersNode(
        classBuilder,
        supernode,
        classMemberMap,
        classSetterMap,
        interfaceMemberMap,
        interfaceSetterMap,
        userNoSuchMethodMember,
        dataForTesting);
  }

  void reportMissingMembers(List<ClassMember> abstractMembers) {
    if (abstractMembers.isEmpty) return;

    Map<String, LocatedMessage> contextMap = <String, LocatedMessage>{};
    for (ClassMember declaration in unfoldDeclarations(abstractMembers)) {
      if (classBuilder.isEnum &&
          declaration.declarationBuilder == classBuilder) {
        classBuilder.addProblem(messageEnumAbstractMember,
            declaration.charOffset, declaration.name.text.length);
      } else {
        String name = declaration.fullNameForErrors;
        String className = declaration.declarationBuilder.fullNameForErrors;
        String displayName =
            declaration.isSetter ? "$className.$name=" : "$className.$name";
        contextMap[displayName] = templateMissingImplementationCause
            .withArguments(displayName)
            .withLocation(
                declaration.fileUri, declaration.charOffset, name.length);
      }
    }
    if (contextMap.isEmpty) return;
    List<String> names = new List<String>.of(contextMap.keys)..sort();
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
}

class ClassMembersNode {
  final ClassBuilder classBuilder;

  final ClassMembersNode? supernode;

  /// All the members of this class including [classMembers] of its
  /// superclasses.
  final Map<Name, ClassMember> classMemberMap;

  /// Similar to [classMembers] but for setters.
  final Map<Name, ClassMember> classSetterMap;

  /// All the interface members of this class including [interfaceMembers] of
  /// its supertypes.
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

  /// The user defined noSuchMethod, i.e. not Object.noSuchMethod, if declared
  /// or inherited.
  final ClassMember? userNoSuchMethodMember;

  final ClassHierarchyNodeDataForTesting? dataForTesting;

  ClassMembersNode(
      this.classBuilder,
      this.supernode,
      this.classMemberMap,
      this.classSetterMap,
      this.interfaceMemberMap,
      this.interfaceSetterMap,
      this.userNoSuchMethodMember,
      this.dataForTesting);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb
      ..write(classBuilder.fullNameForErrors)
      ..writeln(":");
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
        ..write(member.declarationBuilder.fullNameForErrors)
        ..write(".")
        ..write(member.fullNameForErrors)
        ..writeln();
    }
  }

  void printMemberMap(
      Map<Name, ClassMember> memberMap, StringBuffer sb, String heading) {
    List<ClassMember> members = memberMap.values.toList();
    members.sort((ClassMember a, ClassMember b) {
      if (a == b) return 0;
      return ClassHierarchy.compareNames(a.name, b.name);
    });
    printMembers(members, sb, heading);
  }

  ClassMember? getInterfaceMember(Name name, bool isSetter) {
    ClassMember? result = isSetter
        ? (interfaceSetterMap ?? classSetterMap)[name]
        : (interfaceMemberMap ?? classMemberMap)[name];
    if (result == null) {
      return null;
    }
    if (result.isStatic) {
      return null;
    }
    return result;
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
    ClassMember? result =
        isSetter ? classSetterMap[name] : classMemberMap[name];
    if (result == null) {
      return null;
    }
    if (result.isStatic) {
      // TODO(johnniwinther): Can we avoid putting static members in the
      // [classMemberMap]/[classSetterMap] maps?
      return supernode?.getDispatchTarget(name, isSetter);
    }
    return result;
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

class _Tuple {
  final Name name;
  ClassMember? _declaredGetable;
  ClassMember? _declaredSetable;
  ClassMember? _mixedInGetable;
  ClassMember? _mixedInSetable;
  ClassMember? _extendedGetable;
  ClassMember? _extendedSetable;
  List<ClassMember>? _implementedGetables;
  List<ClassMember>? _implementedSetables;

  _Tuple.declareMember(ClassMember declaredMember)
      : assert(!declaredMember.forSetter),
        this._declaredGetable = declaredMember,
        this.name = declaredMember.name;

  _Tuple.mixInMember(ClassMember mixedInMember)
      : assert(!mixedInMember.forSetter),
        this._mixedInGetable = mixedInMember,
        this.name = mixedInMember.name;

  _Tuple.extendMember(ClassMember extendedMember)
      : assert(!extendedMember.forSetter),
        this._extendedGetable = extendedMember,
        this.name = extendedMember.name;

  _Tuple.implementMember(ClassMember implementedMember)
      : assert(!implementedMember.forSetter),
        this.name = implementedMember.name,
        _implementedGetables = <ClassMember>[implementedMember];

  _Tuple.declareSetter(ClassMember declaredSetter)
      : assert(declaredSetter.forSetter),
        this._declaredSetable = declaredSetter,
        this.name = declaredSetter.name;

  _Tuple.mixInSetter(ClassMember mixedInSetter)
      : assert(mixedInSetter.forSetter),
        this._mixedInSetable = mixedInSetter,
        this.name = mixedInSetter.name;

  _Tuple.extendSetter(ClassMember extendedSetter)
      : assert(extendedSetter.forSetter),
        this._extendedSetable = extendedSetter,
        this.name = extendedSetter.name;

  _Tuple.implementSetter(ClassMember implementedSetter)
      : assert(implementedSetter.forSetter),
        this.name = implementedSetter.name,
        _implementedSetables = <ClassMember>[implementedSetter];

  ClassMember? get declaredMember => _declaredGetable;

  void set declaredMember(ClassMember? value) {
    assert(!value!.forSetter);
    assert(
        _declaredGetable == null,
        "Declared member already set to $_declaredGetable, "
        "trying to set it to $value.");
    _declaredGetable = value;
  }

  ClassMember? get declaredSetter => _declaredSetable;

  void set declaredSetter(ClassMember? value) {
    assert(value!.forSetter);
    assert(
        _declaredSetable == null,
        "Declared setter already set to $_declaredSetable, "
        "trying to set it to $value.");
    _declaredSetable = value;
  }

  ClassMember? get extendedMember => _extendedGetable;

  void set extendedMember(ClassMember? value) {
    assert(!value!.forSetter);
    assert(
        _extendedGetable == null,
        "Extended member already set to $_extendedGetable, "
        "trying to set it to $value.");
    _extendedGetable = value;
  }

  ClassMember? get extendedSetter => _extendedSetable;

  void set extendedSetter(ClassMember? value) {
    assert(value!.forSetter);
    assert(
        _extendedSetable == null,
        "Extended setter already set to $_extendedSetable, "
        "trying to set it to $value.");
    _extendedSetable = value;
  }

  ClassMember? get mixedInMember => _mixedInGetable;

  void set mixedInMember(ClassMember? value) {
    assert(!value!.forSetter);
    assert(
        _mixedInGetable == null,
        "Mixed in member already set to $_mixedInGetable, "
        "trying to set it to $value.");
    _mixedInGetable = value;
  }

  ClassMember? get mixedInSetter => _mixedInSetable;

  void set mixedInSetter(ClassMember? value) {
    assert(value!.forSetter);
    assert(
        _mixedInSetable == null,
        "Mixed in setter already set to $_mixedInSetable, "
        "trying to set it to $value.");
    _mixedInSetable = value;
  }

  List<ClassMember>? get implementedMembers => _implementedGetables;

  void addImplementedMember(ClassMember value) {
    assert(!value.forSetter);
    _implementedGetables ??= <ClassMember>[];
    _implementedGetables!.add(value);
  }

  List<ClassMember>? get implementedSetters => _implementedSetables;

  void addImplementedSetter(ClassMember value) {
    assert(value.forSetter);
    _implementedSetables ??= <ClassMember>[];
    _implementedSetables!.add(value);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    String comma = '';
    sb.write('Tuple(');
    if (_declaredGetable != null) {
      sb.write(comma);
      sb.write('declaredMember=');
      sb.write(_declaredGetable);
      comma = ',';
    }
    if (_declaredSetable != null) {
      sb.write(comma);
      sb.write('declaredSetter=');
      sb.write(_declaredSetable);
      comma = ',';
    }
    if (_mixedInGetable != null) {
      sb.write(comma);
      sb.write('mixedInMember=');
      sb.write(_mixedInGetable);
      comma = ',';
    }
    if (_mixedInSetable != null) {
      sb.write(comma);
      sb.write('mixedInSetter=');
      sb.write(_mixedInSetable);
      comma = ',';
    }
    if (_extendedGetable != null) {
      sb.write(comma);
      sb.write('extendedMember=');
      sb.write(_extendedGetable);
      comma = ',';
    }
    if (_extendedSetable != null) {
      sb.write(comma);
      sb.write('extendedSetter=');
      sb.write(_extendedSetable);
      comma = ',';
    }
    if (_implementedGetables != null) {
      sb.write(comma);
      sb.write('implementedMembers=');
      sb.write(_implementedGetables);
      comma = ',';
    }
    if (_implementedSetables != null) {
      sb.write(comma);
      sb.write('implementedSetters=');
      sb.write(_implementedSetables);
      comma = ',';
    }
    sb.write(')');
    return sb.toString();
  }

  /// Sanitizing the members of this tuple.
  ///
  /// Conflicts between methods and properties (getters/setters) or between
  /// static and instance members are reported. Conflicting members and members
  /// overridden by duplicates are removed.
  ///
  /// For this [definingGetable] and [definingSetable] hold the first member
  /// of its kind found among declared, mixed in, extended and implemented
  /// members.
  ///
  /// Conflicts between [definingGetable] and [definingSetable] are reported
  /// afterwards.
  (_SanitizedMember?, _SanitizedMember?) sanitize(
      ClassMembersNodeBuilder builder) {
    ClassMember? definingGetable;
    ClassMember? definingSetable;

    ClassMember? declaredGetable = this.declaredMember;
    if (declaredGetable != null) {
      /// class Class {
      ///   method() {}
      /// }
      definingGetable = declaredGetable;
    }
    ClassMember? declaredSetable = this.declaredSetter;
    if (declaredSetable != null) {
      /// class Class {
      ///   set setter(value) {}
      /// }
      definingSetable = declaredSetable;
    }

    ClassMember? mixedInGetable;
    ClassMember? tupleMixedInMember = this.mixedInMember;
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
          builder.reportInheritanceConflict(
              definingGetable, tupleMixedInMember);
        } else {
          mixedInGetable = tupleMixedInMember;
        }
      }
    }
    ClassMember? mixedInSetable;
    ClassMember? tupleMixedInSetter = this.mixedInSetter;
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
          builder.reportInheritanceConflict(
              definingSetable, tupleMixedInSetter);
        } else {
          mixedInSetable = tupleMixedInSetter;
        }
      }
    }

    ClassMember? extendedGetable;
    ClassMember? tupleExtendedMember = this.extendedMember;
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
          ///     get method => 0;
          ///   }
          builder.reportInheritanceConflict(
              definingGetable, tupleExtendedMember);
        } else {
          extendedGetable = tupleExtendedMember;
        }
      }
    }
    ClassMember? extendedSetable;
    ClassMember? tupleExtendedSetter = this.extendedSetter;
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
          builder.reportInheritanceConflict(
              definingSetable, tupleExtendedSetter);
        } else {
          extendedSetable = tupleExtendedSetter;
        }
      }
    }

    // TODO(johnniwinther): Remove extended and mixed in members/setters
    // from implemented members/setters. Mixin applications always implement
    // the mixin class leading to unnecessary interface members.
    List<ClassMember>? implementedGetables;
    List<ClassMember>? tupleImplementedMembers = this.implementedMembers;
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
            builder.reportInheritanceConflict(
                definingGetable, implementedGetable);
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
    List<ClassMember>? tupleImplementedSetters = this.implementedSetters;
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
            builder.reportInheritanceConflict(
                definingSetable, implementedSetable);
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
        builder.reportInheritanceConflict(definingGetable, definingSetable);
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
    return (
      definingGetable != null
          ? new _SanitizedMember(name, definingGetable, declaredGetable,
              mixedInGetable, extendedGetable, implementedGetables)
          : null,
      definingSetable != null
          ? new _SanitizedMember(name, definingSetable, declaredSetable,
              mixedInSetable, extendedSetable, implementedSetables)
          : null
    );
  }
}

/// The [ClassMember]s involved in defined the [name] getable or setable of
/// a class.
///
/// The values are sanitized to avoid duplicates and conflicting members.
///
/// The [_definingMember] hold the first member found among declared, mixed in,
/// extended and implemented members.
///
/// This is computed by [_Tuple.sanitize].
class _SanitizedMember {
  final Name name;

  /// The member which defines whether the computation is for a method, a getter
  /// or a setter.
  final ClassMember _definingMember;

  /// The member declared in the current class, if any.
  final ClassMember? _declaredMember;

  /// The member declared in a mixin that is mixed into the current class, if
  /// any.
  final ClassMember? _mixedInMember;

  /// The member inherited from the super class.
  final ClassMember? _extendedMember;

  /// The members inherited from the super interfaces, if none this is `null`.
  final List<ClassMember>? _implementedMembers;

  _SanitizedMember(this.name, this._definingMember, this._declaredMember,
      this._mixedInMember, this._extendedMember, this._implementedMembers);

  /// Computes the class and interface members for this [_SanitizedMember].
  ///
  /// The computed class and interface members are added to [classMemberMap]
  /// and [interfaceMemberMap], respectively.
  ///
  /// [
  ClassMember? computeMembers(
      ClassMembersNodeBuilder builder, _Overrides overrides,
      {required ClassMember? noSuchMethodMember,
      required ClassMember? userNoSuchMethodMember,
      required List<ClassMember> abstractMembers,
      required Map<Name, ClassMember> classMemberMap,
      required Map<Name, ClassMember>? interfaceMemberMap,
      required ClassHierarchyNodeDataForTesting? dataForTesting}) {
    ClassBuilder classBuilder = builder.classBuilder;

    ClassMember? classMember;
    ClassMember? interfaceMember;

    /// A noSuchMethodForwarder can be inserted in non-abstract class
    /// if a user defined noSuchMethod implementation is available or
    /// if the member is not accessible from this library;
    bool canHaveNoSuchMethodForwarder = !classBuilder.isAbstract &&
        (userNoSuchMethodMember != null ||
            !isNameVisibleIn(name, classBuilder.libraryBuilder));

    if (_mixedInMember != null) {
      if (_mixedInMember.isAbstract || _mixedInMember.isNoSuchMethodForwarder) {
        ///    class Mixin {
        ///      method();
        ///    }
        ///    class Class = Object with Mixin;

        /// Interface members from the extended, mixed in, and implemented
        /// members define the combined member signature.
        Set<ClassMember> interfaceMembers = {};

        if (_extendedMember != null) {
          ///    class Super {
          ///      method() {}
          ///    }
          ///    class Mixin {
          ///      method();
          ///    }
          ///    class Class = Super with Mixin;
          interfaceMembers.add(_extendedMember.interfaceMember);
        }

        interfaceMembers.add(_mixedInMember);

        if (_implementedMembers != null) {
          ///    class Interface {
          ///      method() {}
          ///    }
          ///    class Mixin {
          ///      method();
          ///    }
          ///    class Class = Object with Mixin implements Interface;
          interfaceMembers.addAll(_implementedMembers);
        }

        ClassMember? noSuchMethodTarget;
        if (canHaveNoSuchMethodForwarder &&
            (_extendedMember == null ||
                _extendedMember.isNoSuchMethodForwarder)) {
          ///    class Super {
          ///      noSuchMethod(_) => null;
          ///      _extendedMember();
          ///    }
          ///    abstract class Mixin {
          ///      mixinMethod();
          ///      _extendedMember();
          ///    }
          ///    class Class = Super with Mixin /*
          ///      mixinMethod() => ...; // noSuchMethod forwarder created
          ///    */;
          noSuchMethodTarget = noSuchMethodMember;
        }

        /// We always create a synthesized interface member, even in the
        /// case of [interfaceMembers] being a singleton, to insert the
        /// abstract mixin stub.
        interfaceMember = new SynthesizedInterfaceMember(
            classBuilder, name, interfaceMembers.toList(),
            superClassMember: _extendedMember,
            // [definingMember] and [mixedInMember] are always the same
            // here. Use the latter here and the former below to show the
            // the member is canonical _because_ its the mixed in member and
            // it defines the isProperty/forSetter properties _because_ it
            // is the defining member.
            canonicalMember: _mixedInMember,
            mixedInMember: _mixedInMember,
            noSuchMethodTarget: noSuchMethodTarget,
            memberKind: _definingMember.memberKind,
            shouldModifyKernel: builder.shouldModifyKernel);
        builder._membersBuilder.registerMemberComputation(interfaceMember);

        if (_extendedMember != null) {
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
              inheritedClassMember: _extendedMember,
              implementedInterfaceMember: interfaceMember,
              memberKind: _definingMember.memberKind);
          builder._membersBuilder.registerMemberComputation(classMember);
          if (!classBuilder.isAbstract) {
            overrides.registerInheritedImplements(
                _extendedMember, {interfaceMember},
                aliasForTesting: classMember);
          }
        } else if (noSuchMethodTarget != null) {
          classMember = interfaceMember;
        } else if (!classBuilder.isAbstract) {
          assert(!canHaveNoSuchMethodForwarder);

          ///    class Mixin {
          ///      method(); // Missing implementation.
          ///    }
          ///    class Class = Object with Mixin;
          builder.registerAbstractMember(abstractMembers, interfaceMember);
        }

        assert(!_mixedInMember.isSynthesized);
        if (!_mixedInMember.isSynthesized) {
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
          overrides.registerMixedInOverride(_mixedInMember,
              aliasForTesting: interfaceMember);
        }
      } else {
        assert(!_mixedInMember.isAbstract);

        ///    class Mixin {
        ///      method() {}
        ///    }
        ///    class Class = Object with Mixin;
        ///

        /// Interface members from the extended, mixed in, and implemented
        /// members define the combined member signature.
        Set<ClassMember> interfaceMembers = {};

        if (_extendedMember != null) {
          ///    class Super {
          ///      method() {}
          ///    }
          ///    class Mixin {
          ///      method() {}
          ///    }
          ///    class Class = Super with Mixin;
          interfaceMembers.add(_extendedMember.interfaceMember);
        }

        interfaceMembers.add(_mixedInMember);

        if (_implementedMembers != null) {
          ///    class Interface {
          ///      method() {}
          ///    }
          ///    class Mixin {
          ///      method() {}
          ///    }
          ///    class Class = Object with Mixin implements Interface;
          interfaceMembers.addAll(_implementedMembers);
        }

        /// We always create a synthesized interface member, even in the
        /// case of [interfaceMembers] being a singleton, to insert the
        /// concrete mixin stub.
        interfaceMember = new SynthesizedInterfaceMember(
            classBuilder, name, interfaceMembers.toList(),
            superClassMember: _mixedInMember,
            // [definingMember] and [mixedInMember] are always the same
            // here. Use the latter here and the former below to show the
            // the member is canonical _because_ its the mixed in member and
            // it defines the isProperty/forSetter properties _because_ it
            // is the defining member.
            canonicalMember: _mixedInMember,
            mixedInMember: _mixedInMember,
            memberKind: _definingMember.memberKind,
            shouldModifyKernel: builder.shouldModifyKernel);
        builder._membersBuilder.registerMemberComputation(interfaceMember);

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
            inheritedClassMember: _mixedInMember,
            implementedInterfaceMember: interfaceMember,
            memberKind: _definingMember.memberKind);
        builder._membersBuilder.registerMemberComputation(classMember);

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
          overrides.registerInheritedImplements(
              _mixedInMember, {interfaceMember},
              aliasForTesting: classMember);
        }
        assert(!_mixedInMember.isSynthesized);
        if (!_mixedInMember.isSynthesized) {
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
          overrides.registerMixedInOverride(_mixedInMember);
        }
      }
    } else if (_declaredMember != null) {
      if (_declaredMember.isAbstract) {
        ///    class Class {
        ///      method();
        ///    }
        interfaceMember = _declaredMember;

        /// Interface members from the declared, extended, and implemented
        /// members define the combined member signature.
        Set<ClassMember> interfaceMembers = {};

        if (_extendedMember != null) {
          ///    class Super {
          ///      method() {}
          ///    }
          ///    class Class extends Super {
          ///      method();
          ///    }
          interfaceMembers.add(_extendedMember);
        }

        interfaceMembers.add(_declaredMember);

        if (_implementedMembers != null) {
          ///    class Interface {
          ///      method() {}
          ///    }
          ///    class Class implements Interface {
          ///      method();
          ///    }
          interfaceMembers.addAll(_implementedMembers);
        }

        ClassMember? noSuchMethodTarget;
        if (canHaveNoSuchMethodForwarder &&
            (_extendedMember == null ||
                _extendedMember.isNoSuchMethodForwarder)) {
          ///    class Super {
          ///      noSuchMethod(_) => null;
          ///      _extendedMember();
          ///    }
          ///    class Class extends Super {
          ///      declaredMethod(); // noSuchMethod forwarder created
          ///      _extendedMember();
          ///    }
          noSuchMethodTarget = noSuchMethodMember;
        }

        /// If only one member defines the interface member there is no
        /// need for a synthesized interface member, since its result will
        /// simply be that one member.
        if (interfaceMembers.length > 1 || noSuchMethodTarget != null) {
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
              superClassMember: _extendedMember,
              // [definingMember] and [declaredMember] are always the same
              // here. Use the latter here and the former below to show the
              // the member is canonical _because_ its the declared member
              // and it defines the isProperty/forSetter properties
              // _because_ it is the defining member.
              canonicalMember: _declaredMember,
              noSuchMethodTarget: noSuchMethodTarget,
              memberKind: _definingMember.memberKind,
              shouldModifyKernel: builder.shouldModifyKernel);
          builder._membersBuilder.registerMemberComputation(interfaceMember);
        }

        if (_extendedMember != null) {
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
              inheritedClassMember: _extendedMember,
              implementedInterfaceMember: interfaceMember,
              memberKind: _definingMember.memberKind);
          builder._membersBuilder.registerMemberComputation(classMember);

          if (!classBuilder.isAbstract && noSuchMethodTarget == null) {
            ///    class Super {
            ///      method() {}
            ///    }
            ///    class Class extends Super {
            ///      method();
            ///    }
            ///
            /// [_extendedMember] must implemented interface member.
            overrides.registerInheritedImplements(
                _extendedMember, {interfaceMember},
                aliasForTesting: classMember);
          }
        } else if (noSuchMethodTarget != null) {
          classMember = interfaceMember;
        } else if (!classBuilder.isAbstract) {
          assert(!canHaveNoSuchMethodForwarder);

          ///    class Class {
          ///      method(); // Missing implementation.
          ///    }
          builder.registerAbstractMember(abstractMembers, _declaredMember);
        }

        /// The declared member must override extended and implemented
        /// members.
        overrides.registerDeclaredOverride(_declaredMember,
            aliasForTesting: interfaceMember);
      } else {
        assert(!_declaredMember.isAbstract);

        ///    class Class {
        ///      method() {}
        ///    }
        classMember = _declaredMember;

        /// The declared member must override extended and implemented
        /// members.
        overrides.registerDeclaredOverride(_declaredMember);
      }
    } else if (_extendedMember != null) {
      ///    class Super {
      ///      method() {}
      ///    }
      ///    class Class extends Super {}
      assert(!_extendedMember.isAbstract,
          "Abstract extended member: ${_extendedMember}");

      classMember = _extendedMember;

      if (_implementedMembers != null) {
        ///    class Super {
        ///      method() {}
        ///    }
        ///    class Interface {
        ///      method() {}
        ///    }
        ///    class Class extends Super implements Interface {}
        ClassMember extendedInterfaceMember = _extendedMember.interfaceMember;

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
        interfaceMembers.addAll(_implementedMembers);

        ClassMember? noSuchMethodTarget;
        if (_extendedMember.isNoSuchMethodForwarder &&
            !classBuilder.isAbstract &&
            (userNoSuchMethodMember != null ||
                !isNameVisibleIn(name, classBuilder.libraryBuilder))) {
          noSuchMethodTarget = noSuchMethodMember;
        }

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
            !builder.needsMemberSignatureFor(extendedInterfaceMember) &&
            noSuchMethodTarget == null) {
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
              superClassMember: _extendedMember,
              noSuchMethodTarget: noSuchMethodTarget,
              memberKind: _definingMember.memberKind,
              shouldModifyKernel: builder.shouldModifyKernel);
          builder._membersBuilder.registerMemberComputation(interfaceMember);
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
              inheritedClassMember: _extendedMember,
              implementedInterfaceMember: interfaceMember,
              memberKind: _definingMember.memberKind);
          builder._membersBuilder.registerMemberComputation(classMember);
          if (!classBuilder.isAbstract && noSuchMethodTarget == null) {
            ///    class Super {
            ///      method() {}
            ///    }
            ///    class Interface {
            ///      method() {}
            ///    }
            ///    class Class extends Super implements Interface {}
            overrides.registerInheritedImplements(
                _extendedMember, {interfaceMember},
                aliasForTesting: classMember);
          }
        }
      } else if (builder.needsMemberSignatureFor(_extendedMember)) {
        ///    // Opt-in library:
        ///    class Super {
        ///      method() {}
        ///    }
        ///    // opt-out library:
        ///    class Class extends Super {}
        interfaceMember = new SynthesizedInterfaceMember(
            classBuilder, name, [_extendedMember],
            superClassMember: _extendedMember,
            memberKind: _definingMember.memberKind,
            shouldModifyKernel: builder.shouldModifyKernel);
        builder._membersBuilder.registerMemberComputation(interfaceMember);

        /// The concrete extended member is the class member and should
        /// be able to be overwritten by a synthesized concrete member here,
        /// but we handle the case for consistency.
        classMember = new InheritedClassMemberImplementsInterface(
            classBuilder, name,
            inheritedClassMember: _extendedMember,
            implementedInterfaceMember: interfaceMember,
            memberKind: _definingMember.memberKind);
        builder._membersBuilder.registerMemberComputation(classMember);
      }
    } else if (_implementedMembers != null) {
      ///    class Interface {
      ///      method() {}
      ///    }
      ///    class Class implements Interface {}
      Set<ClassMember> interfaceMembers = _implementedMembers.toSet();
      if (interfaceMembers.isNotEmpty) {
        ClassMember? noSuchMethodTarget;
        if (canHaveNoSuchMethodForwarder) {
          ///    abstract class Interface {
          ///      implementedMember();
          ///    }
          ///    class Class implements Interface {
          ///      noSuchMethod(_) => null;
          ///      implementedMember(); // noSuchMethod forwarder created
          ///    }
          noSuchMethodTarget = noSuchMethodMember;
        }

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
            !builder.needsMemberSignatureFor(interfaceMembers.first) &&
            noSuchMethodTarget == null) {
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
              noSuchMethodTarget: noSuchMethodTarget,
              memberKind: _definingMember.memberKind,
              shouldModifyKernel: builder.shouldModifyKernel);
          builder._membersBuilder.registerMemberComputation(interfaceMember);
        }
        if (noSuchMethodTarget != null) {
          classMember = interfaceMember;
        } else if (!classBuilder.isAbstract) {
          assert(!canHaveNoSuchMethodForwarder);

          ///    class Interface {
          ///      method() {}
          ///    }
          ///    class Class implements Interface {}
          builder.registerAbstractMember(abstractMembers, interfaceMember);
        }
      }
    }

    if (interfaceMember != null) {
      // We have an explicit interface.
      builder._hasInterfaces = true;
    }
    if (classMember != null) {
      classMemberMap[name] = classMember;
      interfaceMember ??= classMember.interfaceMember;
    }
    if (interfaceMember != null) {
      interfaceMemberMap![name] = interfaceMember;
    }
    return interfaceMember;
  }

  Set<ClassMember> computeOverrides() {
    Set<ClassMember> set = {};
    if (_extendedMember != null) {
      ///    (abstract) class Super {
      ///      method() {}
      ///      int get property => 0;
      ///    }
      ///    (abstract) class Class extends Super {
      ///      method() {}
      ///      set property(int value) {}
      ///    }
      ///
      /// or
      ///
      ///    (abstract) class Super {
      ///      set setter(int value) {}
      ///      set property(int value) {}
      ///    }
      ///    (abstract) class Class extends Super {
      ///      set setter(int value) {}
      ///      int get property => 0;
      ///    }
      set.add(_extendedMember.interfaceMember);
    }
    if (_implementedMembers != null) {
      ///    (abstract) class Interface {
      ///      method() {}
      ///      int get property => 0;
      ///    }
      ///    (abstract) class Class implements Interface {
      ///      method() {}
      ///      set property(int value) {}
      ///    }
      ///
      /// or
      ///
      ///    (abstract) class Interface {
      ///      set setter(int value) {}
      ///      set property(int value) {}
      ///    }
      ///    (abstract) class Class implements Interface {
      ///      set setter(int value) {}
      ///      int get property => 0;
      ///    }
      set.addAll(_implementedMembers);
    }
    return set;
  }
}

/// Object that collects data of overrides found during
/// [_SanitizedMember.computeMembers].
class _Overrides {
  final ClassBuilder _classBuilder;

  /// In case this class is concrete, this maps concrete members that are
  /// inherited into this class to the members they should override to validly
  /// implement the interface of this class.
  final Map<ClassMember, Set<ClassMember>> _inheritedImplementsMap;

  final ClassHierarchyNodeDataForTesting? _dataForTesting;

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

  _Overrides(
      {required ClassBuilder classBuilder,
      required Map<ClassMember, Set<ClassMember>> inheritedImplementsMap,
      required ClassHierarchyNodeDataForTesting? dataForTesting})
      : _classBuilder = classBuilder,
        _inheritedImplementsMap = inheritedImplementsMap,
        _dataForTesting = dataForTesting;

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
    if (_classBuilder is SourceClassBuilder && !declaredMember.isStatic) {
      assert(
          declaredMember.isSourceDeclaration &&
              declaredMember.declarationBuilder.origin == _classBuilder,
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
      if (_dataForTesting != null && aliasForTesting != null) {
        _dataForTesting.aliasMap[aliasForTesting] = declaredMember;
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
    assert(mixedInMember.declarationBuilder != _classBuilder,
        "Only mixin members can override by application: ${mixedInMember}");
    if (_classBuilder is SourceClassBuilder) {
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
      if (_dataForTesting != null && aliasForTesting != null) {
        _dataForTesting.aliasMap[aliasForTesting] = mixedInMember;
      }
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
    if (_classBuilder is SourceClassBuilder) {
      assert(
          inheritedMember.declarationBuilder != _classBuilder,
          "Only inherited members can implement by inheritance: "
          "${inheritedMember}");
      _inheritedImplementsMap[inheritedMember] = overrides;
      if (_dataForTesting != null) {
        _dataForTesting.aliasMap[aliasForTesting] = inheritedMember;
      }
    }
  }

  /// Collects overrides of [getable] and [setable] in [declaredOverridesMap]
  /// and [mixinApplicationOverridesMap] to set up need override checks.
  void collectOverrides(
      {required _SanitizedMember? getable,
      required _SanitizedMember? setable,
      required Map<ClassMember, Set<ClassMember>> declaredOverridesMap,
      required Map<ClassMember, Set<ClassMember>>
          mixinApplicationOverridesMap}) {
    if (hasDeclaredMembers) {
      Set<ClassMember> getableOverrides = getable?.computeOverrides() ?? {};
      Set<ClassMember> setableOverrides = setable?.computeOverrides() ?? {};
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
  }
}

Set<ClassMember> toSet(
    DeclarationBuilder declarationBuilder, Iterable<ClassMember> members) {
  Set<ClassMember> result = <ClassMember>{};
  _toSet(declarationBuilder, members, result);
  return result;
}

void _toSet(DeclarationBuilder declarationBuilder,
    Iterable<ClassMember> members, Set<ClassMember> result) {
  for (ClassMember member in members) {
    if (member.hasDeclarations &&
        declarationBuilder == member.declarationBuilder) {
      _toSet(declarationBuilder, member.declarations, result);
    } else {
      result.add(member);
    }
  }
}

void reportCantInferParameterType(ClassBuilder cls,
    FormalParameterBuilder parameter, Iterable<ClassMember> overriddenMembers) {
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
    Iterable<ClassMember> overriddenMembers) {
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
    Iterable<ClassMember> overriddenMembers) {
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

bool isNameVisibleIn(Name name, LibraryBuilder libraryBuilder) {
  return !name.isPrivate || name.library == libraryBuilder.library;
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
