// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_integration/file_system/multi_root.dart'
    as front_end
    show MultiRootFileSystem;
import 'package:shadow_sources/src/shadow_options.dart';
import 'package:front_end/src/api_unstable/vm.dart'
    as front_end
    show FileSystem;
import 'package:test/test.dart';

import 'util/fss.dart';

void main() {
  const root = '/google/src/cloud/user/workspace/google3';

  group('validatePrefix', () {
    test('accepts valid prefix characters [a-z0-9_.]', () {
      expect(() => validatePrefix('shadowed'), returnsNormally);
      expect(() => validatePrefix('custom_prefix_123'), returnsNormally);
      expect(() => validatePrefix('pkg.shadow'), returnsNormally);
      expect(() => validatePrefix('a'), returnsNormally);
      expect(() => validatePrefix('123'), returnsNormally);
    });

    test('throws ArgumentError for invalid prefixes', () {
      expect(() => validatePrefix(''), throwsA(isA<ArgumentError>()));
      expect(() => validatePrefix('Shadowed'), throwsA(isA<ArgumentError>()));
      expect(() => validatePrefix('shadow-pkg'), throwsA(isA<ArgumentError>()));
      expect(() => validatePrefix('shadow pkg'), throwsA(isA<ArgumentError>()));
      expect(() => validatePrefix('shadow@pkg'), throwsA(isA<ArgumentError>()));
      expect(() => validatePrefix('shadow/pkg'), throwsA(isA<ArgumentError>()));
    });
  });

  group('ShadowOptions.fromArgs', () {
    test('parses options and ensures trailing slash on outputDir', () {
      final options = ShadowOptions.fromArgs([
        '--script=google3:///app/main.dart',
        '--packages=google3:///app/main.packages',
        '--dynamic-interface=google3:///app/dynamic_interface.yaml',
        '--prefix=shadowed',
        '--output-dir=/tmp/output_dir_no_slash',
      ]);

      expect(options.scriptUri, equals(Uri.parse('google3:///app/main.dart')));
      expect(
        options.packagesUri,
        equals(Uri.parse('google3:///app/main.packages')),
      );
      expect(
        options.dynamicInterfaceUri,
        equals(Uri.parse('google3:///app/dynamic_interface.yaml')),
      );
      expect(options.prefix, equals('shadowed'));
      expect(options.outputDir.path.endsWith('/'), isTrue);
      expect(
        options.outputDir.toString(),
        equals('file:///tmp/output_dir_no_slash/'),
      );
    });

    test('configures multi-root filesystem when scheme and roots provided', () {
      final options = ShadowOptions.fromArgs([
        '--script=google3:///app/main.dart',
        '--packages=google3:///app/main.packages',
        '--dynamic-interface=google3:///app/dynamic_interface.yaml',
        '--prefix=shadowed',
        '--output-dir=/tmp/output_dir/',
        '--filesystem-scheme=google3',
        '--filesystem-root=/google/src/cloud/user/workspace/google3',
        '--filesystem-root=/google/src/cloud/user/workspace/google3/blaze-bin',
      ]);

      expect(options.frontendFs, isA<front_end.MultiRootFileSystem>());
      final mrfs = options.frontendFs as front_end.MultiRootFileSystem;
      expect(mrfs.markerScheme, equals('google3'));
    });
  });

  group('ShadowOptions.create', () {
    late front_end.FileSystem frontendFs;

    setUp(() {
      final (fs, _) = fssForTests(root, {});
      frontendFs = fs;
    });

    test('enables relative flags when schemes match and are absolute', () {
      final options = ShadowOptions.create(
        scriptUri: 'google3:///app/main.dart',
        packagesUri: 'google3:///app/main.packages',
        dynamicInterfaceUri: 'google3:///app/dynamic_interface.yaml',
        frontendFs: frontendFs,
        prefix: 'shadowed',
        outputDir: 'file:///tmp/output/dir/',
      );

      expect(options.enableRelativeDynamicInterfaceLibraries, isTrue);
      expect(options.enableRelativeEntrypointScriptDirectives, isTrue);
    });

    test('disables enableRelativeDynamicInterfaceLibraries when dynamicInterfacePath scheme differs', () {
      final options = ShadowOptions.create(
        scriptUri: 'google3:///app/main.dart',
        packagesUri: 'google3:///app/main.packages',
        dynamicInterfaceUri: 'file:///tmp/app/dynamic_interface.yaml',
        frontendFs: frontendFs,
        prefix: 'shadowed',
        outputDir: 'file:///tmp/output/dir/',
      );

      expect(options.enableRelativeDynamicInterfaceLibraries, isFalse);
      expect(options.enableRelativeEntrypointScriptDirectives, isTrue);
    });

    test('disables enableRelativeEntrypointScriptDirectives when packagesPath scheme differs', () {
      final options = ShadowOptions.create(
        scriptUri: 'google3:///app/main.dart',
        packagesUri: 'file:///tmp/app/main.packages',
        dynamicInterfaceUri: 'google3:///app/dynamic_interface.yaml',
        frontendFs: frontendFs,
        prefix: 'shadowed',
        outputDir: 'file:///tmp/output/dir/',
      );

      expect(options.enableRelativeDynamicInterfaceLibraries, isTrue);
      expect(options.enableRelativeEntrypointScriptDirectives, isFalse);
    });

    test('throws ArgumentError when outputDir is inside multi-root filesystem scheme', () {
      expect(
        () => ShadowOptions.create(
          scriptUri: 'google3:///app/main.dart',
          packagesUri: 'google3:///app/main.packages',
          dynamicInterfaceUri: 'google3:///app/dynamic_interface.yaml',
          frontendFs: frontendFs,
          prefix: 'shadowed',
          outputDir: 'google3:///tmp/output/dir/',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Cannot write to multi-root filesystem.'),
          ),
        ),
      );
    });

    test('ensures trailing slash on outputDir', () {
      final options = ShadowOptions.create(
        scriptUri: 'google3:///app/main.dart',
        packagesUri: 'google3:///app/main.packages',
        dynamicInterfaceUri: 'google3:///app/dynamic_interface.yaml',
        frontendFs: frontendFs,
        prefix: 'shadowed',
        outputDir: 'file:///tmp/output_dir_no_slash',
      );

      expect(options.outputDir.path.endsWith('/'), isTrue);
      expect(
        options.outputDir.toString(),
        equals('file:///tmp/output_dir_no_slash/'),
      );
    });
  });
}
