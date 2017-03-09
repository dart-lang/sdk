// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

bool _trapRuntimeErrors = true;
bool _ignoreWhitelistedErrors = true;

// Override, e.g., for testing
void trapRuntimeErrors(bool flag) {
  _trapRuntimeErrors = flag;
}

void ignoreWhitelistedErrors(bool flag) {
  _ignoreWhitelistedErrors = flag;
}

throwCastError(object, actual, type) => JS('', '''(() => {
  var found = $typeName($actual);
  var expected = $typeName($type);
  if ($_trapRuntimeErrors) debugger;
  $throw_(new $CastErrorImplementation($object, found, expected));
})()''');

throwTypeError(object, actual, type) => JS('', '''(() => {
  var found = $typeName($actual);
  var expected = $typeName($type);
  if ($_trapRuntimeErrors) debugger;
  $throw_(new $TypeErrorImplementation($object, found, expected));
})()''');

throwStrongModeCastError(object, actual, type) => JS('', '''(() => {
  var found = $typeName($actual);
  var expected = $typeName($type);
  if ($_trapRuntimeErrors) debugger;
  $throw_(new $StrongModeCastError($object, found, expected));
})()''');

throwStrongModeTypeError(object, actual, type) => JS('', '''(() => {
  var found = $typeName($actual);
  var expected = $typeName($type);
  if ($_trapRuntimeErrors) debugger;
  $throw_(new $StrongModeTypeError($object, found, expected));
})()''');

throwUnimplementedError(message) => JS('', '''(() => {
  if ($_trapRuntimeErrors) debugger;
  $throw_(new $UnimplementedError($message));
})()''');

throwAssertionError([message]) => JS('', '''(() => {
  if ($_trapRuntimeErrors) debugger;
  let error = $message != null
        ? new $AssertionErrorWithMessage($message())
        : new $AssertionError();
  $throw_(error);
})()''');

throwNullValueError() => JS('', '''(() => {
  // TODO(vsm): Per spec, we should throw an NSM here.  Technically, we ought
  // to thread through method info, but that uglifies the code and can't
  // actually be queried ... it only affects how the error is printed.
  if ($_trapRuntimeErrors) debugger;
  $throw_(new $NoSuchMethodError(null,
      new $Symbol('<Unexpected Null Value>'), null, null, null));
})()''');
