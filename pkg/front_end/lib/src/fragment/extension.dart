// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

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
  late final Modifiers modifiers;
  late final TypeBuilder onType;
  late final int startOffset;
  late final int nameOffset;
  late final int endOffset;

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
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceExtensionBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String get name => extensionName.name;

  @override
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
    assert(_extensionThisType != null,
        "DeclarationBuilder.extensionThisType has not been set on $this.");
    return _extensionThisType!;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}
