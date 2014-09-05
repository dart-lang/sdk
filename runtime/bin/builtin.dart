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

const _logBuiltin = false;

// Corelib 'Uri.base' implementation.
Uri _uriBase() {
  return new Uri.file(Directory.current.path + "/");
}


_getUriBaseClosure() => _uriBase;


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
  if (_logBuiltin) {
    _print('# Working Directory: $cwd');
  }
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
  if (_logBuiltin) {
    _print('# Package root: $packageRoot -> $_packageRoot');
  }
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
  if (_logBuiltin) {
    _print('# Resolved entry point to: $_entryPointScript');
  }
  return _entryPointScript.toString();
}

const _DART_EXT = 'dart-ext:';

String _resolveUri(String base, String userString) {
  if (_logBuiltin) {
    _print('# Resolving: $userString from $base');
  }
  var baseUri = Uri.parse(base);
  if (userString.startsWith(_DART_EXT)) {
    var uri = userString.substring(_DART_EXT.length);
    return '$_DART_EXT${baseUri.resolve(uri)}';
  } else {
    return baseUri.resolve(userString).toString();
  }
}


// Returns either a file path or a URI starting with http:, as a String.
String _filePathFromUri(String userUri) {
  var uri = Uri.parse(userUri);
  if (_logBuiltin) {
    _print('# Getting file path from: $uri');
  }

  var path;
  switch (uri.scheme) {
    case '':
    case 'file':
      return uri.toFilePath();
    case 'package':
      return _filePathFromUri(_resolvePackageUri(uri).toString());
    case 'http':
      return uri.toString();
    default:
      // Only handling file, http, and package URIs
      // in standalone binary.
      if (_logBuiltin) {
        _print('# Unknown scheme (${uri.scheme}) in $uri.');
      }
      throw 'Not a known scheme: $uri';
  }
}


Uri _resolvePackageUri(Uri uri) {
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
  return packageRoot.resolve(uri.path);
}


int _numOutstandingLoadRequests = 0;
var _httpClient;

void _httpGet(Uri uri, String libraryUri, loadCallback(List<int> data)) {
  if (_httpClient == null) {
    _httpClient = new HttpClient()..maxConnectionsPerHost = 6;
  }
  _httpClient.getUrl(uri)
    .then((HttpClientRequest request) => request.close())
    .then((HttpClientResponse response) {
      var builder = new BytesBuilder(copy: false);
      response.listen(
          builder.add,
          onDone: () {
            if (response.statusCode != 200) {
              var msg = 'Failure getting $uri: '
                        '${response.statusCode} ${response.reasonPhrase}';
              _asyncLoadError(uri.toString(), libraryUri, msg);
            }
            loadCallback(builder.takeBytes());
          },
          onError: (error) {
            _asyncLoadError(uri.toString(), libraryUri, error);
          });
    })
    .catchError((error) {
      _asyncLoadError(uri.toString(), libraryUri, error);
    });
  // TODO(floitsch): remove this line. It's just here to push an event on the
  // event loop so that we invoke the scheduled microtasks. Also remove the
  // import of dart:async when this line is not needed anymore.
  Timer.run(() {});
}


void _signalDoneLoading() native "Builtin_DoneLoading";

void _cleanup() {
  if (_httpClient != null) {
    _httpClient.close();
    _httpClient = null;
  }
}

void _loadScriptCallback(int tag, String uri, String libraryUri, List<int> data)
    native "Builtin_LoadScript";

void _loadScript(int tag, String uri, String libraryUri, List<int> data) {
  // TODO: Currently a compilation error while loading the script is
  // fatal for the isolate. _loadScriptCallback() does not return and
  // the _numOutstandingLoadRequests counter remains out of sync.
  _loadScriptCallback(tag, uri, libraryUri, data);
  assert(_numOutstandingLoadRequests > 0);
  _numOutstandingLoadRequests--;
  if (_logBuiltin) {
    _print("native Builtin_LoadScript($uri) completed, "
           "${_numOutstandingLoadRequests} requests remaining");
  }
  if (_numOutstandingLoadRequests == 0) {
    _signalDoneLoading();
    _cleanup();
  }
}


void _asyncLoadErrorCallback(uri, libraryUri, error)
    native "Builtin_AsyncLoadError";

void _asyncLoadError(uri, libraryUri, error) {
  assert(_numOutstandingLoadRequests > 0);
  if (_logBuiltin) {
    _print("_asyncLoadError($uri), error: $error");
  }
  _numOutstandingLoadRequests--;
  _asyncLoadErrorCallback(uri, libraryUri, error);
  if (_numOutstandingLoadRequests == 0) {
    _signalDoneLoading();
    _cleanup();
  }
}


// Create a Uri of 'userUri'. If the input uri is a package uri, then the
// package uri is resolved.
Uri _createUri(String userUri) {
  var uri = Uri.parse(userUri);
  if (_logBuiltin) {
    _print('# Creating uri for: $uri');
  }

  switch (uri.scheme) {
    case '':
    case 'file':
    case 'http':
      return uri;
    case 'package':
      return _resolvePackageUri(uri);
    default:
      // Only handling file, http, and package URIs
      // in standalone binary.
      if (_logBuiltin) {
        _print('# Unknown scheme (${uri.scheme}) in $uri.');
      }
      throw 'Not a known scheme: $uri';
  }
}


// Asynchronously loads script data through a http or file uri.
_loadDataAsync(int tag, String uri, String libraryUri) {
  if (tag == null) {
    uri = _resolveScriptUri(uri);
  }
  Uri resourceUri = _createUri(uri);
  _numOutstandingLoadRequests++;
  if (_logBuiltin) {
    _print("_loadDataAsync($uri), "
           "${_numOutstandingLoadRequests} requests outstanding");
  }
  if (resourceUri.scheme == 'http') {
    _httpGet(resourceUri, libraryUri, (data) {
      _loadScript(tag, uri, libraryUri, data);
    });
  } else {
    var sourceFile = new File(resourceUri.toFilePath());
    sourceFile.readAsBytes().then((data) {
      _loadScript(tag, uri, libraryUri, data);
    },
    onError: (e) {
      _asyncLoadError(uri, libraryUri, e);
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
    if (_logBuiltin) {
      _print('Native extensions not supported on ${Platform.operatingSystem}');
    }
    throw 'Native extensions not supported on ${Platform.operatingSystem}';
  }

  return [path, filename, name];
}
