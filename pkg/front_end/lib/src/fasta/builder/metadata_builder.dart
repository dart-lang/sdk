// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.metadata_builder;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart' show Annotatable, Class, Library;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../scope.dart' show Scope;

import 'class_builder.dart';
import 'member_builder.dart';

class MetadataBuilder {
  final Token beginToken;

  int get charOffset => beginToken.charOffset;

  MetadataBuilder(this.beginToken);

  static void buildAnnotations(
      Annotatable parent,
      List<MetadataBuilder> metadata,
      SourceLibraryBuilder library,
      ClassBuilder classBuilder,
      MemberBuilder member) {
    if (metadata == null) return;
    Uri fileUri = member?.fileUri ?? classBuilder?.fileUri ?? library.fileUri;
    Scope scope = parent is Library || parent is Class || classBuilder == null
        ? library.scope
        : classBuilder.scope;
    BodyBuilder bodyBuilder = library.loader
        .createBodyBuilderForOutlineExpression(
            library, classBuilder, member, scope, fileUri);
    for (int i = 0; i < metadata.length; ++i) {
      MetadataBuilder annotationBuilder = metadata[i];
      parent.addAnnotation(
          bodyBuilder.parseAnnotation(annotationBuilder.beginToken));
    }
    bodyBuilder.inferAnnotations(parent, parent.annotations);
    bodyBuilder.resolveRedirectingFactoryTargets();
  }
}
