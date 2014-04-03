// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.interaction_manager;

import 'dart:html';

import 'dart:convert' show
    JSON;

import 'dart:math' show
    max,
    min;

import 'dart:async' show
    Future;

import 'package:compiler/implementation/scanner/scannerlib.dart'
  show
    EOF_TOKEN,
    StringScanner,
    Token;

import 'package:compiler/implementation/source_file.dart' show
    StringSourceFile;

import 'compilation.dart' show
    currentSource,
    scheduleCompilation;

import 'ui.dart' show
    currentTheme,
    hackDiv,
    mainEditorPane,
    observer,
    outputDiv;

import 'decoration.dart' show
    CodeCompletionDecoration,
    Decoration,
    DiagnosticDecoration,
    error,
    info,
    warning;

import 'html_to_text.dart' show
    htmlToText;

import 'compilation_unit.dart' show
    CompilationUnit;

import 'selection.dart' show
    TrySelection;

import 'editor.dart' as editor;

import 'mock.dart' as mock;

import 'settings.dart' as settings;

/**
 * UI interaction manager for the entire application.
 */
abstract class InteractionManager {
  // Design note: All UI interactions go through one instance of this
  // class. This is by design.
  //
  // Simplicity in UI is in the eye of the beholder, not the implementor. Great
  // 'natural UI' is usually achieved with substantial implementation
  // complexity that doesn't modularise well and has nasty complicated state
  // dependencies.
  //
  // In rare cases, some UI components can be independent of this state
  // machine. For example, animation and auto-save loops.

  // Implementation note: The state machine is actually implemented by
  // [InteractionContext], this class represents public event handlers.

  factory InteractionManager() => new InteractionContext();

  InteractionManager.internal();

  void onInput(Event event);

  void onKeyUp(KeyboardEvent event);

  void onMutation(List<MutationRecord> mutations, MutationObserver observer);

  void onSelectionChange(Event event);

  /// Called when the content of a CompilationUnit changed.
  void onCompilationUnitChanged(CompilationUnit unit);

  Future<List<String>> projectFileNames();

  /// Called when the user selected a new project file.
  void onProjectFileSelected(String projectFile);
}

/**
 * State machine for UI interactions.
 */
class InteractionContext extends InteractionManager {
  InteractionState state;

  final Map<String, CompilationUnit> projectFiles = <String, CompilationUnit>{};

  CompilationUnit currentCompilationUnit =
      // TODO(ahe): Don't use a fake unit.
      new CompilationUnit('fake', '');

  InteractionContext()
      : super.internal() {
    state = new InitialState(this);
  }

  void onInput(Event event) => state.onInput(event);

  void onKeyUp(KeyboardEvent event) => state.onKeyUp(event);

  void onMutation(List<MutationRecord> mutations, MutationObserver observer) {
    return state.onMutation(mutations, observer);
  }

  void onSelectionChange(Event event) => state.onSelectionChange(event);

  void onCompilationUnitChanged(CompilationUnit unit) {
    return state.onCompilationUnitChanged(unit);
  }

  Future<List<String>> projectFileNames() => state.projectFileNames();

  void onProjectFileSelected(String projectFile) {
    return state.onProjectFileSelected(projectFile);
  }
}

abstract class InteractionState implements InteractionManager {
  InteractionContext get context;

  void set state(InteractionState newState);

  void onStateChanged(InteractionState previous) {
    print('State change ${previous.runtimeType} -> ${runtimeType}.');
  }

  void transitionToInitialState() {
    state = new InitialState(context);
  }
}

class InitialState extends InteractionState {
  final InteractionContext context;
  bool requestCodeCompletion = false;

  InitialState(this.context);

  void set state(InteractionState state) {
    InteractionState previous = context.state;
    if (previous != state) {
      context.state = state;
      state.onStateChanged(previous);
    }
  }

  void onInput(Event event) {
    state = new PendingInputState(context);
  }

