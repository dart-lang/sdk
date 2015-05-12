// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math";
import "dart:typed_data";

// Equivalent of calling FATAL from C++ code.
_fatal(msg) native "DartCore_fatal";

// We need to pass the exception and stack trace objects as second and third
// parameter to the continuation.  See vm/ast_transformer.cc for usage.
void  _asyncCatchHelper(catchFunction, continuation) {
  catchFunction((e, s) => continuation(null, e, s));
}

// The members of this class are cloned and added to each class that
// represents an enum type.
class _EnumHelper {
  // Declare the list of enum value names private. When this field is
  // cloned into a user-defined enum class, the field will be inaccessible
  // because of the library-specific name suffix. The toString() function
  // below can access it because it uses the same name suffix.
  static const List<String> _enum_names = null;
  String toString() => _enum_names[index];
  int get hashCode => _enum_names[index].hashCode;
}


// _AsyncStarStreamController is used by the compiler to implement
// async* generator functions.
class _AsyncStarStreamController {
  StreamController controller;
  Function asyncStarBody;
  bool isAdding = false;
  bool onListenReceived = false;
  bool isScheduled = false;
  bool isSuspendedAtYield = false;
  Completer cancellationCompleter = null;

  Stream get stream => controller.stream;

  void runBody() {
    isScheduled = false;
    isSuspendedAtYield = false;
    asyncStarBody();
  }

  void scheduleGenerator() {
    if (isScheduled || controller.isPaused || isAdding) {
      return;
    }
    isScheduled = true;
    scheduleMicrotask(runBody);
  }

  // Adds element to steam, returns true if the caller should terminate
  // execution of the generator.
  //
  // TODO(hausner): Per spec, the generator should be suspended before
  // exiting when the stream is closed. We could add a getter like this:
  // get isCancelled => controller.hasListener;
  // The generator would translate a 'yield e' statement to
  // controller.add(e);
  // suspend;
  // if (controller.isCancelled) return;
  bool add(event) {
    if (!onListenReceived) _fatal("yield before stream is listened to!");
    if (isSuspendedAtYield) _fatal("unexpected yield");
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) {
      return true;
    }
    controller.add(event);
    scheduleGenerator();
    isSuspendedAtYield = true;
    return false;
  }

  // Adds the elements of stream into this controller's stream.
  // The generator will be scheduled again when all of the
  // elements of the added stream have been consumed.
  // Returns true if the caller should terminate
  // execution of the generator.
  bool addStream(Stream stream) {
    if (!onListenReceived) _fatal("yield before stream is listened to!");
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) return true;
    isAdding = true;
    var whenDoneAdding =
        controller.addStream(stream as Stream, cancelOnError: false);
    whenDoneAdding.then((_) {
      isAdding = false;
      scheduleGenerator();
    });
    return false;
  }

  void addError(error, stackTrace) {
    if ((cancellationCompleter != null) && !cancellationCompleter.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      cancellationCompleter.completeError(error, stackTrace);
      return;
    }
    // If stream is cancelled, tell caller to exit the async generator.
    if (!controller.hasListener) return;
    controller.addError(error, stackTrace);
    // No need to schedule the generator body here. This code is only
    // called from the catch clause of the implicit try-catch-finally
    // around the generator body. That is, we are on the error path out
    // of the generator and do not need to run the generator again.
  }

  close() {
    if ((cancellationCompleter != null) && !cancellationCompleter.isCompleted) {
      // If the stream has been cancelled, complete the cancellation future
      // with the error.
      cancellationCompleter.complete();
    }
    controller.close();
  }

  _AsyncStarStreamController(this.asyncStarBody) {
    controller = new StreamController(onListen: this.onListen,
                                      onResume: this.onResume,
                                      onCancel: this.onCancel);
  }

  onListen() {
    assert(!onListenReceived);
    onListenReceived = true;
    scheduleGenerator();
  }

  onResume() {
    if (isSuspendedAtYield) {
      scheduleGenerator();
    }
  }

  onCancel() {
    if (controller.isClosed) {
      return null;
    }
    if (cancellationCompleter == null) {
      cancellationCompleter = new Completer();
      scheduleGenerator();
    }
    return cancellationCompleter.future;
  }
}


// _SyncIterable and _syncIterator are used by the compiler to
// implement sync* generator functions. A sync* generator allocates
// and returns a new _SyncIterable object.

typedef bool SyncGeneratorCallback(Iterator iterator);

class _SyncIterable extends IterableBase {
  // moveNextFn is the closurized body of the generator function.
  final SyncGeneratorCallback moveNextFn;

  const _SyncIterable(this.moveNextFn);

  get iterator {
    return new _SyncIterator(moveNextFn._clone());
  }
}

class _SyncIterator implements Iterator {
  bool isYieldEach;  // Set by generated code for the yield* statement.
  Iterator yieldEachIterator;
  var current;  // Set by generated code for the yield and yield* statement.
  SyncGeneratorCallback moveNextFn;

  _SyncIterator(this.moveNextFn);

  bool moveNext() {
    if (moveNextFn == null) {
      return false;
    }
    while(true) {
      if (yieldEachIterator != null) {
        if (yieldEachIterator.moveNext()) {
          current = yieldEachIterator.current;
          return true;
        }
        yieldEachIterator = null;
      }
      isYieldEach = false;
      if (!moveNextFn(this)) {
        moveNextFn = null;
        current = null;
        return false;
      }
      if (isYieldEach) {
        // Spec mandates: it is a dynamic error if the class of [the object
        // returned by yield*] does not implement Iterable.
        yieldEachIterator = (current as Iterable).iterator;
        continue;
      }
      return true;
    }
  }
}
