// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface FileWriter {

  static final int DONE = 2;

  static final int INIT = 0;

  static final int WRITING = 1;

  FileError get error();

  int get length();

  EventListener get onabort();

  void set onabort(EventListener value);

  EventListener get onerror();

  void set onerror(EventListener value);

  EventListener get onprogress();

  void set onprogress(EventListener value);

  EventListener get onwrite();

  void set onwrite(EventListener value);

  EventListener get onwriteend();

  void set onwriteend(EventListener value);

  EventListener get onwritestart();

  void set onwritestart(EventListener value);

  int get position();

  int get readyState();

  void abort();

  void seek(int position);

  void truncate(int size);

  void write(Blob data);
}
