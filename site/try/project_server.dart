// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.projectServer;

import 'dart:io';

import 'dart:async' show
    Future,
    Stream;

import 'dart:convert' show
    HtmlEscape,
    JSON,
    UTF8;

class WatchHandler {
  final WebSocket socket;

  final Set<String> watchedFiles;

  static final Set<WatchHandler> handlers = new Set<WatchHandler>();

  static const Map<int, String> fsEventNames = const <int, String>{
    FileSystemEvent.CREATE: 'create',
    FileSystemEvent.DELETE: 'delete',
    FileSystemEvent.MODIFY: 'modify',
    FileSystemEvent.MOVE: 'move',
  };

  WatchHandler(this.socket, Iterable<String> watchedFiles)
      : this.watchedFiles = watchedFiles.toSet();

  handleFileSystemEvent(FileSystemEvent event) {
    if (event.isDirectory) return;
    String type = fsEventNames[event.type];
    if (type == null) type = 'unknown';
    String path = new Uri.file(event.path).pathSegments.last;
    shouldIgnore(type, path).then((bool ignored) {
      if (ignored) return;
      socket.add(JSON.encode({type: [path]}));
    });
  }

  Future<bool> shouldIgnore(String type, String path) {
    switch (type) {
      case 'create':
        return new Future<bool>.value(!watchedFiles.contains(path));
      case 'delete':
        return Conversation.listProjectFiles().then((List<String> files) {
          watchedFiles
              ..retainAll(files)
              ..addAll(files);
          return watchedFiles.contains(path);
        });
      case 'modify':
        return new Future<bool>.value(false);
      default:
        print('Unhandled fs-event for $path ($type).');
        return new Future<bool>.value(true);
    }
  }

  onData(_) {
    // TODO(ahe): Move POST code here?
  }

  onDone() {
    handlers.remove(this);
  }

  static handleWebSocket(WebSocket socket) {
    Conversation.ensureProjectWatcher();
    Conversation.listProjectFiles().then((List<String> files) {
      socket.add(JSON.encode({'create': files}));
      WatchHandler handler = new WatchHandler(socket, files);
      handlers.add(handler);
      socket.listen(
          handler.onData, cancelOnError: true, onDone: handler.onDone);
    });
  }

