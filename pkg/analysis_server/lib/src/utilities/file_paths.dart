// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The set of constants and utilities to check file paths.
///
/// The recommended import prefix is `file_paths`.
// TODO(srawlins): Move package:analyzer/src/util/file_paths.dart constants
// here: `fixDataYaml`, `fixDataYamlFolder`, `isFixDataYaml`.
library;

import 'package:analyzer/file_system/file_system.dart';

/// The name of analyzer plugin entrpoint files.
const String pluginEntrypointDart = 'plugin.dart';

extension FolderExtension on Folder {
  File get pluginEntrypoint => getFolder('bin').getFile(pluginEntrypointDart);
}
