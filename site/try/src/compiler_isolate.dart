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

import 'caching_compiler.dart' show
    reuseCompiler;

const bool THROW_ON_ERROR = false;

final cachedSources = new Map<Uri, String>();

Uri sdkLocation;
List options = [];

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
        cachedSources[Uri.parse(file)] = content;
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
    }
    return;
  }
  int charactersRead = 0;
  Future<String> inputProvider(Uri uri) {
    if (uri.path.endsWith('/lib/html/dart2js/html_dart2js.dart')) {
      notifyDartHtml(replyTo);
    }
    if (uri.scheme == 'sdk') {
      var value = cachedSources[uri];
      charactersRead += value.length;
      return new Future.value(value);
    } else if (uri.scheme == 'http' || uri.scheme == 'https') {
      var value = cachedSources.putIfAbsent(uri, () {
        var request = new HttpRequest();
        request.open('GET', '$uri', async: false);
        request.send(null);
        return request.responseText;
      });
      charactersRead += value.length;
      return new Future.value(value);
    } else if ('$uri' == '$PRIVATE_SCHEME:/main.dart') {
      charactersRead += source.length;
      return new Future.value(source);
    } else if (uri.scheme == PRIVATE_SCHEME) {
      return HttpRequest.getString('project${uri.path}');
    }
    throw new Exception('Error: Cannot read: $uri');
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
  cachedCompiler = reuseCompiler(
      diagnosticHandler: handler,
      inputProvider: inputProvider,
      options: options,
      cachedCompiler: cachedCompiler,
      libraryRoot: sdkLocation,
      packageRoot: Uri.parse('packages/'));

  cachedCompiler.run(Uri.parse('$PRIVATE_SCHEME:/main.dart')).then((success) {
    if (cachedCompiler.libraries.containsKey('dart:html')) {
      notifyDartHtml(replyTo);
    }
    String js = cachedCompiler.assembledCode;
    try {
      if (js == null) {
        if (!options.contains('--analyze-only')) replyTo.send('failed');
      } else {
        var url;
        if (options.contains('--verbose')) {
          handler(null, 0, 0,
                  'Compiled ${source.length}/${charactersRead} characters Dart'
                  ' -> ${js.length} characters.',
                  compiler.Diagnostic.VERBOSE_INFO);
        }
        try {
          // At least Safari and Firefox do not support creating an
          // object URL from a web worker.  MDN claims that it will be
          // supported in Firefox 21.
          url = Url.createObjectUrl(new Blob([js], 'application/javascript'));
        } catch (_) {
          // Ignored.
        }
        if (url != null) {
          replyTo.send(['url', url]);
        } else {
          replyTo.send(['code', js]);
        }
      }
    } catch (e, trace) {
      replyTo.send(['crash', '$e, $trace']);
    }
    replyTo.send('done');
  });
}
