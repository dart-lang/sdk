// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerGlobalScope {

  WorkerLocation get location();

  void set location(WorkerLocation value);

  WorkerNavigator get navigator();

  void set navigator(WorkerNavigator value);

  WorkerContext get self();

  void set self(WorkerContext value);

  NotificationCenter get webkitNotifications();

  DOMURL get webkitURL();

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void clearInterval(int handle);

  void clearTimeout(int handle);

  void close();

  bool dispatchEvent(Event evt);

  void importScripts();

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout(TimeoutHandler handler, int timeout);

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback, ErrorCallback errorCallback]);

  DOMFileSystemSync webkitRequestFileSystemSync(int type, int size);

  EntrySync webkitResolveLocalFileSystemSyncURL(String url);

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback, ErrorCallback errorCallback]);
}

interface WorkerContext extends WorkerGlobalScope {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;
}
