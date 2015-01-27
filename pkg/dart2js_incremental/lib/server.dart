// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental.server;

import 'dart:io';

import 'dart:async' show
    Completer,
    Future,
    Stream,
    StreamController,
    StreamSubscription;

import 'dart:convert' show
    HtmlEscape,
    JSON,
    UTF8;

import 'src/options.dart';

import 'compiler.dart' show
    CompilerEvent,
    IncrementalKind,
    compile;

class Conversation {
  HttpRequest request;
  HttpResponse response;

  static const String PACKAGES_PATH = '/packages';

  static const String CONTENT_TYPE = HttpHeaders.CONTENT_TYPE;

  static Uri documentRoot = Uri.base;

  static Uri packageRoot = Uri.base.resolve('packages/');

  static Map<Uri, Future<String>> generatedFiles =
      new Map<Uri, Future<String>>();

  static Map<Uri, StreamController<String>> updateControllers =
      new Map<Uri, StreamController<String>>();

  Conversation(this.request, this.response);

  onClosed(_) {
    if (response.statusCode == HttpStatus.OK) return;
    print('Request for ${request.uri} ${response.statusCode}');
  }

  Future notFound(Uri uri) {
    response
        ..headers.set(CONTENT_TYPE, 'text/html')
        ..statusCode = HttpStatus.NOT_FOUND
        ..write(htmlInfo("Not Found", "The file '$uri' could not be found."));
    return response.close();
  }

  Future badRequest(String problem) {
    response
        ..headers.set(CONTENT_TYPE, 'text/html')
        ..statusCode = HttpStatus.BAD_REQUEST
        ..write(
            htmlInfo("Bad request", "Bad request '${request.uri}': $problem"));
    return response.close();
  }

  Future handleSocket() async {
    StreamController<String> controller = updateControllers[request.uri];
    if (controller != null) {
      WebSocket socket = await WebSocketTransformer.upgrade(request);
      print(
          "Patches to ${request.uri} will be pushed to "
          "${request.connectionInfo.remoteAddress.host}:"
          "${request.connectionInfo.remotePort}.");
      controller.stream.pipe(socket);
    } else {
      response.done
          .then(onClosed)
          .catchError(onError);
      return await notFound(request.uri);
    }
  }

  Future handle() {
    response.done
        .then(onClosed)
        .catchError(onError);

    Uri uri = request.uri;
    if (uri.path.endsWith('/')) {
      uri = uri.resolve('index.html');
    }
    if (uri.path.contains('..') || uri.path.contains('%')) {
      return notFound(uri);
    }
    String path = uri.path;
    Uri root = documentRoot;
    if (path.startsWith('${PACKAGES_PATH}/')) {
      root = packageRoot;
      path = path.substring(PACKAGES_PATH.length);
    }

    Uri resolvedRequest = root.resolve('.$path');
    switch (request.method) {
      case 'GET':
        return handleGet(resolvedRequest);
      default:
        String method = const HtmlEscape().convert(request.method);
        return badRequest("Unsupported method: '$method'");
    }
  }

  Future handleGet(Uri uri) async {
    String path = uri.path;
    var f = new File.fromUri(uri);
    if (!await f.exists()) {
      return await handleNonExistingFile(uri);
    } else {
      setContentType(path);
    }
    return await f.openRead().pipe(response);
  }

  void setContentType(String path) {
    if (path.endsWith('.html')) {
      response.headers.set(CONTENT_TYPE, 'text/html');
    } else if (path.endsWith('.dart')) {
      response.headers.set(CONTENT_TYPE, 'application/dart');
    } else if (path.endsWith('.js')) {
      response.headers.set(CONTENT_TYPE, 'application/javascript');
    } else if (path.endsWith('.ico')) {
      response.headers.set(CONTENT_TYPE, 'image/x-icon');
    } else if (path.endsWith('.appcache')) {
      response.headers.set(CONTENT_TYPE, 'text/cache-manifest');
    } else if (path.endsWith('.css')) {
      response.headers.set(CONTENT_TYPE, 'text/css');
    } else if (path.endsWith('.png')) {
      response.headers.set(CONTENT_TYPE, 'image/png');
    }
  }

