// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

/**
 * A constructor element defined in a parameterized type where the values of the
 * type parameters are known.
 */
class ConstructorMember extends ExecutableMember implements ConstructorElement {
  /**
   * Initialize a newly created element to represent a constructor, based on
   * the [baseElement], and applied [substitution].
   */
  ConstructorMember(
    ConstructorElement baseElement,
    MapSubstitution substitution,
  ) : super(baseElement, substitution);

  @override
  ConstructorElement get baseElement => super.baseElement as ConstructorElement;

  @override
  ClassElement get enclosingElement => baseElement.enclosingElement;

  @override
  bool get isConst => baseElement.isConst;

  @override
  bool get isConstantEvaluated => baseElement.isConstantEvaluated;

  @override
  bool get isDefaultConstructor => baseElement.isDefaultConstructor;

  @override
  bool get isFactory => baseElement.isFactory;

  @override
  int get nameEnd => baseElement.nameEnd;

  @override
  int get periodOffset => baseElement.periodOffset;

  @override
  ConstructorElement get redirectedConstructor {
    var definingType = _substitution.substituteType(enclosingElement.thisType);
    return from(baseElement.redirectedConstructor, definingType);
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @deprecated
  @override
  ConstructorDeclaration computeNode() => baseElement.computeNode();

  @override
  String toString() {
    ConstructorElement baseElement = this.baseElement;
    List<ParameterElement> parameters = this.parameters;
    FunctionType type = this.type;

    StringBuffer buffer = StringBuffer();
    if (type != null) {
      buffer.write(type.returnType);
      buffer.write(' ');
    }
    buffer.write(baseElement.enclosingElement.displayName);
    String name = displayName;
    if (name != null && name.isNotEmpty) {
      buffer.write('.');
      buffer.write(name);
    }
    buffer.write('(');
    int parameterCount = parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        buffer.write(', ');
      }
      buffer.write(parameters[i]);
    }
    buffer.write(')');
    return buffer.toString();
  }

  /**
   * If the given [constructor]'s type is different when any type parameters
   * from the defining type's declaration are replaced with the actual type
   * arguments from the [definingType], create a constructor member representing
   * the given constructor. Return the member that was created, or the original
   * constructor if no member was created.
   */
  static ConstructorElement from(
      ConstructorElement constructor, InterfaceType definingType) {
    if (constructor == null || definingType.typeArguments.isEmpty) {
      return constructor;
    }
    FunctionType baseType = constructor.type;
    if (baseType == null) {
      // TODO(brianwilkerson) We need to understand when this can happen.
      return constructor;
    }
    return ConstructorMember(
      constructor,
      Substitution.fromInterfaceType(definingType),
    );
  }
}

/**
 * An executable element defined in a parameterized type where the values of the
 * type parameters are known.
 */
abstract class ExecutableMember extends Member implements ExecutableElement {
  FunctionType _type;

  /**
   * Initialize a newly created element to represent a callable element (like a
   * method or function or property), based on the [baseElement], and applied
   * [substitution].
   */
  ExecutableMember(
    ExecutableElement baseElement,
    MapSubstitution substitution,
  ) : super(baseElement, substitution);

  @override
  ExecutableElement get baseElement => super.baseElement as ExecutableElement;

  @override
  bool get hasImplicitReturnType => baseElement.hasImplicitReturnType;

  @override
  bool get isAbstract => baseElement.isAbstract;

  @override
  bool get isAsynchronous => baseElement.isAsynchronous;

  @override
  bool get isExternal => baseElement.isExternal;

  @override
  bool get isGenerator => baseElement.isGenerator;

  @override
  bool get isOperator => baseElement.isOperator;

  @override
  bool get isSimplyBounded => baseElement.isSimplyBounded;

  @override
  bool get isStatic => baseElement.isStatic;

  @override
  bool get isSynchronous => baseElement.isSynchronous;

  @override
  List<ParameterElement> get parameters {
    return baseElement.parameters.map((p) {
      if (p is FieldFormalParameterElement) {
        return FieldFormalParameterMember(p, _substitution);
      }
      return ParameterMember(p, _substitution);
    }).toList();
  }

  @override
  DartType get returnType => type.returnType;