  static onFileSystemEvent(FileSystemEvent event) {
    for (WatchHandler handler in handlers) {
      handler.handleFileSystemEvent(event);
    }
  }
}

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

  static const String GIT_TAG = 'try_dart_backup';

  static const String COMMIT_MESSAGE = """
Automated backup.

It is safe to delete tag '$GIT_TAG' if you don't need the backup.""";

  static Uri documentRoot = Uri.base;

  static Uri projectRoot = Uri.base.resolve('site/try/src/');

  static Uri packageRoot = Uri.base.resolve('sdk/lib/_internal/');

  static const List<ProjectCommand> COMMANDS = const <ProjectCommand>[
      const ProjectCommand('list', const {'list': null}, handleProjectList),
  ];

  static Stream<FileSystemEvent> projectChanges;

  static final Map<String, String> gitEnv = computeGitEnv();

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

  badRequest(String problem) {
    response.statusCode = HttpStatus.BAD_REQUEST;
    response.write(htmlInfo("Bad request",
                            "Bad request '${request.uri}': $problem"));
    response.close();
  }

  internalError(error, stack) {
    print(error);
    if (stack != null) print(stack);
    response.statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    response.write(htmlInfo("Internal Server Error",
                            "Internal Server Error: $error\n$stack"));
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

  static Future<List<String>> listProjectFiles() {
    String nativeDir = projectRoot.toFilePath();
    Directory dir = new Directory(nativeDir);
    var future = dir.list(recursive: true, followLinks: false).toList();
    return future.then((List<FileSystemEntity> entries) {
      return entries
          .map((e) => e.path)
          .where((p) => p.endsWith('.dart') && p.startsWith(nativeDir))
          .map((p) => p.substring(nativeDir.length))
          .map((p) => new Uri.file(p).path).toList();
    });
  }

  static handleProjectList(Conversation self) {
    listProjectFiles().then((List<String> files) {
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

  handleSocket() {
    if (request.uri.path == '/ws/watch') {
      WebSocketTransformer.upgrade(request).then(WatchHandler.handleWebSocket);
    } else {
      response.done
          .then(onClosed)
          .catchError(onError);
      notFound(request.uri.path);
    }
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

    String filePath = root.resolve('.$path').toFilePath();
    switch (request.method) {
      case 'GET':
        return handleGet(filePath, dartType);
      case 'POST':
        return handlePost(filePath);
      default:
        String method = const HtmlEscape().convert(request.method);
        return badRequest("Unsupported method: '$method'");
    }
  }

  void handleGet(String path, String dartType) {
    var f = new File(path);
    f.exists().then((bool exists) {
      if (!exists) return notFound(request.uri);
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

  handlePost(String path) {
    // The data is sent using a dart:html HttpRequest (aka XMLHttpRequest).
    // According to http://xhr.spec.whatwg.org/, strings are always encoded as
    // UTF-8.
    request.transform(UTF8.decoder).join().then((String data) {
      // The rest of this method is synchronous. This guarantees that we don't
      // make conflicting git changes in response to multiple POST requests.
      try {
        backup(path);
      } catch (e, stack) {
        return internalError(e, stack);
      }

      new File(path).writeAsStringSync(data);

      response
          ..statusCode = HttpStatus.OK
          ..close();
    });
  }

  // Back up the file [path] using git.
  static void backup(String path) {
    // Reset the index.
    git('read-tree', ['HEAD']);

    // Save modifications in index.
    git('update-index', ['--add', path]);

    // If the file isn't modified, don't back it up.
    if (checkGit('diff', ['--cached', '--quiet'])) return;

    String localModifications = git('write-tree');

    String tag = 'refs/tags/$GIT_TAG';
    var arguments = ['-m', COMMIT_MESSAGE, localModifications];

    if (checkGit('rev-parse',  ['-q', '--verify', tag])) {
      // The tag already exists.

      if (checkGit('diff-tree', ['--quiet', localModifications, tag])) {
        // localModifications are identical to the last backup.
        return;
      }

      // Use the tag as a parent.
      arguments = ['-p', tag]..addAll(arguments);

      String headCommit = git('rev-parse', ['HEAD']);
      String mergeBase = git('merge-base', [tag, 'HEAD']);
      if (headCommit != mergeBase) {
        arguments = ['-p', 'HEAD']..addAll(arguments);
      }
    } else {
      arguments = ['-p', 'HEAD']..addAll(arguments);
    }

    // Commit the local modifcations.
    String commit = git('commit-tree', arguments);

    // Create or update the tag.
    git('tag', ['-f', GIT_TAG, commit]);
  }

  static String git(String command,
                    [List<String> arguments = const <String> []]) {
    ProcessResult result =
        run('git', <String>[command]..addAll(arguments), gitEnv);
    if (result.exitCode != 0) {
      throw 'git error: ${result.stdout}\n${result.stderr}';
    }
    return result.stdout.trim();
  }

  static bool checkGit(String command,
                       [List<String> arguments = const <String> []]) {
    return
        run('git', <String>[command]..addAll(arguments), gitEnv).exitCode == 0;
  }

  static Map<String, String> computeGitEnv() {
    ProcessResult result = run('git', ['rev-parse', '--git-dir'], null);
    if (result.exitCode != 0) {
      throw 'git error: ${result.stdout}\n${result.stderr}';
    }
    String gitDir = result.stdout.trim();
    return <String, String>{ 'GIT_INDEX_FILE': '$gitDir/try_dart_backup' };
  }

  static ProcessResult run(String executable,
                           List<String> arguments,
                           Map<String, String> environment) {
    // print('Running $executable ${arguments.join(" ")}');
    return Process.runSync(executable, arguments, environment: environment);
  }

  static onRequest(HttpRequest request) {
    Conversation conversation = new Conversation(request, request.response);
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      conversation.handleSocket();
    } else {
      conversation.handle();
    }
  }

  static ensureProjectWatcher() {
    if (projectChanges != null) return;
    String nativeDir = projectRoot.toFilePath();
    Directory dir = new Directory(nativeDir);
    projectChanges = dir.watch();
    projectChanges.listen(WatchHandler.onFileSystemEvent);
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
<p style='white-space:pre'>$text</p>
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
