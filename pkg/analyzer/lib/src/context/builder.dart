// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

/// The name of the embedder files being searched for.
const String _embedderFileName = '_embedder.yaml';

/// Given the lib directory  of a 'sky_engine' package, locates an
/// `_embedder.yaml` file.
///
/// If the file can be found, and contains a top level [YamlMap], then
/// the [YamlMap] is returned. Otherwise, `null`` is returned.
YamlMap? locateEmbedderYamlFor(Folder libFolder) {
  File file = libFolder.getChildAssumingFile(_embedderFileName);
  try {
    var embedderYaml = file.readAsStringSync();
    try {
      if (loadYaml(embedderYaml) case YamlMap yaml) {
        return yaml;
      }
    } on Exception {
      // TODO(srawlins): If we ever get a malformed `_embedder.yaml` file, we
      // completely suppress the parse exception. We could instead wire up an
      // ErrorListener for the call to `loadYaml` above, and/or catch different
      // exceptions and write them to the instrumentation log.
    }
    return null;
  } on FileSystemException {
    // File can't be read.
    return null;
  }
}
