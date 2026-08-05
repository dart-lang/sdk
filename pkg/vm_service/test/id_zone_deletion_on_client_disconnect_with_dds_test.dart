// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'id_zone_deletion_on_client_disconnect_common.dart';
import 'id_zone_deletion_on_client_disconnect_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    createHarness(args).run(testeeMain: testee_lib.main);
