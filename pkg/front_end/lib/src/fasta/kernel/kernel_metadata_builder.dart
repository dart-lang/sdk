// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_metadata_builder;

import 'package:kernel/ast.dart' show Annotatable, Class, Library;

import 'body_builder.dart' show BodyBuilder;

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelLibraryBuilder,
        MetadataBuilder,
        MemberBuilder;

import '../scanner.dart' show Token;

import '../scope.dart' show Scope;

class KernelMetadataBuilder extends MetadataBuilder {
  final Token beginToken;

  int get charOffset => beginToken.charOffset;

  KernelMetadataBuilder(this.beginToken);

  static void buildAnnotations(
      Annotatable parent,
      List<MetadataBuilder> metadata,
      KernelLibraryBuilder library,
      KernelClassBuilder classBuilder,
      MemberBuilder member) {
    if (metadata == null) return;
    Uri fileUri = member?.fileUri ?? classBuilder?.fileUri ?? library.fileUri;
    Scope scope = parent is Library || parent is Class || classBuilder == null
        ? library.scope
        : classBuilder.scope;
    BodyBuilder bodyBuilder = new BodyBuilder.forOutlineExpression(
        library, classBuilder, member, scope, fileUri);
    for (int i = 0; i < metadata.length; ++i) {
      KernelMetadataBuilder annotationBuilder = metadata[i];
      parent.addAnnotation(
          bodyBuilder.parseAnnotation(annotationBuilder.beginToken));
    }
    bodyBuilder.inferAnnotations(parent.annotations);
    bodyBuilder.resolveRedirectingFactoryTargets();
  }
}
