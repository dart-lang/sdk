// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library provides a single function called injectLogs which when called
/// will request a logs json file and build a small widget out of them which
/// groups the logs by level.
library polymer.build.log_injector;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:code_transformers/messages/messages.dart';

class LogInjector {
  Element selectedMenu;
  Element selectedContent;

  // Gets the logs from a url and inject them into the dom.
  Future injectLogsFromUrl(String url) =>
      HttpRequest.getString(url).then((data) => injectLogs(data));

  // Builds the html for the logs element given some logs, and injects that
  // into the dom. Currently, we do not  use Polymer just to ensure that the
  // page works regardless of the state of the app. Ideally, we could have
  // multiple scripts running independently so we could ensure that this would
  // always be running.
  injectLogs(String data) {
    var logs = new LogEntryTable.fromJson(JSON.decode(data));
    if (logs.entries.isEmpty) return;

    // Group all logs by level.
    var logsByLevel = {
    };
    logs.entries.values.forEach((list) => list.forEach((log) {
      logsByLevel.putIfAbsent(log.level, () => []);
      logsByLevel[log.level].add(log);
    }));
    if (logsByLevel.isEmpty) return;

    // Build the wrapper, menu, and content divs.

    var menuWrapper = new DivElement()
      ..classes.add('menu');
    var contentWrapper = new DivElement()
      ..classes.add('content');
    var wrapperDiv = new DivElement()
      ..classes.add('build-logs')
      ..append(menuWrapper)
      ..append(contentWrapper);

    // For each log level, add a menu item, content section, and all the logs.
    logsByLevel.forEach((level, logs) {
      var levelClassName = level.toLowerCase();

      // Add the menu item and content item.
      var menuItem = new Element.html(
          '<div class="$levelClassName">'
          '$level <span class="num">(${logs.length})</span>'
          '</div>');
      menuWrapper.append(menuItem);
      var contentItem = new DivElement()
        ..classes.add(levelClassName);
      contentWrapper.append(contentItem);

      // Set up the click handlers.
      menuItem.onClick.listen((_) {
        if (selectedMenu == menuItem) {
          selectedMenu = null;
          selectedContent = null;
        } else {
          if (selectedMenu != null) {
            selectedMenu.classes.remove('active');
            selectedContent.classes.remove('active');
          }

          selectedMenu = menuItem;
          selectedContent = contentItem;
        }

        menuItem.classes.toggle('active');
        contentItem.classes.toggle('active');
      });

      // Add the logs to the content item.
      for (var log in logs) {
        var logHtml = new StringBuffer();
        logHtml.write('<div class="log">');

        var id = log.message.id;
        var hashTag = '${id.package}_${id.id}';
        var message = new HtmlEscape().convert(log.message.snippet);
        message.replaceAllMapped(_urlRegex,
            (m) => '<a href="${m.group(0)}" target="blank">${m.group(0)}</a>');
        logHtml.write('<div class="message $levelClassName">$message '
            '<a target="blank" href='
            '"/packages/polymer/src/build/generated/messages.html#$hashTag">'
            '(more details)</a></div>');
        var span = log.span;
        if (span != null) {
          logHtml.write('<div class="location">');
          var text = new HtmlEscape().convert(span.text);
          logHtml.write(
              '  <span class="location">${span.start.toolString}</span></div>'
              '  <span class="text">$text</span>''</div>');
          logHtml.write('</div>');
        }
        logHtml.write('</div>');

        var logElement = new Element.html(logHtml.toString(),
            validator: new NodeValidatorBuilder.common()
              ..allowNavigation(new _OpenUriPolicy()));
        contentItem.append(logElement);
        var messageElement = logElement.querySelector('.message');
        messageElement.onClick.listen((e) {
          if (e.target == messageElement) {
            messageElement.classes.toggle('expanded');
          }
        });
      };
    });

    document.body.append(wrapperDiv);
  }

}

final _urlRegex = new RegExp('http://[^ ]*');
class _OpenUriPolicy implements UriPolicy {
  bool allowsUri(String uri) => true;
}
