// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice_io;

_log(msg) {
  print("% $msg");
}

var _httpClient;

// Send a response to the requesting isolate.
void _sendResourceResponse(SendPort sp, int id, dynamic data) {
  assert((data is List<int>) || (data is String));
  var msg = new List(2);
  msg[0] = id;
  msg[1] = data;
  sp.send(msg);
}

void _loadHttp(SendPort sp, int id, Uri uri) {
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
              var msg = "Failure getting $uri:\n"
                        "  ${response.statusCode} ${response.reasonPhrase}";
              _sendResourceResponse(sp, id, msg);
            } else {
              _sendResourceResponse(sp, id, builder.takeBytes());
            }
          },
          onError: (e) {
            _sendResourceResponse(sp, id, e.toString());
          });
    })
    .catchError((e) {
      _sendResourceResponse(sp, id, e.toString());
    });
  // It's just here to push an event on the event loop so that we invoke the
  // scheduled microtasks.
  Timer.run(() {});
}

void _loadFile(SendPort sp, int id, Uri uri) {
  var path = uri.toFilePath();
  var sourceFile = new File(path);
  sourceFile.readAsBytes().then((data) {
    _sendResourceResponse(sp, id, data);
  },
  onError: (e) {
    var err = "Error loading $uri:\n  $e";
    _sendResourceResponse(sp, id, err);
  });
}

var dataUriRegex = new RegExp(
    r"data:([\w-]+/[\w-]+)?(;charset=([\w-]+))?(;base64)?,(.*)");

void _loadDataUri(SendPort sp, int id, Uri uri) {
  try {
    var match = dataUriRegex.firstMatch(uri.toString());
    if (match == null) throw "Malformed data uri";

    var mimeType = match.group(1);
    var encoding = match.group(3);
    var maybeBase64 = match.group(4);
    var encodedData = match.group(5);

    if (mimeType != "application/dart") {
      throw "MIME-type must be application/dart";
    }
    if (encoding != "utf-8") {
      // Default is ASCII. The C++ portion of the embedder assumes UTF-8.
      throw "Only utf-8 encoding is supported";
    }
    if (maybeBase64 != null) {
      throw "Only percent encoding is supported";
    }

    var data = UTF8.encode(Uri.decodeComponent(encodedData));
    _sendResourceResponse(sp, id, data);
  } catch (e) {
    _sendResourceResponse(sp, id, "Invalid data uri ($uri):\n  $e");
  }
}

_handleResourceRequest(SendPort sp, bool traceLoading, int id, Uri resource) {
  if (resource.scheme == 'file') {
    _loadFile(sp, id, resource);
  } else if ((resource.scheme == 'http') || (resource.scheme == 'https')) {
    _loadHttp(sp, id, resource);
  } else if ((resource.scheme == 'data')) {
    _loadDataUri(sp, id, resource);
  } else {
    _sendResourceResponse(sp, id,
                          'Unknown scheme (${resource.scheme}) for $resource');
  }
}


// Handling of packages requests. Finding and parsing of .packages file or
// packages/ directories.
const _LF    = 0x0A;
const _CR    = 0x0D;
const _SPACE = 0x20;
const _HASH  = 0x23;
const _DOT   = 0x2E;
const _COLON = 0x3A;
const _DEL   = 0x7F;

const _invalidPackageNameChars = const [
  // space  !      "      #      $      %      &      '
     true , false, true , true , false, true , false, false,
  // (      )      *      +      ,      -      .      /
     false, false, false, false, false, false, false, true ,
  // 0      1      2      3      4      5      6      7
     false, false, false, false, false, false, false, false,
  // 8      9      :      ;      <      =      >      ?
     false, false, true , false, true , false, true , true ,
  // @      A      B      C      D      E      F      G
     false, false, false, false, false, false, false, false,
  // H      I      J      K      L      M      N      O
     false, false, false, false, false, false, false, false,
  // P      Q      R      S      T      U      V      W
     false, false, false, false, false, false, false, false,
  // X      Y      Z      [      \      ]      ^      _
     false, false, false, true , true , true , true , false,
  // `      a      b      c      d      e      f      g
     true , false, false, false, false, false, false, false,
  // h      i      j      k      l      m      n      o
     false, false, false, false, false, false, false, false,
  // p      q      r      s      t      u      v      w
     false, false, false, false, false, false, false, false,
  // x      y      z      {      |      }      ~      DEL
     false, false, false, true , true , true , false, true
];

_parsePackagesFile(SendPort sp,
                   bool traceLoading,
                   Uri packagesFile,
                   List<int> data) {
  var result = [];
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
                               (char < _SPACE) || (char > _DEL) ||
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
    sp.send("Uncaught error ($e) loading packags file.");
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


Future<bool> _loadHttpPackagesFile(SendPort sp,
                                   bool traceLoading,
                                   Uri resource) async {
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

_handlePackagesRequest(SendPort sp,
                       bool traceLoading,
                       int id,
                       Uri resource) async {
  try {
    if (id == -1) {
      if (resource.scheme == 'file') {
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
    } else if (id == -2) {
      if (traceLoading) {
        _log("Handling load of packages map: '$resource'.");
      }
      if (resource.scheme == 'file') {
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
      } else {
        sp.send("Unknown scheme (${resource.scheme}) for package file at "
                "'$resource'.");
      }
    } else {
      sp.send("Unknown packages request id: $id for '$resource'.");
    }
  } catch (e, s) {
    if (traceLoading) {
      _log("Error handling packages request: $e\n$s");
    }
    sp.send("Uncaught error ($e) handling packages request.");
  }
}


// External entry point for loader requests.
_processLoadRequest(request) {
  SendPort sp = request[0];
  assert(sp != null);
  bool traceLoading = request[1];
  assert(traceLoading != null);
  int id = request[2];
  assert(id != null);
  String resource = request[3];
  assert(resource != null);
  var uri = Uri.parse(resource);
  if (id >= 0) {
    _handleResourceRequest(sp, traceLoading, id, uri);
  } else {
    _handlePackagesRequest(sp, traceLoading, id, uri);
  }
}
