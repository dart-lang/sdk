// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ExtensionFragment extends DeclarationFragment implements Fragment {
  final ExtensionName extensionName;

  @override
  final int fileOffset;

  SourceExtensionBuilder? _builder;

  late final List<MetadataBuilder>? metadata;
  late final Modifiers modifiers;
  late final TypeBuilder onType;
  late final int startOffset;
  late final int nameOrExtensionOffset;
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

  bool get isUnnamed => extensionName.isUnnamedExtension;

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

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}
