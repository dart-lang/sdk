// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
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
  try {
    Uri requestUri = Uri.parse(uri);
    _client.getUrl(requestUri)
        .then((HttpClientRequest request) {
          request.persistentConnection = false;
          return request.close();
        })
        .then((HttpClientResponse response) {
          // Only create a ByteBuilder, if multiple chunks are received.
          var builder = new BytesBuilder(copy: false);
          response.listen(
            builder.add,
            onDone: () {
              _requestCompleted(builder.takeBytes(), response);
              // Close the client to stop any timers currently held alive.
              _client.close();
            },
            onError: _requestFailed);
        }).catchError((error) {
          _requestFailed(error);
        });
  } catch (error) {
    _requestFailed(error);
  }
  // TODO(floitsch): remove this line. It's just here to push an event on the
  // event loop so that we invoke the scheduled microtasks. Also remove the
  // import of dart:async when this line is not needed anymore.
  Timer.run(() {});
}


void _httpGet(Uri uri, loadCallback(List<int> data)) {
  var httpClient = new HttpClient();
  try {
    httpClient.getUrl(uri)
      .then((HttpClientRequest request) {
        request.persistentConnection = false;
        return request.close();
      })
      .then((HttpClientResponse response) {
        // Only create a ByteBuilder if multiple chunks are received.
        var builder = new BytesBuilder(copy: false);
        response.listen(
            builder.add,
            onDone: () {
              if (response.statusCode != 200) {
                var msg = 'Failure getting $uri: '
                          '${response.statusCode} ${response.reasonPhrase}';
                _asyncLoadError(uri.toString(), msg);
              }

              List<int> data = builder.takeBytes();
              httpClient.close();
              loadCallback(data);
            },
            onError: (error) {
              _asyncLoadError(uri.toString(), error);
            });
      })
      .catchError((error) {
        _asyncLoadError(uri.toString(), error);
      });
  } catch (error) {
    _asyncLoadError(uri.toString(), error);
  }
  // TODO(floitsch): remove this line. It's just here to push an event on the
  // event loop so that we invoke the scheduled microtasks. Also remove the
  // import of dart:async when this line is not needed anymore.
  Timer.run(() {});
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
  _workingDirectoryUri = new Uri.file(cwd);
  if (!_workingDirectoryUri.path.endsWith("/")) {
    var directoryPath = _workingDirectoryUri.path + "/";
    _workingDirectoryUri = _workingDirectoryUri.resolve(directoryPath);
  }

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
  var scriptUri;
  if (scriptName.startsWith("file:") ||
      scriptName.startsWith("http:") ||
      scriptName.startsWith("https:")) {
    scriptUri = Uri.parse(scriptName);
  } else {
    // Assume it's a file name.
    scriptUri = new Uri.file(scriptName);
  }
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

const _DART_EXT = 'dart-ext:';

String _resolveUri(String base, String userString) {
  _logResolution('# Resolving: $userString from $base');
  var baseUri = Uri.parse(base);
  if (userString.startsWith(_DART_EXT)) {
    var uri = userString.substring(_DART_EXT.length);
    return '$_DART_EXT${baseUri.resolve(uri)}';
  } else {
    return '${baseUri.resolve(userString)}';
  }
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
    case 'package':
      return _filePathFromPackageUri(uri);
      break;
    case 'http':
      return uri.toString();
    default:
      // Only handling file, http, and package URIs
      // in standalone binary.
      _logResolution('# Unknown scheme (${uri.scheme}) in $uri.');
      throw 'Not a known scheme: $uri';
  }
}


