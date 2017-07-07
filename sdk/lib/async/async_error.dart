// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "async.dart";

_invokeErrorHandler(
    Function errorHandler, Object error, StackTrace stackTrace) {
  if (errorHandler is ZoneBinaryCallback<dynamic, Null, Null>) {
    return (errorHandler as dynamic)(error, stackTrace);
  } else {
    ZoneUnaryCallback unaryErrorHandler = errorHandler;
    return unaryErrorHandler(error);
  }
}

Function _registerErrorHandler<R>(Function errorHandler, Zone zone) {
  if (errorHandler is ZoneBinaryCallback<dynamic, Null, Null>) {
    return zone.registerBinaryCallback<R, Object, StackTrace>(
        errorHandler as dynamic/*=ZoneBinaryCallback<R, Object, StackTrace>*/);
  } else {
    return zone.registerUnaryCallback<R, Object>(
        errorHandler as dynamic/*=ZoneUnaryCallback<R, Object>*/);
  }
}
