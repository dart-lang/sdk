// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generated from namespace: fileSystem

part of chrome;

/**
 * Types
 */

class FilesystemAcceptOption extends ChromeObject {
  /*
   * Public constructor
   */
  FilesystemAcceptOption(
      {String description, List<String> mimeTypes, List<String> extensions}) {
    if (description != null) this.description = description;
    if (mimeTypes != null) this.mimeTypes = mimeTypes;
    if (extensions != null) this.extensions = extensions;
  }

  /*
   * Private constructor
   */
  FilesystemAcceptOption._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// This is the optional text description for this option. If not present, a
  /// description will be automatically generated; typically containing an
  /// expanded list of valid extensions (e.g. "text/html" may expand to "*.html,
  /// *.htm").
  String get description => JS('String', '#.description', this._jsObject);

  set description(String description) {
    JS('void', '#.description = #', this._jsObject, description);
  }

  /// Mime-types to accept, e.g. "image/jpeg" or "audio/*". One of mimeTypes or
  /// extensions must contain at least one valid element.
  List<String> get mimeTypes =>
      JS('List<String>', '#.mimeTypes', this._jsObject);

  set mimeTypes(List<String> mimeTypes) {
    JS('void', '#.mimeTypes = #', this._jsObject, mimeTypes);
  }

  /// Extensions to accept, e.g. "jpg", "gif", "crx".
  List<String> get extensions =>
      JS('List<String>', '#.extensions', this._jsObject);

  set extensions(List<String> extensions) {
    JS('void', '#.extensions = #', this._jsObject, extensions);
  }
}

class FilesystemChooseEntryOptions extends ChromeObject {
  /*
   * Public constructor
   */
  FilesystemChooseEntryOptions(
      {String type,
      String suggestedName,
      List<FilesystemAcceptOption> accepts,
      bool acceptsAllTypes}) {
    if (type != null) this.type = type;
    if (suggestedName != null) this.suggestedName = suggestedName;
    if (accepts != null) this.accepts = accepts;
    if (acceptsAllTypes != null) this.acceptsAllTypes = acceptsAllTypes;
  }

  /*
   * Private constructor
   */
  FilesystemChooseEntryOptions._proxy(_jsObject) : super._proxy(_jsObject);

  /*
   * Public accessors
   */
  /// Type of the prompt to show. The default is 'openFile'.
  String get type => JS('String', '#.type', this._jsObject);

  set type(String type) {
    JS('void', '#.type = #', this._jsObject, type);
  }

  /// The suggested file name that will be presented to the user as the default
  /// name to read or write. This is optional.
  String get suggestedName => JS('String', '#.suggestedName', this._jsObject);

  set suggestedName(String suggestedName) {
    JS('void', '#.suggestedName = #', this._jsObject, suggestedName);
  }

  /// The optional list of accept options for this file opener. Each option will
  /// be presented as a unique group to the end-user.
  List<FilesystemAcceptOption> get accepts {
    List<FilesystemAcceptOption> __proxy_accepts =
        new List<FilesystemAcceptOption>();
    int count = JS('int', '#.accepts.length', this._jsObject);
    for (int i = 0; i < count; i++) {
      var item = JS('', '#.accepts[#]', this._jsObject, i);
      __proxy_accepts.add(new FilesystemAcceptOption._proxy(item));
    }
    return __proxy_accepts;
  }

  set accepts(List<FilesystemAcceptOption> accepts) {
    JS('void', '#.accepts = #', this._jsObject, convertArgument(accepts));
  }

  /// Whether to accept all file types, in addition to the options specified in
  /// the accepts argument. The default is true. If the accepts field is unset or
  /// contains no valid entries, this will always be reset to true.
  bool get acceptsAllTypes => JS('bool', '#.acceptsAllTypes', this._jsObject);

  set acceptsAllTypes(bool acceptsAllTypes) {
    JS('void', '#.acceptsAllTypes = #', this._jsObject, acceptsAllTypes);
  }
}

/**
 * Functions
 */

class API_file_system {
  /*
   * API connection
   */
  Object _jsObject;

  /*
   * Functions
   */
  /// Get the display path of a FileEntry object. The display path is based on
  /// the full path of the file on the local file system, but may be made more
  /// readable for display purposes.
  void getDisplayPath(FileEntry fileEntry, void callback(String displayPath)) =>
      JS('void', '#.getDisplayPath(#, #)', this._jsObject,
          convertArgument(fileEntry), convertDartClosureToJS(callback, 1));

  /// Get a writable FileEntry from another FileEntry. This call will fail if the
  /// application does not have the 'write' permission under 'fileSystem'.
  void getWritableEntry(
      FileEntry fileEntry, void callback(FileEntry fileEntry)) {
    void __proxy_callback(fileEntry) {
      if (callback != null) {
        callback(fileEntry);
      }
    }

    JS(
        'void',
        '#.getWritableEntry(#, #)',
        this._jsObject,
        convertArgument(fileEntry),
        convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Gets whether this FileEntry is writable or not.
  void isWritableEntry(FileEntry fileEntry, void callback(bool isWritable)) =>
      JS('void', '#.isWritableEntry(#, #)', this._jsObject,
          convertArgument(fileEntry), convertDartClosureToJS(callback, 1));

  /// Ask the user to choose a file.
  void chooseEntry(void callback(FileEntry fileEntry),
      [FilesystemChooseEntryOptions options]) {
    void __proxy_callback(fileEntry) {
      if (callback != null) {
        callback(fileEntry);
      }
    }

    JS('void', '#.chooseEntry(#, #)', this._jsObject, convertArgument(options),
        convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Returns the file entry with the given id if it can be restored. This call
  /// will fail otherwise.
  void restoreEntry(String id, void callback(FileEntry fileEntry)) {
    void __proxy_callback(fileEntry) {
      if (callback != null) {
        callback(fileEntry);
      }
    }

    JS('void', '#.restoreEntry(#, #)', this._jsObject, id,
        convertDartClosureToJS(__proxy_callback, 1));
  }

  /// Returns whether a file entry for the given id can be restored, i.e. whether
  /// restoreEntry would succeed with this id now.
  void isRestorable(String id, void callback(bool isRestorable)) => JS(
      'void',
      '#.isRestorable(#, #)',
      this._jsObject,
      id,
      convertDartClosureToJS(callback, 1));

  /// Returns an id that can be passed to restoreEntry to regain access to a
  /// given file entry. Only the 500 most recently used entries are retained,
  /// where calls to retainEntry and restoreEntry count as use. If the app has
  /// the 'retainEntries' permission under 'fileSystem', entries are retained
  /// indefinitely. Otherwise, entries are retained only while the app is running
  /// and across restarts.
  String retainEntry(FileEntry fileEntry) => JS(
      'String', '#.retainEntry(#)', this._jsObject, convertArgument(fileEntry));

  API_file_system(this._jsObject) {}
}
