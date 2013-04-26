// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_server;
import 'dart:io';
import 'package:args/args.dart';

/** An options parser for the server. */
ArgParser getOptionParser() {
  var parser = new ArgParser();
  parser.addOption('port', abbr: 'p',
      help: 'Set the server listening port.',
      defaultsTo: '80');

  parser.addOption('root', abbr: 'r',
      help: 'Set the directory for static files.');
  return parser;
}

/** A simple HTTP server. Currently handles serving static files. */
class HttpTestServer {
  HttpServer server;
  List<Function> matchers = [];
  List<Function> handlers = [];

  /** If set, serve up static files from this directory. */
  String staticFileDirectory;

  /* A common subset of all possible MIME types. */
  static const MIME_TYPES = const {
      'json' : 'applicaton/json',
      'js'   : 'application/javascript',
      'cgm'  : 'image/cgm',
      'g3fax': 'image/g3fax',
      'gif'  : 'image/gif',
      'jpeg' : 'image/jpeg',
      'jpg'  : 'image/jpeg',
      'png'  : 'image/png',
      'tif'  : 'image/tiff',
      'tiff' : 'image/tiff',
      'ac3'  : 'audio/ac3',
      'mp3'  : 'audio/mpeg',
      'ogg'  : 'audio/ogg',
      'css'  : 'text/css',
      'csv'  : 'text/csv',
      'htm'  : 'text/html',
      'html' : 'text/html',
      'txt'  : 'text/plain',
      'rtf'  : 'text/rtf',
      'mp4'  : 'video/mp4',
      'qt'   : 'video/quicktime',
      'vc1'  : 'video/vc1'
  };

  HttpTestServer(int port, this.staticFileDirectory) {
    HttpServer.bind("127.0.0.1", port).then((s) {
      server = s;
      print('Server listening on port $port');
      server.listen((HttpRequest request) {
        for (var i = 0; i < matchers.length; i++) {
          if (matchers[i](request)) {
            handlers[i](request);
            return;
          }
        }
        HttpResponse response = request.response;
        try {
          if (staticFileDirectory != null) {
            String fname = request.uri.path;
            String path = '$staticFileDirectory$fname';
            File f = new File(path);
            if (f.existsSync()) {
              var p = path.substring(path.lastIndexOf('.') + 1).toLowerCase();
              if (MIME_TYPES.containsKey(p)) {
                var ct = MIME_TYPES[p];
                var idx = ct.indexOf('/');
                response.headers.contentType =
                    new ContentType(ct.substring(0, idx),
                        ct.substring(idx + 1));
              }
              response.addStream(f.openRead()).then((_) => response.close());
            } else {
              response.statusCode = HttpStatus.NOT_FOUND;
              response.reasonPhrase = '$path does not exist';
              response.close();
            }
          }
        } catch(e,s) {
          response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
          response.reasonPhrase = "$e";
          response.write(s);
          response.close();
        }
      });
    });
  }

  void addHandler(Function matcher, Function handler) {
    matchers.add(matcher);
    handlers.add(handler);
  }

  void close() {
    server.close();
  }
}

