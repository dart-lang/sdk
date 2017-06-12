// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

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

class FileRequest {
  final SendPort sp;
  final int tag;
  final Uri uri;
  final Uri resolvedUri;
  final String libraryUrl;
  FileRequest(this.sp, this.tag, this.uri, this.resolvedUri, this.libraryUrl);
}

bool _traceLoading = false;

// State associated with the isolate that is used for loading.
class IsolateLoaderState extends IsolateEmbedderData {
  IsolateLoaderState(this.isolateId);

  final int isolateId;
  bool _dead = false;
  SendPort sp;

  void init(String packageRootFlag, String packagesConfigFlag,
      String workingDirectory, String rootScript) {
    if (_dead) {
      return;
    }
    // _workingDirectory must be set first.
    _workingDirectory = new Uri.directory(workingDirectory);
    if (rootScript != null) {
      _rootScript = Uri.parse(rootScript);
    }
    // If the --package-root flag was passed.
    if (packageRootFlag != null) {
      _setPackageRoot(packageRootFlag);
    }
    // If the --packages flag was passed.
    if (packagesConfigFlag != null) {
      _setPackagesConfig(packagesConfigFlag);
    }
  }

  void updatePackageMap(String packagesConfigFlag) {
    if (packagesConfigFlag == null) {
      return;
    }
    _packageMap = null;
    _setPackagesConfig(packagesConfigFlag);
  }

  void cleanup() {
    _dead = true;
    if (_packagesPort != null) {
      _packagesPort.close();
      _packagesPort = null;
    }
  }

  // The working directory when the embedder started.
  Uri _workingDirectory;

  // The root script's uri.
  Uri _rootScript;

  // Packages are either resolved looking up in a map or resolved from within a
  // package root.
  bool get _packagesReady =>
      (_packageRoot != null) ||
      (_packageMap != null) ||
      (_packageError != null);

  // Error string set if there was an error resolving package configuration.
  // For example not finding a .packages file or packages/ directory, malformed
  // .packages file or any other related error.
  String _packageError = null;

  // The directory to look in to resolve "package:" scheme URIs. By default it
  // is the 'packages' directory right next to the script.
  Uri _packageRoot = null;

  // The map describing how certain package names are mapped to Uris.
  Uri _packageConfig = null;
  Map<String, Uri> _packageMap = null;

  // We issue only 16 concurrent calls to File.readAsBytes() to stay within
  // platform-specific resource limits (e.g. max open files). The rest go on
  // _fileRequestQueue and are processed when we can safely issue them.
  static const int _maxFileRequests = 16;
  int currentFileRequests = 0;
  final List<FileRequest> _fileRequestQueue = new List<FileRequest>();

  bool get shouldIssueFileRequest => currentFileRequests < _maxFileRequests;
  void enqueueFileRequest(FileRequest fr) {
    _fileRequestQueue.add(fr);
  }

  FileRequest dequeueFileRequest() {
    if (_fileRequestQueue.length == 0) {
      return null;
    }
    return _fileRequestQueue.removeAt(0);
  }

  _setPackageRoot(String packageRoot) {
    packageRoot = _sanitizeWindowsPath(packageRoot);
    if (packageRoot.startsWith('file:') ||
        packageRoot.startsWith('http:') ||
        packageRoot.startsWith('https:')) {
      packageRoot = _enforceTrailingSlash(packageRoot);
      _packageRoot = _workingDirectory.resolve(packageRoot);
    } else {
      packageRoot = _sanitizeWindowsPath(packageRoot);
      packageRoot = _trimWindowsPath(packageRoot);
      _packageRoot =
          _workingDirectory.resolveUri(new Uri.directory(packageRoot));
    }
  }

