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

class LogInjector {
  Element selectedMenu;
  Element selectedContent;

  // Gets the logs from a url and inject them into the dom.
  Future injectLogsFromUrl([String url]) {
    if (url == null) url = '${Uri.base.path}._buildLogs';
    return HttpRequest.getString(url).then((data) => injectLogs(data));
  }

  // Builds the html for the logs element given some logs, and injects that
  // into the dom. Currently, we do not  use Polymer just to ensure that the
  // page works regardless of the state of the app. Ideally, we could have
  // multiple scripts running independently so we could ensure that this would
  // always be running.
  injectLogs(String data) {
    // Group all logs by level.
    var logsByLevel = {
    };
    JSON.decode(data).forEach((log) {
      logsByLevel.putIfAbsent(log['level'], () => []);
      logsByLevel[log['level']].add(log);
    });
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
        logHtml.write(
            '<div class="message $levelClassName">${log['message']}</div>');
        var assetId = log['assetId'];
        if (assetId != null) {
          logHtml.write(
              '<div class="asset">'
              '  <span class="package">${assetId['package']}</span>:'
              '  <span class="path">${assetId['path']}</span>''</div>');
        }
        var span = log['span'];
        if (span != null) {
          logHtml.write(
              '<div class="span">'
              '  <div class="location">${span['location']}</div>'
              '  <code class="text">${span['text']}</code>''</div>');
        }
        logHtml.write('</div>');

        contentItem.append(new Element.html(logHtml.toString()));
      };
    });

    document.body.append(wrapperDiv);
  }

}