// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ExtensionFragment extends DeclarationFragmentImpl implements Fragment {
  @override
  final UriOffsetLength uriOffset;

  final ExtensionName extensionName;

  SourceExtensionBuilder? _builder;

  late final List<MetadataBuilder>? metadata;
  late final TypeBuilder onType;
  late final int startOffset;
  late final int endOffset;

  new({
    required String? name,
    required this.uriOffset,
    required super.typeParameters,
    required super.enclosingScope,
    required super.typeParameterScope,
    required super.nominalParameterNameSpace,
    required super.enclosingCompilationUnit,
  }) : extensionName = name != null
           ? new FixedExtensionName(name)
           : new UnnamedExtensionName();

  @override
  Uri get fileUri => uriOffset.fileUri;

  int get nameOrExtensionOffset => uriOffset.fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  SourceExtensionBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceExtensionBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  bool get isPatch => enclosingCompilationUnit.isPatch && modifiers.isAugment;

  bool get isUnnamed => extensionName.isUnnamedExtension;

  @override
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionDeclaration;

  @override
  String get name => extensionName.name;

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOrExtensionOffset)';
}
