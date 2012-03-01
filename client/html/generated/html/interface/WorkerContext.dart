// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface WorkerContext {

  static final int PERSISTENT = 1;

  static final int TEMPORARY = 0;

  final WorkerLocation location;

  final WorkerNavigator navigator;

  EventListener onerror;

  final WorkerContext self;

  final IDBFactory webkitIndexedDB;

  final NotificationCenter webkitNotifications;

  void addEventListener(String type, EventListener listener, [bool useCapture]);

  void clearInterval(int handle);

  void clearTimeout(int handle);

  void close();

  bool dispatchEvent(Event evt);

  void importScripts();

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback]);

  void removeEventListener(String type, EventListener listener, [bool useCapture]);

  int setInterval(TimeoutHandler handler, int timeout);

  int setTimeout(TimeoutHandler handler, int timeout);

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback, ErrorCallback errorCallback]);

  DOMFileSystemSync webkitRequestFileSystemSync(int type, int size);

  EntrySync webkitResolveLocalFileSystemSyncURL(String url);

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback, ErrorCallback errorCallback]);
}
