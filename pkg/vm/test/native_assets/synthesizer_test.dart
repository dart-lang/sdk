// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/kernel_front_end.dart';
import 'package:vm/native_assets/diagnostic_message.dart';
import 'package:vm/native_assets/validator.dart';
import 'package:vm/native_assets/synthesizer.dart';

import '../common_test_utils.dart';

main() {
  test('valid', () {
    final errorDetector = ErrorDetector();
    final yamlString = '''
format-version: [1,0,0]
native-assets:
  linux_x64:
    'package:foo/foo.dart': ['absolute', '/path/to/libfoo.so']
''';
    final validatedYaml =
        NativeAssetsValidator(errorDetector).parseAndValidate(yamlString)!;
    final component = Component(
      libraries: [NativeAssetsSynthesizer.synthesizeLibrary(validatedYaml)],
      mode: NonNullableByDefaultCompiledMode.Strong,
    );
    final libraryToString = kernelLibraryToString(component.libraries.single);
    final expectedKernel = '''@#C3
@#C12
library;
import self as self;

constants  {
  #C1 = "vm:entry-point"
  #C2 = null
  #C3 = #lib1::pragma {name:#C1, options:#C2}
  #C4 = "vm:ffi:native-assets"
  #C5 = "linux_x64"
  #C6 = "package:foo/foo.dart"
  #C7 = "absolute"
  #C8 = "/path/to/libfoo.so"
  #C9 = <dynamic>[#C7, #C8]
  #C10 = <dynamic, dynamic>{#C6:#C9}
  #C11 = <dynamic, dynamic>{#C5:#C10}
  #C12 = #lib1::pragma {name:#C4, options:#C11}
}
''';
    expect(libraryToString, equals(expectedKernel));
  });

  test('no file', () async {
    final errors = <NativeAssetsDiagnosticMessage>[];
    final errorDetector = ErrorDetector(
        previousErrorHandler: (message) =>
            errors.add(message as NativeAssetsDiagnosticMessage));
    final uri = Directory.systemTemp.uri.resolve('file_does_not_exist.yaml');
    Object? result =
        await NativeAssetsSynthesizer.synthesizeLibraryFromYamlFile(
            uri, errorDetector);
    expect(result, null);
    expect(errorDetector.hasCompilationErrors, true);
    expect(errors.single.message,
        equals("Native assets file ${uri.toFilePath()} doesn't exist."));
  });
}