  void onKeyUp(KeyboardEvent event) {
    if (computeHasModifier(event)) {
      print('onKeyUp (modified)');
      onModifiedKeyUp(event);
    } else {
      print('onKeyUp (unmodified)');
      onUnmodifiedKeyUp(event);
    }
  }

  void onModifiedKeyUp(KeyboardEvent event) {
  }

  void onUnmodifiedKeyUp(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.ENTER: {
        event.preventDefault();
        Selection selection = window.getSelection();
        if (selection.isCollapsed && selection.anchorNode is Text) {
          Text text = selection.anchorNode;
          int offset = selection.anchorOffset;
          text.insertData(offset, '\n');
          selection.collapse(text, offset + 1);
        }
        break;
      }
    }

    // editor.scheduleRemoveCodeCompletion();

    // This is a hack to get Safari (iOS) to send mutation events on
    // contenteditable.
    // TODO(ahe): Move to onInput?
    var newDiv = new DivElement();
    hackDiv.replaceWith(newDiv);
    hackDiv = newDiv;
  }

  // TODO(ahe): This method should be cleaned up. It is too large.
  void onMutation(List<MutationRecord> mutations, MutationObserver observer) {
    print('onMutation');

    List<Node> highlighting = mainEditorPane.querySelectorAll(
        'a.diagnostic>span, .dart-code-completion, .hazed-suggestion');
    for (Element element in highlighting) {
      element.remove();
    }

    Selection selection = window.getSelection();
    Node anchorNode = selection.anchorNode;
    int anchorOffset = selection.isCollapsed ? selection.anchorOffset : -1;

    for (MutationRecord record in mutations) {
      if (record.addedNodes.isEmpty) continue;
      for (Node node in record.addedNodes) {
        if (node.parent == null) continue;
        StringBuffer buffer = new StringBuffer();
        int selectionOffset = htmlToText(node, buffer, selection);
        Text newNode = new Text('$buffer');
        node.replaceWith(newNode);
        if (selectionOffset != -1) {
          anchorNode = newNode;
          anchorOffset = selectionOffset;
        }
      }
    }

    String currentText = mainEditorPane.text;
    TrySelection trySelection =
        new TrySelection(mainEditorPane, selection, currentText);

    context.currentCompilationUnit.content = currentText;

    editor.seenIdentifiers = new Set<String>.from(mock.identifiers);

    editor.isMalformedInput = false;
    int offset = 0;
    List<Node> nodes = <Node>[];
    //   + offset  + charOffset  + globalOffset   + (charOffset + charCount)
    //   v         v             v                v
    // do          identifier_abcdefghijklmnopqrst
    for (Token token = tokenize(currentText);
         token.kind != EOF_TOKEN;
         token = token.next) {
      int charOffset = token.charOffset;
      int charCount = token.charCount;

      if (charOffset < offset) continue; // Happens for scanner errors.

      Decoration decoration = editor.getDecoration(token);
      if (decoration == null) continue;

      // Add a node for text before current token.
      trySelection.addNodeFromSubstring(offset, charOffset, nodes);

      // Add a node for current token.
      trySelection.addNodeFromSubstring(
          charOffset, charOffset + charCount, nodes, decoration);

      offset = charOffset + charCount;
    }

    // Add a node for anything after the last (decorated) token.
    trySelection.addNodeFromSubstring(offset, currentText.length, nodes);

    // Ensure text always ends with a newline.
    if (!currentText.endsWith('\n')) {
      nodes.add(new Text('\n'));
    }

    mainEditorPane
        ..nodes.clear()
        ..nodes.addAll(nodes);
    trySelection.adjust(selection);

    // Discard highlighting mutations.
    observer.takeRecords();
  }

  void onSelectionChange(Event event) {
  }

  void onStateChanged(InteractionState previous) {
    super.onStateChanged(previous);
    scheduleCompilation();
  }

  void onCompilationUnitChanged(CompilationUnit unit) {
    if (unit == context.currentCompilationUnit) {
      currentSource = unit.content;
      print("Saved source of '${unit.name}'");
      if (context.projectFiles.containsKey(unit.name)) {
        postProjectFileUpdate(unit);
      }
      scheduleCompilation();
    } else {
      print("Unexpected change to compilation unit '${unit.name}'.");
    }
  }

  void postProjectFileUpdate(CompilationUnit unit) {
    onError(ProgressEvent event) {
      HttpRequest request = event.target;
      window.alert("Couldn't save '${unit.name}': ${request.responseText}");
    }
    new HttpRequest()
        ..open("POST", "/project/${unit.name}")
        ..onError.listen(onError)
        ..send(unit.content);
  }

  Future<List<String>> projectFileNames() {
    return getString('project?list').then((String response) {
      WebSocket socket = new WebSocket('ws://127.0.0.1:9090/ws/watch');
      socket.onMessage.listen((MessageEvent e) {
        print(e.data);
      });
      return new List<String>.from(JSON.decode(response));
    });
  }

  void onProjectFileSelected(String projectFile) {
    // Disable editing whilst fetching data.
    mainEditorPane.contentEditable = 'false';

    CompilationUnit unit = context.projectFiles[projectFile];
    Future<CompilationUnit> future;
    if (unit != null) {
      // This project file had been fetched already.
      future = new Future<CompilationUnit>.value(unit);

      // TODO(ahe): Probably better to fetch the sources again.
    } else {
      // This project file has to be fetched.
      future = getString('project/$projectFile').then((String text) {
        CompilationUnit unit = context.projectFiles[projectFile];
        if (unit == null) {
          // Only create a new unit if the value hadn't arrived already.
          unit = new CompilationUnit(projectFile, text);
          context.projectFiles[projectFile] = unit;
        } else {
          // TODO(ahe): Probably better to overwrite sources. Create a new
          // unit?
          // The server should push updates to the client.
        }
        return unit;
      });
    }
    future.then((CompilationUnit unit) {
      mainEditorPane
          ..contentEditable = 'true'
          ..nodes.clear();
      observer.takeRecords(); // Discard mutations.

      transitionToInitialState();
      context.currentCompilationUnit = unit;

      // Install the code, which will trigger a call to onMutation.
      mainEditorPane.appendText(unit.content);
    });
  }

  void transitionToInitialState() {}
}

