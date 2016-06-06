// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.utilities_dart;

import 'package:analyzer/dart/ast/ast.dart' show AnnotatedNode, Comment;
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/src/dart/element/element.dart' show ElementImpl;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/fast_uri.dart';

/**
 * Resolve the [containedUri] against [baseUri] using Dart rules.
 *
 * This function behaves similarly to [Uri.resolveUri], except that it properly
 * handles situations like the following:
 *
 *     resolveRelativeUri(dart:core, bool.dart) -> dart:core/bool.dart
 *     resolveRelativeUri(package:a/b.dart, ../c.dart) -> package:a/c.dart
 */
Uri resolveRelativeUri(Uri baseUri, Uri containedUri) {
  if (containedUri.isAbsolute) {
    return containedUri;
  }
  Uri origBaseUri = baseUri;
  try {
    bool isOpaque = baseUri.isAbsolute && !baseUri.path.startsWith('/');
    if (isOpaque) {
      String scheme = baseUri.scheme;
      String part = baseUri.path;
      if (scheme == DartUriResolver.DART_SCHEME && part.indexOf('/') < 0) {
        part = "$part/$part.dart";
      }
      baseUri = FastUri.parse("$scheme:/$part");
    }
    Uri result = baseUri.resolveUri(containedUri);
    if (isOpaque) {
      result =
          FastUri.parse("${result.scheme}:${result.path.substring(1)}");
    }
    return result;
  } catch (exception, stackTrace) {
    throw new AnalysisException(
        "Could not resolve URI ($containedUri) relative to source ($origBaseUri)",
        new CaughtException(exception, stackTrace));
  }
}

/**
 * If the given [node] has a documentation comment, remember its content
 * and range into the given [element].
 */
void setElementDocumentationComment(ElementImpl element, AnnotatedNode node) {
  Comment comment = node.documentationComment;
  if (comment != null && comment.isDocumentation) {
    element.documentationComment =
        comment.tokens.map((Token t) => t.lexeme).join('\n');
    element.setDocRange(comment.offset, comment.length);
  }
}

/**
 * Check whether [uri1] starts with (or 'is prefixed by') [uri2] by checking
 * path segments.
 */
bool startsWith(Uri uri1, Uri uri2) {
  List<String> uri1Segments = uri1.pathSegments;
  List<String> uri2Segments = uri2.pathSegments.toList();
  // Punt if empty (https://github.com/dart-lang/sdk/issues/24126)
  if (uri2Segments.isEmpty) {
    return false;
  }
  // Trim trailing empty segments ('/foo/' => ['foo', ''])
  if (uri2Segments.last == '') {
    uri2Segments.removeLast();
  }

  if (uri2Segments.length > uri1Segments.length) {
    return false;
  }

  for (int i = 0; i < uri2Segments.length; ++i) {
    if (uri2Segments[i] != uri1Segments[i]) {
      return false;
    }
  }
  return true;
}

/**
 * The enumeration `ParameterKind` defines the different kinds of parameters. There are two
 * basic kinds of parameters: required and optional. Optional parameters are further divided into
 * two kinds: positional optional and named optional.
 */
class ParameterKind extends Enum<ParameterKind> {
  static const ParameterKind REQUIRED =
      const ParameterKind('REQUIRED', 0, false);

  static const ParameterKind POSITIONAL =
      const ParameterKind('POSITIONAL', 1, true);

  static const ParameterKind NAMED = const ParameterKind('NAMED', 2, true);

  static const List<ParameterKind> values = const [REQUIRED, POSITIONAL, NAMED];

  /**
   * A flag indicating whether this is an optional parameter.
   */
  final bool isOptional;

  /**
   * Initialize a newly created kind with the given state.
   *
   * @param isOptional `true` if this is an optional parameter
   */
  const ParameterKind(String name, int ordinal, this.isOptional)
      : super(name, ordinal);
}
