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

    SyntacticEntity? locationEntity;
    if (node is NamedCompilationUnitMember) {
      locationEntity = node.name;
    } else if (node is Expression) {
      locationEntity = node;
    } else if (node is ExtensionDeclaration) {
      locationEntity = node.name;
    } else if (node is FormalParameter) {
      locationEntity = node.name;
    } else if (node is MethodDeclaration) {
      locationEntity = node.name;
    } else if (node is NamedType) {
      locationEntity = node.name2;
    } else if (node is ConstructorDeclaration) {
      locationEntity = node.name ?? node.returnType;
    } else if (node is DeclaredIdentifier) {
      locationEntity = node.name;
    } else if (node is VariableDeclaration) {
      locationEntity = node.name;
    } else if (node is VariablePattern) {
      locationEntity = node.name;
    } else if (node is PatternFieldName) {
      locationEntity = node.name;
    }
    if (locationEntity == null) {
      return null;
    }

    var parent = node.parent;
    var grandParent = parent?.parent;
    if (parent is NamedType &&
        grandParent is ConstructorName &&
        grandParent.parent is InstanceCreationExpression) {
      node = grandParent.parent;
    } else if (parent is ConstructorName &&
        grandParent is InstanceCreationExpression) {
      node = grandParent;
    } else if (node is SimpleIdentifier &&
        parent is ConstructorDeclaration &&
        parent.name != null) {
      node = parent;
    }
    if (node != null &&
        (node is CompilationUnitMember ||
            node is Expression ||
            node is FormalParameter ||
            node is MethodDeclaration ||
            node is NamedType ||
            node is ConstructorDeclaration ||
            node is DeclaredIdentifier ||
            node is VariableDeclaration ||
            node is VariablePattern ||
            node is PatternFieldName)) {
      // For constructors, the location should cover the type name and
      // constructor name (for both calls and declarations).
      HoverInformation hover;
      if (node is InstanceCreationExpression) {
        hover = HoverInformation(
          node.constructorName.offset,
          node.constructorName.length,
        );
      } else if (node is ConstructorDeclaration) {
        var offset = node.returnType.offset;
        var end = node.name?.end ?? node.returnType.end;
        var length = end - node.returnType.offset;
        hover = HoverInformation(offset, length);
      } else {
        hover = HoverInformation(locationEntity.offset, locationEntity.length);
      }
      // element
      var element = ElementLocator.locate(node);
      if (element != null) {
        // variable, if synthetic accessor
        if (element is PropertyAccessorElement) {
          if (element.isSynthetic) {
            element = element.variable;
          }
        }
        // description
        var description = _elementDisplayString(element);
        hover.elementDescription = description;
        if (description != null &&
            node is InstanceCreationExpression &&
            node.keyword == null) {
          var prefix = node.isConst ? '(const) ' : '(new) ';
          hover.elementDescription = prefix + description;
        }
        hover.elementKind = element.kind.displayName;
        hover.isDeprecated = element.hasDeprecated;
        // not local element
        if (element.enclosingElement2 is! ExecutableElement) {
          // containing class
          var containingClass =
              element.thisOrAncestorOfType<InterfaceElement>();
          if (containingClass != null && containingClass != element) {
            hover.containingClassDescription = containingClass.displayName;
          }
          // containing library
          var library = element.library;
          if (library != null) {
            var uri = library.source.uri;
            var analysisSession = _unit.declaredElement?.session;
            if (uri.isScheme('file') && analysisSession != null) {
              // for 'file:' URIs, use the path after the project root
              var context = analysisSession.resourceProvider.pathContext;
              var projectRootDir =
                  analysisSession.analysisContext.contextRoot.root.path;
              var relativePath =
                  context.relative(context.fromUri(uri), from: projectRootDir);
              if (context.style == path.Style.windows) {
                var pathList = context.split(relativePath);
                hover.containingLibraryName = pathList.join('/');
              } else {
                hover.containingLibraryName = relativePath;
              }
            } else {
              hover.containingLibraryName = uri.toString();
            }
            hover.containingLibraryPath = library.source.fullName;
          }
        }
        // documentation
        hover.dartdoc = computePreferredDocumentation(
            _dartdocInfo, element, documentationPreference);
      }
      // parameter
      if (node is Expression) {
        hover.parameter = _elementDisplayString(
          node.staticParameterElement,
        );
      }
      // types
      {
        var parent = node.parent;
        DartType? staticType;
        if (node is Expression &&
            (element == null || element is VariableElement)) {
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
        }
        hover.staticType = _typeDisplayString(staticType);
      }
      // done
      return hover;
    }
    // not an expression
    return null;
  }

  String? _elementDisplayString(Element? element) {
    return element?.getDisplayString(
      withNullability: _unit.isNonNullableByDefault,
      multiline: true,
    );
  }

  String? _typeDisplayString(DartType? type) {
    return type?.getDisplayString(
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
      element = element.enclosingElement2;
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

    var documentedElementClass = documentedElement.enclosingElement2;
    if (documentedElementClass != null &&
        documentedElementClass != element.enclosingElement2) {
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
