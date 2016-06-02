// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;
// NOTE: Do not import 'dart:io' in builtin.
import 'dart:async';
import 'dart:collection';
import 'dart:_internal';
import 'dart:isolate';
import 'dart:typed_data';


// Before handling an embedder entrypoint we finalize the setup of the
// dart:_builtin library.
bool _setupCompleted = false;


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
  //   return new Uri.directory(Directory.current.path);
  var path = _getCurrentDirectoryPath();
  return new Uri.directory(path);
}


_getUriBaseClosure() => _uriBase;


// Asynchronous loading of resources.
// The embedder forwards most loading requests to this library.

// See Dart_LibraryTag in dart_api.h
const _Dart_kScriptTag = null;
const _Dart_kImportTag = 0;
const _Dart_kSourceTag = 1;
const _Dart_kCanonicalizeUrl = 2;
const _Dart_kResourceLoad = 3;

// Embedder sets this to true if the --trace-loading flag was passed on the
// command line.
bool _traceLoading = false;

// This is currently a build time flag only. We measure the time from the first
// load request (opening the receive port) to completing the last load
// request (closing the receive port). Future, deferred load operations will
// add to this time.
bool _timeLoading = false;
Stopwatch _stopwatch;

// A port for communicating with the service isolate for I/O.
SendPort _loadPort;
// The receive port for a load request. Multiple sources can be fetched in
// a single load request.
RawReceivePort _dataPort;
// A request id valid only for the current load cycle (while the number of
// outstanding load requests is greater than 0). Can be reset when loading is
// completed.
int _reqId = 0;
// An unordered hash map mapping from request id to a particular load request.
// Once there are no outstanding load requests the current load has finished.
HashMap _reqMap = new HashMap();

// The current working directory when the embedder was launched.
Uri _workingDirectory;
// The URI that the root script was loaded from. Remembered so that
// package imports can be resolved relative to it. The root script is the basis
// for the root library in the VM.
Uri _rootScript;

// Packages are either resolved looking up in a map or resolved from within a
// package root.
bool get _packagesReady =>
    (_packageRoot != null) || (_packageMap != null) || (_packageError != null);
// Error string set if there was an error resolving package configuration.
// For example not finding a .packages file or packages/ directory, malformed
// .packages file or any other related error.
String _packageError = null;
// The directory to look in to resolve "package:" scheme URIs. By detault it is
// the 'packages' directory right next to the script.
Uri _packageRoot = null; // Used to be _rootScript.resolve('packages/');
// The map describing how certain package names are mapped to Uris.
Uri _packageConfig = null;
Map<String, Uri> _packageMap = null;

// A list of pending packags which have been requested while resolving the
// location of the package root or the contents of the package map.
List<_LoadRequest> _pendingPackageLoads = [];

// If we have outstanding loads or pending package loads waiting for resolution,
// then we do have pending loads.
bool _pendingLoads() => !_reqMap.isEmpty || !_pendingPackageLoads.isEmpty;

// Special handling for Windows paths so that they are compatible with URI
// handling.
// Embedder sets this to true if we are running on Windows.
bool _isWindows = false;

// Logging from builtin.dart is prefixed with a '*'.
String _logId = (Isolate.current.hashCode % 0x100000).toRadixString(16);
_log(msg) {
  _print("* $_logId $msg");
}

// A class wrapping the load error message in an Error object.
class _LoadError extends Error {
  final _LoadRequest request;
  final String message;
  _LoadError(this.request, this.message);

  String toString() {
    var context = request._context;
    if (context == null || context is! String) {
      return 'Could not load "${request._uri}": $message';
    } else {
      return 'Could not import "${request._uri}" from "$context": $message';
    }
  }
}

// Class collecting all of the information about a particular load request.
class _LoadRequest {
  final int _id = _reqId++;
  final int _tag;
  final String _uri;
  final Uri _resourceUri;
  final _context;

  _LoadRequest(this._tag, this._uri, this._resourceUri, this._context) {
    assert(_reqMap[_id] == null);
    _reqMap[_id] = this;
  }