Future<String> getString(uri) {
  return new Future<String>.sync(() => HttpRequest.getString('$uri'));
}

class PendingInputState extends InitialState {
  PendingInputState(InteractionContext context)
      : super(context);

  void onInput(Event event) {
    // Do nothing.
  }

  void onMutation(List<MutationRecord> mutations, MutationObserver observer) {
    super.onMutation(mutations, observer);

    InteractionState nextState = new InitialState(context);
    if (settings.enableCodeCompletion.value) {
      Element parent = editor.getElementAtSelection();
      Element ui;
      if (parent != null) {
        ui = parent.querySelector('.dart-code-completion');
        if (ui != null) {
          nextState = new CodeCompletionState(context, parent, ui);
        }
      }
    }
    state = nextState;
  }
}

class CodeCompletionState extends InitialState {
  final Element activeCompletion;
  final Element ui;
  int minWidth = 0;
  DivElement staticResults;
  SpanElement inline;
  DivElement serverResults;
  String inlineSuggestion;

  CodeCompletionState(InteractionContext context,
                      this.activeCompletion,
                      this.ui)
      : super(context);

  void onInput(Event event) {
    // Do nothing.
  }

  void onModifiedKeyUp(KeyboardEvent event) {
    // TODO(ahe): Handle DOWN (jump to server results).
  }

