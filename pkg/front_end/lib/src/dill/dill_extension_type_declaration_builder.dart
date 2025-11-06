// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/lookup_result.dart';
import '../base/name_space.dart';
import '../base/scope.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../builder/type_builder.dart';
import 'dill_builder_mixins.dart';
import 'dill_class_builder.dart';
import 'dill_extension_type_member_builder.dart';
import 'dill_library_builder.dart';
import 'dill_member_builder.dart';

class DillExtensionTypeDeclarationBuilder
    extends ExtensionTypeDeclarationBuilderImpl
    with DillDeclarationBuilderMixin {
  @override
  final DillLibraryBuilder libraryBuilder;

  final ExtensionTypeDeclaration _extensionTypeDeclaration;

  late final DeclarationNameSpace _nameSpace;

  List<NominalParameterBuilder>? _typeParameters;

  List<TypeBuilder>? _interfaceBuilders;

  TypeBuilder? _declaredRepresentationTypeBuilder;

  final List<MemberBuilder> _constructorBuilders = [];
  final List<MemberBuilder> _memberBuilders = [];

  DillExtensionTypeDeclarationBuilder(
    this._extensionTypeDeclaration,
    this.libraryBuilder,
  ) {
    Map<String, MemberLookupResult> constructors = {};
    Map<String, MemberLookupResult> content = {};

    bool isPrivateFromOtherLibrary(Member member) {
      Name name = member.name;
      return name.isPrivate &&
          name.libraryReference !=
              _extensionTypeDeclaration.enclosingLibrary.reference;
    }

    for (Procedure procedure in _extensionTypeDeclaration.procedures) {
      String name = procedure.name.text;
      switch (procedure.kind) {
        case ProcedureKind.Factory:
          // Coverage-ignore(suite): Not run.
          throw new UnsupportedError(
            "Unexpected procedure kind in extension type declaration: "
            "$procedure (${procedure.kind}).",
          );
        case ProcedureKind.Setter:
          // Coverage-ignore(suite): Not run.
          DillSetterBuilder builder = new DillSetterBuilder(
            procedure,
            libraryBuilder,
            this,
          );
          // Coverage-ignore(suite): Not run.
          if (!isPrivateFromOtherLibrary(procedure)) {
            MemberLookupResult? existing = content[name];
            if (existing != null) {
              assert(
                existing.getable != null && existing.setable == null,
                "Unexpected existing member $existing, "
                "trying to add $builder.",
              );
              assert(
                existing.isStatic == builder.isStatic,
                "Static/instance conflict between existing member $existing "
                "and new builder $builder.",
              );
              content[name] = new GetableSetableMemberResult(
                existing.getable!,
                builder,
                isStatic: existing.isStatic,
              );
            } else {
              content[name] = builder;
            }
          }
          // Coverage-ignore(suite): Not run.
          _memberBuilders.add(builder);
          break;
        case ProcedureKind.Getter:
          DillGetterBuilder builder = new DillGetterBuilder(
            procedure,
            libraryBuilder,
            this,
          );
          if (!isPrivateFromOtherLibrary(procedure)) {
            MemberLookupResult? existing = content[name];
            if (existing != null) {
              // Coverage-ignore-block(suite): Not run.
              assert(
                existing.getable == null && existing.setable != null,
                "Unexpected existing member $existing, "
                "trying to add $builder.",
              );
              assert(
                existing.isStatic == builder.isStatic,
                "Static/instance conflict between existing member $existing "
                "and new builder $builder.",
              );
              content[name] = new GetableSetableMemberResult(
                builder,
                existing.setable!,
                isStatic: existing.isStatic,
              );
            } else {
              content[name] = builder;
            }
          }
          _memberBuilders.add(builder);
          break;
        case ProcedureKind.Operator:
          DillOperatorBuilder builder = new DillOperatorBuilder(
            procedure,
            libraryBuilder,
            this,
          );
          if (!isPrivateFromOtherLibrary(procedure)) {
            assert(
              !constructors.containsKey(name),
              "Unexpected existing member ${constructors[name]}, "
              "trying to add $builder.",
            );
            constructors[name] = builder;
          }
          _memberBuilders.add(builder);
          break;
        case ProcedureKind.Method:
          DillMethodBuilder builder = new DillMethodBuilder(
            procedure,
            libraryBuilder,
            this,
          );
          if (!isPrivateFromOtherLibrary(procedure)) {
            assert(
              !constructors.containsKey(name),
              "Unexpected existing member ${constructors[name]}, "
              "trying to add $builder.",
            );
            constructors[name] = builder;
          }
          _memberBuilders.add(builder);
          break;
      }
    }
    for (ExtensionTypeMemberDescriptor descriptor
        in _extensionTypeDeclaration.memberDescriptors) {
      if (descriptor.isInternalImplementation) continue;

      String name = descriptor.name.text;
      switch (descriptor.kind) {
        case ExtensionTypeMemberKind.Method:
          MemberBuilder builder;
          Procedure procedure = descriptor.memberReference!.asProcedure;
          if (descriptor.isStatic) {
            builder = new DillExtensionTypeStaticMethodBuilder(
              procedure,
              descriptor,
              libraryBuilder,
              this,
            );
          } else {
            Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
            assert(tearOff != null, "No tear found for ${descriptor}");
            builder = new DillExtensionTypeInstanceMethodBuilder(
              procedure,
              descriptor,
              libraryBuilder,
              this,
              tearOff!,
            );
          }
          if (!isPrivateFromOtherLibrary(procedure)) {
            assert(
              !content.containsKey(name),
              "Unexpected existing member ${content[name]}, "
              "trying to add $builder.",
            );
            content[name] = builder;
          }
          _memberBuilders.add(builder);
          break;
        case ExtensionTypeMemberKind.Getter:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          DillExtensionTypeGetterBuilder builder =
              new DillExtensionTypeGetterBuilder(
                procedure,
                descriptor,
                libraryBuilder,
                this,
              );
          if (!isPrivateFromOtherLibrary(procedure)) {
            MemberLookupResult? existing = content[name];
            if (existing != null) {
              // Coverage-ignore-block(suite): Not run.
              assert(
                existing.getable == null && existing.setable != null,
                "Unexpected existing member $existing, "
                "trying to add $builder.",
              );
              assert(
                existing.isStatic == builder.isStatic,
                "Static/instance conflict between existing member $existing "
                "and new builder $builder.",
              );
              content[name] = new GetableSetableMemberResult(
                builder,
                existing.setable!,
                isStatic: existing.isStatic,
              );
            } else {
              content[name] = builder;
            }
          }
          _memberBuilders.add(builder);
          break;
        case ExtensionTypeMemberKind.Field:
          Field field = descriptor.memberReference!.asField;
          DillExtensionTypeFieldBuilder builder =
              new DillExtensionTypeFieldBuilder(
                field,
                descriptor,
                libraryBuilder,
                this,
              );
          if (!isPrivateFromOtherLibrary(field)) {
            MemberLookupResult? existing = content[name];
            if (existing != null) {
              // Coverage-ignore-block(suite): Not run.
              assert(
                existing.getable == null && existing.setable != null,
                "Unexpected existing member $existing, "
                "trying to add $builder.",
              );
              assert(
                existing.isStatic == builder.isStatic,
                "Static/instance conflict between existing member $existing "
                "and new builder $builder.",
              );
              content[name] = new GetableSetableMemberResult(
                builder,
                existing.setable!,
                isStatic: existing.isStatic,
              );
            } else {
              content[name] = builder;
            }
          }
          _memberBuilders.add(builder);
          break;
        case ExtensionTypeMemberKind.Setter:
          Procedure procedure = descriptor.memberReference!.asProcedure;

          DillExtensionTypeSetterBuilder builder =
              new DillExtensionTypeSetterBuilder(
                procedure,
                descriptor,
                libraryBuilder,
                this,
              );
          if (!isPrivateFromOtherLibrary(procedure)) {
            MemberLookupResult? existing = content[name];
            if (existing != null) {
              assert(
                existing.getable != null && existing.setable == null,
                "Unexpected existing member $existing, "
                "trying to add $builder.",
              );
              assert(
                existing.isStatic == builder.isStatic,
                "Static/instance conflict between existing member $existing "
                "and new builder $builder.",
              );
              content[name] = new GetableSetableMemberResult(
                existing.getable!,
                builder,
                isStatic: existing.isStatic,
              );
            } else {
              content[name] = builder;
            }
          }
          _memberBuilders.add(builder);
          break;
        case ExtensionTypeMemberKind.Operator:
          Procedure procedure = descriptor.memberReference!.asProcedure;

          DillExtensionTypeOperatorBuilder builder =
              new DillExtensionTypeOperatorBuilder(
                procedure,
                descriptor,
                libraryBuilder,
                this,
              );
          if (!isPrivateFromOtherLibrary(procedure)) {
            assert(
              !content.containsKey(name),
              "Unexpected existing member ${content[name]}, "
              "trying to add $builder.",
            );
            content[name] = builder;
          }
          _memberBuilders.add(builder);
          break;
        case ExtensionTypeMemberKind.Constructor:
          Procedure procedure = descriptor.memberReference!.asProcedure;

          Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
          DillExtensionTypeConstructorBuilder builder =
              new DillExtensionTypeConstructorBuilder(
                procedure,
                tearOff,
                descriptor,
                libraryBuilder,
                this,
              );
          if (!isPrivateFromOtherLibrary(procedure)) {
            assert(
              !constructors.containsKey(name),
              "Unexpected existing member ${constructors[name]}, "
              "trying to add $builder.",
            );
            constructors[name] = builder;
          }
          _constructorBuilders.add(builder);

          break;
        case ExtensionTypeMemberKind.Factory:
        case ExtensionTypeMemberKind.RedirectingFactory:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
          DillExtensionTypeFactoryBuilder builder =
              new DillExtensionTypeFactoryBuilder(
                procedure,
                tearOff,
                descriptor,
                libraryBuilder,
                this,
              );
          if (!isPrivateFromOtherLibrary(procedure)) {
            assert(
              !constructors.containsKey(name),
              "Unexpected existing member ${constructors[name]}, "
              "trying to add $builder.",
            );
            constructors[name] = builder;
          }
          _constructorBuilders.add(builder);
          break;
      }
    }
    _nameSpace = new DillDeclarationNameSpace(
      constructors: constructors,
      content: content,
    );
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
      _declaredRepresentationTypeBuilder ??= libraryBuilder.loader
          .computeTypeBuilder(declaredRepresentationType);

  @override
  ExtensionTypeDeclaration get extensionTypeDeclaration =>
      _extensionTypeDeclaration;

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<MemberBuilder> get unfilteredMembersIterator =>
      _memberBuilders.iterator;

  @override
  Iterator<T> filteredMembersIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _memberBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<MemberBuilder> get unfilteredConstructorsIterator =>
      _constructorBuilders.iterator;

  @override
  Iterator<T> filteredConstructorsIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _constructorBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  List<NominalParameterBuilder>? get typeParameters {
    List<NominalParameterBuilder>? typeParameters = _typeParameters;
    if (typeParameters == null &&
        _extensionTypeDeclaration.typeParameters.isNotEmpty) {
      typeParameters = _typeParameters = computeTypeParameterBuilders(
        _extensionTypeDeclaration.typeParameters,
        libraryBuilder.loader,
      );
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
        (int i) => libraryBuilder.loader.computeTypeBuilder(
          _extensionTypeDeclaration.implements[i],
        ),
        growable: false,
      );
    }
    return interfaceBuilders;
  }

  @override
  List<TypeParameter> get typeParameterNodes =>
      _extensionTypeDeclaration.typeParameters;

  @override
  Nullability computeNullability({
    Map<ExtensionTypeDeclarationBuilder, TraversalState>? traversalState,
  }) => _extensionTypeDeclaration.inherentNullability;

  @override
  Reference get reference => _extensionTypeDeclaration.reference;
}
