// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.ui;

import 'dart:html';

import 'dart:async' show
    scheduleMicrotask;

import 'cache.dart' show
    onLoad,
    updateCacheStatus;

import 'editor.dart' show
    onKeyUp,
    onMutation;

import 'run.dart' show
    makeOutputFrame;

import 'themes.dart' show
    THEMES,
    Theme;

import 'samples.dart' show
    EXAMPLE_FIBONACCI,
    EXAMPLE_FIBONACCI_HTML,
    EXAMPLE_HELLO,
    EXAMPLE_HELLO_HTML,
    EXAMPLE_SUNFLOWER;

DivElement inputPre;
PreElement outputDiv;
DivElement hackDiv;
IFrameElement outputFrame;
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
