// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/element/member.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart';

import 'analyzer.dart';
import 'util/dart_type_utilities.dart';

class EnumLikeClassDescription {
  final Map<DartObject, Set<FieldElement>> _enumConstants;
  EnumLikeClassDescription(this._enumConstants);

  /// Returns a fresh map of the class's enum-like constant values.
  Map<DartObject, Set<FieldElement>> get enumConstants => {..._enumConstants};
}

extension AstNodeExtension on AstNode {
  Iterable<AstNode> get childNodes => childEntities.whereType<AstNode>();

  bool get isEffectivelyPrivate {
    var node = this;
    if (node.isInternal) return true;
    if (node is ClassDeclaration) {
      var classElement = node.declaredElement;
      if (classElement != null) {
        if (classElement.isSealed) return true;
        if (classElement.isAbstract) {
          if (classElement.isFinal) return true;
          if (classElement.isInterface) return true;
        }
      }
    }
    return false;
  }

  bool get isInternal {
    var parent = thisOrAncestorOfType<CompilationUnitMember>();
    if (parent == null) return false;

    var element = parent.declaredElement;
    return element != null && element.hasInternal;
  }

  /// Builds the list resulting from traversing the node in DFS and does not
  /// include the node itself.
  ///
  /// It excludes the nodes for which the [excludeCriteria] returns true. If
  /// [excludeCriteria] is not provided, all nodes are included.
  @Deprecated(
      'This approach is slow and slated for removal. Traversal via a standard visitor is preferred.')
  Iterable<AstNode> traverseNodesInDFS({AstNodePredicate? excludeCriteria}) {
    var nodes = <AstNode>{};
    var nodesToVisit = List.of(childNodes);
    if (excludeCriteria == null) {
      while (nodesToVisit.isNotEmpty) {
        var node = nodesToVisit.removeAt(0);
        nodes.add(node);
        nodesToVisit.insertAll(0, node.childNodes);
      }
    } else {
      while (nodesToVisit.isNotEmpty) {
        var node = nodesToVisit.removeAt(0);
        if (excludeCriteria(node)) continue;
        nodes.add(node);
        nodesToVisit.insertAll(0, node.childNodes);
      }
    }

    return nodes;
  }
}

extension AstNodeNullableExtension on AstNode? {
  bool get isFieldNameShortcut {
    var node = this;
    if (node is NullCheckPattern) node = node.parent;
    if (node is NullAssertPattern) node = node.parent;
    return node is PatternField && node.name != null && node.name?.name == null;
  }

  /// Return `true` if the expression is null aware, or if one of its recursive
  /// targets is null aware.
  bool containsNullAwareInvocationInChain() {
    var node = this;
    if (node is PropertyAccess) {
      if (node.isNullAware) return true;
      return node.target.containsNullAwareInvocationInChain();
    } else if (node is MethodInvocation) {
      if (node.isNullAware) return true;
      return node.target.containsNullAwareInvocationInChain();
    } else if (node is IndexExpression) {
      if (node.isNullAware) return true;
      return node.target.containsNullAwareInvocationInChain();
    }
    return false;
  }
}

extension BlockExtension on Block {
  /// Returns the last statement of this block, or `null` if this is empty.
  ///
  /// If the last immediate statement of this block is a [Block], recurses into
  /// it to find the last statement.
  Statement? get lastStatement {
    if (statements.isEmpty) {
      return null;
    }
    var lastStatement = statements.last;
    if (lastStatement is Block) {
      return lastStatement.lastStatement;
    }
    return lastStatement;
  }
}

extension ClassElementExtension on ClassElement {
  /// Returns an [EnumLikeClassDescription] for this if the latter is a valid
  /// "enum-like" class.
  ///
  /// An enum-like class must meet the following requirements:
  ///
  /// * is concrete,
  /// * has no public constructors,
  /// * has no factory constructors,
  /// * has two or more static const fields with the same type as the class,
  /// * has no subclasses declared in the defining library.
  ///
  /// The returned [EnumLikeClassDescription]'s `enumConstantNames` contains all
  /// of the static const fields with the same type as the class, with one
  /// exception; any static const field which is marked `@Deprecated` and is
  /// equal to another static const field with the same type as the class is not
  /// included. Such a field is assumed to be deprecated in favor of the field
  /// with equal value.
  EnumLikeClassDescription? get asEnumLikeClass {
    // See discussion: https://github.com/dart-lang/linter/issues/2083.

    // Must be concrete.
    if (isAbstract) {
      return null;
    }

    // With only private non-factory constructors.
    for (var constructor in constructors) {
      if (!constructor.isPrivate || constructor.isFactory) {
        return null;
      }
    }

    var type = thisType;

    // And 2 or more static const fields whose type is the enclosing class.
    var enumConstantCount = 0;
    var enumConstants = <DartObject, Set<FieldElement>>{};
    for (var field in fields) {
      // Ensure static const.
      if (field.isSynthetic || !field.isConst || !field.isStatic) {
        continue;
      }
      // Check for type equality.
      if (field.type != type) {
        continue;
      }
      var fieldValue = field.computeConstantValue();
      if (fieldValue == null) {
        continue;
      }
      enumConstantCount++;
      enumConstants.putIfAbsent(fieldValue, () => {}).add(field);
    }
    if (enumConstantCount < 2) {
      return null;
    }

    // And no subclasses in the defining library.
    if (hasSubclassInDefiningCompilationUnit) return null;

    return EnumLikeClassDescription(enumConstants);
  }

