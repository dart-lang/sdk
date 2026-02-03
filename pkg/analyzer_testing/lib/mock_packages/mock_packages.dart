// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_testing/src/mock_packages/ffi/ffi.dart' as mock_ffi;
import 'package:analyzer_testing/src/mock_packages/fixnum/fixnum.dart'
    as mock_fixnum;
import 'package:analyzer_testing/src/mock_packages/flutter/animation.dart'
    as mock_flutter_animation;
import 'package:analyzer_testing/src/mock_packages/flutter/cupertino.dart'
    as mock_flutter_cupertino;
import 'package:analyzer_testing/src/mock_packages/flutter/foundation.dart'
    as mock_flutter_foundation;
import 'package:analyzer_testing/src/mock_packages/flutter/material.dart'
    as mock_flutter_material;
import 'package:analyzer_testing/src/mock_packages/flutter/painting.dart'
    as mock_flutter_painting;
import 'package:analyzer_testing/src/mock_packages/flutter/rendering.dart'
    as mock_flutter_rendering;
import 'package:analyzer_testing/src/mock_packages/flutter/widget_previews.dart'
    as mock_flutter_widget_previews;
import 'package:analyzer_testing/src/mock_packages/flutter/widgets.dart'
    as mock_flutter_widgets;
import 'package:analyzer_testing/src/mock_packages/meta/meta.dart' as mock_meta;
import 'package:analyzer_testing/src/mock_packages/mock_library.dart';
import 'package:analyzer_testing/src/mock_packages/test_reflective_loader/test_reflective_loader.dart'
    as mock_test_reflective_loader;
import 'package:analyzer_testing/src/mock_packages/ui/ui.dart' as mock_ui;
import 'package:analyzer_testing/src/mock_packages/vector_math/vector_math.dart'
    as mock_vector_math;
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path;

/// Helper for copying files from "tests/mock_packages" to memory file system
/// for Blaze.
class BlazeMockPackages {
  static final BlazeMockPackages instance = BlazeMockPackages._();

  BlazeMockPackages._();

  void addFlutter(ResourceProvider provider) {
    _addFiles(provider, 'flutter', [
      ...mock_flutter_animation.units,
      ...mock_flutter_cupertino.units,
      ...mock_flutter_foundation.units,
      ...mock_flutter_material.units,
      ...mock_flutter_painting.units,
      ...mock_flutter_rendering.units,
      ...mock_flutter_widget_previews.units,
      ...mock_flutter_widgets.units,
    ]);
  }

  void addMeta(ResourceProvider provider) {
    _addFiles(provider, 'meta', mock_meta.units);
  }

  /// Adds files of the given [packageName] to the [provider].
  Folder _addFiles(
    ResourceProvider provider,
    String packageName,
    List<MockLibraryUnit> units,
  ) {
    var absolutePackagePath = provider.convertPath(
      '/workspace/third_party/dart/$packageName',
    );
    for (var unit in units) {
      var absoluteUnitPath = provider.convertPath(
        '$absolutePackagePath/${unit.path}',
      );
      provider.getFile(absoluteUnitPath).writeAsStringSync(unit.content);
    }

    return provider.getFolder(absolutePackagePath);
  }
}

