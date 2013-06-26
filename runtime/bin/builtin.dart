// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;
import 'dart:io';

// Corelib 'print' implementation.
void _print(arg) {
  _Logger._printString(arg.toString());
}


class _Logger {
  static void _printString(String s) native "Logger_PrintString";
}


_getPrintClosure() => _print;


void _logResolution(String msg) {
  final enabled = false;
  if (enabled) {
    _Logger._printString(msg);
  }
}


var _httpRequestResponseCode = 0;
var _httpRequestStatusString;
var _httpRequestResponse;

_getHttpRequestResponseCode() => _httpRequestResponseCode;
_getHttpRequestStatusString() => _httpRequestStatusString;
_getHttpRequestResponse() => _httpRequestResponse;

void _requestCompleted(HttpClientResponseBody body) {
  _httpRequestResponseCode = body.statusCode;
  _httpRequestStatusString = '${body.statusCode} ${body.reasonPhrase}';
  _httpRequestResponse = null;
  if (body.statusCode != 200 || body.type == 'json') {
    return;
  }
  _httpRequestResponse = body.body;
}


void _requestFailed(error) {
  _httpRequestResponseCode = 0;
  _httpRequestStatusString = error.toString();
  _httpRequestResponse = null;
}


void _makeHttpRequest(String uri) {
  var _client = new HttpClient();
  _httpRequestResponseCode = 0;
  _httpRequestStatusString = null;
  _httpRequestResponse = null;
  Uri requestUri = Uri.parse(uri);
  _client.getUrl(requestUri)
      .then((HttpClientRequest request) => request.close())
      .then(HttpBodyHandler.processResponse)
      .then((HttpClientResponseBody body) {
        _requestCompleted(body);
      }).catchError((error) {
        _requestFailed(error);
      });
}


// Are we running on Windows?
var _isWindows = false;
// The current working directory
var _workingDirectoryUri;
// The URI that the entry point script was loaded from. Remembered so that
// package imports can be resolved relative to it.
var _entryPointScript;
// The directory to look in to resolve "package:" scheme URIs.
var _packageRoot;


void _setWindows() {
  _isWindows = true;
}


_sanitizeWindowsPath(path) {
  // For Windows we need to massage the paths a bit according to
  // http://blogs.msdn.com/b/ie/archive/2006/12/06/file-uris-in-windows.aspx
  //
  // Convert
  // C:\one\two\three
  // to
  // /C:/one/two/three

  if (_isWindows == false) {
    // Do nothing when not running Windows.
    return path;
  }

  var fixedPath = "${path.replaceAll('\\', '/')}";

  if ((path.length > 2) && (path[1] == ':')) {
    // Path begins with a drive letter.
    return '/$fixedPath';
  }

  return fixedPath;
}

_enforceTrailingSlash(uri) {
  // Ensure we have a trailing slash character.
  if (!uri.endsWith('/')) {
    return '$uri/';
  }
  return uri;
}


void _setWorkingDirectory(cwd) {
  cwd = _sanitizeWindowsPath(cwd);
  cwd = _enforceTrailingSlash(cwd);
  _workingDirectoryUri = new Uri(scheme: 'file', path: cwd);
  _logResolution('# Working Directory: $cwd');
}


_setPackageRoot(String packageRoot) {
  packageRoot = _enforceTrailingSlash(packageRoot);
  _packageRoot = _workingDirectoryUri.resolve(packageRoot);
  _logResolution('# Package root: $packageRoot -> $_packageRoot');
}


String _resolveScriptUri(String scriptName) {
  if (_workingDirectoryUri == null) {
    throw 'No current working directory set.';
  }
  scriptName = _sanitizeWindowsPath(scriptName);

  var scriptUri = Uri.parse(scriptName);
  if (scriptUri.scheme != '') {
    // Script has a scheme, assume that it is fully formed.
    _entryPointScript = scriptUri;
  } else {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    _entryPointScript = _workingDirectoryUri.resolve(scriptName);
  }
  _logResolution('# Resolved entry point to: $_entryPointScript');
  return _entryPointScript.toString();
}


String _resolveUri(String base, String userString) {
  var baseUri = Uri.parse(base);
  _logResolution('# Resolving: $userString from $base');

  var uri = Uri.parse(userString);
  var resolved;
  if ('dart-ext' == uri.scheme) {
    // Relative URIs with scheme dart-ext should be resolved as if with no
    // scheme.
    resolved = baseUri.resolve(uri.path);
    var path = resolved.path;
    if (resolved.scheme == 'package') {
      // If we are resolving relative to a package URI we go directly to the
      // file path and keep the dart-ext scheme. Otherwise, we will lose the
      // package URI path part.
      path = _filePathFromPackageUri(resolved);
    }
    resolved = new Uri(scheme: 'dart-ext', path: path);
  } else {
    resolved = baseUri.resolve(userString);
  }
  _logResolution('# Resolved to: $resolved');
  return resolved.toString();
}


String _filePathFromUri(String userUri) {
  var uri = Uri.parse(userUri);
  _logResolution('# Getting file path from: $uri');

  var path;
  switch (uri.scheme) {
    case 'file':
      path = _filePathFromFileUri(uri);
      break;
    case 'dart-ext':
      path = _filePathFromOtherUri(uri);
      break;
    case 'package':
      path = _filePathFromPackageUri(uri);
      break;
    case 'http':
      path = _filePathFromHttpUri(uri);
      break;
    default:
      // Only handling file and package URIs in standalone binary.
      _logResolution('# Unknown scheme (${uri.scheme}) in $uri.');
      throw 'Not a known scheme: $uri';
  }

  if (_isWindows && path.startsWith('/')) {
    // For Windows we need to massage the paths a bit according to
    // http://blogs.msdn.com/b/ie/archive/2006/12/06/file-uris-in-windows.aspx
    //
    // Drop the leading / before the drive letter.
    path = path.substring(1);
    _logResolution('# Path: Removed leading / -> $path');
  }

  return path;
}


String _filePathFromFileUri(Uri uri) {
  if (!uri.host.isEmpty) {
    throw "URIs using the 'file:' scheme may not contain a host.";
  }

  _logResolution('# Path: $uri -> ${uri.path}');
  return uri.path;
}


String _filePathFromOtherUri(Uri uri) {
  if (!uri.host.isEmpty) {
    throw 'URIs whose paths are used as file paths may not contain a host.';
  }

  _logResolution('# Path: $uri -> ${uri.path}');
  return uri.path;
}


String _filePathFromPackageUri(Uri uri) {
  if (!uri.host.isEmpty) {
    var path = (uri.path != '') ? '${uri.host}${uri.path}' : uri.host;
    var right = 'package:$path';
    var wrong = 'package://$path';

    throw "URIs using the 'package:' scheme should look like "
          "'$right', not '$wrong'.";
  }

  var packageUri;
  var path;
  if (_packageRoot != null) {
    // Resolve against package root.
    packageUri = _packageRoot.resolve(uri.path);
  } else {
    // Resolve against working directory.
    packageUri = _entryPointScript.resolve('packages/${uri.path}');
  }

  if (packageUri.scheme == 'file') {
    path = packageUri.path;
  } else {
    path = packageUri.toString();
  }
  _logResolution('# Package: $uri -> $path');
  return path;
}


String _filePathFromHttpUri(Uri uri) {
  _logResolution('# Path: $uri -> $uri');
  return uri.toString();
}