  bool get hasSubclassInDefiningCompilationUnit {
    var compilationUnit = library.definingCompilationUnit;
    for (var cls in compilationUnit.classes) {
      InterfaceType? classType = cls.thisType;
      do {
        classType = classType?.superclass;
        if (classType == thisType) {
          return true;
        }
      } while (classType != null && !classType.isDartCoreObject);
    }
    return false;
  }

  bool get isEnumLikeClass => asEnumLikeClass != null;

  /// Returns whether this class is exactly [otherName] declared in
  /// [otherLibrary].
  bool isClass(String otherName, String otherLibrary) =>
      name == otherName && library.name == otherLibrary;
}

extension ClassMemberListExtension on List<ClassMember> {
  MethodDeclaration? getMethod(String name) => whereType<MethodDeclaration>()
      .firstWhereOrNull((node) => node.name.lexeme == name);
}

extension ConstructorElementExtension on ConstructorElement {
  /// Returns whether `this` is the same element as the [className] constructor
  /// named [constructorName] declared in [uri].
  bool isSameAs({
    required String uri,
    required String className,
    required String constructorName,
  }) =>
      library.name == uri &&
      enclosingElement.name == className &&
      name == constructorName;
}

extension DartTypeExtension on DartType? {
  bool extendsClass(String? className, String library) {
    var self = this;
    if (self is InterfaceType) {
      return _extendsClass(self, <InterfaceElement>{}, className, library);
    }
    return false;
  }

  bool implementsAnyInterface(Iterable<InterfaceTypeDefinition> definitions) {
    bool isAnyInterface(InterfaceType i) =>
        definitions.any((d) => i.isSameAs(d.name, d.library));

    var typeToCheck = this;
    if (typeToCheck is TypeParameterType) {
      typeToCheck = typeToCheck.typeForInterfaceCheck;
    }
    if (typeToCheck is InterfaceType) {
      return isAnyInterface(typeToCheck) ||
          !typeToCheck.element.isSynthetic &&
              typeToCheck.element.allSupertypes.any(isAnyInterface);
    } else {
      return false;
    }
  }

  bool implementsInterface(String interface, String library) {
    var self = this;
    if (self is! InterfaceType) {
      return false;
    }
    bool predicate(InterfaceType i) => i.isSameAs(interface, library);
    var element = self.element;
    return predicate(self) ||
        !element.isSynthetic && element.allSupertypes.any(predicate);
  }

  /// Returns whether `this` is the same element as [interface], declared in
  /// [library].
  bool isSameAs(String? interface, String? library) {
    var self = this;
    return self is InterfaceType &&
        self.element.name == interface &&
        self.element.library.name == library;
  }

  static bool _extendsClass(
          InterfaceType? type,
          Set<InterfaceElement> seenElements,
          String? className,
          String? library) =>
      type != null &&
      seenElements.add(type.element) &&
      (type.isSameAs(className, library) ||
          _extendsClass(type.superclass, seenElements, className, library));
}

extension ElementExtension on Element {
  Element get canonicalElement {
    var self = this;
    if (self is PropertyAccessorElement) {
      var variable = self.variable;
      if (variable is FieldMember) {
        // A field element defined in a parameterized type where the values of
        // the type parameters are known.
        //
        // This concept should be invisible when comparing FieldElements, but a
        // bug in the analyzer causes FieldElements to not evaluate as
        // equivalent to equivalent FieldMembers. See
        // https://github.com/dart-lang/sdk/issues/35343.
        return variable.declaration;
      } else {
        return variable;
      }
    } else {
      return self;
    }
  }
}

extension ExpressionExtension on Expression? {
  bool get isNullLiteral => this?.unParenthesized is NullLiteral;
}

extension FieldDeclarationExtension on FieldDeclaration {
  bool get isInvalidExtensionTypeField =>
      !isStatic && parent is ExtensionTypeDeclaration;
}

extension InhertanceManager3Extension on InheritanceManager3 {
  /// Returns the class member that is overridden by [member], if there is one,
  /// as defined by [getInherited].
  ExecutableElement? overriddenMember(Element? member) {
    if (member == null) {
      return null;
    }

    var interfaceElement = member.thisOrAncestorOfType<InterfaceElement>();
    if (interfaceElement == null) {
      return null;
    }
    var name = member.name;
    if (name == null) {
      return null;
    }

    var libraryUri = interfaceElement.library.source.uri;
    return getInherited(interfaceElement.thisType, Name(libraryUri, name));
  }
}

extension InterfaceElementExtension on InterfaceElement {
  /// Returns whether this element is exactly [otherName] declared in
  /// [otherLibrary].
  bool isClass(String otherName, String otherLibrary) =>
      name == otherName && library.name == otherLibrary;
}

