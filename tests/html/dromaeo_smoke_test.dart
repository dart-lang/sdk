// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dromaeo;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import '../../samples/third_party/dromaeo/Dromaeo.dart' as originalTest;
import 'dart:html';
import 'dart:async';

/** A variant of the Dromaeo test shoehorned into a unit test. */
void main() {
  var combo = '?dartANDhtmlANDnothing';
  if (!window.location.search.toString().contains(combo)) {
    if (window.location.href.toString().indexOf("?") == -1) {
      window.location.href = '${window.location.href}${combo}';
    } else {
      window.location.href = '${window.location.href.toString().substring(0,
          window.location.href.toString().indexOf("?"))}${combo}';
    }
  }

  useHtmlConfiguration();

  var scriptSrc = new ScriptElement();
  scriptSrc.src = '/root_dart/pkg/browser/lib/dart.js';
  document.head.children.add(scriptSrc);
  document.body.innerHtml = '''${document.body.innerHtml}
  <div id="main">
    <h1 id="overview" class="test"><span>Performance Tests</span>
    <input type="button" id="pause" class="pause" value="Loading..."/>
    <div class="bar">
      <div id="timebar" style="width:25%;">
        <span class="left">Est.&nbsp;Time:&nbsp;<strong id="left">0:00</strong>
        </span>
      </div>
    </div>
    <ul id="tests">
      <li><a href="?dom">Smoke Tests</a></li>
    </ul>
  </div>''';

  bool isDone = false;
  originalTest.main();

  test('dromaeo runs', () {
    new Timer.periodic(new Duration(milliseconds: 500),
                       expectAsyncUntil1((timer) {
      if (document.query('.alldone') != null) {
        timer.cancel();
        isDone = true;
      }
    }, () => isDone));
  });
}
