// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch bool sendIsolateServiceMessage(SendPort sp, List m)
    native "VMService_SendIsolateServiceMessage";
patch void sendRootServiceMessage(List m)
    native "VMService_SendRootServiceMessage";
patch void _onStart() native "VMService_OnStart";
patch void _onExit() native "VMService_OnExit";
patch bool _vmListenStream(String streamId) native "VMService_ListenStream";
patch void _vmCancelStream(String streamId) native "VMService_CancelStream";
patch Uint8List _requestAssets() native "VMService_RequestAssets";