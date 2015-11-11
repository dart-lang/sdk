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
  //   return new Uri.file(Directory.current.path + "/");
  var result = _getCurrentDirectoryPath();
  return new Uri.file("$result/");
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
bool _packagesReady() => (_packageRoot != null) || (_packageMap != null);
// The directory to look in to resolve "package:" scheme URIs. By detault it is
// the 'packages' directory right next to the script.
Uri _packageRoot = null; // Used to be _rootScript.resolve('packages/');
// The map describing how certain package names are mapped to Uris.
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
_log(msg) {
  _print("* $msg");
}

// A class wrapping the load error message in an Error object.
class _LoadError extends Error {
  final String message;
  final String uri;
  _LoadError(this.uri, this.message);

  String toString() => 'Load Error for "$uri": $message';
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
  if (_traceLoading) {
    _log('Package root URI: $_packageRoot');
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

  if (_traceLoading) {
    _log('Resolving package with uri path: ${uri.path}');
  }
  var resolvedUri;
  if (_packageRoot != null) {
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
    var path = uri.path.substring(packageName.length + 1);
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
    // Close the _dataPort now that there are no more requests outstanding.
    if (_traceLoading) {
      _log("Closing loading port.");
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
      var error = new _LoadError(req._uri, dataOrError.toString());
      _asyncLoadError(req, error, null);
    }
  } catch(e, s) {
    // Wrap inside a _LoadError unless we are already propagating a
    // previous _LoadError.
    var error = (e is _LoadError) ? e : new _LoadError(req._uri, e.toString());
    assert(req != null);
    _asyncLoadError(req, error, s);
  }
}


void _startLoadRequest(int tag, String uri, Uri resourceUri, context) {
  if (_dataPort == null) {
    if (_traceLoading) {
      _log("Initializing load port.");
    }
    assert(_dataPort == null);
    _dataPort = new RawReceivePort(_handleLoaderReply);
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

  if (_traceLoading) {
    _log("Got packages reply: $msg");
  }
  if (msg is String) {
    if (_traceLoading) {
      _log("Got failure response on package port: '$msg'");
    }
    throw msg;
  }
  if (msg.length == 1) {
    if (_traceLoading) {
      _log("Received package root: '${msg[0]}'");
    }
    _packageRoot = Uri.parse(msg[0]);
  } else {
    assert((msg.length % 2) == 0);
    _packageMap = new Map<String, Uri>();
    for (var i = 0; i < msg.length; i+=2) {
      // TODO(iposva): Complain about duplicate entries.
      _packageMap[msg[i]] = Uri.parse(msg[i+1]);
    }
    if (_traceLoading) {
      _log("Setup package map: $_packageMap");
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
  msg[3] = packagesUri.toString();
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


// Embedder Entrypoint:
// Add mapping from package name to URI.
void _addPackageMapEntry(String key, String value) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  if (_traceLoading) {
    _log("Adding packages map entry: $key -> $value");
  }
  if (_packageRoot != null) {
    if (_traceLoading) {
      _log("_packageRoot already set: $_packageRoot");
    }
    throw "Cannot add package map entry to an exisiting package root.";
  }
  if (_packagesPort != null) {
    if (_traceLoading) {
      _log("Package map load request already pending.");
    }
    throw "Cannot add package map entry during package map resolution.";
  }
  if (_packageMap == null) {
    _packageMap = new Map<String, Uri>();
  }
  _packageMap[key] = _workingDirectory.resolve(value);
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
    // Wrap inside a _LoadError unless we are already propagating a previously
    // seen _LoadError.
    var error = (e is _LoadError) ? e : new _LoadError(uri, e.toString());
    // Register a dummy load request and fail to load it.
    var req = new _LoadRequest(tag, uri, resourceUri, context);
    _asyncLoadError(req, error, s);
  }
}


// Loading a package URI needs to first map the package name to a loadable
// URI.
_loadPackage(int tag, String uri, Uri resourceUri, context) {
  if (_packagesReady()) {
    _loadData(tag, uri, _resolvePackageUri(resourceUri), context);
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


// Embedder Entrypoint:
// Function called by standalone embedder to resolve uris when the VM requests
// Dart_kCanonicalizeUrl from the tag handler.
String _resolveUri(String base, String userString) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  if (_traceLoading) {
    _log('Resolving: $userString from $base');
  }
  var baseUri = Uri.parse(base);
  var result;
  if (userString.startsWith(_DART_EXT)) {
    var uri = userString.substring(_DART_EXT.length);
    result = '$_DART_EXT${baseUri.resolve(uri)}';
  } else {
    result = baseUri.resolve(userString).toString();
  }
  if (_traceLoading) {
    _log('Resolved $userString in $base to $result');
  }
  return result;
}


// Handling of access to the package root or package map from user code.
_triggerPackageResolution(action) {
  if (_packagesReady()) {
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


Future<Uri> _getPackageRoot() {
  if (_traceLoading) {
    _log("Request for package root from user code.");
  }
  var completer = new Completer<Uri>();
  _triggerPackageResolution(() {
    completer.complete(_packageRoot);
  });
  return completer.future;
}


Future<Map<String, Uri>> _getPackageMap() {
  if (_traceLoading) {
    _log("Request for package map from user code.");
  }
  var completer = new Completer<Map<String, Uri>>();
  _triggerPackageResolution(() {
    var result = (_packageMap != null) ? new Map.from(_packageMap) : {};
    completer.complete(result);
  });
  return completer.future;
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


// Embedder Entrypoint:
// When loading an extension the embedder calls this method to get the
// different components.
// Returns the directory part, the filename part, and the name
// of a native extension URL as a list [directory, filename, name].
// The directory part is either a file system path or an HTTP(S) URL.
// The filename part is the extension name, with the platform-dependent
// prefixes and extensions added.
_extensionPathFromUri(String userUri) {
  if (!_setupCompleted) {
    _setupHooks();
  }
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


// Register callbacks and hooks with the rest of the core libraries.
_setupHooks() {
  _setupCompleted = true;
  VMLibraryHooks.resourceReadAsBytes = _resourceReadAsBytes;
  VMLibraryHooks.getPackageRoot = _getPackageRoot;
  VMLibraryHooks.getPackageMap = _getPackageMap;
}
