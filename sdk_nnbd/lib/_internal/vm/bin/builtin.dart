// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;

// NOTE: Do not import 'dart:io' in builtin.
import 'dart:async';
import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' hide Symbol;
import 'dart:io';
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

// The current working directory when the embedder was launched.
late Uri _workingDirectory;

// The URI that the root script was loaded from. Remembered so that
// package imports can be resolved relative to it. The root script is the basis
// for the root library in the VM.
Uri? _rootScript;

// packagesConfig specified for the isolate.
Uri? _packagesConfigUri;

// Packages are either resolved looking up in a map or resolved from within a
// package root.
bool get _packagesReady => (_packageMap != null) || (_packageError != null);

// Error string set if there was an error resolving package configuration.
// For example not finding a .packages file or packages/ directory, malformed
// .packages file or any other related error.
String? _packageError = null;

// The map describing how certain package names are mapped to Uris.
Uri? _packageConfig = null;
Map<String, Uri>? _packageMap = null;

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

_setPackagesConfig(String packagesParam) {
  var packagesName = _sanitizeWindowsPath(packagesParam);
  var packagesUri = Uri.parse(packagesName);
  if (packagesUri.scheme == '') {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    packagesUri = _workingDirectory.resolveUri(packagesUri);
  }
  _packagesConfigUri = packagesUri;
}

