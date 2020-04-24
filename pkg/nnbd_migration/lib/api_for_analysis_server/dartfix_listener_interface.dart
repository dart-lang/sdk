// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:nnbd_migration/api_for_analysis_server/driver_provider.dart';

abstract class DartFixListenerInterface {
  DriverProvider get server;

  SourceChange get sourceChange;
}
