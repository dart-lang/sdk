// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

// We need to set these properties while the sdk is only partially initialized
// so we cannot use regular Dart fields.
// The default values for these properties are set when the global_ final field
// in runtime.dart is initialized.

// Override, e.g., for testing
void trapRuntimeErrors(bool flag) {
  JS('', 'dart.__trapRuntimeErrors = #', flag);
}

void ignoreWhitelistedErrors(bool flag) {
  JS('', 'dart.__ignoreWhitelistedErrors = #', flag);
}

// TODO(jmesserly): remove this?
void ignoreAllErrors(bool flag) {
  JS('', 'dart.__ignoreAllErrors = #', flag);
}

argumentError(value) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new ArgumentError.value(value);
}

throwUnimplementedError(String message) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new UnimplementedError(message);
}

assertFailed(message) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new AssertionErrorImpl(message);
}

throwCyclicInitializationError([Object field]) {
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new CyclicInitializationError(field);
}

throwNullValueError() {
  // TODO(vsm): Per spec, we should throw an NSM here.  Technically, we ought
  // to thread through method info, but that uglifies the code and can't
  // actually be queried ... it only affects how the error is printed.
  if (JS('bool', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  throw new NoSuchMethodError(
      null, new Symbol('<Unexpected Null Value>'), null, null, null);
}

castError(obj, expectedType, [bool typeError = undefined]) {
  var actualType = getReifiedType(obj);
  var message = _castErrorMessage(actualType, expectedType);
  if (JS('!', 'dart.__ignoreAllErrors')) {
    JS('', 'console.error(#)', message);
    return obj;
  }
  if (JS('!', 'dart.__trapRuntimeErrors')) JS('', 'debugger');
  var error = JS<bool>('!', '#', typeError)
      ? new TypeErrorImpl(message)
      : new CastErrorImpl(message);
  throw error;
}

String _castErrorMessage(from, to) {
  // If both types are generic classes, see if we can infer generic type
  // arguments for `from` that would allow the subtype relation to work.
  var fromClass = getGenericClass(from);
  if (fromClass != null) {
    var fromTypeFormals = getGenericTypeFormals(fromClass);
    var fromType = instantiateClass(fromClass, fromTypeFormals);
    var inferrer = new _TypeInferrer(fromTypeFormals);
    if (inferrer.trySubtypeMatch(fromType, to)) {
      var inferredTypes = inferrer.getInferredTypes();
      if (inferredTypes != null) {
        var inferred = instantiateClass(fromClass, inferredTypes);
        return "Type '${typeName(from)}' should be '${typeName(inferred)}' "
            "to implement expected type '${typeName(to)}'.";
      }
    }
  }
  return "Type '${typeName(from)}' is not a subtype of "
      "expected type '${typeName(to)}'.";
}
