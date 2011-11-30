// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntrySyncWrappingImplementation extends DOMWrapperBase implements EntrySync {
  _EntrySyncWrappingImplementation() : super() {}

  static create__EntrySyncWrappingImplementation() native {
    return new _EntrySyncWrappingImplementation();
  }

  DOMFileSystemSync get filesystem() { return _get_filesystem(this); }
  static DOMFileSystemSync _get_filesystem(var _this) native;

  String get fullPath() { return _get_fullPath(this); }
  static String _get_fullPath(var _this) native;

  bool get isDirectory() { return _get_isDirectory(this); }
  static bool _get_isDirectory(var _this) native;

  bool get isFile() { return _get_isFile(this); }
  static bool _get_isFile(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  EntrySync copyTo(DirectoryEntrySync parent, String name) {
    return _copyTo(this, parent, name);
  }
  static EntrySync _copyTo(receiver, parent, name) native;

  Metadata getMetadata() {
    return _getMetadata(this);
  }
  static Metadata _getMetadata(receiver) native;

  DirectoryEntrySync getParent() {
    return _getParent(this);
  }
  static DirectoryEntrySync _getParent(receiver) native;

  EntrySync moveTo(DirectoryEntrySync parent, String name) {
    return _moveTo(this, parent, name);
  }
  static EntrySync _moveTo(receiver, parent, name) native;

  void remove() {
    _remove(this);
    return;
  }
  static void _remove(receiver) native;

  String toURL() {
    return _toURL(this);
  }
  static String _toURL(receiver) native;

  String get typeName() { return "EntrySync"; }
}
