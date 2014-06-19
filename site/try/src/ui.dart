// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.ui;

import 'dart:html';

import 'dart:async' show
    Future,
    Timer,
    scheduleMicrotask;

import 'cache.dart' show
    onLoad,
    updateCacheStatus;

import 'interaction_manager.dart' show InteractionManager;

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

import 'settings.dart';

import 'user_option.dart';

import 'messages.dart' show messages;

import 'compilation_unit.dart' show
    CompilationUnit;

import 'compilation.dart' show
    currentSource;

// TODO(ahe): Make internal to buildUI once all interactions have been moved to
// the manager.
InteractionManager interaction;

DivElement mainEditorPane;
DivElement statusDiv;
PreElement outputDiv;
DivElement hackDiv;
IFrameElement outputFrame;
MutationObserver observer;
SpanElement cacheStatusElement;
Theme currentTheme = Theme.named(theme);

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
    parent.parent.querySelector('li[class="active"]').classes.remove('active');
    parent.classes.add('active');
    action(event);
  }

  codeCallbacks[id] = action;

  return new OptionElement()..append(message)..id = id;
}

Map<String, Function> codeCallbacks = new Map<String, Function>();

void onCodeChange(Event event) {
  SelectElement select = event.target;
  String id = select.querySelectorAll('option')[select.selectedIndex].id;
  Function action = codeCallbacks[id];
  if (action != null) action(event);
  outputFrame.style.display = 'none';
}

buildUI() {
  interaction = new InteractionManager();

  CompilationUnit.onChanged.listen(interaction.onCompilationUnitChanged);

  window.localStorage['currentSample'] = '$currentSample';

  buildCode(interaction);

  (mainEditorPane = new DivElement())
      ..classes.addAll(['mainEditorPane'])
      ..style.backgroundColor = currentTheme.background.color
      ..style.color = currentTheme.foreground.color
      ..style.font = codeFont
      ..spellcheck = false;

  mainEditorPane
      ..contentEditable = 'true'
      ..onKeyDown.listen(interaction.onKeyUp)
      ..onInput.listen(interaction.onInput);

  document.onSelectionChange.listen(interaction.onSelectionChange);

  var inputWrapper = new DivElement()
      ..append(mainEditorPane)
      ..classes.add('well')
      ..style.padding = '0px'
      ..style.overflowX = 'hidden'
      ..style.overflowY = 'scroll'
      ..style.position = 'relative'
      ..style.maxHeight = '80vh';

  var inputHeader = new DivElement()..appendText('Code');

  inputHeader.style
      ..right = '3px'
      ..top = '0px'
      ..position = 'absolute';
  inputWrapper.append(inputHeader);

  statusDiv = new DivElement();
  statusDiv.style
      ..left = '0px'
      ..top = '0px'
      ..position = 'absolute';
  inputWrapper.append(statusDiv);

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
            Url.createObjectUrl(new Blob([mainEditorPane.text], 'text/plain'));
        var save = new AnchorElement(href: blobUrl);
        save.target = '_blank';
        save.download = 'untitled.dart';
        save.dispatchEvent(new Event.eventType('Event', 'click'));
      })
      ..style.position = 'absolute'
      ..style.right = '0px'
      ..appendText('Save');

  cacheStatusElement = document.getElementById('appcache-status');
  updateCacheStatus(null);

  var section = document.querySelector('article[class="homepage"]>section');

  DivElement tryColumn = document.getElementById('try-dart-column');
  DivElement runColumn = document.getElementById('run-dart-column');

  tryColumn.append(inputWrapper);
  outputFrame.style.display = 'none';
  runColumn.append(outputFrame);
  runColumn.append(outputWrapper);
  runColumn.append(hackDiv);

  var settingsElement = document.getElementById('settings');
  settingsElement.onClick.listen(openSettings);

  window.onMessage.listen(interaction.onMessage);

  observer = new MutationObserver(interaction.onMutation)
      ..observe(
          mainEditorPane, childList: true, characterData: true, subtree: true);

  scheduleMicrotask(() {
    mainEditorPane.appendText(currentSource);
  });

  // You cannot install event handlers on window.applicationCache
  // until the window has loaded.  In dartium, that's later than this
  // method is called.
  window.onLoad.listen(onLoad);

  // However, in dart2js, the window has already loaded, and onLoad is
  // never called.
  onLoad(null);
}

