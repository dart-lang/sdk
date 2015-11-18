// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.invocation;

import 'package:analysis_server/plugin/edit/utilities/change_builder_dart.dart';
import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind, SourceChange;
import 'package:analysis_server/src/protocol_server.dart' as protocol
    hide CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart'
    show DART_RELEVANCE_HIGH;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A completion contributor used to suggest replacing partial identifiers inside
 * a class declaration with templates for inherited members.
 */
class InheritedContributor extends DartCompletionContributor {
  @override
  List<CompletionSuggestion> internalComputeSuggestions(
      DartCompletionRequest request) {
    if (!request.isResolved) {
      return null;
    }
    AstNode node = new NodeLocator(request.offset).searchWithin(request.unit);
    if (node == null || !_isMemberLevelIdentifier(node)) {
      return null;
    }
    ClassDeclaration classDeclaration =
        node.getAncestor((AstNode node) => node is ClassDeclaration);
    if (classDeclaration != null) {
      ClassElement element = classDeclaration.element;
      if (element == null) {
        return null;
      }
      return _suggestInheritedMembers(request, node, element);
    }
    return null;
  }

  /**
   * Return a template for an override of the given [element] in the given
   * [source]. If selected, the template will replace the given [identifier].
   */
  String _buildRepacementText(
      Source source, SimpleIdentifier identifier, Element element) {
    AnalysisContext context = element.context;
    DartChangeBuilder builder = new DartChangeBuilder(context);
    builder.addFileEdit(source, context.getModificationStamp(source),
        (DartFileEditBuilder builder) {
      builder.addReplacement(identifier.offset, identifier.length,
          (DartEditBuilder builder) {
        builder.writeOverrideOfInheritedMember(element);
      });
    });
    return builder.sourceChange.edits[0].edits[0].replacement.trim();
  }

  /**
   * Build a suggestion to replace the partial [identifier] in the given
   * [source] with an override of the given [element].
   */
  CompletionSuggestion _buildSuggestion(
      Source source, SimpleIdentifier identifier, Element element) {
    String completion = _buildRepacementText(source, identifier, element);
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER,
        DART_RELEVANCE_HIGH,
        completion,
        identifier.offset,
        0,
        element.isDeprecated,
        false);
    suggestion.element = protocol.convertElement(element);
    return suggestion;
  }

  /**
   * Return a list containing the names of all of the inherited by not
   * implemented members of the class represented by the given [element] that
   * start with the given [prefix]. The [map] is used to find all of the members
   * that are inherited.
   */
  List<String> _computeMemberNames(
      MemberMap map, ClassElement element, String prefix) {
    List<String> memberNames = <String>[];
    int count = map.size;
    for (int i = 0; i < count; i++) {
      String memberName = map.getKey(i);
      if (memberName.startsWith(prefix) && !_hasMember(element, memberName)) {
        memberNames.add(memberName);
      }
    }
    return memberNames;
  }

  /**
   * Return `true` if the given [classElement] directly declares a member with
   * the given [memberName].
   */
  bool _hasMember(ClassElement classElement, String memberName) {
    return classElement.getField(memberName) != null ||
        classElement.getGetter(memberName) != null ||
        classElement.getMethod(memberName) != null ||
        classElement.getSetter(memberName) != null;
  }

  /**
   * Return `true` if the given [node] looks like a partial identifier inside a
   * class declaration.
   */
  bool _isMemberLevelIdentifier(AstNode node) {
    if (node is SimpleIdentifier) {
      AstNode parent1 = node.parent;
      if (parent1 is TypeName) {
        AstNode parent2 = parent1.parent;
        if (parent2 is VariableDeclarationList) {
          AstNode parent3 = parent2.parent;
          if (parent3 is FieldDeclaration) {
            NodeList<VariableDeclaration> variables = parent2.variables;
            return variables.length == 1 && variables[0].name.name.isEmpty;
          }
        }
      }
    }
    return false;
  }

  /**
   * Add any suggestions that are appropriate to the given [request], using the
   * given [element] to find inherited members whose name has the given
   * [identifier] as a prefix.
   */
  List<CompletionSuggestion> _suggestInheritedMembers(
      DartCompletionRequest request,
      SimpleIdentifier identifier,
      ClassElement element) {
    String name = identifier.name;
    InheritanceManager manager = new InheritanceManager(element.library);
    MemberMap map = manager.getMapOfMembersInheritedFromInterfaces(element);
    List<String> memberNames = _computeMemberNames(map, element, name);
    memberNames.sort();
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (String memberName in memberNames) {
      CompletionSuggestion suggestion =
          _buildSuggestion(request.source, identifier, map.get(memberName));
      if (suggestion != null) {
        suggestions.add(suggestion);
      }
    }
    return suggestions;
  }
}
