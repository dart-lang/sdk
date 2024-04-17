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
    var context = ctx.provider.pathContext;
    var normalizedEntry = context.joinAll(p.posix.split(filePath));
    var directoryRoot = context.dirname(ctx.source.fullName);
    var fullPath = context.join(directoryRoot, normalizedEntry);
    var file = ctx.provider.getFile(fullPath);
    return file.exists;
  }

  var contents = ctx.contents;
  if (contents is! YamlMap) return;
  var screenshots = contents[PubspecField.SCREENSHOTS_FIELD];
  if (screenshots is! YamlList) return;
  for (var entry in screenshots) {
    if (entry is! YamlMap) continue;
    var entryValue = entry.valueAt(PubspecField.PATH_FIELD);
    if (entryValue is! YamlScalar) continue;
    var path = entryValue.value;
    if (path is String && !fileExistsAtPath(path)) {
      ctx.reportErrorForNode(
        entryValue,
        PubspecWarningCode.PATH_DOES_NOT_EXIST,
        [entryValue.valueOrThrow],
      );
    }
  }
}