  toString() => "LoadRequest($_id, $_tag, $_uri, $_resourceUri, $_context)";
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
_setPackageRoot(String packageRoot) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  if (_traceLoading) {
    _log('Setting package root: $packageRoot');
  }
  packageRoot = _enforceTrailingSlash(packageRoot);
  if (packageRoot.startsWith('file:') ||
      packageRoot.startsWith('http:') ||
      packageRoot.startsWith('https:')) {
    _packageRoot = _workingDirectory.resolve(packageRoot);
  } else {
    packageRoot = _sanitizeWindowsPath(packageRoot);
    packageRoot = _trimWindowsPath(packageRoot);
    _packageRoot = _workingDirectory.resolveUri(new Uri.file(packageRoot));
  }
  // Now that we have determined the packageRoot value being used, set it
  // up for use in Platform.packageRoot. This is only set when the embedder
  // sets up the package root. Automatically discovered package root will
  // not update the VMLibraryHooks value.
  VMLibraryHooks.packageRootString = _packageRoot.toString();
  if (_traceLoading) {
    _log('Package root URI: $_packageRoot');
  }
}


// Given a uri with a 'package' scheme, return a Uri that is prefixed with
// the package root.
Uri _resolvePackageUri(Uri uri) {
  assert(uri.scheme == "package");
  assert(_packagesReady);

  if (!uri.host.isEmpty) {
    var path = '${uri.host}${uri.path}';
    var right = 'package:$path';
    var wrong = 'package://$path';

    throw "URIs using the 'package:' scheme should look like "
          "'$right', not '$wrong'.";
  }

  if (_traceLoading) {
    _log('Resolving package with uri path: ${uri.path}');
  }
  var resolvedUri;
  if (_packageError != null) {
    if (_traceLoading) {
      _log("Resolving package with pending resolution error: $_packageError");
    }
    throw _packageError;
  } else if (_packageRoot != null) {
    resolvedUri = _packageRoot.resolve(uri.path);
  } else {
    var packageName = uri.pathSegments[0];
    var mapping = _packageMap[packageName];
    if (_traceLoading) {
      _log("Mapped '$packageName' package to '$mapping'");
    }
    if (mapping == null) {
      throw "No mapping for '$packageName' package when resolving '$uri'.";
    }
    var path;
    if (uri.path.length > packageName.length) {
      path = uri.path.substring(packageName.length + 1);
    } else {
      // Handle naked package resolution to the default package name:
      // package:foo is equivalent to package:foo/foo.dart
      assert(uri.path.length == packageName.length);
      path = "$packageName.dart";
    }
    if (_traceLoading) {
      _log("Path to be resolved in package: $path");
    }
    resolvedUri = mapping.resolve(path);
  }
  if (_traceLoading) {
    _log("Resolved '$uri' to '$resolvedUri'.");
  }
  return resolvedUri;
}


// Resolves the script uri in the current working directory iff the given uri
// did not specify a scheme (e.g. a path to a script file on the command line).
Uri _resolveScriptUri(String scriptName) {
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
  return scriptUri;
}


void _finishLoadRequest(_LoadRequest req) {
  if (req != null) {
    // Now that we are done with loading remove the request from the map.
    var tmp = _reqMap.remove(req._id);
    assert(tmp == req);
    if (_traceLoading) {
      _log("Loading of ${req._uri} finished: "
           "${_reqMap.length} requests remaining, "
           "${_pendingPackageLoads.length} packages pending.");
    }
  }

  if (!_pendingLoads() && (_dataPort != null)) {
    _stopwatch.stop();
    // Close the _dataPort now that there are no more requests outstanding.
    if (_traceLoading || _timeLoading) {
      _log("Closing loading port: ${_stopwatch.elapsedMilliseconds} ms");
    }
    _dataPort.close();
    _dataPort = null;
    _reqId = 0;
    _signalDoneLoading();
  }
}


