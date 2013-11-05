// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;
import 'dart:io';
// import 'root_library'; happens here from C Code

// The root library (aka the script) is imported into this library. The
// standalone embedder uses this to lookup the main entrypoint in the
// root library's namespace.
Function _getMainClosure() => main;


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


// Corelib 'Uri.base' implementation.
Uri _uriBase() {
  return new Uri.file(Directory.current.path + "/");
}

_getUriBaseClosure() => _uriBase;


var _httpRequestResponseCode = 0;
var _httpRequestStatusString;
var _httpRequestResponse;

_getHttpRequestResponseCode() => _httpRequestResponseCode;
_getHttpRequestStatusString() => _httpRequestStatusString;
_getHttpRequestResponse() => _httpRequestResponse;

void _requestCompleted(List<int> data, HttpClientResponse response) {
  _httpRequestResponseCode = response.statusCode;
  _httpRequestStatusString = '${response.statusCode} ${response.reasonPhrase}';
  _httpRequestResponse = null;
  if (response.statusCode != 200 ||
      (response.headers.contentType != null &&
       response.headers.contentType.mimeType == 'application/json')) {
    return;
  }
  _httpRequestResponse = data;
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
      .then((HttpClientResponse response) {
        return response
            .fold(new BytesBuilder(), (b, d) => b..add(d))
            .then((builder) {
              _requestCompleted(builder.takeBytes(), response);
            });
      }).catchError((error) {
        _requestFailed(error);
      });
}


// Are we running on Windows?
var _isWindows = false;
var _workingWindowsDrivePrefix;
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


_extractDriveLetterPrefix(cwd) {
  if (!_isWindows) {
    return null;
  }
  if (cwd.length > 1 && cwd[1] == ':') {
    return '/${cwd[0]}:';
  }
  return null;
}


void _setWorkingDirectory(cwd) {
  _workingWindowsDrivePrefix = _extractDriveLetterPrefix(cwd);
  cwd = _sanitizeWindowsPath(cwd);
  cwd = _enforceTrailingSlash(cwd);
  _workingDirectoryUri = new Uri(scheme: 'file', path: cwd);
  _logResolution('# Working Directory: $cwd');
}


_setPackageRoot(String packageRoot) {
  packageRoot = _enforceTrailingSlash(packageRoot);
  if (packageRoot.startsWith('file:') ||
      packageRoot.startsWith('http:') ||
      packageRoot.startsWith('https:')) {
    _packageRoot = _workingDirectoryUri.resolve(packageRoot);
  } else {
    _packageRoot = _workingDirectoryUri.resolveUri(new Uri.file(packageRoot));
  }
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


// Returns either a file path or a URI starting with http:, as a String.
String _filePathFromUri(String userUri) {
  var uri = Uri.parse(userUri);
  _logResolution('# Getting file path from: $uri');

  var path;
  switch (uri.scheme) {
    case '':
    case 'file':
      return uri.toFilePath();
      break;
    case 'dart-ext':
      return new Uri(scheme: 'file',
                     host: uri.host,
                     path: uri.path).toFilePath();
      break;
    case 'package':
      return _filePathFromPackageUri(uri);
      break;
    case 'http':
      return uri.toString();
    default:
      // Only handling file, dart-ext, http, and package URIs
      // in standalone binary.
      _logResolution('# Unknown scheme (${uri.scheme}) in $uri.');
      throw 'Not a known scheme: $uri';
  }
}


String _filePathFromPackageUri(Uri uri) {
  if (!uri.host.isEmpty) {
    var path = (uri.path != '') ? '${uri.host}${uri.path}' : uri.host;
    var right = 'package:$path';
    var wrong = 'package://$path';

    throw "URIs using the 'package:' scheme should look like "
          "'$right', not '$wrong'.";
  }

  var packageRoot = _packageRoot == null ?
                    _entryPointScript.resolve('packages/') :
                    _packageRoot;
  return _filePathFromUri(packageRoot.resolve(uri.path).toString());
}
