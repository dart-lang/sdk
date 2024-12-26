// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    show HoverInformation;
import 'package:analysis_server/src/computer/computer_documentation.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element2.dart';
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
      var element = ElementLocator.locate2(node);
      if (element != null) {
        // short code that illustrates the element meaning.
        hover.elementDescription = _elementDisplayString(node, element);
        hover.elementKind = element.kind.displayName;
        if (element case Annotatable a) {
          hover.isDeprecated = a.metadata2.hasDeprecated;
        }
        // not local element
        if (element.enclosingElement2 is! ExecutableElement2) {
          // containing class
          hover.containingClassDescription = _containingClass(element);
          // containing library
          var libraryInfo = _libraryInfo(element);
          hover.containingLibraryName = libraryInfo?.libraryName;
          hover.containingLibraryPath = libraryInfo?.libraryPath;
        }
        // documentation
        hover.dartdoc = _documentationComputer.computePreferred(
          element,
          documentationPreference,
        );
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
  String? _containingClass(Element2 element) {
    var containingClass = element.thisOrAncestorOfType2<InterfaceElement2>();
    return containingClass != null && containingClass != element
        ? containingClass.displayName
        : null;
  }

  /// Gets the display string for [element].
  ///
  /// This is usually `element.getDisplayString()` but may contain additional
  /// information to disambiguate things like constructors from types (and
  /// whether they are const).
  String? _elementDisplayString(AstNode node, Element2? element) {
    var displayString = element?.displayString2(multiline: true);

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
  _LibraryInfo _libraryInfo(Element2 element) {
    var library = element.library2;
    if (library == null) {
      return null;
    }

    var definingSource = library.firstFragment.source;
    var uri = definingSource.uri;
    var analysisSession = _unit.declaredFragment?.element.session;

    String? libraryName, libraryPath;
    if (uri.isScheme('file') && analysisSession != null) {
      // for 'file:' URIs, use the path after the project root
      var context = analysisSession.resourceProvider.pathContext;
      var projectRootDir =
          analysisSession.analysisContext.contextRoot.root.path;
      var relativePath = context.relative(
        context.fromUri(uri),
        from: projectRootDir,
      );
      if (context.style == path.Style.windows) {
        var pathList = context.split(relativePath);
        libraryName = pathList.join('/');
      } else {
        libraryName = relativePath;
      }
    } else {
      libraryName = uri.toString();
    }
    libraryPath = definingSource.fullName;

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
    if (node is! Expression) {
      return null;
    }
    var parameter = node.correspondingParameter;
    return switch (parameter?.enclosingElement2) {
      // Expressions passed as arguments to setters and binary expressions
      // will have parameters here but we don't want them to show as such in
      // hovers because information about those functions are already available
      // by hovering over the function name or the operator.
      SetterElement() => null,
      MethodElement2 method when method.isOperator => null,
      _ => _elementDisplayString(node, parameter),
    };
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
  String? _typeDisplayString(AstNode node, Element2? element) {
    var parent = node.parent;
    DartType? staticType;
    if (node is Expression &&
        (element == null ||
            element is VariableElement2 ||
            element is GetterElement ||
            element is SetterElement)) {
      staticType = _getTypeOfDeclarationOrReference(node);
    } else if (element is VariableElement2) {
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

  static DartType? _getTypeOfDeclarationOrReference(Expression node) {
    if (node is SimpleIdentifier) {
      var element = node.element;
      if (element is VariableElement2) {
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
