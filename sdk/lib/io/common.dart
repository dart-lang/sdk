// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// Constants used when working with native ports.
const int _SUCCESS_RESPONSE = 0;
const int _ILLEGAL_ARGUMENT_RESPONSE = 1;
const int _OSERROR_RESPONSE = 2;
const int _FILE_CLOSED_RESPONSE = 3;

const int _ERROR_RESPONSE_ERROR_TYPE = 0;
const int _OSERROR_RESPONSE_ERROR_CODE = 1;
const int _OSERROR_RESPONSE_MESSAGE = 2;

/**
  * An [OSError] object holds information about an error from the
  * operating system.
  */
class OSError implements Error {
  /** Constant used to indicate that no OS error code is available. */
  static const int noErrorCode = -1;

  /** Creates an OSError object from a message and an errorCode. */
  const OSError([String this.message = "", int this.errorCode = noErrorCode]);

  /** Converts an OSError object to a string representation. */
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("OS Error");
    if (!message.isEmpty) {
      sb.write(": ");
      sb.write(message);
      if (errorCode != noErrorCode) {
        sb.write(", errno = ");
        sb.write(errorCode.toString());
      }
    } else if (errorCode != noErrorCode) {
      sb.write(": errno = ");
      sb.write(errorCode.toString());
    }
    return sb.toString();
  }

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
}


// Object for holding a buffer and an offset.
class _BufferAndStart {
  _BufferAndStart(List this.buffer, int this.start);
  List buffer;
  int start;
}

// Ensure that the input List can be serialized through a native port.
// Only builtin Lists can be serialized through. If user-defined Lists
// get here, the contents is copied to a Uint8List. This has the added
// benefit that it is faster to access from the C code as well.
_BufferAndStart _ensureFastAndSerializableBuffer(
    List buffer, int start, int end) {
  if (buffer is Uint8List ||
      buffer is Int8List ||
      buffer is Uint16List ||
      buffer is Int16List ||
      buffer is Uint32List ||
      buffer is Int32List ||
      buffer is Uint64List ||
      buffer is Int64List ||
      buffer is ByteData ||
      buffer is Float32List ||
      buffer is Float64List ||
      _BufferUtils._isBuiltinList(buffer)) {
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


// TODO(ager): The only reason for the class here is that
// we cannot patch a top-level function.
class _BufferUtils {
  // Check if a List is a builtin VM List type. Returns true
  // if the List is a builtin VM List type and false if it is
  // a user defined List type.
  external static bool _isBuiltinList(List buffer);
}

class _IOCrypto {
  external static Uint8List getRandomBytes(int count);
}
