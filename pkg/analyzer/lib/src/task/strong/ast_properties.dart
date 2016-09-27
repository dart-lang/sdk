// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Properties that result from Strong Mode analysis on an AST.
///
/// These properties are not public, but provided by use of back-ends such as
/// Dart Dev Compiler.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/type.dart';

const String _implicitAssignmentCast = '_implicitAssignmentCast';
const String _implicitCast = '_implicitCast';
const String _hasImplicitCasts = '_hasImplicitCasts';
const String _isDynamicInvoke = '_isDynamicInvoke';

/// True if this compilation unit has any implicit casts, otherwise false.
///
/// See also [getImplicitCast].
bool hasImplicitCasts(CompilationUnit node) {
  return node.getProperty/*<bool>*/(_hasImplicitCasts) ?? false;
}

/// Sets [hasImplicitCasts] property for this compilation unit.
void setHasImplicitCasts(CompilationUnit node, bool value) {
  node.setProperty(_hasImplicitCasts, value == true ? true : null);
}

/// If this expression has an implicit cast, returns the type it is coerced to,
/// otherwise returns null.
DartType getImplicitCast(Expression node) {
  return node.getProperty/*<DartType>*/(_implicitCast);
}

/// Sets the result of [getImplicitCast] for this node.
void setImplicitCast(Expression node, DartType type) {
  node.setProperty(_implicitCast, type);
}

/// If this op-assign has an implicit cast on the assignment, returns the type
/// it is coerced to, otherwise returns null.
DartType getImplicitAssignmentCast(Expression node) {
  return node.getProperty/*<DartType>*/(_implicitAssignmentCast);
}

/// Sets the result of [getImplicitAssignmentCast] for this node.
void setImplicitAssignmentCast(Expression node, DartType type) {
  node.setProperty(_implicitAssignmentCast, type);
}

/// True if this node is a dynamic operation that requires dispatch and/or
/// checking at runtime.
bool isDynamicInvoke(Expression node) {
  return node.getProperty/*<bool>*/(_isDynamicInvoke) ?? false;
}

/// Sets [isDynamicInvoke] property for this expression
void setIsDynamicInvoke(Expression node, bool value) {
  node.setProperty(_isDynamicInvoke, value == true ? true : null);
}
