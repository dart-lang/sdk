// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("builtin");

void print(arg) {
  _Logger._printString(arg.toString());
}

void exit(int status) {
  if (status is !int) {
    throw new IllegalArgumentException("int status expected");
  }
  _exit(status);
}

_exit(int status) native "Exit";

class _Logger {
  static void _printString(String s) native "Logger_PrintString";
}


// Code to deal with URI resolution for the standalone binary.
// For Windows we need to massage the paths a bit according to
// http://blogs.msdn.com/b/ie/archive/2006/12/06/file-uris-in-windows.aspx
var _is_windows;

void _logResolution(String msg) {
  final enabled = false;
  if (enabled) {
    _Logger._printString(msg);
  }
}

String _resolveScriptUri(String cwd, String scriptName, bool windows) {
  _is_windows = windows;
  _logResolution("# Current working directory: $cwd");
  _logResolution("# ScriptName: $scriptName");
  if (windows) {
    // Convert
    // C:\one\two\three
    // to
    // /C:/one/two/three
    cwd = "/${cwd.replaceAll('\\', '/')}";
    _logResolution("## cwd: $cwd");
    if ((scriptName.length > 2) && (scriptName[1] == ":")) {
      // This is an absolute path.
      scriptName = "/${scriptName.replaceAll('\\', '/')}";
    } else {
      scriptName = scriptName.replaceAll('\\', '/');
    }
    _logResolution("## scriptName: $scriptName");
  }
  var base = new Uri(scheme: "file", path: cwd.endsWith("/") ? cwd : "$cwd/");
  var resolved = base.resolve(scriptName);
  _logResolution("# Resolved to: $resolved");
  return resolved.toString();
}

String _resolveUri(String base, String userString) {
  var baseUri = new Uri.fromString(base);
  _logResolution("# Resolving: $userString from $base");
  var resolved = baseUri.resolve(userString);
  _logResolution("# Resolved to: $resolved");
  return resolved.toString();
}

String _resolveExtensionUri(String base, String userString) {
  var uri = new Uri.fromString(userString);
  if ("dart-ext" != uri.scheme) {
    throw "Not a Dart extension uri: $uri";
  }
  var schemelessUri = new Uri(path: uri.path);
  var baseUri = new Uri.fromString(base);
  _logResolution("# Resolving: $userString from $base");
  var resolved = baseUri.resolveUri(schemelessUri);
  resolved = new Uri(scheme: 'dart-ext', path: resolved.path);
  _logResolution("# Resolved to: $resolved");
  return resolved.toString();
}

String _filePathFromUri(String userUri) {
  var uri = new Uri.fromString(userUri);
  _logResolution("# Getting file path from: $uri");
  if ("file" != uri.scheme) {
    // Only handling file URIs in standalone binary.
    _logResolution("# Not a file URI.");
    throw "Not a file uri: $uri";
  }
  var path = uri.path;
  _logResolution("# Path: $path");
  if (_is_windows) {
    // Drop the leading / before the drive letter.
    path = path.substring(1);
    _logResolution("# path: $path");
  }
  return path;
}
