// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for classifying the semantics of identifiers appearing in a Dart file.
 */
library dart2js.access_semantics;

import '../constants/expressions.dart';
import '../elements/resolution_types.dart';
import '../elements/elements.dart';
import '../elements/names.dart';

/// Enum representing the different kinds of destinations which a property
/// access or method or function invocation might refer to.
enum AccessKind {
  /// The destination of the conditional access is an instance method, property,
  /// or field of a class, and thus must be determined dynamically.
  CONDITIONAL_DYNAMIC_PROPERTY,

  /// The destination of the access is an instance method, property, or field
  /// of a class, and thus must be determined dynamically.
  DYNAMIC_PROPERTY,

  // TODO(johnniwinther): Split these cases into captured and non-captured
  // local access.
  /// The destination of the access is a function that is defined locally within
  /// an enclosing function or method.
  LOCAL_FUNCTION,

  /// The destination of the access is a non-final variable that is defined
  /// locally within an enclosing function or method.
  LOCAL_VARIABLE,

  /// The destination of the access is a final variable that is defined locally
  /// within an enclosing function or method.
  FINAL_LOCAL_VARIABLE,

  /// The destination of the access is a variable that is defined as a non-final
  /// parameter to an enclosing function or method.
  PARAMETER,

  /// The destination of the access is a variable that is defined as a final
  /// parameter to an enclosing function or method.
  FINAL_PARAMETER,

  /// The destination of the access is a non-final field that is defined
  /// statically within a class.
  STATIC_FIELD,

  /// The destination of the access is a final field that is defined statically
  /// within a class.
  FINAL_STATIC_FIELD,

  /// The destination of the access is a method that is defined statically
  /// within a class.
  STATIC_METHOD,

  /// The destination of the access is a property getter that is defined
  /// statically within a class.
  STATIC_GETTER,

  /// The destination of the access is a property setter that is defined
  /// statically within a class.
  STATIC_SETTER,

  /// The destination of the access is a non-final top level variable defined
  /// within a library.
  TOPLEVEL_FIELD,

  /// The destination of the access is a final top level variable defined within
  /// a library.
  FINAL_TOPLEVEL_FIELD,

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

  /// The destination of the access is a non-final field of the super class of
  /// the enclosing class.
  SUPER_FIELD,

  /// The destination of the access is a final field of the super class of the
  /// enclosing class.
  SUPER_FINAL_FIELD,

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

  /// The destination of the access is unresolved super access.
  UNRESOLVED_SUPER,

  /// The destination is invalid as an access. For instance a prefix used
  /// as an expression.
  INVALID,
}

enum CompoundAccessKind {
  /// Read from a static getter and write to a static setter.
  STATIC_GETTER_SETTER,

  /// Read from a static method (closurize) and write to a static setter.
  STATIC_METHOD_SETTER,

  /// Read from an unresolved static getter and write to a static setter.
  UNRESOLVED_STATIC_GETTER,

  /// Read from a static getter and write to an unresolved static setter.
  UNRESOLVED_STATIC_SETTER,

  /// Read from a top level getter and write to a top level setter.
  TOPLEVEL_GETTER_SETTER,

  /// Read from a top level method (closurize) and write to top level setter.
  TOPLEVEL_METHOD_SETTER,

  /// Read from an unresolved top level getter and write to a top level setter.
  UNRESOLVED_TOPLEVEL_GETTER,

  /// Read from a top level getter and write to an unresolved top level setter.
  UNRESOLVED_TOPLEVEL_SETTER,

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

  /// Read from a superclass where the getter is unresolved.
  // TODO(johnniwinther): Use [AccessKind.SUPER_GETTER] when the erroneous
  // element is no longer needed.
  UNRESOLVED_SUPER_GETTER,

  /// Read from a superclass getter and write to an unresolved setter.
  // TODO(johnniwinther): Use [AccessKind.SUPER_SETTER] when the erroneous
  // element is no longer needed.
  UNRESOLVED_SUPER_SETTER,
}

/**
 * Data structure used to classify the semantics of a property access or method
 * or function invocation.
 */
abstract class AccessSemantics {
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

  ConstantExpression get constant => null;

  /// The element for the getter in case of a compound access,
  /// [element] otherwise.
  Element get getter => element;

  /// The element for the setter in case of a compound access,
  /// [element] otherwise.
  Element get setter => element;

  Name get name => null;

  const AccessSemantics._(this.kind);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('AccessSemantics[');
    sb.write('kind=$kind,');
    if (element != null) {
      if (getter != setter) {
        sb.write('getter=');
        sb.write('${getter}');
        sb.write(',setter=');
        sb.write('${setter}');
      } else {
        sb.write('element=');
        sb.write('${element}');
      }
    } else if (name != null) {
      sb.write('name=');
      sb.write(name);
    }
    sb.write(']');
    return sb.toString();
  }
}

class DynamicAccess extends AccessSemantics {
  final Name name;

  const DynamicAccess.expression()
      : name = null,
        super._(AccessKind.EXPRESSION);

  const DynamicAccess.thisAccess()
      : name = null,
        super._(AccessKind.THIS);

  const DynamicAccess.thisProperty(this.name)
      : super._(AccessKind.THIS_PROPERTY);

  const DynamicAccess.dynamicProperty(this.name)
      : super._(AccessKind.DYNAMIC_PROPERTY);

  const DynamicAccess.ifNotNullProperty(this.name)
      : super._(AccessKind.CONDITIONAL_DYNAMIC_PROPERTY);
}

class ConstantAccess extends AccessSemantics {
  final ConstantExpression constant;

