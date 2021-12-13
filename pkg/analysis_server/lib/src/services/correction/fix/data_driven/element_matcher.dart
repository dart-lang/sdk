// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, ExtensionElement, PrefixElement;
import 'package:analyzer/dart/element/type.dart';

/// An object that can be used to determine whether an element is appropriate
/// for a given reference.
class ElementMatcher {
  /// The URIs of the libraries that are imported in the library containing the
  /// reference.
  final List<Uri> importedUris;

  /// The components of the element being referenced. The components are ordered
  /// from the most local to the most global.
  final List<String> components;

  /// A list of the kinds of elements that are appropriate for some given
  /// location in the code An empty list represents all kinds rather than no
  /// kinds.
  final List<ElementKind> validKinds;

  /// Initialize a newly created matcher representing a reference to an element
  /// with the given [name] in a library that imports the [importedUris].
  ElementMatcher(
      {required this.importedUris,
      required this.components,
      List<ElementKind>? kinds})
      : assert(components.isNotEmpty),
        validKinds = kinds ?? const [];

  /// Return `true` if this matcher matches the given [element].
  bool matches(ElementDescriptor element) {
    //
    // Check that the components in the element's name match the node.
    //
    // This algorithm is probably too general given that there will currently
    // always be either one or two components.
    //
    var elementComponents = element.components;
    var elementComponentCount = elementComponents.length;
    var nodeComponentCount = components.length;
    if (nodeComponentCount == elementComponentCount) {
      // The component counts are the same, so we can just compare the two
      // lists.
      for (var i = 0; i < nodeComponentCount; i++) {
        if (elementComponents[i] != components[i]) {
          return false;
        }
      }
    } else if (nodeComponentCount < elementComponentCount) {
      // The node has fewer components, which can happen, for example, when we
      // can't figure out the class that used to define a field. We treat the
      // missing components as wildcards and match the rest.
      for (var i = 0; i < nodeComponentCount; i++) {
        if (elementComponents[i] != components[i]) {
          return false;
        }
      }
    } else {
      // The node has more components than the element, which can happen when a
      // constructor is implicitly renamed because the class was renamed.
      // TODO(brianwilkerson) Figure out whether we want to support this or
      //  whether we want to require fix data authors to explicitly include the
      //  change to the constructor. On the one hand it's more work for the
      //  author, on the other hand it give us more data so we're less likely to
      //  make apply a fix in invalid circumstances.
      if (elementComponents[0] != components[1]) {
        return false;
      }
    }
    //
    // Check whether the kind of element matches the possible kinds that the
    // node might have.
    //
    if (validKinds.isNotEmpty && !validKinds.contains(element.kind)) {
      return false;
    }
    //
    // Check whether the element is in an imported library.
    //
    var libraryUris = element.libraryUris;
    for (var importedUri in importedUris) {
      if (libraryUris.contains(importedUri)) {
        return true;
      }
    }
    return false;
  }

  /// Return an element matcher that will match the element that is, or should
  /// be, associated with the given [node], or `null` if there is no appropriate
  /// matcher for the node.
  static ElementMatcher? forNode(AstNode? node) {
    if (node == null) {
      return null;
    }
    var importedUris = _importElementsForNode(node);
    if (importedUris == null) {
      return null;
    }
    var components = _componentsForNode(node);
    if (components == null) {
      return null;
    }
    return ElementMatcher(
        importedUris: importedUris,
        components: components,
        kinds: _kindsForNode(node));
  }

