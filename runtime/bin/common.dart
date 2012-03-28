// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
  * An [OSError] object holds information about an error from the
  * operating system.
  */
class OSError {
  static final int noErrorCode = -1;

  const OSError([String this.message = "", int this.errorCode = noErrorCode]);

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


// TODO(sgjesse): Remove this once Dart constructors can be invoked
// through the API.
OSError _makeOSError(message, code) => new OSError(message, code);
