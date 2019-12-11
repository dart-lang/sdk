// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void RecognizerCallback<T>();
typedef void GestureTapCancelCallback();
GestureTapCancelCallback onTapCancel;
T invokeCallback<T>(String name, RecognizerCallback<T> callback,
    {String debugReport()}) {}
main() {
  invokeCallback<void>('spontaneous onTapCancel', onTapCancel);
}
