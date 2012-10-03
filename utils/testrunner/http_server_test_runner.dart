// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('server');
#import('dart:io');
#import('../../pkg/args/lib/args.dart');

/** A simple HTTP server. Currently handles serving static files. */
class HttpTestServer {
  HttpServer server;

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

  HttpTestServer(port, this.staticFileDirectory) {
    server = new HttpServer();
    server.listen("127.0.0.1", port);
    server.onError = (e) {
    };
    server.defaultRequestHandler =
      (HttpRequest request, HttpResponse response) {
        try {
          if (staticFileDirectory != null) {
            String fname = request.path;
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
              f.openInputStream().pipe(response.outputStream);
            } else {
              response.statusCode = HttpStatus.NOT_FOUND;
              response.reasonPhrase = '$path does not exist';
              response.outputStream.close();
            }
          }
        } catch(e,s) {
          response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
          response.reasonPhrase = "$e";
          response.outputStream.writeString(s.toString());
          response.outputStream.close();
        }
      };
  }

  void addHandler(Function matcher, handler) {
    if (handler is Function) {
      server.addRequestHandler(matcher, handler);
    } else {
      server.addRequestHandler(matcher, handler.onRequest);
    }
  }

  void close() {
    server.close();
  }
}

ArgParser getOptionParser() {
  var parser = new ArgParser();
  parser.addOption('port', abbr: 'p',
      help: 'Set the server listening port.',
      defaultsTo: '80');

  parser.addOption('root', abbr: 'r',
      help: 'Set the directory for static files.',
      defaultsTo: '/tmp');
  return parser;
}

main() {
  var optionsParser = getOptionParser();
  try {
    var argResults = optionsParser.parse(new Options().arguments);
    var server = new HttpTestServer(
        int.parse(argResults['port']),
        argResults['root']);
  } catch (e) {
    print(e);
    print('Usage: http_server_test_runner.dart <options>');
    print(optionsParser.getUsage());
  }
}
