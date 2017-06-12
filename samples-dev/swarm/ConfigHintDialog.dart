// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

/** A placeholder dialog that just passes the buck to Reader on feed
    configuration. */
class ConfigHintDialog extends DialogView {
  CompositeView _parent;
  Function _doneHandler;

  factory ConfigHintDialog(CompositeView parent, Function doneHandler) {
    View content = ConfigHintDialog.makeContent();
    return new ConfigHintDialog._impl(parent, doneHandler, content);
  }

  ConfigHintDialog._impl(this._parent, this._doneHandler, View content)
      : super('Feed configuration', '', content);

  void onDone() {
    _doneHandler();
  }

  static View makeContent() {
    return new View.html('''
        <div>
          Add or remove feeds in
          <a href="https://www.google.com/reader" target="_blank">
            Google Reader</a>'s "Subscriptions".
          Then come back here and click "Done" and we'll load your updated
          list of subscriptions.
        </div>
        ''');
  }
}
