// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FileReaderWrappingImplementation extends DOMWrapperBase implements FileReader {
  FileReaderWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FileError get error() { return LevelDom.wrapFileError(_ptr.error); }

  EventListener get onabort() { return LevelDom.wrapEventListener(_ptr.onabort); }

  void set onabort(EventListener value) { _ptr.onabort = LevelDom.unwrap(value); }

  EventListener get onerror() { return LevelDom.wrapEventListener(_ptr.onerror); }

  void set onerror(EventListener value) { _ptr.onerror = LevelDom.unwrap(value); }

  EventListener get onload() { return LevelDom.wrapEventListener(_ptr.onload); }

  void set onload(EventListener value) { _ptr.onload = LevelDom.unwrap(value); }

  EventListener get onloadend() { return LevelDom.wrapEventListener(_ptr.onloadend); }

  void set onloadend(EventListener value) { _ptr.onloadend = LevelDom.unwrap(value); }

  EventListener get onloadstart() { return LevelDom.wrapEventListener(_ptr.onloadstart); }

  void set onloadstart(EventListener value) { _ptr.onloadstart = LevelDom.unwrap(value); }

  EventListener get onprogress() { return LevelDom.wrapEventListener(_ptr.onprogress); }

  void set onprogress(EventListener value) { _ptr.onprogress = LevelDom.unwrap(value); }

  int get readyState() { return _ptr.readyState; }

  String get result() { return _ptr.result; }

  void abort() {
    _ptr.abort();
    return;
  }

  void readAsArrayBuffer(Blob blob) {
    _ptr.readAsArrayBuffer(LevelDom.unwrap(blob));
    return;
  }

  void readAsBinaryString(Blob blob) {
    _ptr.readAsBinaryString(LevelDom.unwrap(blob));
    return;
  }

  void readAsDataURL(Blob blob) {
    _ptr.readAsDataURL(LevelDom.unwrap(blob));
    return;
  }

  void readAsText(Blob blob, String encoding) {
    _ptr.readAsText(LevelDom.unwrap(blob), encoding);
    return;
  }

  String get typeName() { return "FileReader"; }
}
