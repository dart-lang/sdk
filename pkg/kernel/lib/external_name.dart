// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.external_name;

import 'ast.dart';
import 'core_types.dart';

/// Returns external (native) name of given [Member].
String? getExternalName(CoreTypes coreTypes, Member procedure) {
  // Native procedures are marked as external and have an annotation,
  // which looks like this:
  //
  //    @pragma("vm:external-name", "<name-of-native>")
  //    external Object foo(arg0, ...);
  //
  // Previously the following encoding was used, which is still supported
  // until all users are migrated away from it:
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
    final String? value = _getExternalNameValue(coreTypes, annotation);
    if (value != null) {
      return value;
    }
  }
  return null;
}

String? _getExternalNameValue(CoreTypes coreTypes, Expression annotation) {
  if (annotation is ConstantExpression) {
    final Constant constant = annotation.constant;
    if (constant is InstanceConstant) {
      if (_isExternalName(constant.classNode)) {
        return (constant.fieldValues.values.single as StringConstant).value;
      } else if (_isPragma(constant.classNode)) {
        final String pragmaName =
            (constant.fieldValues[coreTypes.pragmaName.fieldReference]
                    as StringConstant)
                .value;
        final Constant? pragmaOptionsValue =
            constant.fieldValues[coreTypes.pragmaOptions.fieldReference];
        final String? pragmaOptions = pragmaOptionsValue is StringConstant
            ? pragmaOptionsValue.value
            : null;
        if (pragmaName == _externalNamePragma && pragmaOptions != null) {
          return pragmaOptions;
        }
      }
    }
  }
  return null;
}

bool _isExternalName(Class klass) =>
    klass.name == 'ExternalName' &&
    klass.enclosingLibrary.importUri.toString() == 'dart:_internal';

bool _isPragma(Class klass) =>
    klass.name == 'pragma' &&
    klass.enclosingLibrary.importUri.toString() == 'dart:core';

const String _externalNamePragma = 'vm:external-name';
