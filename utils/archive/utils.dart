// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("utils");

#import("dart-ext:dart_archive");
#import("dart:isolate");
#import("archive.dart", prefix: "archive");

/** The cache of the port used to communicate with the C extension. */
SendPort _port;

/** The port used to communicate with the C extension. */
SendPort get servicePort {
  if (_port == null) _port = _newServicePort();
  return _port;
}

/** Creates a new port to communicate with the C extension. */
SendPort _newServicePort() native "Archive_ServicePort";

/**
 * Send a message to the C extension.
 *
 * [requestType] is the specific request id to send. [id] is the id of the
 * archive; it may be null for requests that don't operate on a specific
 * archive. [args] are arguments that will be passed on to the extension. They
 * should all be C-safe.
 *
 * Returns a future that completes with the C extension's reply.
 */
Future call(int requestType, [int id, List args]) {
  var fullArgs = [requestType, id];
  if (args != null) fullArgs.addAll(args);
  return servicePort.call(listForC(fullArgs)).transform((response) {
    var success = response[0];
    var errno = response[1];
    var message = response[2];

    if (!success) throw new ArchiveException(message, errno);
    return message;
  });
}

/** Converts [input] to a fixed-length list which C can understand. */
List listForC(List input) {
  var list = new List(input.length);
  list.setRange(0, input.length, input);
  return list;
}

/** Converts [input] to a [Uint8List] that C can process easily. */
Uint8List bytesForC(List<int> input) {
  var list = new Uint8List(input.length);
  list.setRange(0, input.length, input);
  return list;
}

/**
 * Attaches [callback] as a finalizer for [object]. After [object] has been
 * garbage collected, [callback] will be called and passed [peer] as an
 * argument.
 *
 * Neither [callback] nor [peer] should contain any references to [object];
 * otherwise, [object] will never be collected and [callback] will never be
 * called.
 */
void attachFinalizer(object, void callback(peer), [peer]) {}

// TODO(nweiz): re-enable this once issue 4378 is fixed.
// void attachFinalizer(object, void callback(peer), [peer])
//     native "Archive_AttachFinalizer";

/**
 * A reference to a single value.
 *
 * This is primarily meant to be used when a finalizer needs to refer to a field
 * on the object being finalized that may be set to null during the lifetime of
 * the object. Since the object itself has been garbage collected once the
 * finalizer runs, it needs a second-order reference to check if the field is
 * null.
 */
class Reference<E> {
  E value;
  Reference(this.value);
}

/**
 * Returns a [Future] that completes immediately upon hitting the event loop.
 */
Future async() {
  var completer = new Completer();
  new Timer(0, (_) => completer.complete(null));
  return completer.future;
}

/** An error raised by the archive library. */
class ArchiveException implements archive.ArchiveException {
  /** A description of the error that occurred. */   
  final String message;

  /** The error code for the error, or null. */
  final int errno;

  ArchiveException(this.message, [this.errno]);

  String toString() {
    if (errno == null) return "Archive error: $message";
    return "Archive error $errno: $message";
  }
}
