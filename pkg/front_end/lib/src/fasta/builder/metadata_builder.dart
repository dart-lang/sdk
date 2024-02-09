// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.metadata_builder;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';

import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/body_builder_context.dart';
import '../scope.dart' show Scope;
import '../source/source_library_builder.dart' show SourceLibraryBuilder;

class MetadataBuilder {
  /// Token for `@` for annotations that have not yet been parsed.
  Token? _beginToken;

  final int charOffset;

  /// `true` if the annotation begins with 'patch'.
  ///
  /// This is used for detecting `@patch` annotations in patch libraries where
  /// it can be assumed that it implies that it _is_ a `@patch` annotation.
  final bool hasPatch;

  /// Expression for an already parsed annotation.
  Expression? _expression;

  MetadataBuilder(Token this._beginToken)
      : charOffset = _beginToken.charOffset,
        hasPatch = _beginToken.next?.lexeme == 'patch';

  Token? get beginToken => _beginToken;

  static void buildAnnotations(
      Annotatable parent,
      List<MetadataBuilder>? metadata,
      BodyBuilderContext bodyBuilderContext,
      SourceLibraryBuilder library,
      Uri fileUri,
      Scope scope,
      {bool createFileUriExpression = false}) {
    if (metadata == null) return;

    // [BodyBuilder] used to build annotations from [Token]s.
    BodyBuilder? bodyBuilder;
    // Cloner used to clone already parsed annotations.
    CloneVisitorNotMembers? cloner;

    // Map from annotation builder of parsed annotations to the index of the
    // corresponding annotation in `parent.annotations`.
    //
    // This is used to read the fully inferred annotation from [parent] and
    // store it in `_expression` of the corresponding [MetadataBuilder].
    Map<MetadataBuilder, int> parsedAnnotationBuilders = {};

    for (int i = 0; i < metadata.length; ++i) {
      MetadataBuilder annotationBuilder = metadata[i];
      Token? beginToken = annotationBuilder._beginToken;
      if (beginToken != null) {
        bodyBuilder ??= library.loader.createBodyBuilderForOutlineExpression(
            library, bodyBuilderContext, scope, fileUri);
        Expression annotation = bodyBuilder.parseAnnotation(beginToken);
        annotationBuilder._beginToken = null;
        if (createFileUriExpression) {
          annotation = new FileUriExpression(annotation, fileUri)
            ..fileOffset = annotationBuilder.charOffset;
        }
        // Record the index of [annotation] in `parent.annotations`.
        parsedAnnotationBuilders[annotationBuilder] = parent.annotations.length;
        // It is important for the inference and backlog computations that the
        // annotation is already a child of [parent].
        parent.addAnnotation(annotation);
      } else {
        // The annotation is needed for multiple declarations so we need to
        // clone the expression to use it more than once. For instance
        //
        //     abstract class Class {
        //       @annotation
        //       abstract int field;
        //     }
        //
        // will be compiled to
        //
        //     abstract class Class {
        //       @annotation
        //       int get field;
        //       @annotation
        //       void set field(int value);
        //     }
        //
        cloner ??= new CloneVisitorNotMembers();
        Expression annotation =
            cloner.cloneInContext(annotationBuilder._expression!);
        if (createFileUriExpression && annotation is! FileUriExpression) {
          annotation = new FileUriExpression(annotation, fileUri)
            ..fileOffset = annotationBuilder.charOffset;
        }
        parent.addAnnotation(annotation);
      }
    }
    if (bodyBuilder != null) {
      // TODO(johnniwinther): Avoid potentially inferring annotations multiple
      // times.
      bodyBuilder.inferAnnotations(parent, parent.annotations);
      bodyBuilder.performBacklogComputations(allowFurtherDelays: false);
      for (MapEntry<MetadataBuilder, int> entry
          in parsedAnnotationBuilders.entries) {
        MetadataBuilder annotationBuilder = entry.key;
        int index = entry.value;
        annotationBuilder._expression = parent.annotations[index];
      }
    }
  }
}