buildCode(InteractionManager interaction) {
  var codePicker =
      document.getElementById('code-picker')
      ..style.visibility = 'hidden'
      ..onChange.listen(onCodeChange);
  var htmlGroup = new OptGroupElement()..label = 'HTML';
  var benchmarkGroup = new OptGroupElement()..label = 'Benchmarks';

  interaction.projectFileNames().then((List<String> names) {
    OptionElement none = new OptionElement()
        ..appendText('--')
        ..disabled = true;
    codePicker
        ..append(none)
        ..style.visibility = 'visible'
        ..selectedIndex = 0;

    for (String name in names) {
      codePicker.append(buildTab(name, name, (event) {
        interaction.onProjectFileSelected(name);
      }));
    }
  }).catchError((error) {
    codePicker.style.visibility = 'visible';
    OptionElement none = new OptionElement()
        ..appendText('Pick an example')
        ..disabled = true;
    codePicker.append(none);

    // codePicker.classes.addAll(['nav', 'nav-tabs']);
    codePicker.append(buildTab('Hello, World!', 'EXAMPLE_HELLO', (_) {
      mainEditorPane
          ..nodes.clear()
          ..appendText(EXAMPLE_HELLO);
    }));
    codePicker.append(buildTab('Fibonacci', 'EXAMPLE_FIBONACCI', (_) {
      mainEditorPane
          ..nodes.clear()
          ..appendText(EXAMPLE_FIBONACCI);
    }));
    codePicker.append(htmlGroup);
    // TODO(ahe): Restore benchmarks.
    // codePicker.append(benchmarkGroup);

    htmlGroup.append(
        buildTab('Hello, World!', 'EXAMPLE_HELLO_HTML', (_) {
      mainEditorPane
          ..nodes.clear()
          ..appendText(EXAMPLE_HELLO_HTML);
    }));
    htmlGroup.append(
        buildTab('Fibonacci', 'EXAMPLE_FIBONACCI_HTML', (_) {
      mainEditorPane
          ..nodes.clear()
          ..appendText(EXAMPLE_FIBONACCI_HTML);
    }));
    htmlGroup.append(buildTab('Sunflower', 'EXAMPLE_SUNFLOWER', (_) {
      mainEditorPane
          ..nodes.clear()
          ..appendText(EXAMPLE_SUNFLOWER);
    }));

    benchmarkGroup.append(buildTab('DeltaBlue', 'BENCHMARK_DELTA_BLUE', (_) {
      mainEditorPane.contentEditable = 'false';
      LinkElement link = querySelector('link[rel="benchmark-DeltaBlue"]');
      String deltaBlueUri = link.href;
      link = querySelector('link[rel="benchmark-base"]');
      String benchmarkBaseUri = link.href;
      HttpRequest.getString(benchmarkBaseUri).then((String benchmarkBase) {
        HttpRequest.getString(deltaBlueUri).then((String deltaBlue) {
          benchmarkBase = benchmarkBase.replaceFirst(
              'part of benchmark_harness;', '// part of benchmark_harness;');
          deltaBlue = deltaBlue.replaceFirst(
              "import 'package:benchmark_harness/benchmark_harness.dart';",
              benchmarkBase);
          mainEditorPane
              ..nodes.clear()
              ..appendText(deltaBlue)
              ..contentEditable = 'true';
        });
      });
    }));

    benchmarkGroup.append(buildTab('Richards', 'BENCHMARK_RICHARDS', (_) {
      mainEditorPane.contentEditable = 'false';
      LinkElement link = querySelector('link[rel="benchmark-Richards"]');
      String richardsUri = link.href;
      link = querySelector('link[rel="benchmark-base"]');
      String benchmarkBaseUri = link.href;
      HttpRequest.getString(benchmarkBaseUri).then((String benchmarkBase) {
        HttpRequest.getString(richardsUri).then((String richards) {
          benchmarkBase = benchmarkBase.replaceFirst(
              'part of benchmark_harness;', '// part of benchmark_harness;');
          richards = richards.replaceFirst(
              "import 'package:benchmark_harness/benchmark_harness.dart';",
              benchmarkBase);
          mainEditorPane
              ..nodes.clear()
              ..appendText(richards)
              ..contentEditable = 'true';
        });
      });
    }));

    codePicker.selectedIndex = 0;
  });
}

