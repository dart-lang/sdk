// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dwds/src/readers/asset_reader.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

/// A reader for Dart sources and related source maps provided by the Frontend
/// Server.
class FrontendServerAssetReader implements AssetReader {
  final _logger = Logger('FrontendServerAssetReader');
  final File _mapOriginal;
  final File _mapIncremental;
  final File _jsonOriginal;
  final File _jsonIncremental;
  final String _packageRoot;
  final Future<PackageConfig> _packageConfig;
  final String _basePath;

  /// Map of Dart module server path to source map contents.
  final _mapContents = <String, String>{};

  bool _haveReadOriginals = false;

  /// Creates a [FrontendServerAssetReader].
  ///
  /// [outputPath] is the file path to the Frontend Server kernel file e.g.
  ///
  ///   /some/path/main.dart.dill
  ///
  /// Corresponding `.json` and `.map` files will be read relative to
  /// [outputPath].
  ///
  /// [_packageRoot] is the path to the directory that contains a
  /// `.dart_tool/package_config.json` file for the application.
  FrontendServerAssetReader({
    required String outputPath,
    required String packageRoot,
    String? basePath,
  }) : _packageRoot = packageRoot,
       _basePath = basePath ?? '',
       _mapOriginal = File('$outputPath.map'),
       _mapIncremental = File('$outputPath.incremental.map'),
       _jsonOriginal = File('$outputPath.json'),
       _jsonIncremental = File('$outputPath.incremental.json'),
       _packageConfig = loadPackageConfig(
         File(
           p.absolute(p.join(packageRoot, '.dart_tool/package_config.json')),
         ),
       );

  @override
  String get basePath => _basePath;

  @override
  Future<String?> dartSourceContents(String serverPath) async {
    if (serverPath.endsWith('.dart')) {
      final packageConfig = await _packageConfig;

      Uri? fileUri;
      if (serverPath.startsWith('packages/')) {
        final packagePath = serverPath.replaceFirst('packages/', 'package:');
        fileUri = packageConfig.resolve(Uri.parse(packagePath));
      } else {
        fileUri = p.toUri(p.join(_packageRoot, serverPath));
      }
      if (fileUri != null) {
        final source = File(fileUri.toFilePath());
        if (source.existsSync()) return source.readAsString();
      }
    }
    _logger.severe('Cannot find source contents for $serverPath');
    return null;
  }

  @override
  Future<String?> sourceMapContents(String serverPath) async {
    if (serverPath.endsWith('lib.js.map')) {
      if (!serverPath.startsWith('/')) serverPath = '/$serverPath';
      // Strip the .map, sources are looked up by their js path.
      serverPath = p.withoutExtension(serverPath);
      if (_mapContents.containsKey(serverPath)) {
        return _mapContents[serverPath];
      }
    }
    _logger.severe('Cannot find source map contents for $serverPath');
    return null;
  }

  /// Updates the internal caches by reading the Frontend Server output files.
  ///
  /// Will only read the incremental files on additional calls.
  void updateCaches() {
    if (!_haveReadOriginals) {
      _updateCaches(_mapOriginal, _jsonOriginal);
      _haveReadOriginals = true;
    } else {
      _updateCaches(_mapIncremental, _jsonIncremental);
    }
  }

  void _updateCaches(File map, File json) {
    if (!(map.existsSync() && json.existsSync())) {
      throw StateError('$map and $json do not exist.');
    }
    final sourceContents = map.readAsBytesSync();
    final sourceInfo =
        jsonDecode(json.readAsStringSync()) as Map<String, dynamic>;
    for (final key in sourceInfo.keys) {
      final info = sourceInfo[key] as Map<String, dynamic>;
      final sourcemapOffsets = info['sourcemap'] as List<dynamic>;
      _mapContents[key] = utf8.decode(
        sourceContents
            .getRange(sourcemapOffsets[0] as int, sourcemapOffsets[1] as int)
            .toList(),
      );
    }
  }

  @override
  Future<String> metadataContents(String serverPath) {
    // TODO(grouma) - Implement the merged metadata reader.
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}
}