  void onUnmodifiedKeyUp(KeyboardEvent event) {
    switch (event.keyCode) {
      case KeyCode.DOWN:
        return moveDown(event);

      case KeyCode.UP:
        return moveUp(event);

      case KeyCode.ESC:
        event.preventDefault();
        return endCompletion();

      case KeyCode.TAB:
      case KeyCode.RIGHT:
      case KeyCode.ENTER:
        event.preventDefault();
        return endCompletion(acceptSuggestion: true);
    }
  }

  void moveDown(Event event) {
    event.preventDefault();
    move(1);
  }

  void moveUp(Event event) {
    event.preventDefault();
    move(-1);
  }

  void move(int direction) {
    Element element = editor.moveActive(direction);
    if (element == null) return;
    var text = activeCompletion.firstChild;
    String prefix = "";
    if (text is Text) prefix = text.data.trim();
    updateInlineSuggestion(prefix, element.text);
  }

  void endCompletion({bool acceptSuggestion: false}) {
    if (acceptSuggestion) {
      suggestionAccepted();
    }
    activeCompletion.classes.remove('active');
    mainEditorPane.querySelectorAll('.hazed-suggestion')
        .forEach((e) => e.remove());
    // The above changes create mutation records. This implicitly fire mutation
    // events that result in saving the source code in local storage.
    // TODO(ahe): Consider making this more explicit.
    state = new InitialState(context);
  }

  void suggestionAccepted() {
    if (inlineSuggestion != null) {
      Text text = new Text(inlineSuggestion);
      activeCompletion.replaceWith(text);
      window.getSelection().collapse(text, inlineSuggestion.length);
    }
  }

  void onMutation(List<MutationRecord> mutations, MutationObserver observer) {
    for (MutationRecord record in mutations) {
      if (!activeCompletion.contains(record.target)) {
        endCompletion();
        return super.onMutation(mutations, observer);
      }
    }

    var text = activeCompletion.firstChild;
    if (text is! Text) return endCompletion();
    updateSuggestions(text.data.trim());
  }

  void onStateChanged(InteractionState previous) {
    super.onStateChanged(previous);
    displayCodeCompletion();
  }

  void displayCodeCompletion() {
    Selection selection = window.getSelection();
    if (selection.anchorNode is! Text) {
      return endCompletion();
    }
    Text text = selection.anchorNode;
    if (!activeCompletion.contains(text)) {
      return endCompletion();
    }

    int anchorOffset = selection.anchorOffset;

    String prefix = text.data.substring(0, anchorOffset).trim();
    if (prefix.isEmpty) {
      return endCompletion();
    }

    num height = activeCompletion.getBoundingClientRect().height;
    activeCompletion.classes.add('active');
    ui.nodes.clear();

    inline = new SpanElement()
        ..classes.add('hazed-suggestion');
    Text rest = text.splitText(anchorOffset);
    text.parentNode.insertBefore(inline, text.nextNode);
    activeCompletion.parentNode.insertBefore(
        rest, activeCompletion.nextNode);

    staticResults = new DivElement()
        ..classes.addAll(['dart-static', 'dart-limited-height']);
    serverResults = new DivElement()
        ..style.display = 'none'
        ..classes.add('dart-server');
    ui.nodes.addAll([staticResults, serverResults]);
    ui.style.top = '${height}px';

    staticResults.nodes.add(buildCompletionEntry(prefix));

    updateSuggestions(prefix);
  }

  void updateInlineSuggestion(String prefix, String suggestion) {
    inlineSuggestion = suggestion;

    minWidth = max(minWidth, activeCompletion.getBoundingClientRect().width);

    activeCompletion.style
        ..display = 'inline-block'
        ..minWidth = '${minWidth}px';

    inline
        ..nodes.clear()
        ..appendText(suggestion.substring(prefix.length))
        ..style.display = '';

    observer.takeRecords(); // Discard mutations.
  }