void _handleLoaderReply(msg) {
  int id = msg[0];
  var dataOrError = msg[1];
  assert((id >= 0) && (id < _reqId));
  var req = _reqMap[id];
  try {
    if (dataOrError is Uint8List) {
      // Successfully loaded the data.
      if (req._tag == _Dart_kResourceLoad) {
        Completer c = req._context;
        c.complete(dataOrError);
      } else {
        // TODO: Currently a compilation error while loading the script is
        // fatal for the isolate. _loadScriptCallback() does not return and
        // the number of requests remains out of sync.
        _loadScriptCallback(req._tag, req._uri, req._context, dataOrError);
      }
      _finishLoadRequest(req);
    } else {
      assert(dataOrError is String);
      var error = new _LoadError(req, dataOrError.toString());
      _asyncLoadError(req, error, null);
    }
  } catch(e, s) {
    // Wrap inside a _LoadError unless we are already propagating a
    // previous _LoadError.
    var error = (e is _LoadError) ? e : new _LoadError(req, e.toString());
    assert(req != null);
    _asyncLoadError(req, error, s);
  }
}


void _startLoadRequest(int tag, String uri, Uri resourceUri, context) {
  if (_dataPort == null) {
    if (_traceLoading) {
      _log("Initializing load port.");
    }
    // Allocate the Stopwatch if necessary.
    if (_stopwatch == null) {
      _stopwatch = new Stopwatch();
    }
    assert(_dataPort == null);
    _dataPort = new RawReceivePort(_handleLoaderReply);
    _stopwatch.start();
  }
  // Register the load request and send it to the VM service isolate.
  var req = new _LoadRequest(tag, uri, resourceUri, context);

  assert(_dataPort != null);
  var msg = new List(4);
  msg[0] = _dataPort.sendPort;
  msg[1] = _traceLoading;
  msg[2] = req._id;
  msg[3] = resourceUri.toString();
  _loadPort.send(msg);

  if (_traceLoading) {
    _log("Loading of $resourceUri for $uri started with id: ${req._id}. "
         "${_reqMap.length} requests remaining, "
         "${_pendingPackageLoads.length} packages pending.");
  }
}


RawReceivePort _packagesPort;

void _handlePackagesReply(msg) {
  // Make sure to close the _packagePort before any other action.
  _packagesPort.close();
  _packagesPort = null;

  if (_traceLoading) {
    _log("Got packages reply: $msg");
  }
  if (msg is String) {
    if (_traceLoading) {
      _log("Got failure response on package port: '$msg'");
    }
    // Remember the error message.
    _packageError = msg;
  } else if (msg is List) {
    if (msg.length == 1) {
      if (_traceLoading) {
        _log("Received package root: '${msg[0]}'");
      }
      _packageRoot = Uri.parse(msg[0]);
    } else {
      // First entry contains the location of the loaded .packages file.
      assert((msg.length % 2) == 0);
      assert(msg.length >= 2);
      assert(msg[1] == null);
      _packageConfig = Uri.parse(msg[0]);
      _packageMap = new Map<String, Uri>();
      for (var i = 2; i < msg.length; i+=2) {
        // TODO(iposva): Complain about duplicate entries.
        _packageMap[msg[i]] = Uri.parse(msg[i+1]);
      }
      if (_traceLoading) {
        _log("Setup package map: $_packageMap");
      }
    }
  } else {
    _packageError = "Bad type of packages reply: ${msg.runtimeType}";
    if (_traceLoading) {
      _log(_packageError);
    }
  }

  // Resolve all pending package loads now that we know how to resolve them.
  while (_pendingPackageLoads.length > 0) {
    // Order does not matter as we queue all of the requests up right now.
    var req = _pendingPackageLoads.removeLast();
    // Call the registered closure, to handle the delayed action.
    req();
  }
  // Reset the pending package loads to empty. So that we eventually can
  // finish loading.
  _pendingPackageLoads = [];
  // Make sure that the receive port is closed if no other loads are pending.
  _finishLoadRequest(null);
}


void _requestPackagesMap() {
  assert(_packagesPort == null);
  assert(_rootScript != null);
  // Create a port to receive the packages map on.
  _packagesPort = new RawReceivePort(_handlePackagesReply);
  var sp = _packagesPort.sendPort;

  var msg = new List(4);
  msg[0] = sp;
  msg[1] = _traceLoading;
  msg[2] = -1;
  msg[3] = _rootScript.toString();
  _loadPort.send(msg);

  if (_traceLoading) {
    _log("Requested packages map for '$_rootScript'.");
  }
}


