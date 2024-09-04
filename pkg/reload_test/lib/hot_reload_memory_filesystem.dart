// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dev_compiler/dev_compiler.dart' as ddc_names
    show libraryUriToJsIdentifier;

import 'package:reload_test/ddc_helpers.dart' show FileDataPerGeneration;

/// A pseudo in-memory filesystem with helpers to aid the hot reload runner.
///
/// The Frontend Server outputs web sources and sourcemaps as concatenated
/// single files per-invocation. A manifest file contains the byte offsets
/// for resolving the individual files.
/// Adapted from:
/// https://github.com/flutter/flutter/blob/ac7879e2aa6de40afec1fe2af9730a8d55de3e06/packages/flutter_tools/lib/src/web/memory_fs.dart
class HotReloadMemoryFilesystem {
  /// The root directory's URI from which JS file are being served.
  final Uri jsRootUri;

  final Map<String, Uint8List> files = {};
  final Map<String, Uint8List> sourcemaps = {};

  /// Maps generation numbers to a list of changed libraries.
  final Map<String, List<LibraryInfo>> generationChanges = {};
  final List<LibraryInfo> libraries = [];
  final List<LibraryInfo> firstGenerationLibraries = [];

  HotReloadMemoryFilesystem(this.jsRootUri);

  /// Writes the entirety of this filesystem to [outputDirectoryUri].
  ///
  /// [clearWritableState] clears generation-specific state so that old
  /// generations' files aren't rewritten.
  void writeToDisk(Uri outputDirectoryUri,
      {required String generation, bool clearWritableState = true}) {
    assert(Directory.fromUri(outputDirectoryUri).existsSync(),
        '$outputDirectoryUri does not exist.');
    files.forEach((path, content) {
      final outputFileUri =
          outputDirectoryUri.resolve('generation$generation/').resolve(path);
      final outputFile = File.fromUri(outputFileUri);
      outputFile.createSync(recursive: true);
      outputFile.writeAsBytesSync(content);
    });

    if (clearWritableState) {
      files.clear();
      sourcemaps.clear();
    }
  }

  /// Returns a map of generation number to modified files' paths.
  ///
  /// Used to determine which JS files should be loaded per generation.
  FileDataPerGeneration get generationsToModifiedFilePaths => {
        for (var e in generationChanges.entries)
          e.key: e.value
              .map((info) => [info.dartSourcePath, info.jsSourcePath])
              .toList()
      };

  /// Returns all scripts in the filesystem in a form that can be ingested by
  /// the DDC module system's bootstrapper.
  /// Files must only be in the first generation.
  List<Map<String, String?>> get scriptDescriptorForBootstrap {
    // TODO(markzipan): This currently isn't ordered, which may cause problems
    // with cycles.
    final scriptsJson = <Map<String, String?>>[];
    for (var library in firstGenerationLibraries) {
      final scriptDescriptor = <String, String?>{
        'id': library.dartSourcePath,
        'src': library.jsSourcePath,
      };
      scriptsJson.add(scriptDescriptor);
    }
    return scriptsJson;
  }

  /// Update the filesystem with the provided source and manifest files.
  ///
  /// Returns the list of updated files. Also associates file info with a
  /// generation label.
  List<String> update(
    File codeFile,
    File manifestFile,
    File sourcemapFile, {
    required String generation,
  }) {
    final updatedFiles = <String>[];
    final codeBytes = codeFile.readAsBytesSync();
    final sourcemapBytes = sourcemapFile.readAsBytesSync();
    final manifest = Map.castFrom<dynamic, dynamic, String, Object?>(
        json.decode(manifestFile.readAsStringSync()) as Map);

    generationChanges[generation] = [];
    for (final filePath in manifest.keys) {
      final fileUri = Uri.file(filePath);
      final Map<String, dynamic> offsets =
          Map.castFrom<dynamic, dynamic, String, Object?>(
              manifest[filePath] as Map);
      final codeOffsets = (offsets['code'] as List<dynamic>).cast<int>();
      final sourcemapOffsets =
          (offsets['sourcemap'] as List<dynamic>).cast<int>();

      if (codeOffsets.length != 2 || sourcemapOffsets.length != 2) {
        continue;
      }

      final codeStart = codeOffsets[0];
      final codeEnd = codeOffsets[1];
      if (codeStart < 0 || codeEnd > codeBytes.lengthInBytes) {
        continue;
      }
      final byteView = Uint8List.view(
        codeBytes.buffer,
        codeStart,
        codeEnd - codeStart,
      );
      final fileName =
          filePath.startsWith('/') ? filePath.substring(1) : filePath;
      files[fileName] = byteView;
      final libraryName = ddc_names.libraryUriToJsIdentifier(fileUri);
      // TODO(markzipan): This is an overly simple heuristic to resolve the
      // original Dart file. Replace this if it no longer holds.
      var dartFileName = fileName;
      if (dartFileName.endsWith('.lib.js')) {
        dartFileName =
            fileName.substring(0, fileName.length - '.lib.js'.length);
      }
      final fullyResolvedFileUri =
          jsRootUri.resolve('generation$generation/$fileName');
      // TODO(markzipan): Update this if module and library names are no
      // longer the same.
      final libraryInfo = LibraryInfo(
          moduleName: libraryName,
          libraryName: libraryName,
          dartSourcePath: dartFileName,
          jsSourcePath: fullyResolvedFileUri.toFilePath());
      libraries.add(libraryInfo);
      if (generation == '0') {
        firstGenerationLibraries.add(libraryInfo);
      }
      generationChanges[generation]!.add(libraryInfo);
      updatedFiles.add(fileName);

      final sourcemapStart = sourcemapOffsets[0];
      final sourcemapEnd = sourcemapOffsets[1];
      if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
        continue;
      }
      final sourcemapView = Uint8List.view(
        sourcemapBytes.buffer,
        sourcemapStart,
        sourcemapEnd - sourcemapStart,
      );
      final sourcemapName = '$fileName.map';
      sourcemaps[sourcemapName] = sourcemapView;
    }
    return updatedFiles;
  }
}

/// Bundles information associated with a DDC library.
class LibraryInfo {
  final String moduleName;
  final String libraryName;
  final String dartSourcePath;
  final String jsSourcePath;

  LibraryInfo(
      {required this.moduleName,
      required this.libraryName,
      required this.dartSourcePath,
      required this.jsSourcePath});

  @override
  String toString() =>
      'LibraryInfo($moduleName, $libraryName, $dartSourcePath, $jsSourcePath)';
}
