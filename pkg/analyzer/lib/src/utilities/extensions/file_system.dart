// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:path/path.dart';

extension FolderExtension on Folder {
  /// Returns the existing analysis options file in the target, or `null`.
  File? get existingAnalysisOptionsYamlFile {
    return getExistingFile(file_paths.analysisOptionsYaml);
  }

  /// Return the analysis options file to be used for files in the target.
  File? findAnalysisOptionsYamlFile() {
    for (var current in withAncestors) {
      var file = current.existingAnalysisOptionsYamlFile;
      if (file != null) {
        return file;
      }
    }
    return null;
  }

  /// If the target contains an existing file with the given [name], then
  /// returns it. Otherwise, return `null`.
  File? getExistingFile(String name) {
    var file = getChildAssumingFile(name);
    return file.exists ? file : null;
  }
}

extension ResourceExtension on Resource {
  /// If the path style is `Windows`, returns the corresponding Posix path.
  /// Otherwise the path is already a Posix path, and it is returned as is.
  String get posixPath {
    var pathContext = provider.pathContext;
    if (pathContext.style == Style.windows) {
      var components = pathContext.split(path);
      return '/${components.skip(1).join('/')}';
    } else {
      return path;
    }
  }

  bool endsWithNames(List<String> expected) {
    return provider.pathContext.split(path).endsWith(expected);
  }
}
