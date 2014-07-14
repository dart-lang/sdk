// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.compilation;

import 'dart:html' show
    Blob,
    Element,
    ErrorEvent,
    IFrameElement,
    MessageEvent,
    Url,
    Worker,
    window;

import 'dart:isolate' show
    ReceivePort,
    SendPort;

import 'editor.dart' show
    addDiagnostic,
    isMalformedInput;

import 'run.dart' show
    makeOutputFrame;

import 'ui.dart' show
    buildButton,
    interaction,
    outputDiv,
    outputFrame;

import 'settings.dart' show
    alwaysRunInWorker,
    incrementalCompilation,
    minified,
    onlyAnalyze,
    verboseCompiler;

import 'iframe_error_handler.dart' show
    errorStream;

/**
 * Scheme for recognizing files stored in memory.
 *
 * From http://tools.ietf.org/html/bcp35#section-2.8:
 *
 * Organizations that desire a private name space for URI scheme names
 * are encouraged to use a prefix based on their domain name, expressed
 * in reverse order.  For example, a URI scheme name of com-example-info
 * might be registered by the vendor that owns the example.com domain
 * name.
 */
const String PRIVATE_SCHEME = 'org-trydart';

SendPort compilerPort;

// TODO(ahe): Remove this.
String get currentSource => window.localStorage['currentSource'];

void set currentSource(String text) {
  window.localStorage['currentSource'] = text;
}

bool startCompilation() {
  if (!CompilationProcess.shouldStartCompilation()) return false;
  new CompilationProcess(currentSource, outputDiv).start();
  return true;
}

class CompilationProcess {
  final String source;
  final Element console;
  final ReceivePort receivePort = new ReceivePort();
  final Set<String> seenMessages = new Set<String>();
  bool isDone = false;
  bool usesDartHtml = false;
  Worker worker;
  List<String> objectUrls = <String>[];
  String firstError;

  static CompilationProcess current;

  CompilationProcess(this.source, this.console);

  static bool shouldStartCompilation() {
    if (compilerPort == null) return false;
    if (isMalformedInput) return false;
    if (current != null) return current.isDone;
    return true;
  }

  void start() {
    if (!shouldStartCompilation()) {
      receivePort.close();
      return;
    }
    if (current != null) current.dispose();
    current = this;
    var options = [
        '--analyze-main',
        '--no-source-maps',
    ];
    if (verboseCompiler) options.add('--verbose');
    if (minified) options.add('--minify');
    if (onlyAnalyze) options.add('--analyze-only');
    if (incrementalCompilation.value) {
      options.addAll(['--incremental-support', '--disable-type-inference']);
    }
    interaction.compilationStarting();
    compilerPort.send([['options', options], receivePort.sendPort]);
    receivePort.listen(onMessage);
    compilerPort.send([source, receivePort.sendPort]);
  }

  void dispose() {
    if (worker != null) worker.terminate();
    objectUrls.forEach(Url.revokeObjectUrl);
  }

  onMessage(message) {
    String kind = message is String ? message : message[0];
    var data = (message is List && message.length == 2) ? message[1] : null;
    switch (kind) {
      case 'done': return onDone(data);
      case 'url': return onUrl(data);
      case 'code': return onCode(data);
      case 'diagnostic': return onDiagnostic(data);
      case 'crash': return onCrash(data);
      case 'failed': return onFail(data);
      case 'dart:html': return onDartHtml(data);
      default:
        throw ['Unknown message kind', message];
    }
  }

  onDartHtml(_) {
    usesDartHtml = true;
  }

  onFail(_) {
    interaction.onCompilationFailed(firstError);
  }

  onDone(_) {
    interaction.onCompilationDone();
    isDone = true;
    receivePort.close();
  }

  // This is called in browsers that support creating Object URLs in a
  // web worker.  For example, Chrome and Firefox 21.
  onUrl(String url) {
    objectUrls.add(url);
    String wrapper = '''
// Fool isolate_helper.dart so it does not think this is an isolate.
var window = self;
function dartPrint(msg) {
  self.postMessage(msg);
};
self.importScripts("$url");
''';
    var wrapperUrl =
        Url.createObjectUrl(new Blob([wrapper], 'application/javascript'));
    objectUrls.add(wrapperUrl);

    run(wrapperUrl, () => makeOutputFrame(url));
  }

  // This is called in browsers that do not support creating Object
  // URLs in a web worker.  For example, Safari and Firefox < 21.
  onCode(String code) {
    IFrameElement makeIframe() {
      // The obvious thing would be to call [makeOutputFrame], but
      // Safari doesn't support access to Object URLs in an iframe.

      IFrameElement frame = new IFrameElement()
          ..src = 'iframe.html'
          ..style.width = '100%'
          ..style.height = '0px';
      frame.onLoad.listen((_) {
        frame.contentWindow.postMessage(['source', code], '*');
      });
      return frame;
    }

    String codeWithPrint =
        '$code\n'
        'function dartPrint(msg) { postMessage(msg); }\n';
    var url =
        Url.createObjectUrl(
            new Blob([codeWithPrint], 'application/javascript'));
    objectUrls.add(url);

    run(url, makeIframe);
  }

  void run(String url, IFrameElement makeIframe()) {
    void retryInIframe() {
      var frame = makeIframe();
      frame.style
          ..visibility = 'hidden'
          ..position = 'absolute';
      outputFrame.parent.insertBefore(frame, outputFrame);
      outputFrame = frame;
      errorStream(frame).listen(interaction.onIframeError);
    }
    void onError(String errorMessage) {
      console
          ..appendText(errorMessage)
          ..appendText(' ')
          ..append(buildButton('Try in iframe', (_) => retryInIframe()))
          ..appendText('\n');
    }
    interaction.aboutToRun();
    if (usesDartHtml && !alwaysRunInWorker) {
      retryInIframe();
    } else {
      runInWorker(url, onError);
    }
  }

  void runInWorker(String url, void onError(String errorMessage)) {
    worker = new Worker(url)
        ..onMessage.listen((MessageEvent event) {
          interaction.consolePrintLine(event.data);
        })
        ..onError.listen((ErrorEvent event) {
          worker.terminate();
          worker = null;
          onError(event.message);
        });
  }

  onDiagnostic(Map<String, dynamic> diagnostic) {
    if (currentSource != source) return;
    String kind = diagnostic['kind'];
    String message = diagnostic['message'];
    if (kind == 'verbose info') {
      interaction.verboseCompilerMessage(message);
      return;
    }
    if (kind == 'error' && firstError == null) {
      firstError = message;
    }
    String uri = diagnostic['uri'];
    if (uri != '${PRIVATE_SCHEME}:/main.dart') {
      interaction.consolePrintLine('$uri: [$kind] $message');
      return;
    }
    int begin = diagnostic['begin'];
    int end = diagnostic['end'];
    if (begin == null) return;
    if (seenMessages.add('$begin:$end: [$kind] $message')) {
      // Guard against duplicated messages.
      addDiagnostic(kind, message, begin, end);
    }
  }

  onCrash(data) {
    interaction.onCompilerCrash(data);
  }
}
