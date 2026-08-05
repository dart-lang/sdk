// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';

import 'package:dwds/src/debugging/metadata/module_metadata.dart';
import 'package:dwds/src/debugging/metadata/provider.dart';
import 'package:test/test.dart';

import 'fixtures/fakes.dart';
import 'fixtures/utilities.dart';

const _emptySourceMetadata =
    '{"version":"1.0.0","name":"web/main","closureName":"load__web__main",'
    '"sourceMapUri":"foo/web/main.ddc.js.map",'
    '"moduleUri":"foo/web/main.ddc.js",'
    '"libraries":[{"name":"main",'
    '"importUri":"org-dartlang-app:///web/main.dart",'
    '"fileUri":"org-dartlang-app:///web/main.dart","partUris":[]}]}\n'
    '// intentionally empty: package blah has no dart sources';

const _fileUriMetadata =
    '{"version":"1.0.0","name":"web/main","closureName":"load__web__main",'
    '"sourceMapUri":"foo/web/main.ddc.js.map",'
    '"moduleUri":"foo/web/main.ddc.js",'
    '"libraries":[{"name":"main",'
    '"importUri":"file:/Users/foo/blah/sample/lib/bar.dart",'
    '"fileUri":"org-dartlang-app:///web/main.dart","partUris":[]}]}\n'
    '// intentionally empty: package blah has no dart sources';

