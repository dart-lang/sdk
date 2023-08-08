// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    show HoverInformation;
import 'package:analysis_server/src/computer/computer_overrides.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:path/path.dart' as path;

/// Information about a library to display in a hover.
typedef _LibraryInfo = ({String? libraryName, String? libraryPath})?;
typedef _OffsetLength = ({int offset, int length});

/// A computer for the hover at the specified offset of a Dart
/// [CompilationUnit].
class DartUnitHoverComputer {
  final DartdocDirectiveInfo _dartdocInfo;
  final CompilationUnit _unit;
  final int _offset;
  final DocumentationPreference documentationPreference;

  DartUnitHoverComputer(
    this._dartdocInfo,
    this._unit,
    this._offset, {
    this.documentationPreference = DocumentationPreference.full,
  });

  /// Returns the computed hover, maybe `null`.
  HoverInformation? compute() {
    var node = NodeLocator(_offset).searchWithin(_unit);
    if (node == null) {
      return null;
    }

    var locationEntity = _locationEntity(node);
    node = _targetNode(node);
    if (node == null || locationEntity == null) {
      return null;
    }

    if (node is CompilationUnitMember ||
        node is Expression ||
        node is FormalParameter ||
        node is MethodDeclaration ||
        node is NamedType ||
        node is ConstructorDeclaration ||
        node is DeclaredIdentifier ||
        node is VariableDeclaration ||
        node is VariablePattern ||
        node is PatternFieldName ||
        node is DartPattern) {
      var range = _hoverRange(node, locationEntity);
      var hover = HoverInformation(range.offset, range.length);
      // element
      var element = ElementLocator.locate(node);
      if (element != null) {
        // variable, if synthetic accessor
        if (element is PropertyAccessorElement) {
          element = element.nonSynthetic;
        }
        // description
        hover.elementDescription = _elementDisplayString(node, element);
        hover.elementKind = element.kind.displayName;
        hover.isDeprecated = element.hasDeprecated;
        // not local element
        if (element.enclosingElement is! ExecutableElement) {
          // containing class
          hover.containingClassDescription = _containingClass(element);
          // containing library
          var libraryInfo = _libraryInfo(element);
          hover.containingLibraryName = libraryInfo?.libraryName;
          hover.containingLibraryPath = libraryInfo?.libraryPath;
        }
        // documentation
        hover.dartdoc = computePreferredDocumentation(
            _dartdocInfo, element, documentationPreference);
      }
      // parameter
      hover.parameter = _parameterDisplayString(node);
      // types
      hover.staticType = _typeDisplayString(node, element);
      // done
      return hover;
    }
    // not an expression
    return null;
  }

  /// Gets the name of the containing class of [element].
  String? _containingClass(Element element) {
    var containingClass = element.thisOrAncestorOfType<InterfaceElement>();
    return containingClass != null && containingClass != element
        ? containingClass.displayName
        : null;
  }

  /// Gets the display string for [element].
  ///
  /// This is usually `element.getDisplayString()` but may contain additional
  /// information to disambiguate things like constructors from types (and
  /// whether they are const).
  String? _elementDisplayString(AstNode node, Element? element) {
    var displayString = element?.getDisplayString(
      withNullability: _unit.isNonNullableByDefault,
      multiline: true,
    );

    if (displayString != null &&
        node is InstanceCreationExpression &&
        node.keyword == null) {
      var prefix = node.isConst ? '(const) ' : '(new) ';
      displayString = prefix + displayString;
    }

    return displayString;
  }

  /// Computes the range this hover applies to.
  ///
  /// This is usually the range of [entity] but may be adjusted for entities
  /// like constructor names.
  _OffsetLength _hoverRange(AstNode node, SyntacticEntity entity) {
    // For constructors, the location should cover the type name and
    // constructor name (for both calls and declarations).
    if (node is InstanceCreationExpression) {
      return (
        offset: node.constructorName.offset,
        length: node.constructorName.length,
      );
    } else if (node is ConstructorDeclaration) {
      var offset = node.returnType.offset;
      var end = node.name?.end ?? node.returnType.end;
      var length = end - node.returnType.offset;
      return (offset: offset, length: length);
    } else {
      return (offset: entity.offset, length: entity.length);
    }
  }

  /// Returns information about the library that contains [element].
  _LibraryInfo _libraryInfo(Element element) {
    var library = element.library;
    if (library == null) {
      return null;
    }

    var uri = library.source.uri;
    var analysisSession = _unit.declaredElement?.session;

    String? libraryName, libraryPath;
    if (uri.isScheme('file') && analysisSession != null) {
      // for 'file:' URIs, use the path after the project root
      var context = analysisSession.resourceProvider.pathContext;
      var projectRootDir =
          analysisSession.analysisContext.contextRoot.root.path;
      var relativePath =
          context.relative(context.fromUri(uri), from: projectRootDir);
      if (context.style == path.Style.windows) {
        var pathList = context.split(relativePath);
        libraryName = pathList.join('/');
      } else {
        libraryName = relativePath;
      }
    } else {
      libraryName = uri.toString();
    }
    libraryPath = library.source.fullName;

    return (libraryName: libraryName, libraryPath: libraryPath);
  }

