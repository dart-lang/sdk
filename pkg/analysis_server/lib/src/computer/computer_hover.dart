// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    show HoverInformation;
import 'package:analysis_server/src/computer/computer_documentation.dart';
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
  final CompilationUnit _unit;
  final int _offset;
  final DocumentationPreference documentationPreference;
  final DartDocumentationComputer _documentationComputer;

  DartUnitHoverComputer(
    DartdocDirectiveInfo dartdocInfo,
    this._unit,
    this._offset, {
    this.documentationPreference = DocumentationPreference.full,
  }) : _documentationComputer = DartDocumentationComputer(dartdocInfo);

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
        node is DartPattern ||
        (node is LibraryDirective && node.name2 == null) ||
        (node is SimpleIdentifier && node.parent is ImportDirective) ||
        node is ImportPrefixReference) {
      var range = _hoverRange(node, locationEntity);
      var hover = HoverInformation(range.offset, range.length);
      // element
      var element = ElementLocator.locate(node);
      if (element != null) {
        // use the non-synthetic element to get things like dartdoc from the
        // underlying field (and resolved type args), except for `enum.values`
        // because that will resolve to the enum itself.
        if (_useNonSyntheticElement(element)) {
          element = element.nonSynthetic;
        }
        // description
        hover.elementDescription = _elementDisplayString(node, element);
        hover.elementKind = element.kind.displayName;
        hover.isDeprecated = element.hasDeprecated;
        // not local element
        if (element.enclosingElement3 is! ExecutableElement) {
          // containing class
          hover.containingClassDescription = _containingClass(element);
          // containing library
          var libraryInfo = _libraryInfo(element);
          hover.containingLibraryName = libraryInfo?.libraryName;
          hover.containingLibraryPath = libraryInfo?.libraryPath;
        }
        // documentation
        hover.dartdoc = _documentationComputer.computePreferred(
            element, documentationPreference);
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
      LibraryDirective() => node.libraryKeyword,
      ImportPrefixReference() => node.name,
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

  /// Returns information about the static type of [node].
  String? _typeDisplayString(AstNode node, Element? element) {
    var parent = node.parent;
    DartType? staticType;
    if (node is Expression &&
        (element == null ||
            element is VariableElement ||
            element is PropertyAccessorElement)) {
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
    return staticType?.getDisplayString();
  }

  /// Whether to use the non-synthetic element for hover information.
  ///
  /// Usually we want this because the non-synthetic element will include the
  /// users DartDoc and show any type arguments as declared.
  ///
  /// For enum.values, nonSynthetic returns the enum itself which causes
  /// incorrect types to be shown and so we stick with the synthetic getter.
  bool _useNonSyntheticElement(Element element) {
    return element is PropertyAccessorElement &&
        !(element.enclosingElement3 is EnumElement &&
            element.name == 'values' &&
            element.isSynthetic);
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
      var parent = node.parent;
      var parent2 = parent?.parent;

      if (parent is AssignmentExpression && parent.leftHandSide == node) {
        // Direct setter reference
        return parent.writeType;
      } else if (parent2 is AssignmentExpression &&
          parent2.leftHandSide == parent) {
        if (parent is PrefixedIdentifier && parent.identifier == node) {
          // Prefixed setter (`myInstance.foo =`)
          return parent2.writeType;
        } else if (parent is PropertyAccess && parent.propertyName == node) {
          // Expression prefix (`A<int>().foo =`)
          return parent2.writeType;
        }
      }
    }
    return node.staticType;
  }
}
