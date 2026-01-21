// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

/// Given a package map, check in each package's lib directory for the existence
/// of an `_embedder.yaml` file. If the file contains a top level YamlMap, it
/// will be added to the [embedderYamls] map.
class EmbedderYamlLocator {
  /// The name of the embedder files being searched for.
  static const String _embedderFileName = '_embedder.yaml';

  /// A mapping from a package's library directory to the parsed [YamlMap].
  final Map<Folder, YamlMap> embedderYamls;

  /// Initialize with the given [libFolder] of `sky_engine` package.
  EmbedderYamlLocator.forLibFolder(Folder libFolder)
    : embedderYamls = _findEmbedderYaml(libFolder);

  static Map<Folder, YamlMap> _findEmbedderYaml(Folder libFolder) {
    File file = libFolder.getChildAssumingFile(_embedderFileName);
    try {
      String? embedderYaml = file.readAsStringSync();
      return _processEmbedderYaml(libFolder, embedderYaml);
    } on FileSystemException {
      // File can't be read.
      return const {};
    }
  }

  /// Given the YAML for an embedder ([embedderYaml]) and a folder ([libDir]),
  /// returns the URI mapping.
  static Map<Folder, YamlMap> _processEmbedderYaml(
    Folder libDir,
    String embedderYaml,
  ) {
    try {
      if (loadYaml(embedderYaml) case YamlMap yaml) {
        return {libDir: yaml};
      }
    } catch (_) {
      // Ignored.
    }
    return const {};
  }
}
