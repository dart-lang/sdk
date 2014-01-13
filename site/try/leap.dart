// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.main;

import 'dart:async';
import 'dart:html';
import 'dart:isolate';

import '../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart'
  show
    EOF_TOKEN,
    StringScanner,
    Token;

import '../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart'
    as scanner;

import '../../sdk/lib/_internal/compiler/implementation/source_file.dart' show
    StringSourceFile;

import 'decoration.dart';
import 'themes.dart';

import 'isolate_legacy.dart';

@lazy import 'compiler_isolate.dart';

// const lazy = const DeferredLibrary('compiler_isolate');
const lazy = null;

DivElement inputPre;
PreElement outputDiv;
DivElement hackDiv;
IFrameElement outputFrame;
Timer compilerTimer;
SendPort compilerPort;
MutationObserver observer;
SpanElement cacheStatusElement;
bool alwaysRunInWorker = window.localStorage['alwaysRunInWorker'] == 'true';
bool verboseCompiler = window.localStorage['verboseCompiler'] == 'true';
bool minified = window.localStorage['minified'] == 'true';
bool onlyAnalyze = window.localStorage['onlyAnalyze'] == 'true';
final String rawCodeFont = window.localStorage['codeFont'];
String codeFont = rawCodeFont == null ? '' : rawCodeFont;
String currentSample = window.localStorage['currentSample'];
Theme currentTheme = Theme.named(window.localStorage['theme']);
bool applyingSettings = false;

const String INDENT = '\u{a0}\u{a0}';

onKeyUp(KeyboardEvent e) {
  if (e.keyCode == 13) {
    e.preventDefault();
    Selection selection = window.getSelection();
    if (selection.isCollapsed && selection.anchorNode is Text) {
      Text text = selection.anchorNode;
      int offset = selection.anchorOffset;
      text.insertData(offset, '\n');
      selection.collapse(text, offset + 1);
    }
  }
  // This is a hack to get Safari to send mutation events on contenteditable.
  var newDiv = new DivElement();
  hackDiv.replaceWith(newDiv);
  hackDiv = newDiv;
}

bool isMalformedInput = false;
String currentSource = "";

