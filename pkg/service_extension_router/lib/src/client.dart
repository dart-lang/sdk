// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(danchevalier): Add documentation before major release
abstract class Client {
  void streamNotify(String stream, Map<String, Object?> data);

  Future<void> close();
  Future<dynamic> sendRequest({required String method, dynamic parameters});

  final Map<String, String> services = {};

  static int _idCounter = 0;
  final int _id = ++_idCounter;

  /// The name given to the client upon its creation.
  String get defaultClientName => 'client$_id';

  /// The current name associated with this client.
  String? get name => _name;

  // NOTE: this should not be called directly except from:
  //   - `ClientManager._clearClientName`
  //   - `ClientManager._setClientNameHelper`
  set name(String? n) => _name = n ?? defaultClientName;
  String? _name;
}
