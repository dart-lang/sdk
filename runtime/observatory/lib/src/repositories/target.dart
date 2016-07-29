// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class TargetChangeEvent implements M.TargetChangeEvent {
  final TargetRepository repository;
  TargetChangeEvent(this.repository);
}

class TargetRepository implements M.TargetRepository {

  static const _historyKey = 'history';

  final StreamController<TargetChangeEvent> _onChange;
  final Stream<TargetChangeEvent> onChange;
  final SettingsRepository _settings = new SettingsRepository('targetManager');

  final List<SC.WebSocketVMTarget> _list = <SC.WebSocketVMTarget>[];
  SC.WebSocketVMTarget current;

  factory TargetRepository() {
    var controller = new StreamController<TargetChangeEvent>();
    var stream = controller.stream.asBroadcastStream();
    return new TargetRepository._(controller, stream);
  }

  TargetRepository._(this._onChange, this.onChange) {
    _restore();
    if (_list.isEmpty) {
      _list.add(new SC.WebSocketVMTarget(_networkAddressOfDefaultTarget()));
    }
    current = _list.first;
  }

  void add(String address) {
    if (_find(address) != null) return;
    _list.insert(0, new SC.WebSocketVMTarget(address));
    _onChange.add(new TargetChangeEvent(this));
    _store();
  }

  Iterable<SC.WebSocketVMTarget> list() => _list;

  void setCurrent(M.Target t) {
    SC.WebSocketVMTarget target = t as SC.WebSocketVMTarget;
    if (!_list.contains(target)) return;
    current = target;
    _onChange.add(new TargetChangeEvent(this));
  }

  void delete(o) {
    if (_list.remove(o)) {
      if (o == current) {
        current = null;
      }
      _onChange.add(new TargetChangeEvent(this));
      _store();
    }
  }

  /// Read settings from data store.
  void _restore() {
    _list.clear();
    var loaded = _settings.get(_historyKey);
    if (loaded == null) {
      return;
    }
    _list.addAll(loaded.map((i) => new SC.WebSocketVMTarget.fromMap(i)));
    _list.sort((SC.WebSocketVMTarget a, SC.WebSocketVMTarget b) {
       return b.lastConnectionTime.compareTo(a.lastConnectionTime);
    });
  }

  /// After making a change, update settings.
  void _store() {
    _settings.set(_historyKey,  _list);
  }

  /// Find by networkAddress.
  SC.WebSocketVMTarget _find(String networkAddress) {
    for (SC.WebSocketVMTarget item in _list) {
      if (item.networkAddress == networkAddress) {
        return item;
      }
    }
    return null;
  }

  static String _networkAddressOfDefaultTarget() {
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
}