num settingsHeight = 0;

void openSettings(MouseEvent event) {
  event.preventDefault();

  if (settingsHeight != 0) {
    var dialog = document.getElementById('settings-dialog');
    if (dialog.getBoundingClientRect().height > 0) {
      dialog.style.height = '0px';
    } else {
      dialog.style.height = '${settingsHeight}px';
    }
    return;
  }

  void updateCodeFont(Event e) {
    TextInputElement target = e.target;
    codeFont = target.value;
    mainEditorPane.style.font = codeFont;
  }

  void updateTheme(Event e) {
    var select = e.target;
    String theme = select.queryAll('option')[select.selectedIndex].text;
    window.localStorage['theme'] = theme;
    currentTheme = Theme.named(theme);

    mainEditorPane.style
        ..backgroundColor = currentTheme.background.color
        ..color = currentTheme.foreground.color;

    outputDiv.style
        ..backgroundColor = currentTheme.background.color
        ..color = currentTheme.foreground.color;

    bool oldCompilationPaused = compilationPaused;
    compilationPaused = true;
    interaction.onMutation([], observer);
    compilationPaused = false;
  }

  var body = document.getElementById('settings-body');

  body.nodes.clear();

  var form = new FormElement();
  var fieldSet = new FieldSetElement();
  body.append(form);
  form.append(fieldSet);

  bool isChecked(CheckboxInputElement checkBox) => checkBox.checked;

  String messageFor(UserOption option) {
    var message = messages[option.name];
    if (message is List) message = message[0];
    return (message == null) ? option.name : message;
  }

  String placeHolderFor(UserOption option) {
    var message = messages[option.name];
    if (message is! List) return '';
    message = message[1];
    return (message == null) ? '' : message;
  }

  void addBooleanOption(BooleanUserOption option) {
    CheckboxInputElement checkBox = new CheckboxInputElement()
        ..checked = option.value
        ..onChange.listen((Event e) { option.value = isChecked(e.target); });

    LabelElement label = new LabelElement()
        ..classes.add('checkbox')
        ..append(checkBox)
        ..appendText(' ${messageFor(option)}');

    fieldSet.append(label);
  }

  void addStringOption(StringUserOption option) {
    fieldSet.append(new LabelElement()..appendText(messageFor(option)));
    var textInput = new TextInputElement();
    textInput.classes.add('input-block-level');
    String value = option.value;
    if (!value.isEmpty) {
      textInput.value = value;
    }
    textInput.placeholder = placeHolderFor(option);;
    textInput.onChange.listen(updateCodeFont);
    fieldSet.append(textInput);
  }

  void addThemeOption(StringUserOption option) {
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
  }

  for (UserOption option in options) {
    if (option.isHidden) continue;
    if (option.name == 'theme') {
      addThemeOption(option);
    } else if (option is BooleanUserOption) {
      addBooleanOption(option);
    } else if (option is StringUserOption) {
      addStringOption(option);
    }
  }

  var dialog = document.getElementById('settings-dialog');

  if (settingsHeight == 0) {
    settingsHeight = dialog.getBoundingClientRect().height;
    dialog.classes
        ..add('slider')
        ..remove('myhidden');
    Timer.run(() {
      dialog.style.height = '${settingsHeight}px';
    });
  } else {
    dialog.style.height = '${settingsHeight}px';
  }

  onSubmit(Event event) {
    event.preventDefault();

    window.localStorage['alwaysRunInWorker'] = '$alwaysRunInWorker';
    window.localStorage['verboseCompiler'] = '$verboseCompiler';
    window.localStorage['minified'] = '$minified';
    window.localStorage['onlyAnalyze'] = '$onlyAnalyze';
    window.localStorage['enableDartMind'] = '$enableDartMind';
    window.localStorage['compilationPaused'] = '$compilationPaused';
    window.localStorage['codeFont'] = '$codeFont';

    dialog.style.height = '0px';
  }
  form.onSubmit.listen(onSubmit);

  var doneButton = document.getElementById('settings-done');
  doneButton.onClick.listen(onSubmit);
}
