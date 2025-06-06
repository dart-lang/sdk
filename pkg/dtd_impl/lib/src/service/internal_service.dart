// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../dtd_client.dart';

abstract class InternalService {
  String get serviceName;

  void register(DTDClient client);

  void shutdown();
}
