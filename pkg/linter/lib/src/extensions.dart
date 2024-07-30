// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/member.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart' // ignore: implementation_imports
    show
        InvalidTypeImpl;
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

  /// Whether this is the child of a private compilation unit member.
  bool get inPrivateMember {
    var parent = this.parent;
    return switch (parent) {
      NamedCompilationUnitMember() => parent.name.isPrivate,
      ExtensionDeclaration() => parent.name == null || parent.name.isPrivate,
      _ => false,
    };
  }

  bool get isAugmentation {
    var self = this;
    return switch (self) {
      ClassDeclaration() => self.augmentKeyword != null,
      ConstructorDeclaration() => self.augmentKeyword != null,
      EnumConstantDeclaration() => self.augmentKeyword != null,
      EnumDeclaration() => self.augmentKeyword != null,
      ExtensionTypeDeclaration() => self.augmentKeyword != null,
      FieldDeclaration() => self.augmentKeyword != null,
      FunctionDeclarationImpl() => self.augmentKeyword != null,
      FunctionExpression() => self.parent?.isAugmentation ?? false,
      MethodDeclaration() => self.augmentKeyword != null,
      MixinDeclaration() => self.augmentKeyword != null,
      TopLevelVariableDeclaration() => self.augmentKeyword != null,
      VariableDeclaration(declaredElement: var element) =>
        element is PropertyInducingElement && element.isAugmentation,
      _ => false
    };
  }

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
}

extension AstNodeNullableExtension on AstNode? {
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
  /// Get all accessors, including merged augmentations.
  List<PropertyAccessorElement> get allAccessors => augmented.accessors;

  /// Get all constructors, including merged augmentations.
  List<ConstructorElement> get allConstructors => augmented.constructors;

  /// Get all fields, including merged augmentations.
  List<FieldElement> get allFields => augmented.fields;

  /// Get all interfaces, including merged augmentations.
  List<InterfaceType> get allInterfaces => augmented.interfaces;

  /// Get all methods, including merged augmentations.
  List<MethodElement> get allMethods => augmented.methods;

  /// Get all mixins, including merged augmentations.
  List<InterfaceType> get allMixins => augmented.mixins;

  bool get hasImmutableAnnotation {
    var inheritedAndSelfElements = <InterfaceElement>[
      ...allSupertypes.map((t) => t.element),
      this,
    ];

    return inheritedAndSelfElements.any((e) => e.hasImmutable);

    // TODO(pq): update when implemented or replace w/ a better has{*} call
    // https://github.com/dart-lang/linter/issues/4939
    //return inheritedAndSelfElements.any((e) => e.augmented.metadata.any((e) => e.isImmutable));
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
  EnumLikeClassDescription? asEnumLikeClass() {
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

  /// Returns whether this class is exactly [otherName] declared in
  /// [otherLibrary].
  bool isClass(String otherName, String otherLibrary) =>
      name == otherName && library.name == otherLibrary;

  bool isEnumLikeClass() => asEnumLikeClass() != null;
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
      var variable = self.variable2;
      if (variable is FieldMember) {
        // A field element defined in a parameterized type where the values of
        // the type parameters are known.
        //
        // This concept should be invisible when comparing FieldElements, but a
        // bug in the analyzer causes FieldElements to not evaluate as
        // equivalent to equivalent FieldMembers. See
        // https://github.com/dart-lang/sdk/issues/35343.
        return variable.declaration;
      } else if (variable != null) {
        return variable;
      }
    }
    return self;
  }

  bool get isMacro {
    var self = this;
    return self is ClassElementImpl && self.isMacro;
  }
}

