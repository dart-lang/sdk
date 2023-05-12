// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart'
    show ExtensionElement, InterfaceElement, PrefixElement;
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
  /// whose name matches the given [components] and element [kinds] in a library
  /// that imports the [importedUris].
  ElementMatcher(
      {required this.importedUris,
      required this.components,
      required List<ElementKind> kinds})
      : assert(components.isNotEmpty),
        validKinds = kinds;

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
      // The element has one more empty component
      if (nodeComponentCount + 1 == elementComponentCount &&
          elementComponents[0].isEmpty) {
        for (var i = 0; i < nodeComponentCount; i++) {
          if (elementComponents[i + 1] != components[i]) {
            return false;
          }
        }
      } else {
        // The node has fewer components, which can happen, for example, when we
        // can't figure out the class that used to define a field. We treat the
        // missing components as wildcards and match the rest.
        for (var i = 0; i < nodeComponentCount; i++) {
          if (elementComponents[i] != components[i]) {
            return false;
          }
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

  /// Return a list of element matchers that will match the element that is, or
  /// should be, associated with the given [node]. The list will be empty if
  /// there are no appropriate matchers for the [node].
  static List<ElementMatcher> matchersForNode(AstNode? node, Token? nameToken) {
    if (node == null) {
      return const [];
    }
    var importedUris = _importElementsForNode(node);
    if (importedUris == null) {
      return const [];
    }
    var builder = _MatcherBuilder(importedUris);
    builder.buildMatchersForNode(node, nameToken);
    return builder.matchers.toList();
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
    for (var importElement in library.libraryImports) {
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
}

/// A helper class used to build a list of element matchers.
class _MatcherBuilder {
  final List<ElementMatcher> matchers = [];

  final List<Uri> importedUris;

  _MatcherBuilder(this.importedUris);

  void buildMatchersForNode(AstNode? node, Token? nameToken) {
    if (node is ArgumentList) {
      _buildFromArgumentList(node);
    } else if (node is BinaryExpression) {
      _buildFromBinaryExpression(node);
    } else if (node is ConstructorName) {
      _buildFromConstructorName(node);
    } else if (node is ExtensionOverride) {
      _buildFromExtensionOverride(node);
    } else if (node is FunctionDeclaration) {
      _addMatcher(components: [node.name.lexeme], kinds: []);
    } else if (node is Literal) {
      var parent = node.parent;
      if (parent is NamedExpression) {
        parent = parent.parent;
      }
      if (parent is ArgumentList) {
        _buildFromArgumentList(parent);
      }
    } else if (node is NamedType) {
      _buildFromNamedType(node);
    } else if (node is PrefixedIdentifier) {
      _buildFromPrefixedIdentifier(node);
    } else if (node is MethodDeclaration) {
      _buildFromMethodDeclaration(node);
    } else if (node is SimpleIdentifier && nameToken != null) {
      _buildFromSimpleIdentifier(node, nameToken);
    } else if (node is TypeArgumentList) {
      _buildFromTypeArgumentList(node);
    } else if (node is VariableDeclaration) {
      _addMatcher(components: [node.name.lexeme], kinds: []);
    }
  }

  void _addMatcher(
      {required List<String> components, required List<ElementKind> kinds}) {
    matchers.add(ElementMatcher(
        importedUris: importedUris, components: components, kinds: kinds));
  }

  /// Build a matcher for the element being invoked.
  void _buildFromArgumentList(ArgumentList node) {
    var parent = node.parent;
    if (parent is Annotation) {
      _addMatcher(
        components: [parent.constructorName?.name ?? '', parent.name.name],
        kinds: [ElementKind.constructorKind],
      );
      // } else if (parent is ExtensionOverride) {
      //   // TODO(brianwilkerson) Determine whether this branch can be reached.
      //   _buildFromExtensionOverride(parent);
    } else if (parent is FunctionExpressionInvocation) {
      _buildFromFunctionExpressionInvocation(parent);
    } else if (parent is InstanceCreationExpression) {
      _buildFromInstanceCreationExpression(parent);
    } else if (parent is MethodInvocation) {
      _buildFromMethodInvocation(parent);
    } else if (parent is RedirectingConstructorInvocation) {
      var grandparent = parent.parent;
      if (grandparent is ConstructorDeclaration) {
        _addMatcher(
          components: [
            parent.constructorName?.name ?? '',
            grandparent.returnType.name
          ],
          kinds: [ElementKind.constructorKind],
        );
      }
    } else if (parent is SuperConstructorInvocation) {
      var superclassName = parent.staticElement?.enclosingElement.name;
      if (superclassName != null) {
        _addMatcher(
          components: [parent.constructorName?.name ?? '', superclassName],
          kinds: [ElementKind.constructorKind],
        );
      }
    }
  }

  /// Build a matcher for the operator being invoked.
  void _buildFromBinaryExpression(BinaryExpression node) {
    // TODO(brianwilkerson) Implement this method in order to support changes to
    //  operators.
  }

  /// Build a matcher for the constructor being referenced.
  void _buildFromConstructorName(ConstructorName node) {
    // TODO(brianwilkerson) Use the static element, if there is one, in order to
    //  get a more exact matcher.
    // TODO(brianwilkerson) Use 'new' for the name of the unnamed constructor.
    var constructorName = node.name?.name ?? ''; // ?? 'new';
    var className = node.type.name2.lexeme;
    _addMatcher(
      components: [constructorName, className],
      kinds: const [ElementKind.constructorKind],
    );
    _addMatcher(
      components: [className],
      kinds: const [ElementKind.classKind],
    );
  }

  /// Build a matcher for the extension.
  void _buildFromExtensionOverride(ExtensionOverride node) {
    _addMatcher(
      components: [node.name.lexeme],
      kinds: [ElementKind.extensionKind],
    );
  }

  /// Build a matcher for the function being invoked.
  void _buildFromFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    // TODO(brianwilkerson) This case was missed in the original implementation
    //  and there are no tests for it at this point, but it ought to be supported.
  }

  /// Build a matcher for the constructor being invoked.
  void _buildFromInstanceCreationExpression(InstanceCreationExpression node) {
    _buildFromConstructorName(node.constructorName);
  }

  /// Build a matcher for the method being declared.
  void _buildFromMethodDeclaration(MethodDeclaration node) {
    _addMatcher(
      components: [node.name.lexeme],
      kinds: [ElementKind.methodKind],
    );
  }

  /// Build a matcher for the method being invoked.
  void _buildFromMethodInvocation(MethodInvocation node) {
    // TODO(brianwilkerson) Use the static element, if there is one, in order to
    //  get a more exact matcher.
    // var element = node.methodName.staticElement;
    // if (element != null) {
    //   return _buildFromElement(element);
    // }
    var methodName = node.methodName;
    var targetName = _nameOfTarget(node.realTarget);
    if (targetName != null) {
      // If there is a target, and we know the type of the target, then we know
      // that a method is being invoked.
      _addMatcher(
        components: [methodName.name, targetName],
        kinds: [
          ElementKind.constructorKind,
          ElementKind.methodKind,
        ],
      );
    } else if (node.realTarget != null) {
      // If there is a target, but we don't know the type of the target, then
      // the target type might be undefined and this might have been either a
      // method invocation, an invocation of a function returned by a getter, or
      // a constructor invocation prior to the type having been deleted.
      _addMatcher(
        components: _componentsFromIdentifier(methodName),
        kinds: [
          ElementKind.constructorKind,
          ElementKind.getterKind,
          ElementKind.methodKind,
        ],
      );
    } else {
      // If there is no target, then this might have been either a method
      // invocation, a function invocation (of either a function or a function
      // returned from a getter), a constructor invocation, or an extension
      // override. If it's a constructor, then the change might have been to the
      // class rather than an individual constructor.
      _addMatcher(
        components: _componentsFromIdentifier(methodName),
        kinds: [
          ElementKind.classKind,
          ElementKind.constructorKind,
          ElementKind.extensionKind,
          ElementKind.functionKind,
          ElementKind.getterKind,
          ElementKind.methodKind,
        ],
      );
    }
  }

  /// Build a matcher for the type.
  void _buildFromNamedType(NamedType node) {
    var parent = node.parent;
    if (parent is ConstructorName) {
      return _buildFromConstructorName(parent);
    }
    // TODO(brianwilkerson) Use the static element, if there is one, in order to
    //  get a more exact matcher.
    _addMatcher(
      components: [node.name2.lexeme],
      kinds: const [
        ElementKind.classKind,
        ElementKind.enumKind,
        ElementKind.mixinKind,
        ElementKind.typedefKind
      ],
    );
    // TODO(brianwilkerson) Determine whether we can ever get here as a result
    //  of having a removed unnamed constructor.
    // _addMatcher(
    //   components: ['', node.name.name],
    //   kinds: const [ElementKind.constructorKind],
    // );
  }

  /// Build a matcher for the element represented by the prefixed identifier.
  void _buildFromPrefixedIdentifier(PrefixedIdentifier node) {
    var parent = node.parent;
    if (parent is NamedType) {
      return _buildFromNamedType(parent);
    }
    // TODO(brianwilkerson) Use the static element, if there is one, in order to
    //  get a more exact matcher.
    var prefix = node.prefix;
    if (prefix.staticElement is PrefixElement) {
      var parent = node.parent;
      if ((parent is NamedType && parent.parent is! ConstructorName) ||
          (parent is PropertyAccess && parent.target == node)) {
        _addMatcher(components: [
          node.identifier.name
        ], kinds: const [
          ElementKind.classKind,
          ElementKind.enumKind,
          ElementKind.extensionKind,
          ElementKind.mixinKind,
          ElementKind.typedefKind
        ]);
      }
      _addMatcher(components: [
        node.identifier.name
      ], kinds: const [
        // If the old class has been removed then this might have been a
        // constructor invocation.
        ElementKind.constructorKind,
        ElementKind.functionKind, // tear-off
        ElementKind.getterKind,
        ElementKind.setterKind,
        ElementKind.variableKind
      ]);
    }
    // It looks like we're accessing a member, so try to figure out the
    // name of the type defining the member.
    var targetType = node.prefix.staticType;
    if (targetType is InterfaceType) {
      _addMatcher(
        components: [node.identifier.name, targetType.element.name],
        kinds: const [
          ElementKind.constantKind,
          ElementKind.fieldKind,
          ElementKind.functionKind, // tear-off
          ElementKind.getterKind,
          ElementKind.methodKind, // tear-off
          ElementKind.setterKind
        ],
      );
    }
    // It looks like we're accessing a member, but we don't know what kind of
    // member, so we include all of the member kinds.
    var container = node.prefix.staticElement;
    if (container is InterfaceElement) {
      _addMatcher(
        components: [node.identifier.name, container.name],
        kinds: const [
          ElementKind.constantKind,
          ElementKind.fieldKind,
          ElementKind.functionKind, // tear-off
          ElementKind.getterKind,
          ElementKind.methodKind, // tear-off
          ElementKind.setterKind
        ],
      );
    } else if (container is ExtensionElement) {
      _addMatcher(
        components: [node.identifier.name, container.displayName],
        kinds: const [
          ElementKind.constantKind,
          ElementKind.fieldKind,
          ElementKind.functionKind, // tear-off
          ElementKind.getterKind,
          ElementKind.methodKind, // tear-off
          ElementKind.setterKind
        ],
      );
    }
  }

  /// Build a matcher for the property being accessed.
  void _buildFromPropertyAccess(PropertyAccess node) {
    // TODO(brianwilkerson) Use the static element, if there is one, in order to
    //  get a more exact matcher.
    var propertyName = node.propertyName;
    var targetName = _nameOfTarget(node.realTarget);
    List<String> components;
    if (targetName != null) {
      components = [propertyName.name, targetName];
    } else {
      components = _componentsFromIdentifier(propertyName);
    }
    _addMatcher(
      components: components,
      kinds: const [
        ElementKind.constantKind,
        ElementKind.fieldKind,
        ElementKind.functionKind, // tear-off, prefixed
        ElementKind.getterKind,
        ElementKind.methodKind, // tear-off, prefixed
        ElementKind.setterKind
      ],
    );
  }

  /// Build a matcher for the element referenced by the identifier.
  void _buildFromSimpleIdentifier(SimpleIdentifier node, Token nameToken) {
    // TODO(brianwilkerson) Use the static element, if there is one, in order to
    //  get a more exact matcher.
    var parent = node.parent;
    if (parent is Label && parent.parent is NamedExpression) {
      // The parent of the named expression is an argument list. Because we
      // don't represent parameters as elements, the element we need to match
      // against is the invocation containing those arguments.
      _buildFromArgumentList(parent.parent!.parent as ArgumentList);
    } else if (parent is NamedType) {
      _buildFromNamedType(parent);
    } else if (parent is MethodDeclaration && nameToken == parent.name) {
      _buildFromMethodDeclaration(parent);
    } else if (parent is MethodInvocation &&
        node == parent.methodName &&
        !_isPrefix(parent.target)) {
      _buildFromMethodInvocation(parent);
    } else if (parent is PrefixedIdentifier && node == parent.identifier) {
      _buildFromPrefixedIdentifier(parent);
    } else if (parent is PropertyAccess &&
        node == parent.propertyName &&
        !_isPrefix(parent.target)) {
      _buildFromPropertyAccess(parent);
    } else {
      // TODO(brianwilkerson) See whether the list of kinds can be specified.
      _addMatcher(components: [node.name], kinds: []);
    }
  }

  /// Build a matcher for the element with which the type arguments are
  /// associated.
  void _buildFromTypeArgumentList(TypeArgumentList node) {
    var parent = node.parent;
    if (parent is ExtensionOverride) {
      _buildFromExtensionOverride(parent);
    } else if (parent is FunctionExpressionInvocation) {
      _buildFromFunctionExpressionInvocation(parent);
    } else if (parent is InstanceCreationExpression) {
      _buildFromInstanceCreationExpression(parent);
    } else if (parent is MethodInvocation) {
      _buildFromMethodInvocation(parent);
    }
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
      if (enclosingElement is InterfaceElement) {
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

  /// Return `true` if the [node] is a prefix
  static bool _isPrefix(AstNode? node) {
    return node is SimpleIdentifier && node.staticElement is PrefixElement;
  }

  /// Return the name of the class associated with the given [target].
  static String? _nameOfTarget(Expression? target) {
    if (target is SimpleIdentifier) {
      var type = target.staticType;
      if (type != null) {
        if (type is InterfaceType) {
          return type.element.name;
        } else if (type is DynamicType) {
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