// TODO(ahe): This method should be cleaned up. It is too large.
onMutation(List<MutationRecord> mutations, MutationObserver observer) {
  scheduleCompilation();

  for (Element element in inputPre.queryAll('a[class="diagnostic"]>span')) {
    element.remove();
  }
  // Discard clean-up mutations.
  observer.takeRecords();

  Selection selection = window.getSelection();

  while (!mutations.isEmpty) {
    for (MutationRecord record in mutations) {
      String type = record.type;
      switch (type) {

        case 'characterData':

          bool hasSelection = false;
          int offset = selection.anchorOffset;
          if (selection.isCollapsed && selection.anchorNode == record.target) {
            hasSelection = true;
          }
          var parent = record.target.parentNode;
          if (parent != inputPre) {
            inlineChildren(parent);
          }
          if (hasSelection) {
            selection.collapse(record.target, offset);
          }
          break;

        default:
          if (!record.addedNodes.isEmpty) {
            for (var node in record.addedNodes) {

              if (node.nodeType != Node.ELEMENT_NODE) continue;

              if (node is BRElement) {
                if (selection.anchorNode != node) {
                  node.replaceWith(new Text('\n'));
                }
              } else {
                var parent = node.parentNode;
                if (parent == null) continue;
                var nodes = new List.from(node.nodes);
                var style = node.getComputedStyle();
                if (style.display != 'inline') {
                  var previous = node.previousNode;
                  if (previous is Text) {
                    previous.appendData('\n');
                  } else {
                    parent.insertBefore(new Text('\n'), node);
                  }
                }
                for (Node child in nodes) {
                  child.remove();
                  parent.insertBefore(child, node);
                }
                node.remove();
              }
            }
          }
      }
    }
    mutations = observer.takeRecords();
  }

  if (!inputPre.nodes.isEmpty && inputPre.nodes.last is Text) {
    Text text = inputPre.nodes.last;
    if (!text.text.endsWith('\n')) {
      text.appendData('\n');
    }
  }

  int offset = 0;
  int anchorOffset = 0;
  bool hasSelection = false;
  Node anchorNode = selection.anchorNode;
  // TODO(ahe): Try to share walk4 methods.
  void walk4(Node node) {
    // TODO(ahe): Use TreeWalker when that is exposed.
    // function textNodesUnder(root){
    //   var n, a=[], walk=document.createTreeWalker(
    //       root,NodeFilter.SHOW_TEXT,null,false);
    //   while(n=walk.nextNode()) a.push(n);
    //   return a;
    // }
    int type = node.nodeType;
    if (type == Node.TEXT_NODE || type == Node.CDATA_SECTION_NODE) {
      CharacterData text = node;
      if (anchorNode == node) {
        hasSelection = true;
        anchorOffset = selection.anchorOffset + offset;
        return;
      }
      offset += text.length;
    }

    var child = node.firstChild;
    while (child != null) {
      walk4(child);
      if (hasSelection) return;
      child = child.nextNode;
    }
  }
  if (selection.isCollapsed) {
    walk4(inputPre);
  }

  currentSource = inputPre.text;
  inputPre.nodes.clear();
  inputPre.appendText(currentSource);
  if (hasSelection) {
    selection.collapse(inputPre.firstChild, anchorOffset);
  }

  isMalformedInput = false;
  for (var n in new List.from(inputPre.nodes)) {
    if (n is! Text) continue;
    Text node = n;
    String text = node.text;

    Token token = new StringScanner(
        new StringSourceFile('', text), includeComments: true).tokenize();
    int offset = 0;
    for (;token.kind != EOF_TOKEN; token = token.next) {
      Decoration decoration = getDecoration(token);
      if (decoration == null) continue;
      bool hasSelection = false;
      int selectionOffset = selection.anchorOffset;

      if (selection.isCollapsed && selection.anchorNode == node) {
        hasSelection = true;
        selectionOffset = selection.anchorOffset;
      }
      int splitPoint = token.charOffset - offset;
      Text str = node.splitText(splitPoint);
      Text after = str.splitText(token.charCount);
      offset += splitPoint + token.charCount;
      inputPre.insertBefore(after, node.nextNode);
      inputPre.insertBefore(decoration.applyTo(str), after);

      if (hasSelection && selectionOffset > node.length) {
        selectionOffset -= node.length;
        if (selectionOffset > str.length) {
          selectionOffset -= str.length;
          selection.collapse(after, selectionOffset);
        } else {
          selection.collapse(str, selectionOffset);
        }
      }
      node = after;
    }
  }

  window.localStorage['currentSource'] = currentSource;

  // Discard highlighting mutations.
  observer.takeRecords();
}

addDiagnostic(String kind, String message, int begin, int end) {
  observer.disconnect();
  Selection selection = window.getSelection();
  int offset = 0;
  int anchorOffset = 0;
  bool hasSelection = false;
  Node anchorNode = selection.anchorNode;
  bool foundNode = false;
  void walk4(Node node) {
    // TODO(ahe): Use TreeWalker when that is exposed.
    int type = node.nodeType;
    if (type == Node.TEXT_NODE || type == Node.CDATA_SECTION_NODE) {
      CharacterData cdata = node;
      // print('walking: ${node.data}');
      if (anchorNode == node) {
        hasSelection = true;
        anchorOffset = selection.anchorOffset + offset;
      }
      int newOffset = offset + cdata.length;
      if (offset <= begin && begin < newOffset) {
        hasSelection = node == anchorNode;
        anchorOffset = selection.anchorOffset;
        Node marker = new Text("");
        node.replaceWith(marker);
        // TODO(ahe): Don't highlight everything in the node.  Find
        // the relevant token.
        if (kind == 'error') {
          marker.replaceWith(diagnostic(node, error(message)));
        } else if (kind == 'warning') {
          marker.replaceWith(diagnostic(node, warning(message)));
        } else {
          marker.replaceWith(diagnostic(node, info(message)));
        }
        if (hasSelection) {
          selection.collapse(node, anchorOffset);
        }
        foundNode = true;
        return;
      }
      offset = newOffset;
    } else if (type == Node.ELEMENT_NODE) {
      Element element = node;
      if (element.classes.contains('alert')) return;
    }

    var child = node.firstChild;
    while(child != null && !foundNode) {
      walk4(child);
      child = child.nextNode;
    }
  }
  walk4(inputPre);

  if (!foundNode) {
    outputDiv.appendText('$message\n');
  }

  observer.takeRecords();
  observer.observe(
      inputPre, childList: true, characterData: true, subtree: true);
}