  @override
  FunctionType get type {
    if (_type != null) return _type;

    return _type = _substitution.substituteType(baseElement.type);
  }

  @override
  List<TypeParameterElement> get typeParameters {
    return TypeParameterMember.from2(
      baseElement.typeParameters,
      _substitution,
    );
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // TODO(brianwilkerson) We need to finish implementing the accessors used
    // below so that we can safely invoke them.
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }

  static ExecutableElement from2(
    ExecutableElement element,
    MapSubstitution substitution,
  ) {
    var combined = substitution;
    if (element is ExecutableMember) {
      ExecutableMember member = element;
      element = member.baseElement;
      var map = <TypeParameterElement, DartType>{};
      map.addAll(member._substitution.map);
      map.addAll(substitution.map);
      combined = Substitution.fromMap(map);
    }

    if (combined.map.isEmpty) {
      return element;
    }

    if (element is ConstructorElement) {
      return ConstructorMember(element, combined);
    } else if (element is MethodElement) {
      return MethodMember(element, combined);
    } else if (element is PropertyAccessorElement) {
      return PropertyAccessorMember(element, combined);
    } else {
      throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }
}

/**
 * A parameter element defined in a parameterized type where the values of the
 * type parameters are known.
 */
class FieldFormalParameterMember extends ParameterMember
    implements FieldFormalParameterElement {
  /**
   * Initialize a newly created element to represent a field formal parameter,
   * based on the [baseElement], with applied [substitution].
   */
  FieldFormalParameterMember(
    FieldFormalParameterElement baseElement,
    MapSubstitution substitution,
  ) : super(baseElement, substitution);

  @override
  FieldElement get field {
    var field = (baseElement as FieldFormalParameterElement).field;
    if (field == null) {
      return null;
    }

    return FieldMember(field, _substitution);
  }

  @override
  bool get isCovariant => baseElement.isCovariant;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/**
 * A field element defined in a parameterized type where the values of the type
 * parameters are known.
 */
class FieldMember extends VariableMember implements FieldElement {
  /**
   * Initialize a newly created element to represent a field, based on the
   * [baseElement], with applied [substitution].
   */
  FieldMember(
    FieldElement baseElement,
    MapSubstitution substitution,
  ) : super(baseElement, substitution);

  @override
  FieldElement get baseElement => super.baseElement as FieldElement;

  @override
  Element get enclosingElement => baseElement.enclosingElement;

  @override
  PropertyAccessorElement get getter {
    var baseGetter = baseElement.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseGetter, _substitution);
  }

  @override
  bool get isCovariant => baseElement.isCovariant;

  @override
  bool get isEnumConstant => baseElement.isEnumConstant;

  @deprecated
  @override
  bool get isVirtual => baseElement.isVirtual;

  @deprecated
  @override
  DartType get propagatedType => null;

  @override
  PropertyAccessorElement get setter {
    var baseSetter = baseElement.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseSetter, _substitution);
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);

  @deprecated
  @override
  VariableDeclaration computeNode() => baseElement.computeNode();

  @override
  String toString() => '$type $displayName';

  /**
   * If the given [field]'s type is different when any type parameters from the
   * defining type's declaration are replaced with the actual type arguments
   * from the [definingType], create a field member representing the given
   * field. Return the member that was created, or the base field if no member
   * was created.
   */
  static FieldElement from(FieldElement field, InterfaceType definingType) {
    if (field == null || definingType.typeArguments.isEmpty) {
      return field;
    }
    return FieldMember(
      field,
      Substitution.fromInterfaceType(definingType),
    );
  }

  static FieldElement from2(
    FieldElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return FieldMember(element, substitution);
  }
}

/**
 * An element defined in a parameterized type where the values of the type
 * parameters are known.
 */
abstract class Member implements Element {
  /**
   * The element on which the parameterized element was created.
   */
  final Element _baseElement;

  /**
   * The substitution for type parameters referenced in the base element.
   */
  final MapSubstitution _substitution;

  /**
   * Initialize a newly created element to represent a member, based on the
   * [baseElement], and applied [_substitution].
   */
  Member(this._baseElement, this._substitution);

  /**
   * Return the element on which the parameterized element was created.
   */
  Element get baseElement => _baseElement;