  void updateSuggestions(String prefix) {
    if (prefix.isEmpty) {
      return endCompletion();
    }

    Token first = tokenize(prefix);
    for (Token token = first; token.kind != EOF_TOKEN; token = token.next) {
      String tokenInfo = token.info.value;
      if (token != first ||
          tokenInfo != 'identifier' &&
          tokenInfo != 'keyword') {
        return endCompletion();
      }
    }

    var borderHeight = 2; // 1 pixel border top & bottom.
    num height = ui.getBoundingClientRect().height - borderHeight;
    ui.style.minHeight = '${height}px';

    minWidth =
        max(minWidth, activeCompletion.getBoundingClientRect().width);

    staticResults.nodes.clear();
    serverResults.nodes.clear();

    if (inlineSuggestion != null && inlineSuggestion.startsWith(prefix)) {
      inline
          ..nodes.clear()
          ..appendText(inlineSuggestion.substring(prefix.length));
    }

    List<String> results = editor.seenIdentifiers.where(
        (String identifier) {
          return identifier != prefix && identifier.startsWith(prefix);
        }).toList(growable: false);
    results.sort();
    if (results.isEmpty) results = <String>[prefix];

    results.forEach((String completion) {
      staticResults.nodes.add(buildCompletionEntry(completion));
    });

    if (settings.enableDartMind) {
      // TODO(ahe): Move this code to its own function or class.
      String encodedArg0 = Uri.encodeComponent('"$prefix"');
      String mindQuery =
          'http://dart-mind.appspot.com/rpc'
          '?action=GetExportingPubCompletions'
          '&arg0=$encodedArg0';
      try {
        var serverWatch = new Stopwatch()..start();
        HttpRequest.getString(mindQuery).then((String responseText) {
          serverWatch.stop();
          List<String> serverSuggestions = JSON.decode(responseText);
          if (!serverSuggestions.isEmpty) {
            updateInlineSuggestion(prefix, serverSuggestions.first);
          }
          for (int i = 1; i < serverSuggestions.length; i++) {
            String completion = serverSuggestions[i];
            DivElement where = staticResults;
            int index = results.indexOf(completion);
            if (index != -1) {
              List<Element> entries =
                  document.querySelectorAll('.dart-static>.dart-entry');
              entries[index].classes.add('doubleplusgood');
            } else {
              if (results.length > 3) {
                serverResults.style.display = 'block';
                where = serverResults;
              }
              Element entry = buildCompletionEntry(completion);
              entry.classes.add('doubleplusgood');
              where.nodes.add(entry);
            }
          }
          serverResults.appendHtml(
              '<div>${serverWatch.elapsedMilliseconds}ms</div>');
          // Discard mutations.
          observer.takeRecords();
        }).catchError((error, stack) {
          window.console.dir(error);
          window.console.error('$stack');
        });
      } catch (error, stack) {
        window.console.dir(error);
        window.console.error('$stack');
      }
    }
    // Discard mutations.
    observer.takeRecords();
  }

  Element buildCompletionEntry(String completion) {
    return new DivElement()
        ..classes.add('dart-entry')
        ..appendText(completion);
  }

  void transitionToInitialState() {
    endCompletion();
  }
}

Token tokenize(String text) {
  var file = new StringSourceFile('', text);
  return new StringScanner(file, includeComments: true).tokenize();
}

bool computeHasModifier(KeyboardEvent event) {
  return
      event.getModifierState("Alt") ||
      event.getModifierState("AltGraph") ||
      event.getModifierState("CapsLock") ||
      event.getModifierState("Control") ||
      event.getModifierState("Fn") ||
      event.getModifierState("Meta") ||
      event.getModifierState("NumLock") ||
      event.getModifierState("ScrollLock") ||
      event.getModifierState("Scroll") ||
      event.getModifierState("Win") ||
      event.getModifierState("Shift") ||
      event.getModifierState("SymbolLock") ||
      event.getModifierState("OS");
}
