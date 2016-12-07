// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helpers for Analyzer's Element model and corelib model.

import 'package:analyzer/dart/ast/ast.dart'
    show
        ConstructorDeclaration,
        Expression,
        FunctionBody,
        FunctionExpression,
        MethodDeclaration,
        MethodInvocation,
        SimpleIdentifier;
import 'package:analyzer/dart/element/element.dart'
    show Element, ExecutableElement, FunctionElement;
import 'package:analyzer/dart/element/type.dart'
    show DartType, InterfaceType, ParameterizedType;
import 'package:analyzer/src/dart/element/type.dart' show DynamicTypeImpl;
import 'package:analyzer/src/generated/constant.dart'
    show DartObject, DartObjectImpl;

class Tuple2<T0, T1> {
  final T0 e0;
  final T1 e1;
  Tuple2(this.e0, this.e1);
}

/*=T*/ fillDynamicTypeArgs/*<T extends DartType>*/(/*=T*/ t) {
  if (t is ParameterizedType) {
    var dyn = new List<DartType>.filled(
        t.typeArguments.length, DynamicTypeImpl.instance);
    return t.substitute2(dyn, t.typeArguments) as dynamic/*=T*/;
  }
  return t;
}

/// Given an annotated [node] and a [test] function, returns the first matching
/// constant valued annotation.
///
/// For example if we had the ClassDeclaration node for `FontElement`:
///
///    @js.JS('HTMLFontElement')
///    @deprecated
///    class FontElement { ... }
///
/// We could match `@deprecated` with a test function like:
///
///    (v) => v.type.name == 'Deprecated' && v.type.element.library.isDartCore
///
DartObject findAnnotation(Element element, bool test(DartObjectImpl value)) {
  for (var metadata in element.metadata) {
    var value = metadata.computeConstantValue();
    if (value != null && test(value)) return value;
  }
  return null;
}

/// Searches all supertype, in order of most derived members, to see if any
/// [match] a condition. If so, returns the first match, otherwise returns null.
InterfaceType findSupertype(InterfaceType type, bool match(InterfaceType t)) {
  for (var m in type.mixins.reversed) {
    if (match(m)) return m;
  }
  var s = type.superclass;
  if (s == null) return null;

  if (match(s)) return type;
  return findSupertype(s, match);
}

//TODO(leafp): Is this really necessary?  In theory I think
// the static type should always be filled in for resolved
// ASTs.  This may be a vestigial workaround.
DartType getStaticType(Expression e) =>
    e.staticType ?? DynamicTypeImpl.instance;

// TODO(leafp) Factor this out or use an existing library
/// Similar to [SimpleIdentifier] inGetterContext, inSetterContext, and
/// inDeclarationContext, this method returns true if [node] is used in an
/// invocation context such as a MethodInvocation.
bool inInvocationContext(SimpleIdentifier node) {
  var parent = node.parent;
  return parent is MethodInvocation && parent.methodName == node;
}

bool isInlineJS(Element e) =>
    e is FunctionElement &&
    e.name == 'JS' &&
    e.library.isInSdk &&
    e.library.source.uri.toString() == 'dart:_foreign_helper';

ExecutableElement getFunctionBodyElement(FunctionBody body) {
  var f = body.parent;
  if (f is FunctionExpression) {
    return f.element;
  } else if (f is MethodDeclaration) {
    return f.element;
  } else {
    return (f as ConstructorDeclaration).element;
  }
}

/// Returns the value of the `name` field from the [match]ing annotation on
/// [element], or `null` if we didn't find a valid match or it was not a string.
///
/// For example, consider this code:
///
///     class MyAnnotation {
///       final String name;
///       // ...
///       const MyAnnotation(this.name/*, ... other params ... */);
///     }
///
///     @MyAnnotation('FooBar')
///     main() { ... }
///
/// If we match the annotation for the `@MyAnnotation('FooBar')` this will
/// return the string 'FooBar'.
String getAnnotationName(Element element, bool match(DartObjectImpl value)) =>
    findAnnotation(element, match)?.getField('name')?.toStringValue();
