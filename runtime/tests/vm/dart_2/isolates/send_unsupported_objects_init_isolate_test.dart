// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import '../use_flag_test_helper.dart';

import 'send_unsupported_objects_test.dart';

main() async {
  asyncStart();

  final fu = Fu.unsendable('fu');
  try {
    await () async {
      final foo1 = Foo();
      await () async {
        final foo2 = Foo();
        await () async {
          final foo3 = Foo();
          await Isolate.spawn((arg) {
            arg();
          }, () {
            print('${fu.label} $foo1 $foo2 $foo3');
            Expect.fail('This closure should fail to be sent, '
                'shouldn\'t be called');
          });
        }();
      }();
    }();
  } catch (e) {
    print(e);
    Expect.isTrue(checkForRetainingPath(e, <String>[
      'nativeClass in Instance of \'Baz\' ',
      'baz in Instance of \'Fu\'',
      if (isAOTRuntime) ...[
        'Context',
        'main.<anonymous closure>'
      ] else ...[
        'field fu in main.<anonymous closure>'
      ],
    ]));
    asyncEnd();
  }
}