// Embedder Entrypoint:
// Request the load of a particular packages map.
void _loadPackagesMap(String packagesParam) {
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

  // Request the loading and parsing of the packages map at the specified URI.
  // Create a port to receive the packages map on.
  assert(_packagesPort == null);
  _packagesPort = new RawReceivePort(_handlePackagesReply);
  var sp = _packagesPort.sendPort;

  var msg = new List(4);
  msg[0] = sp;
  msg[1] = _traceLoading;
  msg[2] = -2;
  msg[3] = packagesUriStr;
  _loadPort.send(msg);

  // Signal that the resolution of the packages map has started. But in this
  // case it is not tied to a particular request.
  _pendingPackageLoads.add(() {
    // Nothing to be done beyond registering that there is pending package
    // resolution requested by having an empty entry.
    if (_traceLoading) {
      _log("Skipping dummy deferred request.");
    }
  });

  if (_traceLoading) {
    _log("Requested packages map at '$packagesUri'.");
  }
}


void _asyncLoadError(_LoadRequest req, _LoadError error, StackTrace stack) {
  if (_traceLoading) {
    _log("_asyncLoadError(${req._uri}), error: $error\nstack: $stack");
  }
  if (req._tag == _Dart_kResourceLoad) {
    Completer c = req._context;
    c.completeError(error, stack);
  } else {
    String libraryUri = req._context;
    if (req._tag == _Dart_kImportTag) {
      // When importing a library, the libraryUri is the imported
      // uri.
      libraryUri = req._uri;
    }
    _asyncLoadErrorCallback(req._uri, libraryUri, error);
  }
  _finishLoadRequest(req);
}


_loadDataFromLoadPort(int tag, String uri, Uri resourceUri, context) {
  try {
    _startLoadRequest(tag, uri, resourceUri, context);
  } catch (e, s) {
    if (_traceLoading) {
      _log("Exception when communicating with service isolate: $e");
    }
    // Register a dummy load request so we can fail to load it.
    var req = new _LoadRequest(tag, uri, resourceUri, context);

    // Wrap inside a _LoadError unless we are already propagating a previously
    // seen _LoadError.
    var error = (e is _LoadError) ? e : new _LoadError(req, e.toString());
    _asyncLoadError(req, error, s);
  }
}


// Loading a package URI needs to first map the package name to a loadable
// URI.
_loadPackage(int tag, String uri, Uri resourceUri, context) {
  if (_packagesReady) {
    var resolvedUri;
    try {
      resolvedUri = _resolvePackageUri(resourceUri);
    } catch (e, s) {
      if (_traceLoading) {
        _log("Exception ($e) when resolving package URI: $resourceUri");
      }
      // Register a dummy load request so we can fail to load it.
      var req = new _LoadRequest(tag, uri, resourceUri, context);

      // Wrap inside a _LoadError unless we are already propagating a previously
      // seen _LoadError.
      var error = (e is _LoadError) ? e : new _LoadError(req, e.toString());
      _asyncLoadError(req, error, s);
    }
    _loadData(tag, uri, resolvedUri, context);
  } else {
    if (_pendingPackageLoads.isEmpty) {
      // Package resolution has not been setup yet, and this is the first
      // request for package resolution & loading.
      _requestPackagesMap();
    }
    // Register the action of loading this package once the package resolution
    // is ready.
    _pendingPackageLoads.add(() {
      if (_traceLoading) {
        _log("Handling deferred package request: "
             "$tag, $uri, $resourceUri, $context");
      }
      _loadPackage(tag, uri, resourceUri, context);
    });
    if (_traceLoading) {
      _log("Pending package load of '$uri': "
           "${_pendingPackageLoads.length} pending");
    }
  }
}


// Load the data associated with the resourceUri.
_loadData(int tag, String uri, Uri resourceUri, context) {
  if (resourceUri.scheme == 'package') {
    // package based uris need to be resolved to the correct loadable location.
    // The logic of which is handled seperately, and then _loadData is called
    // recursively.
    _loadPackage(tag, uri, resourceUri, context);
  } else {
    _loadDataFromLoadPort(tag, uri, resourceUri, context);
  }
}