void inlineChildren(Element element) {
  if (element == null) return;
  var parent = element.parentNode;
  if (parent == null) return;
  for (Node child in new List.from(element.nodes)) {
    child.remove();
    parent.insertBefore(child, element);
  }
  element.remove();
}

int count = 0;

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

Decoration getDecoration(scanner.Token token) {
  String tokenValue = token.value;
  String tokenInfo = token.info.value;
  if (tokenInfo == 'string') return currentTheme.string;
  // if (tokenInfo == 'identifier') return identifier;
  if (tokenInfo == 'keyword') return currentTheme.keyword;
  if (tokenInfo == 'comment') return currentTheme.singleLineComment;
  if (tokenInfo == 'malformed input') {
    isMalformedInput = true;
    return new DiagnosticDecoration('error', tokenValue);
  }
  return null;
}

diagnostic(text, tip) {
  if (text is String) {
    text = new Text(text);
  }
  return new AnchorElement()
      ..classes.add('diagnostic')
      ..append(text)
      ..append(tip);
}

img(src, width, height, alt) {
  return new ImageElement(src: src, width: width, height: height)..alt = alt;
}

makeOutputFrame(String scriptUrl) {
  final String outputHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
<title>JavaScript output</title>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8">
</head>
<body>
<script type="application/javascript" src="$outputHelper"></script>
<script type="application/javascript" src="$scriptUrl"></script>
</body>
</html>
''';

  return new IFrameElement()
      ..src = Url.createObjectUrl(new Blob([outputHtml], "text/html"))
      ..style.width = '100%'
      ..style.height = '0px'
      ..seamless = false;
}

const String HAS_NON_DOM_HTTP_REQUEST = 'spawnFunction supports HttpRequest';
const String NO_NON_DOM_HTTP_REQUEST =
    'spawnFunction does not support HttpRequest';


checkHttpRequest(SendPort replyTo) {
  try {
    new HttpRequest();
    replyTo.send(HAS_NON_DOM_HTTP_REQUEST);
  } catch (e, trace) {
    replyTo.send(NO_NON_DOM_HTTP_REQUEST);
  }
}

main() {
  if (window.localStorage['currentSource'] == null) {
    window.localStorage['currentSource'] = EXAMPLE_HELLO;
  }

  buildUI();
  spawnFunction(checkHttpRequest).first.then((reply) {
    ReceivePort port;
    if (reply == HAS_NON_DOM_HTTP_REQUEST) {
      port = spawnFunction(compilerIsolate);
    } else {
      port = spawnDomFunction(compilerIsolate);
    }
    LinkElement link = query('link[rel="dart-sdk"]');
    String sdk = link.href;
    print('Using Dart SDK: $sdk');
    int messageCount = 0;
    SendPort sendPort;
    port.listen((message) {
      messageCount++;
      switch (messageCount) {
        case 1:
          sendPort = message as SendPort;
          sendPort.send([sdk, port.sendPort]);
          break;
        case 2:
          // Acknowledged Receiving the SDK URI.
          compilerPort = sendPort;
          onMutation([], observer);
          break;
        default:
          // TODO(ahe): Close [port]?
          print('Unexpected message received: $message');
          break;
      }
    });
  });
}

buildButton(message, action) {
  if (message is String) {
    message = new Text(message);
  }
  return new ButtonElement()
      ..onClick.listen(action)
      ..append(message);
}

buildTab(message, id, action) {
  if (message is String) {
    message = new Text(message);
  }

  onClick(MouseEvent event) {
    event.preventDefault();
    Element e = event.target;
    LIElement parent = e.parent;
    parent.parent.query('li[class="active"]').classes.remove('active');
    parent.classes.add('active');
    action(event);
  }

  inspirationCallbacks[id] = action;

  return new OptionElement()..append(message)..id = id;
}

Map<String, Function> inspirationCallbacks = new Map<String, Function>();

void onInspirationChange(Event event) {
  SelectElement select = event.target;
  String id = select.queryAll('option')[select.selectedIndex].id;
  Function action = inspirationCallbacks[id];
  if (action != null) action(event);
  outputFrame.style.display = 'none';
}

buildUI() {
  window.localStorage['currentSample'] = '$currentSample';

  var inspirationTabs = document.getElementById('inspiration');
  var htmlGroup = new OptGroupElement()..label = 'HTML';
  var benchmarkGroup = new OptGroupElement()..label = 'Benchmarks';
  inspirationTabs.append(new OptionElement()..appendText('Pick an example'));
  inspirationTabs.onChange.listen(onInspirationChange);
  // inspirationTabs.classes.addAll(['nav', 'nav-tabs']);
  inspirationTabs.append(buildTab('Hello, World!', 'EXAMPLE_HELLO', (_) {
    inputPre
        ..nodes.clear()
        ..appendText(EXAMPLE_HELLO);
  }));
  inspirationTabs.append(buildTab('Fibonacci', 'EXAMPLE_FIBONACCI', (_) {
    inputPre
        ..nodes.clear()
        ..appendText(EXAMPLE_FIBONACCI);
  }));
  inspirationTabs.append(htmlGroup);
  // TODO(ahe): Restore benchmarks.
  // inspirationTabs.append(benchmarkGroup);

  htmlGroup.append(
      buildTab('Hello, World!', 'EXAMPLE_HELLO_HTML', (_) {
    inputPre
        ..nodes.clear()
        ..appendText(EXAMPLE_HELLO_HTML);
  }));
  htmlGroup.append(
      buildTab('Fibonacci', 'EXAMPLE_FIBONACCI_HTML', (_) {
    inputPre
        ..nodes.clear()
        ..appendText(EXAMPLE_FIBONACCI_HTML);
  }));
  htmlGroup.append(buildTab('Sunflower', 'EXAMPLE_SUNFLOWER', (_) {
    inputPre
        ..nodes.clear()
        ..appendText(EXAMPLE_SUNFLOWER);
  }));

  benchmarkGroup.append(buildTab('DeltaBlue', 'BENCHMARK_DELTA_BLUE', (_) {
    inputPre.contentEditable = 'false';
    LinkElement link = query('link[rel="benchmark-DeltaBlue"]');
    String deltaBlueUri = link.href;
    link = query('link[rel="benchmark-base"]');
    String benchmarkBaseUri = link.href;
    HttpRequest.getString(benchmarkBaseUri).then((String benchmarkBase) {
      HttpRequest.getString(deltaBlueUri).then((String deltaBlue) {
        benchmarkBase = benchmarkBase.replaceFirst(
            'part of benchmark_harness;', '// part of benchmark_harness;');
        deltaBlue = deltaBlue.replaceFirst(
            "import 'package:benchmark_harness/benchmark_harness.dart';",
            benchmarkBase);
        inputPre
            ..nodes.clear()
            ..appendText(deltaBlue)
            ..contentEditable = 'true';
      });
    });
  }));

  benchmarkGroup.append(buildTab('Richards', 'BENCHMARK_RICHARDS', (_) {
    inputPre.contentEditable = 'false';
    LinkElement link = query('link[rel="benchmark-Richards"]');
    String richardsUri = link.href;
    link = query('link[rel="benchmark-base"]');
    String benchmarkBaseUri = link.href;
    HttpRequest.getString(benchmarkBaseUri).then((String benchmarkBase) {
      HttpRequest.getString(richardsUri).then((String richards) {
        benchmarkBase = benchmarkBase.replaceFirst(
            'part of benchmark_harness;', '// part of benchmark_harness;');
        richards = richards.replaceFirst(
            "import 'package:benchmark_harness/benchmark_harness.dart';",
            benchmarkBase);
        inputPre
            ..nodes.clear()
            ..appendText(richards)
            ..contentEditable = 'true';
      });
    });
  }));

  // TODO(ahe): Update currentSample.  Or try switching to a drop-down menu.
  var active = inspirationTabs.query('[id="$currentSample"]');
  if (active == null) {
    // inspirationTabs.query('li').classes.add('active');
  }

  (inputPre = new DivElement())
      ..classes.add('well')
      ..style.backgroundColor = currentTheme.background.color
      ..style.color = currentTheme.foreground.color
      ..style.overflow = 'auto'
      ..style.whiteSpace = 'pre'
      ..style.font = codeFont
      ..spellcheck = false;

  inputPre.contentEditable = 'true';
  inputPre.onKeyDown.listen(onKeyUp);

  var inputWrapper = new DivElement()
      ..append(inputPre)
      ..style.position = 'relative';

  var inputHeader = new DivElement()..appendText('Code');

  inputHeader.style
      ..right = '3px'
      ..top = '0px'
      ..position = 'absolute';
  inputWrapper.append(inputHeader);

  outputFrame =
      makeOutputFrame(
          Url.createObjectUrl(new Blob([''], 'application/javascript')));

  outputDiv = new PreElement();
  outputDiv.style
      ..backgroundColor = currentTheme.background.color
      ..color = currentTheme.foreground.color
      ..overflow = 'auto'
      ..padding = '1em'
      ..minHeight = '10em'
      ..whiteSpace = 'pre-wrap';

  var outputWrapper = new DivElement()
      ..append(outputDiv)
      ..style.position = 'relative';

  var consoleHeader = new DivElement()..appendText('Console');

  consoleHeader.style
      ..right = '3px'
      ..top = '0px'
      ..position = 'absolute';
  outputWrapper.append(consoleHeader);

  hackDiv = new DivElement();

  var saveButton = new ButtonElement()
      ..onClick.listen((_) {
        var blobUrl =
            Url.createObjectUrl(new Blob([inputPre.text], 'text/plain'));
        var save = new AnchorElement(href: blobUrl);
        save.target = '_blank';
        save.download = 'untitled.dart';
        save.dispatchEvent(new Event.eventType('Event', 'click'));
      })
      ..style.position = 'absolute'
      ..style.right = '0px'
      ..appendText('Save');

  cacheStatusElement = document.getElementById('appcache-status');
  updateCacheStatus();

  // TODO(ahe): Switch to two column layout so the console is on the right.
  var section = document.query('article[class="homepage"]>section');

  DivElement tryColumn = document.getElementById('try-dart-column');
  DivElement runColumn = document.getElementById('run-dart-column');

  tryColumn.append(inputWrapper);
  outputFrame.style.display = 'none';
  runColumn.append(outputFrame);
  runColumn.append(outputWrapper);
  runColumn.append(hackDiv);

  var settingsElement = document.getElementById('settings');
  settingsElement.onClick.listen(openSettings);

  window.onMessage.listen((MessageEvent event) {
    if (event.data is List) {
      List message = event.data;
      if (message.length > 0) {
        switch (message[0]) {
        case 'error':
          Map diagnostics = message[1];
          String url = diagnostics['url'];
          outputDiv.appendText('${diagnostics["message"]}\n');
          return;
        case 'scrollHeight':
          int scrollHeight = message[1];
          if (scrollHeight > 0) {
            outputFrame.style.height = '${scrollHeight}px';
          }
          return;
        }
      }
    }
    outputDiv.appendText('${event.data}\n');
  });

  observer = new MutationObserver(onMutation)
      ..observe(inputPre, childList: true, characterData: true, subtree: true);

  scheduleMicrotask(() {
    inputPre.appendText(window.localStorage['currentSource']);
  });

  // You cannot install event handlers on window.applicationCache
  // until the window has loaded.  In dartium, that's later than this
  // method is called.
  window.onLoad.listen(onLoad);

  // However, in dart2js, the window has already loaded, and onLoad is
  // never called.
  onLoad(null);
}

void openSettings(MouseEvent event) {
  event.preventDefault();

  var backdrop = new DivElement()..classes.add('modal-backdrop');
  document.body.append(backdrop);

  void updateCodeFont(Event e) {
    TextInputElement target = e.target;
    codeFont = target.value;
    inputPre.style.font = codeFont;
    backdrop.style.opacity = '0.0';
  }

  void updateTheme(Event e) {
    var select = e.target;
    String theme = select.queryAll('option')[select.selectedIndex].text;
    window.localStorage['theme'] = theme;
    currentTheme = Theme.named(theme);

    inputPre.style
        ..backgroundColor = currentTheme.background.color
        ..color = currentTheme.foreground.color;

    outputDiv.style
        ..backgroundColor = currentTheme.background.color
        ..color = currentTheme.foreground.color;

    backdrop.style.opacity = '0.0';

    applyingSettings = true;
    onMutation([], observer);
    applyingSettings = false;
  }


  var body = document.getElementById('settings-body');

  body.nodes.clear();

  var form = new FormElement();
  var fieldSet = new FieldSetElement();
  body.append(form);
  form.append(fieldSet);

  buildCheckBox(String text, bool defaultValue, void action(Event e)) {
    var checkBox = new CheckboxInputElement()
        // TODO(ahe): Used to be ..defaultChecked = defaultValue
        ..checked = defaultValue
        ..onChange.listen(action);
    return new LabelElement()
        ..classes.add('checkbox')
        ..append(checkBox)
        ..appendText(' $text');
  }

  bool isChecked(CheckboxInputElement checkBox) => checkBox.checked;

  // TODO(ahe): Build abstraction for flags/options.
  fieldSet.append(
      buildCheckBox(
          'Always run in Worker thread.', alwaysRunInWorker,
          (Event e) { alwaysRunInWorker = isChecked(e.target); }));

  fieldSet.append(
      buildCheckBox(
          'Verbose compiler output.', verboseCompiler,
          (Event e) { verboseCompiler = isChecked(e.target); }));

  fieldSet.append(
      buildCheckBox(
          'Generate compact (minified) JavaScript.', minified,
          (Event e) { minified = isChecked(e.target); }));

  fieldSet.append(
      buildCheckBox(
          'Only analyze program.', onlyAnalyze,
          (Event e) { onlyAnalyze = isChecked(e.target); }));

  fieldSet.append(new LabelElement()..appendText('Code font:'));
  var textInput = new TextInputElement();
  textInput.classes.add('input-block-level');
  if (codeFont != null && codeFont != '') {
    textInput.value = codeFont;
  }
  textInput.placeholder = 'Enter a size and font, for example, 11pt monospace';
  textInput.onChange.listen(updateCodeFont);
  fieldSet.append(textInput);

  fieldSet.append(new LabelElement()..appendText('Theme:'));
  var themeSelector = new SelectElement();
  themeSelector.classes.add('input-block-level');
  for (Theme theme in THEMES) {
    OptionElement option = new OptionElement()..appendText(theme.name);
    if (theme == currentTheme) option.selected = true;
    themeSelector.append(option);
  }
  themeSelector.onChange.listen(updateTheme);
  fieldSet.append(themeSelector);

  var dialog = document.getElementById('settings-dialog');

  dialog.style.display = 'block';
  dialog.classes.add('in');

  onSubmit(Event event) {
    event.preventDefault();

    window.localStorage['alwaysRunInWorker'] = '$alwaysRunInWorker';
    window.localStorage['verboseCompiler'] = '$verboseCompiler';
    window.localStorage['minified'] = '$minified';
    window.localStorage['onlyAnalyze'] = '$onlyAnalyze';
    window.localStorage['codeFont'] = '$codeFont';

    dialog.style.display = 'none';
    dialog.classes.remove('in');
    backdrop.remove();
  }
  form.onSubmit.listen(onSubmit);

  var doneButton = document.getElementById('settings-done');
  doneButton.onClick.listen(onSubmit);
}

/// Called when the window has finished loading.
void onLoad(Event event) {
  window.applicationCache.onUpdateReady.listen((_) => updateCacheStatus());
  window.applicationCache.onCached.listen((_) => updateCacheStatus());
  window.applicationCache.onChecking.listen((_) => updateCacheStatus());
  window.applicationCache.onDownloading.listen((_) => updateCacheStatus());
  window.applicationCache.onError.listen((_) => updateCacheStatus());
  window.applicationCache.onNoUpdate.listen((_) => updateCacheStatus());
  window.applicationCache.onObsolete.listen((_) => updateCacheStatus());
  window.applicationCache.onProgress.listen(onCacheProgress);
}

onCacheProgress(ProgressEvent event) {
  if (!event.lengthComputable) {
    updateCacheStatus();
    return;
  }
  cacheStatusElement.nodes.clear();
  cacheStatusElement.appendText('Downloading SDK ');
  var progress = '${event.loaded} of ${event.total}';
  if (MeterElement.supported) {
    cacheStatusElement.append(
        new MeterElement()
            ..appendText(progress)
            ..min = 0
            ..max = event.total
            ..value = event.loaded);
  } else {
    cacheStatusElement.appendText(progress);
  }
}

String cacheStatus() {
  if (!ApplicationCache.supported) return 'offline not supported';
  int status = window.applicationCache.status;
  if (status == ApplicationCache.CHECKING) return 'Checking for updates';
  if (status == ApplicationCache.DOWNLOADING) return 'Downloading SDK';
  if (status == ApplicationCache.IDLE) return 'Try Dart! works offline';
  if (status == ApplicationCache.OBSOLETE) return 'OBSOLETE';
  if (status == ApplicationCache.UNCACHED) return 'offline not available';
  if (status == ApplicationCache.UPDATEREADY) return 'SDK downloaded';
  return '?';
}

void updateCacheStatus() {
  cacheStatusElement.nodes.clear();
  int status = window.applicationCache.status;
  if (status == ApplicationCache.UPDATEREADY) {
    cacheStatusElement.appendText('New version of Try Dart! ready: ');
    cacheStatusElement.append(
        new AnchorElement(href: '#')
            ..appendText('Load')
            ..onClick.listen((event) {
              event.preventDefault();
              window.applicationCache.swapCache();
              window.location.reload();
            }));
  } else if (status == ApplicationCache.IDLE) {
    cacheStatusElement.appendText(cacheStatus());
    cacheStatusElement.classes.add('offlineyay');
    new Timer(const Duration(seconds: 10), () {
      cacheStatusElement.style.display = 'none';
    });
  } else {
    cacheStatusElement.appendText(cacheStatus());
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

final String outputHelper =
    Url.createObjectUrl(new Blob([OUTPUT_HELPER], 'application/javascript'));

const String EXAMPLE_HELLO = r'''
// Go ahead and modify this example.

var greeting = "Hello, World!";

// Prints a greeting.
void main() {
  // The [print] function displays a message in the "Console" box.
  // Try modifying the greeting above and watch the "Console" box change.
  print(greeting);
}
''';

const String EXAMPLE_HELLO_HTML = r'''
// Go ahead and modify this example.

import "dart:html";

var greeting = "Hello, World!";

// Displays a greeting.
void main() {
  // This example uses HTML to display the greeting and it will appear
  // in a nested HTML frame (an iframe).
  document.body.append(new HeadingElement.h1()..appendText(greeting));
}
''';

const String EXAMPLE_FIBONACCI = r'''
// Go ahead and modify this example.

// Computes the nth Fibonacci number.
int fibonacci(int n) {
  if (n < 2) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

// Prints a Fibonacci number.
void main() {
  int i = 20;
  String message = "fibonacci($i) = ${fibonacci(i)}";
  // Print the result in the "Console" box.
  print(message);
}
''';

const String EXAMPLE_FIBONACCI_HTML = r'''
// Go ahead and modify this example.

import "dart:html";

// Computes the nth Fibonacci number.
int fibonacci(int n) {
  if (n < 2) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

// Displays a Fibonacci number.
void main() {
  int i = 20;
  String message = "fibonacci($i) = ${fibonacci(i)}";

  // This example uses HTML to display the result and it will appear
  // in a nested HTML frame (an iframe).
  document.body.append(new HeadingElement.h1()..appendText(message));
}
''';

const String OUTPUT_HELPER = r'''
function dartPrint(msg) {
  window.parent.postMessage(String(msg), "*");
}

function dartMainRunner(main) {
  main();
}

window.onerror = function (message, url, lineNumber) {
  window.parent.postMessage(
      ["error", {message: message, url: url, lineNumber: lineNumber}], "*");
};

(function () {

function postScrollHeight() {
  window.parent.postMessage(["scrollHeight", document.documentElement.scrollHeight], "*");
}

var observer = new (window.MutationObserver||window.WebKitMutationObserver||window.MozMutationObserver)(function(mutations) {
  postScrollHeight()
  window.setTimeout(postScrollHeight, 500);
});

observer.observe(
    document.body,
    { attributes: true,
      childList: true,
      characterData: true,
      subtree: true });
})();
''';

const String EXAMPLE_SUNFLOWER = '''
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sunflower;

import "dart:html";
import "dart:math";

const String ORANGE = "orange";
const int SEED_RADIUS = 2;
const int SCALE_FACTOR = 4;
const num TAU = PI * 2;
const int MAX_D = 300;
const num centerX = MAX_D / 2;
const num centerY = centerX;

final InputElement slider = query("#slider");
final Element notes = query("#notes");
final num PHI = (sqrt(5) + 1) / 2;
int seeds = 0;
final CanvasRenderingContext2D context =
  (query("#canvas") as CanvasElement).context2D;

void main() {
  document.head.append(new StyleElement()..appendText(STYLE));
  document.body.innerHtml = BODY;
  slider.onChange.listen((e) => draw());
  draw();
}

/// Draw the complete figure for the current number of seeds.
void draw() {
  seeds = int.parse(slider.value);
  context.clearRect(0, 0, MAX_D, MAX_D);
  for (var i = 0; i < seeds; i++) {
    final num theta = i * TAU / PHI;
    final num r = sqrt(i) * SCALE_FACTOR;
    drawSeed(centerX + r * cos(theta), centerY - r * sin(theta));
  }
  notes.text = "\${seeds} seeds";
}

/// Draw a small circle representing a seed centered at (x,y).
void drawSeed(num x, num y) {
  context..beginPath()
         ..lineWidth = 2
         ..fillStyle = ORANGE
         ..strokeStyle = ORANGE
         ..arc(x, y, SEED_RADIUS, 0, TAU, false)
         ..fill()
         ..closePath()
         ..stroke();
}

const String MATH_PNG =
    "https://dart.googlecode.com/svn/trunk/dart/samples/sunflower/web/math.png";
const String BODY = """
    <h1>drfibonacci\'s Sunflower Spectacular</h1>

    <p>A canvas 2D demo.</p>

    <div id="container">
      <canvas id="canvas" width="300" height="300" class="center"></canvas>
      <form class="center">
        <input id="slider" type="range" max="1000" value="500"/>
      </form>
      <br/>
      <img src="\$MATH_PNG" width="350px" height="42px" class="center">
    </div>

    <footer>
      <p id="summary"> </p>
      <p id="notes"> </p>
    </footer>
""";

const String STYLE = r"""
body {
  background-color: #F8F8F8;
  font-family: 'Open Sans', sans-serif;
  font-size: 14px;
  font-weight: normal;
  line-height: 1.2em;
  margin: 15px;
}

p {
  color: #333;
}

#container {
  width: 100%;
  height: 400px;
  position: relative;
  border: 1px solid #ccc;
  background-color: #fff;
}

#summary {
  float: left;
}

#notes {
  float: right;
  width: 120px;
  text-align: right;
}

.error {
  font-style: italic;
  color: red;
}

img {
  border: 1px solid #ccc;
  margin: auto;
}

.center {
  display: block;
  margin: 0px auto;
  text-align: center;
}
""";

''';
