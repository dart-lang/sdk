// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// Constants used when working with native ports.
// These must match the constants in runtime/bin/dartutils.h class CObject.
const int _SUCCESS_RESPONSE = 0;
const int _ILLEGAL_ARGUMENT_RESPONSE = 1;
const int _OSERROR_RESPONSE = 2;
const int _FILE_CLOSED_RESPONSE = 3;

const int _ERROR_RESPONSE_ERROR_TYPE = 0;
const int _OSERROR_RESPONSE_ERROR_CODE = 1;
const int _OSERROR_RESPONSE_MESSAGE = 2;

// Functions used to receive exceptions from native ports.
bool _isErrorResponse(response) =>
    response is List && response[0] != _SUCCESS_RESPONSE;

/**
 * Returns an Exception or an Error
 */
_exceptionFromResponse(response, String message, String path) {
  assert(_isErrorResponse(response));
  switch (response[_ERROR_RESPONSE_ERROR_TYPE]) {
    case _ILLEGAL_ARGUMENT_RESPONSE:
      return new ArgumentError("$message: $path");
    case _OSERROR_RESPONSE:
      var err = new OSError(response[_OSERROR_RESPONSE_MESSAGE],
          response[_OSERROR_RESPONSE_ERROR_CODE]);
      return new FileSystemException(message, path, err);
    case _FILE_CLOSED_RESPONSE:
      return new FileSystemException("File closed", path);
    default:
      return new Exception("Unknown error");
  }
}

/**
 * Base class for all IO related exceptions.
 */
abstract class IOException implements Exception {
  String toString() => "IOException";
}

/**
  * An [OSError] object holds information about an error from the
  * operating system.
  */
class OSError {
  /** Constant used to indicate that no OS error code is available. */
  static const int noErrorCode = -1;

  /**
    * Error message supplied by the operating system. null if no message is
    * associated with the error.
    */
  final String message;

  /**
    * Error code supplied by the operating system. Will have the value
    * [noErrorCode] if there is no error code associated with the error.
    */
  final int errorCode;

  /** Creates an OSError object from a message and an errorCode. */
  const OSError([this.message = "", this.errorCode = noErrorCode]);

  /** Converts an OSError object to a string representation. */
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("OS Error");
    if (!message.isEmpty) {
      sb..write(": ")..write(message);
      if (errorCode != noErrorCode) {
        sb..write(", errno = ")..write(errorCode.toString());
      }
    } else if (errorCode != noErrorCode) {
      sb..write(": errno = ")..write(errorCode.toString());
    }
    return sb.toString();
  }
}

// Object for holding a buffer and an offset.
class _BufferAndStart {
  List<int> buffer;
  int start;
  _BufferAndStart(this.buffer, this.start);
}

// Ensure that the input List can be serialized through a native port.
// Only Int8List and Uint8List Lists are serialized directly.
// All other lists are first copied into a Uint8List. This has the added
// benefit that it is faster to access from the C code as well.
_BufferAndStart _ensureFastAndSerializableByteData(
    List<int> buffer, int start, int end) {
  if (buffer is Uint8List || buffer is Int8List) {
    return new _BufferAndStart(buffer, start);
  }
  int length = end - start;
  var newBuffer = new Uint8List(length);
  int j = start;
  for (int i = 0; i < length; i++) {
    int value = buffer[j];
    if (value is! int) {
      throw new ArgumentError("List element is not an integer at index $j");
    }
    newBuffer[i] = value;
    j++;
  }
  return new _BufferAndStart(newBuffer, 0);
}

class _IOCrypto {
  external static Uint8List getRandomBytes(int count);
}
