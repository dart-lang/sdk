// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=wildcard-variables

// ignore: invalid_language_version_override
// @dart = 3.7

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'wildcard_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'wildcard_lib.dart',
      args,
    )
    .hasStoppedAtBreakpoint()
    .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);

      final lib =
          await service.getObject(
                isolateId,
                isolate.libraries!
                    .firstWhere((l) => l.uri!.contains('wildcard_lib'))
                    .id!,
              )
              as Library;
      final ioImport = lib.dependencies!.firstWhere(
        (e) => e.target!.name == 'dart.io',
      );
      // Wildcard prefixes shouldn't be stripped from imports.
      expect(ioImport.prefix, '_');

      final stack = await service.getStack(isolateId);
      final frame = stack.frames!.first;
      final function =
          await service.getObject(isolateId, frame.function!.id!) as Func;
      expect(function.name, '<anonymous closure>');

      // Type parameter names are replaced with synthetic names in general so we
      // don't need to check for the name '_' here.
      final typeParameters = function.signature!.typeParameters!;
      expect(typeParameters.length, 1);

      // There should only be bound variables for non-wildcard parameters.
      final vars = frame.vars!;
      expect(vars.length, 1);
      expect(vars.first.name, 'i');
    })
    .run(
      testeeMain: testee_lib.main,
      extraArgs: ['--enable-experiment=wildcard-variables'],
    );
