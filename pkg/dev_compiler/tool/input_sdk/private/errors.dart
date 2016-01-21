// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart._runtime;

throwCastError(actual, type) => JS('', '''(() => {
  $throw_(new $CastErrorImplementation($actual, $type));
})()''');

throwAssertionError() => JS('', '''(() => {
  $throw_(new $AssertionError());
})()''');

throwNullValueError() => JS('', '''(() => {
  // TODO(vsm): Per spec, we should throw an NSM here.  Technically, we ought
  // to thread through method info, but that uglifies the code and can't
  // actually be queried ... it only affects how the error is printed.
  $throw_(new $NoSuchMethodError(null,
      new $Symbol('<Unexpected Null Value>'), null, null, null));
})()''');