// Given a uri with a 'package' scheme, return a Uri that is prefixed with
// the package root or resolved relative to the package configuration.
Uri _resolvePackageUri(Uri uri) {
  assert(uri.scheme == "package");
  assert(_packagesReady);

  if (uri.host.isNotEmpty) {
    var path = '${uri.host}${uri.path}';
    var right = 'package:$path';
    var wrong = 'package://$path';

    throw "URIs using the 'package:' scheme should look like "
        "'$right', not '$wrong'.";
  }

  var packageNameEnd = uri.path.indexOf('/');
  if (packageNameEnd == 0) {
    // Package URIs must have a non-empty package name (not start with "/").
    throw "URIS using the 'package:' scheme should look like "
        "'package:packageName${uri.path}', not 'package:${uri.path}'";
  }
  if (_traceLoading) {
    _log('Resolving package with uri path: ${uri.path}');
  }
  var resolvedUri;
  final error = _packageError;
  if (error != null) {
    if (_traceLoading) {
      _log("Resolving package with pending resolution error: $error");
    }
    throw error;
  } else {
    if (packageNameEnd < 0) {
      // Package URIs must have a path after the package name, even if it's
      // just "/".
      throw "URIS using the 'package:' scheme should look like "
          "'package:${uri.path}/', not 'package:${uri.path}'";
    }
    var packageName = uri.path.substring(0, packageNameEnd);
    final mapping = _packageMap![packageName];
    if (_traceLoading) {
      _log("Mapped '$packageName' package to '$mapping'");
    }
    if (mapping == null) {
      throw "No mapping for '$packageName' package when resolving '$uri'.";
    }
    var path;
    assert(uri.path.length > packageName.length);
    path = uri.path.substring(packageName.length + 1);
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

void _requestPackagesMap(Uri? packageConfig) {
  var msg = null;
  if (packageConfig != null) {
    // Explicitly specified .packages path.
    msg = _handlePackagesRequest(_traceLoading, -2, packageConfig);
  } else {
    // Search for .packages starting at the root script.
    msg = _handlePackagesRequest(_traceLoading, -1, _rootScript!);
  }
  if (_traceLoading) {
    _log("Requested packages map for '$_rootScript'.");
  }
  if (msg is String) {
    if (_traceLoading) {
      _log("Got failure response on package port: '$msg'");
    }
    // Remember the error message.
    _packageError = msg;
  } else if (msg is List) {
    // First entry contains the location of the loaded .packages file.
    assert((msg.length % 2) == 0);
    assert(msg.length >= 2);
    assert(msg[1] == null);
    _packageConfig = Uri.parse(msg[0]);
    final pmap = new Map<String, Uri>();
    _packageMap = pmap;
    for (var i = 2; i < msg.length; i += 2) {
      // TODO(iposva): Complain about duplicate entries.
      pmap[msg[i]] = Uri.parse(msg[i + 1]);
    }
    if (_traceLoading) {
      _log("Setup package map: $_packageMap");
    }
  } else {
    _packageError = "Bad type of packages reply: ${msg.runtimeType}";
    if (_traceLoading) {
      _log(_packageError);
    }
  }
}

// Handling of packages requests. Finding and parsing of .packages file or
// packages/ directories.
const _LF = 0x0A;
const _CR = 0x0D;
const _SPACE = 0x20;
const _HASH = 0x23;
const _DOT = 0x2E;
const _COLON = 0x3A;
const _DEL = 0x7F;

const _invalidPackageNameChars = const [
  true, //  space
  false, // !
  true, //  "
  true, //  #
  false, // $
  true, //  %
  false, // &
  false, // '
  false, // (
  false, // )
  false, // *
  false, // +
  false, // ,
  false, // -
  false, // .
  true, //  /
  false, // 0
  false, // 1
  false, // 2
  false, // 3
  false, // 4
  false, // 5
  false, // 6
  false, // 7
  false, // 8
  false, // 9
  true, //  :
  false, // ;
  true, //  <
  false, // =
  true, //  >
  true, //  ?
  false, // @
  false, // A
  false, // B
  false, // C
  false, // D
  false, // E
  false, // F
  false, // G
  false, // H
  false, // I
  false, // J
  false, // K
  false, // L
  false, // M
  false, // N
  false, // O
  false, // P
  false, // Q
  false, // R
  false, // S
  false, // T
  false, // U
  false, // V
  false, // W
  false, // X
  false, // Y
  false, // Z
  true, //  [
  true, //  \
  true, //  ]
  true, //  ^
  false, // _
  true, //  `
  false, // a
  false, // b
  false, // c
  false, // d
  false, // e
  false, // f
  false, // g
  false, // h
  false, // i
  false, // j
  false, // k
  false, // l
  false, // m
  false, // n
  false, // o
  false, // p
  false, // q
  false, // r
  false, // s
  false, // t
  false, // u
  false, // v
  false, // w
  false, // x
  false, // y
  false, // z
  true, //  {
  true, //  |
  true, //  }
  false, // ~
  true, //  DEL
];

_parsePackagesFile(bool traceLoading, Uri packagesFile, List<int> data) {
  // The first entry contains the location of the identified .packages file
  // instead of a mapping.
  var result = [packagesFile.toString(), null];
  var index = 0;
  var len = data.length;
  while (index < len) {
    var start = index;
    var char = data[index];
    if ((char == _CR) || (char == _LF)) {
      // Skipping empty lines.
      index++;
      continue;
    }

    // Identify split within the line and end of the line.
    var separator = -1;
    var end = len;
    // Verifying validity of package name while scanning the line.
    var nonDot = false;
    var invalidPackageName = false;

    // Scan to the end of the line or data.
    while (index < len) {
      char = data[index++];
      // If we have not reached the separator yet, determine whether we are
      // scanning legal package name characters.
      if (separator == -1) {
        if ((char == _COLON)) {
          // The first colon on a line is the separator between package name and
          // related URI.
          separator = index - 1;
        } else {
          // Still scanning the package name part. Check for the validity of
          // the characters.
          nonDot = nonDot || (char != _DOT);
          invalidPackageName = invalidPackageName ||
              (char < _SPACE) ||
              (char > _DEL) ||
              _invalidPackageNameChars[char - _SPACE];
        }
      }
      // Identify end of line.
      if ((char == _CR) || (char == _LF)) {
        end = index - 1;
        break;
      }
    }

    // No further handling needed for comment lines.
    if (data[start] == _HASH) {
      if (traceLoading) {
        _log("Skipping comment in $packagesFile:\n"
            "${new String.fromCharCodes(data, start, end)}");
      }
      continue;
    }

    // Check for a badly formatted line, starting with a ':'.
    if (separator == start) {
      var line = new String.fromCharCodes(data, start, end);
      if (traceLoading) {
        _log("Line starts with ':' in $packagesFile:\n"
            "$line");
      }
      return "Missing package name in $packagesFile:\n"
          "$line";
    }

    // Ensure there is a separator on the line.
    if (separator == -1) {
      var line = new String.fromCharCodes(data, start, end);
      if (traceLoading) {
        _log("Line has no ':' in $packagesFile:\n"
            "$line");
      }
      return "Missing ':' separator in $packagesFile:\n"
          "$line";
    }

    var packageName = new String.fromCharCodes(data, start, separator);

    // Check for valid package name.
    if (invalidPackageName || !nonDot) {
      var line = new String.fromCharCodes(data, start, end);
      if (traceLoading) {
        _log("Invalid package name $packageName in $packagesFile");
      }
      return "Invalid package name '$packageName' in $packagesFile:\n"
          "$line";
    }

    if (traceLoading) {
      _log("packageName: $packageName");
    }
    var packageUri = new String.fromCharCodes(data, separator + 1, end);
    if (traceLoading) {
      _log("original packageUri: $packageUri");
    }
    // Ensure the package uri ends with a /.
    if (!packageUri.endsWith("/")) {
      packageUri = "$packageUri/";
    }
    packageUri = packagesFile.resolve(packageUri).toString();
    if (traceLoading) {
      _log("mapping: $packageName -> $packageUri");
    }
    result.add(packageName);
    result.add(packageUri);
  }

  if (traceLoading) {
    _log("Parsed packages file at $packagesFile. Sending:\n$result");
  }
  return result;
}

_loadPackagesFile(bool traceLoading, Uri packagesFile) {
  try {
    var data = new File.fromUri(packagesFile).readAsBytesSync();
    if (traceLoading) {
      _log("Loaded packages file from $packagesFile:\n"
          "${new String.fromCharCodes(data)}");
    }
    return _parsePackagesFile(traceLoading, packagesFile, data);
  } catch (e, s) {
    if (traceLoading) {
      _log("Error loading packages: $e\n$s");
    }
    return "Uncaught error ($e) loading packages file.";
  }
}

_findPackagesFile(bool traceLoading, Uri base) {
  try {
    // Walk up the directory hierarchy to check for the existence of
    // .packages files in parent directories and for the existence of a
    // packages/ directory on the first iteration.
    var dir = new File.fromUri(base).parent;
    var prev = null;
    // Keep searching until we reach the root.
    while ((prev == null) || (prev.path != dir.path)) {
      // Check for the existence of a .packages file and if it exists try to
      // load and parse it.
      var dirUri = dir.uri;
      var packagesFile = dirUri.resolve(".packages");
      if (traceLoading) {
        _log("Checking for $packagesFile file.");
      }
      var exists = new File.fromUri(packagesFile).existsSync();
      if (traceLoading) {
        _log("$packagesFile exists: $exists");
      }
      if (exists) {
        return _loadPackagesFile(traceLoading, packagesFile);
      }
      // Move up one level.
      prev = dir;
      dir = dir.parent;
    }

    // No .packages file was found.
    if (traceLoading) {
      _log("Could not resolve a package location from $base");
    }
    return "Could not resolve a package location for base at $base";
  } catch (e, s) {
    if (traceLoading) {
      _log("Error loading packages: $e\n$s");
    }
    return "Uncaught error ($e) loading packages file.";
  }
}

_loadPackagesData(traceLoading, resource) {
  try {
    var data = resource.data;
    var mime = data.mimeType;
    if (mime != "text/plain") {
      throw "MIME-type must be text/plain: $mime given.";
    }
    var charset = data.charset;
    if ((charset != "utf-8") && (charset != "US-ASCII")) {
      // The C++ portion of the embedder assumes UTF-8.
      throw "Only utf-8 or US-ASCII encodings are supported: $charset given.";
    }
    return _parsePackagesFile(traceLoading, resource, data.contentAsBytes());
  } catch (e) {
    return "Uncaught error ($e) loading packages data.";
  }
}

_handlePackagesRequest(bool traceLoading, int tag, Uri resource) {
  try {
    if (tag == -1) {
      if (resource.scheme == '' || resource.scheme == 'file') {
        return _findPackagesFile(traceLoading, resource);
      } else {
        return "Unsupported scheme used to locate .packages file:'$resource'.";
      }
    } else if (tag == -2) {
      if (traceLoading) {
        _log("Handling load of packages map: '$resource'.");
      }
      if (resource.scheme == '' || resource.scheme == 'file') {
        var exists = new File.fromUri(resource).existsSync();
        if (exists) {
          return _loadPackagesFile(traceLoading, resource);
        } else {
          return "Packages file '$resource' not found.";
        }
      } else if (resource.scheme == 'data') {
        return _loadPackagesData(traceLoading, resource);
      } else {
        return "Unknown scheme (${resource.scheme}) for package file at "
            "'$resource'.";
      }
    } else {
      return "Unknown packages request tag: $tag for '$resource'.";
    }
  } catch (e, s) {
    if (traceLoading) {
      _log("Error handling packages request: $e\n$s");
    }
    return "Uncaught error ($e) handling packages request.";
  }
}

// Embedder Entrypoint:
// The embedder calls this method to initial the package resolution state.
@pragma("vm:entry-point")
void _Init(String packagesConfig, String workingDirectory, String rootScript) {
  // Register callbacks and hooks with the rest of core libraries.
  _setupHooks();

  // _workingDirectory must be set first.
  _workingDirectory = new Uri.directory(workingDirectory);

  // setup _rootScript.
  if (rootScript != null) {
    _rootScript = Uri.parse(rootScript);
  }

  // If the --packages flag was passed, setup _packagesConfig.
  if (packagesConfig != null) {
    _packageMap = null;
    _setPackagesConfig(packagesConfig);
  }
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

// Register callbacks and hooks with the rest of the core libraries.
@pragma("vm:entry-point")
_setupHooks() {
  _setupCompleted = true;
  VMLibraryHooks.packageConfigUriFuture = _getPackageConfigFuture;
  VMLibraryHooks.resolvePackageUriFuture = _resolvePackageUriFuture;
}

Future<Uri?> _getPackageConfigFuture() {
  if (_traceLoading) {
    _log("Request for package config from user code.");
  }
  if (!_packagesReady) {
    _requestPackagesMap(_packagesConfigUri);
  }
  // Respond with the packages config (if any) after package resolution.
  return Future.value(_packageConfig);
}

Future<Uri?> _resolvePackageUriFuture(Uri packageUri) {
  if (_traceLoading) {
    _log("Request for package Uri resolution from user code: $packageUri");
  }
  if (packageUri.scheme != "package") {
    if (_traceLoading) {
      _log("Non-package Uri, returning unmodified: $packageUri");
    }
    // Return the incoming parameter if not passed a package: URI.
    return Future.value(packageUri);
  }
  if (!_packagesReady) {
    _requestPackagesMap(_packagesConfigUri);
  }
  Uri? resolvedUri;
  try {
    resolvedUri = _resolvePackageUri(packageUri);
  } catch (e, s) {
    if (_traceLoading) {
      _log("Exception when resolving package URI: $packageUri");
    }
    resolvedUri = null;
  }
  if (_traceLoading) {
    _log("Resolved '$packageUri' to '$resolvedUri'");
  }
  return Future.value(resolvedUri);
}
