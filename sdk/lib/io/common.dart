// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
class OSError {
  /** Constant used to indicate that no OS error code is available. */
  static const int noErrorCode = -1;

  /** Creates an OSError object from a message and an errorCode. */
  const OSError([String this.message = "", int this.errorCode = noErrorCode]);

  /** Converts an OSError object to a string representation. */
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add("OS Error");
    if (!message.isEmpty) {
      sb.add(": ");
      sb.add(message);
      if (errorCode != noErrorCode) {
        sb.add(", errno = ");
        sb.add(errorCode.toString());
      }
    } else if (errorCode != noErrorCode) {
      sb.add(": errno = ");
      sb.add(errorCode.toString());
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
class _BufferAndOffset {
  _BufferAndOffset(List this.buffer, int this.offset);
  List buffer;
  int offset;
}

// Ensure that the input List can be serialized through a native port.
// Only builtin Lists can be serialized through. If user-defined Lists
// get here, the contents is copied to a Uint8List. This has the added
// benefit that it is faster to access from the C code as well.
_BufferAndOffset _ensureFastAndSerializableBuffer(
    List buffer, int offset, int bytes) {
  if (buffer is Uint8List ||
      buffer is Int8List ||
      _BufferUtils._isBuiltinList(buffer)) {
    return new _BufferAndOffset(buffer, offset);
  }
  var newBuffer = new Uint8List(bytes);
  int j = offset;
  for (int i = 0; i < bytes; i++) {
    int value = buffer[j];
    if (value is! int) {
      throw new ArgumentError("List element is not an integer at index $j");
    }
    newBuffer[i] = value;
    j++;
  }
  return new _BufferAndOffset(newBuffer, 0);
}


// TODO(ager): The only reason for the class here is that
// we cannot patch a top-level function.
class _BufferUtils {
  // Check if a List is a builtin VM List type. Returns true
  // if the List is a builtin VM List type and false if it is
  // a user defined List type.
  external static bool _isBuiltinList(List buffer);
}
