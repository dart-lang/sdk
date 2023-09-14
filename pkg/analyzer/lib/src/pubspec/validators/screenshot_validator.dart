// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Validate screenshots.
void screenshotsValidator(PubspecValidationContext ctx) {
  bool fileExistsAtPath(String filePath) {
    final context = ctx.provider.pathContext;
    final normalizedEntry = context.joinAll(p.posix.split(filePath));
    final directoryRoot = context.dirname(ctx.source.fullName);
    final fullPath = context.join(directoryRoot, normalizedEntry);
    final file = ctx.provider.getFile(fullPath);
    return file.exists;
  }

  final screenshots = ctx.contents[PubspecField.SCREENSHOTS_FIELD];
  if (screenshots is! YamlList) return;
  for (final entry in screenshots) {
    if (entry is! YamlMap) continue;
    final entryValue = entry.valueAt(PubspecField.PATH_FIELD);
    if (entryValue is! YamlScalar) continue;
    final path = entryValue.value;
    if (path is String && !fileExistsAtPath(path)) {
      ctx.reportErrorForNode(
        entryValue,
        PubspecWarningCode.PATH_DOES_NOT_EXIST,
        [entryValue.valueOrThrow],
      );
    }
  }
}
