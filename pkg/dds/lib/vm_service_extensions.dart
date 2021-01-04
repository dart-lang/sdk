// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:vm_service/src/vm_service.dart';

extension DdsExtension on VmService {
  static bool _factoriesRegistered = false;
  static Version _ddsVersion;

  /// The _getDartDevelopmentServiceVersion_ RPC is used to determine what version of
  /// the Dart Development Service Protocol is served by a DDS instance.
  ///
  /// The result of this call is cached for subsequent invocations.
  Future<Version> getDartDevelopmentServiceVersion() async {
    if (_ddsVersion == null) {
      _ddsVersion =
          await _callHelper<Version>('getDartDevelopmentServiceVersion');
    }
    return _ddsVersion;
  }

  /// Retrieve the event history for `stream`.
  ///
  /// If `stream` does not have event history collected, a parameter error is
  /// returned.
  Future<StreamHistory> getStreamHistory(String stream) async {
    if (!(await _versionCheck(1, 2))) {
      throw UnimplementedError('getStreamHistory requires DDS version 1.2');
    }
    return _callHelper<StreamHistory>('getStreamHistory', args: {
      'stream': stream,
    });
  }

  Future<bool> _versionCheck(int major, int minor) async {
    if (_ddsVersion == null) {
      _ddsVersion = await getDartDevelopmentServiceVersion();
    }
    return ((_ddsVersion.major == major && _ddsVersion.minor >= minor) ||
        (_ddsVersion.major > major));
  }

  Future<T> _callHelper<T>(String method,
      {String isolateId, Map args = const {}}) {
    if (!_factoriesRegistered) {
      _registerFactories();
    }
    return callMethod(
      method,
      args: {
        if (isolateId != null) 'isolateId': isolateId,
        ...args,
      },
    ).then((e) => e as T);
  }

  static void _registerFactories() {
    addTypeFactory('StreamHistory', StreamHistory.parse);
    _factoriesRegistered = true;
  }
}

/// A collection of historical [Event]s from some stream.
class StreamHistory extends Response {
  static StreamHistory parse(Map<String, dynamic> json) =>
      json == null ? null : StreamHistory._fromJson(json);

  StreamHistory({@required List<Event> history}) : _history = history;

  StreamHistory._fromJson(Map<String, dynamic> json)
      : _history = List<Event>.from(
            createServiceObject(json['history'], const ['Event']) as List ??
                []) {
    type = json['type'];
  }

  /// Historical [Event]s for a stream.
  List<Event> get history => UnmodifiableListView(_history);
  final List<Event> _history;
}
