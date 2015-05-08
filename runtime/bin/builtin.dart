// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;
// NOTE: Do not import 'dart:io' in builtin.
import 'dart:isolate';
import 'dart:typed_data';

// import 'root_library'; happens here from C Code

// Build time flag to enable debug logging of loading code.
const _logLoading = false;


// The root library (aka the script) is imported into this library. The
// standalone embedder uses this to lookup the main entrypoint in the
// root library's namespace.
Function _getMainClosure() => main;


// 'print' implementation.
// The standalone embedder registers the closurized _print function with the
// dart:core library.
void _printString(String s) native "Builtin_PrintString";


void _print(arg) {
  _printString(arg.toString());
}


_getPrintClosure() => _print;


// Corelib 'Uri.base' implementation.
// Uri.base is susceptible to changes in the current working directory.
_getCurrentDirectoryPath() native "Builtin_GetCurrentDirectory";


Uri _uriBase() {
  // We are not using Dircetory.current here to limit the dependency
  // on dart:io. This code is the same as:
  //   return new Uri.file(Directory.current.path + "/");
  var result = _getCurrentDirectoryPath();
  return new Uri.file("$result/");
}


_getUriBaseClosure() => _uriBase;


// Asynchronous loading of resources.
// The embedder forwards most loading requests to this library.

// See Dart_LibraryTag in dart_api.h
const Dart_kScriptTag = null;
const Dart_kImportTag = 0;
const Dart_kSourceTag = 1;
const Dart_kCanonicalizeUrl = 2;

// A port for communicating with the service isolate for I/O.
SendPort _loadPort;
// Maintain a number of outstanding load requests. Current loading request is
// finished once there are no outstanding requests.
int _numOutstandingLoadRequests = 0;

// The current working directory when the embedder was launched.
var _workingDirectoryUri;
// The URI that the entry point script was loaded from. Remembered so that
// package imports can be resolved relative to it.
var _entryPointScript;
// The directory to look in to resolve "package:" scheme URIs. By detault it is
// the 'packages' directory right next to the script.
var _packageRoot = _entryPointScript.resolve('packages/');

// Special handling for Windows paths so that they are compatible with URI
// handling.
// Embedder sets whether we are running on Windows.
var _isWindows;


// A class wrapping the load error message in an Error object.
class LoadError extends Error {
  final String message;
  LoadError(this.message);

  String toString() => 'Load Error: $message';
}


// Native calls provided by the embedder.
void _signalDoneLoading() native "Builtin_DoneLoading";
void _loadScriptCallback(int tag, String uri, String libraryUri, Uint8List data)
    native "Builtin_LoadSource";
void _asyncLoadErrorCallback(uri, libraryUri, error)
    native "Builtin_AsyncLoadError";


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


_trimWindowsPath(path) {
  // Convert /X:/ to X:/.
  if (_isWindows == false) {
    // Do nothing when not running Windows.
    return path;
  }
  if (!path.startsWith('/') || (path.length < 3)) {
    return path;
  }
  // Match '/?:'.
  if ((path[0] == '/') && (path[2] == ':')) {
    // Remove leading '/'.
    return path.substring(1);
  }
  return path;
}


// Ensure we have a trailing slash character.
_enforceTrailingSlash(uri) {
  if (!uri.endsWith('/')) {
    return '$uri/';
  }
  return uri;
}


// Embedder Entrypoint:
// The embedder calls this method with the current working directory.
void _setWorkingDirectory(cwd) {
  cwd = _sanitizeWindowsPath(cwd);
  _workingDirectoryUri = new Uri.directory(cwd);
  if (_logLoading) {
    _print('# Working Directory: $cwd -> $_workingDirectoryUri');
  }
}


