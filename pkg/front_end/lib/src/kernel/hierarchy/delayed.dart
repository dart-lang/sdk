// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/src/types.dart';
import 'package:kernel/type_algebra.dart';

import '../../base/messages.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/library_builder.dart';
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
  final ClassMember? _localMember;

  DelayedOverrideCheck(
    this._classBuilder,
    this._declaredMember,
    this._overriddenMembers, {
    required ClassMember? localMember,
  }) : this._localMember = localMember;

  @override
  void check(ClassMembersBuilder membersBuilder) {
    Member declaredMember = _declaredMember.getMember(membersBuilder);
    Member? localMember = _localMember?.getMember(membersBuilder);

    // If the local [ClassMember] didn't produce a local [Member], don't mark
    // any member as erroneous.
    if (localMember?.enclosingTypeDeclaration != _classBuilder.cls) {
      localMember = null;
    }

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

    void callback(Member interfaceMember, bool isSetter) {
      _classBuilder.checkOverride(
        membersBuilder.hierarchyBuilder.types,
        membersBuilder,
        declaredMember,
        interfaceMember,
        isSetter,
        callback,
        isInterfaceCheck: !_classBuilder.isMixinApplication,
        localMember: localMember,
      );
    }

    for (ClassMember overriddenMember in _overriddenMembers) {
      callback(
        overriddenMember.getMember(membersBuilder),
        _declaredMember.isSetter,
      );
    }
  }
}

abstract class DelayedGetterSetterCheck implements DelayedCheck {
  DeclarationBuilder get declarationBuilder;

  LibraryBuilder get libraryBuilder => declarationBuilder.libraryBuilder;

  int get declarationOffset => declarationBuilder.fileOffset;

  Uri get declarationUri => declarationBuilder.fileUri;

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
      bool isValid = types.isSubtypeOf(getterType, setterType);
      if (!isValid) {
        if (getterIsDeclared && setterIsDeclared) {
          libraryBuilder.addProblem(
            diag.invalidGetterSetterType.withArguments(
              getterType: getterType,
              getterName: getterFullName,
              setterType: setterType,
              setterName: setterFullName,
            ),
            getterOffset,
            name.text.length,
            getterUri,
            context: [
              diag.invalidGetterSetterTypeSetterContext
                  .withArguments(setterName: setterFullName)
                  .withLocation(setterUri, setterOffset, name.text.length),
            ],
          );
        } else if (getterIsDeclared) {
          Template<
            Message Function({
              required DartType getterType,
              required String getterName,
              required DartType setterType,
              required String setterName,
            })
          >
          template = diag.invalidGetterSetterTypeSetterInheritedGetter;
          if (getterIsField) {
            template = diag.invalidGetterSetterTypeSetterInheritedField;
          }
          libraryBuilder.addProblem(
            template.withArguments(
              getterType: getterType,
              getterName: getterFullName,
              setterType: setterType,
              setterName: setterFullName,
            ),
            getterOffset,
            name.text.length,
            getterUri,
            context: [
              diag.invalidGetterSetterTypeSetterContext
                  .withArguments(setterName: setterFullName)
                  .withLocation(setterUri, setterOffset, name.text.length),
            ],
          );
        } else if (setterIsDeclared) {
          Template<
            Message Function({
              required DartType getterType,
              required String getterName,
              required DartType setterType,
              required String setterName,
            })
          >
          template = diag.invalidGetterSetterTypeGetterInherited;
          Template<Message Function({required String getterName})> context =
              diag.invalidGetterSetterTypeGetterContext;
          if (getterIsField) {
            template = diag.invalidGetterSetterTypeFieldInherited;
            context = diag.invalidGetterSetterTypeFieldContext;
          }
          libraryBuilder.addProblem(
            template.withArguments(
              getterType: getterType,
              getterName: getterFullName,
              setterType: setterType,
              setterName: setterFullName,
            ),
            setterOffset,
            name.text.length,
            setterUri,
            context: [
              context
                  .withArguments(getterName: getterFullName)
                  .withLocation(getterUri, getterOffset, name.text.length),
            ],
          );
        } else {
          Template<
            Message Function({
              required DartType getterType,
              required String getterName,
              required DartType setterType,
              required String setterName,
            })
          >
          template = diag.invalidGetterSetterTypeBothInheritedGetter;
          Template<Message Function({required String getterName})> context =
              diag.invalidGetterSetterTypeGetterContext;
          if (getterIsField) {
            template = diag.invalidGetterSetterTypeBothInheritedField;
            context = diag.invalidGetterSetterTypeFieldContext;
          }
          libraryBuilder.addProblem(
            template.withArguments(
              getterType: getterType,
              getterName: getterFullName,
              setterType: setterType,
              setterName: setterFullName,
            ),
            declarationOffset,
            noLength,
            declarationUri,
            context: [
              context
                  .withArguments(getterName: getterFullName)
                  .withLocation(getterUri, getterOffset, name.text.length),
              diag.invalidGetterSetterTypeSetterContext
                  .withArguments(setterName: setterFullName)
                  .withLocation(setterUri, setterOffset, name.text.length),
            ],
          );
        }
      }
    }
  }
}