  @override
  AnalysisContext get context => _baseElement.context;

  @override
  String get displayName => _baseElement.displayName;

  @override
  String get documentationComment => _baseElement.documentationComment;

  @override
  bool get hasAlwaysThrows => _baseElement.hasAlwaysThrows;

  @override
  bool get hasDeprecated => _baseElement.hasDeprecated;

  @override
  bool get hasFactory => _baseElement.hasFactory;

  @override
  bool get hasIsTest => _baseElement.hasIsTest;

  @override
  bool get hasIsTestGroup => _baseElement.hasIsTestGroup;

  @override
  bool get hasJS => _baseElement.hasJS;

  @override
  bool get hasLiteral => _baseElement.hasLiteral;

  @override
  bool get hasMustCallSuper => _baseElement.hasMustCallSuper;

  @override
  bool get hasOptionalTypeArgs => _baseElement.hasOptionalTypeArgs;

  @override
  bool get hasOverride => _baseElement.hasOverride;

  @override
  bool get hasProtected => _baseElement.hasProtected;

  @override
  bool get hasRequired => _baseElement.hasRequired;

  @override
  bool get hasSealed => _baseElement.hasSealed;

  @override
  bool get hasVisibleForTemplate => _baseElement.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => _baseElement.hasVisibleForTesting;

  @override
  int get id => _baseElement.id;

  @override
  bool get isAlwaysThrows => _baseElement.hasAlwaysThrows;

  @override
  bool get isDeprecated => _baseElement.hasDeprecated;

  @override
  bool get isFactory => _baseElement.hasFactory;

  @override
  bool get isJS => _baseElement.hasJS;

  @override
  bool get isOverride => _baseElement.hasOverride;

  @override
  bool get isPrivate => _baseElement.isPrivate;

  @override
  bool get isProtected => _baseElement.hasProtected;

  @override
  bool get isPublic => _baseElement.isPublic;

  @override
  bool get isRequired => _baseElement.hasRequired;

  @override
  bool get isSynthetic => _baseElement.isSynthetic;

  @override
  bool get isVisibleForTesting => _baseElement.hasVisibleForTesting;

  @override
  ElementKind get kind => _baseElement.kind;

  @override
  LibraryElement get library => _baseElement.library;

  @override
  Source get librarySource => _baseElement.librarySource;

  @override
  ElementLocation get location => _baseElement.location;

  @override
  List<ElementAnnotation> get metadata => _baseElement.metadata;

  @override
  String get name => _baseElement.name;

  @override
  int get nameLength => _baseElement.nameLength;

  @override
  int get nameOffset => _baseElement.nameOffset;

  @override
  AnalysisSession get session => _baseElement.session;

  @override
  Source get source => _baseElement.source;

  /**
   * The substitution for type parameters referenced in the base element.
   */
  MapSubstitution get substitution => _substitution;

  @deprecated
  @override
  CompilationUnit get unit => _baseElement.unit;

  @override
  String computeDocumentationComment() => documentationComment;

  @deprecated
  @override
  AstNode computeNode() => _baseElement.computeNode();

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) =>
      baseElement.getAncestor(predicate);

  @override
  String getExtendedDisplayName(String shortName) =>
      _baseElement.getExtendedDisplayName(shortName);

  @override
  bool isAccessibleIn(LibraryElement library) =>
      _baseElement.isAccessibleIn(library);

  /**
   * Use the given [visitor] to visit all of the [children].
   */
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    // TODO(brianwilkerson) Make this private
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }
}

/**
 * A method element defined in a parameterized type where the values of the type
 * parameters are known.
 */
class MethodMember extends ExecutableMember implements MethodElement {
  /**
   * Initialize a newly created element to represent a method, based on the
   * [baseElement], with applied [substitution].
   */
  MethodMember(
    MethodElement baseElement,
    MapSubstitution substitution,
  ) : super(baseElement, substitution);

  @override
  MethodElement get baseElement => super.baseElement as MethodElement;