// Embedder Entrypoint:
// The embedder calls this method with a custom package root.
_setPackageRoot(String packageRoot) {
  packageRoot = _enforceTrailingSlash(packageRoot);
  if (packageRoot.startsWith('file:') ||
      packageRoot.startsWith('http:') ||
      packageRoot.startsWith('https:')) {
    _packageRoot = _workingDirectoryUri.resolve(packageRoot);
  } else {
    packageRoot = _sanitizeWindowsPath(packageRoot);
    packageRoot = _trimWindowsPath(packageRoot);
    _packageRoot = _workingDirectoryUri.resolveUri(new Uri.file(packageRoot));
  }
  if (_logLoading) {
    _print('# Package root: $packageRoot -> $_packageRoot');
  }
}


// Given a uri with a 'package' scheme, return a Uri that is prefixed with
// the package root.
Uri _resolvePackageUri(Uri uri) {
  if (!uri.host.isEmpty) {
    var path = '${uri.host}${uri.path}';
    var right = 'package:$path';
    var wrong = 'package://$path';

    throw "URIs using the 'package:' scheme should look like "
          "'$right', not '$wrong'.";
  }

  if (_logLoading) {
    _print('# Package root: $_packageRoot');
    _print('# uri path: ${uri.path}');
  }
  return _packageRoot.resolve(uri.path);
}


// Resolves the script uri in the current working directory iff the given uri
// did not specify a scheme (e.g. a path to a script file on the command line).
Uri _resolveScriptUri(String scriptName) {
  if (_workingDirectoryUri == null) {
    throw 'No current working directory set.';
  }
  scriptName = _sanitizeWindowsPath(scriptName);

  var scriptUri = Uri.parse(scriptName);
  if (scriptUri.scheme == '') {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    scriptUri = _workingDirectoryUri.resolveUri(scriptUri);
  }

  // Remember the entry point script URI so that we can resolve packages
  // based on this location.
  _entryPointScript = scriptUri;

  if (_logLoading) {
    _print('# Resolved entry point to: $_entryPointScript');
  }
  return scriptUri;
}


void _finishLoadRequest(String uri) {
  assert(_numOutstandingLoadRequests > 0);
  _numOutstandingLoadRequests--;
  if (_logLoading) {
    _print("Loading of $uri finished, "
           "${_numOutstandingLoadRequests} requests remaining");
  }
  if (_numOutstandingLoadRequests == 0) {
    _signalDoneLoading();
  }
}


void _startLoadRequest(String uri, Uri resourceUri) {
  assert(_numOutstandingLoadRequests >= 0);
  _numOutstandingLoadRequests++;
  if (_logLoading) {
    _print("Loading of $resourceUri for $uri started, "
           "${_numOutstandingLoadRequests} requests outstanding");
  }
}


void _loadScript(int tag, String uri, String libraryUri, Uint8List data) {
  // TODO: Currently a compilation error while loading the script is
  // fatal for the isolate. _loadScriptCallback() does not return and
  // the _numOutstandingLoadRequests counter remains out of sync.
  _loadScriptCallback(tag, uri, libraryUri, data);
  _finishLoadRequest(uri);
}


void _asyncLoadError(int tag, String uri, String libraryUri, LoadError error) {
  if (_logLoading) {
    _print("_asyncLoadError($uri), error: $error");
  }
  if (tag == Dart_kImportTag) {
    // When importing a library, the libraryUri is the imported
    // uri.
    libraryUri = uri;
  }
  _asyncLoadErrorCallback(uri, libraryUri, error);
  _finishLoadRequest(uri);
}


