// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/source/source_type_alias_builder.dart';
import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../source/name_scheme.dart';
import '../source/source_extension_builder.dart';
import '../source/type_parameter_scope_builder.dart';

sealed class Fragment {
  Builder get builder;
}

class TypedefFragment implements Fragment {
  final List<MetadataBuilder>? metadata;
  final String name;
  final List<NominalVariableBuilder>? typeVariables;
  final TypeBuilder type;
  final Uri fileUri;
  final int fileOffset;
  final Reference? reference;

  SourceTypeAliasBuilder? _builder;

  TypedefFragment(
      {required this.metadata,
      required this.name,
      required this.typeVariables,
      required this.type,
      required this.fileUri,
      required this.fileOffset,
      required this.reference});

  @override
  // Coverage-ignore(suite): Not run.
  SourceTypeAliasBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceTypeAliasBuilder value) {
    assert(
        _builder == null, // Coverage-ignore(suite): Not run.
        "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => "$runtimeType($name,$fileUri,$fileOffset)";
}

class ExtensionFragment extends DeclarationFragment implements Fragment {
  final ExtensionName extensionName;

  @override
  final int fileOffset;

  /// The type of `this` in instance methods declared in extension declarations.
  ///
  /// Instance methods declared in extension declarations methods are extended
  /// with a synthesized parameter of this type.
  TypeBuilder? _extensionThisType;

  SourceExtensionBuilder? _builder;

  late final List<MetadataBuilder>? metadata;
  late final int modifiers;
  late final TypeBuilder onType;
  late final int startOffset;
  late final int nameOffset;
  late final int endOffset;
  late final Reference? reference;

  ExtensionFragment(
      String? name,
      super.fileUri,
      this.fileOffset,
      super.typeParameters,
      super.typeParameterScope,
      super._nominalParameterNameSpace)
      : extensionName = name != null
            ? new FixedExtensionName(name)
            : new UnnamedExtensionName();

  @override
  SourceExtensionBuilder get builder {
    assert(
        _builder != null, // Coverage-ignore(suite): Not run.
        "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceExtensionBuilder value) {
    assert(
        _builder == null, // Coverage-ignore(suite): Not run.
        "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String get name => extensionName.name;

  @override
  ContainerName get containerName => extensionName;

  @override
  ContainerType get containerType => ContainerType.Extension;

  @override
  // Coverage-ignore(suite): Not run.
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionDeclaration;

  /// Registers the 'extension this type' of the extension declaration prepared
  /// for by this builder.
  ///
  /// See [extensionThisType] for terminology.
  void registerExtensionThisType(TypeBuilder type) {
    assert(_extensionThisType == null,
        "Extension this type has already been set.");
    _extensionThisType = type;
  }

  /// Returns the 'extension this type' of the extension declaration prepared
  /// for by this builder.
  ///
  /// The 'extension this type' is the type mentioned in the on-clause of the
  /// extension declaration. For instance `B` in this extension declaration:
  ///
  ///     extension A on B {
  ///       B method() => this;
  ///     }
  ///
  /// The 'extension this type' is the type if `this` expression in instance
  /// methods declared in extension declarations.
  TypeBuilder get extensionThisType {
    assert(
        _extensionThisType != null,
        // Coverage-ignore(suite): Not run.
        "DeclarationBuilder.extensionThisType has not been set on $this.");
    return _extensionThisType!;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}
