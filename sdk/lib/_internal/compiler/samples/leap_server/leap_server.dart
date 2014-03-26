// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library leap_server;

import 'dart:io';

import 'dart:convert' show JSON, HtmlEscape;

/// Represents a "project" command. These commands are accessed from the URL
/// "/project?name".
class ProjectCommand {
  final String name;

  /// For each query parameter, this map describes rules for validating them.
  final Map<String, String> rules;

  final Function handle;

  const ProjectCommand(this.name, this.rules, this.handle);
}

class Conversation {
  HttpRequest request;
  HttpResponse response;

  static const String PROJECT_PATH = '/project';

  static const String PACKAGES_PATH = '/packages';

  static const String CONTENT_TYPE = HttpHeaders.CONTENT_TYPE;

  static Uri documentRoot = Uri.base;

  static Uri projectRoot = Uri.base.resolve('site/try/src/');

  static Uri packageRoot = Uri.base.resolve('sdk/lib/_internal/');

  static const List<ProjectCommand> COMMANDS = const <ProjectCommand>[
      const ProjectCommand('list', const {'list': null}, handleProjectList),
  ];

  Conversation(this.request, this.response);

  onClosed(_) {
    if (response.statusCode == HttpStatus.OK) return;
    print('Request for ${request.uri} ${response.statusCode}');
  }

  notFound(path) {
    response.statusCode = HttpStatus.NOT_FOUND;
    response.write(htmlInfo('Not Found',
                            'The file "$path" could not be found.'));
    response.close();
  }

  redirect(String location) {
    response.statusCode = HttpStatus.FOUND;
    response.headers.add(HttpHeaders.LOCATION, location);
    response.close();
  }

  badRequest(String problem) {
    response.statusCode = HttpStatus.BAD_REQUEST;
    response.write(htmlInfo("Bad request",
                            "Bad request '${request.uri}': $problem"));
    response.close();
  }

  bool validate(Map<String, String> parameters, Map<String, String> rules) {
    Iterable<String> problems = rules.keys
        .where((name) => !parameters.containsKey(name))
        .map((name) => "Missing parameter: '$name'.");
    if (!problems.isEmpty) {
      badRequest(problems.first);
      return false;
    }
    Set extra = new Set.from(parameters.keys)..removeAll(rules.keys);
    if (extra.isEmpty) return true;
    String extraString = (extra.toList()..sort()).join("', '");
    badRequest("Extra parameters: '$extraString'.");
    return false;
  }

  static handleProjectList(Conversation self) {
    String nativeDir = projectRoot.toFilePath();
    Directory dir = new Directory(nativeDir);
    var future = dir.list(recursive: true, followLinks: false).toList();
    future.then((List<FileSystemEntity> entries) {
      List<String> files = entries
          .map((e) => e.path)
          .where((p) => !p.endsWith('~') && p.startsWith(nativeDir))
          .map((p) => p.substring(nativeDir.length))
          .map((p) => new Uri.file(p).path).toList();
      self.response
          ..write(JSON.encode(files))
          ..close();
    });
  }

  handleProjectRequest() {
    Map<String, String> parameters = request.uri.queryParameters;
    for (ProjectCommand command in COMMANDS) {
      if (parameters.containsKey(command.name)) {
        if (validate(parameters, command.rules)) {
          (command.handle)(this);
        }
        return;
      }
    }
    String commands = COMMANDS.map((c) => c.name).join("', '");
    badRequest("Valid commands are: '$commands'");
  }

  handle() {
    response.done
      .then(onClosed)
      .catchError(onError);

    Uri uri = request.uri;
    if (uri.path == PROJECT_PATH) {
      return handleProjectRequest();
    }
    if (uri.path.endsWith('/')) {
      uri = uri.resolve('index.html');
    }
    if (uri.path == '/css/fonts/fontawesome-webfont.woff') {
      uri = uri.resolve('/fontawesome-webfont.woff');
    }
    if (uri.path.contains('..') || uri.path.contains('%')) {
      return notFound(uri.path);
    }
    String path = uri.path;
    Uri root = documentRoot;
    String dartType = 'application/dart';
    if (path.startsWith('/project/packages/')) {
      root = packageRoot;
      path = path.substring('/project/packages'.length);
    } else if (path.startsWith('${PROJECT_PATH}/')) {
      root = projectRoot;
      path = path.substring(PROJECT_PATH.length);
      dartType = 'text/plain';
    } else if (path.startsWith('${PACKAGES_PATH}/')) {
      root = packageRoot;
      path = path.substring(PACKAGES_PATH.length);
    }
    var f = new File(root.resolve('.$path').toFilePath());
    f.exists().then((bool exists) {
      if (!exists) return notFound(path);
      if (path.endsWith('.html')) {
        response.headers.set(CONTENT_TYPE, 'text/html');
      } else if (path.endsWith('.dart')) {
        response.headers.set(CONTENT_TYPE, dartType);
      } else if (path.endsWith('.js')) {
        response.headers.set(CONTENT_TYPE, 'application/javascript');
      } else if (path.endsWith('.ico')) {
        response.headers.set(CONTENT_TYPE, 'image/x-icon');
      } else if (path.endsWith('.appcache')) {
        response.headers.set(CONTENT_TYPE, 'text/cache-manifest');
      }
      f.openRead().pipe(response).catchError(onError);
    });
  }

  static onRequest(HttpRequest request) {
    new Conversation(request, request.response).handle();
  }

  static onError(error) {
    if (error is HttpException) {
      print('Error: ${error.message}');
    } else {
      print('Error: ${error}');
    }
  }

  String htmlInfo(String title, String text) {
    // No script injection, please.
    title = const HtmlEscape().convert(title);
    text = const HtmlEscape().convert(text);
    return """
<!DOCTYPE html>
<html lang='en'>
<head>
<title>$title</title>
</head>
<body>
<h1>$title</h1>
<p>$text</p>
</body>
</html>
""";
  }
}

main(List<String> arguments) {
  if (arguments.length > 0) {
    Conversation.documentRoot = Uri.base.resolve(arguments[0]);
  }
  var host = '127.0.0.1';
  if (arguments.length > 1) {
    host = arguments[1];
  }
  int port = 0;
  if (arguments.length > 2) {
    port = int.parse(arguments[2]);
  }
  if (arguments.length > 3) {
    Conversation.projectRoot = Uri.base.resolve(arguments[3]);
  }
  if (arguments.length > 4) {
    Conversation.packageRoot = Uri.base.resolve(arguments[4]);
  }
  HttpServer.bind(host, port).then((HttpServer server) {
    print('HTTP server started on http://$host:${server.port}/');
    server.listen(Conversation.onRequest, onError: Conversation.onError);
  }).catchError((e) {
    print("HttpServer.bind error: $e");
    exit(1);
  });
}
