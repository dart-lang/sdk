// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart' // ignore: implementation_imports
    show InvalidTypeImpl, TypeParameterTypeImpl;
import 'package:analyzer/src/utilities/extensions/ast.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart';

import 'util/scope.dart';

class EnumLikeTypeDescription {
  final Map<DartObject, Set<FieldElement>> _enumConstants;
  new(this._enumConstants);

  /// Returns a fresh map of the type's enum-like constant values.
  Map<DartObject, Set<FieldElement>> get enumConstants => {..._enumConstants};
}

/// A simple container for an interface type, by its name and its containing
/// library's "name" ('dart.core' for example).
class InterfaceTypeDefinition {
  final String name;
  final String library;

  new(this.name, this.library);

  @override
  int get hashCode => Object.hash(name, library);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is InterfaceTypeDefinition &&
        name == other.name &&
        library == other.library;
  }
}

/// Collects every reference to [target] found in the visited subtree.
class _ReferenceCollector extends RecursiveAstVisitor<void> {
  final Element target;
  final Set<AstNode> references = {};

  new(this.target);

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    _registerIfMatch(node, node.element);
    super.visitImportPrefixReference(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _registerIfMatch(node, node.element);
    super.visitSimpleIdentifier(node);
  }

  void _registerIfMatch(AstNode node, Element? element) {
    if (element == target) references.add(node);
  }
}

extension AstNodeExtension on AstNode {
  Iterable<AstNode> get childNodes => childEntities.whereType<AstNode>();

  /// The nearest enclosing function, method, or constructor body (or the
  /// compilation unit, for a top-level declaration) that `this` is declared
  /// within — the extent within which references to it can occur.
  AstNode get enclosingBody {
    for (AstNode? context = this; context != null; context = context.parent) {
      var body = switch (context) {
        MethodDeclaration(:var body) => body,
        ConstructorDeclaration(:var body) => body,
        FunctionExpression(:var body) => body,
        _ => null,
      };
      if (body != null) return body;
    }
    return thisOrAncestorOfType<CompilationUnit>() ?? this;
  }

  /// Whether this is the child of a private compilation unit member.
  bool get inPrivateMember {
    var parent = this.parent?.parent;
    return switch (parent) {
      ClassDeclaration() => parent.namePart.typeName.isPrivate,
      EnumDeclaration() => parent.namePart.typeName.isPrivate,
      ExtensionDeclaration() => parent.name == null || parent.name.isPrivate,
      ExtensionTypeDeclaration() => parent.namePart.typeName.isPrivate,
      MixinDeclaration() => parent.name.isPrivate,
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
      FunctionDeclaration() => self.augmentKeyword != null,
      FunctionExpression() => self.parent?.isAugmentation ?? false,
      MethodDeclaration() => self.augmentKeyword != null,
      MixinDeclaration() => self.augmentKeyword != null,
      TopLevelVariableDeclaration() => self.augmentKeyword != null,
      VariableDeclaration(declaredFragment: var fragment?) =>
        fragment is PropertyInducingFragment && fragment.isAugmentation,
      _ => false,
    };
  }

  bool get isEffectivelyPrivate {
    var node = this;
    if (node.isInternal) return true;
    if (node is ClassDeclaration) {
      var classElement = node.declaredFragment?.element;
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
    var self = this;
    if (self is VariableDeclaration) {
      var element = self.declaredFragment?.element;
      if (element is TopLevelVariableElement) {
        return element.metadata.hasInternal;
      }
    }

    var parent = thisOrAncestorOfType<CompilationUnitMember>();
    if (parent == null) return false;

    var metadata = parent.declaredFragment?.element.metadata;
    return metadata?.hasInternal ?? false;
  }

  /// Whether, at some reference to [element] within `this`, [newName] would
  /// already resolve to something -- either lexically (necessarily a
  /// different element, since [newName] differs from [element]'s own name),
  /// or as an accessible member of the reference's enclosing class, mixin,
  /// enum, or extension type, which -- through the implicit `this` -- takes
  /// priority over whatever [element] would be renamed to.
  bool isShadowedAtSomeReference(String newName, Element element) {
    var collector = _ReferenceCollector(element);
    accept(collector);
    return collector.references.any(
      (reference) => reference._isNameVisible(newName),
    );
  }

  bool _isNameVisible(String name) {
    var result = resolveNameInScope(name, this, shouldResolveSetter: false);
    if (result.isRequestedName) return true;

    // An import-prefix reference (as in `prefix.SomeType`) only ever names
    // an import prefix -- the grammar for a type never falls back to
    // instance-member resolution the way a bare expression identifier does.
    if (this is ImportPrefixReference) return false;

    // Neither lexical scoping nor nested declarations can see instance
    // members, which are resolved through the implicit `this`.
    var enclosingElement = enclosingInstanceElement;
    if (enclosingElement == null) return false;

    var library = enclosingElement.library;
    return (enclosingElement.lookUpGetter(name: name, library: library) ??
            enclosingElement.lookUpSetter(name: name, library: library) ??
            enclosingElement.lookUpMethod(name: name, library: library)) !=
        null;
  }
}

extension AstNodeNullableExtension on AstNode? {
  Element? get canonicalElement {
    var self = this;
    if (self is Expression) {
      var node = self.unParenthesized;
      if (node is Identifier) {
        return node.element;
      } else if (node is PropertyAccess) {
        return node.propertyName.element;
      }
    }
    return null;
  }

