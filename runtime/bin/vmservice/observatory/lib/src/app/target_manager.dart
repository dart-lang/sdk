// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

class ChromiumTargetLister {
  /// Fetch the list of chromium [NetworkVMTargets].
  static Future<List<WebSocketVMTarget>> fetch(String networkAddress) {
    if (networkAddress == null) {
      return new Future.error(null);
    }
    var encoded = Uri.encodeComponent(networkAddress);
    var url = '/crdptargets/$encoded';
    return HttpRequest.getString(url).then((String responseText) {
      var list = JSON.decode(responseText);
      if (list == null) {
        return list;
      }
      for (var i = 0; i < list.length; i++) {
        list[i] = new WebSocketVMTarget.fromMap(list[i]);
      }
      return list;
    }).catchError((e) {
      // An error occured while getting the list of Chrome targets.
      // We eagerly request the list of targets, meaning this error can occur
      // regularly. By catching it and dropping it, we avoid spamming errors
      // on the console.
    });
  }
}

class TargetManager extends Observable {
  static const _historyKey = 'history';
  final SettingsGroup _settings = new SettingsGroup('targetManager');
  final List history = new ObservableList();
  WebSocketVMTarget defaultTarget;

  String _networkAddressOfDefaultTarget() {
    if (Utils.runningInJavaScript()) {
      // We are running as JavaScript, use the same host that Observatory has
      // been loaded from.
      return 'ws://${window.location.host}/ws';
    } else {
      // Otherwise, assume we are running from Dart Editor and want to connect
      // to the default host.
      return 'ws://localhost:8181/ws';
    }
  }
  TargetManager() {
    _restore();
    // Add a default standalone VM target.
    defaultTarget = findOrMake(_networkAddressOfDefaultTarget());
    assert(defaultTarget != null);
    add(defaultTarget);
  }

  void clearHistory() {
    history.clear();
    _store();
  }

  WebSocketVMTarget findOrMake(String networkAddress) {
    var target;
    target = _find(networkAddress);
    if (target != null) {
      return target;
    }
    target = new WebSocketVMTarget(networkAddress);
    return target;
  }

  /// Find by networkAddress.
  WebSocketVMTarget _find(String networkAddress) {
    var r;
    history.forEach((item) {
      if ((item.networkAddress == networkAddress) && (item.chrome == false)) {
        r = item;
      }
    });
    return r;
  }

  void add(WebSocketVMTarget item) {
    if (item.chrome) {
      // We don't store chrome tabs.
      return;
    }
    if (history.contains(item)) {
      return;
    }
    // Not inserting duplicates.
    assert(_find(item.networkAddress) == null);
    history.add(item);
    _sort();
    _store();
  }

  void remove(WebSocketVMTarget target) {
    history.remove(target);
    _sort();
    _store();
  }

  void _sort() {
    this.history.sort((WebSocketVMTarget a, WebSocketVMTarget b) {
      return b.lastConnectionTime.compareTo(a.lastConnectionTime);
    });
  }

  /// After making a change, update settings.
  void _store() {
    _sort();
    _settings.set(_historyKey,  history);
  }

  /// Read settings from data store.
  void _restore() {
    this.history.clear();
    var loaded = _settings.get(_historyKey);
    if (loaded == null) {
      return;
    }
    for (var i = 0; i < loaded.length; i++) {
      loaded[i] = new WebSocketVMTarget.fromMap(loaded[i]);
    }
    this.history.addAll(loaded);
    _sort();
  }
}
