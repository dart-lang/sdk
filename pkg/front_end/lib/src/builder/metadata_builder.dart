// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';

import '../base/loader.dart';
import '../base/scope.dart' show LookupScope;
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/body_builder_context.dart';
import '../kernel/macro/metadata.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;

bool computeSharedExpressionForTesting = false;
bool delaySharedExpressionLookupForTesting = false;

class MetadataBuilder {
  /// Token for `@` for annotations that have not yet been parsed.
  Token? _atToken;

  final int atOffset;

  /// `true` if the annotation begins with 'patch'.
  ///
  /// This is used for detecting `@patch` annotations in patch libraries where
  /// it can be assumed that it implies that it _is_ a `@patch` annotation.
  final bool hasPatch;

  /// Expression for an already parsed annotation.
  Expression? _expression;

  final Uri fileUri;

  MetadataBuilder(Token this._atToken, this.fileUri)
    : atOffset = _atToken.charOffset,
      hasPatch = _atToken.next?.lexeme == 'patch';

  // Coverage-ignore(suite): Not run.
  Token? get beginToken => _atToken;

  shared.Expression? _sharedExpression;

  shared.Expression? _unresolvedSharedExpressionForTesting;

  // Coverage-ignore(suite): Not run.
  shared.Expression? get expression => _sharedExpression;

  // Coverage-ignore(suite): Not run.
  shared.Expression? get unresolvedExpressionForTesting =>
      _unresolvedSharedExpressionForTesting;

  static void buildAnnotations({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required List<MetadataBuilder>? metadata,
    required BodyBuilderContext bodyBuilderContext,
    required SourceLibraryBuilder libraryBuilder,
    required LookupScope scope,
  }) {
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

    List<int> indicesOfAnnotationsToBeInferred = [];
    for (int i = 0; i < metadata.length; ++i) {
      MetadataBuilder annotationBuilder = metadata[i];
      bool createFileUriExpression =
          annotatableFileUri != annotationBuilder.fileUri;
      Token? beginToken = annotationBuilder._atToken;
      if (beginToken != null) {
        if (computeSharedExpressionForTesting) {
          // Coverage-ignore-block(suite): Not run.
          annotationBuilder._sharedExpression = _parseSharedExpression(
            libraryBuilder.loader,
            beginToken,
            libraryBuilder.importUri,
            annotationBuilder.fileUri,
            scope,
          );
          if (delaySharedExpressionLookupForTesting) {
            annotationBuilder._unresolvedSharedExpressionForTesting =
                _parseSharedExpression(
                  libraryBuilder.loader,
                  beginToken,
                  libraryBuilder.importUri,
                  annotationBuilder.fileUri,
                  scope,
                  delayLookupForTesting: true,
                );
          }
        }

        bodyBuilder ??= libraryBuilder.loader
            .createBodyBuilderForOutlineExpression(
              libraryBuilder,
              bodyBuilderContext,
              scope,
              annotationBuilder.fileUri,
            );
        Expression annotation = bodyBuilder.parseAnnotation(beginToken);
        annotationBuilder._atToken = null;
        if (createFileUriExpression) {
          annotation = new FileUriExpression(
            annotation,
            annotationBuilder.fileUri,
          )..fileOffset = annotationBuilder.atOffset;
        }
        // Record the index of [annotation] in `parent.annotations`.
        int annotationIndex = annotatable.annotations.length;
        parsedAnnotationBuilders[annotationBuilder] = annotationIndex;
        indicesOfAnnotationsToBeInferred.add(annotationIndex);
        // It is important for the inference and backlog computations that the
        // annotation is already a child of [parent].
        annotatable.addAnnotation(annotation);
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
        Expression annotation = cloner.cloneInContext(
          annotationBuilder._expression!,
        );
        // Coverage-ignore(suite): Not run.
        if (createFileUriExpression && annotation is! FileUriExpression) {
          annotation = new FileUriExpression(
            annotation,
            annotationBuilder.fileUri,
          )..fileOffset = annotationBuilder.atOffset;
        }
        annotatable.addAnnotation(annotation);
      }
    }
    if (bodyBuilder != null) {
      bodyBuilder.inferAnnotations(
        annotatable,
        annotatable.annotations,
        indices: indicesOfAnnotationsToBeInferred,
      );
      bodyBuilder.performBacklogComputations();
      for (MapEntry<MetadataBuilder, int> entry
          in parsedAnnotationBuilders.entries) {
        MetadataBuilder annotationBuilder = entry.key;
        int index = entry.value;
        annotationBuilder._expression = annotatable.annotations[index];
      }
    }
  }
}

// Coverage-ignore(suite): Not run.
shared.Expression _parseSharedExpression(
  Loader loader,
  Token atToken,
  Uri importUri,
  Uri fileUri,
  LookupScope scope, {
  bool delayLookupForTesting = false,
}) {
  return parseAnnotation(
    loader,
    atToken,
    importUri,
    fileUri,
    scope,
    delayLookupForTesting: delayLookupForTesting,
  );
}
