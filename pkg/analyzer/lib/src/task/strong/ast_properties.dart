// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Properties that result from Strong Mode analysis on an AST.
///
/// These properties are not public, but provided by use of back-ends such as
/// Dart Dev Compiler.
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

const String _hasImplicitCasts = '_hasImplicitCasts';
const String _implicitOperationCast = '_implicitAssignmentCast';
const String _implicitCast = '_implicitCast';
const String _isDynamicInvoke = '_isDynamicInvoke';
const String _classCovariantParameters = '_classCovariantParameters';
const String _superclassCovariantParameters = '_superclassCovariantParameters';
const String _covariantGenericReturn = '_covariantGenericReturn';
const String _covariantPrivateFields = '_covariantPrivateFields';
const String _covariantPrivateMembers = '_covariantPrivateMembers';

/// If this expression needs an implicit cast on a subexpression that cannot be
/// expressed anywhere else, returns the type it is coerced to.
///
/// For example, op-assign can have an implicit cast on the final assignment,
/// and MethodInvocation calls on functions (`obj.f()` where `obj.f` is an
/// accessor and not a real method) can need a cast on the function.
DartType getImplicitOperationCast(Expression node) {
  return node.getProperty/*<DartType>*/(_implicitOperationCast);
}

/// If this expression has an implicit cast, returns the type it is coerced to,
/// otherwise returns null.
DartType getImplicitCast(Expression node) {
  return node.getProperty/*<DartType>*/(_implicitCast);
}

/// True if this compilation unit has any implicit casts, otherwise false.
///
/// See also [getImplicitCast].
bool hasImplicitCasts(CompilationUnit node) {
  return node.getProperty/*<bool>*/(_hasImplicitCasts) ?? false;
}

/// True if this node is a dynamic operation that requires dispatch and/or
/// checking at runtime.
bool isDynamicInvoke(Expression node) {
  return node.getProperty/*<bool>*/(_isDynamicInvoke) ?? false;
}

/// Sets [hasImplicitCasts] property for this compilation unit.
void setHasImplicitCasts(CompilationUnit node, bool value) {
  node.setProperty(_hasImplicitCasts, value == true ? true : null);
}

/// Sets the result of [getImplicitOperationCast] for this node.
void setImplicitOperationCast(Expression node, DartType type) {
  node.setProperty(_implicitOperationCast, type);
}

/// Sets the result of [getImplicitCast] for this node.
void setImplicitCast(Expression node, DartType type) {
  node.setProperty(_implicitCast, type);
}

/// Sets [isDynamicInvoke] property for this expression.
void setIsDynamicInvoke(Expression node, bool value) {
  node.setProperty(_isDynamicInvoke, value == true ? true : null);
}

/// Returns a list of parameters and method type parameters in this class
/// declaration that need a check at runtime to ensure soundness.
Set<Element> getClassCovariantParameters(Declaration node) {
  return node.getProperty(_classCovariantParameters);
}

/// Sets [getClassCovariantParameters] property for this class.
void setClassCovariantParameters(Declaration node, Set<Element> value) {
  node.setProperty(_classCovariantParameters, value);
}

/// Returns a list of parameters and method type parameters from mixins and
/// superclasses of this class that need a stub method to check their type at
/// runtime for soundness.
Set<Element> getSuperclassCovariantParameters(Declaration node) {
  return node.getProperty(_superclassCovariantParameters);
}

/// Sets [getSuperclassCovariantParameters] property for this class.
void setSuperclassCovariantParameters(Declaration node, Set<Element> value) {
  node.setProperty(_superclassCovariantParameters, value);
}

/// Gets the private setters and methods that are accessed unsafely from
/// this compilation unit.
///
/// These members will require a check.
Set<ExecutableElement> getCovariantPrivateMembers(CompilationUnit node) {
  return node.getProperty(_covariantPrivateMembers);
}

/// Sets [getCovariantPrivateMembers] property for this compilation unit.
void setCovariantPrivateMembers(
    CompilationUnit node, Set<ExecutableElement> value) {
  node.setProperty(_covariantPrivateMembers, value);
}
