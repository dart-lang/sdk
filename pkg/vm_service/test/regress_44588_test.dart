// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'regress_44588_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('regress_44588_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolate) async {
      final classes = (await service.getClassList(isolate.id!)).classes!;
      final fooRef = classes.firstWhere((element) => element.name == 'Foo');
      final foo = (await service.getObject(isolate.id!, fooRef.id!)) as Class;
      final field = (await service.getObject(
        isolate.id!,
        foo.fields!.first.id!,
      )) as Field;
      expect(field.staticValue!.valueAsString, '<not initialized>');
    }).run(testeeMain: testee_lib.main);
