// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/element/type.dart' // ignore: implementation_imports
    show
        InvalidTypeImpl;
import 'package:collection/collection.dart';

import 'analyzer.dart';
import 'util/dart_type_utilities.dart';

class EnumLikeClassDescription {
  final Map<DartObject, Set<FieldElement2>> _enumConstants;
  EnumLikeClassDescription(this._enumConstants);

  /// Returns a fresh map of the class's enum-like constant values.
  Map<DartObject, Set<FieldElement2>> get enumConstants => {..._enumConstants};
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
      VariableDeclaration(declaredFragment: var fragment?) =>
        fragment is PropertyInducingFragment && fragment.isAugmentation,
      _ => false
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
    var parent = thisOrAncestorOfType<CompilationUnitMember>();
    if (parent == null) return false;

    return switch (parent.declaredFragment?.element) {
      Annotatable(:var metadata2) => metadata2.hasInternal,
      _ => false,
    };
  }
}

extension AstNodeNullableExtension on AstNode? {
  Element2? get canonicalElement {
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

extension ClassElementExtension on ClassElement2 {
  bool get hasImmutableAnnotation {
    var inheritedAndSelfElements = <InterfaceElement2>[
      ...allSupertypes.map((t) => t.element3),
      this,
    ];

    return inheritedAndSelfElements.any((e) => e.metadata2.hasImmutable);

    // TODO(pq): update when implemented or replace w/ a better has{*} call
    // https://github.com/dart-lang/linter/issues/4939
    //return inheritedAndSelfElements.any((e) => e.augmented.metadata.any((e) => e.isImmutable));
  }

  bool get hasSubclassInDefiningCompilationUnit {
    for (var cls in library2.classes) {
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
    for (var constructor in constructors2) {
      if (!constructor.isPrivate || constructor.isFactory) {
        return null;
      }
    }

    var type = thisType;

    // And 2 or more static const fields whose type is the enclosing class.
    var enumConstantCount = 0;
    var enumConstants = <DartObject, Set<FieldElement2>>{};
    for (var field in fields2) {
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

  bool isEnumLikeClass() => asEnumLikeClass() != null;
}

extension ClassMemberListExtension on List<ClassMember> {
  MethodDeclaration? getMethod(String name) => whereType<MethodDeclaration>()
      .firstWhereOrNull((node) => node.name.lexeme == name);
}

extension ConstructorElementExtension on ConstructorElement2 {
  /// Returns whether `this` is the same element as the [className] constructor
  /// named [constructorName] declared in [uri].
  bool isSameAs({
    required String uri,
    required String className,
    required String constructorName,
  }) =>
      library2.name3 == uri &&
      enclosingElement2.name3 == className &&
      name3 == constructorName;
}

extension DartTypeExtension on DartType? {
  bool extendsClass(String? className, String library) {
    var self = this;
    if (self is InterfaceType) {
      return _extendsClass(self, <InterfaceElement2>{}, className, library);
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
          !typeToCheck.element3.isSynthetic &&
              typeToCheck.element3.allSupertypes.any(isAnyInterface);
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
    var element = self.element3;
    return predicate(self) ||
        !element.isSynthetic && element.allSupertypes.any(predicate);
  }

  /// Returns whether `this` is the same element as [interface], declared in
  /// [library].
  bool isSameAs(String? interface, String? library) {
    var self = this;
    return self is InterfaceType &&
        self.element3.name3 == interface &&
        self.element3.library2.name3 == library;
  }

  static bool _extendsClass(
          InterfaceType? type,
          Set<InterfaceElement2> seenElements,
          String? className,
          String? library) =>
      type != null &&
      seenElements.add(type.element3) &&
      (type.isSameAs(className, library) ||
          _extendsClass(type.superclass, seenElements, className, library));
}

extension ElementExtension on Element2? {
  Element2? get canonicalElement2 => switch (this) {
        PropertyAccessorElement2(:var variable3?) => variable3,
        _ => this,
      };

  bool get isDartCorePrint {
    var self = this;
    return self is TopLevelFunctionElement &&
        self.name3 == 'print' &&
        self.firstFragment.libraryFragment.element.isDartCore;
  }

  bool get isMacro => switch (this) {
        ClassElement2(:var isMacro) => isMacro,
        _ => false,
      };
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
        return self.correspondingParameter?.type ?? InvalidTypeImpl.instance;
      case AssignmentExpression():
        // Allow `x = LinkedHashMap()`.
        return ancestor.staticType;
      case ConditionalExpression():
        return ancestor.staticType;
      case ConstructorFieldInitializer():
        var fieldElement = ancestor.fieldName.element;
        return (fieldElement is VariableElement2) ? fieldElement.type : null;
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

extension InhertanceManager3Extension on InheritanceManager3 {
  /// Returns the class member that is overridden by [member], if there is one,
  /// as defined by [getInherited].
  ExecutableElement2? overriddenMember(Element2? member) {
    var executable = switch (member) {
      FieldElement2() => member.getter2,
      MethodElement2() => member,
      PropertyAccessorElement2() => member,
      _ => null,
    };

    if (executable == null) return null;

    var interfaceElement = executable.enclosingElement2;
    if (interfaceElement is! InterfaceElement2) return null;

    var nameObj = Name.forElement(executable);
    if (nameObj == null) return null;

    return getInherited3(interfaceElement.thisType, nameObj);
  }
}

extension InterfaceElementExtension on InterfaceElement2 {
  /// Whether this element has the exact [name] and defined in the file with
  /// the given [uri].
  bool isExactly(String name, Uri uri) =>
      name3 == name && enclosingElement2.uri == uri;
}

extension InterfaceTypeExtension on InterfaceType {
  /// Returns the collection of all interfaces that this type implements,
  /// including itself.
  Iterable<InterfaceType> get implementedInterfaces {
    void searchSupertypes(
        InterfaceType? type,
        Set<InterfaceElement2> alreadyVisited,
        List<InterfaceType> interfaceTypes) {
      if (type == null || !alreadyVisited.add(type.element3)) {
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

  GetterElement? getGetter2(String name, {LibraryElement2? library}) =>
      getters.firstWhereOrNull((s) =>
          s.name3 == name && (library == null || (s.library2 == library)));

  SetterElement? getSetter2(String name) =>
      setters.firstWhereOrNull((s) => s.canonicalName == name);
}

extension LinterContextExtension on LinterContext {
  /// Whether the given [feature] is enabled in this linter context.
  bool isEnabled(Feature feature) =>
      libraryElement2!.featureSet.isEnabled(feature);
}

extension MethodDeclarationExtension on MethodDeclaration {
  /// Returns whether this method is an override of a method in any supertype.
  bool get isOverride {
    var element = declaredFragment?.element;

    var name = element?.name3;
    if (name == null) return false;

    var parentElement = element?.enclosingElement2;
    if (parentElement is! InterfaceElement2) return false;

    var parentLibrary = parentElement.library2;

    if (isGetter) {
      // Search supertypes for a getter of the same name.
      return parentElement.allSupertypes
          .any((t) => t.lookUpGetter3(name, parentLibrary) != null);
    } else if (isSetter) {
      // Search supertypes for a setter of the same name.
      return parentElement.allSupertypes
          .any((t) => t.lookUpSetter3(name, parentLibrary) != null);
    } else {
      // Search supertypes for a method of the same name.
      return parentElement.allSupertypes
          .any((t) => t.lookUpMethod3(name, parentLibrary) != null);
    }
  }

  bool hasInheritedMethod(InheritanceManager3 inheritanceManager) =>
      lookUpInheritedMethod(inheritanceManager) != null;

  MethodElement2? lookUpInheritedMethod(
      InheritanceManager3 inheritanceManager) {
    var declaredElement = declaredFragment?.element;
    if (declaredElement != null) {
      var parent = declaredElement.enclosingElement2;
      if (parent is InterfaceElement2) {
        var methodName = Name.forElement(declaredElement);
        if (methodName == null) return null;
        var inherited = inheritanceManager.getInherited4(parent, methodName);
        if (inherited is MethodElement2) return inherited;
      }
    }
    return null;
  }
}

extension SetterElementExtension on SetterElement {
  /// Return name in a format suitable for string comparison.
  String? get canonicalName {
    var name = name3;
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
