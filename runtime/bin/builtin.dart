// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;

// NOTE: Do not import 'dart:io' in builtin.
import 'dart:async';
import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' hide Symbol;
import 'dart:isolate';
import 'dart:typed_data';

// Embedder sets this to true if the --trace-loading flag was passed on the
// command line.
bool _traceLoading = false;

// Before handling an embedder entrypoint we finalize the setup of the
// dart:_builtin library.
bool _setupCompleted = false;

// 'print' implementation.
// The standalone embedder registers the closurized _print function with the
// dart:core library.
void _printString(String s) native "Builtin_PrintString";

void _print(arg) {
  _printString(arg.toString());
}

@pragma("vm:entry-point")
_getPrintClosure() => _print;

// Asynchronous loading of resources.
// The embedder forwards loading requests to the service isolate.

// A port for communicating with the service isolate for I/O.
@pragma("vm:entry-point")
SendPort _loadPort;

// The isolateId used to communicate with the service isolate for I/O.
@pragma("vm:entry-point")
int _isolateId;

// Requests made to the service isolate over the load port.

// Extra requests. Keep these in sync between loader.dart and builtin.dart.
const _Dart_kInitLoader = 4; // Initialize the loader.
const _Dart_kResourceLoad = 5; // Resource class support.
const _Dart_kGetPackageRootUri = 6; // Uri of the packages/ directory.
const _Dart_kGetPackageConfigUri = 7; // Uri of the .packages file.
const _Dart_kResolvePackageUri = 8; // Resolve a package: uri.

// Make a request to the loader. Future will complete with result which is
// either a Uri or a List<int>.
Future<T> _makeLoaderRequest<T>(int tag, String uri) {
  assert(_isolateId != null);
  if (_loadPort == null) {
    throw new UnsupportedError("Service isolate is not available.");
  }
  Completer completer = new Completer<T>();
  RawReceivePort port = new RawReceivePort();
  port.handler = (msg) {
    // Close the port.
    port.close();
    completer.complete(msg);
  };
  _loadPort.send([_traceLoading, _isolateId, tag, port.sendPort, uri]);
  return completer.future;
}

// The current working directory when the embedder was launched.
Uri _workingDirectory;
// The URI that the root script was loaded from. Remembered so that
// package imports can be resolved relative to it. The root script is the basis
// for the root library in the VM.
Uri _rootScript;
// The package root set on the command line.
Uri _packageRoot;

// Special handling for Windows paths so that they are compatible with URI
// handling.
// Embedder sets this to true if we are running on Windows.
@pragma("vm:entry-point")
bool _isWindows = false;

// Logging from builtin.dart is prefixed with a '*'.
String _logId = (Isolate.current.hashCode % 0x100000).toRadixString(16);
_log(msg) {
  _print("* $_logId $msg");
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
@pragma("vm:entry-point")
void _setWorkingDirectory(String cwd) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  if (_traceLoading) {
    _log('Setting working directory: $cwd');
  }
  _workingDirectory = new Uri.directory(cwd);
  if (_traceLoading) {
    _log('Working directory URI: $_workingDirectory');
  }
}

// Embedder Entrypoint:
// The embedder calls this method with a custom package root.
@pragma("vm:entry-point")
String _setPackageRoot(String packageRoot) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  if (_traceLoading) {
    _log('Setting package root: $packageRoot');
  }
  if (packageRoot.startsWith('file:') ||
      packageRoot.startsWith('http:') ||
      packageRoot.startsWith('https:')) {
    packageRoot = _enforceTrailingSlash(packageRoot);
    _packageRoot = _workingDirectory.resolve(packageRoot);
  } else {
    packageRoot = _sanitizeWindowsPath(packageRoot);
    packageRoot = _trimWindowsPath(packageRoot);
    _packageRoot = _workingDirectory.resolveUri(new Uri.directory(packageRoot));
  }
  // Now that we have determined the packageRoot value being used, set it
  // up for use in Platform.packageRoot. This is only set when the embedder
  // sets up the package root. Automatically discovered package root will
  // not update the VMLibraryHooks value.
  var packageRootStr = _packageRoot.toString();
  VMLibraryHooks.packageRootString = packageRootStr;
  if (_traceLoading) {
    _log('Package root URI: $_packageRoot');
  }
  return packageRootStr;
}