  /// Whether the expression is null-aware, or if one of its recursive targets
  /// is null-aware.
  bool get containsNullAwareInvocationInChain {
    var node = this;
    if (node is PropertyAccess) {
      if (node.isNullAware) return true;
      return node.target.containsNullAwareInvocationInChain;
    } else if (node is MethodInvocation) {
      if (node.isNullAware) return true;
      return node.target.containsNullAwareInvocationInChain;
    } else if (node is IndexExpression) {
      if (node.isNullAware) return true;
      return node.target.containsNullAwareInvocationInChain;
    }
    return false;
  }

  bool get isFieldNameShortcut {
    var node = this;
    if (node is NullCheckPattern) node = node.parent;
    if (node is NullAssertPattern) node = node.parent;
    return node is PatternField && node.name != null && node.name?.name == null;
  }
}

extension BlockExtension on Block {
  /// The last statement of this block, or `null` if this is empty.
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
  /// Whether this [ClassElement], or one of its supertypes, is annotated with
  /// `@Immutable`.
  bool get hasImmutableAnnotation => [
    ...allSupertypes.map((t) => t.element),
    this,
  ].any((e) => e.metadata.hasImmutable);

  bool get _hasSubclassInDefiningCompilationUnit {
    for (var cls in library.classes) {
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
}

extension ConstructorElementExtension on ConstructorElement {
  /// Whether this [ConstructorElement] is the same constructor as the
  /// [className] constructor named [constructorName] declared in [uri].
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
  /// Returns the type which should be used when conducting "interface checks"
  /// on `this`.
  ///
  /// If `this` is a type variable, then the type-for-interface-check of its
  /// promoted bound or bound is returned. Otherwise, `this` is returned.
  DartType? get typeForInterfaceCheck {
    var self = this;
    if (self == null) return null;
    if (self is! TypeParameterType) return self.extensionTypeErasure;

    var promotedType = (self as TypeParameterTypeImpl).promotedBound;
    if (promotedType != null) {
      return promotedType.typeForInterfaceCheck;
    }
    return self.bound.typeForInterfaceCheck;
  }

  /// Whether this [DartType] extends [className], declared in [library].
  bool extendsClass(String? className, String library) {
    var self = this?.typeForInterfaceCheck;
    return self is InterfaceType &&
        _extendsClass(self, <InterfaceElement>{}, className, library);
  }

  /// Whether this [DartType] implements any of [definitions].
  bool implementsAnyInterface(Iterable<InterfaceTypeDefinition> definitions) {
    var typeToCheck = this?.typeForInterfaceCheck;
    if (typeToCheck is! InterfaceType) return false;

    bool isAnyInterface(InterfaceType i) =>
        definitions.any((d) => i.isSameAs(d.name, d.library));

    return isAnyInterface(typeToCheck) ||
        typeToCheck.element.allSupertypes.any(isAnyInterface);
  }

  /// Whether this [DartType] implements [interface], declared in [library].
  bool implementsInterface(String interface, String library) {
    var typeToCheck = this?.typeForInterfaceCheck;
    if (typeToCheck is! InterfaceType) return false;
    if (typeToCheck.isSameAs(interface, library)) return true;
    return typeToCheck.element.allSupertypes.any(
      (i) => i.isSameAs(interface, library),
    );
  }

  /// Whether this [DartType] is the same element as [interface], declared in
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
    String? library,
  ) =>
      type != null &&
      seenElements.add(type.element) &&
      (type.isSameAs(className, library) ||
          _extendsClass(type.superclass, seenElements, className, library));
}

extension ElementAnnotationExtension on ElementAnnotation {
  bool get isReflectiveTest => switch (element) {
    GetterElement(:var name, :var library) =>
      name == 'reflectiveTest' &&
          library.uri.toString() ==
              'package:test_reflective_loader/test_reflective_loader.dart',
    _ => false,
  };
}

extension ElementExtension on Element? {
  Element? get canonicalElement2 => switch (this) {
    PropertyAccessorElement(:var variable) => variable,
    _ => this,
  };

