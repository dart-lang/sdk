// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.external_name;

import 'ast.dart';

/// Returns external (native) name of given [Member].
String getExternalName(Member procedure) {
  // Native procedures are marked as external and have an annotation,
  // which looks like this:
  //
  //    import 'dart:_internal' as internal;
  //
  //    @internal.ExternalName("<name-of-native>")
  //    external Object foo(arg0, ...);
  //
  if (!procedure.isExternal) {
    return null;
  }
  for (final Expression annotation in procedure.annotations) {
    final String value = _getExternalNameValue(annotation);
    if (value != null) {
      return value;
    }
  }
  return null;
}

/// Returns native extension URIs for given [library].
List<String> getNativeExtensionUris(Library library) {
  final List<String> uris = <String>[];
  for (Expression annotation in library.annotations) {
    final String value = _getExternalNameValue(annotation);
    if (value != null) {
      uris.add(value);
    }
  }
  return uris;
}

String _getExternalNameValue(Expression annotation) {
  if (annotation is ConstructorInvocation) {
    if (_isExternalName(annotation.target.enclosingClass)) {
      return (annotation.arguments.positional.single as StringLiteral).value;
    }
  } else if (annotation is ConstantExpression) {
    final Constant constant = annotation.constant;
    if (constant is InstanceConstant) {
      if (_isExternalName(constant.classNode)) {
        return (constant.fieldValues.values.single as StringConstant).value;
      }
    }
  }
  return null;
}

bool _isExternalName(Class klass) =>
    klass.name == 'ExternalName' &&
    klass.enclosingLibrary.importUri.toString() == 'dart:_internal';