/// Helper for copying files from "test/mock_packages" to memory file system.
mixin MockPackagesMixin {
  /// The path to a folder where mock packages can be written.
  String get packagesRootPath;

  path.Context get pathContext => resourceProvider.pathContext;

  ResourceProvider get resourceProvider;

  Folder addFfi() {
    var packageFolder = _addFiles('ffi', mock_ffi.units);
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addFixnum() {
    var packageFolder = _addFiles('fixnum', mock_fixnum.units);
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addFlutter() {
    var packageFolder = _addFiles('flutter', [
      ...mock_flutter_animation.units,
      ...mock_flutter_cupertino.units,
      ...mock_flutter_foundation.units,
      ...mock_flutter_material.units,
      ...mock_flutter_painting.units,
      ...mock_flutter_rendering.units,
      ...mock_flutter_widget_previews.units,
      ...mock_flutter_widgets.units,
    ]);
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addMeta() {
    var packageFolder = _addFiles('meta', mock_meta.units);
    return packageFolder.getChildAssumingFolder('lib');
  }

  Folder addTestReflectiveLoader() {
    var packageFolder = _addFiles(
      'test_reflective_loader',
      mock_test_reflective_loader.units,
    );
    return packageFolder.getChildAssumingFolder('lib');
  }

  /// Adds a mock sky_engine package with an `_embedder.yaml` file, and returns
  /// the [Folder] of the sky_engine package's 'lib' directory.
  Folder addSkyEngine({required String sdkPath}) {
    // Emulate sky engine by writing to disk:
    // * a `sky_engine/lib` directory,
    // * a `sky_engine/lib/_embedder.yaml` file which points to the Dart SDK
    //   sources, and
    // * the `dart:ui` sources into `sky_engine/lib/ui`.
    var packageFolder = _addFiles('ui', mock_ui.units);

    var skyEngineFolder = resourceProvider.getFolder(
      resourceProvider.convertPath('$packagesRootPath/sky_engine'),
    )..create();
    var skyEngineLibFolder = skyEngineFolder.getChildAssumingFolder('lib')
      ..create();
    var embedderFile = skyEngineLibFolder.getChildAssumingFile(
      '_embedder.yaml',
    );
    // SDK-relative paths.
    var embeddedSdkLibRelativePaths = {
      'dart:async': 'lib/async/async.dart',
      'dart:collection': 'lib/collection/collection.dart',
      'dart:convert': 'lib/convert/convert.dart',
      'dart:core': 'lib/core/core.dart',
      'dart:developer': 'lib/developer/developer.dart',
      'dart:ffi': 'lib/ffi/ffi.dart',
      'dart:html': 'lib/html/dart2js/html_dart2js.dart',
      'dart:io': 'lib/io/io.dart',
      'dart:isolate': 'lib/isolate/isolate.dart',
      'dart:js': 'lib/js/js.dart',
      'dart:js_interop': 'lib/js/js_interop.dart',
      'dart:math': 'lib/math/math.dart',
      'dart:typed_data': 'lib/typed_data/typed_data.dart',
      'dart:_interceptors': 'lib/_interceptors/interceptors.dart',
      'dart:_internal': 'lib/internal/internal.dart',
    };
    // Build map of all absolute paths, including the project-specific dart:ui.
    var embeddedLibAbsolutePaths = {
      'dart:ui': path.join(packageFolder.path, 'lib', 'ui.dart'),
      for (var MapEntry(key: name, value: relativePath)
          in embeddedSdkLibRelativePaths.entries)
        // The paths above all use forward slashes, but we must use the correct
        // slashes for the platform here.
        name: path.join(
          sdkPath,
          relativePath.replaceAll(path.posix.separator, path.separator),
        ),
    };

    // Build the YAML file contents.
    var embeddedFileContents = StringBuffer();
    embeddedFileContents.writeln('embedded_libs:');
    for (var MapEntry(key: name, value: path)
        in embeddedLibAbsolutePaths.entries) {
      // Use jsonEncode to ensure escape is correct when the path contains
      // backslashes (Windows).
      embeddedFileContents.writeln(
        '  ${jsonEncode(name)}: ${jsonEncode(path)}',
      );
    }
    embedderFile.writeAsStringSync(embeddedFileContents.toString());

    return skyEngineLibFolder;
  }

  Folder addVectorMath() {
    var packageFolder = _addFiles('vector_math', mock_vector_math.units);
    return packageFolder.getChildAssumingFolder('lib');
  }

  /// Adds files of the given [packageName] to the [resourceProvider].
  Folder _addFiles(String packageName, List<MockLibraryUnit> units) {
    var absolutePackagePath = resourceProvider.convertPath(
      '$packagesRootPath/$packageName',
    );
    for (var unit in units) {
      var absoluteUnitPath = resourceProvider.convertPath(
        '$absolutePackagePath/${unit.path}',
      );
      resourceProvider
          .getFile(absoluteUnitPath)
          .writeAsStringSync(unit.content);
    }

    return resourceProvider.getFolder(absolutePackagePath);
  }
}
