// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';
import 'id_zone_deletion_on_client_disconnect_common.dart';

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      idZoneDeletionOnDisconnectTests,
      'id_zone_deletion_on_client_disconnect_without_dds_test.dart',
      extraArgs: ['--no-dds'],
      testeeConcurrent: testeeMain,
    );
