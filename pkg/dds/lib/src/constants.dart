// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dds;

abstract class _RPCResponses {
  static const success = <String, dynamic>{
    'type': 'Success',
  };

  static const collectedSentinel = <String, dynamic>{
    'type': 'Sentinel',
    'kind': 'Collected',
    'valueAsString': '<collected>',
  };
}

abstract class _PauseTypeMasks {
  static const pauseOnStartMask = 1 << 0;
  static const pauseOnReloadMask = 1 << 1;
  static const pauseOnExitMask = 1 << 2;
}

abstract class _ServiceEvents {
  static const isolateExit = 'IsolateExit';
  static const isolateSpawn = 'IsolateSpawn';
  static const isolateStart = 'IsolateStart';
  static const pauseExit = 'PauseExit';
  static const pausePostRequest = 'PausePostRequest';
  static const pauseStart = 'PauseStart';
  static const resume = 'Resume';
}
