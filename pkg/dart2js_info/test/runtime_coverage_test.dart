// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for dart2js_info's runtime_coverage command.
//
// Regenerate files with dart2js flags:
// --multi-root-scheme='testroot'
// --multi-root='$PATH_TO_TEST_ROOT'
// --entry-uri='testroot:$TEST_FILE.dart'
// --dump-info=binary
// --packages=$PATH_TO_SDK/.dart_tool/package_config.json

import 'dart:io';

import 'package:dart2js_info/binary_serialization.dart';
import 'package:dart2js_info/src/runtime_coverage_utils.dart';
import 'package:dart2js_info/src/util.dart';

import 'package:test/test.dart';

void main() {
  group('runtime coverage', () {
    group('class filter (angular info)', () {
      final infoBinaryFile =
          File.fromUri(Platform.script.resolve('classes/classes.js.info.data'));
      final allInfo = decode(infoBinaryFile.readAsBytesSync());
      final classFilters =
          File.fromUri(Platform.script.resolve('classes/class_filter.txt'))
              .readAsLinesSync();
      final runtimeClassInfos = <String, RuntimeClassInfo>{};

      setUp(() {
        runtimeClassInfos.clear();
      });

      test('class filters are formatted properly', () {
        for (final filterString in classFilters) {
          expect(filterString.contains(' - '), isTrue);
        }
      });

      test('AngularInfo conversions throws on invalid schemes', () {
        expect(
            () => RuntimeClassInfo.fromAngularInfo(
                'no/scheme/here.dart - ClassName'),
            throwsArgumentError);
        expect(
            () => RuntimeClassInfo.fromAngularInfo('noscheme.dart - ClassName'),
            throwsArgumentError);
      });

      test('class filters parse and annotate properly', () {
        // Process class filters.
        for (final filterString in classFilters) {
          final runtimeClassInfo =
              RuntimeClassInfo.fromAngularInfo(filterString);
          expect(runtimeClassInfo.annotated, isFalse);
          runtimeClassInfos[runtimeClassInfo.key] = runtimeClassInfo;
        }

        // Annotate class filters with their corresponding ClassInfo.
        for (final classInfo in allInfo.classes) {
          final name = qualifiedName(classInfo);
          final nameWithoutScheme =
              name.substring(name.indexOf(':') + 1, name.length);
          final runtimeClassInfo = runtimeClassInfos[nameWithoutScheme];
          if (runtimeClassInfo != null) {
            runtimeClassInfo.annotateWithClassInfo(classInfo);
            expect(runtimeClassInfos[runtimeClassInfo.key], isNotNull);
          }
        }

        // Check that all class info objects are annotated.
        for (final runtimeClassInfo in runtimeClassInfos.values) {
          expect(runtimeClassInfo.annotated, isTrue);
        }
      });
    });
  });
}