  Future handleNonExistingFile(Uri uri) async {
    String path = uri.path;
    String generated = await generatedFiles[request.uri];
    if (generated != null) {
      print("Serving ${request.uri} from memory.");
      setContentType(path);
      response.write(generated);
      return await response.close();
    }
    if (path.endsWith('.dart.js')) {
      Uri dartScript = uri.resolve(path.substring(0, path.length - 3));
      if (await new File.fromUri(dartScript).exists()) {
        return await compileToJavaScript(dartScript);
      }
    }
    return await notFound(request.uri);
  }

  compileToJavaScript(Uri dartScript) {
    Uri outputUri = request.uri;
    Completer<String> completer = new Completer<String>();
    generatedFiles[outputUri] = completer.future;
    StreamController controller = updateControllers[outputUri];
    if (controller != null) {
      controller.close();
    }
    updateControllers[outputUri] = new StreamController<String>.broadcast();
    print("Compiling $dartScript to $outputUri.");
    StreamSubscription<CompilerEvent> subscription;
    subscription = compile(dartScript).listen((CompilerEvent event) {
      subscription.onData(
          (CompilerEvent event) => onCompilerEvent(completer, event));
      if (event.kind != IncrementalKind.FULL) {
        notFound(request.uri);
        // TODO(ahe): Do something about this situation.
      } else {
        print("Done compiling $dartScript to $outputUri.");
        completer.complete(event['.js']);
        setContentType(outputUri.path);
        response.write(event['.js']);
        response.close();
      }
    });
  }

  onCompilerEvent(Completer completer, CompilerEvent event) {
    Uri outputUri = request.uri;
    print("Got ${event.kind} for $outputUri");

    switch (event.kind) {
      case IncrementalKind.FULL:
        generatedFiles[outputUri] = new Future.value(event['.js']);
        break;

      case IncrementalKind.INCREMENTAL:
        generatedFiles[outputUri] = completer.future.then(
            (String full) => '$full\n\n${event.compiler.allUpdates()}');
        pushUpdates(event.updates);
        break;

      case IncrementalKind.ERROR:
        generatedFiles.removeKey(outputUri);
        break;
    }
  }

  void pushUpdates(String updates) {
    if (updates == null) return;
    StreamController<String> controller = updateControllers[request.uri];
    if (controller == null) return;
    print("Adding updates to controller");
    controller.add(updates);
  }

  Future dispatch() async {
    try {
      return await WebSocketTransformer.isUpgradeRequest(request)
          ? handleSocket()
          : handle();
    } catch (e, s) {
      onError(e, s);
    }
  }

  static Future onRequest(HttpRequest request) async {
    HttpResponse response = request.response;
    try {
      return await new Conversation(request, response).dispatch();
    } catch (e, s) {
      try {
        onStaticError(e, s);
        return await response.close();
      } catch (e, s) {
        onStaticError(e, s);
      }
    }
  }

  Future onError(error, [stack]) async {
    try {
      onStaticError(error, stack);
      return await response.close();
    } catch (e, s) {
      onStaticError(e, s);
    }
  }

  static void onStaticError(error, [stack]) {
    if (error is HttpException) {
      print('Error: ${error.message}');
    } else {
      print('Error: ${error}');
    }
    if (stack != null) {
      print(stack);
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

main(List<String> arguments) async {
  Options options = Options.parse(arguments);
  if (options == null) {
    exit(1);
  }
  if (!options.arguments.isEmpty) {
    Conversation.documentRoot = Uri.base.resolve(options.arguments.single);
  }
  Conversation.packageRoot = options.packageRoot;
  String host = options.host;
  int port = options.port;
  try {
    HttpServer server = await HttpServer.bind(host, port);
    print('HTTP server started on http://$host:${server.port}/');
    server.listen(Conversation.onRequest, onError: Conversation.onStaticError);
  } catch (e) {
    print("HttpServer.bind error: $e");
    exit(1);
  };
}
