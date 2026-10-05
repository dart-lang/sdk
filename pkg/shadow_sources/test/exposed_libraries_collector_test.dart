// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shadow_sources/src/exposed_libraries_collector.dart';
import 'package:shadow_sources/src/uris.dart';
import 'package:front_end/src/kernel/dynamic_module_validator.dart'
    show DynamicInterfaceYamlFile;
import 'package:test/test.dart';

import 'util/fss.dart';
import 'util/package_config.dart';

void main() {
  const root = '/google/src/cloud/user/workspace/google3';
  final dynamicInterfaceRawUri = Uri.parse(
    'google3:///app/dynamic_interface.yaml',
  );
  final dynamicInterfaceFileSystemUri = FileSystemUri(dynamicInterfaceRawUri);
  final dynamicInterfaceLibraryUri = LibraryUri(dynamicInterfaceRawUri);

  group('Separation of whole vs partial interface libraries', () {
    test(
      'findInterfaceLibraries returns empty sets for empty dynamic interface',
      () {
        final (frontendFs, _) = fssForTests(root, {});
        final packageConfig = createPackageConfig();
        final dynamicInterface = DynamicInterfaceYamlFile('{}');

        final (partial, whole) = ExposedLibrariesCollector(
          frontendFs: frontendFs,
          dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
          packageConfig: packageConfig,
          enableRelativeDynamicInterfaceLibraries: false,
        ).findInterfaceLibraries(dynamicInterface: dynamicInterface);

        expect(partial, isEmpty);
        expect(whole, isEmpty);
      },
    );

    test('findInterfaceLibraries separates whole and partial libraries', () {
      final (frontendFs, _) = fssForTests(root, {
        'app/dynamic_interface.yaml': r'''
extendable:
  - library: 'package:pkg_a/whole_extendable.dart'
  - library: 'package:pkg_a/class_extendable.dart'
    class: 'BaseClass'
can-be-overridden:
  - library: 'package:pkg_a/member_override.dart'
    class: 'BaseClass'
    member: 'foo'
callable:
  - library: 'package:pkg_a/whole_callable.dart'
can-be-used-as-type:
  - library: 'package:pkg_a/ext_type.dart'
    extension_type: 'MyExtType'
dynamically-callable:
  - library: 'package:pkg_a/ext.dart'
    extension: 'MyExt'
  - library: 'package:pkg_b/whole_dyn_callable.dart'
''',
      });

      final packageConfig = createPackageConfig();
      final dynamicInterface = DynamicInterfaceYamlFile(r'''
extendable:
  - library: 'package:pkg_a/whole_extendable.dart'
  - library: 'package:pkg_a/class_extendable.dart'
    class: 'BaseClass'
can-be-overridden:
  - library: 'package:pkg_a/member_override.dart'
    class: 'BaseClass'
    member: 'foo'
callable:
  - library: 'package:pkg_a/whole_callable.dart'
can-be-used-as-type:
  - library: 'package:pkg_a/ext_type.dart'
    extension_type: 'MyExtType'
dynamically-callable:
  - library: 'package:pkg_a/ext.dart'
    extension: 'MyExt'
  - library: 'package:pkg_b/whole_dyn_callable.dart'
''');

      final (partial, whole) = ExposedLibrariesCollector(
        frontendFs: frontendFs,
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        packageConfig: packageConfig,
        enableRelativeDynamicInterfaceLibraries: false,
      ).findInterfaceLibraries(dynamicInterface: dynamicInterface);

      expect(
        whole,
        containsAll(
          [
            'package:pkg_a/whole_extendable.dart',
            'package:pkg_a/whole_callable.dart',
            'package:pkg_b/whole_dyn_callable.dart',
          ].map(Uri.parse),
        ),
      );

      expect(
        partial,
        containsAll(
          [
            'package:pkg_a/class_extendable.dart',
            'package:pkg_a/member_override.dart',
            'package:pkg_a/ext_type.dart',
            'package:pkg_a/ext.dart',
          ].map(Uri.parse),
        ),
      );

      // Whole libraries should not appear in partialLibraries.
      for (final w in whole) {
        expect(partial.contains(w), isFalse);
      }
    });

    test(
      'collectExposedLibraries includes both whole and partial libraries',
      () async {
        final (frontendFs, _) = fssForTests(root, {
          'app/dynamic_interface.yaml': r'''
extendable:
  - library: 'package:pkg_a/partial.dart'
    class: 'BaseClass'
callable:
  - library: 'package:pkg_a/whole.dart'
''',
          'pkg_a/lib/partial.dart': 'class BaseClass {}',
          'pkg_a/lib/whole.dart': 'void wholeFunc() {}',
        });

        final packageConfig = createPackageConfig();
        final exposed = await collectExposedLibraries(
          dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
          frontendFs: frontendFs,
          packageConfig: packageConfig,
        );

        final partialUri = LibraryUri.parse('package:pkg_a/partial.dart');
        final wholeUri = LibraryUri.parse('package:pkg_a/whole.dart');

        expect(exposed, containsAll([partialUri, wholeUri]));
      },
    );

    test('partial libraries do NOT have their exports expanded', () async {
      final (frontendFs, _) = fssForTests(root, {
        'app/dynamic_interface.yaml': r'''
extendable:
  - library: 'package:pkg_a/partial.dart'
    class: 'BaseClass'
''',
        'pkg_a/lib/partial.dart': r'''
export 'partial_sub.dart';
class BaseClass {}
''',
        'pkg_a/lib/partial_sub.dart': 'void sub() {}',
      });

      final packageConfig = createPackageConfig();

      final exposed = await collectExposedLibraries(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
      );

      final partialUri = Uri.parse('package:pkg_a/partial.dart');
      final subUri = Uri.parse('package:pkg_a/partial_sub.dart');

      expect(exposed.contains(partialUri), isTrue);
      expect(exposed.contains(subUri), isFalse);
    });
  });

  group('Transitive export expansion', () {
    test(
      'expands direct and multi-hop transitive exports for whole libraries',
      () async {
        final (frontendFs, _) = fssForTests(root, {
          'app/dynamic_interface.yaml': r'''
callable:
  - library: 'package:pkg_a/a.dart'
''',
          'pkg_a/lib/a.dart': r'''
export 'b.dart';
void a() {}
''',
          'pkg_a/lib/b.dart': r'''
export 'src/c.dart';
export 'package:pkg_b/d.dart';
void b() {}
''',
          'pkg_a/lib/src/c.dart': 'void c() {}',
          'pkg_b/lib/d.dart': 'void d() {}',
        });

        final packageConfig = createPackageConfig();

        final exposed = await collectExposedLibraries(
          dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
          frontendFs: frontendFs,
          packageConfig: packageConfig,
        );

        final aUri = Uri.parse('package:pkg_a/a.dart');
        final bUri = Uri.parse('package:pkg_a/b.dart');
        final cUri = Uri.parse('package:pkg_a/src/c.dart');
        final dUri = Uri.parse('package:pkg_b/d.dart');

        expect(exposed, containsAll([aUri, bUri, cUri, dUri]));
      },
    );

    test('handles circular exports without infinite loop', () async {
      final (frontendFs, _) = fssForTests(root, {
        'app/dynamic_interface.yaml': r'''
callable:
  - library: 'package:pkg_a/cycle_a.dart'
''',
        'pkg_a/lib/cycle_a.dart': r'''
export 'cycle_b.dart';
void a() {}
''',
        'pkg_a/lib/cycle_b.dart': r'''
export 'cycle_a.dart';
void b() {}
''',
      });

      final packageConfig = createPackageConfig();
      final exposed = await collectExposedLibraries(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
      );

      final aUri = Uri.parse('package:pkg_a/cycle_a.dart');
      final bUri = Uri.parse('package:pkg_a/cycle_b.dart');

      expect(exposed, containsAll([aUri, bUri]));
    });

    test('handles diamond export hierarchies', () async {
      final (frontendFs, _) = fssForTests(root, {
        'app/dynamic_interface.yaml': r'''
callable:
  - library: 'package:pkg_a/top.dart'
''',
        'pkg_a/lib/top.dart': r'''
export 'left.dart';
export 'right.dart';
''',
        'pkg_a/lib/left.dart': r'''
export 'bottom.dart';
''',
        'pkg_a/lib/right.dart': r'''
export 'bottom.dart';
''',
        'pkg_a/lib/bottom.dart': 'void bottom() {}',
      });

      final packageConfig = createPackageConfig();
      final exposed = await collectExposedLibraries(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
      );

      final top = Uri.parse('package:pkg_a/top.dart');
      final left = Uri.parse('package:pkg_a/left.dart');
      final right = Uri.parse('package:pkg_a/right.dart');
      final bottom = Uri.parse('package:pkg_a/bottom.dart');

      expect(exposed, containsAll([top, left, right, bottom]));
    });

    test('ignores dart: SDK libraries', () async {
      final (frontendFs, _) = fssForTests(root, {
        'app/dynamic_interface.yaml': r'''
callable:
  - library: 'package:pkg_a/lib.dart'
''',
        'pkg_a/lib/lib.dart': r'''
export 'dart:async';
export 'dart:core';
export 'package:unknown_host_pkg/foo.dart';
export 'valid_sub.dart';
''',
        'pkg_a/lib/valid_sub.dart': 'void sub() {}',
      });

      final packageConfig = createPackageConfig();
      final exposed = await collectExposedLibraries(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
      );

      final libUri = Uri.parse('package:pkg_a/lib.dart');
      final subUri = Uri.parse('package:pkg_a/valid_sub.dart');
      final unknownLibUri = Uri.parse('package:unknown_host_pkg/foo.dart');

      expect(exposed, containsAll([libUri, subUri, unknownLibUri]));
      expect(exposed.any((u) => u.isScheme('dart')), isFalse);
    });

    test(
      'tolerates missing files in known packages and non-package URIs',
      () async {
        final (frontendFs, _) = fssForTests(root, {
          'app/dynamic_interface.yaml': r'''
callable:
  - library: 'package:pkg_a/existing.dart'
  - library: 'package:pkg_a/missing_from_yaml.dart'
  - library: 'relative_missing.dart'
''',
          'pkg_a/lib/existing.dart': r'''
export 'missing_from_export.dart';
export 'valid_sub.dart';
''',
          'pkg_a/lib/valid_sub.dart': 'void sub() {}',
        });

        final packageConfig = createPackageConfig();
        final exposed = await collectExposedLibraries(
          dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
          frontendFs: frontendFs,
          packageConfig: packageConfig,
          enableRelativeDynamicInterfaceLibraries: true,
        );

        expect(
          exposed,
          containsAll([
            Uri.parse('package:pkg_a/existing.dart'),
            Uri.parse('package:pkg_a/missing_from_yaml.dart'),
            Uri.parse('package:pkg_a/missing_from_export.dart'),
            Uri.parse('package:pkg_a/valid_sub.dart'),
            Uri.parse('google3:///app/relative_missing.dart'),
          ]),
        );
      },
    );
  });

  group('resolveLibraryUri and enableRelativeDynamicInterfaceLibraries flag', () {
    test('throws StateError when relative URI used without flag', () {
      final packageConfig = createPackageConfig();
      final (frontendFs, _) = fssForTests(root, {});
      final collector = ExposedLibrariesCollector(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
        enableRelativeDynamicInterfaceLibraries: false,
      );

      expect(
        () => collector.resolveLibraryUri(
          'relative/local_lib.dart',
          dynamicInterfaceLibraryUri,
          false,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(
              'Relative library uri `relative/local_lib.dart` is not supported',
            ),
          ),
        ),
      );
    });

    test('accepts relative URI when enableRelativeDynamicInterfaceLibraries is true', () {
      final packageConfig = createPackageConfig();
      final (frontendFs, _) = fssForTests(root, {});
      final collector = ExposedLibrariesCollector(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
        enableRelativeDynamicInterfaceLibraries: true,
      );

      expect(
        collector.resolveLibraryUri(
          'relative/local_lib.dart',
          dynamicInterfaceLibraryUri,
          true,
        ),
        LibraryUri.parse('google3:///app/relative/local_lib.dart'),
      );
    });

    test('resolves relative export with .. from package library to package URI rather than disk parent', () async {
      // Reproduces review comment on CL 963311201 (snapshot 23, line 98):
      // Suppose package:pkg_a is located under pkg_a/lib/.
      // pkg_a/lib/a.dart exports '../b.dart'.
      //
      // By Dart language semantics, the relative export '../b.dart' is resolved
      // relative to the library import URI (package:pkg_a/a.dart), yielding
      // package:pkg_a/b.dart, which maps to pkg_a/lib/b.dart (file 2).
      //
      // If instead the relative export is resolved against the physical disk URI
      // of a.dart (google3:///pkg_a/lib/a.dart), it resolves to google3:///pkg_a/b.dart
      // (file 3, outside lib/ at the package root).
      final (frontendFs, _) = fssForTests(root, {
        'app/dynamic_interface.yaml': r'''
callable:
  - library: 'package:pkg_a/a.dart'
''',
        'pkg_a/lib/a.dart': r'''
export '../b.dart';
void a() {}
''',
        'pkg_a/lib/b.dart': 'void bInLib() {}',
        'pkg_a/b.dart': 'void bInRoot() {}',
      });

      final packageConfig = createPackageConfig();
      final exposed = await collectExposedLibraries(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
      );

      final bInLib = Uri.parse('package:pkg_a/b.dart');
      final bInRoot = Uri.parse('google3:///pkg_a/b.dart');

      // Dart language semantics expect package:pkg_a/b.dart
      // to be exposed, not pkg_a/b.dart.
      expect(exposed, contains(bInLib));
      expect(exposed, isNot(contains(bInRoot)));
    });

    test('resolveLibraryUri with relative ../ resolves differently from package URI vs disk URI', () {
      final packageConfig = createPackageConfig();
      final (frontendFs, _) = fssForTests(root, {});
      final collector = ExposedLibrariesCollector(
        dynamicInterfaceUri: dynamicInterfaceFileSystemUri,
        frontendFs: frontendFs,
        packageConfig: packageConfig,
        enableRelativeDynamicInterfaceLibraries: false,
      );

      // When currentUri is package:pkg_a/a.dart, resolving ../b.dart yields
      // package:pkg_a/b.dart:
      final fromPackageUri = collector.resolveLibraryUri(
        '../b.dart',
        LibraryUri.parse('package:pkg_a/a.dart'),
        true,
      );
      expect(fromPackageUri, Uri.parse('package:pkg_a/b.dart'));

      // When currentUri is disk URI google3:///pkg_a/lib/a.dart, resolving
      // ../b.dart steps out of lib/ to pkg_a/b.dart:
      final fromDiskUri = collector.resolveLibraryUri(
        '../b.dart',
        LibraryUri.parse('google3:///pkg_a/lib/a.dart'),
        true,
      );
      expect(fromDiskUri, Uri.parse('google3:///pkg_a/b.dart'));
    });
  });
}