  /// Whether this is annotated with `@awaitNotRequired`.
  bool get hasAwaitNotRequired {
    var self = this;
    if (self == null) {
      return false;
    }
    return self.metadata.hasAwaitNotRequired ||
        (self is PropertyAccessorElement && self.variable.hasAwaitNotRequired);
  }

  bool get isDartCorePrint {
    var self = this;
    return self is TopLevelFunctionElement &&
        self.name == 'print' &&
        self.library.isDartCore;
  }

  /// Returns the class member that is overridden by `this`, if there is one,
  /// as defined by [InterfaceElement.getInheritedMember].
  ExecutableElement? get overriddenMember {
    var member = switch (this) {
      FieldElement(:var getter) => getter,
      MethodElement method => method,
      PropertyAccessorElement accessor => accessor,
      _ => null,
    };

    if (member == null) return null;

    var interfaceElement = member.enclosingElement;
    if (interfaceElement is! InterfaceElement) return null;

    var name = Name.forElement(member);
    if (name == null) return null;

    return interfaceElement.getInheritedMember(name);
  }
}

extension ExpressionExtension on Expression {
  /// Returns whether `await` is not required for this expression.
  bool get isAwaitNotRequired {
    var element = switch (this) {
      BinaryExpression(:var element) => element,
      MethodInvocation(:var methodName) => methodName.element,
      PrefixedIdentifier(:var identifier) => identifier.element,
      PrefixExpression(:var element) => element,
      PropertyAccess(:var propertyName) => propertyName.element,
      _ => null,
    };

    // This handles `p();` where `p` is a parameter typed with a typedef which
    // is annotated with `@awaitNotRequired`.
    if (this case FunctionExpressionInvocation self) {
      if (self.function.staticType?.alias case var alias?) {
        if (alias.element.hasAwaitNotRequired) {
          return true;
        }
      }
    }

    if (element == null) return false;
    if (element.hasAwaitNotRequired) return true;

    var elementName = element.name;
    if (elementName == null) return false;

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return false;

    var superTypes = enclosingElement.allSupertypes;
    var superMembers = element is MethodElement
        ? superTypes.map((t) => t.getMethod(elementName))
        : superTypes.map((t) => t.getGetter(elementName));
    return superMembers.any((e) => e.hasAwaitNotRequired);
  }
}

extension ExpressionNullableExtension on Expression? {
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
        return self.correspondingParameter?.type ?? InvalidTypeImpl.instance;
      case AssignmentExpression():
        // Allow `x = LinkedHashMap()`.
        return ancestor.staticType;
      case BinaryExpression(:var operator)
          when operator.type == TokenType.QUESTION_QUESTION:
        return ancestor.approximateContextType;
      case ConditionalExpression():
        return ancestor.staticType;
      case ConstructorFieldInitializer():
        var fieldElement = ancestor.fieldName.element;
        return (fieldElement is VariableElement) ? fieldElement.type : null;
      case ExpressionFunctionBody(parent: FunctionExpression function):
        // Allow `<int, LinkedHashSet>{}.putIfAbsent(3, () => LinkedHashSet())`
        // and `<int, LinkedHashMap>{}.putIfAbsent(3, () => LinkedHashMap())`.
        var functionParent = function.parent;
        if (functionParent is FunctionDeclaration) {
          return functionParent.returnType?.type;
        }
        var functionType = function.approximateContextType;
        return functionType is FunctionType ? functionType.returnType : null;
      case ExpressionFunctionBody(parent: ConstructorDeclaration constructor):
        return constructor.declaredFragment!.element.returnType;
      case ExpressionFunctionBody(parent: FunctionDeclaration function):
        return function.returnType?.type;
      case ExpressionFunctionBody(parent: MethodDeclaration function):
        return function.returnType?.type;
      case NamedArgument():
        // Allow `void f({required LinkedHashSet<Foo> s})`.
        return ancestor.correspondingParameter?.type ??
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
      !isStatic && parent?.parent is ExtensionTypeDeclaration;
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
        var returnType = grandparent.declaredFragment?.element.returnType;
        return self._expectedReturnableOrYieldableType(returnType);
      }
      var functionType = parent.approximateContextType;
      if (functionType is! FunctionType) return null;
      var returnType = functionType.returnType;
      return self._expectedReturnableOrYieldableType(returnType);
    }
    if (parent is MethodDeclaration) {
      var returnType = parent.declaredFragment?.element.returnType;
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

extension InstanceElementExtension on InstanceElement {
  bool get isReflectiveTest =>
      this is ClassElement &&
      metadata.annotations.any((a) => a.isReflectiveTest);
}

extension InterfaceElementExtension on InterfaceElement {
  /// Returns an [EnumLikeTypeDescription] if this is a valid "enum-like" type.
  ///
  /// An enum-like type must be either a class or an extension type and meet the
  /// following requirements:
  ///
  /// * if a class, is concrete,
  /// * has no public constructors,
  /// * has no factory constructors,
  /// * has two or more static const fields with the same enclosing type,
  /// * if a class, has no subclasses declared in the defining library.
  ///
  /// The returned [EnumLikeTypeDescription]'s `enumConstants` contains all of
  /// the static const fields with the same enclosing type, with one
  /// exception; any static const field which is marked `@Deprecated` and is
  /// equal to another such field is grouped with that field. Such a field is
  /// assumed to be deprecated in favor of the field with equal value.
  EnumLikeTypeDescription? asEnumLikeType() {
    // See discussion: https://github.com/dart-lang/linter/issues/2083.

    switch (this) {
      case ClassElement self:
        // Must be concrete and have no subclasses in the defining library.
        if (self.isAbstract || self._hasSubclassInDefiningCompilationUnit) {
          return null;
        }
      case ExtensionTypeElement():
        break;
      default:
        return null;
    }

    // With only private generative constructors.
    if (!constructors.every((c) => c.isPrivate && c.isGenerative)) {
      return null;
    }

    // And 2 or more static const fields whose type is the enclosing type.
    var enumConstantCount = 0;
    var enumConstants = <DartObject, Set<FieldElement>>{};
    for (var field in fields) {
      // Ensure static const.
      if (field.isOriginGetterSetter || !field.isConst || !field.isStatic) {
        continue;
      }
      // Check for type equality.
      if (field.type != thisType) {
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

    return EnumLikeTypeDescription(enumConstants);
  }

  bool isEnumLikeType() => asEnumLikeType() != null;
}

extension InterfaceTypeExtension on InterfaceType {
  /// Returns the collection of all interfaces that this type implements,
  /// including itself.
  Iterable<InterfaceType> get implementedInterfaces {
    void searchSupertypes(
      InterfaceType? type,
      Set<InterfaceElement> alreadyVisited,
      List<InterfaceType> interfaceTypes,
    ) {
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

  GetterElement? getGetter2(String name, {LibraryElement? library}) =>
      getters.firstWhereOrNull(
        (s) => s.name == name && (library == null || (s.library == library)),
      );

  SetterElement? getSetter2(String name) =>
      setters.firstWhereOrNull((s) => s.canonicalName == name);
}

extension MethodDeclarationExtension on MethodDeclaration {
  bool get hasInheritedMethod => lookUpInheritedMethod() != null;

  /// Returns whether this method is an override of a method in any supertype.
  bool get isOverride {
    var element = declaredFragment?.element;

    var name = element?.name;
    if (name == null) return false;

    var parentElement = element?.enclosingElement;
    if (parentElement is! InterfaceElement) return false;

    var parentLibrary = parentElement.library;

    if (isGetter) {
      // Search supertypes for a getter of the same name.
      return parentElement.allSupertypes.any(
        (t) => t.lookUpGetter(name, parentLibrary) != null,
      );
    } else if (isSetter) {
      // Search supertypes for a setter of the same name.
      return parentElement.allSupertypes.any(
        (t) => t.lookUpSetter(name, parentLibrary) != null,
      );
    } else {
      // Search supertypes for a method of the same name.
      return parentElement.allSupertypes.any(
        (t) => t.lookUpMethod(name, parentLibrary) != null,
      );
    }
  }

  MethodElement? lookUpInheritedMethod() {
    var declaredElement = declaredFragment?.element;
    if (declaredElement != null) {
      var parent = declaredElement.enclosingElement;
      if (parent is InterfaceElement) {
        var methodName = Name.forElement(declaredElement);
        if (methodName == null) return null;
        var inherited = parent.getInheritedMember(methodName);
        if (inherited is InternalMethodElement) return inherited;
      }
    }
    return null;
  }
}

extension NullableObjectExtension on Object? {
  /// If the target is [T], return it, otherwise `null`.
  // TODO(scheglov): consider using the same method from the analyzer.
  T? tryCast<T>() => switch (this) {
    T value => value,
    _ => null,
  };
}

extension SetterElementExtension on SetterElement {
  /// Return name in a format suitable for string comparison.
  String? get canonicalName {
    var name = this.name;
    if (name == null) return null;
    // TODO(pq): remove when `name3` consistently does not include a trailing `=`.
    return name.endsWith('=') ? name.substring(0, name.length - 1) : name;
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
    return self != null && Identifier.isPrivateName(self.lexeme);
  }
}

extension TokenTypeExtension on TokenType {
  TokenType get inverted => switch (this) {
    TokenType.LT_EQ => TokenType.GT_EQ,
    TokenType.LT => TokenType.GT,
    TokenType.GT => TokenType.LT,
    TokenType.GT_EQ => TokenType.LT_EQ,
    _ => this,
  };
}
