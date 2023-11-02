// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'http_get_vm_rpc_common.dart';
import '../common/test_helper.dart';

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'http_auth_get_vm_rpc_test.dart',
      testeeBefore: testeeBefore,
    );