  @override
  Element get enclosingElement => baseElement.enclosingElement;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);

  @deprecated
  @override
  MethodDeclaration computeNode() => baseElement.computeNode();

  @override
  String toString() {
    MethodElement baseElement = this.baseElement;
    List<ParameterElement> parameters = this.parameters;
    FunctionType type = this.type;

    StringBuffer buffer = StringBuffer();
    if (type != null) {
      buffer.write(type.returnType);
      buffer.write(' ');
    }
    buffer.write(baseElement.enclosingElement.displayName);
    buffer.write('.');
    buffer.write(baseElement.displayName);
    int typeParameterCount = typeParameters.length;
    if (typeParameterCount > 0) {
      buffer.write('<');
      for (int i = 0; i < typeParameterCount; i++) {
        if (i > 0) {
          buffer.write(', ');
        }
        // TODO(scheglov) consider always using TypeParameterMember
        var typeParameter = typeParameters[i];
        if (typeParameter is TypeParameterElementImpl) {
          typeParameter.appendTo(buffer);
        } else
          (typeParameter as TypeParameterMember).appendTo(buffer);
      }
      buffer.write('>');
    }
    buffer.write('(');
    String closing;
    ParameterKind kind = ParameterKind.REQUIRED;
    int parameterCount = parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        buffer.write(', ');
      }
      ParameterElement parameter = parameters[i];
      // ignore: deprecated_member_use_from_same_package
      ParameterKind parameterKind = parameter.parameterKind;
      if (parameterKind != kind) {
        if (closing != null) {
          buffer.write(closing);
        }
        if (parameter.isOptionalPositional) {
          buffer.write('[');
          closing = ']';
        } else if (parameter.isNamed) {
          buffer.write('{');
          closing = '}';
        } else {
          closing = null;
        }
      }
      kind = parameterKind;
      parameter.appendToWithoutDelimiters(buffer);
    }
    if (closing != null) {
      buffer.write(closing);
    }
    buffer.write(')');
    return buffer.toString();
  }

  /**
   * If the given [method]'s type is different when any type parameters from the
   * defining type's declaration are replaced with the actual type arguments
   * from the [definingType], create a method member representing the given
   * method. Return the member that was created, or the base method if no member
   * was created.
   */
  static MethodElement from(MethodElement method, InterfaceType definingType) {
    if (method == null || definingType.typeArguments.isEmpty) {
      return method;
    }

    return MethodMember(
      method,
      Substitution.fromInterfaceType(definingType),
    );
  }

  static MethodElement from2(
    MethodElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return MethodMember(element, substitution);
  }
}

/**
 * A parameter element defined in a parameterized type where the values of the
 * type parameters are known.
 */
