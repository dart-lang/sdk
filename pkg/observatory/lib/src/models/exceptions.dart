// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class BasicException implements Exception {
  String get message;
}

abstract class ConnectionException implements BasicException {}

abstract class ResponseException implements BasicException {}

abstract class RequestException implements BasicException {}

abstract class ParseErrorException implements RequestException {}

abstract class InvalidRequestException implements RequestException {}

abstract class MethodNotFoundException implements RequestException {}

abstract class InvalidParamsException implements RequestException {}

abstract class InternalErrorException implements RequestException {}

abstract class FeatureDisabledException implements RequestException {}

abstract class CannotAddBreakpointException implements RequestException {}

abstract class StreamAlreadySubscribedException implements RequestException {}

abstract class StreamNotSubscribedException implements RequestException {}

abstract class IsolateMustBeRunnableException implements RequestException {}

abstract class IsolateMustBePausedException implements RequestException {}

abstract class IsolateIsReloadingException implements RequestException {}

abstract class FileSystemAlreadyExistsException implements RequestException {}

abstract class FileSystemDoesNotExistException implements RequestException {}

abstract class FileDoesNotExistException implements RequestException {}

abstract class IsolateReloadFailedException implements RequestException {}

abstract class UnknownException implements RequestException {}