  /// Return the components of the path of the element associated with the given
  /// [node]. The components are ordered from the most local to the most global.
  /// For example, for a constructor this would be the name of the constructor
  /// followed by the name of the class in which the constructor is declared
  /// (with an empty string for the unnamed constructor).
  static List<String>? _componentsForNode(AstNode? node) {
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is Label && parent.parent is NamedExpression) {
        // The parent of the named expression is an argument list. Because we
        // don't represent parameters as elements, the element we need to match
        // against is the invocation containing those arguments.
        return _componentsFromParent(parent.parent!.parent!);
      } else if (parent is NamedType && parent.parent is ConstructorName) {
        return ['', node.name];
      } else if (parent is MethodDeclaration && node == parent.name) {
        return [node.name];
      } else if ((parent is MethodInvocation &&
              node == parent.methodName &&
              !_isPrefix(parent.target)) ||
          (parent is PrefixedIdentifier &&
              node == parent.identifier &&
              !_isPrefix(parent.prefix)) ||
          (parent is PropertyAccess &&
              node == parent.propertyName &&
              !_isPrefix(parent.target))) {
        return _componentsFromParent(node);
      }
      return _componentsFromIdentifier(node);
    } else if (node is PrefixedIdentifier) {
      var parent = node.parent;
      if (parent is NamedType && parent.parent is ConstructorName) {
        return ['', node.identifier.name];
      }
      return [node.identifier.name];
    } else if (node is ConstructorName) {
      var constructorName = node.name;
      if (constructorName != null) {
        return [constructorName.name];
      }
    } else if (node is NamedType) {
      return [node.name.name];
    } else if (node is TypeArgumentList) {
      return _componentsFromParent(node);
    } else if (node is ArgumentList) {
      return _componentsFromParent(node);
    }
    var parent = node?.parent;
    if (parent is ArgumentList) {
      return _componentsFromParent(parent);
    }
    return null;
  }

  /// Return the components associated with the [identifier] when there is no
  /// contextual information.
  static List<String> _componentsFromIdentifier(SimpleIdentifier identifier) {
    var element = identifier.staticElement;
    if (element == null) {
      var parent = identifier.parent;
      if (parent is AssignmentExpression && identifier == parent.leftHandSide) {
        element = parent.writeElement;
      }
    }
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElement) {
        return [identifier.name, enclosingElement.name];
      } else if (enclosingElement is ExtensionElement) {
        var name = enclosingElement.name;
        if (name != null) {
          return [identifier.name, name];
        }
      }
    }
    return [identifier.name];
  }

  /// Return the components for the element associated with the given [node] by
  /// looking at the parent of the [node].
  static List<String>? _componentsFromParent(AstNode node) {
    var parent = node.parent;
    if (parent is ArgumentList) {
      parent = parent.parent;
    }
    if (parent is Annotation) {
      return [parent.constructorName?.name ?? '', parent.name.name];
    } else if (parent is ExtensionOverride) {
      return [parent.extensionName.name];
    } else if (parent is InstanceCreationExpression) {
      var constructorName = parent.constructorName;
      return [
        constructorName.name?.name ?? '',
        constructorName.type2.name.name
      ];
    } else if (parent is MethodInvocation) {
      var methodName = parent.methodName;
      var targetName = _nameOfTarget(parent.realTarget);
      if (targetName != null) {
        return [methodName.name, targetName];
      }
      return _componentsFromIdentifier(methodName);
    } else if (parent is PrefixedIdentifier) {
      var identifier = parent.identifier;
      var targetName = _nameOfTarget(parent.prefix);
      if (targetName != null) {
        return [identifier.name, targetName];
      }
      return _componentsFromIdentifier(identifier);
    } else if (parent is PropertyAccess) {
      var propertyName = parent.propertyName;
      var targetName = _nameOfTarget(parent.realTarget);
      if (targetName != null) {
        return [propertyName.name, targetName];
      }
      return _componentsFromIdentifier(propertyName);
    } else if (parent is RedirectingConstructorInvocation) {
      var ancestor = parent.parent;
      if (ancestor is ConstructorDeclaration) {
        return [parent.constructorName?.name ?? '', ancestor.returnType.name];
      }
    } else if (parent is SuperConstructorInvocation) {
      var ancestor = parent.parent;
      if (ancestor is ConstructorDeclaration) {
        return [parent.constructorName?.name ?? '', ancestor.returnType.name];
      }
    }
    return null;
  }

  /// Return the URIs of the imports in the library containing the [node], or
  /// `null` if the imports can't be determined.
  static List<Uri>? _importElementsForNode(AstNode node) {
    var root = node.root;
    if (root is! CompilationUnit) {
      return null;
    }
    var importedUris = <Uri>[];
    var library = root.declaredElement?.library;
    if (library == null) {
      return null;
    }
    for (var importElement in library.imports) {
      // TODO(brianwilkerson) Filter based on combinators to help avoid making
      //  invalid suggestions.
      var uri = importElement.importedLibrary?.source.uri;
      if (uri != null) {
        // The [uri] is `null` if the literal string is not a valid URI.
        importedUris.add(uri);
      }
    }
    return importedUris;
  }

  /// Return `true` if the [node] is a prefix
  static bool _isPrefix(AstNode? node) {
    return node is SimpleIdentifier && node.staticElement is PrefixElement;
  }

  /// Return the kinds of elements that could reasonably be referenced at the
  /// location of the [node]. If [child] is not `null` then the [node] is a
  /// parent of the [child].
  static List<ElementKind>? _kindsForNode(AstNode? node, {AstNode? child}) {
    if (node is ConstructorName) {
      return const [ElementKind.constructorKind];
    } else if (node is ExtensionOverride) {
      return const [ElementKind.extensionKind];
    } else if (node is InstanceCreationExpression) {
      return const [ElementKind.constructorKind];
    } else if (node is Label) {
      var argumentList = node.parent?.parent;
      return _kindsForNode(argumentList?.parent, child: argumentList);
    } else if (node is MethodInvocation) {
      assert(child != null);
      if (node.target == child) {
        return const [
          ElementKind.classKind,
          ElementKind.enumKind,
          ElementKind.mixinKind
        ];
      }
      var realTarget = node.realTarget;
      if (realTarget != null && !_isPrefix(realTarget)) {
        return const [ElementKind.constructorKind, ElementKind.methodKind];
      }
      return const [
        ElementKind.classKind,
        ElementKind.extensionKind,
        ElementKind.functionKind,
        ElementKind.methodKind
      ];
    } else if (node is NamedType) {
      var parent = node.parent;
      if (parent is ConstructorName && parent.name == null) {
        return const [ElementKind.classKind, ElementKind.constructorKind];
      }
      return const [
        ElementKind.classKind,
        ElementKind.enumKind,
        ElementKind.mixinKind,
        ElementKind.typedefKind
      ];
    } else if (node is PrefixedIdentifier) {
      var prefix = node.prefix;
      if (prefix == child) {
        return const [
          ElementKind.classKind,
          ElementKind.enumKind,
          ElementKind.extensionKind,
          ElementKind.mixinKind,
          ElementKind.typedefKind
        ];
      } else if (prefix.staticElement is PrefixElement) {
        var parent = node.parent;
        if ((parent is NamedType && parent.parent is! ConstructorName) ||
            (parent is PropertyAccess && parent.target == node)) {
          return const [
            ElementKind.classKind,
            ElementKind.enumKind,
            ElementKind.extensionKind,
            ElementKind.mixinKind,
            ElementKind.typedefKind
          ];
        }
        return const [
          // If the old class has been removed then this might have been a
          // constructor invocation.
          ElementKind.constructorKind,
          ElementKind.functionKind, // tear-off
          ElementKind.getterKind,
          ElementKind.setterKind,
          ElementKind.variableKind
        ];
      }
      return const [
        ElementKind.constantKind,
        ElementKind.fieldKind,
        ElementKind.functionKind, // tear-off
        ElementKind.getterKind,
        ElementKind.methodKind, // tear-off
        ElementKind.setterKind
      ];
    } else if (node is PropertyAccess) {
      return const [
        ElementKind.constantKind,
        ElementKind.fieldKind,
        ElementKind.functionKind, // tear-off, prefixed
        ElementKind.getterKind,
        ElementKind.methodKind, // tear-off, prefixed
        ElementKind.setterKind
      ];
    } else if (node is SimpleIdentifier) {
      return _kindsForNode(node.parent, child: node);
    }
    return null;
  }

  /// Return the name of the class associated with the given [target].
  static String? _nameOfTarget(Expression? target) {
    if (target is SimpleIdentifier) {
      var type = target.staticType;
      if (type != null) {
        if (type is InterfaceType) {
          return type.element.name;
        } else if (type.isDynamic) {
          // The name is likely to be undefined.
          return target.name;
        }
        return null;
      }
      return target.name;
    } else if (target != null) {
      var type = target.staticType;
      if (type is InterfaceType) {
        return type.element.name;
      }
      return null;
    }
    return null;
  }
}
