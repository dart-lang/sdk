// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.list_path_observer;

import 'dart:async';
import 'package:observe/observe.dart';

// Inspired by ArrayReduction at:
// https://raw.github.com/rafaelw/ChangeSummary/master/util/array_reduction.js
// The main difference is we support anything on the rich Dart Iterable API.

/// Observes a path starting from each item in the list.
@deprecated
class ListPathObserver<E, P> extends ChangeNotifier {
  final ObservableList<E> list;
  final String _itemPath;
  final List<PathObserver> _observers = <PathObserver>[];
  StreamSubscription _sub;
  bool _scheduled = false;
  Iterable<P> _value;

  ListPathObserver(this.list, String path)
      : _itemPath = path {

    // TODO(jmesserly): delay observation until we are observed.
    _sub = list.listChanges.listen((records) {
      for (var record in records) {
        _observeItems(record.addedCount - record.removed.length);
      }
      _scheduleReduce(null);
    });

    _observeItems(list.length);
    _reduce();
  }

  @reflectable Iterable<P> get value => _value;

  void dispose() {
    if (_sub != null) _sub.cancel();
    _observers.forEach((o) => o.close());
    _observers.clear();
  }

  void _reduce() {
    _scheduled = false;
    var newValue = _observers.map((o) => o.value);
    _value = notifyPropertyChange(#value, _value, newValue);
  }

  void _scheduleReduce(_) {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_reduce);
  }

  void _observeItems(int lengthAdjust) {
    if (lengthAdjust > 0) {
      for (int i = 0; i < lengthAdjust; i++) {
        int len = _observers.length;
        var pathObs = new PathObserver(list, '[$len].$_itemPath');
        pathObs.open(_scheduleReduce);
        _observers.add(pathObs);
      }
    } else if (lengthAdjust < 0) {
      for (int i = 0; i < -lengthAdjust; i++) {
        _observers.removeLast().close();
      }
    }
  }
}
