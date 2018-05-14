// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution_strategy;

import 'package:front_end/src/fasta/scanner.dart' show Token;

import '../common.dart';
import '../common/resolution.dart';
import '../common/work.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../enqueue.dart';
import '../js_backend/mirrors_data.dart';
import '../tree/tree.dart' show Node;

class ComputeSpannableMixin {
  SourceSpan spanFromToken(Element currentElement, Token token) =>
      _spanFromTokens(currentElement, token, token);

  SourceSpan _spanFromTokens(Element currentElement, Token begin, Token end,
      [Uri uri]) {
    if (begin == null || end == null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'Cannot find tokens to produce error message.';
    }
    if (uri == null && currentElement != null) {
      if (currentElement is! Element) {
        throw 'Can only find tokens from an Element.';
      }
      Element element = currentElement;
      uri = element.compilationUnit.script.resourceUri;
      String message;
      assert(() {
        bool sameToken(Token token, Token sought) {
          if (token == sought) return true;
          if (token.stringValue == '[') {
            // `[` is converted to `[]` in the parser when needed.
            return sought.stringValue == '[]' &&
                token.charOffset <= sought.charOffset &&
                sought.charOffset < token.charEnd;
          }
          if (token.stringValue == '>>') {
            // `>>` is converted to `>` in the parser when needed.
            return sought.stringValue == '>' &&
                token.charOffset <= sought.charOffset &&
                sought.charOffset < token.charEnd;
          }
          return false;
        }

        /// Check that [begin] and [end] can be found between [from] and [to].
        validateToken(Token from, Token to) {
          if (from == null || to == null) return true;
          bool foundBegin = false;
          bool foundEnd = false;
          Token token = from;
          while (true) {
            if (sameToken(token, begin)) {
              foundBegin = true;
            }
            if (sameToken(token, end)) {
              foundEnd = true;
            }
            if (foundBegin && foundEnd) {
              return true;
            }
            if (token == to || token == token.next || token.next == null) {
              break;
            }
            token = token.next;
          }

          // Create a good message for when the tokens were not found.
          StringBuffer sb = new StringBuffer();
          sb.write('Invalid current element: $element. ');
          sb.write('Looking for ');
          sb.write('[${begin} (${begin.hashCode}),');
          sb.write('${end} (${end.hashCode})] in');

          token = from;
          while (true) {
            sb.write('\n ${token} (${token.hashCode})');
            if (token == to || token == token.next || token.next == null) {
              break;
            }
            token = token.next;
          }
          message = sb.toString();
          return false;
        }

        if (element.enclosingClass != null &&
            element.enclosingClass.isEnumClass) {
          // Enums ASTs are synthesized (and give messed up messages).
          return true;
        }

        if (element is AstElement) {
          AstElement astElement = element;
          if (astElement.hasNode) {
            Token from = astElement.node.getBeginToken();
            Token to = astElement.node.getEndToken();
            if (astElement.metadata.isNotEmpty) {
              if (!astElement.metadata.first.hasNode) {
                // We might try to report an error while parsing the metadata
                // itself.
                return true;
              }
              from = astElement.metadata.first.node.getBeginToken();
            }
            return validateToken(from, to);
          }
        }
        return true;
      }(), failedAt(currentElement, message));
    }
    return new SourceSpan.fromTokens(uri, begin, end);
  }

  SourceSpan _spanFromNode(Element currentElement, Node node) {
    return _spanFromTokens(
        currentElement, node.getBeginToken(), node.getPrefixEndToken());
  }

  SourceSpan _spanFromElement(Element currentElement, Element element) {
    if (element != null && element.sourcePosition != null) {
      return element.sourcePosition;
    }
    while (element != null && element.isSynthesized) {
      element = element.enclosingElement;
    }
    if (element != null &&
        element.sourcePosition == null &&
        !element.isLibrary &&
        !element.isCompilationUnit) {
      // Sometimes, the backend fakes up elements that have no
      // position. So we use the enclosing element instead. It is
      // not a good error location, but cancel really is "internal
      // error" or "not implemented yet", so the vicinity is good
      // enough for now.
      element = element.enclosingElement;
      // TODO(ahe): I plan to overhaul this infrastructure anyways.
    }
    if (element == null) {
      element = currentElement;
    }
    if (element == null) {
      return null;
    }

    if (element.sourcePosition != null) {
      return element.sourcePosition;
    }
    Token position = element.position;
    Uri uri = element.compilationUnit.script.resourceUri;
    return (position == null)
        ? new SourceSpan(uri, 0, 0)
        : _spanFromTokens(currentElement, position, position, uri);
  }

  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement) {
    if (spannable is Node) {
      return _spanFromNode(currentElement, spannable);
    } else if (spannable is Element) {
      return _spanFromElement(currentElement, spannable);
    } else if (spannable is MetadataAnnotation) {
      return spannable.sourcePosition;
    } else if (spannable is LocalVariable) {
      return spanFromSpannable(spannable.executableContext, currentElement);
    }
    return null;
  }
}

/// Builder that creates work item necessary for the resolution of a
/// [MemberElement].
class ResolutionWorkItemBuilder extends WorkItemBuilder {
  final Resolution _resolution;

  ResolutionWorkItemBuilder(this._resolution);

  @override
  WorkItem createWorkItem(MemberElement element) {
    assert(element.isDeclaration, failedAt(element));
    if (element.isMalformed) return null;

    assert(element is AnalyzableElement,
        failedAt(element, 'Element $element is not analyzable.'));
    return _resolution.createWorkItem(element);
  }
}

class ResolutionMirrorsData extends MirrorsDataImpl {
  ResolutionMirrorsData(Compiler compiler,
      ElementEnvironment elementEnvironment, CommonElements commonElements)
      : super(compiler, elementEnvironment, commonElements);

  @override
  bool isClassInjected(covariant ClassElement cls) => cls.isInjected;

  @override
  bool isClassResolved(covariant ClassElement cls) => cls.isResolved;

  @override
  void forEachConstructor(
      covariant ClassElement cls, void f(ConstructorEntity constructor)) {
    cls.constructors.forEach((Element _constructor) {
      ConstructorElement constructor = _constructor;
      f(constructor);
    });
  }
}