extension ExpressionExtension on Expression? {
  /// A very, very, very rough approximation of the context type of this node.
  ///
  /// This approximation will never be accurate for some expressions.
  DartType? get approximateContextType {
    var self = this;
    if (self == null) return null;
    var ancestor = self.parent;
    var ancestorChild = self;
    while (ancestor != null) {
      if (ancestor is ParenthesizedExpression) {
        ancestorChild = ancestor;
        ancestor = ancestor.parent;
      } else if (ancestor is CascadeExpression &&
          ancestorChild == ancestor.target) {
        ancestorChild = ancestor;
        ancestor = ancestor.parent;
      } else {
        break;
      }
    }

    switch (ancestor) {
      // TODO(srawlins): Handle [AwaitExpression], [BinaryExpression],
      // [CascadeExpression], [SwitchExpressionCase], likely others. Or move
      // everything here to an analysis phase which has the actual context type.
      case ArgumentList():
        // Allow `function(LinkedHashSet())` for `function(LinkedHashSet mySet)`
        // and `function(LinkedHashMap())` for `function(LinkedHashMap myMap)`.
        return self.staticParameterElement?.type ?? InvalidTypeImpl.instance;
      case AssignmentExpression():
        // Allow `x = LinkedHashMap()`.
        return ancestor.staticType;
      case ConditionalExpression():
        return ancestor.staticType;
      case ConstructorFieldInitializer():
        var fieldElement = ancestor.fieldName.staticElement;
        return (fieldElement is VariableElement) ? fieldElement.type : null;
      case ExpressionFunctionBody(parent: var function)
          when function is FunctionExpression:
        // Allow `<int, LinkedHashSet>{}.putIfAbsent(3, () => LinkedHashSet())`
        // and `<int, LinkedHashMap>{}.putIfAbsent(3, () => LinkedHashMap())`.
        var functionParent = function.parent;
        if (functionParent is FunctionDeclaration) {
          return functionParent.returnType?.type;
        }
        var functionType = function.approximateContextType;
        return functionType is FunctionType ? functionType.returnType : null;
      case ExpressionFunctionBody(parent: var function)
          when function is FunctionDeclaration:
        return function.returnType?.type;
      case ExpressionFunctionBody(parent: var function)
          when function is MethodDeclaration:
        return function.returnType?.type;
      case NamedExpression():
        // Allow `void f({required LinkedHashSet<Foo> s})`.
        return ancestor.staticParameterElement?.type ??
            InvalidTypeImpl.instance;
      case ReturnStatement():
        return ancestor.thisOrAncestorOfType<FunctionBody>().expectedReturnType;
      case VariableDeclaration(parent: VariableDeclarationList(:var type)):
        // Allow `LinkedHashSet<int> s = node` and
        // `LinkedHashMap<int> s = node`.
        return type?.type;
      case YieldStatement():
        return ancestor.thisOrAncestorOfType<FunctionBody>().expectedReturnType;
    }

    return null;
  }

  bool get isNullLiteral => this?.unParenthesized is NullLiteral;
}

extension FieldDeclarationExtension on FieldDeclaration {
  bool get isInvalidExtensionTypeField =>
      !isStatic && parent is ExtensionTypeDeclaration;
}

extension FunctionBodyExtension on FunctionBody? {
  /// Attempts to calculate the expected return type of the function represented
  /// by this node, accounting for an approximation of the function's context
  /// type, in the case of a function literal.
  DartType? get expectedReturnType {
    var self = this;
    if (self == null) return null;
    var parent = self.parent;
    if (parent is FunctionExpression) {
      var grandparent = parent.parent;
      if (grandparent is FunctionDeclaration) {
        var returnType = grandparent.declaredElement?.returnType;
        return self._expectedReturnableOrYieldableType(returnType);
      }
      var functionType = parent.approximateContextType;
      if (functionType is! FunctionType) return null;
      var returnType = functionType.returnType;
      return self._expectedReturnableOrYieldableType(returnType);
    }
    if (parent is MethodDeclaration) {
      var returnType = parent.declaredElement?.returnType;
      return self._expectedReturnableOrYieldableType(returnType);
    }
    return null;
  }

  /// Extracts the expected type for return statements or yield statements.
  ///
  /// For example, for an asynchronous body in a function with a declared
  /// [returnType] of `Future<int>`, this returns `int`. (Note: it would be more
  /// accurate to use `FutureOr<int>` and an assignability check, but `int` is
  /// an approximation that works for now; this should probably be revisited.)
  DartType? _expectedReturnableOrYieldableType(DartType? returnType) {
    var self = this;
    if (self == null) return null;
    if (returnType is! InterfaceType) return null;
    if (self.isAsynchronous) {
      if (!self.isGenerator && returnType.isDartAsyncFuture) {
        return returnType.typeArguments.firstOrNull;
      }
      if (self.isGenerator && returnType.isDartAsyncStream) {
        return returnType.typeArguments.firstOrNull;
      }
    } else {
      if (self.isGenerator && returnType.isDartCoreIterable) {
        return returnType.typeArguments.firstOrNull;
      }
    }
    return returnType;
  }
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
      return parent.augmented
          .lookUpGetter(name: name.lexeme, library: declaredElement.library);
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

extension StringExtension on String {
  String toAbsoluteNormalizedPath() {
    var pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    return pathContext.normalize(pathContext.absolute(this));
  }
}

extension TokenExtension on Token? {
  bool get isFinal => this?.keyword == Keyword.FINAL;

  /// Whether the given identifier has a private name.
  bool get isPrivate {
    var self = this;
    return self != null ? Identifier.isPrivateName(self.lexeme) : false;
  }
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
