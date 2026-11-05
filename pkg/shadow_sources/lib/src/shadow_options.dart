// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/resolve_input_uri.dart'
    as front_end;
import 'package:args/args.dart';
import 'package:build_integration/file_system/multi_root.dart'
    as front_end
    show MultiRootFileSystem;
import 'package:front_end/src/api_unstable/vm.dart'
    as front_end
    show FileSystem;
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:vm/kernel_front_end.dart' show createFrontEndFileSystem;

/// Configuration options for `shadowSources` and [SourceShadowTransformer].
class ShadowOptions {
  /// Dynamic module entrypoint script path.
  final Uri scriptUri;

  /// package_config.json path.
  final Uri packagesUri;

  /// dynamic_interface.yaml path.
  final Uri dynamicInterfaceUri;

  /// Used for reading sources and multi-root virtual file system.
  final front_end.FileSystem frontendFs;

  /// Prefix to apply to shadowed package names.
  final String prefix;

  /// Output directory for shadowed sources.
  final Uri outputDir;

  /// Whether to enable relative library URIs in the dynamic interface.
  ///
  /// Relative URIs without a scheme in a dynamic interface are resolved using
  /// the [dynamicInterfaceUri]. Relative URIs without a scheme in entrypoint
  /// script directives are resolved using the [scriptUri].
  ///
  /// This flag makes sure that we can compare these resolution results (i.e.
  /// both [dynamicInterfaceUri] and [scriptUri] are absolute and in the same
  /// scheme).
  final bool enableRelativeDynamicInterfaceLibraries;

  /// Whether to enable relative directive URIs in the entrypoint [scriptUri].
  ///
  /// These relative URIs are resolved using the [scriptUri], while a package
  /// config resolves package: URIs according to the [packagesUri] and the
  /// package config contents.
  ///
  /// To make sure that we can compare resolution results (i.e. figure out that
  /// `import 'foo.dart'` and `import 'package:bar/foo.dart'` refer to the same
  /// library), [scriptUri] and [packagesUri] must both be absolute and in
  /// the same scheme.
  final bool enableRelativeEntrypointScriptDirectives;

  ShadowOptions._({
    required this.scriptUri,
    required this.packagesUri,
    required this.dynamicInterfaceUri,
    required this.frontendFs,
    required this.prefix,
    required this.outputDir,
  }) : enableRelativeDynamicInterfaceLibraries =
           dynamicInterfaceUri.scheme == scriptUri.scheme &&
           dynamicInterfaceUri.isAbsolute &&
           scriptUri.isAbsolute,
       enableRelativeEntrypointScriptDirectives =
           scriptUri.scheme == packagesUri.scheme &&
           scriptUri.isAbsolute &&
           packagesUri.isAbsolute;

  /// Convenience wrapper for parsing command line arguments.
  ///
  /// Does minimal validation and conversion of arguments, relying on
  /// [ShadowOptions.create].
  static ShadowOptions fromArgs(List<String> args) {
    final results = _parser.parse(args);

    final frontendFs = createFrontEndFileSystem(
      results.option('filesystem-scheme'),
      results.multiOption('filesystem-root'),
    );

    return ShadowOptions.create(
      scriptUri: results.option('script')!,
      packagesUri: results.option('packages')!,
      dynamicInterfaceUri: results.option('dynamic-interface')!,
      frontendFs: frontendFs,
      prefix: results.option('prefix')!,
      outputDir: results.option('output-dir')!,
    );
  }

  /// Creates and validates [ShadowOptions].
  static ShadowOptions create({
    required String scriptUri,
    required String packagesUri,
    required String dynamicInterfaceUri,
    required front_end.FileSystem frontendFs,
    required String prefix,
    required String outputDir,
  }) {
    validatePrefix(prefix);

    final isMultiRoot = frontendFs is front_end.MultiRootFileSystem;
    final multiRootFilesystemScheme = isMultiRoot
        ? frontendFs.markerScheme
        : null;

    final resolvedScriptUri = front_end.resolveInputUri(scriptUri);
    final resolvedPackagesUri = front_end.resolveInputUri(packagesUri);
    final resolvedDynamicInterfaceUri = front_end.resolveInputUri(
      dynamicInterfaceUri,
    );
    var resolvedOutputDir = front_end.resolveInputUri(outputDir);
    if (!resolvedOutputDir.path.endsWith('/')) {
      resolvedOutputDir = resolvedOutputDir.replace(
        path: '${resolvedOutputDir.path}/',
      );
    }
    if (isMultiRoot && resolvedOutputDir.scheme == multiRootFilesystemScheme) {
      throw ArgumentError.value(
        outputDir,
        'outputDir',
        'Cannot write to multi-root filesystem. '
            'Please use file: URI or a path.',
      );
    }

    return ShadowOptions._(
      scriptUri: resolvedScriptUri,
      packagesUri: resolvedPackagesUri,
      dynamicInterfaceUri: resolvedDynamicInterfaceUri,
      frontendFs: frontendFs,
      prefix: prefix,
      outputDir: resolvedOutputDir,
    );
  }
}

/// Validates that [prefix] consists of valid prefix characters [a-z0-9_.].
@visibleForTesting
void validatePrefix(String prefix) {
  if (!_validPrefixRegExp.hasMatch(prefix)) {
    throw ArgumentError.value(
      prefix,
      'prefix',
      'Prefix must contain valid Dart package name characters [a-z0-9_.]',
    );
  }
}

final _validPrefixRegExp = RegExp(r'^[a-z0-9_.]+$');

final _parser = ArgParser()
  ..addOption(
    'script',
    abbr: 's',
    mandatory: true,
    help: 'URI to the entrypoint script file.',
  )
  ..addOption(
    'packages',
    abbr: 'p',
    mandatory: true,
    help: 'Path or URI to input packages config JSON file.',
  )
  ..addOption(
    'dynamic-interface',
    abbr: 'd',
    mandatory: true,
    help: 'Path or URI to dynamic_interface.yaml file.',
  )
  ..addMultiOption(
    'filesystem-root',
    abbr: 'r',
    help: 'Filesystem root directories.',
  )
  ..addOption(
    'filesystem-scheme',
    help: 'The URI scheme for the multi-root virtual filesystem.',
  )
  ..addOption(
    'prefix',
    abbr: 'i',
    mandatory: true,
    help: 'Import prefix string to disambiguate shadowed dependencies.',
  )
  ..addOption(
    'output-dir',
    abbr: 'o',
    mandatory: true,
    help: 'Output directory for shadowed sources.',
  );
