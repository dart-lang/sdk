// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Temporarily copied from analyzer2dart. Merge when
// we shared code with the analyzer and this semantic visitor is complete.

/**
 * Code for classifying the semantics of identifiers appearing in a Dart file.
 */
library dart2js.access_semantics;

import '../constants/expressions.dart';
import '../elements/elements.dart';
import '../dart_types.dart';

/// Enum representing the different kinds of destinations which a property
/// access or method or function invocation might refer to.
enum AccessKind {
  /// The destination of the access is an instance method, property, or field
  /// of a class, and thus must be determined dynamically.
  DYNAMIC_PROPERTY,

  // TODO(johnniwinther): Split these cases into captured and non-captured
  // local access.
  /// The destination of the access is a function that is defined locally within
  /// an enclosing function or method.
  LOCAL_FUNCTION,

  /// The destination of the access is a variable that is defined locally within
  /// an enclosing function or method.
  LOCAL_VARIABLE,

  /// The destination of the access is a variable that is defined as a parameter
  /// to an enclosing function or method.
  PARAMETER,

  /// The destination of the access is a field that is defined statically within
  /// a class.
  STATIC_FIELD,

  /// The destination of the access is a method that is defined statically
  /// within a class.
  STATIC_METHOD,

  /// The destination of the access is a property getter that is defined
  /// statically within a class.
  STATIC_GETTER,

  /// The destination of the access is a property setter that is defined
  /// statically within a class.
  STATIC_SETTER,

  /// The destination of the access is a top level variable defined within a
  /// library.
  TOPLEVEL_FIELD,

  /// The destination of the access is a top level method defined within a
  /// library.
  TOPLEVEL_METHOD,

  /// The destination of the access is a top level property getter defined
  /// within a library.
  TOPLEVEL_GETTER,

  /// The destination of the access is a top level property setter defined
  /// within a library.
  TOPLEVEL_SETTER,

  /// The destination of the access is a toplevel class, or named mixin
  /// application.
  CLASS_TYPE_LITERAL,

  /// The destination of the access is a function typedef.
  TYPEDEF_TYPE_LITERAL,

  /// The destination of the access is the built-in type "dynamic".
  DYNAMIC_TYPE_LITERAL,

  /// The destination of the access is a type parameter of the enclosing class.
  TYPE_PARAMETER_TYPE_LITERAL,

  /// The destination of the access is a (complex) expression. For instance the
  /// function expression `(){}` in the function expression invocation `(){}()`.
  EXPRESSION,

  /// The destination of the access is `this` of the enclosing class.
  THIS,

  /// The destination of the access is an instance method, property, or field
  /// of the enclosing class.
  THIS_PROPERTY,

  /// The destination of the access is a field of the super class of the
  /// enclosing class.
  SUPER_FIELD,

  /// The destination of the access is a method of the super class of the
  /// enclosing class.
  SUPER_METHOD,

  /// The destination of the access is a getter of the super class of the
  /// enclosing class.
  SUPER_GETTER,

  /// The destination of the access is a setter of the super class of the
  /// enclosing class.
  SUPER_SETTER,

  /// Compound access where read and write access different elements.
  /// See [CompoundAccessKind].
  COMPOUND,

  /// The destination of the access is a compile-time constant.
  CONSTANT,

  /// The destination of the access is unresolved in a static context.
  UNRESOLVED,
}

enum CompoundAccessKind {
  /// Read from a static getter and write to static setter.
  STATIC_GETTER_SETTER,
  /// Read from a static method (closurize) and write to static setter.
  STATIC_METHOD_SETTER,

  /// Read from a top level getter and write to a top level setter.
  TOPLEVEL_GETTER_SETTER,
  /// Read from a top level method (closurize) and write to top level setter.
  TOPLEVEL_METHOD_SETTER,

  /// Read from one superclass field and write to another.
  SUPER_FIELD_FIELD,
  /// Read from a superclass field and write to a superclass setter.
  SUPER_FIELD_SETTER,
  /// Read from a superclass getter and write to a superclass setter.
  SUPER_GETTER_SETTER,
  /// Read from a superclass method (closurize) and write to a superclass
  /// setter.
  SUPER_METHOD_SETTER,
  /// Read from a superclass getter and write to a superclass field.
  SUPER_GETTER_FIELD,
}

