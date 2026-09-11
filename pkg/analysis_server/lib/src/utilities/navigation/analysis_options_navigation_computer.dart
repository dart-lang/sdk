// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:yaml/yaml.dart';

/// Computes navigation targets for `include` directives in the analysis options
/// file at [path].
void computeAnalysisOptionsNavigation(
  ResourceProvider resourceProvider,
  NavigationCollector collector,
  SourceFactory? sourceFactory,
  String path,
  int offset,
  int length,
) {
  if (sourceFactory == null) return;

  var optionsFile = resourceProvider.getFile(path);
  YamlNode yamlNode;
  try {
    var content = optionsFile.readAsStringSync();
    yamlNode = loadYamlNode(content);
  } catch (_) {
    return;
  }

  if (yamlNode is! YamlMap) return;

  var includeNode = yamlNode.valueAt(AnalysisOptionsFileKeys.include);
  var includeNodes = switch (includeNode) {
    YamlScalar(value: String _) => [includeNode],
    YamlList(:var nodes) => [
      for (var node in nodes.whereType<YamlScalar>())
        if (node.value is String) node,
    ],
    _ => const <YamlScalar>[],
  };

  for (var node in includeNodes) {
    var uri = node.value;
    if (uri is! String || uri.isEmpty) continue;

    var nodeSpan = node.span;
    var nodeOffset = nodeSpan.start.offset;
    var nodeLength = nodeSpan.length;
    if (nodeLength == 0) continue;

    var isWithinRequestedRange =
        nodeOffset + nodeLength >= offset && nodeOffset <= offset + length;
    if (!isWithinRequestedRange) continue;

    var source = sourceFactory.resolveUri(FileSource(optionsFile), uri);
    if (source is FileSource && source.file.exists) {
      collector.addRegion(
        nodeOffset,
        nodeLength,
        protocol.ElementKind.FILE,
        protocol.Location(
          source.file.path,
          0,
          0,
          1,
          1,
          endLine: 1,
          endColumn: 1,
        ),
      );
    }
  }
}