String _filePathFromPackageUri(Uri uri) {
  if (!uri.host.isEmpty) {
    var path = '${uri.host}${uri.path}';
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


int _numOutstandingLoadRequests = 0;

void _signalDoneLoading() native "Builtin_DoneLoading";

void _loadScriptCallback(String uri, List<int> data) native "Builtin_LoadScript";

void _loadScript(String uri, List<int> data) {
  // TODO: Currently a compilation error while loading the script is
  // fatal for the isolate. _loadScriptCallback() does not return and
  // the _numOutstandingLoadRequests counter remains out of sync.
  _loadScriptCallback(uri, data);
  assert(_numOutstandingLoadRequests > 0);
  _numOutstandingLoadRequests--;
  _logResolution("native Builtin_LoadScript($uri) completed, "
                 "${_numOutstandingLoadRequests} requests remaining");
  if (_numOutstandingLoadRequests == 0) {
    _signalDoneLoading();
  }
}


void _asyncLoadErrorCallback(uri, error) native "Builtin_AsyncLoadError";

void _asyncLoadError(uri, error) {
  assert(_numOutstandingLoadRequests > 0);
  _numOutstandingLoadRequests--;
  _asyncLoadErrorCallback(uri, error);
}


// Asynchronously loads script data (source or snapshot) through
// an http or file uri.
_loadDataAsync(String uri) {
  uri = _resolveScriptUri(uri);
  Uri sourceUri = Uri.parse(uri);
  _numOutstandingLoadRequests++;
  _logResolution("_loadDataAsync($uri), "
                 "${_numOutstandingLoadRequests} requests outstanding");
  if (sourceUri.scheme == 'http') {
    _httpGet(sourceUri, (data) {
      _loadScript(uri, data);
    });
  } else {
    var sourceFile = new File(_filePathFromUri(uri));
    sourceFile.readAsBytes().then((data) {
      _loadScript(uri, data);
    },
    onError: (e) {
      _asyncLoadError(uri, e);
    });
  }
}


void _loadLibrarySourceCallback(tag, uri, libraryUri, text)
    native "Builtin_LoadLibrarySource";

void _loadLibrarySource(tag, uri, libraryUri, text) {
  // TODO: Currently a compilation error while loading the library is
  // fatal for the isolate. _loadLibraryCallback() does not return and
  // the _numOutstandingLoadRequests counter remains out of sync.
  _loadLibrarySourceCallback(tag, uri, libraryUri, text);
  assert(_numOutstandingLoadRequests > 0);
  _numOutstandingLoadRequests--;
  _logResolution("native Builtin_LoadLibrarySource($uri) completed, "
                 "${_numOutstandingLoadRequests} requests remaining");
  if (_numOutstandingLoadRequests == 0) {
    _signalDoneLoading();
  }
}


// Asynchronously loads source code through an http or file uri.
_loadSourceAsync(int tag, String uri, String libraryUri) {
  var filePath = _filePathFromUri(uri);
  Uri sourceUri = Uri.parse(filePath);
  _numOutstandingLoadRequests++;
  _logResolution("_loadLibrarySource($uri), "
                 "${_numOutstandingLoadRequests} requests outstanding");
  if (sourceUri.scheme == 'http') {
    _httpGet(sourceUri, (data) {
      var text = UTF8.decode(data);
      _loadLibrarySource(tag, uri, libraryUri, text);
    });
  } else {
    var sourceFile = new File(filePath);
    sourceFile.readAsString().then((text) {
      _loadLibrarySource(tag, uri, libraryUri, text);
    },
    onError: (e) {
      _asyncLoadError(uri, e);
    });
  }
}


// Returns the directory part, the filename part, and the name
// of a native extension URL as a list [directory, filename, name].
// The directory part is either a file system path or an HTTP(S) URL.
// The filename part is the extension name, with the platform-dependent
// prefixes and extensions added.
_extensionPathFromUri(String userUri) {
  if (!userUri.startsWith(_DART_EXT)) {
    throw 'Unexpected internal error: Extension URI $userUri missing dart-ext:';
  }
  userUri = userUri.substring(_DART_EXT.length);

  if (userUri.contains('\\')) {
    throw 'Unexpected internal error: Extension URI $userUri contains \\';
  }

  String filename;
  String name;
  String path;  // Will end in '/'.
  int index = userUri.lastIndexOf('/');
  if (index == -1) {
    name = userUri;
    path = './';
  } else if (index == userUri.length - 1) {
    throw 'Extension name missing in $extensionUri';
  } else {
    name = userUri.substring(index + 1);
    path = userUri.substring(0, index + 1);
  }

  path = _filePathFromUri(path);

  if (Platform.isLinux || Platform.isAndroid) {
    filename = 'lib$name.so';
  } else if (Platform.isMacOS) {
    filename = 'lib$name.dylib';
  } else if (Platform.isWindows) {
    filename = '$name.dll';
  } else {
    _logResolution(
        'Native extensions not supported on ${Platform.operatingSystem}');
    throw 'Native extensions not supported on ${Platform.operatingSystem}';
  }

  return [path, filename, name];
}
