// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// ignore: import_internal_library, unused_import
import 'dart:_internal';
import 'dart:async';

/// A user-defined class of which objects can be identified with a field value.
class Nonce {
  final int value;

  Nonce(this.value);

  String toString() => 'Nonce($value)';
}

/// Never inline to ensure `value` becomes unreachable.
@pragma('vm:never-inline')
void makeObjectWithFinalizer<T>(Finalizer<T> finalizer, T token,
    {Object detach}) {
  final value = Nonce(1);
  finalizer.attach(value, token, detach: detach);
}

/// Triggers garbage collection.
// Defined in `dart:_internal`.
// ignore: undefined_identifier
void triggerGc() => VMInternalsForTesting.collectAllGarbage();

void Function(String) _namedPrint(String name) {
  if (name != null) {
    return (String value) => print('$name: $value');
  }
  return (String value) => print(value);
}

/// Does a GC and if [doAwait] awaits a future to enable running finalizers.
///
/// Also prints for debug purposes.
///
/// If provided, [name] prefixes the debug prints.
void doGC({String name}) {
  final _print = _namedPrint(name);

  _print('Do GC.');
  triggerGc();
  _print('GC done');
}

Future<void> yieldToMessageLoop({String name}) async {
  await Future.delayed(Duration(milliseconds: 1));
  _namedPrint(name)('Await done.');
  return null;
}

// Uses [object] to guarantee it is reachable.
@pragma('vm:never-inline')
void reachabilityFence(Object object) {
  // Make sure [object] parameter is used and not tree shaken.
  object.toString();
}
