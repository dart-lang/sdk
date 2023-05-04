// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.metadata_builder;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';

import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/body_builder_context.dart';
import '../scope.dart' show Scope;
import '../source/source_library_builder.dart' show SourceLibraryBuilder;

class MetadataBuilder {
  final Token beginToken;

  int get charOffset => beginToken.charOffset;

  MetadataBuilder(this.beginToken);

  static void buildAnnotations(
      Annotatable parent,
      List<MetadataBuilder>? metadata,
      BodyBuilderContext bodyBuilderContext,
      SourceLibraryBuilder library,
      Uri fileUri,
      Scope scope) {
    if (metadata == null) return;
    BodyBuilder bodyBuilder = library.loader
        .createBodyBuilderForOutlineExpression(
            library, bodyBuilderContext, scope, fileUri);
    for (int i = 0; i < metadata.length; ++i) {
      MetadataBuilder annotationBuilder = metadata[i];
      parent.addAnnotation(
          bodyBuilder.parseAnnotation(annotationBuilder.beginToken));
    }
    bodyBuilder.inferAnnotations(parent, parent.annotations);
    bodyBuilder.performBacklogComputations(allowFurtherDelays: false);
  }
}
