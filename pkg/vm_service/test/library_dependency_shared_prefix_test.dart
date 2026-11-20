// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

// ignore: invalid_language_version_override
// @dart = 3.6

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'library_dependency_shared_prefix_lib.dart' as testee_lib;

// Parts of a library can import different libraries with the same prefix
// name, including a deferred import. All of these imports must be reported as
// dependencies of the library.
void main([args = const <String>[]]) =>
    IsolateTestHarness('library_dependency_shared_prefix_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolate = await service.getIsolate(isolateRef.id!);
      final libRef = isolate.libraries!.firstWhere(
        (lib) => lib.uri!.contains('library_dependency_shared_prefix_lib'),
      );
      final lib = await service.getObject(isolate.id!, libRef.id!) as Library;

      final prefixed = <String, String>{
        for (final dep in lib.dependencies!)
          if (dep.prefix case final prefix? when prefix.isNotEmpty)
            dep.target!.name!: prefix,
      };
      expect(prefixed, {'dart.collection': 'l', 'dart.math': 'l'});
    }).run(
      testeeMain: testee_lib.main,
      extraArgs: ['--enable-experiment=enhanced-parts'],
    );
