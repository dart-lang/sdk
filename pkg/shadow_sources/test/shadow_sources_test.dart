// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shadow_sources/src/shadow_options.dart';
import 'package:shadow_sources/src/shadow_sources.dart';
import 'package:test/test.dart';

import 'util/fss.dart';

void main() {
  const root = '/google/src/cloud/user/workspace/google3';

  test('basic', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'mobile/flutter/samples/ddm/app/bytecode/returns_min_function_from_collection.dart':
          r'''
import 'package:collection/collection.dart';

typedef MinFunction = T Function<T extends Comparable<T>>(Iterable<T>);

T _minProxy<T extends Comparable<T>>(Iterable<T> iterable) => iterable.min;

@pragma('dyn-module:entry-point')
MinFunction main() => _minProxy;
''',
      'blaze-bin/mobile/flutter/samples/ddm/app/bytecode/returns_min_function_from_collection.packages':
          r'''
{"configVersion": 2, "packages": [
{ "name": "mobile.flutter.samples.ddm.app.bytecode"
,"rootUri": "../../../../../../mobile/flutter/samples/ddm/app/bytecode/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "collection"
,"rootUri": "../../../../../../third_party/dart/collection/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
,
{ "name": "meta"
,"rootUri": "../../../../../../third_party/dart/meta/"
,"packageUri": "lib/"
,"languageVersion": "3.5"
}
], "generator": "Bazel" }
''',
      'mobile/flutter/samples/ddm/app/bytecode/dynamic_interface.yaml': r'''
extendable:
  - library: 'dart:core'
  - library: 'dart:collection'
  - library: 'dart:_internal'
  - library: 'dart:async'
  - library: 'dart:typed_data'
  - library: 'package:flutter/src/widgets/framework.dart'
    class: 'State'
  - library: 'package:flutter/src/widgets/framework.dart'
    class: 'StatefulWidget'
  - library: 'package:flutter/src/widgets/framework.dart'
    class: 'StatelessWidget'

can-be-overridden:
  - library: 'dart:core'
  - library: 'dart:collection'
  - library: 'dart:collection'
    class: 'UnmodifiableListView'
    member: '_source'
  - library: 'dart:_internal'
  - library: 'dart:async'
  - library: 'dart:typed_data'
  - library: 'package:flutter/src/widgets/framework.dart'
    class: 'State'
  - library: 'package:flutter/src/widgets/framework.dart'
    class: 'StatefulWidget'
  - library: 'package:flutter/src/widgets/framework.dart'
    class: 'StatelessWidget'
  - library: 'package:flutter/src/foundation/diagnostics.dart'

callable:
  - library: 'dart:core'
  - library: 'dart:async'
  - library: 'dart:collection'
  - library: 'dart:convert'
  - library: 'dart:math'
  - library: 'dart:typed_data'
  - library: 'dart:ui'
  - library: 'dart:_internal'
  - library: 'package:meta/meta.dart'
  - library: 'package:flutter/material.dart'
  - library: 'package:quiver/iterables.dart' # Library is used in bytecode, but not in the app.
''',
      'third_party/dart/collection/lib/collection.dart': r'''
// just to make traversal more fun.
import 'src/list.dart';

void hello() {};
''',
      'blaze-genfiles/third_party/dart/collection/lib/src/list.dart': '',
      'third_party/dart/meta/lib/meta.dart': 'export "meta_meta.dart";',
      'third_party/dart/meta/lib/meta_meta.dart': '',
    });

    final scriptFile =
        'google3:///mobile/flutter/samples/ddm/app/bytecode/returns_min_function_from_collection.dart';

    final packagesFile =
        'google3:///mobile/flutter/samples/ddm/app/bytecode/returns_min_function_from_collection.packages';

    final dynamicInterfaceFile =
        'google3:///mobile/flutter/samples/ddm/app/bytecode/dynamic_interface.yaml';

    final options = ShadowOptions.create(
      scriptUri: scriptFile,
      packagesUri: packagesFile,
      dynamicInterfaceUri: dynamicInterfaceFile,
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      logger: print,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final rewrittenEntrypoint = fs.file(
      '/tmp/output/dir/mobile/flutter/samples/ddm/app/bytecode/shadowed_returns_min_function_from_collection.dart',
    );
    expect(rewrittenEntrypoint.existsSync(), isTrue);
    expect(
      rewrittenEntrypoint.readAsStringSync(),
      contains("import 'package:collection/shadowed_collection.dart';"),
    );
  });

  test('shadows module sources and external dependencies', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
import 'package:my_module/helper.dart';
import 'relative_helper.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

void main() {
  helper();
  relativeHelper();
}
''',
      'my_module/lib/helper.dart': r'''
void helper() {}
''',
      'my_module/lib/relative_helper.dart': r'''
import 'package:collection/collection.dart';

void relativeHelper() {}
''',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "collection"
,"rootUri": "../../../../../../third_party/dart/collection/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
,
{ "name": "meta"
,"rootUri": "../../../../../../third_party/dart/meta/"
,"packageUri": "lib/"
,"languageVersion": "3.5"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': r'''
callable:
  - library: 'package:meta/meta.dart'
''',
      'third_party/dart/collection/lib/collection.dart': r'''
void collectionHelper() {}
''',
      'third_party/dart/meta/lib/meta.dart': r'''
void metaHelper() {}
''',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'google3:///my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    // Module files must be written with "shadowed_" prefix.
    final mainFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_main.dart',
    );
    final helperFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_helper.dart',
    );
    final relativeHelperFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_relative_helper.dart',
    );

    expect(mainFile.existsSync(), isTrue);
    expect(helperFile.existsSync(), isTrue);
    expect(relativeHelperFile.existsSync(), isTrue);

    // Intra-module directives must be rewritten to shadowed filenames.
    final mainContent = mainFile.readAsStringSync();
    expect(
      mainContent,
      contains("import 'package:my_module/shadowed_helper.dart';"),
    );
    expect(mainContent, contains("import 'shadowed_relative_helper.dart';"));

    // Unexposed external dependency must be rewritten.
    expect(
      mainContent,
      contains("import 'package:collection/shadowed_collection.dart';"),
    );
    // Exposed external dependency must NOT be rewritten.
    expect(mainContent, contains("import 'package:meta/meta.dart';"));

    final relativeHelperContent = relativeHelperFile.readAsStringSync();
    expect(
      relativeHelperContent,
      contains("import 'package:collection/shadowed_collection.dart';"),
    );

    // External dependency must be written as shadowed file.
    final shadowedCollectionFile = fs.file(
      '/tmp/output/dir/third_party/dart/collection/lib/shadowed_collection.dart',
    );
    expect(shadowedCollectionFile.existsSync(), isTrue);
  });

  test('shadows multi-hop transitive unexposed dependencies', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
import 'package:pkg_a/a.dart';
void main() {}
''',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "pkg_a"
,"rootUri": "../../../../../../third_party/dart/pkg_a/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
,
{ "name": "pkg_b"
,"rootUri": "../../../../../../third_party/dart/pkg_b/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
,
{ "name": "pkg_c"
,"rootUri": "../../../../../../third_party/dart/pkg_c/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': '{}',
      'third_party/dart/pkg_a/lib/a.dart': r'''
import 'package:pkg_b/b.dart';
void funcA() {}
''',
      'third_party/dart/pkg_b/lib/b.dart': r'''
import 'package:pkg_c/c.dart';
void funcB() {}
''',
      'third_party/dart/pkg_c/lib/c.dart': r'''
void funcC() {}
''',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'google3:///my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final fileA = fs.file(
      '/tmp/output/dir/third_party/dart/pkg_a/lib/shadowed_a.dart',
    );
    final fileB = fs.file(
      '/tmp/output/dir/third_party/dart/pkg_b/lib/shadowed_b.dart',
    );
    final fileC = fs.file(
      '/tmp/output/dir/third_party/dart/pkg_c/lib/shadowed_c.dart',
    );

    expect(fileA.existsSync(), isTrue);
    expect(fileB.existsSync(), isTrue);
    expect(fileC.existsSync(), isTrue);

    expect(
      fileA.readAsStringSync(),
      contains("import 'package:pkg_b/shadowed_b.dart';"),
    );
    expect(
      fileB.readAsStringSync(),
      contains("import 'package:pkg_c/shadowed_c.dart';"),
    );
  });

  test(
    'throws on relative dynamic interface libraries when disabled',
    () async {
      final (frontendFs, _) = fssForTests(root, {
        'my_module/lib/main.dart': 'void main() {}',
        'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
], "generator": "Bazel" }
''',
        'my_module/lib/dynamic_interface.yaml': r'''
callable:
  - library: 'relative/sub.dart'
''',
      });

      final options = ShadowOptions.create(
        scriptUri: 'google3:///my_module/lib/main.dart',
        packagesUri: 'google3:///my_module/lib/main.packages',
        dynamicInterfaceUri: 'file:///google/src/cloud/user/workspace/google3/my_module/lib/dynamic_interface.yaml',
        frontendFs: frontendFs,
        prefix: 'shadowed',
        outputDir: 'file:///tmp/output/dir/',
      );

      expect(
        () => shadowSources(options, fileWriter: (uri, content) async {}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Relative library uri `relative/sub.dart` is not supported.',
          ),
        ),
      );
    },
  );

  test('throws on relative imports in entrypoint when enableRelativeEntrypointScriptImports is false', () async {
    final (frontendFs, _) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
import 'helper.dart';
void main() {}
''',
      'my_module/lib/helper.dart': 'void helper() {}',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': '{}',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'file:///google/src/cloud/user/workspace/google3/my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    expect(
      () => shadowSources(options, fileWriter: (uri, content) async {}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'Relative import `helper.dart` is not supported for this entrypoint script.',
        ),
      ),
    );
  });

  test(
    'throws ArgumentError when source file does not exist in frontendFs',
    () async {
      final (frontendFs, _) = fssForTests(root, {
        'my_module/lib/main.dart': r'''
import 'package:collection/collection.dart';
void main() {}
''',
        'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "collection"
,"rootUri": "../../../../../../third_party/dart/collection/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
], "generator": "Bazel" }
''',
        'my_module/lib/dynamic_interface.yaml': '{}',
        // Note: third_party/dart/collection/lib/collection.dart is missing from
        // filesystem.
      });

      final options = ShadowOptions.create(
        scriptUri: 'google3:///my_module/lib/main.dart',
        packagesUri: 'google3:///my_module/lib/main.packages',
        dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
        frontendFs: frontendFs,
        prefix: 'shadowed',
        outputDir: 'file:///tmp/output/dir/',
      );

      expect(
        () => shadowSources(options, fileWriter: (uri, content) async {}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('does not exist'),
          ),
        ),
      );
    },
  );

  test('shadows standalone entrypoint and its dependencies', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'standalone/main.dart': r'''
import 'package:collection/collection.dart';
void main() {}
''',
      'standalone/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "other_package"
,"rootUri": "../other/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "collection"
,"rootUri": "../../../../../../third_party/dart/collection/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
], "generator": "Bazel" }
''',
      'standalone/dynamic_interface.yaml': '{}',
      'third_party/dart/collection/lib/collection.dart': 'void hello() {}',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///standalone/main.dart',
      packagesUri: 'google3:///standalone/main.packages',
      dynamicInterfaceUri: 'google3:///standalone/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final mainFile = fs.file('/tmp/output/dir/standalone/shadowed_main.dart');
    expect(mainFile.existsSync(), isTrue);
    final mainContent = mainFile.readAsStringSync();
    expect(
      mainContent,
      contains("import 'package:collection/shadowed_collection.dart';"),
    );

    final shadowedCollectionFile = fs.file(
      '/tmp/output/dir/third_party/dart/collection/lib/shadowed_collection.dart',
    );
    expect(shadowedCollectionFile.existsSync(), isTrue);
  });

  test('handles part and part-of directives in shadowed module sources and external dependencies', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
import 'package:external_pkg/external.dart';
part 'part_file.dart';

void main() {}
''',
      'my_module/lib/part_file.dart': r'''
part of 'main.dart';

void partFunc() {}
''',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "external_pkg"
,"rootUri": "../../../../../../third_party/dart/external_pkg/"
,"packageUri": "lib/"
,"languageVersion": "3.4"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': '{}',
      'third_party/dart/external_pkg/lib/external.dart': r'''
part 'src/external_part.dart';

void ext() {}
''',
      'third_party/dart/external_pkg/lib/src/external_part.dart': r'''
part of '../external.dart';

void extPart() {}
''',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'google3:///my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final mainFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_main.dart',
    );
    final partFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_part_file.dart',
    );
    expect(mainFile.existsSync(), isTrue);
    expect(partFile.existsSync(), isTrue);

    final mainContent = mainFile.readAsStringSync();
    expect(mainContent, contains("part 'shadowed_part_file.dart';"));
    expect(
      mainContent,
      contains("import 'package:external_pkg/shadowed_external.dart';"),
    );

    final partContent = partFile.readAsStringSync();
    expect(partContent, contains("part of 'shadowed_main.dart';"));

    final extFile = fs.file(
      '/tmp/output/dir/third_party/dart/external_pkg/lib/shadowed_external.dart',
    );
    final extPartFile = fs.file(
      '/tmp/output/dir/third_party/dart/external_pkg/lib/src/shadowed_external_part.dart',
    );
    expect(extFile.existsSync(), isTrue);
    expect(extPartFile.existsSync(), isTrue);

    final extContent = extFile.readAsStringSync();
    expect(extContent, contains("part 'src/shadowed_external_part.dart';"));

    final extPartContent = extPartFile.readAsStringSync();
    expect(extPartContent, contains("part of '../shadowed_external.dart';"));
  });

  test('handles named part-of directive in shadowed sources', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
library my_module;
part 'named_part.dart';

void main() {}
''',
      'my_module/lib/named_part.dart': r'''
part of my_module;

void namedPartFunc() {}
''',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': '{}',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'google3:///my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final mainFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_main.dart',
    );
    final partFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_named_part.dart',
    );
    expect(mainFile.existsSync(), isTrue);
    expect(partFile.existsSync(), isTrue);

    final mainContent = mainFile.readAsStringSync();
    expect(mainContent, contains("part 'shadowed_named_part.dart';"));

    final partContent = partFile.readAsStringSync();
    expect(partContent, contains('part of my_module;'));
  });

  test('transitively expands export directives of exposed umbrella libraries', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
import 'package:umbrella/umbrella.dart';
import 'package:umbrella/src/sub_a.dart';
import 'package:umbrella/src/sub_b.dart';
import 'package:exported_dep/exported_dep.dart';
import 'package:unexposed/unexposed.dart';

void main() {
  umbrellaFunc();
  subAFunc();
  subBFunc();
  exportedDepFunc();
  unexposedFunc();
}
''',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "umbrella"
,"rootUri": "../../../../../../third_party/dart/umbrella/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "exported_dep"
,"rootUri": "../../../../../../third_party/dart/exported_dep/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "unexposed"
,"rootUri": "../../../../../../third_party/dart/unexposed/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': r'''
callable:
  - library: 'package:umbrella/umbrella.dart'
''',
      'third_party/dart/umbrella/lib/umbrella.dart': r'''
export 'src/sub_a.dart';
export 'package:exported_dep/exported_dep.dart';
export 'dart:async';

void umbrellaFunc() {}
''',
      'third_party/dart/umbrella/lib/src/sub_a.dart': r'''
export 'sub_b.dart';

void subAFunc() {}
''',
      'third_party/dart/umbrella/lib/src/sub_b.dart': r'''
export '../umbrella.dart';

void subBFunc() {}
''',
      'third_party/dart/exported_dep/lib/exported_dep.dart': r'''
void exportedDepFunc() {}
''',
      'third_party/dart/unexposed/lib/unexposed.dart': r'''
void unexposedFunc() {}
''',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'google3:///my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final mainFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_main.dart',
    );
    expect(mainFile.existsSync(), isTrue);

    final mainContent = mainFile.readAsStringSync();
    expect(mainContent, contains("import 'package:umbrella/umbrella.dart';"));
    expect(mainContent, contains("import 'package:umbrella/src/sub_a.dart';"));
    expect(mainContent, contains("import 'package:umbrella/src/sub_b.dart';"));
    expect(
      mainContent,
      contains("import 'package:exported_dep/exported_dep.dart';"),
    );
    expect(
      mainContent,
      contains("import 'package:unexposed/shadowed_unexposed.dart';"),
    );

    final shadowedUnexposedFile = fs.file(
      '/tmp/output/dir/third_party/dart/unexposed/lib/shadowed_unexposed.dart',
    );
    expect(shadowedUnexposedFile.existsSync(), isTrue);

    final shadowedUmbrellaFile = fs.file(
      '/tmp/output/dir/third_party/dart/umbrella/lib/shadowed_umbrella.dart',
    );
    expect(shadowedUmbrellaFile.existsSync(), isFalse);

    final shadowedSubAFile = fs.file(
      '/tmp/output/dir/third_party/dart/umbrella/lib/src/shadowed_sub_a.dart',
    );
    expect(shadowedSubAFile.existsSync(), isFalse);

    final shadowedSubBFile = fs.file(
      '/tmp/output/dir/third_party/dart/umbrella/lib/src/shadowed_sub_b.dart',
    );
    expect(shadowedSubBFile.existsSync(), isFalse);

    final shadowedExportedDepFile = fs.file(
      '/tmp/output/dir/third_party/dart/exported_dep/lib/shadowed_exported_dep.dart',
    );
    expect(shadowedExportedDepFile.existsSync(), isFalse);
  });

  test('does not expand exports of class-restricted libraries, but expands umbrella and dynamically-callable libraries', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
import 'package:class_only_dep/class_only_dep.dart';
import 'package:class_only_dep/src/class_only_sub.dart';
import 'package:umbrella/umbrella.dart';
import 'package:umbrella/src/sub_exported.dart';
import 'package:dyn_umbrella/dyn_umbrella.dart';
import 'package:dyn_umbrella/src/dyn_sub.dart';

void main() {
  ClassOnly();
  classOnlySubFunc();
  umbrellaFunc();
  subExportedFunc();
  dynUmbrellaFunc();
  dynSubFunc();
}
''',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "class_only_dep"
,"rootUri": "../../../../../../third_party/dart/class_only_dep/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "umbrella"
,"rootUri": "../../../../../../third_party/dart/umbrella/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "dyn_umbrella"
,"rootUri": "../../../../../../third_party/dart/dyn_umbrella/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': r'''
extendable:
  - library: 'package:class_only_dep/class_only_dep.dart'
    class: 'ClassOnly'
  # package:umbrella/src/sub_exported.dart is in extendable with a class,
  # but also exported by umbrella.dart. Its transitive exports must still
  # expand.
  - library: 'package:umbrella/src/sub_exported.dart'
    class: 'ExportedClass'
callable:
  - library: 'package:umbrella/umbrella.dart'
dynamically-callable:
  - library: 'package:dyn_umbrella/dyn_umbrella.dart'
''',
      'third_party/dart/class_only_dep/lib/class_only_dep.dart': r'''
export 'src/class_only_sub.dart';

class ClassOnly {}
''',
      'third_party/dart/class_only_dep/lib/src/class_only_sub.dart': r'''
void classOnlySubFunc() {}
''',
      'third_party/dart/umbrella/lib/umbrella.dart': r'''
export 'src/sub_exported.dart';

void umbrellaFunc() {}
''',
      'third_party/dart/umbrella/lib/src/sub_exported.dart': r'''
export 'deep_exported.dart';

class ExportedClass {}
void subExportedFunc() {}
''',
      'third_party/dart/umbrella/lib/src/deep_exported.dart': r'''
void deepExportedFunc() {}
''',
      'third_party/dart/dyn_umbrella/lib/dyn_umbrella.dart': r'''
export 'src/dyn_sub.dart';

void dynUmbrellaFunc() {}
''',
      'third_party/dart/dyn_umbrella/lib/src/dyn_sub.dart': r'''
void dynSubFunc() {}
''',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'google3:///my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final mainFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_main.dart',
    );
    expect(mainFile.existsSync(), isTrue);

    final mainContent = mainFile.readAsStringSync();

    expect(
      mainContent,
      contains("import 'package:class_only_dep/class_only_dep.dart';"),
    );
    expect(
      mainContent,
      contains(
        "import 'package:class_only_dep/src/shadowed_class_only_sub.dart';",
      ),
    );

    expect(mainContent, contains("import 'package:umbrella/umbrella.dart';"));
    expect(
      mainContent,
      contains("import 'package:umbrella/src/sub_exported.dart';"),
    );

    expect(
      mainContent,
      contains("import 'package:dyn_umbrella/dyn_umbrella.dart';"),
    );
    expect(
      mainContent,
      contains("import 'package:dyn_umbrella/src/dyn_sub.dart';"),
    );

    final shadowedClassOnlySub = fs.file(
      '/tmp/output/dir/third_party/dart/class_only_dep/lib/src/shadowed_class_only_sub.dart',
    );
    expect(shadowedClassOnlySub.existsSync(), isTrue);

    final shadowedDynSub = fs.file(
      '/tmp/output/dir/third_party/dart/dyn_umbrella/lib/src/shadowed_dyn_sub.dart',
    );
    expect(shadowedDynSub.existsSync(), isFalse);
  });

  test('does not shadow partially exposed library with unexposed sibling classes', () async {
    final (frontendFs, fs) = fssForTests(root, {
      'my_module/lib/main.dart': r'''
import 'package:foo/bar.dart';

void main() {
  Bar();
  Baz();
}
''',
      'my_module/lib/main.packages': r'''
{"configVersion": 2, "packages": [
{ "name": "my_module"
,"rootUri": "../"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
,
{ "name": "foo"
,"rootUri": "../../../../../../third_party/dart/foo/"
,"packageUri": "lib/"
,"languageVersion": "3.13"
}
], "generator": "Bazel" }
''',
      'my_module/lib/dynamic_interface.yaml': r'''
callable:
  - library: 'package:foo/bar.dart'
    class: 'Bar'
''',
      'third_party/dart/foo/lib/bar.dart': r'''
class Bar {}
class Baz {}
''',
    });

    final options = ShadowOptions.create(
      scriptUri: 'google3:///my_module/lib/main.dart',
      packagesUri: 'google3:///my_module/lib/main.packages',
      dynamicInterfaceUri: 'google3:///my_module/lib/dynamic_interface.yaml',
      frontendFs: frontendFs,
      prefix: 'shadowed',
      outputDir: 'file:///tmp/output/dir/',
    );

    await shadowSources(
      options,
      fileWriter: (uri, content) async {
        final file = fs.file(uri.toFilePath());
        await file.parent.create(recursive: true);
        await file.writeAsString(content);
      },
    );

    final mainFile = fs.file(
      '/tmp/output/dir/my_module/lib/shadowed_main.dart',
    );
    expect(mainFile.existsSync(), isTrue);

    final mainContent = mainFile.readAsStringSync();

    // The entire library is not shadowed because it has an exposed class 'Bar',
    // even though 'Baz' is not exposed.
    expect(mainContent, contains("import 'package:foo/bar.dart';"));
    expect(mainContent, isNot(contains('shadowed_bar.dart')));

    final shadowedBar = fs.file(
      '/tmp/output/dir/third_party/dart/foo/lib/shadowed_bar.dart',
    );
    expect(shadowedBar.existsSync(), isFalse);
  });
}