// Embedder Entrypoint:
// Asynchronously loads script data through a http[s] or file uri.
_loadDataAsync(int tag, String uri, String libraryUri) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  var resourceUri;
  if (tag == _Dart_kScriptTag) {
    resourceUri = _resolveScriptUri(uri);
    uri = resourceUri.toString();
  } else {
    resourceUri = Uri.parse(uri);
  }
  _loadData(tag, uri, resourceUri, libraryUri);
}


// Handling of access to the package root or package map from user code.
_triggerPackageResolution(action) {
  if (_packagesReady) {
    // Packages are ready. Execute the action now.
    action();
  } else {
    if (_pendingPackageLoads.isEmpty) {
      // Package resolution has not been setup yet, and this is the first
      // request for package resolution & loading.
      _requestPackagesMap();
    }
    // Register the action for when the package resolution is ready.
    _pendingPackageLoads.add(action);
  }
}


Future<Uri> _getPackageRootFuture() {
  if (_traceLoading) {
    _log("Request for package root from user code.");
  }
  var completer = new Completer<Uri>();
  _triggerPackageResolution(() {
    completer.complete(_packageRoot);
  });
  return completer.future;
}


Future<Uri> _getPackageConfigFuture() {
  if (_traceLoading) {
    _log("Request for package config from user code.");
  }
  var completer = new Completer<Uri>();
  _triggerPackageResolution(() {
    completer.complete(_packageConfig);
  });
  return completer.future;
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

  if (!_packagesReady) {
    if (_traceLoading) {
      _log("Trigger loading by requesting the package config.");
    }
    // Make sure to trigger package resolution.
    var dummy = await _getPackageConfigFuture();
  }
  assert(_packagesReady);

  var result;
  try {
    result = _resolvePackageUri(packageUri);
  } catch (e, s) {
    // Any error during resolution will resolve this package as not mapped,
    // which is indicated by a null return.
    if (_traceLoading) {
      _log("Exception ($e) when resolving package URI: $packageUri");
    }
    result = null;
  }
  if (_traceLoading) {
    _log("Resolved '$packageUri' to '$result'");
  }
  return result;
}


// Handling of Resource class by dispatching to the load port.
Future<List<int>> _resourceReadAsBytes(Uri uri) {
  var completer = new Completer<List<int>>();
  // Request the load of the resource associating the completer as the context
  // for the load.
  _loadData(_Dart_kResourceLoad, uri.toString(), uri, completer);
  // Return the future that will be triggered once the resource has been loaded.
  return completer.future;
}


// Embedder Entrypoint (gen_snapshot):
// Resolve relative paths relative to working directory.
String _resolveInWorkingDirectory(String fileName) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  if (_workingDirectory == null) {
    throw 'No current working directory set.';
  }
  var name = _sanitizeWindowsPath(fileName);

  var uri = Uri.parse(name);
  if (uri.scheme != '') {
    throw 'Schemes are not supported when resolving filenames.';
  }
  uri = _workingDirectory.resolveUri(uri);

  if (_traceLoading) {
    _log('Resolved in working directory: $fileName -> $uri');
  }
  return uri.toString();
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


// Embedder Entrypoint.
_libraryFilePath(String libraryUri) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  int index = libraryUri.lastIndexOf('/');
  var path;
  if (index == -1) {
    path = './';
  } else {
    path = libraryUri.substring(0, index + 1);
  }
  return _filePathFromUri(path);
}


// Register callbacks and hooks with the rest of the core libraries.
_setupHooks() {
  _setupCompleted = true;
  VMLibraryHooks.resourceReadAsBytes = _resourceReadAsBytes;

  VMLibraryHooks.packageRootUriFuture = _getPackageRootFuture;
  VMLibraryHooks.packageConfigUriFuture = _getPackageConfigFuture;
  VMLibraryHooks.resolvePackageUriFuture = _resolvePackageUriFuture;
}
