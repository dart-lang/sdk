// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/52893

// VMOptions=--retain_function_objects=true
// VMOptions=--retain_function_objects=false

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'fetch_all_types_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('fetch_all_types_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final profile = await service.getAllocationProfile(isolateRef.id!);
      for (var entry in profile.members!) {
        if (entry.instancesCurrent == 0) continue;

        final classRef = entry.classRef!;
        print(classRef);
        if (classRef.name == 'Sentinel') continue;
        if (classRef.name == 'Null') continue;
        final instanceSet =
            await service.getInstances(isolateRef.id!, classRef.id!, 10);
        for (var instance in instanceSet.instances!) {
          await service.getObject(isolateRef.id!, instance.id!);
        }
      }
    }).run(testeeMain: testee_lib.main);