extension InterfaceTypeExtension on InterfaceType {
  /// Returns the collection of all interfaces that this type implements,
  /// including itself.
  Iterable<InterfaceType> get implementedInterfaces {
    void searchSupertypes(
        InterfaceType? type,
        Set<InterfaceElement> alreadyVisited,
        List<InterfaceType> interfaceTypes) {
      if (type == null || !alreadyVisited.add(type.element)) {
        return;
      }
      interfaceTypes.add(type);
      searchSupertypes(type.superclass, alreadyVisited, interfaceTypes);
      for (var interface in type.interfaces) {
        searchSupertypes(interface, alreadyVisited, interfaceTypes);
      }
      for (var mixin in type.mixins) {
        searchSupertypes(mixin, alreadyVisited, interfaceTypes);
      }
    }

    var interfaceTypes = <InterfaceType>[];
    searchSupertypes(this, {}, interfaceTypes);
    return interfaceTypes;
  }
}

extension MethodDeclarationExtension on MethodDeclaration {
  bool get hasInheritedMethod => lookUpInheritedMethod() != null;

  /// Returns whether this method is an override of a method in any supertype.
  bool get isOverride {
    var name = declaredElement?.name;
    if (name == null) {
      return false;
    }
    var parentElement = declaredElement?.enclosingElement;
    if (parentElement is! InterfaceElement) {
      return false;
    }
    var parentLibrary = parentElement.library;

    if (isGetter) {
      // Search supertypes for a getter of the same name.
      return parentElement.allSupertypes
          .any((t) => t.lookUpGetter2(name, parentLibrary) != null);
    } else if (isSetter) {
      // Search supertypes for a setter of the same name.
      return parentElement.allSupertypes
          .any((t) => t.lookUpSetter2(name, parentLibrary) != null);
    } else {
      // Search supertypes for a method of the same name.
      return parentElement.allSupertypes
          .any((t) => t.lookUpMethod2(name, parentLibrary) != null);
    }
  }

  PropertyAccessorElement? lookUpGetter() {
    var declaredElement = this.declaredElement;
    if (declaredElement == null) {
      return null;
    }
    var parent = declaredElement.enclosingElement;
    if (parent is InterfaceElement) {
      return parent.lookUpGetter(name.lexeme, declaredElement.library);
    }
    if (parent is ExtensionElement) {
      return parent.getGetter(name.lexeme);
    }
    return null;
  }

  PropertyAccessorElement? lookUpInheritedConcreteGetter() {
    var declaredElement = this.declaredElement;
    if (declaredElement == null) {
      return null;
    }
    var parent = declaredElement.enclosingElement;
    if (parent is InterfaceElement) {
      return parent.lookUpInheritedConcreteGetter(
          name.lexeme, declaredElement.library);
    }
    // Extensions don't inherit.
    return null;
  }

  MethodElement? lookUpInheritedConcreteMethod() {
    var declaredElement = this.declaredElement;
    if (declaredElement != null) {
      var parent = declaredElement.enclosingElement;
      if (parent is InterfaceElement) {
        return parent.lookUpInheritedConcreteMethod(
            name.lexeme, declaredElement.library);
      }
    }
    // Extensions don't inherit.
    return null;
  }

  PropertyAccessorElement? lookUpInheritedConcreteSetter() {
    var declaredElement = this.declaredElement;
    if (declaredElement != null) {
      var parent = declaredElement.enclosingElement;
      if (parent is InterfaceElement) {
        return parent.lookUpInheritedConcreteSetter(
            name.lexeme, declaredElement.library);
      }
    }
    // Extensions don't inherit.
    return null;
  }

  MethodElement? lookUpInheritedMethod() {
    var declaredElement = this.declaredElement;
    if (declaredElement != null) {
      var parent = declaredElement.enclosingElement;
      if (parent is InterfaceElement) {
        return parent.lookUpInheritedMethod(
            name.lexeme, declaredElement.library);
      }
    }
    return null;
  }
}

extension NullableAstNodeExtension on AstNode? {
  Element? get canonicalElement {
    var self = this;
    if (self is Expression) {
      var node = self.unParenthesized;
      if (node is Identifier) {
        return node.staticElement?.canonicalElement;
      } else if (node is PropertyAccess) {
        return node.propertyName.staticElement?.canonicalElement;
      }
    }
    return null;
  }
}

extension StringExtension on String {
  String toAbsoluteNormalizedPath() {
    var pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    return pathContext.normalize(pathContext.absolute(this));
  }
}

extension TokenExtension on Token? {
  bool get isFinal => this?.keyword == Keyword.FINAL;
}

extension TokenTypeExtension on TokenType {
  TokenType get inverted => switch (this) {
        TokenType.LT_EQ => TokenType.GT_EQ,
        TokenType.LT => TokenType.GT,
        TokenType.GT => TokenType.LT,
        TokenType.GT_EQ => TokenType.LT_EQ,
        _ => this
      };
}
