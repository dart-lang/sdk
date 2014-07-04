// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.editor;

import 'dart:html';

import 'package:compiler/implementation/scanner/scannerlib.dart' show
    EOF_TOKEN,
    ErrorToken,
    StringScanner,
    Token;

import 'ui.dart' show
    currentTheme,
    hackDiv,
    interaction,
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

import 'selection.dart' show
    isCollapsed;

import 'shadow_root.dart' show
    getShadowRoot;

import 'settings.dart' as settings;

const String INDENT = '\u{a0}\u{a0}';

Set<String> seenIdentifiers;

Element moveActive(int distance, Node ui) {
  var /* ShadowRoot or Element */ root = getShadowRoot(ui);
  List<Element> entries = root.querySelectorAll('.dart-static>.dart-entry');
  int activeIndex = -1;
  for (var i = 0; i < entries.length; i++) {
    if (entries[i].classes.contains('activeEntry')) {
      activeIndex = i;
      break;
    }
  }
  int newIndex = activeIndex + distance;
  Element currentEntry;
  if (0 <= newIndex && newIndex < entries.length) {
    currentEntry = entries[newIndex];
  }
  if (currentEntry == null) return null;
  if (0 <= newIndex && activeIndex != -1) {
    entries[activeIndex].classes.remove('activeEntry');
  }
  Element staticNode = root.querySelector('.dart-static');
  String visibility = computeVisibility(currentEntry, staticNode);
  print(visibility);
  var serverResults = root.querySelectorAll('.dart-server>.dart-entry');
  var serverResultCount = serverResults.length;
  if (serverResultCount > 0) {
    switch (visibility) {
      case obscured:
      case hidden: {
        Rectangle cr = currentEntry.getBoundingClientRect();
        Rectangle sr = staticNode.getBoundingClientRect();
        Element entry = serverResults[0];
        entry.remove();
        currentEntry.parentNode.insertBefore(entry, currentEntry);
        currentEntry = entry;
        serverResultCount--;

        staticNode.style.maxHeight = '${sr.boundingBox(cr).height}px';
      }
    }
  } else {
    currentEntry.scrollIntoView();
  }
  if (serverResultCount == 0) {
    root.querySelector('.dart-server').style.display = 'none';
  }
  if (currentEntry != null) {
    currentEntry.classes.add('activeEntry');
  }
  // Discard mutations.
  observer.takeRecords();
  return currentEntry;
}

const visible = 'visible';
const obscured = 'obscured';
const hidden = 'hidden';

String computeVisibility(Element node, [Element parent]) {
  Rectangle nr = node.getBoundingClientRect();
  if (parent == null) parent = node.parentNode;
  Rectangle pr = parent.getBoundingClientRect();

  if (pr.containsRectangle(nr)) return visible;

  if (pr.intersects(nr)) return obscured;

  return hidden;
}

var activeCompletion;
num minSuggestionWidth = 0;

/// Returns the [Element] which encloses the current collapsed selection, if it
/// exists.
Element getElementAtSelection() {
  Selection selection = window.getSelection();
  if (!isCollapsed(selection)) return null;
  var anchorNode = selection.anchorNode;
  if (!mainEditorPane.contains(anchorNode)) return null;
  if (mainEditorPane == anchorNode) return null;
  int type = anchorNode.nodeType;
  if (type != Node.TEXT_NODE) return null;
  Text text = anchorNode;
  var parent = text.parent;
  if (parent is! Element) return null;
  if (mainEditorPane == parent) return null;
  return parent;
}

bool isMalformedInput = false;

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
        var alert;
        if (kind == 'error') {
          alert = error(message);
        } else if (kind == 'warning') {
          alert = warning(message);
        } else {
          alert = info(message);
        }
        Element parent = node.parent;
        if (parent.classes.contains("diagnostic") &&
            !interaction.oldDiagnostics.contains(parent)) {
          Element other = parent.lastChild;
          other.remove();
          SpanElement wrapper = new SpanElement();
          wrapper.style
              ..fontWeight = 'normal';
          var root = getShadowRoot(wrapper);
          if (root is ShadowRoot) {
            // When https://code.google.com/p/chromium/issues/detail?id=313458
            // is fixed:
            // var link = new LinkElement()
            //     ..rel = "stylesheet"
            //     ..type = "text/css"
            //     ..href = "dartlang-style.css";
            // root.append(link);
            root.append(
                new StyleElement()..text = '@import url(dartlang-style.css)');
          }
          root
              ..append(other)
              ..append(alert);
          other.style.display = 'block';
          alert.style.display = 'block';
          parent.append(wrapper);
        } else {
          if (interaction.oldDiagnostics.contains(parent)) {
            node.remove();
            parent.replaceWith(node);
          }
          Node marker = new Text("");
          node.replaceWith(marker);
          // TODO(ahe): Don't highlight everything in the node.  Find the
          // relevant token (works for now as we create a node for each token,
          // which is probably not great for performance).
          marker.replaceWith(diagnostic(node, alert));
          if (hasSelection) {
            selection.collapse(node, anchorOffset);
          }
        }
        foundNode = true;
        return;
      }
      offset = newOffset;
    } else if (type == Node.ELEMENT_NODE) {
      Element element = node;
      CssClassSet classes = element.classes;
      if (classes.contains('alert') ||
          classes.contains('dart-code-completion')) {
        return;
      }
    }

    var child = node.firstChild;
    while(child != null && !foundNode) {
      walk4(child);
      child = child.nextNode;
    }
  }
  walk4(mainEditorPane);

  if (!foundNode) {
    outputDiv.appendText('$message\n');
  }

  observer.takeRecords();
  observer.observe(
      mainEditorPane, childList: true, characterData: true, subtree: true);
}

Decoration getDecoration(Token token) {
  if (token is ErrorToken) {
    isMalformedInput = true;
    return new DiagnosticDecoration('error', token.assertionMessage);
  }
  String tokenValue = token.value;
  String tokenInfo = token.info.value;
  if (tokenInfo == 'string') return currentTheme.string;
  if (tokenInfo == 'identifier') {
    seenIdentifiers.add(tokenValue);
    Decoration decoration = currentTheme.foreground;
    if (settings.enableCodeCompletion.value) {
      decoration = CodeCompletionDecoration.from(decoration);
    }
    return decoration;
  }
  if (tokenInfo == 'keyword') return currentTheme.keyword;
  if (tokenInfo == 'comment') return currentTheme.singleLineComment;
  if (tokenInfo == 'malformed input') {
    isMalformedInput = true;
    return new DiagnosticDecoration('error', tokenValue);
  }
  return currentTheme.foreground;
}

diagnostic(content, tip) {
  if (content is String) {
    content = new Text(content);
  }
  if (content is! List) {
    content = [content];
  }
  return new AnchorElement()
      ..classes.add('diagnostic')
      ..append(tip) // Should be first for better Firefox editing.
      ..nodes.addAll(content);
}
