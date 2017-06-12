// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:front_end/src/base/source.dart' show Source;

/**
 * An object used to build code completion suggestions for Dart code.
 */
abstract class SuggestionBuilder {
  /**
   * Return a suggestion based on the given [element], or `null` if a suggestion
   * is not appropriate for the given element. If the suggestion is not
   * currently in scope, then specify [importForSource] as the source to which
   * an import should be added.
   */
  CompletionSuggestion forElement(Element element,
      {String completion,
      CompletionSuggestionKind kind: CompletionSuggestionKind.INVOCATION,
      int relevance: DART_RELEVANCE_DEFAULT,
      Source importForSource});
}
