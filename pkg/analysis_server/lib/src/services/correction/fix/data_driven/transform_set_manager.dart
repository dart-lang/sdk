// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_parser.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:meta/meta.dart';

/// An object used to manage the transform sets.
class TransformSetManager {
  /// The single instance of this class.
  static final TransformSetManager instance = TransformSetManager._();

  /// The name of the data file.
  static const String dataFileName = 'fix_data.yaml';

  /// The name of the data folder.
  static const String dataFolderName = 'fix_data';

  /// The cache for the list of [TransformSet] for a given [Folder].
  final Map<Folder, List<TransformSet>> _cache = {};

  /// The cache for [TransformSet] of the SDK.
  TransformSet? _sdkCache;

  /// Initialize a newly created transform set manager.
  TransformSetManager._();

  /// Clear the internal cache.
  @visibleForTesting
  void clearCache() {
    _cache.clear();
    _sdkCache = null;
  }

  /// Return the transform sets associated with the [library].
  List<TransformSet> forLibrary(LibraryElement library) {
    var transformSets = <TransformSet>[];
    var analysisContext = library.session.analysisContext;
    var workspace = analysisContext.contextRoot.workspace;
    var libraryPath = library.source.fullName;
    var package = workspace.findPackageFor(libraryPath);
    if (package == null) {
      return transformSets;
    }
    var packages = package.packagesAvailableTo(libraryPath);
    for (var package in packages.packages) {
      var folder = package.libFolder;
      transformSets.addAll(fromFolder(folder));
    }
    if (_sdkCache != null) {
      transformSets.add(_sdkCache!);
    } else {
      var sdkRoot = analysisContext.sdkRoot;
      if (sdkRoot != null) {
        var file = sdkRoot.getChildAssumingFile('lib/_internal/$dataFileName');
        var transformSet = _loadTransformSet(file, null);
        if (transformSet != null) {
          transformSets.add(transformSet);
          _sdkCache = transformSet;
        }
      }
    }
    return transformSets;
  }

  List<TransformSet> fromFolder(Folder folder, {String? packageName}) {
    var cache = _cache[folder];
    if (cache != null) return cache;

    packageName ??= folder.parent.shortName;
    var transformSets = <TransformSet>[];
    var file = folder.getChildAssumingFile(dataFileName);
    var transformSet = _loadTransformSet(file, packageName);
    if (transformSet != null) {
      transformSets.add(transformSet);
    }
    var childFolder = folder.getChildAssumingFolder(dataFolderName);
    if (childFolder.exists) {
      _loadTransforms(transformSets, childFolder, packageName);
    }
    _cache[folder] = transformSets;
    return transformSets;
  }

  /// Recursively search all the children of the specified [folder],
  /// and add the transform sets found to the [transforms].
  void _loadTransforms(
      List<TransformSet> transforms, Folder folder, String packageName) {
    for (var resource in folder.getChildren()) {
      if (resource is File) {
        if (resource.shortName.endsWith('.yaml')) {
          var transformSet = _loadTransformSet(resource, packageName);
          if (transformSet != null) {
            transforms.add(transformSet);
          }
        }
      } else if (resource is Folder) {
        _loadTransforms(transforms, resource, packageName);
      }
    }
  }

  /// Read the [file] and parse the content. Return the transform set that was
  /// parsed, or `null` if the file doesn't exist, isn't readable, or if the
  /// content couldn't be parsed.
  TransformSet? _loadTransformSet(File file, String? packageName) {
    try {
      var content = file.readAsStringSync();
      var parser = TransformSetParser(
          ErrorReporter(
            AnalysisErrorListener.NULL_LISTENER,
            file.createSource(),
            isNonNullableByDefault: false,
          ),
          packageName);
      return parser.parse(content);
    } on FileSystemException {
      // Fall through to return `null`.
    }
    return null;
  }
}