/**
 * Data structure used to classify the semantics of a property access or method
 * or function invocation.
 */
class AccessSemantics {
  /**
   * The kind of access.
   */
  final AccessKind kind;

  /**
   * The element being accessed, if statically known.  This will be null if
   * [kind] is DYNAMIC or if the element is undefined (e.g. an attempt to
   * access a non-existent static method in a class).
   */
  Element get element => null;

  /**
   * The class containing the element being accessed, if this is a static
   * reference to an element in a class.  This will be null if [kind] is
   * DYNAMIC, LOCAL_FUNCTION, LOCAL_VARIABLE, PARAMETER, TOPLEVEL_CLASS, or
   * TYPE_PARAMETER, or if the element being accessed is defined at toplevel
   * within a library.
   *
   * Note: it is possible for [classElement] to be non-null and for [element]
   * to be null; for example this occurs if the element being accessed is a
   * non-existent static method or field inside an existing class.
   */
  ClassElement get classElement => null;

  // TODO(paulberry): would it also be useful to store the libraryElement?

  // TODO(johnniwinther): Do we need this?
  /**
   * When [kind] is DYNAMIC_PROPERTY, the expression whose runtime type
   * determines the class in which [identifier] should be looked up.
   *
   * When [kind] is not DYNAMIC_PROPERTY, this field is always null.
   */
  /*Expression*/ get target => null;

  ConstantExpression get constant => null;

  AccessSemantics.expression()
      : kind = AccessKind.EXPRESSION;

  AccessSemantics.thisAccess()
      : kind = AccessKind.THIS;

  AccessSemantics.thisProperty()
      : kind = AccessKind.THIS_PROPERTY;

  AccessSemantics._(this.kind);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('AccessSemantics[');
    sb.write('kind=$kind,');
    if (element != null) {
      sb.write('element=');
      if (classElement != null) {
        sb.write('${classElement.name}.');
      }
      sb.write('${element}');
    }
    sb.write(']');
    return sb.toString();
  }
}


class DynamicAccess extends AccessSemantics {
  final target;

  DynamicAccess.dynamicProperty(this.target)
      : super._(AccessKind.DYNAMIC_PROPERTY);
}

class ConstantAccess extends AccessSemantics {
  final ConstantExpression constant;

  ConstantAccess(AccessKind kind, this.constant)
      : super._(kind);

  ConstantAccess.classTypeLiteral(this.constant)
      : super._(AccessKind.CLASS_TYPE_LITERAL);

  ConstantAccess.typedefTypeLiteral(this.constant)
      : super._(AccessKind.TYPEDEF_TYPE_LITERAL);

  ConstantAccess.dynamicTypeLiteral(this.constant)
      : super._(AccessKind.DYNAMIC_TYPE_LITERAL);
}

class StaticAccess extends AccessSemantics {
  final Element element;

  ClassElement get classElement => element.enclosingClass;

  StaticAccess._(AccessKind kind, this.element)
      : super._(kind);

  StaticAccess.superSetter(MethodElement this.element)
      : super._(AccessKind.SUPER_SETTER);

  StaticAccess.superField(FieldElement this.element)
      : super._(AccessKind.SUPER_FIELD);

  StaticAccess.superMethod(MethodElement this.element)
      : super._(AccessKind.SUPER_METHOD);

  StaticAccess.superGetter(MethodElement this.element)
      : super._(AccessKind.SUPER_GETTER);

  StaticAccess.typeParameterTypeLiteral(TypeVariableElement this.element)
      : super._(AccessKind.TYPE_PARAMETER_TYPE_LITERAL);

  StaticAccess.localFunction(LocalFunctionElement this.element)
      : super._(AccessKind.LOCAL_FUNCTION);

  StaticAccess.localVariable(LocalVariableElement this.element)
      : super._(AccessKind.LOCAL_VARIABLE);

  StaticAccess.parameter(ParameterElement this.element)
      : super._(AccessKind.PARAMETER);

  StaticAccess.staticField(FieldElement this.element)
      : super._(AccessKind.STATIC_FIELD);

  StaticAccess.staticMethod(MethodElement this.element)
      : super._(AccessKind.STATIC_METHOD);

