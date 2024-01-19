// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/types.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../builder/declaration_builders.dart';
import '../../builder/library_builder.dart';
import '../../messages.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_extension_type_declaration_builder.dart';
import 'class_member.dart';
import 'members_builder.dart';
import 'members_node.dart';

abstract class DelayedCheck {
  void check(ClassMembersBuilder membersBuilder);
}

class DelayedOverrideCheck implements DelayedCheck {
  final SourceClassBuilder _classBuilder;
  final ClassMember _declaredMember;
  final Set<ClassMember> _overriddenMembers;

  DelayedOverrideCheck(
      this._classBuilder, this._declaredMember, this._overriddenMembers);

  @override
  void check(ClassMembersBuilder membersBuilder) {
    Member declaredMember = _declaredMember.getMember(membersBuilder);

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
      _classBuilder.checkOverride(membersBuilder.hierarchyBuilder.types,
          membersBuilder, declaredMember, interfaceMember, isSetter, callback,
          isInterfaceCheck: !_classBuilder.isMixinApplication,
          declaredNeedsLegacyErasure: declaredNeedsLegacyErasure);
    }

    for (ClassMember overriddenMember in _overriddenMembers) {
      callback(
          overriddenMember.getMember(membersBuilder), _declaredMember.isSetter);
    }
  }
}

abstract class DelayedGetterSetterCheck implements DelayedCheck {
  DeclarationBuilder get declarationBuilder;

  LibraryBuilder get libraryBuilder => declarationBuilder.libraryBuilder;

  int get declarationOffset => declarationBuilder.charOffset;

  Uri get declarationUri => declarationBuilder.fileUri;

  Name get name;

  void _checkGetterSetter({
    required Types types,
    required Name name,
    required DartType getterType,
    required String getterFullName,
    required int getterOffset,
    required Uri getterUri,
    required bool getterIsDeclared,
    required bool getterIsField,
    required DartType setterType,
    required String setterFullName,
    required int setterOffset,
    required Uri setterUri,
    required bool setterIsDeclared,
  }) {
    if (getterType is InvalidType || setterType is InvalidType) {
      // Don't report a problem as something else is wrong that has already
      // been reported.
    } else {
      bool isValid = types.isSubtypeOf(
          getterType,
          setterType,
          libraryBuilder.isNonNullableByDefault
              ? SubtypeCheckMode.withNullabilities
              : SubtypeCheckMode.ignoringNullabilities);
      if (!isValid && !libraryBuilder.isNonNullableByDefault) {
        // Allow assignability in legacy libraries.
        isValid = types.isSubtypeOf(
            setterType, getterType, SubtypeCheckMode.ignoringNullabilities);
      }
      if (!isValid) {
        if (getterIsDeclared && setterIsDeclared) {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterType
                  : templateInvalidGetterSetterTypeLegacy;
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterFullName, setterType,
                  setterFullName, libraryBuilder.isNonNullableByDefault),
              getterOffset,
              name.text.length,
              getterUri,
              context: [
                templateInvalidGetterSetterTypeSetterContext
                    .withArguments(setterFullName)
                    .withLocation(setterUri, setterOffset, name.text.length)
              ]);
        } else if (getterIsDeclared) {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterTypeSetterInheritedGetter
                  : templateInvalidGetterSetterTypeSetterInheritedGetterLegacy;
          if (getterIsField) {
            template = libraryBuilder.isNonNullableByDefault
                ? templateInvalidGetterSetterTypeSetterInheritedField
                : templateInvalidGetterSetterTypeSetterInheritedFieldLegacy;
          }
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterFullName, setterType,
                  setterFullName, libraryBuilder.isNonNullableByDefault),
              getterOffset,
              name.text.length,
              getterUri,
              context: [
                templateInvalidGetterSetterTypeSetterContext
                    .withArguments(setterFullName)
                    .withLocation(setterUri, setterOffset, name.text.length)
              ]);
        } else if (setterIsDeclared) {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterTypeGetterInherited
                  : templateInvalidGetterSetterTypeGetterInheritedLegacy;
          Template<Message Function(String)> context =
              templateInvalidGetterSetterTypeGetterContext;
          if (getterIsField) {
            template = libraryBuilder.isNonNullableByDefault
                ? templateInvalidGetterSetterTypeFieldInherited
                : templateInvalidGetterSetterTypeFieldInheritedLegacy;
            context = templateInvalidGetterSetterTypeFieldContext;
          }
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterFullName, setterType,
                  setterFullName, libraryBuilder.isNonNullableByDefault),
              setterOffset,
              name.text.length,
              setterUri,
              context: [
                context
                    .withArguments(getterFullName)
                    .withLocation(getterUri, getterOffset, name.text.length)
              ]);
        } else {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterTypeBothInheritedGetter
                  : templateInvalidGetterSetterTypeBothInheritedGetterLegacy;
          Template<Message Function(String)> context =
              templateInvalidGetterSetterTypeGetterContext;
          if (getterIsField) {
            template = libraryBuilder.isNonNullableByDefault
                ? templateInvalidGetterSetterTypeBothInheritedField
                : templateInvalidGetterSetterTypeBothInheritedFieldLegacy;
            context = templateInvalidGetterSetterTypeFieldContext;
          }
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterFullName, setterType,
                  setterFullName, libraryBuilder.isNonNullableByDefault),
              declarationOffset,
              noLength,
              declarationUri,
              context: [
                context
                    .withArguments(getterFullName)
                    .withLocation(getterUri, getterOffset, name.text.length),
                templateInvalidGetterSetterTypeSetterContext
                    .withArguments(setterFullName)
                    .withLocation(setterUri, setterOffset, name.text.length)
              ]);
        }
      }
    }
  }
}