class DelayedClassGetterSetterCheck extends DelayedGetterSetterCheck {
  final SourceClassBuilder classBuilder;
  final Name name;
  final ClassMember getable;
  final ClassMember setable;

  DelayedClassGetterSetterCheck(
    this.classBuilder,
    this.name,
    this.getable,
    this.setable,
  );

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
          thisType,
          getter.enclosingClass!,
        )!,
      ).substituteType(getterType);
    }

    DartType setterType = setter.setterType;
    if (setter.enclosingClass!.typeParameters.isNotEmpty) {
      setterType = Substitution.fromPairs(
        setter.enclosingClass!.typeParameters,
        types.hierarchy.getTypeArgumentsAsInstanceOf(
          thisType,
          setter.enclosingClass!,
        )!,
      ).substituteType(setterType);
    }
    Member getterOrigin = getter.memberSignatureOrigin ?? getter;
    Member setterOrigin = setter.memberSignatureOrigin ?? setter;
    String getterMemberName =
        '${getterOrigin.enclosingClass!.name}'
        '.${getterOrigin.name.text}';
    String setterMemberName =
        '${setterOrigin.enclosingClass!.name}'
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
      setterIsDeclared: setterOrigin.enclosingClass == cls,
    );
  }
}

// Coverage-ignore(suite): Not run.
class DelayedExtensionTypeGetterSetterCheck extends DelayedGetterSetterCheck {
  final SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder;
  final Name name;
  final ClassMember getable;
  final ClassMember setable;

  DelayedExtensionTypeGetterSetterCheck(
    this.extensionTypeDeclarationBuilder,
    this.name,
    this.getable,
    this.setable,
  );

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
      Nullability.nonNullable,
    );

    DartType getterType = getterResult.getMemberType(membersBuilder, thisType);

    DartType setterType = setterResult.getMemberType(membersBuilder, thisType);

    _checkGetterSetter(
      types: types,
      name: name,
      getterType: getterType,
      getterFullName: getterResult.fullName,
      getterOffset: getterResult.fileOffset,
      getterUri: getterResult.fileUri,
      getterIsDeclared:
          getable.isSourceDeclaration &&
          getable.declarationBuilder == declarationBuilder,
      getterIsField: getterResult.isDeclaredAsField,
      setterType: setterType,
      setterFullName: setterResult.fullName,
      setterOffset: setterResult.fileOffset,
      setterUri: setterResult.fileUri,
      setterIsDeclared:
          setable.isSourceDeclaration &&
          setable.declarationBuilder == declarationBuilder,
    );
  }
}

class DelayedTypeComputation {
  final ClassMembersNodeBuilder builder;
  final ClassMember declaredMember;
  final Set<ClassMember> overriddenMembers;
  bool _computed = false;

  DelayedTypeComputation(
    this.builder,
    this.declaredMember,
    this.overriddenMembers,
  ) : assert(declaredMember.isSourceDeclaration);

  void compute(ClassMembersBuilder membersBuilder) {
    if (_computed) return;
    declaredMember.inferType(membersBuilder);
    _computed = true;
    if (declaredMember.isProperty) {
      builder.inferPropertySignature(
        membersBuilder,
        declaredMember,
        overriddenMembers,
      );
    } else {
      builder.inferMethodSignature(
        membersBuilder,
        declaredMember,
        overriddenMembers,
      );
    }
  }

  @override
  String toString() =>
      'DelayedTypeComputation('
      '${builder.classBuilder.name},$declaredMember,$overriddenMembers)';
}
