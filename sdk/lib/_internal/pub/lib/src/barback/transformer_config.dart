// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.transformer_config;

import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import 'transformer_id.dart';

/// The configuration for a transformer.
///
/// This corresponds to the transformers listed in a pubspec, which have both an
/// [id] indicating the location of the transformer and configuration specific
/// to that use of the transformer.
class TransformerConfig {
  /// The [id] of the transformer [this] is configuring.
  final TransformerId id;

  /// The configuration to pass to the transformer.
  ///
  /// Any pub-specific configuration (i.e. keys starting with "$") will have
  /// been stripped out of this and handled separately. This will be an empty
  /// map if no configuration was provided.
  final Map configuration;

  /// The source span from which this configuration was parsed.
  final SourceSpan span;

  /// The primary input inclusions.
  ///
  /// Each inclusion is an asset path. If this set is non-empty, then *only*
  /// matching assets are allowed as a primary input by this transformer. If
  /// `null`, all assets are included.
  ///
  /// This is processed before [excludes]. If a transformer has both includes
  /// and excludes, then the set of included assets is determined and assets
  /// are excluded from that resulting set.
  final Set<String> includes;

  /// The primary input exclusions.
  ///
  /// Any asset whose pach is in this is not allowed as a primary input by
  /// this transformer.
  ///
  /// This is processed after [includes]. If a transformer has both includes
  /// and excludes, then the set of included assets is determined and assets
  /// are excluded from that resulting set.
  final Set<String> excludes;

  /// Returns whether this config excludes certain asset ids from being
  /// processed.
  bool get hasExclusions => includes != null || excludes != null;

  /// Returns whether this transformer might transform a file that's visible to
  /// the package's dependers.
  bool get canTransformPublicFiles {
    if (includes == null) return true;
    return includes.any((path) =>
        p.url.isWithin('lib', path) || p.url.isWithin('bin', path));
  }

  /// Parses [identifier] as a [TransformerId] with [configuration].
  ///
  /// [identifierSpan] is the source span for [identifier].
  factory TransformerConfig.parse(String identifier, SourceSpan identifierSpan,
        YamlMap configuration) =>
      new TransformerConfig(new TransformerId.parse(identifier, identifierSpan),
          configuration);

  factory TransformerConfig(TransformerId id, YamlMap configurationNode) {
    parseField(key) {
      if (!configurationNode.containsKey(key)) return null;
      var fieldNode = configurationNode.nodes[key];
      var field = fieldNode.value;

      if (field is String) return new Set.from([field]);

      if (field is List) {
        for (var node in field.nodes) {
          if (node.value is String) continue;
          throw new SourceSpanFormatException(
              '"$key" field may contain only strings.', node.span);
        }

        return new Set.from(field);
      } else {
        throw new SourceSpanFormatException(
            '"$key" field must be a string or list.', fieldNode.span);
      }
    }

    var includes = null;
    var excludes = null;

    var configuration;
    var span;
    if (configurationNode == null) {
      configuration = {};
      span = id.span;
    } else {
      // Don't write to the immutable YAML map.
      configuration = new Map.from(configurationNode);
      span = configurationNode.span;

      // Pull out the exclusions/inclusions.
      includes = parseField("\$include");
      configuration.remove("\$include");
      excludes = parseField("\$exclude");
      configuration.remove("\$exclude");

      // All other keys starting with "$" are unexpected.
      for (var key in configuration.keys) {
        if (key is! String || !key.startsWith(r'$')) continue;
        throw new SourceSpanFormatException(
            'Unknown reserved field.', configurationNode.nodes[key].span);
      }
    }

    return new TransformerConfig._(id, configuration, span, includes, excludes);
  }

  TransformerConfig._(
      this.id, this.configuration, this.span, this.includes, this.excludes);

  String toString() => id.toString();

  /// Returns whether the include/exclude rules allow the transformer to run on
  /// [pathWithinPackage].
  ///
  /// [pathWithinPackage] must be a URL-style path relative to the containing
  /// package's root directory.
  bool canTransform(String pathWithinPackage) {
    // TODO(rnystrom): Support globs in addition to paths. See #17093.
    if (excludes != null) {
      // If there are any excludes, it must not match any of them.
      if (excludes.contains(pathWithinPackage)) return false;
    }

    // If there are any includes, it must match one of them.
    return includes == null || includes.contains(pathWithinPackage);
  }
}