  /// Returns the [SyntacticEntity] that should be used as the range for this
  /// hover.
  ///
  /// Returns `null` if there is no valid entity for this hover.
  SyntacticEntity? _locationEntity(AstNode node) {
    return switch (node) {
      NamedCompilationUnitMember() => node.name,
      Expression() => node,
      ExtensionDeclaration() => node.name,
      FormalParameter() => node.name,
      MethodDeclaration() => node.name,
      NamedType() => node.name2,
      ConstructorDeclaration() => node.name ?? node.returnType,
      DeclaredIdentifier() => node.name,
      VariableDeclaration() => node.name,
      VariablePattern() => node.name,
      PatternFieldName() => node.name,
      WildcardPattern() => node.name,
      _ => null,
    };
  }

  /// Gets the display string for the type of the parameter.
  ///
  /// Returns `null` if the parameter is not an expression.
  String? _parameterDisplayString(AstNode node) {
    if (node is Expression) {
      return _elementDisplayString(
        node,
        node.staticParameterElement,
      );
    }
    return null;
  }

  /// Adjusts the target node for constructors.
  AstNode? _targetNode(AstNode node) {
    var parent = node.parent;
    var grandParent = parent?.parent;
    if (parent is NamedType &&
        grandParent is ConstructorName &&
        grandParent.parent is InstanceCreationExpression) {
      return grandParent.parent;
    } else if (parent is ConstructorName &&
        grandParent is InstanceCreationExpression) {
      return grandParent;
    } else if (node is SimpleIdentifier &&
        parent is ConstructorDeclaration &&
        parent.name != null) {
      return parent;
    }
    return node;
  }

  /// Returns information abtout the static type of [node].
  String? _typeDisplayString(AstNode node, Element? element) {
    var parent = node.parent;
    DartType? staticType;
    if (node is Expression && (element == null || element is VariableElement)) {
      staticType = _getTypeOfDeclarationOrReference(node);
    } else if (element is VariableElement) {
      staticType = element.type;
    } else if (parent is MethodInvocation && parent.methodName == node) {
      staticType = parent.staticInvokeType;
      if (staticType != null && staticType is DynamicType) {
        staticType = null;
      }
    } else if (node is PatternFieldName && parent is PatternField) {
      staticType = parent.pattern.matchedValueType;
    } else if (node is DartPattern) {
      staticType = node.matchedValueType;
    }
    return staticType?.getDisplayString(
        withNullability: _unit.isNonNullableByDefault);
  }

  static Documentation? computeDocumentation(
      DartdocDirectiveInfo dartdocInfo, Element elementBeingDocumented,
      {bool includeSummary = false}) {
    // TODO(dantup) We're reusing this in parameter information - move it
    // somewhere shared?
    Element? element = elementBeingDocumented;
    if (element is FieldFormalParameterElement) {
      element = element.field;
    }
    if (element is ParameterElement) {
      element = element.enclosingElement;
    }
    if (element == null) {
      // This can happen when the code is invalid, such as having a field formal
      // parameter for a field that does not exist.
      return null;
    }

    Element? documentedElement;
    Element? documentedGetter;

    // Look for documentation comments of overridden members
    var overridden = findOverriddenElements(element);
    for (var candidate in [
      element,
      ...overridden.superElements,
      ...overridden.interfaceElements
    ]) {
      if (candidate.documentationComment != null) {
        documentedElement = candidate;
        break;
      }
      if (documentedGetter == null &&
          candidate is PropertyAccessorElement &&
          candidate.isSetter) {
        var getter = candidate.correspondingGetter;
        if (getter != null && getter.documentationComment != null) {
          documentedGetter = getter;
        }
      }
    }

    // Use documentation of a corresponding getter if setters don't have it
    documentedElement ??= documentedGetter;
    if (documentedElement == null) {
      return null;
    }

    var rawDoc = documentedElement.documentationComment;
    if (rawDoc == null) {
      return null;
    }
    var result =
        dartdocInfo.processDartdoc(rawDoc, includeSummary: includeSummary);

    var documentedElementClass = documentedElement.enclosingElement;
    if (documentedElementClass != null &&
        documentedElementClass != element.enclosingElement) {
      var documentedClass = documentedElementClass.displayName;
      result.full = '${result.full}\n\nCopied from `$documentedClass`.';
    }

    return result;
  }

  /// Compute documentation for [element] and return either the summary or full
  /// docs (or `null`) depending on `preference`.
  static String? computePreferredDocumentation(
    DartdocDirectiveInfo dartdocInfo,
    Element element,
    DocumentationPreference preference,
  ) {
    if (preference == DocumentationPreference.none) {
      return null;
    }

    final doc = computeDocumentation(
      dartdocInfo,
      element,
      includeSummary: preference == DocumentationPreference.summary,
    );

    return doc is DocumentationWithSummary ? doc.summary : doc?.full;
  }

  static DartType? _getTypeOfDeclarationOrReference(Expression node) {
    if (node is SimpleIdentifier) {
      var element = node.staticElement;
      if (element is VariableElement) {
        if (node.inDeclarationContext()) {
          return element.type;
        }
        var parent2 = node.parent?.parent;
        if (parent2 is NamedExpression && parent2.name.label == node) {
          return element.type;
        }
      }
    }
    return node.staticType;
  }
}

/// The type of documentation the user prefers to see in hovers and other
/// related displays in their editor.
enum DocumentationPreference {
  none,
  summary,
  full,
}
