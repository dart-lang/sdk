// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.package.map.provider;

import 'dart:convert';

import 'package:analysis_server/src/package_map_provider.dart';
import 'package:unittest/unittest.dart';
import 'package:analysis_server/src/resource.dart';

main() {
  groupSep = ' | ';

  group('PubPackageMapProvider', () {
    group('parsePackageMap', () {
      MemoryResourceProvider resourceProvider;
      PubPackageMapProvider packageMapProvider;

      setUp(() {
        resourceProvider = new MemoryResourceProvider();
        packageMapProvider = new PubPackageMapProvider(resourceProvider);
      });

      test('normal folder', () {
        String packageName = 'foo';
        String folderPath = '/path/to/folder';
        resourceProvider.newFolder(folderPath);
        Map<String, Folder> result = packageMapProvider.parsePackageMap(
            JSON.encode({'packages': {packageName: folderPath}}));
        expect(result, hasLength(1));
        expect(result.keys, contains(packageName));
        expect(result[packageName], new isInstanceOf<Folder>());
        expect(result[packageName].path, equals(folderPath));
      });

      test('ignore nonexistent folder', () {
        String packageName = 'foo';
        String folderPath = '/path/to/folder';
        Map<String, Folder> result = packageMapProvider.parsePackageMap(
            JSON.encode({'packages': {packageName: folderPath}}));
        expect(result, hasLength(0));
      });
    });
  });
}
