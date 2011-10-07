// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileWriterWrappingImplementation extends DOMWrapperBase implements FileWriter {
  FileWriterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  int get length() { return _ptr.length; }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onprogress() { return LevelDom.wrapEventListener(_ptr.onprogress); }

  void set onprogress(EventListener value) { _ptr.onprogress = LevelDom.unwrap(value); }

  EventListener get onwrite() { return LevelDom.wrapEventListener(_ptr.onwrite); }

  void set onwrite(EventListener value) { _ptr.onwrite = LevelDom.unwrap(value); }

  EventListener get onwriteend() { return LevelDom.wrapEventListener(_ptr.onwriteend); }

  void set onwriteend(EventListener value) { _ptr.onwriteend = LevelDom.unwrap(value); }

  EventListener get onwritestart() { return LevelDom.wrapEventListener(_ptr.onwritestart); }

  void set onwritestart(EventListener value) { _ptr.onwritestart = LevelDom.unwrap(value); }

  int get position() { return _ptr.position; }

  int get readyState() { return _ptr.readyState; }

  void abort() {
    _ptr.abort();
    return;
  }

  void seek(int position) {
    _ptr.seek(position);
    return;
  }

  void truncate(int size) {
    _ptr.truncate(size);
    return;
  }

  void write(Blob data) {
    _ptr.write(LevelDom.unwrap(data));
    return;
  }
}
