part of leap;

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

compilerIsolate(port) {
  Runner runner = new Runner();
  runner.init();

  port.receive((msg, replyTo) {
    replyTo.send(runner.update(msg));
  });
}

main() {
  html.document.query('#status').innerHTML = 'Initializing...';
  setOutline(msg) {
    html.document.query('#out').innerHTML = msg;
  }
  final codeDiv = html.document.query('#code');
  final popup = html.document.query('#popup');

  // The port for communicating with the compiler isolate.
  var port = null;

  // Should be called when [codeDiv] has changed. For now, call it always
  // on mouse up and key up events.
  update() {
    if (port == null) return;
    port.call(codeDiv.text).then(setOutline);
  }

  hide(Element e) {
    e.style.visibility = 'hidden';
  }

  show(Element e) {
    e.style.visibility = 'visible';
  }

  insertTextAtPoint(Event e, String newText) {
    e.preventDefault();
    var selection = html.window.getSelection();
    var range = selection.getRangeAt(0);
    var offset = range.startOffset;
    Text text = codeDiv.nodes[0];
    text.insertData(offset, newText);
    selection.setPosition(text, offset + newText.length);
  }

  // This prevents creating a new div element when hitting enter.
  codeDiv.on.keyPress.add((Event e) {
    if (e.keyIdentifier == 'Enter') {
      // TODO(ahe): Is 'Enter' portable?
      insertTextAtPoint(e, '\n');
    }
  });

  // Override tab key.
  codeDiv.on.keyDown.add((Event e) {
    if (e.keyIdentifier == 'U+0009') {
      // TODO(ahe): Find better way to detect tab key.
      insertTextAtPoint(e, '  ');
    }
  });

  // Called on keyUp and mouseUp to display a marker at the current
  // insertion point (the selection's first range). This probably
  // needs more work before it works really well, but seems to be good
  // enough for now.
  handleUp(Event e) {
    var selection = html.window.getSelection();
    var range = selection.getRangeAt(0);
    var rects = range.getClientRects();
    if (rects.length < 1) {
      hide(popup);
      return;
    }
    html.ClientRect rect = rects.item(rects.length - 1);
    if (rect.width.toInt() != 0) {
      // This is a selection of multiple characters, not a single
      // point of insertion.
      hide(popup);
      return;
    }
    popup.style.top = "${rect.bottom.toInt()}px";
    popup.style.left = "${rect.right.toInt()}px";
    // Instead of displaying this immediately, we could set up a timer
    // event and display it later. This is a matter of getting the UX
    // just right, for now it simply demonstrates that we know where
    // the insertion point is (in pixels) and what the character
    // offset is.
    show(popup);
    popup.text = '''Code completion here...
Current character offset: ${range.startOffset}''';
    // TODO(ahe): Better detection of when [codeDiv] has changed.
    update();
  }

  codeDiv.on.keyUp.add(handleUp);
  codeDiv.on.mouseUp.add(handleUp);

  codeDiv.on.blur.add((Event e) => hide(popup));

  // The event handlers are now set up. Allow editing.
  codeDiv.contentEditable = "true";

  // Creates a compiler isolate in its own iframe. This should prevent
  // the compiler from blocking the UI.
  spawnDomIsolate(html.document.query('#isolate').contentWindow,
                       'compilerIsolate').then((sendPort) {
    // The compiler isolate is now ready to talk. Store the port so
    // that the update function starts requesting outlines whenever
    // [codeDiv] changes.
    port = sendPort;
    // Make sure that we get an initial outline.
    update();
    html.document.query('#status').innerHTML = 'Ready';
  });
}

class Runner {
  final LeapCompiler compiler;

  Runner() : compiler = new LeapCompiler();

  String init() {
    Stopwatch sw = new Stopwatch()..start();
    compiler.scanBuiltinLibraries();
    sw.stop();
    return 'Scanned core libraries in ${sw.elapsedInMs()}ms';
  }

