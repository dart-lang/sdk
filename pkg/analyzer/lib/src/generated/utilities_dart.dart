// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart' show AnnotatedNode, Comment;
import 'package:analyzer/dart/ast/token.dart' show Token;
import 'package:analyzer/src/dart/element/element.dart' show ElementImpl;

export 'package:front_end/src/base/resolve_relative_uri.dart'
    show resolveRelativeUri;

/**
 * If the given [node] has a documentation comment, remember its content
 * and range into the given [element].
 */
void setElementDocumentationComment(ElementImpl element, AnnotatedNode node) {
  Comment comment = node.documentationComment;
  if (comment != null && comment.isDocumentation) {
    element.documentationComment =
        comment.tokens.map((Token t) => t.lexeme).join('\n');
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
 * The kind of a parameter. A parameter can be either positional or named, and
 * can be either required or optional. 
 */
class ParameterKind implements Comparable<ParameterKind> {
  /// A positional required parameter.
  static const ParameterKind REQUIRED =
      const ParameterKind('REQUIRED', 0, false, false);

  /// A positional optional parameter.
  static const ParameterKind POSITIONAL =
      const ParameterKind('POSITIONAL', 1, false, true);

  /// A named required parameter.
  static const ParameterKind NAMED_REQUIRED =
      const ParameterKind('NAMED_REQUIRED', 2, true, false);

  /// A named optional parameter.
  static const ParameterKind NAMED =
      const ParameterKind('NAMED', 2, true, true);

  static const List<ParameterKind> values = const [
    REQUIRED,
    POSITIONAL,
    NAMED_REQUIRED,
    NAMED
  ];

  /**
   * The name of this parameter.
   */
  final String name;

  /**
   * The ordinal value of the parameter.
   */
  final int ordinal;

  /**
   * A flag indicating whether this is a named or positional parameter.
   */
  final bool isNamed;

  /**
   * A flag indicating whether this is an optional or required parameter.
   */
  final bool isOptional;

  /**
   * Initialize a newly created kind with the given state.
   */
  const ParameterKind(this.name, this.ordinal, this.isNamed, this.isOptional);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(ParameterKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}
