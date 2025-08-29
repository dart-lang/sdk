// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
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
import 'dill_extension_member_builder.dart';
import 'dill_library_builder.dart';

class DillExtensionBuilder extends ExtensionBuilderImpl
    with DillDeclarationBuilderMixin {
  @override
  final DillLibraryBuilder libraryBuilder;

  @override
  final Extension extension;

  late final DeclarationNameSpace _nameSpace;

  final List<MemberBuilder> _constructorBuilders = [];
  final List<MemberBuilder> _memberBuilders = [];

  List<NominalParameterBuilder>? _typeParameters;
  TypeBuilder? _onType;

  DillExtensionBuilder(this.extension, this.libraryBuilder) {
    Map<String, MemberLookupResult> content = {};

    bool isPrivateFromOtherLibrary(Member member) {
      Name name = member.name;
      return name.isPrivate &&
          name.libraryReference != extension.enclosingLibrary.reference;
    }

    for (ExtensionMemberDescriptor descriptor in extension.memberDescriptors) {
      if (descriptor.isInternalImplementation) continue;

      String name = descriptor.name.text;
      switch (descriptor.kind) {
        case ExtensionMemberKind.Method:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          MemberBuilder builder;
          if (descriptor.isStatic) {
            builder = new DillExtensionStaticMethodBuilder(
              procedure,
              descriptor,
              libraryBuilder,
              this,
            );
          } else {
            Procedure? tearOff = descriptor.tearOffReference?.asProcedure;
            assert(tearOff != null, "No tear found for ${descriptor}");
            builder = new DillExtensionInstanceMethodBuilder(
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
        case ExtensionMemberKind.Getter:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          DillExtensionGetterBuilder builder = new DillExtensionGetterBuilder(
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
        case ExtensionMemberKind.Field:
          Field field = descriptor.memberReference!.asField;
          DillExtensionFieldBuilder builder = new DillExtensionFieldBuilder(
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
        case ExtensionMemberKind.Setter:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          DillExtensionSetterBuilder builder = new DillExtensionSetterBuilder(
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
        case ExtensionMemberKind.Operator:
          Procedure procedure = descriptor.memberReference!.asProcedure;
          DillExtensionOperatorBuilder builder =
              new DillExtensionOperatorBuilder(
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
      }
    }

    _nameSpace = new DillDeclarationNameSpace(
      constructors: const {},
      content: content,
    );
  }

  @override
  DillLibraryBuilder get parent => libraryBuilder;

  @override
  Reference get reference => extension.reference;

  @override
  int get fileOffset => extension.fileOffset;

  @override
  String get name => extension.name;

  @override
  Uri get fileUri => extension.fileUri;

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<MemberBuilder> get unfilteredMembersIterator =>
      _memberBuilders.iterator;

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  Iterator<T> filteredConstructorsIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _constructorBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  List<NominalParameterBuilder>? get typeParameters {
    if (_typeParameters == null && extension.typeParameters.isNotEmpty) {
      _typeParameters = computeTypeParameterBuilders(
        extension.typeParameters,
        libraryBuilder.loader,
      );
    }
    return _typeParameters;
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeBuilder get onType {
    return _onType ??= libraryBuilder.loader.computeTypeBuilder(
      extension.onType,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<TypeParameter> get typeParameterNodes => extension.typeParameters;
}
