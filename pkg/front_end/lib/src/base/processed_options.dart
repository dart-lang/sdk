// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/file_system.dart';
import 'package:front_end/src/base/uri_resolver.dart';
import 'package:package_config/packages_file.dart' as package_config;

/// Wrapper around [CompilerOptions] which exposes the options in a form useful
/// to the front end implementation.
///
/// The intent is that the front end should immediately wrap any incoming
/// [CompilerOptions] object in this class before doing further processing, and
/// should thereafter access all options via the wrapper.  This ensures that
/// options are interpreted in a consistent way and that data derived from
/// options is not unnecessarily recomputed.
class ProcessedOptions {
  /// The raw [CompilerOptions] which this class wraps.
  final CompilerOptions _raw;

  /// The package map derived from the options, or `null` if the package map has
  /// not been computed yet.
  Map<String, Uri> _packages;

  /// A URI resolver based on the options, or `null` if the URI resolver has not
  /// been computed yet.
  UriResolver _uriResolver;

  /// Initializes a [ProcessedOptions] object wrapping the given [rawOptions].
  ProcessedOptions(CompilerOptions rawOptions) : this._raw = rawOptions;

  /// Determine whether to generate code for the SDK when compiling a
  /// whole-program.
  bool get compileSdk => _raw.compileSdk;

  /// Get the [FileSystem] which should be used by the front end to access
  /// files.
  ///
  /// If the client supplied roots using [CompilerOptions.multiRoots], the
  /// returned [FileSystem] will automatically perform the appropriate mapping.
  FileSystem get fileSystem {
    // TODO(paulberry): support multiRoots.
    assert(_raw.multiRoots.isEmpty);
    return _raw.fileSystem;
  }

  /// Get the [UriResolver] which resolves "package:" and "dart:" URIs.
  ///
  /// This is an asynchronous getter since file system operations may be
  /// required to locate/read the packages file as well as SDK metadata.
  Future<UriResolver> getUriResolver() async {
    if (_uriResolver == null) {
      await _getPackages();
      var sdkLibraries =
          <String, Uri>{}; // TODO(paulberry): support SDK libraries
      _uriResolver = new UriResolver(_packages, sdkLibraries);
    }
    return _uriResolver;
  }

  /// Get the package map which maps package names to URIs.
  ///
  /// This is an asynchronous getter since file system operations may be
  /// required to locate/read the packages file.
  Future<Map<String, Uri>> _getPackages() async {
    if (_packages == null) {
      if (_raw.packagesFileUri == null) {
        throw new UnimplementedError(); // TODO(paulberry): search for .packages
      } else if (_raw.packagesFileUri.path.isEmpty) {
        _packages = {};
      } else {
        var contents =
            await fileSystem.entityForUri(_raw.packagesFileUri).readAsBytes();
        _packages = package_config.parse(contents, _raw.packagesFileUri);
      }
    }
    return _packages;
  }
}
