// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

// TODO(danchevalier): get this from DDS instead.
abstract class RpcErrorCodes {
  static json_rpc.RpcException buildRpcException(int code, {dynamic data}) {
    return json_rpc.RpcException(
      code,
      errorMessages[code]!,
      data: data,
    );
  }

  // These error codes must be kept in sync with those in vm/json_stream.h and
  // vmservice.dart.
  // static const kParseError = -32700;
  // static const kInvalidRequest = -32600;
  static const kMethodNotFound = -32601;

  static const kInvalidParams = -32602;

  static const kStreamAlreadySubscribed = 103;
  static const kStreamNotSubscribed = 104;

  static const kServiceAlreadyRegistered = 111;
  static const kServiceDisappeared = 112;

  static const kServiceMethodAlreadyRegistered = 132;

  static const kDirectoryDoesNotExist = 140;
  static const kFileDoesNotExist = 141;
  static const kPermissionDenied = 142;
  static const kExpectsUriParamWithFileScheme = 143;

  // Experimental (used in private rpcs).
  // static const kFileSystemAlreadyExists = 1001;
  // static const kFileSystemDoesNotExist = 1002;
  // static const kFileDoesNotExist = 1003;

  static const errorMessages = {
    kStreamAlreadySubscribed: 'Stream already subscribed',
    kStreamNotSubscribed: 'Stream not subscribed',
    kServiceAlreadyRegistered: 'Service already registered',
    kServiceDisappeared: 'Service has disappeared',
    kServiceMethodAlreadyRegistered:
        'The service method has already been registered',
    kDirectoryDoesNotExist: 'The directory does not exist',
    kFileDoesNotExist: 'The file does not exist',
    kPermissionDenied: 'Permission denied',
    kExpectsUriParamWithFileScheme: 'File scheme expected on uri',
  };
}