  StaticAccess.staticGetter(MethodElement this.element)
      : super._(AccessKind.STATIC_GETTER);

  StaticAccess.staticSetter(MethodElement this.element)
      : super._(AccessKind.STATIC_SETTER);

  StaticAccess.topLevelField(FieldElement this.element)
      : super._(AccessKind.TOPLEVEL_FIELD);

  StaticAccess.topLevelMethod(MethodElement this.element)
      : super._(AccessKind.TOPLEVEL_METHOD);

  StaticAccess.topLevelGetter(MethodElement this.element)
      : super._(AccessKind.TOPLEVEL_GETTER);

  StaticAccess.topLevelSetter(MethodElement this.element)
      : super._(AccessKind.TOPLEVEL_SETTER);

  StaticAccess.unresolved(this.element)
      : super._(AccessKind.UNRESOLVED);
}

class CompoundAccessSemantics extends AccessSemantics {
  final CompoundAccessKind compoundAccessKind;
  final Element getter;
  final Element setter;

  CompoundAccessSemantics(this.compoundAccessKind,
                          this.getter,
                          this.setter)
      : super._(AccessKind.COMPOUND);

  Element get element => setter;
}

/// Enum representing the different kinds of destinations which a constructor
/// invocation might refer to.
enum ConstructorAccessKind {
  /// An invocation of a generative constructor.
  ///
  /// For instance
  ///     class C {
  ///       C();
  ///     }
  ///     m() => new C();
  ///
  GENERATIVE,

  /// An invocation of a redirecting generative constructor.
  ///
  /// For instance
  ///     class C {
  ///       C() : this._();
  ///       C._();
  ///     }
  ///     m() => new C();
  ///
  REDIRECTING_GENERATIVE,

  /// An invocation of a factory constructor.
  ///
  /// For instance
  ///     class C {
  ///       factory C() => new C._();
  ///       C._();
  ///     }
  ///     m() => new C();
  ///
  FACTORY,

  /// An invocation of a redirecting factory constructor.
  ///
  /// For instance
  ///     class C {
  ///       factory C() = C._;
  ///       C._();
  ///     }
  ///     m() => new C();
  ///
  REDIRECTING_FACTORY,

  /// An invocation of a (redirecting) generative constructor of an abstract
  /// class.
  ///
  /// For instance
  ///     abstract class C {
  ///       C();
  ///     }
  ///     m() => new C();
  ///
  ABSTRACT,

  /// An invocation of an unresolved constructor or an unresolved type.
  ///
  /// For instance
  ///     class C {
  ///       C();
  ///     }
  ///     m1() => new C.unresolved();
  ///     m2() => new Unresolved();
  ///
  // TODO(johnniwinther): Differentiate between error types.
  ERRONEOUS,

  /// An invocation of an ill-defined redirecting factory constructor.
  ///
  /// For instance
  ///     class C {
  ///       factory C() = Unresolved;
  ///     }
  ///     m() => new C();
  ///
  ERRONEOUS_REDIRECTING_FACTORY,
}

/// Data structure used to classify the semantics of a constructor invocation.
class ConstructorAccessSemantics {
  /// The kind of constructor invocation.
  final ConstructorAccessKind kind;

  /// The invoked constructor.
  final Element element;

  /// The type on which the constructor is invoked.
  final DartType type;

  ConstructorAccessSemantics(this.kind, this.element, this.type);

  /// The effect target of the access. Used to defined redirecting factory
  /// constructor invocations.
  ConstructorAccessSemantics get effectiveTargetSemantics => this;

  /// `true` if this invocation is erroneous.
  bool get isErroneous {
    return kind == ConstructorAccessKind.ABSTRACT ||
           kind == ConstructorAccessKind.ERRONEOUS ||
           kind == ConstructorAccessKind.ERRONEOUS_REDIRECTING_FACTORY;
  }
}

/// Data structure used to classify the semantics of a redirecting factory
/// constructor invocation.
class RedirectingFactoryConstructorAccessSemantics
    extends ConstructorAccessSemantics {
  final ConstructorAccessSemantics effectiveTargetSemantics;

  RedirectingFactoryConstructorAccessSemantics(
      ConstructorAccessKind kind,
      Element element,
      DartType type,
      this.effectiveTargetSemantics)
      : super(kind, element, type);
}


