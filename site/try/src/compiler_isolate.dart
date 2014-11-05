// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler_isolate;

import 'dart:async';
import 'dart:html';
import 'dart:isolate';
import 'dart:convert' show JSON;

import 'compilation.dart' show PRIVATE_SCHEME;

import 'package:compiler/compiler.dart' as compiler;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    reuseCompiler;

import 'package:compiler/implementation/dart2jslib.dart' show
    Compiler;

const bool THROW_ON_ERROR = false;

final cachedSources = new Map<Uri, Future<String>>();

Uri sdkLocation;
List options = [];

var communicateViaBlobs;

var cachedCompiler;

void notifyDartHtml(SendPort port) {
  // Notify the controlling isolate (Try Dart UI) that the program imports
  // dart:html. This is used to determine how to run the program: in an iframe
  // or in a worker.
  port.send('dart:html');
}

compile(source, SendPort replyTo) {
  if (sdkLocation == null) {
    // The first message received gives us the URI of this web app.
    if (source.endsWith('/sdk.json')) {
      var request = new HttpRequest();
      request.open('GET', source, async: false);
      request.send(null);
      if (request.status != 200) {
        throw 'SDK not found at $source';
      }
      sdkLocation = Uri.parse('sdk:/sdk/');
      JSON.decode(request.responseText).forEach((file, content) {
        cachedSources[Uri.parse(file)] = new Future<String>.value(content);
      });
    } else {
      sdkLocation = Uri.parse(source);
    }
    replyTo.send(null);
    return;
  }
  if (source is List) {
    String messageType = (source.length > 0) ? source[0] : null;
    var data = (source.length > 1) ? source[1] : null;
    if (messageType == 'options') {
      options = data as List;
    } if (messageType == 'communicateViaBlobs') {
      communicateViaBlobs = data as bool;
    }
    return;
  }
  int charactersRead = 0;
  Future<String> inputProvider(Uri uri) {
    Future<String> future;
    if (uri.scheme == 'sdk') {
      if (uri.path.endsWith('/lib/html/dart2js/html_dart2js.dart')) {
        notifyDartHtml(replyTo);
      }
      future = cachedSources[uri];
    } else if (uri.scheme == 'http' || uri.scheme == 'https') {
      future =
          cachedSources.putIfAbsent(uri, () => HttpRequest.getString('$uri'));
    } else if ('$uri' == '$PRIVATE_SCHEME:/main.dart') {
      future = new Future<String>.value(source);
    } else if (uri.scheme == PRIVATE_SCHEME) {
      future = HttpRequest.getString('project${uri.path}');
    }
    if (future == null) {
      future = new Future<String>.error('$uri: Not found');
    }
    return future.then((String value) {
      charactersRead += value.length;
      return value;
    }).catchError((Event event) {
      var target = event.target;
      if (target is HttpRequest) {
        throw '$uri: ${target.statusText}';
      } else {
        throw event;
      }
    }, test: (error) => error is Event);
  }
  void handler(Uri uri, int begin, int end,
               String message, compiler.Diagnostic kind) {
    replyTo.send(['diagnostic', { 'uri': '$uri',
                                  'begin': begin,
                                  'end': end,
                                  'message': message,
                                  'kind': kind.name }]);
    if (THROW_ON_ERROR && kind == compiler.Diagnostic.ERROR) {
      throw new Exception('Throw on error');
    }
  }
  Stopwatch compilationTimer = new Stopwatch()..start();
  reuseCompiler(
      diagnosticHandler: handler,
      inputProvider: inputProvider,
      options: options,
      cachedCompiler: cachedCompiler,
      libraryRoot: sdkLocation,
      packageRoot: Uri.base.resolve('/packages/'),
      packagesAreImmutable: true).then((Compiler newCompiler) {
    cachedCompiler = newCompiler;
    return cachedCompiler.run(Uri.parse('$PRIVATE_SCHEME:/main.dart'));
  }).then((success) {
    compilationTimer.stop();
    print('Compilation took ${compilationTimer.elapsed}');
    if (cachedCompiler.libraryLoader
            .lookupLibrary(Uri.parse('dart:html')) != null) {
      notifyDartHtml(replyTo);
    }
    String js = cachedCompiler.assembledCode;
    if (js == null) {
      if (!options.contains('--analyze-only')) replyTo.send('failed');
    } else {
      var url;
      handler(null, 0, 0,
              'Compiled ${source.length}/${charactersRead} characters Dart'
              ' -> ${js.length} characters.',
              compiler.Diagnostic.VERBOSE_INFO);
      if (communicateViaBlobs) {
        try {
          // At least Safari and Firefox do not support creating an
          // object URL from a web worker.  MDN claims that it will be
          // supported in Firefox 21.
          url = Url.createObjectUrl(new Blob([js], 'application/javascript'));
        } catch (_) {
          // Ignored.
        }
      } else  {
        url = null;
      }
      if (url != null) {
        replyTo.send(['url', url]);
      } else {
        replyTo.send(['code', js]);
      }
    }
  }).catchError((e, trace) {
    replyTo.send(['crash', '$e, $trace']);
  }).whenComplete(() {
    replyTo.send('done');
  });
}

void main(List<String> arguments, SendPort port) {
  ReceivePort replyTo = new ReceivePort();
  port.send(replyTo.sendPort);
  replyTo.listen((message) {
    try {
      List list = message as List;
      compile(list[0], list[1]);
    } catch (exception, stack) {
      port.send('$exception\n$stack');
    }
  });
}
