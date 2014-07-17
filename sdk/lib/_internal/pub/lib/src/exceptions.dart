// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.exceptions;

import 'dart:io';
import 'dart:isolate';

import "package:analyzer/analyzer.dart";
import "package:http/http.dart" as http;
import "package:stack_trace/stack_trace.dart";
import "package:yaml/yaml.dart";

import '../../asset/dart/serialize.dart';

/// An exception class for exceptions that are intended to be seen by the user.
///
/// These exceptions won't have any debugging information printed when they're
/// thrown.
class ApplicationException implements Exception {
  final String message;

  ApplicationException(this.message);

  String toString() => message;
}

/// An exception class for exceptions that are intended to be seen by the user
/// and are associated with a problem in a file at some path.
class FileException implements ApplicationException {
  final String message;

  /// The path to the file that was missing or erroneous.
  final String path;

  FileException(this.message, this.path);

  String toString() => message;
}

/// A class for exceptions that wrap other exceptions.
class WrappedException extends ApplicationException {
  /// The underlying exception that [this] is wrapping, if any.
  final innerError;

  /// The stack chain for [innerError] if it exists.
  final Chain innerChain;

  WrappedException(String message, this.innerError, [StackTrace innerTrace])
      : innerChain = innerTrace == null ? null : new Chain.forTrace(innerTrace),
        super(message);
}

/// A class for exceptions that shouldn't be printed at the top level.
///
/// This is usually used when an exception has already been printed using
/// [log.exception].
class SilentException extends WrappedException {
  SilentException(innerError, [StackTrace innerTrace])
      : super(innerError.toString(), innerError, innerTrace);
}

/// A class for command usage exceptions.
class UsageException extends ApplicationException {
  /// The command usage information.
  String _usage;

  UsageException(String message, this._usage)
      : super(message);

  String toString() => "$message\n\n$_usage";
}

/// A class for errors in a command's input data.
///
/// This corresponds to the [exit_codes.DATA] exit code.
class DataException extends ApplicationException {
  DataException(String message)
      : super(message);
}

/// An class for exceptions where a package could not be found in a [Source].
///
/// The source is responsible for wrapping its internal exceptions in this so
/// that other code in pub can use this to show a more detailed explanation of
/// why the package was being requested.
class PackageNotFoundException extends WrappedException {
  PackageNotFoundException(String message, [innerError, StackTrace innerTrace])
      : super(message, innerError, innerTrace);
}

/// All the names of user-facing exceptions.
final _userFacingExceptions = new Set<String>.from([
  'ApplicationException',
  // This refers to http.ClientException.
  'ClientException',
  // Errors coming from the Dart analyzer are probably caused by syntax errors
  // in user code, so they're user-facing.
  'AnalyzerError', 'AnalyzerErrorGroup',
  // An error spawning an isolate probably indicates a transformer with an
  // invalid import.
  'IsolateSpawnException',
  // IOException and subclasses.
  'CertificateException', 'FileSystemException', 'HandshakeException',
  'HttpException', 'IOException', 'ProcessException', 'RedirectException',
  'SignalException', 'SocketException', 'StdoutException', 'TlsException',
  'WebSocketException'
]);

/// Returns whether [error] is a user-facing error object.
///
/// This includes both [ApplicationException] and any dart:io errors.
bool isUserFacingException(error) {
  if (error is CrossIsolateException) {
    return _userFacingExceptions.contains(error.type);
  }

  // TODO(nweiz): unify this list with _userFacingExceptions when issue 5897 is
  // fixed.
  return error is ApplicationException ||
    error is AnalyzerError ||
    error is AnalyzerErrorGroup ||
    error is IsolateSpawnException ||
    error is IOException ||
    error is http.ClientException ||
    error is YamlException;
}
