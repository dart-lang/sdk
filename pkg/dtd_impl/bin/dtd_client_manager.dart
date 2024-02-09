// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_service_protocol_shared/dart_service_protocol_shared.dart';

import 'dtd_client.dart';

/// Used for keeping track and managing clients that are connected to a given
/// service.
class DTDClientManager extends ClientManager {
  @override
  void addClient(Client client) {
    client as DTDClient;
    super.addClient(client);
    client.done.then((_) => removeClient(client));
  }
}
