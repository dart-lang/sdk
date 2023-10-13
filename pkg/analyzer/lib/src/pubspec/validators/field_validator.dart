// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:yaml/yaml.dart';

const _deprecatedFields = [
  'author',
  'authors',
  'transformers',
  'web',
];

/// Validate fields.
void fieldValidator(PubspecValidationContext ctx) {
  final contents = ctx.contents;
  if (contents is! YamlMap) {
    return;
  }
  for (var field in contents.nodes.keys) {
    var name = ctx.asString(field);
    if (field is YamlNode && name != null && _deprecatedFields.contains(name)) {
      ctx.reportErrorForNode(
          field, PubspecWarningCode.DEPRECATED_FIELD, [name]);
    }
  }
}
