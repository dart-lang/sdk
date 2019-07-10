// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/protocol_server.dart' as protocol
    hide CompletionSuggestion, CompletionSuggestionKind;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/**
 * A completion contributor used to suggest replacing partial identifiers inside
 * a class declaration with templates for inherited members.
 */
class OverrideContributor implements DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    SimpleIdentifier targetId = _getTargetId(request.target);
    if (targetId == null) {
      return const <CompletionSuggestion>[];
    }
    var classDecl = targetId.thisOrAncestorOfType<ClassOrMixinDeclaration>();
    if (classDecl == null) {
      return const <CompletionSuggestion>[];
    }

    var inheritance = new InheritanceManager2(request.result.typeSystem);

    // Generate a collection of inherited members
    var classElem = classDecl.declaredElement;
    var interface = inheritance.getInterface(classElem.type);
    var interfaceMap = interface.map;
    var namesToOverride =
        _namesToOverride(classElem.librarySource.uri, interface);

    // Build suggestions
    List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];
    for (Name name in namesToOverride) {
      FunctionType signature = interfaceMap[name];
      // Gracefully degrade if the overridden element has not been resolved.
      if (signature.returnType != null) {
        var invokeSuper = interface.isSuperImplemented(name);
        var suggestion =
            await _buildSuggestion(request, targetId, signature, invokeSuper);
        if (suggestion != null) {
          suggestions.add(suggestion);
        }
      }
    }
    return suggestions;
  }

  /**
   * Build a suggestion to replace [targetId] in the given [request] with an
   * override of the given [signature].
   */
  Future<CompletionSuggestion> _buildSuggestion(
      DartCompletionRequest request,
      SimpleIdentifier targetId,
      FunctionType signature,
      bool invokeSuper) async {
    var displayTextBuffer = new StringBuffer();
    var builder = new DartChangeBuilder(request.result.session);
    await builder.addFileEdit(request.result.path, (builder) {
      builder.addReplacement(range.node(targetId), (builder) {
        builder.writeOverride(
          signature,
          displayTextBuffer: displayTextBuffer,
          invokeSuper: invokeSuper,
        );
      });
    });

    var fileEdits = builder.sourceChange.edits;
    if (fileEdits.length != 1) return null;

    var sourceEdits = fileEdits[0].edits;
    if (sourceEdits.length != 1) return null;

    String replacement = sourceEdits[0].replacement;
    String completion = replacement.trim();
    String overrideAnnotation = '@override';
    if (_hasOverride(request.target.containingNode) &&
        completion.startsWith(overrideAnnotation)) {
      completion = completion.substring(overrideAnnotation.length).trim();
    }
    if (completion.isEmpty) {
      return null;
    }

    SourceRange selectionRange = builder.selectionRange;
    if (selectionRange == null) {
      return null;
    }
    int offsetDelta = targetId.offset + replacement.indexOf(completion);
    String displayText =
        displayTextBuffer.isNotEmpty ? displayTextBuffer.toString() : null;
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.OVERRIDE,
        DART_RELEVANCE_HIGH,
        completion,
        selectionRange.offset - offsetDelta,
        selectionRange.length,
        signature.element.hasDeprecated,
        false,
        displayText: displayText);
    suggestion.element = protocol.convertElement(signature.element);
    return suggestion;
  }

  /**
   * If the target looks like a partial identifier inside a class declaration
   * then return that identifier, otherwise return `null`.
   */
  SimpleIdentifier _getTargetId(CompletionTarget target) {
    AstNode node = target.containingNode;
    if (node is ClassOrMixinDeclaration) {
      Object entity = target.entity;
      if (entity is FieldDeclaration) {
        return _getTargetIdFromVarList(entity.fields);
      }
    } else if (node is FieldDeclaration) {
      Object entity = target.entity;
      if (entity is VariableDeclarationList) {
        return _getTargetIdFromVarList(entity);
      }
    }
    return null;
  }

  SimpleIdentifier _getTargetIdFromVarList(VariableDeclarationList fields) {
    NodeList<VariableDeclaration> variables = fields.variables;
    if (variables.length == 1) {
      VariableDeclaration variable = variables[0];
      SimpleIdentifier targetId = variable.name;
      if (targetId.name.isEmpty) {
        // analyzer parser
        // Actual: class C { foo^ }
        // Parsed: class C { foo^ _s_ }
        //   where _s_ is a synthetic id inserted by the analyzer parser
        return targetId;
      } else if (fields.keyword == null &&
          fields.type == null &&
          variable.initializer == null) {
        // fasta parser does not insert a synthetic identifier
        return targetId;
      }
    }
    return null;
  }

  /**
   * Return `true` if the given [node] has an `override` annotation.
   */
  bool _hasOverride(AstNode node) {
    if (node is AnnotatedNode) {
      NodeList<Annotation> metadata = node.metadata;
      for (Annotation annotation in metadata) {
        if (annotation.name.name == 'override' &&
            annotation.arguments == null) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Return the list of names that belong to the [interface] of a class, but
   * are not yet declared in the class.
   */
  List<Name> _namesToOverride(Uri libraryUri, Interface interface) {
    var namesToOverride = <Name>[];
    for (var name in interface.map.keys) {
      if (name.isAccessibleFor(libraryUri)) {
        if (!interface.declared.containsKey(name)) {
          namesToOverride.add(name);
        }
      }
    }
    return namesToOverride;
  }
}
