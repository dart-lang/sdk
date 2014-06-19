// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.transformer_config;

import '../utils.dart';
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

  /// Parses [identifier] as a [TransformerId].
  factory TransformerConfig.parse(String identifier, Map configuration) =>
      new TransformerConfig(new TransformerId.parse(identifier), configuration);

  factory TransformerConfig(TransformerId id, Map configuration) {
    parseField(key) {
      if (!configuration.containsKey(key)) return null;
      var field = configuration.remove(key);

      if (field is String) return new Set<String>.from([field]);

      if (field is List) {
        var nonstrings = field
            .where((element) => element is! String)
            .map((element) => '"$element"');

        if (nonstrings.isNotEmpty) {
          throw new FormatException(
              '"$key" list field may only contain strings, but contained '
              '${toSentence(nonstrings)}.');
        }

        return new Set<String>.from(field);
      } else {
        throw new FormatException(
            '"$key" field must be a string or list, but was "$field".');
      }
    }

    var includes = null;
    var excludes = null;

    if (configuration == null) {
      configuration = {};
    } else {
      // Don't write to the immutable YAML map.
      configuration = new Map.from(configuration);

      // Pull out the exclusions/inclusions.
      includes = parseField("\$include");
      excludes = parseField("\$exclude");

      // All other keys starting with "$" are unexpected.
      var reservedKeys = configuration.keys
          .where((key) => key is String && key.startsWith(r'$'))
          .map((key) => '"$key"');

      if (reservedKeys.isNotEmpty) {
        throw new FormatException(
            'Unknown reserved ${pluralize('field', reservedKeys.length)} '
            '${toSentence(reservedKeys)}.');
      }
    }

    return new TransformerConfig._(id, configuration, includes, excludes);
  }

  TransformerConfig._(
      this.id, this.configuration, this.includes, this.excludes);

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