  _setPackagesConfig(String packagesParam) {
    var packagesName = _sanitizeWindowsPath(packagesParam);
    var packagesUri = Uri.parse(packagesName);
    if (packagesUri.scheme == '') {
      // Script does not have a scheme, assume that it is a path,
      // resolve it against the working directory.
      packagesUri = _workingDirectory.resolveUri(packagesUri);
    }
    _requestPackagesMap(packagesUri);
    _pendingPackageLoads.add(() {
      // Dummy action.
    });
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

  // A list of callbacks which should be invoked after the package map has been
  // loaded.
  List<Function> _pendingPackageLoads = [];

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
    if (_packageError != null) {
      if (_traceLoading) {
        _log("Resolving package with pending resolution error: $_packageError");
      }
      throw _packageError;
    } else if (_packageRoot != null) {
      resolvedUri = _packageRoot.resolve(uri.path);
    } else {
      if (packageNameEnd < 0) {
        // Package URIs must have a path after the package name, even if it's
        // just "/".
        throw "URIS using the 'package:' scheme should look like "
            "'package:${uri.path}/', not 'package:${uri.path}'";
      }
      var packageName = uri.path.substring(0, packageNameEnd);
      var mapping = _packageMap[packageName];
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

  RawReceivePort _packagesPort;

  void _requestPackagesMap([Uri packageConfig]) {
    assert(_rootScript != null);
    if (_packagesPort != null) {
      // Already scheduled.
      return;
    }
    // Create a port to receive the packages map on.
    _packagesPort = new RawReceivePort(_handlePackagesReply);
    var sp = _packagesPort.sendPort;

    if (packageConfig != null) {
      // Explicitly specified .packages path.
      _handlePackagesRequest(sp, _traceLoading, -2, packageConfig);
    } else {
      // Search for .packages or packages/ starting at the root script.
      _handlePackagesRequest(sp, _traceLoading, -1, _rootScript);
    }

    if (_traceLoading) {
      _log("Requested packages map for '$_rootScript'.");
    }
  }

  void _handlePackagesReply(msg) {
    if (_packagesPort == null) {
      return;
    }
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
        for (var i = 2; i < msg.length; i += 2) {
          // TODO(iposva): Complain about duplicate entries.
          _packageMap[msg[i]] = Uri.parse(msg[i + 1]);
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
  }
}

_log(msg) {
  print("% $msg");
}

var _httpClient;

// Send a response to the requesting isolate.
void _sendResourceResponse(SendPort sp, int tag, Uri uri, Uri resolvedUri,
    String libraryUrl, dynamic data) {
  assert((data is List<int>) || (data is String));
  var msg = new List(5);
  if (data is String) {
    // We encountered an error, flip the sign of the tag to indicate that.
    tag = -tag;
    if (libraryUrl == null) {
      data = 'Could not load "$uri": $data';
    } else {
      data = 'Could not import "$uri" from "$libraryUrl": $data';
    }
  }
  msg[0] = tag;
  msg[1] = uri.toString();
  msg[2] = resolvedUri.toString();
  msg[3] = libraryUrl;
  msg[4] = data;
  sp.send(msg);
}

// Send a response to the requesting isolate.
void _sendExtensionImportResponse(
    SendPort sp, Uri uri, String libraryUrl, String resolvedUri) {
  var msg = new List(5);
  int tag = _Dart_kImportExtension;
  if (resolvedUri == null) {
    // We could not resolve the dart-ext: uri.
    tag = -tag;
    resolvedUri = 'Could not resolve "$uri" from "$libraryUrl"';
  }
  msg[0] = tag;
  msg[1] = uri.toString();
  msg[2] = resolvedUri;
  msg[3] = libraryUrl;
  msg[4] = resolvedUri;
  sp.send(msg);
}

void _loadHttp(
    SendPort sp, int tag, Uri uri, Uri resolvedUri, String libraryUrl) {
  if (_httpClient == null) {
    _httpClient = new HttpClient()..maxConnectionsPerHost = 6;
  }
  _httpClient
      .getUrl(resolvedUri)
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
    var builder = new BytesBuilder(copy: false);
    response.listen(builder.add, onDone: () {
      if (response.statusCode != 200) {
        var msg = "Failure getting $resolvedUri:\n"
            "  ${response.statusCode} ${response.reasonPhrase}";
        _sendResourceResponse(sp, tag, uri, resolvedUri, libraryUrl, msg);
      } else {
        _sendResourceResponse(
            sp, tag, uri, resolvedUri, libraryUrl, builder.takeBytes());
      }
    }, onError: (e) {
      _sendResourceResponse(
          sp, tag, uri, resolvedUri, libraryUrl, e.toString());
    });
  }).catchError((e) {
    _sendResourceResponse(sp, tag, uri, resolvedUri, libraryUrl, e.toString());
  });
  // It's just here to push an event on the event loop so that we invoke the
  // scheduled microtasks.
  Timer.run(() {});
}

void _loadFile(IsolateLoaderState loaderState, SendPort sp, int tag, Uri uri,
    Uri resolvedUri, String libraryUrl) {
  var path = resolvedUri.toFilePath();
  var sourceFile = new File(path);
  sourceFile.readAsBytes().then((data) {
    _sendResourceResponse(sp, tag, uri, resolvedUri, libraryUrl, data);
  }, onError: (e) {
    _sendResourceResponse(sp, tag, uri, resolvedUri, libraryUrl, e.toString());
  }).whenComplete(() {
    loaderState.currentFileRequests--;
    while (loaderState.shouldIssueFileRequest) {
      FileRequest fr = loaderState.dequeueFileRequest();
      if (fr == null) {
        break;
      }
      _loadFile(
          loaderState, fr.sp, fr.tag, fr.uri, fr.resolvedUri, fr.libraryUrl);
      loaderState.currentFileRequests++;
    }
  });
}

void _loadDataUri(
    SendPort sp, int tag, Uri uri, Uri resolvedUri, String libraryUrl) {
  try {
    var mime = uri.data.mimeType;
    if ((mime != "application/dart") && (mime != "text/plain")) {
      throw "MIME-type must be application/dart or text/plain: $mime given.";
    }
    var charset = uri.data.charset;
    if ((charset != "utf-8") && (charset != "US-ASCII")) {
      // The C++ portion of the embedder assumes UTF-8.
      throw "Only utf-8 or US-ASCII encodings are supported: $charset given.";
    }
    _sendResourceResponse(
        sp, tag, uri, resolvedUri, libraryUrl, uri.data.contentAsBytes());
  } catch (e) {
    _sendResourceResponse(sp, tag, uri, resolvedUri, libraryUrl,
        "Invalid data uri ($uri):\n  $e");
  }
}

// Loading a package URI needs to first map the package name to a loadable
// URI.
_loadPackage(IsolateLoaderState loaderState, SendPort sp, bool traceLoading,
    int tag, Uri uri, Uri resolvedUri, String libraryUrl) {
  if (loaderState._packagesReady) {
    var resolvedUri;
    try {
      resolvedUri = loaderState._resolvePackageUri(uri);
    } catch (e, s) {
      if (traceLoading) {
        _log("Exception ($e) when resolving package URI: $uri");
      }
      // Report error.
      _sendResourceResponse(
          sp, tag, uri, resolvedUri, libraryUrl, e.toString());
      return;
    }
    // Recursively call with the new resolved uri.
    _handleResourceRequest(
        loaderState, sp, traceLoading, tag, uri, resolvedUri, libraryUrl);
  } else {
    if (loaderState._pendingPackageLoads.isEmpty) {
      // Package resolution has not been setup yet, and this is the first
      // request for package resolution & loading.
      loaderState._requestPackagesMap();
    }
    // Register the action of loading this package once the package resolution
    // is ready.
    loaderState._pendingPackageLoads.add(() {
      _handleResourceRequest(
          loaderState, sp, traceLoading, tag, uri, uri, libraryUrl);
    });
    if (traceLoading) {
      _log("Pending package load of '$uri': "
          "${loaderState._pendingPackageLoads.length} pending");
    }
  }
}

// TODO(johnmccutchan): This and most other top level functions in this file
// should be turned into methods on the IsolateLoaderState class.
_handleResourceRequest(IsolateLoaderState loaderState, SendPort sp,
    bool traceLoading, int tag, Uri uri, Uri resolvedUri, String libraryUrl) {
  if (resolvedUri.scheme == '' || resolvedUri.scheme == 'file') {
    if (loaderState.shouldIssueFileRequest) {
      _loadFile(loaderState, sp, tag, uri, resolvedUri, libraryUrl);
      loaderState.currentFileRequests++;
    } else {
      FileRequest fr = new FileRequest(sp, tag, uri, resolvedUri, libraryUrl);
      loaderState.enqueueFileRequest(fr);
    }
  } else if ((resolvedUri.scheme == 'http') ||
      (resolvedUri.scheme == 'https')) {
    _loadHttp(sp, tag, uri, resolvedUri, libraryUrl);
  } else if ((resolvedUri.scheme == 'data')) {
    _loadDataUri(sp, tag, uri, resolvedUri, libraryUrl);
  } else if ((resolvedUri.scheme == 'package')) {
    _loadPackage(
        loaderState, sp, traceLoading, tag, uri, resolvedUri, libraryUrl);
  } else {
    _sendResourceResponse(
        sp,
        tag,
        uri,
        resolvedUri,
        libraryUrl,
        'Unknown scheme (${resolvedUri.scheme}) for '
        '$resolvedUri');
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

_parsePackagesFile(
    SendPort sp, bool traceLoading, Uri packagesFile, List<int> data) {
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
      sp.send("Missing package name in $packagesFile:\n"
          "$line");
      return;
    }

    // Ensure there is a separator on the line.
    if (separator == -1) {
      var line = new String.fromCharCodes(data, start, end);
      if (traceLoading) {
        _log("Line has no ':' in $packagesFile:\n"
            "$line");
      }
      sp.send("Missing ':' separator in $packagesFile:\n"
          "$line");
      return;
    }

    var packageName = new String.fromCharCodes(data, start, separator);

    // Check for valid package name.
    if (invalidPackageName || !nonDot) {
      var line = new String.fromCharCodes(data, start, end);
      if (traceLoading) {
        _log("Invalid package name $packageName in $packagesFile");
      }
      sp.send("Invalid package name '$packageName' in $packagesFile:\n"
          "$line");
      return;
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
  sp.send(result);
}

_loadPackagesFile(SendPort sp, bool traceLoading, Uri packagesFile) async {
  try {
    var data = await new File.fromUri(packagesFile).readAsBytes();
    if (traceLoading) {
      _log("Loaded packages file from $packagesFile:\n"
          "${new String.fromCharCodes(data)}");
    }
    _parsePackagesFile(sp, traceLoading, packagesFile, data);
  } catch (e, s) {
    if (traceLoading) {
      _log("Error loading packages: $e\n$s");
    }
    sp.send("Uncaught error ($e) loading packages file.");
  }
}

_findPackagesFile(SendPort sp, bool traceLoading, Uri base) async {
  try {
    // Walk up the directory hierarchy to check for the existence of
    // .packages files in parent directories and for the existense of a
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
      var exists = await new File.fromUri(packagesFile).exists();
      if (traceLoading) {
        _log("$packagesFile exists: $exists");
      }
      if (exists) {
        _loadPackagesFile(sp, traceLoading, packagesFile);
        return;
      }
      // On the first loop try whether there is a packages/ directory instead.
      if (prev == null) {
        var packageRoot = dirUri.resolve("packages/");
        if (traceLoading) {
          _log("Checking for $packageRoot directory.");
        }
        exists = await new Directory.fromUri(packageRoot).exists();
        if (traceLoading) {
          _log("$packageRoot exists: $exists");
        }
        if (exists) {
          if (traceLoading) {
            _log("Found a package root at: $packageRoot");
          }
          sp.send([packageRoot.toString()]);
          return;
        }
      }
      // Move up one level.
      prev = dir;
      dir = dir.parent;
    }

    // No .packages file was found.
    if (traceLoading) {
      _log("Could not resolve a package location from $base");
    }
    sp.send("Could not resolve a package location for base at $base");
  } catch (e, s) {
    if (traceLoading) {
      _log("Error loading packages: $e\n$s");
    }
    sp.send("Uncaught error ($e) loading packages file.");
  }
}

Future<bool> _loadHttpPackagesFile(
    SendPort sp, bool traceLoading, Uri resource) async {
  try {
    if (_httpClient == null) {
      _httpClient = new HttpClient()..maxConnectionsPerHost = 6;
    }
    if (traceLoading) {
      _log("Fetching packages file from '$resource'.");
    }
    var req = await _httpClient.getUrl(resource);
    var rsp = await req.close();
    var builder = new BytesBuilder(copy: false);
    await for (var bytes in rsp) {
      builder.add(bytes);
    }
    if (rsp.statusCode != 200) {
      if (traceLoading) {
        _log("Got status ${rsp.statusCode} fetching '$resource'.");
      }
      return false;
    }
    var data = builder.takeBytes();
    if (traceLoading) {
      _log("Loaded packages file from '$resource':\n"
          "${new String.fromCharCodes(data)}");
    }
    _parsePackagesFile(sp, traceLoading, resource, data);
  } catch (e, s) {
    if (traceLoading) {
      _log("Error loading packages file from '$resource': $e\n$s");
    }
    sp.send("Uncaught error ($e) loading packages file from '$resource'.");
  }
  return false;
}

_loadPackagesData(sp, traceLoading, resource) {
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
    _parsePackagesFile(sp, traceLoading, resource, data.contentAsBytes());
  } catch (e) {
    sp.send("Uncaught error ($e) loading packages data.");
  }
}

// This code used to exist in a second isolate and so it uses a SendPort to
// report it's return value. This could be refactored so that it returns it's
// value and the caller could wait on the future rather than a message on
// SendPort.
_handlePackagesRequest(
    SendPort sp, bool traceLoading, int tag, Uri resource) async {
  try {
    if (tag == -1) {
      if (resource.scheme == '' || resource.scheme == 'file') {
        _findPackagesFile(sp, traceLoading, resource);
      } else if ((resource.scheme == 'http') || (resource.scheme == 'https')) {
        // Try to load the .packages file next to the resource.
        var packagesUri = resource.resolve(".packages");
        var exists = await _loadHttpPackagesFile(sp, traceLoading, packagesUri);
        if (!exists) {
          // If the loading of the .packages file failed for http/https based
          // scripts then setup the package root.
          var packageRoot = resource.resolve('packages/');
          sp.send([packageRoot.toString()]);
        }
      } else {
        sp.send("Unsupported scheme used to locate .packages file: "
            "'$resource'.");
      }
    } else if (tag == -2) {
      if (traceLoading) {
        _log("Handling load of packages map: '$resource'.");
      }
      if (resource.scheme == '' || resource.scheme == 'file') {
        var exists = await new File.fromUri(resource).exists();
        if (exists) {
          _loadPackagesFile(sp, traceLoading, resource);
        } else {
          sp.send("Packages file '$resource' not found.");
        }
      } else if ((resource.scheme == 'http') || (resource.scheme == 'https')) {
        var exists = await _loadHttpPackagesFile(sp, traceLoading, resource);
        if (!exists) {
          sp.send("Packages file '$resource' not found.");
        }
      } else if (resource.scheme == 'data') {
        _loadPackagesData(sp, traceLoading, resource);
      } else {
        sp.send("Unknown scheme (${resource.scheme}) for package file at "
            "'$resource'.");
      }
    } else {
      sp.send("Unknown packages request tag: $tag for '$resource'.");
    }
  } catch (e, s) {
    if (traceLoading) {
      _log("Error handling packages request: $e\n$s");
    }
    sp.send("Uncaught error ($e) handling packages request.");
  }
}

// Shutdown all active loaders by sending an error message.
void shutdownLoaders() {
  String message = 'Service shutdown';
  if (_httpClient != null) {
    _httpClient.close(force: true);
    _httpClient = null;
  }
  isolateEmbedderData.values.toList().forEach((IsolateLoaderState ils) {
    ils.cleanup();
    assert(ils.sp != null);
    _sendResourceResponse(ils.sp, 1, null, null, null, message);
  });
}

// See Dart_LibraryTag in dart_api.h
const _Dart_kCanonicalizeUrl = 0; // Canonicalize the URL.
const _Dart_kScriptTag = 1; // Load the root script.
const _Dart_kSourceTag = 2; // Load a part source.
const _Dart_kImportTag = 3; // Import a library.

// Extra requests. Keep these in sync between loader.dart and builtin.dart.
const _Dart_kInitLoader = 4; // Initialize the loader.
const _Dart_kResourceLoad = 5; // Resource class support.
const _Dart_kGetPackageRootUri = 6; // Uri of the packages/ directory.
const _Dart_kGetPackageConfigUri = 7; // Uri of the .packages file.
const _Dart_kResolvePackageUri = 8; // Resolve a package: uri.

// Extra requests. Keep these in sync between loader.dart and loader.cc.
const _Dart_kImportExtension = 9; // Import a dart-ext: file.
const _Dart_kResolveAsFilePath = 10; // Resolve uri to file path.

// External entry point for loader requests.
_processLoadRequest(request) {
  assert(request is List);
  assert(request.length > 4);

  // Should we trace loading?
  bool traceLoading = request[0];

  // This is the sending isolate's Dart_GetMainPortId().
  int isolateId = request[1];

  // The tag describing the operation.
  int tag = request[2];

  // The send port to send the response on.
  SendPort sp = request[3];

  // Grab the loader state for the requesting isolate.
  IsolateLoaderState loaderState = isolateEmbedderData[isolateId];

  // We are either about to initialize the loader, or, we already have.
  assert((tag == _Dart_kInitLoader) || (loaderState != null));

  // Handle the request specified in the tag.
  switch (tag) {
    case _Dart_kScriptTag:
      {
        Uri uri = Uri.parse(request[4]);
        // Remember the root script.
        loaderState._rootScript = uri;
        _handleResourceRequest(
            loaderState, sp, traceLoading, tag, uri, uri, null);
      }
      break;
    case _Dart_kSourceTag:
    case _Dart_kImportTag:
      {
        // The url of the file being loaded.
        var uri = Uri.parse(request[4]);
        // The library that is importing/parting the file.
        String libraryUrl = request[5];
        _handleResourceRequest(
            loaderState, sp, traceLoading, tag, uri, uri, libraryUrl);
      }
      break;
    case _Dart_kInitLoader:
      {
        String packageRoot = request[4];
        String packagesFile = request[5];
        String workingDirectory = request[6];
        String rootScript = request[7];
        bool isReloading = request[8];
        if (loaderState == null) {
          loaderState = new IsolateLoaderState(isolateId);
          isolateEmbedderData[isolateId] = loaderState;
          loaderState.init(
              packageRoot, packagesFile, workingDirectory, rootScript);
        } else if (isReloading) {
          loaderState.updatePackageMap(packagesFile);
        }
        loaderState.sp = sp;
        assert(isolateEmbedderData[isolateId] == loaderState);
      }
      break;
    case _Dart_kResourceLoad:
      {
        Uri uri = Uri.parse(request[4]);
        _handleResourceRequest(
            loaderState, sp, traceLoading, tag, uri, uri, null);
      }
      break;
    case _Dart_kGetPackageRootUri:
      loaderState._triggerPackageResolution(() {
        // Respond with the package root (if any) after package resolution.
        sp.send(loaderState._packageRoot);
      });
      break;
    case _Dart_kGetPackageConfigUri:
      loaderState._triggerPackageResolution(() {
        // Respond with the packages config (if any) after package resolution.
        sp.send(loaderState._packageConfig);
      });
      break;
    case _Dart_kResolvePackageUri:
      Uri uri = Uri.parse(request[4]);
      loaderState._triggerPackageResolution(() {
        // Respond with the resolved package uri after package resolution.
        Uri resolvedUri;
        try {
          resolvedUri = loaderState._resolvePackageUri(uri);
        } catch (e, s) {
          if (traceLoading) {
            _log("Exception ($e) when resolving package URI: $uri");
          }
          resolvedUri = null;
        }
        sp.send(resolvedUri);
      });
      break;
    case _Dart_kImportExtension:
      Uri uri = Uri.parse(request[4]);
      String libraryUri = request[5];
      // Strip any filename off of the libraryUri's path.
      int index = libraryUri.lastIndexOf('/');
      var path;
      if (index == -1) {
        path = './';
      } else {
        path = libraryUri.substring(0, index + 1);
      }
      var pathUri = Uri.parse(path);
      switch (pathUri.scheme) {
        case '':
        case 'file':
          _sendExtensionImportResponse(
              sp, uri, libraryUri, pathUri.toFilePath());
          break;
        case 'data':
        case 'http':
        case 'https':
          _sendExtensionImportResponse(sp, uri, libraryUri, pathUri.toString());
          break;
        case 'package':
          // Start package resolution.
          loaderState._triggerPackageResolution(() {
            // Attempt to find the fully resolved uri of [path].
            Uri resolvedUri;
            try {
              resolvedUri = loaderState._resolvePackageUri(pathUri);
            } catch (e, s) {
              if (traceLoading) {
                _log("Exception ($e) when resolving package URI: $uri");
              }
              resolvedUri = null;
            }
            _sendExtensionImportResponse(
                sp, uri, libraryUri, resolvedUri.toString());
          });
          break;
        default:
          if (traceLoading) {
            _log('Unknown scheme (${pathUri.scheme}) in $pathUri.');
          }
          _sendExtensionImportResponse(sp, uri, libraryUri, null);
          break;
      }
      break;
    case _Dart_kResolveAsFilePath:
      loaderState._triggerPackageResolution(() {
        String uri = request[4];
        Uri resolvedUri = Uri.parse(_sanitizeWindowsPath(uri));
        try {
          if (resolvedUri.scheme == 'package') {
            resolvedUri = loaderState._resolvePackageUri(resolvedUri);
          }
          if (resolvedUri.scheme == '' || resolvedUri.scheme == 'file') {
            resolvedUri = loaderState._workingDirectory.resolveUri(resolvedUri);
            var msg = new List(5);
            msg[0] = tag;
            msg[1] = uri;
            msg[2] = resolvedUri.toString();
            msg[3] = null;
            msg[4] = resolvedUri.toFilePath();
            sp.send(msg);
          } else {
            throw "Cannot resolve scheme (${resolvedUri.scheme}) to file path"
                " for $resolvedUri";
          }
        } catch (e) {
          var msg = new List(5);
          msg[0] = -tag;
          msg[1] = uri;
          msg[2] = resolvedUri.toString();
          msg[3] = null;
          msg[4] = e.toString();
          sp.send(msg);
        }
      });
      break;
    default:
      _log('Unknown loader request tag=$tag from $isolateId');
  }
}
