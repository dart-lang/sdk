// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:yaml/yaml.dart';

/// Validate the value of the required `name` field.
void nameValidator(PubspecValidationContext ctx) {
  var contents = ctx.contents;
  if (contents is! YamlMap) {
    ctx.reporter.report(diag.missingName.atOffset(offset: 0, length: 0));
    return;
  }
  var nameField = contents.nodes[PubspecField.NAME_FIELD];
  if (nameField == null) {
    ctx.reporter.report(diag.missingName.atOffset(offset: 0, length: 0));
  } else if (nameField is! YamlScalar || nameField.value is! String) {
    ctx.reportErrorForNode(nameField, diag.nameNotString);
  }
}