class DelayedClassGetterSetterCheck extends DelayedGetterSetterCheck {
  final SourceClassBuilder classBuilder;
  @override
  final Name name;
  final ClassMember getable;
  final ClassMember setable;

  DelayedClassGetterSetterCheck(
      this.classBuilder, this.name, this.getable, this.setable);

  @override
  DeclarationBuilder get declarationBuilder => classBuilder;

  @override
  void check(ClassMembersBuilder membersBuilder) {
    Class cls = classBuilder.cls;
    Member getter = getable.getMember(membersBuilder);
    Member setter = setable.getMember(membersBuilder);
    if (getter == setter) {
      return;
    }
    if (cls != getter.enclosingClass &&
        getter.enclosingClass == setter.enclosingClass) {
      return;
    }

    Types types = membersBuilder.hierarchyBuilder.types;
    InterfaceType thisType = classBuilder.thisType;
    DartType getterType = getter.getterType;
    if (getter.enclosingClass!.typeParameters.isNotEmpty) {
      getterType = Substitution.fromPairs(
              getter.enclosingClass!.typeParameters,
              types.hierarchy.getTypeArgumentsAsInstanceOf(
                  thisType, getter.enclosingClass!)!)
          .substituteType(getterType);
    }

    DartType setterType = setter.setterType;
    if (setter.enclosingClass!.typeParameters.isNotEmpty) {
      setterType = Substitution.fromPairs(
              setter.enclosingClass!.typeParameters,
              types.hierarchy.getTypeArgumentsAsInstanceOf(
                  thisType, setter.enclosingClass!)!)
          .substituteType(setterType);
    }
    Member getterOrigin = getter.memberSignatureOrigin ?? getter;
    Member setterOrigin = setter.memberSignatureOrigin ?? setter;
    String getterMemberName = '${getterOrigin.enclosingClass!.name}'
        '.${getterOrigin.name.text}';
    String setterMemberName = '${setterOrigin.enclosingClass!.name}'
        '.${setterOrigin.name.text}';

    _checkGetterSetter(
        types: types,
        name: name,
        getterType: getterType,
        getterFullName: getterMemberName,
        getterOffset: getterOrigin.fileOffset,
        getterUri: getterOrigin.fileUri,
        getterIsDeclared: getterOrigin.enclosingClass == cls,
        getterIsField: getterOrigin is Field,
        setterType: setterType,
        setterFullName: setterMemberName,
        setterOffset: setterOrigin.fileOffset,
        setterUri: setterOrigin.fileUri,
        setterIsDeclared: setterOrigin.enclosingClass == cls);
  }
}

class DelayedExtensionTypeGetterSetterCheck extends DelayedGetterSetterCheck {
  final SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder;
  @override
  final Name name;
  final ClassMember getable;
  final ClassMember setable;

  DelayedExtensionTypeGetterSetterCheck(this.extensionTypeDeclarationBuilder,
      this.name, this.getable, this.setable);

  @override
  DeclarationBuilder get declarationBuilder => extensionTypeDeclarationBuilder;

  @override
  void check(ClassMembersBuilder membersBuilder) {
    if (getable.isSameDeclaration(setable)) {
      return;
    }

    MemberResult getterResult = getable.getMemberResult(membersBuilder);
    MemberResult setterResult = setable.getMemberResult(membersBuilder);

    Types types = membersBuilder.hierarchyBuilder.types;
    ExtensionType thisType = types.coreTypes.thisExtensionType(
        extensionTypeDeclarationBuilder.extensionTypeDeclaration,
        Nullability.nonNullable);

    DartType getterType = getterResult.getMemberType(membersBuilder, thisType);

    DartType setterType = setterResult.getMemberType(membersBuilder, thisType);

    _checkGetterSetter(
        types: types,
        name: name,
        getterType: getterType,
        getterFullName: getterResult.fullName,
        getterOffset: getterResult.fileOffset,
        getterUri: getterResult.fileUri,
        getterIsDeclared: getable.isSourceDeclaration &&
            getable.declarationBuilder == declarationBuilder,
        getterIsField: getterResult.isDeclaredAsField,
        setterType: setterType,
        setterFullName: setterResult.fullName,
        setterOffset: setterResult.fileOffset,
        setterUri: setterResult.fileUri,
        setterIsDeclared: setable.isSourceDeclaration &&
            setable.declarationBuilder == declarationBuilder);
  }
}

class DelayedTypeComputation {
  final ClassMembersNodeBuilder builder;
  final ClassMember declaredMember;
  final Set<ClassMember> overriddenMembers;
  bool _computed = false;

  DelayedTypeComputation(
      this.builder, this.declaredMember, this.overriddenMembers)
      : assert(declaredMember.isSourceDeclaration);

  void compute(ClassMembersBuilder membersBuilder) {
    if (_computed) return;
    declaredMember.inferType(membersBuilder);
    _computed = true;
    if (declaredMember.isField) {
      builder.inferFieldSignature(
          membersBuilder, declaredMember, overriddenMembers);
    } else if (declaredMember.isGetter) {
      builder.inferGetterSignature(
          membersBuilder, declaredMember, overriddenMembers);
    } else if (declaredMember.isSetter) {
      builder.inferSetterSignature(
          membersBuilder, declaredMember, overriddenMembers);
    } else {
      builder.inferMethodSignature(
          membersBuilder, declaredMember, overriddenMembers);
    }
  }

  @override
  String toString() => 'DelayedTypeComputation('
      '${builder.classBuilder.name},$declaredMember,$overriddenMembers)';
}
