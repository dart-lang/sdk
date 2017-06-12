// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

/**
 * An informational dialog that shows keyboard shortcuts and provides a
 * link to the Dart language webpage.
 */
//TODO(efortuna): fix DialogView so it doesn't require the HTML passed to
// the constructor.
class HelpDialog extends DialogView {
  CompositeView _parent;
  Function _doneHandler;

  HelpDialog(this._parent, this._doneHandler)
      : super('Information', '', makeContent());

  void onDone() {
    _doneHandler();
  }

  static View makeContent() {
    return new View.html('''
        <div>

          <p>
          Keyboard shortcuts:
          ${generateTableHtml()}
          </p>

          <p>
          <div id="dart-logo">
          <a href="http://dartlang.org">
          Dart, the programming language</a>.
          </div>
          </p>
        </div>
        ''');
  }

  static String generateTableHtml() {
    String cellStart = '''<th valign="middle" align="center">''';
    return '''<table width="90%" border=1 cellspacing="0" cellpadding="2">
            <tr bgcolor="#c3d9ff">
              ${cellStart} Shortcut Key </th>
              ${cellStart} Action </th>
            </tr>
            <tr>
              ${cellStart} j, &lt;down arrow&gt; </th>
              ${cellStart} Next Article </th>
            </tr>
            <tr>
              ${cellStart} k, &lt;up arrow&gt; </th>
              ${cellStart} Previous Article </th>
            </tr>
            <tr>
              ${cellStart} o, &lt;enter&gt; </th>
              ${cellStart} Open Article </th>
            </tr>
            <tr>
              ${cellStart} &lt;esc&gt;, &lt;delete&gt; </th>
              ${cellStart} Back </th>
            </tr>
            <tr>
              ${cellStart} a, h, &lt;left arrow&gt; </th>
              ${cellStart} Left </th>
            </tr>
            <tr>
              ${cellStart} d, l, &lt;right arrow&gt; </th>
              ${cellStart} Right </th>
            </tr>
            <tr>
              ${cellStart} n </th>
              ${cellStart} Next Category </th>
            </tr>
            <tr>
              ${cellStart} p </th>
              ${cellStart} Previous Category </th>
            </tr>

        </table>''';
  }
}
