// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:yaml/yaml.dart';

/// Validate the value of the required `name` field.
void nameValidator(PubspecValidationContext ctx) {
  var contents = ctx.contents;
  if (contents is! YamlMap) {
    ctx.reporter.atOffset(
      offset: 0,
      length: 0,
      diagnosticCode: PubspecWarningCode.missingName,
    );
    return;
  }
  var nameField = contents.nodes[PubspecField.NAME_FIELD];
  if (nameField == null) {
    ctx.reporter.atOffset(
      offset: 0,
      length: 0,
      diagnosticCode: PubspecWarningCode.missingName,
    );
  } else if (nameField is! YamlScalar || nameField.value is! String) {
    ctx.reportErrorForNode(nameField, PubspecWarningCode.nameNotString);
  }
}
