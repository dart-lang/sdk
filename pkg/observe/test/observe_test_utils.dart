// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.test.observe_test_utils;

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // to make tests smaller
import 'package:unittest/unittest.dart';
export 'package:observe/src/dirty_check.dart' show dirtyCheckZone;

/// A small method to help readability. Used to cause the next "then" in a chain
/// to happen in the next microtask:
///
///     future.then(newMicrotask).then(...)
newMicrotask(_) => new Future.value();

// TODO(jmesserly): use matchers when we have a way to compare ChangeRecords.
// For now just use the toString.
expectChanges(actual, expected, {reason}) =>
    expect('$actual', '$expected', reason: reason);

List getListChangeRecords(List changes, int index) => changes
    .where((c) => c.indexChanged(index)).toList();

List getPropertyChangeRecords(List changes, Symbol property) => changes
    .where((c) => c is PropertyChangeRecord && c.name == property).toList();