// Embedder Entrypoint:
@pragma("vm:entry-point")
String _setPackagesMap(String packagesParam) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  // First convert the packages parameter from the command line to a URI which
  // can be handled by the loader code.
  // TODO(iposva): Consider refactoring the common code below which is almost
  // shared with resolution of the root script.
  if (_traceLoading) {
    _log("Resolving packages map: $packagesParam");
  }
  if (_workingDirectory == null) {
    throw 'No current working directory set.';
  }
  var packagesName = _sanitizeWindowsPath(packagesParam);
  var packagesUri = Uri.parse(packagesName);
  if (packagesUri.scheme == '') {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    packagesUri = _workingDirectory.resolveUri(packagesUri);
  }
  var packagesUriStr = packagesUri.toString();
  VMLibraryHooks.packageConfigString = packagesUriStr;
  if (_traceLoading) {
    _log('Resolved packages map to: $packagesUri');
  }
  return packagesUriStr;
}

// Resolves the script uri in the current working directory iff the given uri
// did not specify a scheme (e.g. a path to a script file on the command line).
@pragma("vm:entry-point")
String _resolveScriptUri(String scriptName) {
  if (_traceLoading) {
    _log("Resolving script: $scriptName");
  }
  if (_workingDirectory == null) {
    throw 'No current working directory set.';
  }
  scriptName = _sanitizeWindowsPath(scriptName);

  var scriptUri = Uri.parse(scriptName);
  if (scriptUri.scheme == '') {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    scriptUri = _workingDirectory.resolveUri(scriptUri);
  }

  // Remember the root script URI so that we can resolve packages based on
  // this location.
  _rootScript = scriptUri;

  if (_traceLoading) {
    _log('Resolved entry point to: $_rootScript');
  }
  return scriptUri.toString();
}

// Only used by vm/cc unit tests.
Uri _resolvePackageUri(Uri uri) {
  assert(_packageRoot != null);
  return _packageRoot.resolve(uri.path);
}

// Returns either a file path or a URI starting with http[s]:, as a String.
String _filePathFromUri(String userUri) {
  var uri = Uri.parse(userUri);
  if (_traceLoading) {
    _log('Getting file path from: $uri');
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
      if (_traceLoading) {
        _log('Unknown scheme (${uri.scheme}) in $uri.');
      }
      throw 'Not a known scheme: $uri';
  }
}

// Register callbacks and hooks with the rest of the core libraries.
@pragma("vm:entry-point")
_setupHooks() {
  _setupCompleted = true;
  VMLibraryHooks.resourceReadAsBytes = _resourceReadAsBytes;

  VMLibraryHooks.packageRootUriFuture = _getPackageRootFuture;
  VMLibraryHooks.packageConfigUriFuture = _getPackageConfigFuture;
  VMLibraryHooks.resolvePackageUriFuture = _resolvePackageUriFuture;
}

// Handling of Resource class by dispatching to the load port.
Future<List<int>> _resourceReadAsBytes(Uri uri) async {
  List response =
      await _makeLoaderRequest<List<int>>(_Dart_kResourceLoad, uri.toString());
  if (response[4] is String) {
    // Throw the error.
    throw response[4];
  } else {
    return response[4];
  }
}

// TODO(mfairhurst): remove this
Future<Uri> _getPackageRootFuture() {
  if (_traceLoading) {
    _log("Request for package root from user code.");
  }
  // Return null, as the `packages/` directory is not supported in dart 2.
  return new Future.value(null);
}

Future<Uri> _getPackageConfigFuture() {
  if (_traceLoading) {
    _log("Request for package config from user code.");
  }
  assert(_loadPort != null);
  return _makeLoaderRequest<Uri>(_Dart_kGetPackageConfigUri, null);
}

Future<Uri> _resolvePackageUriFuture(Uri packageUri) async {
  if (_traceLoading) {
    _log("Request for package Uri resolution from user code: $packageUri");
  }
  if (packageUri.scheme != "package") {
    if (_traceLoading) {
      _log("Non-package Uri, returning unmodified: $packageUri");
    }
    // Return the incoming parameter if not passed a package: URI.
    return packageUri;
  }
  var result = await _makeLoaderRequest<Uri>(
      _Dart_kResolvePackageUri, packageUri.toString());
  if (result is! Uri) {
    if (_traceLoading) {
      _log("Exception when resolving package URI: $packageUri");
    }
    result = null;
  }
  if (_traceLoading) {
    _log("Resolved '$packageUri' to '$result'");
  }
  return result;
}
