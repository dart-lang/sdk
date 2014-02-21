// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.test.resolver_test;

import 'dart:io' show File, Platform;

import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:code_transformers/tests.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useCompactVMConfiguration();

  var sdkDir = dartSdkDirectory;
  if (sdkDir == null) {
    // If we cannot find the SDK dir, then assume this is being run from Dart's
    // source directory and this script is the main script.
    sdkDir = path.join(
        path.dirname(path.fromUri(Platform.script)), '..', '..', '..', 'sdk');
  }

  var entryPoint = new AssetId('a', 'web/main.dart');
  var transformer = new ResolverTransformer(sdkDir,
      (asset) => asset.id == entryPoint);

  var phases = [[transformer]];

  group('Resolver', () {

    test('should handle empty files', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '',
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);
            var source = resolver.sources[entryPoint];
            expect(source.modificationStamp, 1);

            var lib = resolver.entryLibrary;
            expect(lib, isNotNull);
            expect(lib.entryPoint, isNull);
          });
    });

    test('should update when sources change', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': ''' main() {} ''',
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);
            var source = resolver.sources[entryPoint];
            expect(source.modificationStamp, 2);

            var lib = resolver.entryLibrary;
            expect(lib, isNotNull);
            expect(lib.entryPoint, isNotNull);
          });
    });

    test('should follow imports', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              import 'a.dart';

              main() {
              } ''',
            'a|web/a.dart': '''
              library a;
              ''',
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);
            var lib = resolver.entryLibrary;
            expect(lib.importedLibraries.length, 2);
            var libA = lib.importedLibraries.where((l) => l.name == 'a').single;
            expect(libA.getType('Foo'), isNull);
          });
    });

    test('should update changed imports', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              import 'a.dart';

              main() {
              } ''',
            'a|web/a.dart': '''
              library a;
              class Foo {}
              ''',
          }).then((_) {
            var lib = transformer.getResolver(entryPoint).entryLibrary;
            expect(lib.importedLibraries.length, 2);
            var libA = lib.importedLibraries.where((l) => l.name == 'a').single;
            expect(libA.getType('Foo'), isNotNull);
          });
    });

    test('should follow package imports', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
            'b|lib/b.dart': '''
              library b;
              ''',
          }).then((_) {
            var lib = transformer.getResolver(entryPoint).entryLibrary;
            expect(lib.importedLibraries.length, 2);
            var libB = lib.importedLibraries.where((l) => l.name == 'b').single;
            expect(libB.getType('Foo'), isNull);
          });
    });

    test('should update on changed package imports', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
            'b|lib/b.dart': '''
              library b;
              class Bar {}
              ''',
          }).then((_) {
            var lib = transformer.getResolver(entryPoint).entryLibrary;
            expect(lib.importedLibraries.length, 2);
            var libB = lib.importedLibraries.where((l) => l.name == 'b').single;
            expect(libB.getType('Bar'), isNotNull);
          });
    });

    test('should handle deleted files', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
          },
          messages: [
            'error: Unable to find asset for "package:b/b.dart"',
            'error: Unable to find asset for "package:b/b.dart"',
          ]).then((_) {
            var lib = transformer.getResolver(entryPoint).entryLibrary;
            expect(lib.importedLibraries.length, 1);
          });
    });

    test('should fail on absolute URIs', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              import '/b.dart';

              main() {
              } ''',
          },
          messages: [
            // First from the AST walker
            'error: absolute paths not allowed: "/b.dart" (main.dart 0 14)',
            // Then two from the resolver.
            'error: absolute paths not allowed: "/b.dart"',
            'error: absolute paths not allowed: "/b.dart"',
          ]).then((_) {
            var lib = transformer.getResolver(entryPoint).entryLibrary;
            expect(lib.importedLibraries.length, 1);
          });
    });

    test('should list all libraries', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              library a.main;
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              ''',
            'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
            'a|lib/b.dart': 'library a.b;\n import "c.dart";',
            'a|lib/c.dart': 'library a.c;'
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);
            var libs = resolver.libraries.where((l) => !l.isInSdk);
            expect(libs.map((l) => l.name), unorderedEquals([
              'a.main',
              'a.a',
              'a.b',
              'a.c',
            ]));
          });
    });

    test('should resolve types and library uris', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
              import 'dart:core';
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              import 'sub_dir/d.dart';
              class Foo {}
              ''',
            'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
            'a|lib/b.dart': 'library a.b;\n import "c.dart";',
            'a|lib/c.dart': '''
                library a.c;
                class Bar {}
                ''',
            'a|web/sub_dir/d.dart': '''
                library a.web.sub_dir.d;
                class Baz{}
                ''',
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);

            var a = resolver.getLibraryByName('a.a');
            expect(a, isNotNull);
            expect(resolver.getImportUri(a).toString(),
                'package:a/a.dart');
            expect(resolver.getLibraryByUri(Uri.parse('package:a/a.dart')), a);

            var main = resolver.getLibraryByName('');
            expect(main, isNotNull);
            expect(resolver.getImportUri(main), isNull);

            var fooType = resolver.getType('Foo');
            expect(fooType, isNotNull);
            expect(fooType.library, main);

            var barType = resolver.getType('a.c.Bar');
            expect(barType, isNotNull);
            expect(resolver.getImportUri(barType.library).toString(),
                'package:a/c.dart');
            expect(resolver.getSourceAssetId(barType),
                new AssetId('a', 'lib/c.dart'));

            var bazType = resolver.getType('a.web.sub_dir.d.Baz');
            expect(bazType, isNotNull);
            expect(resolver.getImportUri(bazType.library), isNull);
            expect(resolver
                .getImportUri(bazType.library, from: entryPoint).toString(),
                'sub_dir/d.dart');

            var hashMap = resolver.getType('dart.collection.HashMap');
            expect(resolver.getImportUri(hashMap.library).toString(),
                'dart:collection');
            expect(resolver.getLibraryByUri(Uri.parse('dart:collection')),
                hashMap.library);

          });
    });

    test('deleted files should be removed', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''import 'package:a/a.dart';''',
            'a|lib/a.dart': '''import 'package:a/b.dart';''',
            'a|lib/b.dart': '''class Engine{}''',
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);
            var engine = resolver.getType('Engine');
            var uri = resolver.getImportUri(engine.library);
            expect(uri.toString(), 'package:a/b.dart');
          }).then((_) {
            return applyTransformers(phases,
              inputs: {
                'a|web/main.dart': '''import 'package:a/a.dart';''',
                'a|lib/a.dart': '''lib a;\n class Engine{}'''
              });
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);
            var engine = resolver.getType('Engine');
            var uri = resolver.getImportUri(engine.library);
            expect(uri.toString(), 'package:a/a.dart');

            // Make sure that we haven't leaked any sources.
            expect(resolver.sources.length, 2);
          });
    });

    test('handles circular imports', () {
      return applyTransformers(phases,
          inputs: {
            'a|web/main.dart': '''
                library main;
                import 'package:a/a.dart'; ''',
            'a|lib/a.dart': '''
                library a;
                import 'package:a/b.dart'; ''',
            'a|lib/b.dart': '''
                library b;
                import 'package:a/a.dart'; ''',
          }).then((_) {
            var resolver = transformer.getResolver(entryPoint);

            var libs = resolver.libraries.map((lib) => lib.name);
            expect(libs.contains('a'), isTrue);
            expect(libs.contains('b'), isTrue);
          });
    });
  });
}
