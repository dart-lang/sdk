// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('file_system_dom');

#import('dart:dom_deprecated');
#import('file_system.dart');

/**
 * [FileSystem] implementation using XHRs for reading files and an in memory
 * cache for writing them.
 */
class DomFileSystem implements FileSystem {
  Map<String, String> _fileCache;
  String _path;

  DomFileSystem([this._path = null]) : _fileCache = {};

  // TODO(vsm): Move this to FileSystem.
  String absPath(String filename) {
    if (_path != null && !filename.startsWith('/')
        && !filename.startsWith('file:///') && !filename.startsWith('http://')
        && !filename.startsWith('dart:')) {
      filename = joinPaths(_path, filename);
    }
    return filename;
  }

  String readAll(String filename) {
    filename = absPath(filename);
    var result = _fileCache[filename];
    if (result == null) {
      final xhr = new XMLHttpRequest();
      // TODO(jimhug): Fix API so we can get multiple files at once.
      // Use a sychronous XHR to match the current API.
      xhr.open('GET', filename, false);
      try {
        xhr.send(null);
      } catch (var e) {
        // TODO(vsm): This XHR appears to fail if the URL is a
        // directory.  Return something to make fileExists work.
        // Handle this better.
        return "_directory($filename)_";
      }

      if (xhr.status == 0 || xhr.status == 200) {
        result = xhr.responseText;
        if (result.isEmpty()) {
          // TODO(vsm): Figure out why a non-existent file is not giving
          // an error code.
          print('Error: $filename is not found or empty');
          return null;
        }
      } else {
        // TODO(jimhug): Better error handling.
        print("Error: ${xhr.statusText}");
      }
      _fileCache[filename] = result;
    }
    return result;
  }

  void writeString(String outfile, String text) {
    outfile = absPath(outfile);
    _fileCache[outfile] = text;
  }

  // Note: this is not a perf nightmare only because of caching.
  bool fileExists(String filename) => readAll(filename) != null;

  void createDirectory(String path, [bool recursive = false]) {
    // TODO(rnystrom): Implement.
    throw 'createDirectory() is not implemented by DomFileSystem yet.';
  }

  void removeDirectory(String path, [bool recursive = false]) {
    // TODO(rnystrom): Implement.
    throw 'removeDirectory() is not implemented by DomFileSystem yet.';
  }
}
