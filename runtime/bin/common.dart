// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    if (!message.isEmpty()) {
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


// Check if a List is a builtin VM List type. Returns true
// if the List is a builtin VM List type and false if it is
// a user defined List type.
bool _isBuiltinList(List buffer) native "Common_IsBuiltinList";


// Ensure that the input List can be serialized through a native port.
// Only builtin Lists can be serialized through. If user-defined Lists
// get here, the contents is copied to a Uint8List. This has the added
// benefit that it is faster to access from the C code as well.
List _ensureFastAndSerializableBuffer(
    List buffer, int offset, int bytes) {
  List outBuffer;
  int outOffset = offset;
  if (buffer is Uint8List || _isBuiltinList(buffer)) {
    outBuffer = buffer;
  } else {
    outBuffer = new Uint8List(bytes);
    outOffset = 0;
    int j = offset;
    for (int i = 0; i < bytes; i++) {
      int value = buffer[j];
      if (value is! int) {
        throw new FileIOException(
            "List element is not an integer at index $j");
      }
      outBuffer[i] = value;
      j++;
    }
  }
  return [outBuffer, outOffset];
}
