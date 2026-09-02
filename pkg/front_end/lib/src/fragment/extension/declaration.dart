// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../../builder/metadata_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../source/source_library_builder.dart';
import '../fragment.dart';

class ExtensionDeclaration(final ExtensionFragment _fragment) {
  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required Extension extension,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: extension,
      annotatableFileUri: extension.fileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
    );
  }
}