class ParameterMember extends VariableMember
    with ParameterElementMixin
    implements ParameterElement {
  /**
   * Initialize a newly created element to represent a parameter, based on the
   * [baseElement], with applied [substitution]. If [type] is passed it will
   * represent the already substituted type.
   */
  ParameterMember(
    ParameterElement baseElement,
    MapSubstitution substitution, [
    DartType type,
  ]) : super._(baseElement, substitution, type);

  @override
  ParameterElement get baseElement => super.baseElement as ParameterElement;

  @override
  String get defaultValueCode => baseElement.defaultValueCode;

  @override
  Element get enclosingElement => baseElement.enclosingElement;

  @override
  int get hashCode => baseElement.hashCode;

  @override
  bool get isCovariant => baseElement.isCovariant;

  @override
  bool get isInitializingFormal => baseElement.isInitializingFormal;

  @deprecated
  @override
  ParameterKind get parameterKind => baseElement.parameterKind;

  @override
  List<ParameterElement> get parameters {
    DartType type = this.type;
    if (type is FunctionType) {
      return type.parameters;
    }
    return const <ParameterElement>[];
  }

  @override
  List<TypeParameterElement> get typeParameters {
    return TypeParameterMember.from2(
      baseElement.typeParameters,
      _substitution,
    );
  }

  @override
  SourceRange get visibleRange => baseElement.visibleRange;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitParameterElement(this);

  @deprecated
  @override
  FormalParameter computeNode() => baseElement.computeNode();

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) {
    Element element = baseElement.getAncestor(predicate);
    if (element is ExecutableElement) {
      return ExecutableMember.from2(element, _substitution) as E;
    }
    return element as E;
  }

  @override
  String toString() {
    ParameterElement baseElement = this.baseElement;
    String left = "";
    String right = "";
    while (true) {
      if (baseElement.isNamed) {
        left = "{";
        right = "}";
      } else if (baseElement.isOptionalPositional) {
        left = "[";
        right = "]";
      }
      break;
    }
    return '$left$type ${baseElement.displayName}$right';
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/**
 * A property accessor element defined in a parameterized type where the values
 * of the type parameters are known.
 */
class PropertyAccessorMember extends ExecutableMember
    implements PropertyAccessorElement {
  /**
   * Initialize a newly created element to represent a property, based on the
   * [baseElement], with applied [substitution].
   */
  PropertyAccessorMember(
    PropertyAccessorElement baseElement,
    MapSubstitution substitution,
  ) : super(baseElement, substitution);

  @override
  PropertyAccessorElement get baseElement =>
      super.baseElement as PropertyAccessorElement;

  @override
  PropertyAccessorElement get correspondingGetter {
    return PropertyAccessorMember(
      baseElement.correspondingGetter,
      _substitution,
    );
  }

  @override
  PropertyAccessorElement get correspondingSetter {
    return PropertyAccessorMember(
      baseElement.correspondingSetter,
      _substitution,
    );
  }

  @override
  Element get enclosingElement => baseElement.enclosingElement;

  @override
  bool get isGetter => baseElement.isGetter;

  @override
  bool get isSetter => baseElement.isSetter;

  @override
  PropertyInducingElement get variable {
    PropertyInducingElement variable = baseElement.variable;
    if (variable is FieldElement) {
      return FieldMember(variable, _substitution);
    }
    return variable;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

  @override
  String toString() {
    PropertyAccessorElement baseElement = this.baseElement;
    List<ParameterElement> parameters = this.parameters;
    FunctionType type = this.type;

    StringBuffer builder = StringBuffer();
    if (type != null) {
      builder.write(type.returnType);
      builder.write(' ');
    }
    if (isGetter) {
      builder.write('get ');
    } else {
      builder.write('set ');
    }
    builder.write(baseElement.enclosingElement.displayName);
    builder.write('.');
    builder.write(baseElement.displayName);
    builder.write('(');
    int parameterCount = parameters.length;
    for (int i = 0; i < parameterCount; i++) {
      if (i > 0) {
        builder.write(', ');
      }
      builder.write(parameters[i]);
    }
    builder.write(')');
    return builder.toString();
  }

  /**
   * If the given [accessor]'s type is different when any type parameters from
   * the defining type's declaration are replaced with the actual type
   * arguments from the [definingType], create an accessor member representing
   * the given accessor. Return the member that was created, or the base
   * accessor if no member was created.
   */
  static PropertyAccessorElement from(
      PropertyAccessorElement accessor, InterfaceType definingType) {
    if (accessor == null || definingType.typeArguments.isEmpty) {
      return accessor;
    }

    return PropertyAccessorMember(
      accessor,
      Substitution.fromInterfaceType(definingType),
    );
  }
}

/**
 * A type parameter defined inside of another parameterized type, where the
 * values of the enclosing type parameters are known.
 *
 * For example:
 *
 *     class C<T> {
 *       S m<S extends T>(S s);
 *     }
 *
 * If we have `C<num>.m` and we ask for the type parameter "S", we should get
 * `<S extends num>` instead of `<S extends T>`. This is how the parameter
 * and return types work, see: [FunctionType.parameters],
 * [FunctionType.returnType], and [ParameterMember].
 */
class TypeParameterMember extends Member implements TypeParameterElement {
  DartType _bound;
  DartType _type;

  TypeParameterMember(TypeParameterElement baseElement,
      MapSubstitution substitution, this._bound)
      : super(baseElement, substitution) {
    _type = TypeParameterTypeImpl(this);
  }

  @override
  TypeParameterElement get baseElement =>
      super.baseElement as TypeParameterElement;

  @override
  DartType get bound => _bound;

  @override
  Element get enclosingElement => baseElement.enclosingElement;

  @override
  int get hashCode => baseElement.hashCode;

  @override
  TypeParameterType get type => _type;

  @override
  bool operator ==(Object other) =>
      other is TypeParameterMember && baseElement == other.baseElement;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitTypeParameterElement(this);

  void appendTo(StringBuffer buffer) {
    buffer.write(displayName);
    if (bound != null) {
      buffer.write(" extends ");
      buffer.write(bound);
    }
  }

  @override
  TypeParameterType instantiate({
    @required NullabilitySuffix nullabilitySuffix,
  }) {
    return TypeParameterTypeImpl(this, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    appendTo(buffer);
    return buffer.toString();
  }

  /**
   * If the given [parameter]'s type is different when any type parameters from
   * the defining type's declaration are replaced with the actual type
   * arguments from the [definingType], create a parameter member representing
   * the given parameter. Return the member that was created, or the base
   * parameter if no member was created.
   */
  static List<TypeParameterElement> from(
      List<TypeParameterElement> formals, FunctionType definingType) {
    var substitution = Substitution.fromPairs(
      definingType.typeParameters,
      definingType.typeArguments,
    );
    return from2(formals, substitution);
  }

  static List<TypeParameterElement> from2(
    List<TypeParameterElement> elements,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return elements;
    }

    // Create type formals with specialized bounds.
    // For example `<U extends T>` where T comes from an outer scope.
    var newElements = List<TypeParameterElement>(elements.length);
    var newTypes = List<TypeParameterType>(elements.length);
    for (int i = 0; i < newElements.length; i++) {
      var element = elements[i];
      var bound = element?.bound;
      if (bound != null) {
        bound = substitution.substituteType(bound);
        element = TypeParameterMember(element, substitution, bound);
      }
      newElements[i] = element;
      newTypes[i] = newElements[i].instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // Recursive bounds are allowed too, so make sure these are updated
    // to refer to any new TypeParameterMember we just made, rather than
    // the original type parameter
    var substitution2 = Substitution.fromPairs(elements, newTypes);
    for (var newElement in newElements) {
      if (newElement is TypeParameterMember) {
        // TODO(jmesserly): this is required so substituting for the
        // type formal will work. Investigate if there's a better solution.
        newElement._bound = substitution2.substituteType(newElement.bound);
      }
    }
    return newElements;
  }
}

/**
 * A variable element defined in a parameterized type where the values of the
 * type parameters are known.
 */
abstract class VariableMember extends Member implements VariableElement {
  DartType _type;

  /**
   * Initialize a newly created element to represent a variable, based on the
   * [baseElement], with applied [substitution].
   */
  VariableMember(
    VariableElement baseElement,
    MapSubstitution substitution, [
    DartType type,
  ])  : _type = type,
        super(baseElement, substitution);

  // TODO(jmesserly): this is temporary to allow the ParameterMember subclass.
  // Apparently mixins don't work with optional params.
  VariableMember._(VariableElement baseElement, MapSubstitution substitution,
      [DartType type])
      : this(baseElement, substitution, type);

  @override
  VariableElement get baseElement => super.baseElement as VariableElement;

  @override
  DartObject get constantValue => baseElement.constantValue;

  @override
  bool get hasImplicitType => baseElement.hasImplicitType;

  @override
  FunctionElement get initializer {
    //
    // Elements within this element should have type parameters substituted,
    // just like this element.
    //
    throw UnsupportedError('initializer');
    //    return getBaseElement().getInitializer();
  }

  @override
  bool get isConst => baseElement.isConst;

  @override
  bool get isConstantEvaluated => baseElement.isConstantEvaluated;

  @override
  bool get isFinal => baseElement.isFinal;

  @override
  bool get isLate => baseElement.isLate;

  @override
  @deprecated
  bool get isPotentiallyMutatedInClosure =>
      baseElement.isPotentiallyMutatedInClosure;

  @override
  @deprecated
  bool get isPotentiallyMutatedInScope =>
      baseElement.isPotentiallyMutatedInScope;

  @override
  bool get isStatic => baseElement.isStatic;

  @override
  DartType get type {
    if (_type != null) return _type;

    return _type = _substitution.substituteType(baseElement.type);
  }

  @override
  DartObject computeConstantValue() => baseElement.computeConstantValue();

  @override
  void visitChildren(ElementVisitor visitor) {
    // TODO(brianwilkerson) We need to finish implementing the accessors used
    // below so that we can safely invoke them.
    super.visitChildren(visitor);
    baseElement.initializer?.accept(visitor);
  }
}
