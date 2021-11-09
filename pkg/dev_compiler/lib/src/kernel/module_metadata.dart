// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Module metadata format version.
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

  /// The current metadata version.
  ///
  /// Version follows simple semantic versioning format 'major.minor.patch'.
  /// See: https://semver.org
  ///
  /// TODO(annagrin): create metadata package, make version the same as the
  /// metadata package version, automate updating with the package update
  static const ModuleMetadataVersion current = ModuleMetadataVersion(1, 0, 2);

  /// Current metadata version created by the reader
  String get version => '$majorVersion.$minorVersion.$patchVersion';

  /// True if this metadata version is compatible with [version].
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

/// Metadata used by the debugger to describe a library.
///
/// Supports reading from and writing to json.
/// See: https://goto.google.com/dart-web-debugger-metadata
class LibraryMetadata {
  /// Library name as defined in pubspec.yaml
  final String name;

  /// URI used to import the library.
  ///
  /// Example: package:path/path.dart
  final String importUri;

  /// File URI for the library.
  ///
  /// Example: file:///path/to/path/path.dart
  final String fileUri;

  /// All file URIs (include part files) from the library.
  ///
  /// Can be relative paths to the directory of the fileUri.
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

/// Metadata used by the debugger to describe a module.
///
/// Supports reading from and writing to json.
/// See: https://goto.google.com/dart-web-debugger-metadata
class ModuleMetadata {
  /// The version of this metadata.
  final String version;

  /// Name of the js module created by the compiler.
  ///
  /// Used as a key to store and load modules in the debugger and the browser.
  final String name;

  /// Name of the function enclosing the module.
  ///
  /// Used by debugger to determine the top dart scope.
  final String closureName;

  /// URI of the source map for this module.
  final String sourceMapUri;

  /// URI of the module.
  final String moduleUri;

  /// The URI where DDC wrote a full .dill file for this module.
  ///
  /// Will be `null` when the module was compiled without the option to output
  /// the .dill fle.
  final String? fullDillUri;

  final Map<String, LibraryMetadata> libraries = {};

  /// True if the module corresponding to this metadata was compiled with sound
  /// null safety enabled.
  final bool soundNullSafety;

  ModuleMetadata(this.name, this.closureName, this.sourceMapUri, this.moduleUri,
      this.fullDillUri, this.soundNullSafety,
      {String? version})
      : version = version ??= ModuleMetadataVersion.current.version;

  /// Add [library] to this metadata.
  ///
  /// Used for filling the metadata in the compiler or for reading from stored
  /// metadata files.
  void addLibrary(LibraryMetadata library) {
    if (!libraries.containsKey(library.importUri)) {
      libraries[library.importUri] = library;
    } else {
      throw 'Metadata creation error: '
          'Cannot add library $library with uri ${library.importUri}: '
          'another library "${libraries[library.importUri]}" is found '
          'with the same uri';
    }
  }

  ModuleMetadata.fromJson(Map<String, dynamic> json)
      : version = json['version'] as String,
        name = json['name'] as String,
        closureName = json['closureName'] as String,
        sourceMapUri = json['sourceMapUri'] as String,
        moduleUri = json['moduleUri'] as String,
        fullDillUri = json['fullDillUri'] as String,
        soundNullSafety = json['soundNullSafety'] as bool {
    if (!ModuleMetadataVersion.current.isCompatibleWith(version)) {
      throw Exception('Unsupported metadata version $version');
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
      'fullDillUri': fullDillUri,
      'libraries': [for (var lib in libraries.values) lib.toJson()],
      'soundNullSafety': soundNullSafety
    };
  }
}
