// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

/// Helper for building `.dart_tool/package_config.json` files.
///
/// See accepted/future-releases/language-versioning/package-config-file-v2.md
/// in https://github.com/dart-lang/language/.
///
/// Use the [add] method to add package configurations. These configurations
/// will accumulate into one package config file with the [toContent] method.
class PackageConfigFileBuilder {
  final List<_PackageDescription> _packages = [];

  /// Adds a package configuration.
  ///
  /// The [rootFolder] is used to produce the package root URI.
  ///
  /// The [packageUriStr] is optional (defaults to `'lib/'`), a relative path
  /// resolved against the root URI. The result must be inside the root URI.
  ///
  /// The [languageVersion] specifies the package's Dart language version, in
  /// the form of 'X.Y', such as '3.9'.
  void add({
    required String name,
    required Folder rootFolder,
    String packageUriStr = 'lib/',
    String? languageVersion,
  }) {
    if (_packages.any((e) => e.name == name)) {
      throw StateError('Already added: $name');
    }
    _packages.add(
      _PackageDescription(
        name: name,
        rootFolder: rootFolder,
        packageUriStr: packageUriStr,
        languageVersion: languageVersion,
      ),
    );
  }

  /// Copies this [PackageConfigFileBuilder] into a new instance.
  PackageConfigFileBuilder copy() {
    var copy = PackageConfigFileBuilder();
    copy._packages.addAll(_packages);
    return copy;
  }

  /// Returns the contents of the built package config file.
  String toContent() {
    var buffer = StringBuffer();

    buffer.writeln('{');

    var prefix = ' ' * 2;
    buffer.writeln('$prefix"configVersion": 2,');
    buffer.writeln('$prefix"packages": [');

    for (var i = 0; i < _packages.length; i++) {
      var package = _packages[i];

      var prefix = ' ' * 4;
      buffer.writeln('$prefix{');

      prefix = ' ' * 6;
      buffer.writeln('$prefix"name": "${package.name}",');

      buffer.write('$prefix"rootUri": "${package.rootFolder.toUri()}"');

      buffer.writeln(',');
      buffer.write('$prefix"packageUri": "${package.packageUriStr}"');

      if (package.languageVersion != null) {
        buffer.writeln(',');
        buffer.write('$prefix"languageVersion": "${package.languageVersion}"');
      }

      buffer.writeln();

      prefix = ' ' * 4;
      buffer.write(prefix);
      buffer.writeln(i < _packages.length - 1 ? '},' : '}');
    }

    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }
}

class _PackageDescription {
  final String name;
  final Folder rootFolder;
  final String packageUriStr;
  final String? languageVersion;

  _PackageDescription({
    required this.name,
    required this.rootFolder,
    required this.packageUriStr,
    required this.languageVersion,
  });
}
