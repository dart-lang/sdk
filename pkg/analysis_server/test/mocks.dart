// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mocks;

import 'package:analysis_server/src/channel.dart';

/**
 * Instances of the class [MockChannel] implement a [CommunicationChannel] that
 * does nothing in response to every method invoked on it.
 */
class MockChannel implements CommunicationChannel {
  dynamic noSuchMethod(Invocation invocation) {
    // Do nothing
    return null;
  }
}
