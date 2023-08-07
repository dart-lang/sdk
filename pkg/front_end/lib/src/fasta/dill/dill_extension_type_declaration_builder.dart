// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/extension_type_declaration_builder.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import 'package:kernel/ast.dart';

import '../scope.dart';
import 'dill_class_builder.dart';
import 'dill_extension_type_member_builder.dart';
import 'dill_library_builder.dart';

class DillExtensionTypeDeclarationBuilder
    extends ExtensionTypeDeclarationBuilderImpl {
  final ExtensionTypeDeclaration _extensionTypeDeclaration;

  List<TypeVariableBuilder>? _typeParameters;

  List<TypeBuilder>? _interfaceBuilders;

  TypeBuilder? _declaredRepresentationTypeBuilder;

  DillExtensionTypeDeclarationBuilder(
      this._extensionTypeDeclaration, DillLibraryBuilder parent)
      : super(
            /*metadata builders*/
            null,
            /* modifiers*/
            0,
            _extensionTypeDeclaration.name,
            parent,
            _extensionTypeDeclaration.fileOffset,
            new Scope(
                kind: ScopeKind.declaration,
                local: <String, MemberBuilder>{},
                setters: <String, MemberBuilder>{},
                parent: parent.scope,
                debugName: "extension type ${_extensionTypeDeclaration.name}",
                isModifiable: false),
            new ConstructorScope(
                _extensionTypeDeclaration.name, <String, MemberBuilder>{})) {
    Map<Name, Procedure> _tearOffs = {};
    for (ExtensionTypeMemberDescriptor descriptor
        in _extensionTypeDeclaration.members) {
      Name name = descriptor.name;
      if (descriptor.kind == ExtensionTypeMemberKind.TearOff) {
        _tearOffs[name] = descriptor.member.asProcedure;
      }
    }

    for (ExtensionTypeMemberDescriptor descriptor
        in _extensionTypeDeclaration.members) {
      Name name = descriptor.name;
      switch (descriptor.kind) {
        case ExtensionTypeMemberKind.Method:
          if (descriptor.isStatic) {
            Procedure procedure = descriptor.member.asProcedure;
            scope.addLocalMember(
                name.text,
                new DillExtensionTypeStaticMethodBuilder(
                    procedure, descriptor, this),
                setter: false);
          } else {
            Procedure procedure = descriptor.member.asProcedure;
            assert(_tearOffs.containsKey(name),
                "No tear found for ${descriptor} in ${_tearOffs}");
            scope.addLocalMember(
                name.text,
                new DillExtensionTypeInstanceMethodBuilder(
                    procedure, descriptor, this, _tearOffs[name]!),
                setter: false);
          }
          break;
        case ExtensionTypeMemberKind.TearOff:
          assert(_tearOffs[name] == descriptor.member.asProcedure);
          break;
        case ExtensionTypeMemberKind.Getter:
          Procedure procedure = descriptor.member.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeGetterBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Field:
          Field field = descriptor.member.asField;
          scope.addLocalMember(name.text,
              new DillExtensionTypeFieldBuilder(field, descriptor, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Setter:
          Procedure procedure = descriptor.member.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeSetterBuilder(procedure, descriptor, this),
              setter: true);
          break;
        case ExtensionTypeMemberKind.Operator:
          Procedure procedure = descriptor.member.asProcedure;
          scope.addLocalMember(name.text,
              new DillExtensionTypeOperatorBuilder(procedure, descriptor, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Constructor:
          Procedure procedure = descriptor.member.asProcedure;
          constructorScope.addLocalMember(
              name.text,
              new DillExtensionTypeConstructorBuilder(
                  procedure, _tearOffs[name], descriptor, this));
          break;
        case ExtensionTypeMemberKind.Factory:
        case ExtensionTypeMemberKind.RedirectingFactory:
          Procedure procedure = descriptor.member.asProcedure;
          constructorScope.addLocalMember(
              name.text,
              new DillExtensionTypeFactoryBuilder(
                  procedure, _tearOffs[name], descriptor, this));
          break;
      }
    }
  }

  @override
  DillLibraryBuilder get libraryBuilder => parent as DillLibraryBuilder;

  @override
  DartType get declaredRepresentationType =>
      _extensionTypeDeclaration.declaredRepresentationType;

  @override
  TypeBuilder? get declaredRepresentationTypeBuilder =>
      _declaredRepresentationTypeBuilder ??=
          libraryBuilder.loader.computeTypeBuilder(declaredRepresentationType);

  @override
  ExtensionTypeDeclaration get extensionTypeDeclaration =>
      _extensionTypeDeclaration;

  @override
  List<TypeVariableBuilder>? get typeParameters {
    List<TypeVariableBuilder>? typeVariables = _typeParameters;
    if (typeVariables == null &&
        _extensionTypeDeclaration.typeParameters.isNotEmpty) {
      typeVariables = _typeParameters = computeTypeVariableBuilders(
          libraryBuilder, _extensionTypeDeclaration.typeParameters);
    }
    return typeVariables;
  }

  @override
  List<TypeBuilder>? get interfaceBuilders {
    if (_extensionTypeDeclaration.implements.isEmpty) return null;
    List<TypeBuilder>? interfaceBuilders = _interfaceBuilders;
    if (interfaceBuilders == null) {
      interfaceBuilders = _interfaceBuilders = new List<TypeBuilder>.generate(
          _extensionTypeDeclaration.implements.length,
          (int i) => libraryBuilder.loader
              .computeTypeBuilder(_extensionTypeDeclaration.implements[i]),
          growable: false);
    }
    return interfaceBuilders;
  }
}
