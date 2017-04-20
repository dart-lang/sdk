// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:http_server/http_server.dart' as http_server;
import 'package:route/server.dart';
import 'package:path/path.dart';
import 'package:http_server/http_server.dart';

/*
 * This program serves a visualization of a JavaScript source map file generated
 * by dart2js or pub.
 *
 * Usage: dart source_map_viewer.dart <path to map file>.
 *
 * The default system browser is started and pointed to the viewer if
 * available.
 */

Uri sourceMapFile;

void main(List<String> args) {
  if (args.length != 1) {
    print('One argument expected; the source map file.');
    exit(-1);
    return;
  }

  File mapFile = new File(args[0]);
  if (!mapFile.existsSync()) {
    print('Map file not found at ${args[0]}');
    exit(-2);
    return;
  }

  sourceMapFile = toUri(mapFile.path);
  startServer();
}

// Sends the content of the file requested in the path parameter.
void handleFile(HttpRequest request) {
  String path = request.uri.queryParameters["path"];
  if (path == null) {
    request.response.close();
    return;
  }

  Uri uri = sourceMapFile.resolve(path);
  new File.fromUri(uri).openRead().pipe(request.response).catchError((e) {
    print("Error: $e");
    request.response.close();
  });
}

// Sends back the name of the source map file.
void handleSourceMapFile(HttpRequest request) {
  request.response.write(basename(sourceMapFile.path));
  request.response.close();
}

// Starts an HttpServer rooted in [dir] with two special routes, /file and /map.
//
// /file takes a parameter [path] and serves the content of the specified file
//  in path relative to [dir]
//
// /map serves the name of the map file such that its content can be requested
// with a /file request as above.
void startServer() {
  String root = fromUri(Platform.script.resolve('../build/web/'));
  Directory directory = new Directory(root);
  if (!directory.existsSync()) {
    print("Directory '$root' does not exist. "
        "Run 'pub build' to generate the output.");
    exit(-1);
  }

  // Use port 0 to get an ephemeral port.
  int port = 0;
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, port).then((server) {
    port = server.port;
    print("Source mapping server is running on "
        "'http://${server.address.address}:$port/'");
    Router router = new Router(server)
      ..serve('/file').listen(handleFile)
      ..serve('/map').listen(handleSourceMapFile);

    // Set up default handler. This will serve files from our 'build'
    // directory. Disable jail root, as packages are local symlinks.
    VirtualDirectory virDir = new http_server.VirtualDirectory(root)
      ..jailRoot = false
      ..allowDirectoryListing = true;

    virDir.directoryHandler = (dir, request) {
      // Redirect directory requests to index.html files.
      Uri indexUri = new Uri.file(dir.path).resolve('display.html');
      virDir.serveFile(new File(indexUri.toFilePath()), request);
    };

    // Add an error page handler.
    virDir.errorPageHandler = (HttpRequest request) {
      print("Resource not found: ${request.uri.path}");
      request.response.statusCode = HttpStatus.NOT_FOUND;
      request.response.close();
    };

    // Serve everything not routed elsewhere through the virtual directory.
    virDir.serve(router.defaultStream);

    // Start the system' default browser
    startBrowser('http://${server.address.address}:$port/');
  });
}

startBrowser(String url) {
  String command;
  if (Platform.isWindows) {
    command = 'cmd.exe /C start';
  } else if (Platform.isMacOS) {
    command = 'open';
  } else {
    String xdg = '/usr/bin/xdg-open';
    if (new File(xdg).existsSync()) {
      command = xdg;
    } else {
      command = '/usr/bin/google-chrome';
    }
  }

  print('Starting browser: ${command} ${url}');
  Process.run(command, ['$url']).then((ProcessResult result) {
    if (result.exitCode != 0) {
      print(result.stderr);
    }
  });
}