void main() {
  final toolConfiguration = TestToolConfiguration.withLoadStrategy(
    loadStrategy: FakeStrategy(FakeAssetReader()),
  );
  setGlobalsForTesting(toolConfiguration: toolConfiguration);
  test('can parse metadata with empty sources', () async {
    final provider = MetadataProvider(
      'foo.bootstrap.js',
      FakeAssetReader(metadata: _emptySourceMetadata),
    );
    expect(
      await provider.libraries,
      contains('org-dartlang-app:///web/main.dart'),
    );
  });

  test('throws on metadata with absolute import uris', () async {
    final provider = MetadataProvider(
      'foo.bootstrap.js',
      FakeAssetReader(metadata: _fileUriMetadata),
    );
    await expectLater(
      provider.libraries,
      throwsA(const TypeMatcher<AbsoluteImportUriException>()),
    );
  });

  test(
    'module name exists if useModuleName and otherwise use module uri',
    () async {
      final provider = MetadataProvider(
        'foo.bootstrap.js',
        FakeAssetReader(metadata: _emptySourceMetadata),
      );
      final modulePath = 'foo/web/main.ddc.js';
      final moduleName = 'web/main';
      final module = moduleName;
      expect(
        await provider.scriptToModule,
        predicate<Map<String, String>>(
          (scriptToModule) =>
              !scriptToModule.values.any((value) => value == modulePath),
        ),
      );
      expect(await provider.moduleToSourceMap, {
        module: 'foo/web/main.ddc.js.map',
      });
      expect(await provider.modulePathToModule, {modulePath: module});
      expect(await provider.moduleToModulePath, {module: modulePath});
      expect(await provider.modules, {module});
    },
  );

  test('creates metadata from json', () async {
    const json = {
      'version': '1.0.0',
      'name': 'web/main',
      'closureName': 'load__web__main',
      'sourceMapUri': 'foo/web/main.ddc.js.map',
      'moduleUri': 'foo/web/main.ddc.js',
      'libraries': [
        {
          'name': 'main',
          'importUri': 'org-dartlang-app:///web/main.dart',
          'partUris': ['org-dartlang-app:///web/main.dart'],
        },
      ],
    };

    final metadata = ModuleMetadata.fromJson(json);
    expect(metadata.version, '1.0.0');
    expect(metadata.name, 'web/main');
    expect(metadata.closureName, 'load__web__main');
    expect(metadata.sourceMapUri, 'foo/web/main.ddc.js.map');
    expect(metadata.moduleUri, 'foo/web/main.ddc.js');
    final libraries = metadata.libraries;
    expect(libraries.length, 1);
    for (final lib in libraries.values) {
      expect(lib.name, 'main');
      expect(lib.importUri, 'org-dartlang-app:///web/main.dart');
      final parts = lib.partUris;
      expect(parts.length, 1);
      expect(parts[0], 'org-dartlang-app:///web/main.dart');
    }
  });

  String createMetadataContents(
    Map<String, List<String>> moduleToLibraries,
    Map<String, List<String>> libraryToParts,
  ) {
    final contents = StringBuffer();
    for (final MapEntry(key: module, value: libraries)
        in moduleToLibraries.entries) {
      final moduleMetadata = ModuleMetadata(
        module,
        'load__web__$module',
        'foo/web/$module.ddc.js.map',
        'foo/web/$module.ddc.js',
      );
      for (final library in libraries) {
        moduleMetadata.addLibrary(
          LibraryMetadata(library, library, libraryToParts[library] ?? []),
        );
      }
      contents.writeln(json.encode(moduleMetadata.toJson()));
    }
    contents.write('// intentionally empty: ...');
    return contents.toString();
  }

  Future<void> validateProvider(
    MetadataProvider provider,
    Map<String, List<String>> moduleToLibraries,
    Map<String, List<String>> libraryToParts,
  ) async {
    final expectedScriptToModule = <String, String>{};
    final expectedModuleToSourceMap = <String, String>{};
    final expectedModulePathToModule = <String, String>{};
    final expectedModules = <String>{};
    for (final MapEntry(key: module, value: libraries)
        in moduleToLibraries.entries) {
      for (final library in libraries) {
        expectedScriptToModule[library] = module;
        final parts = libraryToParts[library];
        if (parts != null) {
          for (final part in parts) {
            expectedScriptToModule[part] = module;
          }
        }
      }
      expectedModuleToSourceMap[module] = 'foo/web/$module.ddc.js.map';
      expectedModulePathToModule['foo/web/$module.ddc.js'] = module;
      expectedModules.add(module);
    }

    final scriptToModule = await provider.scriptToModule;
    for (final MapEntry(key: script, value: module)
        in expectedScriptToModule.entries) {
      expect(scriptToModule[script], module);
    }

    final moduleToSourceMap = await provider.moduleToSourceMap;
    for (final MapEntry(key: module, value: sourceMap)
        in expectedModuleToSourceMap.entries) {
      expect(moduleToSourceMap[module], sourceMap);
    }

    final modulePathToModule = await provider.modulePathToModule;
    for (final MapEntry(key: modulePath, value: module)
        in expectedModulePathToModule.entries) {
      expect(modulePathToModule[modulePath], module);
    }

    expect(await provider.modules, containsAll(expectedModules));
  }

  test('reinitialize produces correct ModifiedModuleReport', () async {
    const moduleToLibraries = <String, List<String>>{
      'm1': [
        'org-dartlang-app:///web/l1.dart',
        'org-dartlang-app:///web/l2.dart',
      ],
      'm2': [
        'org-dartlang-app:///web/l3.dart',
        'org-dartlang-app:///web/l4.dart',
      ],
      'm3': [
        'org-dartlang-app:///web/l5.dart',
        'org-dartlang-app:///web/l6.dart',
      ],
    };
    const libraryToParts = <String, List<String>>{
      'org-dartlang-app:///web/l1.dart': ['org-dartlang-app:///web/l1_p1.dart'],
      'org-dartlang-app:///web/l3.dart': ['org-dartlang-app:///web/l3_p1.dart'],
    };
    final assetReader = FakeAssetReader(
      metadata: createMetadataContents(moduleToLibraries, libraryToParts),
    );
    final provider = MetadataProvider('foo.bootstrap.js', assetReader);
    await validateProvider(provider, moduleToLibraries, libraryToParts);

    const newModuleToLibraries = <String, List<String>>{
      'm1': [
        'org-dartlang-app:///web/l1.dart',
        'org-dartlang-app:///web/l2.dart',
      ],
      'm3': ['org-dartlang-app:///web/l3.dart'],
      'm4': [
        'org-dartlang-app:///web/l4.dart',
        'org-dartlang-app:///web/l7.dart',
      ],
    };
    const newLibraryToParts = <String, List<String>>{
      'org-dartlang-app:///web/l2.dart': ['org-dartlang-app:///web/l1_p1.dart'],
      'org-dartlang-app:///web/l3.dart': ['org-dartlang-app:///web/l3_p2.dart'],
      'org-dartlang-app:///web/l7.dart': ['org-dartlang-app:///web/l7_p1.dart'],
    };
    const reloadedModulesToLibraries = <String, List<String>>{
      'm3': ['org-dartlang-app:///web/l3.dart'],
      'm4': [
        'org-dartlang-app:///web/l4.dart',
        'org-dartlang-app:///web/l7.dart',
      ],
    };
    assetReader.metadata = createMetadataContents(
      newModuleToLibraries,
      newLibraryToParts,
    );
    final modifiedModuleReport = await provider.reinitializeAfterHotReload(
      reloadedModulesToLibraries,
    );
    expect(modifiedModuleReport.deletedModules, ['m2']);
    expect(
      modifiedModuleReport.deletedLibraries,
      unorderedEquals([
        'org-dartlang-app:///web/l5.dart',
        'org-dartlang-app:///web/l6.dart',
      ]),
    );
    expect(modifiedModuleReport.reloadedModules, ['m3', 'm4']);
    expect(
      modifiedModuleReport.reloadedLibraries,
      unorderedEquals([
        'org-dartlang-app:///web/l3.dart',
        'org-dartlang-app:///web/l4.dart',
        'org-dartlang-app:///web/l7.dart',
      ]),
    );
    expect(modifiedModuleReport.modifiedModules, ['m2', 'm3', 'm4']);
    expect(
      modifiedModuleReport.modifiedLibraries,
      unorderedEquals([
        'org-dartlang-app:///web/l3.dart',
        'org-dartlang-app:///web/l4.dart',
        'org-dartlang-app:///web/l5.dart',
        'org-dartlang-app:///web/l6.dart',
        'org-dartlang-app:///web/l7.dart',
      ]),
    );
    await validateProvider(provider, newModuleToLibraries, newLibraryToParts);
  });
}