_loadDataFromLoadPort(int tag,
                      String uri,
                      String libraryUri,
                      Uri resourceUri) {
  var receivePort = new ReceivePort();
  receivePort.first.then((dataOrError) {
    receivePort.close();
    if (dataOrError is Uint8List) {
      _loadScript(tag, uri, libraryUri, dataOrError);
    } else {
      assert(dataOrError is String);
      var error = new LoadError(dataOrError.toString());
      _asyncLoadError(tag, uri, libraryUri, error);
    }
  }).catchError((e) {
    receivePort.close();
    // Wrap inside a LoadError unless we are already propagating a previously
    // seen LoadError.
    var error = (e is LoadError) ? e : new LoadError(e.toString);
    _asyncLoadError(tag, uri, libraryUri, error);
  });

  try {
    var msg = [receivePort.sendPort, resourceUri.toString()];
    _loadPort.send(msg);
    _startLoadRequest(uri, resourceUri);
  } catch (e) {
    if (_logLoading) {
      _print("Exception when communicating with service isolate: $e");
    }
    // Wrap inside a LoadError unless we are already propagating a previously
    // seen LoadError.
    var error = (e is LoadError) ? e : new LoadError(e.toString);
    _asyncLoadError(tag, uri, libraryUri, error);
    receivePort.close();
  }
}


// Embedder Entrypoint:
// Asynchronously loads script data through a http[s] or file uri.
_loadDataAsync(int tag, String uri, String libraryUri) {
  var resourceUri;
  if (tag == Dart_kScriptTag) {
    resourceUri = _resolveScriptUri(uri);
    uri = resourceUri.toString();
  } else {
    resourceUri = Uri.parse(uri);
  }

  // package based uris need to be resolved to the correct loadable location.
  if (resourceUri.scheme == 'package') {
    resourceUri = _resolvePackageUri(resourceUri);
  }

  _loadDataFromLoadPort(tag, uri, libraryUri, resourceUri);
}


// Embedder Entrypoint:
// Function called by standalone embedder to resolve uris when the VM requests
// Dart_kCanonicalizeUrl from the tag handler.
String _resolveUri(String base, String userString) {
  if (_logLoading) {
    _print('# Resolving: $userString from $base');
  }
  var baseUri = Uri.parse(base);
  var result;
  if (userString.startsWith(_DART_EXT)) {
    var uri = userString.substring(_DART_EXT.length);
    result = '$_DART_EXT${baseUri.resolve(uri)}';
  } else {
    result = baseUri.resolve(userString).toString();
  }
  if (_logLoading) {
    _print('Resolved $userString in $base to $result');
  }
  return result;
}


// Embedder Entrypoint (gen_snapshot):
// Resolve relative paths relative to working directory.
String _resolveInWorkingDirectory(String fileName) {
  if (_workingDirectoryUri == null) {
    throw 'No current working directory set.';
  }
  var name = _sanitizeWindowsPath(fileName);

  var uri = Uri.parse(name);
  if (uri.scheme != '') {
    throw 'Schemes are not supported when resolving filenames.';
  }
  uri = _workingDirectoryUri.resolveUri(uri);

  if (_logLoading) {
    _print('# Resolved in working directory: $fileName -> $uri');
  }
  return uri.toString();
}


// Handling of dart-ext loading.
// Dart native extension scheme.
const _DART_EXT = 'dart-ext:';

String _nativeLibraryExtension() native "Builtin_NativeLibraryExtension";


String _platformExtensionFileName(String name) {
  var extension = _nativeLibraryExtension();

  if (_isWindows) {
    return '$name.$extension';
  } else {
    return 'lib$name.$extension';
  }
}


// Returns either a file path or a URI starting with http[s]:, as a String.
String _filePathFromUri(String userUri) {
  var uri = Uri.parse(userUri);
  if (_logLoading) {
    _print('# Getting file path from: $uri');
  }

  var path;
  switch (uri.scheme) {
    case '':
    case 'file':
    return uri.toFilePath();
    case 'package':
    return _filePathFromUri(_resolvePackageUri(uri).toString());
    case 'data':
    case 'http':
    case 'https':
    return uri.toString();
    default:
    // Only handling file, http, and package URIs
    // in standalone binary.
    if (_logLoading) {
      _print('# Unknown scheme (${uri.scheme}) in $uri.');
    }
    throw 'Not a known scheme: $uri';
  }
}


// Embedder Entrypoint:
// When loading an extension the embedder calls this method to get the
// different components.
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
  var filename = _platformExtensionFileName(name);

  return [path, filename, name];
}