  ConstantAccess(AccessKind kind, this.constant) : super._(kind);

  ConstantAccess.classTypeLiteral(this.constant)
      : super._(AccessKind.CLASS_TYPE_LITERAL);

  ConstantAccess.typedefTypeLiteral(this.constant)
      : super._(AccessKind.TYPEDEF_TYPE_LITERAL);

  ConstantAccess.dynamicTypeLiteral(this.constant)
      : super._(AccessKind.DYNAMIC_TYPE_LITERAL);
}

class StaticAccess extends AccessSemantics {
  final Element element;

  StaticAccess.internal(AccessKind kind, this.element) : super._(kind);

  StaticAccess.superSetter(MethodElement this.element)
      : super._(AccessKind.SUPER_SETTER);

  StaticAccess.superField(FieldElement this.element)
      : super._(AccessKind.SUPER_FIELD);

  StaticAccess.superFinalField(FieldElement this.element)
      : super._(AccessKind.SUPER_FINAL_FIELD);

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

  StaticAccess.finalLocalVariable(LocalVariableElement this.element)
      : super._(AccessKind.FINAL_LOCAL_VARIABLE);

  StaticAccess.parameter(ParameterElement this.element)
      : super._(AccessKind.PARAMETER);

  StaticAccess.finalParameter(ParameterElement this.element)
      : super._(AccessKind.FINAL_PARAMETER);

  StaticAccess.staticField(FieldElement this.element)
      : super._(AccessKind.STATIC_FIELD);

  StaticAccess.finalStaticField(FieldElement this.element)
      : super._(AccessKind.FINAL_STATIC_FIELD);

  StaticAccess.staticMethod(MethodElement this.element)
      : super._(AccessKind.STATIC_METHOD);

  StaticAccess.staticGetter(MethodElement this.element)
      : super._(AccessKind.STATIC_GETTER);

  StaticAccess.staticSetter(MethodElement this.element)
      : super._(AccessKind.STATIC_SETTER);

  StaticAccess.topLevelField(FieldElement this.element)
      : super._(AccessKind.TOPLEVEL_FIELD);

  StaticAccess.finalTopLevelField(FieldElement this.element)
      : super._(AccessKind.FINAL_TOPLEVEL_FIELD);

  StaticAccess.topLevelMethod(MethodElement this.element)
      : super._(AccessKind.TOPLEVEL_METHOD);

  StaticAccess.topLevelGetter(MethodElement this.element)
      : super._(AccessKind.TOPLEVEL_GETTER);

  StaticAccess.topLevelSetter(MethodElement this.element)
      : super._(AccessKind.TOPLEVEL_SETTER);

  StaticAccess.unresolved(this.element) : super._(AccessKind.UNRESOLVED);

  StaticAccess.unresolvedSuper(this.element)
      : super._(AccessKind.UNRESOLVED_SUPER);

  StaticAccess.invalid(this.element) : super._(AccessKind.INVALID);
}

class CompoundAccessSemantics extends AccessSemantics {
  final CompoundAccessKind compoundAccessKind;
  final Element getter;
  final Element setter;

  CompoundAccessSemantics(this.compoundAccessKind, this.getter, this.setter)
      : super._(AccessKind.COMPOUND);

  Element get element => setter;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('CompoundAccessSemantics[');
    sb.write('kind=$compoundAccessKind');
    if (getter != null) {
      sb.write(',getter=');
      sb.write('${getter}');
    }
    if (setter != null) {
      sb.write(',setter=');
      sb.write('${setter}');
    }
    sb.write(']');
    return sb.toString();
  }
}

/// Enum representing the different kinds of destinations which a constructor
/// invocation might refer to.
enum ConstructorAccessKind {
  /// An invocation of a (redirecting) generative constructor.
  ///
  /// For instance
  ///     class C {
  ///       C();
  ///       C.redirect() : this();
  ///     }
  ///     m1() => new C();
  ///     m2() => new C.redirect();
  ///
  GENERATIVE,

  /// An invocation of a (redirecting) factory constructor.
  ///
  /// For instance
  ///     class C {
  ///       factory C() => new C._();
  ///       factory C.redirect() => C._;
  ///       C._();
  ///     }
  ///     m1() => new C();
  ///     m2() => new C.redirect();
  ///
  FACTORY,

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

  /// An invocation of a constructor on an unresolved type.
  ///
  /// For instance
  ///     m() => new Unresolved();
  ///
  UNRESOLVED_TYPE,

  /// An invocation of an unresolved constructor.
  ///
  /// For instance
  ///     class C {
  ///       C();
  ///     }
  ///     m() => new C.unresolved();
  ///
  UNRESOLVED_CONSTRUCTOR,

  /// An const invocation of an non-constant constructor.
  ///
  /// For instance
  ///     class C {
  ///       C();
  ///     }
  ///     m() => const C();
  ///
  NON_CONSTANT_CONSTRUCTOR,

  /// An invocation of a constructor with incompatible arguments.
  ///
  /// For instance
  ///     class C {
  ///       C();
  ///     }
  ///     m() => new C(true);
  ///
  INCOMPATIBLE,
}

/// Data structure used to classify the semantics of a constructor invocation.
class ConstructorAccessSemantics {
  /// The kind of constructor invocation.
  final ConstructorAccessKind kind;

  /// The invoked constructor.
  final Element element;

  /// The type on which the constructor is invoked.
  final ResolutionDartType type;

  ConstructorAccessSemantics(this.kind, this.element, this.type);

  String toString() => 'ConstructorAccessSemantics($kind, $element, $type)';
}
