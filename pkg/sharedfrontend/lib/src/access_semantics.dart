// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for classifying the semantics of identifiers appearing in a Dart file.
 */
library sharedfrontend.access_semantics;

import '../elements.dart';

/**
 * Enum representing the different kinds of destinations which a property
 * access or method or function invocation might refer to.
 */
class AccessKind {
  /**
   * The destination of the access is an instance method, property, or field
   * of a class, and thus must be determined dynamically.
   */
  static const AccessKind DYNAMIC = const AccessKind._('DYNAMIC');

  /**
   * The destination of the access is a function that is defined locally within
   * an enclosing function or method.
   */
  static const AccessKind LOCAL_FUNCTION = const AccessKind._('LOCAL_FUNCTION');

  /**
   * The destination of the access is a variable that is defined locally within
   * an enclosing function or method.
   */
  static const AccessKind LOCAL_VARIABLE = const AccessKind._('LOCAL_VARIABLE');

  /**
   * The destination of the access is a variable that is defined as a parameter
   * to an enclosing function or method.
   */
  static const AccessKind PARAMETER = const AccessKind._('PARAMETER');

  /**
   * The destination of the access is a field that is defined statically within
   * a class, or a top level variable within a library.
   */
  static const AccessKind STATIC_FIELD = const AccessKind._('STATIC_FIELD');

  /**
   * The destination of the access is a method that is defined statically
   * within a class, or at top level within a library.
   */
  static const AccessKind STATIC_METHOD = const AccessKind._('STATIC_METHOD');

  /**
   * The destination of the access is a property getter/setter that is defined
   * statically within a class, or at top level within a library.
   */
  static const AccessKind STATIC_PROPERTY =
      const AccessKind._('STATIC_PROPERTY');

  /**
   * The destination of the access is a toplevel class, function typedef, mixin
   * application, or the built-in type "dynamic".
   */
  static const AccessKind TOPLEVEL_TYPE = const AccessKind._('TOPLEVEL_TYPE');

  /**
   * The destination of the access is a type parameter of the enclosing class.
   */
  static const AccessKind TYPE_PARAMETER = const AccessKind._('TYPE_PARAMETER');

  final String name;

  const AccessKind._(this.name);

  String toString() => name;
}

/**
 * Data structure used to classify the semantics of a property access or method
 * or function invocation.
 */
// TODO(paulberry,johnniwinther): Support index operations in AccessSemantics.
class AccessSemantics {
  /**
   * The kind of access.
   */
  final AccessKind kind;

  /**
   * The name being used to access the property, method, or function.
   */
  final String name;

  /**
   * The element being accessed, if statically known.  This will be null if
   * [kind] is DYNAMIC or if the element is undefined (e.g. an attempt to
   * access a non-existent static method in a class).
   */
  final Element element;

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
  final ClassElement classElement;

  // TODO(paulberry): would it also be useful to store the libraryElement?

  /**
   * When [kind] is DYNAMIC, the expression whose runtime type determines the
   * class in which [identifier] should be looked up.  Null if the expression
   * is implicit "this".
   *
   * When [kind] is not DYNAMIC, this field is always null.
   */
  final /*Expression*/ target;

  /**
   * True if this is an invocation of a method, or a call on a property.
   */
  final bool isInvoke;

  /**
   * True if this is a read access to a property, or a method tear-off.  Note
   * that both [isRead] and [isWrite] will be true in the case of a
   * read-modify-write operation (e.g. "+=").
   */
  final bool isRead;// => !isInvoke && identifier.inGetterContext();

  /**
   * True if this is a write access to a property, or an (erroneous) attempt to
   * write to a method.  Note that both [isRead] and [isWrite] will be true in
   * the case of a read-modify-write operation (e.g. "+=").
   */
  final bool isWrite; // => identifier.inSetterContext();

  AccessSemantics.dynamic(
      this.name,
      this.target,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.DYNAMIC,
        element = null,
        classElement = null;

  AccessSemantics.localFunction(
      this.name,
      this.element,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.LOCAL_FUNCTION,
        classElement = null,
        target = null;

  AccessSemantics.localVariable(
      this.name,
      this.element,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.LOCAL_VARIABLE,
        classElement = null,
        target = null;

  AccessSemantics.parameter(
      this.name,
      this.element,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.PARAMETER,
        classElement = null,
        target = null;

  AccessSemantics.staticField(
      this.name,
      this.element,
      this.classElement,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.STATIC_FIELD,
        target = null;

  AccessSemantics.staticMethod(
      this.name,
      this.element,
      this.classElement,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.STATIC_METHOD,
        target = null;

  AccessSemantics.staticProperty(
      this.name,
      this.element,
      this.classElement,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.STATIC_PROPERTY,
        target = null;

  AccessSemantics.toplevelType(
      this.name,
      this.element,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.TOPLEVEL_TYPE,
        classElement = null,
        target = null;

  AccessSemantics.typeParameter(
      this.name,
      this.element,
      {this.isInvoke: false,
       this.isRead: false,
       this.isWrite: false})
      : kind = AccessKind.TYPE_PARAMETER,
        classElement = null,
        target = null;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('AccessSemantics[');
    sb.write('kind=$kind,');
    if (isRead && isWrite) {
      assert(!isInvoke);
      sb.write('read/write,');
    } else if (isRead) {
      sb.write('read,');
    } else if (isWrite) {
      sb.write('write,');
    } else if (isInvoke) {
      sb.write('call,');
    }
    if (element != null) {
      sb.write('element=');
      if (classElement != null) {
        sb.write('${classElement.name}.');
      }
      sb.write('${element}');
    } else {
      if (target == null) {
        sb.write('target=this.$name');
      } else {
        sb.write('target=$target.$name');
      }
    }
    sb.write(']');
    return sb.toString();
  }
}
