// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:convert';
import 'dart:io';

import 'package:dev_compiler/src/kernel/module_metadata.dart';
import 'package:test/test.dart';

// Test creating, reading and writing debugger metadata
void main() {
  group('Module metadata', () {
    Directory tempDir;
    File file;

    setUpAll(() {
      var systemTempDir = Directory.systemTemp;
      tempDir = systemTempDir.createTempSync('foo bar');
      var input = tempDir.uri.resolve('module.metadata');
      file = File.fromUri(input)..createSync();
    });

    tearDownAll(() {
      tempDir.delete(recursive: true);
    });

    test('create, write, and read', () async {
      // create metadata
      var version = ModuleMetadataVersion.current.version;
      var module = createMetadata(version);
      testMetadataFields(module, version);

      // write metadata
      file.writeAsBytesSync(utf8.encode(json.encode(module)));
      expect(file.existsSync(), true);

      // read metadata
      var moduleJson = json.decode(utf8.decode(file.readAsBytesSync()));
      var newModule =
          ModuleMetadata.fromJson(moduleJson as Map<String, dynamic>);
      testMetadataFields(newModule, version);
    });

    test('read later backward-compatible patch version', () async {
      // create metadata with next patch version
      var version = ModuleMetadataVersion(
              ModuleMetadataVersion.current.majorVersion,
              ModuleMetadataVersion.current.minorVersion,
              ModuleMetadataVersion.current.patchVersion + 1)
          .version;

      var module = createMetadata(version);

      // write metadata
      file.writeAsBytesSync(utf8.encode(json.encode(module)));
      expect(file.existsSync(), true);

      // read metadata
      var moduleJson = json.decode(utf8.decode(file.readAsBytesSync()));
      var newModule =
          ModuleMetadata.fromJson(moduleJson as Map<String, dynamic>);
      testMetadataFields(newModule, version);
    });

    test('read later backward-compatible minor version', () async {
      // create metadata with next minor version
      var version = ModuleMetadataVersion(
              ModuleMetadataVersion.current.majorVersion,
              ModuleMetadataVersion.current.minorVersion + 1,
              ModuleMetadataVersion.current.patchVersion + 1)
          .version;
      var module = createMetadata(version);

      // write metadata
      file.writeAsBytesSync(utf8.encode(json.encode(module)));
      expect(file.existsSync(), true);

      // read metadata
      var moduleJson = json.decode(utf8.decode(file.readAsBytesSync()));
      var newModule =
          ModuleMetadata.fromJson(moduleJson as Map<String, dynamic>);
      testMetadataFields(newModule, version);
    });

    test('fail to read later non-backward-compatible major version', () async {
      // create metadata with next minor version
      var version = ModuleMetadataVersion(
              ModuleMetadataVersion.current.majorVersion + 1,
              ModuleMetadataVersion.current.minorVersion + 1,
              ModuleMetadataVersion.current.patchVersion + 1)
          .version;
      var module = createMetadata(version);

      // write metadata
      file.writeAsBytesSync(utf8.encode(json.encode(module)));
      expect(file.existsSync(), true);

      // try read metadata, expect to fail
      var moduleJson = json.decode(utf8.decode(file.readAsBytesSync()));
      ModuleMetadata newModule;
      try {
        newModule = ModuleMetadata.fromJson(moduleJson as Map<String, dynamic>);
      } catch (e) {
        expect(
            e.toString(), 'Exception: Unsupported metadata version $version');
      }

      expect(newModule, null);
    });
  });
}

ModuleMetadata createMetadata(String version) => ModuleMetadata(
    'module', 'closure', 'module.map', 'module.js', version: version)
  ..addLibrary(LibraryMetadata('library', 'package:library/test.dart',
      'file:///source/library/lib/test.dart', ['src/test2.dart']));

void testMetadataFields(ModuleMetadata module, String version) {
  // reader always creates current metadata version
  expect(module.version, version);
  expect(module.name, 'module');
  expect(module.closureName, 'closure');
  expect(module.sourceMapUri, 'module.map');
  expect(module.moduleUri, 'module.js');

  var libUri = module.libraries.keys.first;
  var lib = module.libraries[libUri];

  expect(libUri, 'package:library/test.dart');
  expect(lib.name, 'library');
  expect(lib.importUri, 'package:library/test.dart');
  expect(lib.fileUri, 'file:///source/library/lib/test.dart');
  expect(lib.partUris[0], 'src/test2.dart');
}
