// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.responder;

import 'action.dart';

/**
 * The behavior of a method call in the mock library is specified
 * with [Responder]s. A [Responder] has a [value] to throw
 * or return (depending on the type of [action]),
 * and can either be one-shot, multi-shot, or infinitely repeating,
 * depending on the value of [count (1, greater than 1, or 0 respectively).
 */
class Responder {
  final Object value;
  final Action action;
  int count;
  Responder(this.value, [this.count = 1, this.action = Action.RETURN]);
}
