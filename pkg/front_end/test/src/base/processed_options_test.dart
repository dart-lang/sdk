// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/compiler_options.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ProcessedOptionsTest);
  });
}

@reflectiveTest
class ProcessedOptionsTest {
  final fileSystem = new MemoryFileSystem(pathos.posix, '/');

  test_compileSdk_false() {
    for (var value in [false, true]) {
      var raw = new CompilerOptions()..compileSdk = value;
      var processed = new ProcessedOptions(raw);
      expect(processed.compileSdk, value);
    }
  }

  test_fileSystem_noBazelRoots() {
    // When no bazel roots are specified, the filesystem should be passed
    // through unmodified.
    var raw = new CompilerOptions()..fileSystem = fileSystem;
    var processed = new ProcessedOptions(raw);
    expect(processed.fileSystem, same(fileSystem));
  }

  test_getUriResolver_explicitPackagesFile() async {
    // This .packages file should be ignored.
    fileSystem.entityForPath('/.packages').writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForPath('/explicit.packages')
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFilePath = '/explicit.packages';
    var processed = new ProcessedOptions(raw);
    var uriResolver = await processed.getUriResolver();
    expect(uriResolver.packages, {'foo': Uri.parse('file:///baz/')});
    expect(uriResolver.pathContext, same(fileSystem.context));
  }

  test_getUriResolver_explicitPackagesFile_withBaseLocation() async {
    // This .packages file should be ignored.
    fileSystem.entityForPath('/.packages').writeAsStringSync('foo:bar\n');
    // This one should be used.
    fileSystem
        .entityForPath('/base/location/explicit.packages')
        .writeAsStringSync('foo:baz\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFilePath = '/base/location/explicit.packages';
    var processed = new ProcessedOptions(raw);
    var uriResolver = await processed.getUriResolver();
    expect(
        uriResolver.packages, {'foo': Uri.parse('file:///base/location/baz/')});
    expect(uriResolver.pathContext, same(fileSystem.context));
  }

  test_getUriResolver_noPackages() async {
    // .packages file should be ignored.
    fileSystem.entityForPath('/.packages').writeAsStringSync('foo:bar\n');
    var raw = new CompilerOptions()
      ..fileSystem = fileSystem
      ..packagesFilePath = '';
    var processed = new ProcessedOptions(raw);
    var uriResolver = await processed.getUriResolver();
    expect(uriResolver.packages, isEmpty);
    expect(uriResolver.pathContext, same(fileSystem.context));
  }
}
