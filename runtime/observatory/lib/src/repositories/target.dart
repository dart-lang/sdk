// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of repositories;

class TargetChangeEvent implements M.TargetChangeEvent {
  final TargetRepository repository;
  final bool disconnected;
  TargetChangeEvent(this.repository, [this.disconnected = false]);
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
    // Add the default address if it doesn't already exist.
    if (find(_networkAddressOfDefaultTarget()) == null) {
      add(_networkAddressOfDefaultTarget());
    }
    // Set the current target to the default target.
    current = find(_networkAddressOfDefaultTarget());
  }

  void add(String address) {
    if (find(address) != null) {
      return;
    }
    _list.insert(0, new SC.WebSocketVMTarget(address));
    _onChange.add(new TargetChangeEvent(this));
    _store();
  }

  Iterable<SC.WebSocketVMTarget> list() => _list;

  void setCurrent(M.Target t) {
    SC.WebSocketVMTarget target = t as SC.WebSocketVMTarget;
    if (!_list.contains(target)) {
      return;
    }
    current = target;
    current.lastConnectionTime = new DateTime.now().millisecondsSinceEpoch;
    _onChange.add(new TargetChangeEvent(this));
    _store();
  }

  void emitDisconnectEvent() {
    _onChange.add(new TargetChangeEvent(this, true));
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
    _settings.set(_historyKey, _list);
  }

  /// Find by networkAddress.
  SC.WebSocketVMTarget find(String networkAddress) {
    for (SC.WebSocketVMTarget item in _list) {
      if (item.networkAddress == networkAddress) {
        return item;
      }
    }
    return null;
  }

  static String _networkAddressOfDefaultTarget() {
    Uri serverAddress = Uri.parse(window.location.toString());
    return 'ws://${serverAddress.authority}${serverAddress.path}ws';
  }
}
