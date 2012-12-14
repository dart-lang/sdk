// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _foreign_helper;

dynamic JS(String typeDescription, String code,
    [var arg0, var arg1, var arg2]) {}

/**
 * Invokes a method without the compiler trying to intercept it.
 */
dynamic UNINTERCEPTED(var expression) {}

/**
 * Returns [:true:] if [object] has its own operator== definition.
 */
bool JS_HAS_EQUALS(var object) {}

/**
 * Returns the isolate in which this code is running.
 */
dynamic JS_CURRENT_ISOLATE() {}

/**
 * Invokes [function] in the context of [isolate].
 */
dynamic JS_CALL_IN_ISOLATE(var isolate, Function function) {}

/**
 * Converts the Dart closure [function] into a JavaScript closure.
 */
dynamic DART_CLOSURE_TO_JS(Function function) {}

/**
 * Sets the current isolate to [isolate].
 */
void JS_SET_CURRENT_ISOLATE(var isolate) {}

/**
 * Creates an isolate and returns it.
 */
dynamic JS_CREATE_ISOLATE() {}