  String update(String codeText) {
    StringBuffer sb = new StringBuffer();

    Stopwatch sw = new Stopwatch()..start();

    LibraryElement e = compile(new LeapScript(codeText));

    void printFunction(FunctionElement fe, [String indentation = ""]) {
      var paramAcc = [];

      FunctionType ft = fe.computeType(compiler);

      sb.add("<div>${indentation}");
      ft.returnType.name.printOn(sb);
      sb.add(" ");
      fe.name.printOn(sb);
      sb.add("(");
      ft.parameterTypes.printOn(sb, ", ");
      sb.add(");</div>");

    }

    void printField(FieldElement fe, [String indentation = ""]) {
      sb.add("<div>${indentation}var ");
      fe.name.printOn(sb);
      sb.add(";</div>");
    }

    void printClass(ClassElement ce) {
      ce.parseNode(compiler);

      sb.add("<div>class ");
      ce.name.printOn(sb);
      sb.add(" {");

      for (Element e in ce.members.reverse()) {
        switch(e.kind) {
        case ElementKind.FUNCTION:

          printFunction(e, "&nbsp; ");
          break;

        case ElementKind.FIELD:

          printField(e, "&nbsp; ");
          break;
        }
      }
      sb.add("}</div>");
    }

    for (Element c in e.topLevelElements.reverse()) {
      switch (c.kind) {
      case ElementKind.FUNCTION:
        printFunction (c);
        break;

      case ElementKind.CLASS:
        printClass(c);
        break;

      case ElementKind.FIELD:
        printField (c);
        break;
      }
    }

    compiler.log("Outline ${sw.elapsedInMs()}");
    return sb.toString();
  }

  Element compile(String script) {
    return compiler.runSelective(script);
  }
}

class LeapCompiler extends Compiler {
  HttpRequestCache cache;

  final bool throwOnError = false;

  final libDir = "../..";

  LeapCompiler() : cache = new HttpRequestCache(), super() {
    tasks = [scanner, dietParser, parser, resolver, checker];
  }

  void log(message) { print(message); }

  String get legDirectory => libDir;

  LibraryElement scanBuiltinLibrary(String path) {
    Uri base = new Uri.fromString(html.window.location.toString());
    Uri libraryRoot = base.resolve(libDir);
    Uri resolved = libraryRoot.resolve(DART2JS_LIBRARY_MAP[path]);
    LibraryElement library = scanner.loadLibrary(resolved, null);
    return library;
  }

  currentScript() {
    if (currentElement == null) return null;
    CompilationUnitElement compilationUnit =
      currentElement.getCompilationUnit();
    if (compilationUnit == null) return null;
    return compilationUnit.script;
  }

  Script readScript(Uri uri, [ScriptTag node]) {
    String text = "";
    try {
      text = cache.readAll(uri.path.toString());
    } catch (exception) {
      cancel("${uri.path}: $exception", node: node);
    }
    SourceFile sourceFile = new SourceFile(uri.toString(), text);
    return new Script(uri, sourceFile);
  }

  reportWarning(Node node, var message) {
    print(message);
  }

  reportError(Node node, var message) {
    cancel(message.toString(), node);
  }

  void cancel(String reason, {Node node, token, instruction, element}) {
    print(reason);
  }

  Element runSelective(Script script) {
    Stopwatch sw = new Stopwatch()..start();
    Element e;
    try {
      e = runCompilerSelective(script);
    } on CompilerCancelledException catch (exception) {
      log(exception.toString());
      log('compilation failed');
      return null;
    }
    log('compilation succeeded: ${sw.elapsedInMs()}ms');
    return e;
  }

  LibraryElement runCompilerSelective(Script script) {
    mainApp = new LibraryElement(script);

    universe.libraries.remove(script.uri.toString());
    Element element;
    withCurrentElement(mainApp, () {
        scanner.scan(mainApp);
      });
    return mainApp;
  }
}
