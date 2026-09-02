// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast;
import 'package:kernel/class_hierarchy.dart';

import '../../builder/constructor_reference_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../source/source_library_builder.dart';
import '../fragment.dart';

class ExtensionTypeDeclaration(final ExtensionTypeFragment _fragment) {
  int resolveConstructors(SourceLibraryBuilder libraryBuilder) {
    int count = _fragment.constructorReferences.length;
    if (count > 0) {
      for (ConstructorReferenceBuilder ref in _fragment.constructorReferences) {
        ref.resolveIn(_fragment.bodyScope, libraryBuilder);
      }
    }
    return count;
  }

  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required ast.ExtensionTypeDeclaration extensionTypeDeclaration,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: extensionTypeDeclaration,
      annotatableFileUri: extensionTypeDeclaration.fileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
    );

    if (_fragment.typeParameters != null) {
      for (int i = 0; i < _fragment.typeParameters!.length; i++) {
        _fragment.typeParameters![i].builder.buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }
  }
}
