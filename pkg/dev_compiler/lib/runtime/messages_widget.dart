// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library displays [MessageSummary]s from the Dart Dev Compiler.

import 'dart:convert';
import 'dart:html';

import 'package:dev_compiler/src/summary.dart';
import 'package:source_span/source_span.dart';

main() async {
  await window.animationFrame;
  displayMessages(await HttpRequest.getString('messages.json'));
}

void displayMessages(String data) {
  var summary = GlobalSummary.parse(JSON.decode(data));
  var messagesByLevel = _getMessagesByLevel(summary);
  if (messagesByLevel.isEmpty) return;

  // Build the wrapper, menu, and content divs.
  var menuWrapper = new DivElement()..classes.add('menu');
  var contentWrapper = new DivElement()..classes.add('content');
  var wrapperDiv = new DivElement()
    ..classes.add('dev-compiler-messages')
    ..append(menuWrapper)
    ..append(contentWrapper);

  var selectedMenu = new _Selection();
  var selectedContent = new _Selection();

  // Add a menu item, content section, and messages for each log level.
  messagesByLevel.forEach((level, messages) {
    var contentItem = new DivElement()..classes.add(level);
    var menuItem = new Element.html('<div class="$level">'
        '$level <span class="num">(${messages.length})</span>'
        '</div>');
    menuWrapper.append(menuItem);
    contentWrapper.append(contentItem);
    menuItem.onClick.listen((_) {
      selectedMenu.select(menuItem);
      selectedContent.select(contentItem);
    });

    // TODO(sigmund): add permanent links to error messages like in polymer.
    for (var m in messages) {
      var message = _hyperlinkUrls(_escape(m.message));
      var span = m.span;
      var sb = new StringBuffer();
      sb.write('<div class="message"><div class="text $level">$message</div>');
      if (span != null) {
        sb.write('<div class="location">'
            '  <span class="location">${span.start.toolString}</span></div>'
            '  <span class="text">');
        if (span is SourceSpanWithContext) {
          sb.write(_escape(span.context.substring(0, span.start.column)));
          sb.write('<span class="$level">');
          sb.write(_escape(span.text));
          sb.write('</span>');
          var end = span.start.column + span.text.length;
          sb.write(_escape(span.context.substring(end)));
        } else {
          sb.write(_escape(span.text));
        }
        sb.write('</span></div></div>');
      }
      sb.write('</div>');

      var logElement = new Element.html('$sb',
          validator: new NodeValidatorBuilder.common()
            ..allowNavigation(new _OpenUriPolicy()));
      contentItem.append(logElement);
      var messageElement = logElement.querySelector('div.text');
      messageElement.onClick.listen((e) {
        if (e.target == messageElement) {
          messageElement.classes.toggle('expanded');
        }
      });
    }
  });

  document.body.append(wrapperDiv);
}

/// Toggles classes to match which item of a list of items is selected.
class _Selection {
  Element _selected;

  select(Element newItem) {
    if (_selected == newItem) {
      _selected = null;
    } else {
      if (_selected != null) {
        _selected.classes.remove('active');
      }
      _selected = newItem;
    }
    newItem.classes.toggle('active');
  }
}

final _urlRegex = new RegExp('http://[^ ]*');
final _escaper = new HtmlEscape();
String _hyperlinkUrls(String text) => text.replaceAllMapped(_urlRegex,
    (m) => '<a href="${m.group(0)}" target="blank">${m.group(0)}</a>');
String _escape(String text) => _escaper.convert(text);

class _OpenUriPolicy implements UriPolicy {
  bool allowsUri(String uri) => true;
}

Map<String, List<MessageSummary>> _getMessagesByLevel(GlobalSummary messages) {
  var visitor = new _Visitor();
  messages.accept(visitor);
  return visitor.messagesByLevel;
}

class _Visitor extends RecursiveSummaryVisitor {
  final Map<String, List<MessageSummary>> messagesByLevel = {};

  @override
  void visitMessage(MessageSummary message) {
    var level = message.level.toLowerCase();
    messagesByLevel.putIfAbsent(level, () => []);
    messagesByLevel[level].add(message);
  }
}
