// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.editor;

import 'dart:html';

import '../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart'
  show
    EOF_TOKEN,
    StringScanner,
    Token;

import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart' show
    StringSourceFile;

import 'compilation.dart' show
    scheduleCompilation;

import 'ui.dart' show
    currentTheme,
    hackDiv,
    inputPre,
    observer,
    outputDiv;

import 'decoration.dart' show
    Decoration,
    DiagnosticDecoration,
    error,
    info,
    warning;

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
        // TODO(ahe): Don't highlight everything in the node.  Find the
        // relevant token (works for now as we create a node for each token,
        // which is probably not great for performance).
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

Decoration getDecoration(Token token) {
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
  return currentTheme.foreground;
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
