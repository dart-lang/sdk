// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Module metadata format version
///
/// Module reader always creates the current version but is able to read
/// metadata files with later versions as long as the changes are backward
/// compatible, i.e. only minor or patch versions have changed.
///
/// See: https://goto.google.com/dart-web-debugger-metadata
class ModuleMetadataVersion {
  final int majorVersion;
  final int minorVersion;
  final int patchVersion;

  const ModuleMetadataVersion(
    this.majorVersion,
    this.minorVersion,
    this.patchVersion,
  );

  /// Current metadata version
  ///
  /// Version follows simple semantic versioning format 'major.minor.patch'
  /// See https://semver.org
  ///
  /// TODO(annagrin): create metadata package, make version the same as the
  /// metadata package version, automate updating with the package update
  static const ModuleMetadataVersion current = ModuleMetadataVersion(1, 0, 0);

  /// Current metadata version created by the reader
  String get version => '$majorVersion.$minorVersion.$patchVersion';

  /// Is this metadata version compatible with the given version
  ///
  /// The minor and patch version changes never remove any fields that current
  /// version supports, so the reader can create current metadata version from
  /// any file created with a later reader, as long as the major version does
  /// not change.
  bool isCompatibleWith(String version) {
    var parts = version.split('.');
    if (parts.length != 3) {
      throw FormatException('Version: $version'
          'does not follow simple semantic versioning format');
    }
    var major = int.parse(parts[0]);
    var minor = int.parse(parts[1]);
    var patch = int.parse(parts[2]);
    return major == majorVersion &&
        minor >= minorVersion &&
        patch >= patchVersion;
  }
}

/// Library metadata
///
/// Represents library metadata used in the debugger,
/// supports reading from and writing to json
/// See: https://goto.google.com/dart-web-debugger-metadata
class LibraryMetadata {
  /// Library name as defined in pubspec.yaml
  final String name;

  /// Library importUri
  ///
  /// Example package:path/path.dart
  final String importUri;

  /// Library fileUri
  ///
  /// Example file:///path/to/path/path.dart
  final String fileUri;

  /// All file uris from the library
  ///
  /// Can be relative paths to the directory of the fileUri
  final List<String> partUris;

  LibraryMetadata(this.name, this.importUri, this.fileUri, this.partUris);

  LibraryMetadata.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        importUri = json['importUri'] as String,
        fileUri = json['fileUri'] as String,
        partUris =
            List.castFrom<dynamic, String>(json['partUris'] as List<dynamic>);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'importUri': importUri,
      'fileUri': fileUri,
      'partUris': [...partUris]
    };
  }
}

/// Module metadata
///
/// Represents module metadata used in the debugger,
/// supports reading from and writing to json
/// See: https://goto.google.com/dart-web-debugger-metadata
class ModuleMetadata {
  /// Metadata format version
  String version;

  /// Module name
  ///
  /// Used as a name of the js module created by the compiler and
  /// as key to store and load modules in the debugger and the browser
  final String name;

  /// Name of the function enclosing the module
  ///
  /// Used by debugger to determine the top dart scope
  final String closureName;

  /// Source map uri
  final String sourceMapUri;

  /// Module uri
  final String moduleUri;

  final Map<String, LibraryMetadata> libraries = {};

  ModuleMetadata(this.name, this.closureName, this.sourceMapUri, this.moduleUri,
      {this.version}) {
    version ??= ModuleMetadataVersion.current.version;
  }

  /// Add [library] to metadata
  ///
  /// Used for filling the metadata in the compiler or for reading from
  /// stored metadata files.
  void addLibrary(LibraryMetadata library) {
    if (!libraries.containsKey(library.importUri)) {
      libraries[library.importUri] = library;
    } else {
      throw ('Metadata creation error: '
          'Cannot add library $library with uri ${library.importUri}: '
          'another library "${libraries[library.importUri]}" is found '
          'with the same uri');
    }
  }

  ModuleMetadata.fromJson(Map<String, dynamic> json)
      : version = json['version'] as String,
        name = json['name'] as String,
        closureName = json['closureName'] as String,
        sourceMapUri = json['sourceMapUri'] as String,
        moduleUri = json['moduleUri'] as String {
    var fileVersion = json['version'] as String;
    if (!ModuleMetadataVersion.current.isCompatibleWith(version)) {
      throw Exception('Unsupported metadata version $fileVersion');
    }

    for (var l in json['libraries'] as List<dynamic>) {
      addLibrary(LibraryMetadata.fromJson(l as Map<String, dynamic>));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'name': name,
      'closureName': closureName,
      'sourceMapUri': sourceMapUri,
      'moduleUri': moduleUri,
      'libraries': [for (var lib in libraries.values) lib.toJson()]
    };
  }
}
