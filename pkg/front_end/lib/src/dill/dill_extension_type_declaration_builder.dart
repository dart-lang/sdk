// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/name_space.dart';
import '../builder/declaration_builders.dart';
import '../builder/type_builder.dart';
import 'dill_builder_mixins.dart';
import 'dill_class_builder.dart';
import 'dill_extension_type_member_builder.dart';
import 'dill_library_builder.dart';
import 'dill_member_builder.dart';

class DillExtensionTypeDeclarationBuilder
    extends ExtensionTypeDeclarationBuilderImpl
    with DillClassMemberAccessMixin, DillDeclarationBuilderMixin {
  @override
  final DillLibraryBuilder libraryBuilder;

  final ExtensionTypeDeclaration _extensionTypeDeclaration;

  final MutableDeclarationNameSpace _nameSpace;

  List<NominalParameterBuilder>? _typeParameters;

  List<TypeBuilder>? _interfaceBuilders;

  TypeBuilder? _declaredRepresentationTypeBuilder;

  DillExtensionTypeDeclarationBuilder(
      this._extensionTypeDeclaration, this.libraryBuilder)
      : _nameSpace = new DillDeclarationNameSpace() {
    for (Procedure procedure in _extensionTypeDeclaration.procedures) {
      String name = procedure.name.text;
      switch (procedure.kind) {
        case ProcedureKind.Factory:
          // Coverage-ignore(suite): Not run.
          throw new UnsupportedError(
              "Unexpected procedure kind in extension type declaration: "
              "$procedure (${procedure.kind}).");
        case ProcedureKind.Setter:
          // Coverage-ignore(suite): Not run.
          _nameSpace.addLocalMember(
              name, new DillSetterBuilder(procedure, libraryBuilder, this),
              setter: true);
          break;
        case ProcedureKind.Getter:
          _nameSpace.addLocalMember(
              name, new DillGetterBuilder(procedure, libraryBuilder, this),
              setter: false);
          break;
        case ProcedureKind.Operator:
          _nameSpace.addLocalMember(
              name, new DillOperatorBuilder(procedure, libraryBuilder, this),
              setter: false);
          break;
        case ProcedureKind.Method:
          _nameSpace.addLocalMember(
              name, new DillMethodBuilder(procedure, libraryBuilder, this),
              setter: false);
          break;
      }
    }
    for (ExtensionTypeMemberDescriptor descriptor
        in _extensionTypeDeclaration.memberDescriptors) {
      if (descriptor.isInternalImplementation) continue;

      Name name = descriptor.name;
      switch (descriptor.kind) {
        case ExtensionTypeMemberKind.Method:
          if (descriptor.isStatic) {
            Procedure procedure = descriptor.memberReference!.asProcedure;
            _nameSpace.addLocalMember(
                name.text,
                new DillExtensionTypeStaticMethodBuilder(
                    procedure, descriptor, libraryBuilder, this),
                setter: false);
          } else {
            Procedure procedure = descriptor.memberReference!.asProcedure;
            Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
            assert(tearOff != null, "No tear found for ${descriptor}");
            _nameSpace.addLocalMember(
                name.text,
                new DillExtensionTypeInstanceMethodBuilder(
                    procedure, descriptor, libraryBuilder, this, tearOff!),
                setter: false);
          }
          break;
        case ExtensionTypeMemberKind.Getter:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          _nameSpace.addLocalMember(
              name.text,
              new DillExtensionTypeGetterBuilder(
                  procedure, descriptor, libraryBuilder, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Field:
          Field field = descriptor.memberReference!.asField;
          _nameSpace.addLocalMember(
              name.text,
              new DillExtensionTypeFieldBuilder(
                  field, descriptor, libraryBuilder, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Setter:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          _nameSpace.addLocalMember(
              name.text,
              new DillExtensionTypeSetterBuilder(
                  procedure, descriptor, libraryBuilder, this),
              setter: true);
          break;
        case ExtensionTypeMemberKind.Operator:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          _nameSpace.addLocalMember(
              name.text,
              new DillExtensionTypeOperatorBuilder(
                  procedure, descriptor, libraryBuilder, this),
              setter: false);
          break;
        case ExtensionTypeMemberKind.Constructor:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
          _nameSpace.addConstructor(
              name.text,
              new DillExtensionTypeConstructorBuilder(
                  procedure, tearOff, descriptor, libraryBuilder, this));
          break;
        case ExtensionTypeMemberKind.Factory:
        case ExtensionTypeMemberKind.RedirectingFactory:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
          _nameSpace.addConstructor(
              name.text,
              new DillExtensionTypeFactoryBuilder(
                  procedure, tearOff, descriptor, libraryBuilder, this));
          break;
      }
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => _extensionTypeDeclaration.fileOffset;

  @override
  String get name => _extensionTypeDeclaration.name;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _extensionTypeDeclaration.fileUri;

  @override
  DillLibraryBuilder get parent => libraryBuilder;

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

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
  List<NominalParameterBuilder>? get typeParameters {
    List<NominalParameterBuilder>? typeParameters = _typeParameters;
    if (typeParameters == null &&
        _extensionTypeDeclaration.typeParameters.isNotEmpty) {
      typeParameters = _typeParameters = computeTypeParameterBuilders(
          _extensionTypeDeclaration.typeParameters, libraryBuilder.loader);
    }
    return typeParameters;
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

  @override
  List<TypeParameter> get typeParameterNodes =>
      _extensionTypeDeclaration.typeParameters;

  @override
  Nullability computeNullability(
          {Map<ExtensionTypeDeclarationBuilder, TraversalState>?
              traversalState}) =>
      _extensionTypeDeclaration.inherentNullability;

  @override
  Reference get reference => _extensionTypeDeclaration.reference;
}
