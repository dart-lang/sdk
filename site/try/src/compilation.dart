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
    Worker;

import 'dart:async' show
    Timer;

import 'dart:isolate' show
    ReceivePort,
    SendPort;

import 'editor.dart' show
    addDiagnostic,
    currentSource,
    isMalformedInput;

import 'run.dart' show
    makeOutputFrame;

import 'ui.dart' show
    alwaysRunInWorker,
    applyingSettings,
    buildButton,
    minified,
    onlyAnalyze,
    outputDiv,
    outputFrame,
    verboseCompiler;

@lazy import 'compiler_isolate.dart';

// const lazy = const DeferredLibrary('compiler_isolate');
const lazy = null;

SendPort compilerPort;
Timer compilerTimer;

void scheduleCompilation() {
  if (applyingSettings) return;
  if (compilerTimer != null) {
    compilerTimer.cancel();
    compilerTimer = null;
  }
  compilerTimer =
      new Timer(const Duration(milliseconds: 500), startCompilation);
}

void startCompilation() {
  if (compilerTimer != null) {
    compilerTimer.cancel();
    compilerTimer = null;
  }

  new CompilationProcess(currentSource, outputDiv).start();
}

class CompilationProcess {
  final String source;
  final Element console;
  final ReceivePort receivePort = new ReceivePort();
  bool isCleared = false;
  bool isDone = false;
  bool usesDartHtml = false;
  Worker worker;
  List<String> objectUrls = <String>[];

  static CompilationProcess current;

  CompilationProcess(this.source, this.console);

  static bool shouldStartCompilation() {
    if (compilerPort == null) return false;
    if (isMalformedInput) return false;
    if (current != null) return current.isDone;
    return true;
  }

  void clear() {
    if (verboseCompiler) return;
    if (!isCleared) console.nodes.clear();
    isCleared = true;
  }

  void start() {
    if (!shouldStartCompilation()) {
      receivePort.close();
      if (!isMalformedInput) scheduleCompilation();
      return;
    }
    if (current != null) current.dispose();
    current = this;
    console.nodes.clear();
    var options = [];
    if (verboseCompiler) options.add('--verbose');
    if (minified) options.add('--minify');
    if (onlyAnalyze) options.add('--analyze-only');
    compilerPort.send([['options', options], receivePort.sendPort]);
    console.appendHtml('<i class="icon-spinner icon-spin"></i>');
    console.appendText(' Compiling Dart program...\n');
    outputFrame.style.display = 'none';
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
    clear();
    consolePrint('Compilation failed');
  }

  onDone(_) {
    isDone = true;
    receivePort.close();
  }

  // This is called in browsers that support creating Object URLs in a
  // web worker.  For example, Chrome and Firefox 21.
  onUrl(String url) {
    objectUrls.add(url);
    clear();
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
    void retryInIframe(_) {
      var frame = makeOutputFrame(url);
      outputFrame.replaceWith(frame);
      outputFrame = frame;
    }
    void onError(String errorMessage) {
      console.appendText(errorMessage);
      console.appendText(' ');
      console.append(buildButton('Try in iframe', retryInIframe));
      console.appendText('\n');
    }
    if (usesDartHtml && !alwaysRunInWorker) {
      retryInIframe(null);
    } else {
      runInWorker(wrapperUrl, onError);
    }
  }

  // This is called in browsers that do not support creating Object
  // URLs in a web worker.  For example, Safari and Firefox < 21.
  onCode(String code) {
    clear();

    void retryInIframe(_) {
      // The obvious thing would be to call [makeOutputFrame], but
      // Safari doesn't support access to Object URLs in an iframe.

      var frame = new IFrameElement()
          ..src = 'iframe.html'
          ..style.width = '100%'
          ..style.height = '0px'
          ..seamless = false;
      frame.onLoad.listen((_) {
        frame.contentWindow.postMessage(['source', code], '*');
      });
      outputFrame.replaceWith(frame);
      outputFrame = frame;
    }

    void onError(String errorMessage) {
      console.appendText(errorMessage);
      console.appendText(' ');
      console.append(buildButton('Try in iframe', retryInIframe));
      console.appendText('\n');
    }

    String codeWithPrint =
        '$code\n'
        'function dartPrint(msg) { postMessage(msg); }\n';
    var url =
        Url.createObjectUrl(
            new Blob([codeWithPrint], 'application/javascript'));
    objectUrls.add(url);

    if (usesDartHtml && !alwaysRunInWorker) {
      retryInIframe(null);
    } else {
      runInWorker(url, onError);
    }
  }

  void runInWorker(String url, void onError(String errorMessage)) {
    worker = new Worker(url)
        ..onMessage.listen((MessageEvent event) {
          consolePrint(event.data);
        })
        ..onError.listen((ErrorEvent event) {
          worker.terminate();
          worker = null;
          onError(event.message);
        });
  }

  onDiagnostic(Map<String, dynamic> diagnostic) {
    String kind = diagnostic['kind'];
    String message = diagnostic['message'];
    if (kind == 'verbose info') {
      if (verboseCompiler) {
        consolePrint(message);
      } else {
        console.appendText('.');
      }
      return;
    }
    String uri = diagnostic['uri'];
    if (uri == null) {
      clear();
      consolePrint(message);
      return;
    }
    if (uri != 'memory:/main.dart') return;
    if (currentSource != source) return;
    int begin = diagnostic['begin'];
    int end = diagnostic['end'];
    if (begin == null) return;
    addDiagnostic(kind, message, begin, end);
  }

  onCrash(data) {
    consolePrint(data);
  }

  void consolePrint(message) {
    console.appendText('$message\n');
  }
}

void compilerIsolate(SendPort port) {
  // TODO(ahe): Restore when restoring deferred loading.
  // lazy.load().then((_) => port.listen(compile));
  ReceivePort replyTo = new ReceivePort();
  port.send(replyTo.sendPort);
  replyTo.listen((message) {
    List list = message as List;
    try {
      compile(list[0], list[1]);
    } catch (exception, stack) {
      port.send('$exception\n$stack');
    }
  });
}
