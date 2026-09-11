// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library provides [MessagePort] wrapper around `web.MessagePort`.
///
/// This serves 3 purposes:
///  * (A) Exposing a nominally typed object to end-users reduces risk that
///    users pass us a `web.MessagePort` created by someone else.
///  * (B) Wrapping makes it easy to offer proxying over binary [StreamChannel],
///    this allows users to launch an iframe on a phone, and connect to the
///    dartpad-environment over a Web Socket or WebRTC channel.
///  * (C) Allows us to test the worker on VM, by testing with a binary encoded
///    [MessagePort] abstraction.
///
/// @docImport 'package:stream_channel/stream_channel.dart';
/// @docImport 'message_port_js.dart';
library;

export 'message_port_js.dart'
    if (dart.library.io) 'message_port_io.dart'
    show MessagePort, MessagePortExt;
