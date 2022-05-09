// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/utilities/extensions/completion_request.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// A contributor that produces suggestions based on the static members of a
/// given class, enum, or extension. More concretely, this class produces
/// suggestions for expressions of the form `C.^`, where `C` is the name of a
/// class, enum, or extension.
class StaticMemberContributor extends DartCompletionContributor {
  StaticMemberContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    var library = request.libraryElement;
    bool isVisible(Element element) => element.isAccessibleIn(library);
    var targetId = request.target.dotTarget;
    if (targetId is Identifier && !request.target.isCascade) {
      var element = targetId.staticElement;
      if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        element = aliasedType.element;
      }
      if (element is ClassElement) {
        for (var accessor in element.accessors) {
          if (accessor.isStatic &&
              !accessor.isSynthetic &&
              isVisible(accessor)) {
            builder.suggestAccessor(accessor, inheritanceDistance: 0.0);
          }
        }
        if (!request.shouldSuggestTearOff(element)) {
          for (var constructor in element.constructors) {
            if (isVisible(constructor)) {
              if (!element.isAbstract || constructor.isFactory) {
                builder.suggestConstructor(constructor, hasClassName: true);
              }
            }
          }
        }
        for (var field in element.fields) {
          if (field.isStatic &&
              (!field.isSynthetic || element.isEnum) &&
              isVisible(field)) {
            builder.suggestField(field, inheritanceDistance: 0.0);
          }
        }
        for (var method in element.methods) {
          if (method.isStatic && isVisible(method)) {
            builder.suggestMethod(
              method,
              kind: protocol.CompletionSuggestionKind.INVOCATION,
              inheritanceDistance: 0.0,
            );
          }
        }
      } else if (element is ExtensionElement) {
        for (var accessor in element.accessors) {
          if (accessor.isStatic &&
              !accessor.isSynthetic &&
              isVisible(accessor)) {
            builder.suggestAccessor(accessor, inheritanceDistance: 0.0);
          }
        }
        for (var field in element.fields) {
          if (field.isStatic && !field.isSynthetic && isVisible(field)) {
            builder.suggestField(field, inheritanceDistance: 0.0);
          }
        }
        for (var method in element.methods) {
          if (method.isStatic && isVisible(method)) {
            builder.suggestMethod(
              method,
              kind: protocol.CompletionSuggestionKind.INVOCATION,
              inheritanceDistance: 0.0,
            );
          }
        }
      }
    }
  }
}
