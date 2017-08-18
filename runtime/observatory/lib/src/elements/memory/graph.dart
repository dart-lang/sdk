// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This Element is part of MemoryDashboardElement.
///
/// The Element periodically interrogates the VM to log the memory usage of each
/// Isolate and of the Native Memory.
///
/// For each isolate it is shown the Used and Free heap (new and old are merged
/// together)
///
/// When a GC event is received an extra point is introduced in the graph to
/// make the representation as precise as possible.
///
/// When an Isolate is selected the event is bubbled up to the parent.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:charted/charted.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/utils.dart';

class IsolateSelectedEvent {
  final M.Isolate isolate;

  const IsolateSelectedEvent([this.isolate]);
}

class MemoryGraphElement extends HtmlElement implements Renderable {
  static const tag = const Tag<MemoryGraphElement>('memory-graph');

  RenderingScheduler<MemoryGraphElement> _r;

  final StreamController<IsolateSelectedEvent> _onIsolateSelected =
      new StreamController<IsolateSelectedEvent>();

  Stream<RenderedEvent<MemoryGraphElement>> get onRendered => _r.onRendered;
  Stream<IsolateSelectedEvent> get onIsolateSelected =>
      _onIsolateSelected.stream;

  M.VMRef _vm;
  M.VMRepository _vms;
  M.IsolateRepository _isolates;
  M.EventRepository _events;
  StreamSubscription _onGCSubscription;
  StreamSubscription _onResizeSubscription;
  StreamSubscription _onConnectionClosedSubscription;
  Timer _onTimer;

  M.VMRef get vm => _vm;

  factory MemoryGraphElement(M.VMRef vm, M.VMRepository vms,
      M.IsolateRepository isolates, M.EventRepository events,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(vms != null);
    assert(isolates != null);
    assert(events != null);
    MemoryGraphElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._vms = vms;
    e._isolates = isolates;
    e._events = events;
    return e;
  }

  MemoryGraphElement.created() : super.created() {
    final now = new DateTime.now();
    var sample = now.subtract(_window);
    while (sample.isBefore(now)) {
      _ts.add(sample);
      _vmSamples.add(<int>[0, 0]);
      _isolateUsedSamples.add([]);
      _isolateFreeSamples.add([]);
      sample = sample.add(_period);
    }
    _ts.add(now);
    _vmSamples.add(<int>[0, 0]);
    _isolateUsedSamples.add([]);
    _isolateFreeSamples.add([]);
  }

  static const Duration _period = const Duration(seconds: 2);
  static const Duration _window = const Duration(minutes: 2);

  @override
  attached() {
    super.attached();
    _r.enable();
    _onGCSubscription =
        _events.onGCEvent.listen((e) => _refresh(gcIsolate: e.isolate));
    _onConnectionClosedSubscription =
        _events.onConnectionClosed.listen((_) => _onTimer.cancel());
    _onResizeSubscription = window.onResize.listen((_) => _r.dirty());
    _onTimer = new Timer.periodic(_period, (_) => _refresh());
    _refresh();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
    _onGCSubscription.cancel();
    _onConnectionClosedSubscription.cancel();
    _onResizeSubscription.cancel();
    _onTimer.cancel();
  }

  final List<DateTime> _ts = <DateTime>[];
  final List<List<int>> _vmSamples = <List<int>>[];
  final List<M.IsolateRef> _seenIsolates = <M.IsolateRef>[];
  final List<List<int>> _isolateUsedSamples = <List<int>>[];
  final List<List<int>> _isolateFreeSamples = <List<int>>[];
  final Map<String, int> _isolateIndex = <String, int>{};
  final Map<String, String> _isolateName = <String, String>{};

  var _selected;
  var _previewed;
  var _hovered;

  void render() {
    if (_previewed != null || _hovered != null) return;

    // cache data of hoverboards
    final ts = new List<DateTime>.from(_ts);
    final vmSamples = new List<List<int>>.from(_vmSamples);
    final isolateFreeSamples = new List<List<int>>.from(_isolateFreeSamples);
    final isolateUsedSamples = new List<List<int>>.from(_isolateUsedSamples);

    final now = _ts.last;
    final nativeComponents = 1;
    final legend = new DivElement();
    final host = new DivElement();
    final theme = new MemoryChartTheme(1);
    children = [theme.style, legend, host];
    final rect = host.getBoundingClientRect();

    final series =
        new List<int>.generate(_isolateIndex.length * 2 + 1, (i) => i + 1);
    // The stacked line chart sorts from top to bottom
    final columns = [
      new ChartColumnSpec(
          formatter: _formatTimeAxis, type: ChartColumnSpec.TYPE_NUMBER),
      new ChartColumnSpec(label: 'Native', formatter: Utils.formatSize)
    ]..addAll(_isolateName.keys.expand((id) => [
          new ChartColumnSpec(formatter: Utils.formatSize),
          new ChartColumnSpec(label: _label(id), formatter: Utils.formatSize)
        ]));
    // The stacked line chart sorts from top to bottom
    final rows = new List.generate(_ts.length, (sampleIndex) {
      final free = isolateFreeSamples[sampleIndex];
      final used = isolateUsedSamples[sampleIndex];
      final isolates = _isolateIndex.keys.expand((key) {
        final isolateIndex = _isolateIndex[key];
        return <int>[free[isolateIndex], used[isolateIndex]];
      });
      return [
        ts[sampleIndex].difference(now).inMicroseconds,
        vmSamples[sampleIndex][1] ?? 1000000
      ]..addAll(isolates);
    });

    final scale = new LinearScale()..domain = [(-_window).inMicroseconds, 0];
    final axisConfig = new ChartAxisConfig()..scale = scale;
    final sMemory =
        new ChartSeries('Memory', series, new StackedLineChartRenderer());
    final config = new ChartConfig([sMemory], [0])
      ..legend = new ChartLegend(legend)
      ..registerDimensionAxis(0, axisConfig);
    config.minimumSize = new Rect(rect.width, rect.height);
    final data = new ChartData(columns, rows);
    final state = new ChartState(isMultiSelect: true)
      ..changes.listen(_handleEvent);
    final area = new CartesianArea(host, data, config, state: state)
      ..theme = theme;
    area.addChartBehavior(new Hovercard(builder: (int column, int row) {
      if (column == 1) {
        final data = vmSamples[row];
        return _formatNativeOvercard(data[0], data[1]);
      }
      final isolate = _seenIsolates[column - 2];
      final index = _isolateIndex[isolate.id];
      final free = isolateFreeSamples[row][index];
      final used = isolateUsedSamples[row][index];
      return _formatIsolateOvercard(isolate.name, free, used);
    }));
    area.draw();

    if (_selected != null) {
      state.select(_selected);
      if (_selected > 1) {
        state.select(_selected + 1);
      }
    }
  }

  String _formatTimeAxis(num ms) =>
      Utils.formatDuration(new Duration(microseconds: ms.toInt()),
          precision: DurationComponent.Seconds);

  bool _running = false;

  Future _refresh({M.IsolateRef gcIsolate}) async {
    if (_running) return;
    _running = true;
    final now = new DateTime.now();
    final start = now.subtract(_window);
    final vm = await _vms.get(_vm);
    // The Service classes order isolates from the older to the newer
    final isolates =
        (await Future.wait(vm.isolates.map(_isolates.get))).reversed.toList();
    while (_ts.first.isBefore(start)) {
      _ts.removeAt(0);
      _vmSamples.removeAt(0);
      _isolateUsedSamples.removeAt(0);
      _isolateFreeSamples.removeAt(0);
    }

    if (_ts.first.isAfter(start)) {
      _ts.insert(0, start);
      _vmSamples.insert(0, _vmSamples.first);
      _isolateUsedSamples.insert(0, _isolateUsedSamples.first);
      _isolateFreeSamples.insert(0, _isolateFreeSamples.first);
    }

    if (_isolateIndex.length == 0) {
      _selected = isolates.length * 2;
      _onIsolateSelected.add(new IsolateSelectedEvent(isolates.last));
    }

    isolates
        .where((isolate) => !_isolateIndex.containsKey(isolate.id))
        .forEach((isolate) {
      _isolateIndex[isolate.id] = _isolateIndex.length;
      _seenIsolates.addAll([isolate, isolate]);
    });

    if (_isolateIndex.length != _isolateName.length) {
      final extra =
          new List.filled(_isolateIndex.length - _isolateName.length, 0);
      _isolateUsedSamples.forEach((sample) => sample.addAll(extra));
      _isolateFreeSamples.forEach((sample) => sample.addAll(extra));
    }

    final length = _isolateIndex.length;

    if (gcIsolate != null) {
      // After GC we add an extra point to show the drop in a clear way
      final List<int> isolateUsedSample = new List<int>.filled(length, 0);
      final List<int> isolateFreeSample = new List<int>.filled(length, 0);
      isolates.forEach((M.Isolate isolate) {
        _isolateName[isolate.id] = isolate.name;
        final index = _isolateIndex[isolate.id];
        if (isolate.id == gcIsolate) {
          isolateUsedSample[index] =
              _isolateUsedSamples.last[index] + _isolateFreeSamples.last[index];
          isolateFreeSample[index] = 0;
        } else {
          isolateUsedSample[index] = _used(isolate);
          isolateFreeSample[index] = _free(isolate);
        }
      });
      _isolateUsedSamples.add(isolateUsedSample);
      _isolateFreeSamples.add(isolateFreeSample);

      _vmSamples.add(<int>[vm.currentRSS, vm.heapAllocatedMemoryUsage]);

      _ts.add(now);
    }
    final List<int> isolateUsedSample = new List<int>.filled(length, 0);
    final List<int> isolateFreeSample = new List<int>.filled(length, 0);
    isolates.forEach((M.Isolate isolate) {
      _isolateName[isolate.id] = isolate.name;
      final index = _isolateIndex[isolate.id];
      isolateUsedSample[index] = _used(isolate);
      isolateFreeSample[index] = _free(isolate);
    });
    _isolateUsedSamples.add(isolateUsedSample);
    _isolateFreeSamples.add(isolateFreeSample);

    _vmSamples.add(<int>[vm.currentRSS, vm.heapAllocatedMemoryUsage]);

    _ts.add(now);
    _r.dirty();
    _running = false;
  }

  void _handleEvent(records) => records.forEach((record) {
        if (record is ChartSelectionChangeRecord) {
          var selected = record.add;
          if (selected == null) {
            if (selected != _selected) {
              _onIsolateSelected.add(const IsolateSelectedEvent());
              _r.dirty();
            }
          } else {
            if (selected == 1) {
              if (selected != _selected) {
                _onIsolateSelected.add(const IsolateSelectedEvent());
                _r.dirty();
              }
            } else {
              selected -= selected % 2;
              if (selected != _selected) {
                _onIsolateSelected
                    .add(new IsolateSelectedEvent(_seenIsolates[selected - 2]));
                _r.dirty();
              }
            }
          }
          _selected = selected;
          _previewed = null;
          _hovered = null;
        } else if (record is ChartPreviewChangeRecord) {
          _previewed = record.previewed;
        } else if (record is ChartHoverChangeRecord) {
          _hovered = record.hovered;
        }
      });

  int _used(M.Isolate i) => i.newSpace.used + i.oldSpace.used;
  int _capacity(M.Isolate i) => i.newSpace.capacity + i.oldSpace.capacity;
  int _free(M.Isolate i) => _capacity(i) - _used(i);

  String _label(String isolateId) {
    final index = _isolateIndex[isolateId];
    final name = _isolateName[isolateId];
    final free = _isolateFreeSamples.last[index];
    final used = _isolateUsedSamples.last[index];
    final usedStr = Utils.formatSize(used);
    final capacity = free + used;
    final capacityStr = Utils.formatSize(capacity);
    return '${name} ($usedStr / $capacityStr)';
  }

  static HtmlElement _formatNativeOvercard(int currentRSS, int heap) =>
      new DivElement()
        ..children = [
          new DivElement()
            ..classes = ['hovercard-title']
            ..text = 'Native',
          new DivElement()
            ..classes = ['hovercard-measure', 'hovercard-multi']
            ..children = [
              new DivElement()
                ..classes = ['hovercard-measure-label']
                ..text = 'Total Memory Usage',
              new DivElement()
                ..classes = ['hovercard-measure-value']
                ..text = currentRSS != null
                    ? Utils.formatSize(currentRSS)
                    : "unavailable",
            ],
          new DivElement()
            ..classes = ['hovercard-measure', 'hovercard-multi']
            ..children = [
              new DivElement()
                ..classes = ['hovercard-measure-label']
                ..text = 'Native Heap',
              new DivElement()
                ..classes = ['hovercard-measure-value']
                ..text = heap != null ? Utils.formatSize(heap) : "unavailable",
            ]
        ];

  static HtmlElement _formatIsolateOvercard(String name, int free, int used) {
    final capacity = free + used;
    return new DivElement()
      ..children = [
        new DivElement()
          ..classes = ['hovercard-title']
          ..text = name,
        new DivElement()
          ..classes = ['hovercard-measure', 'hovercard-multi']
          ..children = [
            new DivElement()
              ..classes = ['hovercard-measure-label']
              ..text = 'Heap Capacity',
            new DivElement()
              ..classes = ['hovercard-measure-value']
              ..text = Utils.formatSize(capacity),
          ],
        new DivElement()
          ..classes = ['hovercard-measure', 'hovercard-multi']
          ..children = [
            new DivElement()
              ..classes = ['hovercard-measure-label']
              ..text = 'Free Heap',
            new DivElement()
              ..classes = ['hovercard-measure-value']
              ..text = Utils.formatSize(free),
          ],
        new DivElement()
          ..classes = ['hovercard-measure', 'hovercard-multi']
          ..children = [
            new DivElement()
              ..classes = ['hovercard-measure-label']
              ..text = 'Used Heap',
            new DivElement()
              ..classes = ['hovercard-measure-value']
              ..text = Utils.formatSize(used),
          ]
      ];
  }
}

class MemoryChartTheme extends QuantumChartTheme {
  final int _offset;

  MemoryChartTheme(int offset) : _offset = offset {
    assert(offset != null);
    assert(offset >= 0);
  }

  @override
  String getColorForKey(key, [int state = 0]) {
    key -= 1;
    if (key > _offset) {
      key = _offset + (key - _offset) ~/ 2;
    }
    key += 1;
    return super.getColorForKey(key, state);
  }

  @override
  String getFilterForState(int state) => state & ChartState.COL_PREVIEW != 0 ||
          state & ChartState.VAL_HOVERED != 0 ||
          state & ChartState.COL_SELECTED != 0 ||
          state & ChartState.VAL_HIGHLIGHTED != 0
      ? 'url(#drop-shadow)'
      : '';

  @override
  String get filters =>
      '<defs>' +
      super.filters +
      '''
<filter id="stroke-grid" primitiveUnits="userSpaceOnUse">
    <feFlood in="SourceGraphic" x="0" y="0" width="4" height="4"
      flood-color="black" flood-opacity="0.2" result='Black'/>
    <feFlood in="SourceGraphic" x="1" y="1" width="3" height="3"
      flood-color="black" flood-opacity="0.8" result='White'/>
    <feComposite in="Black" in2="White" operator="xor" x="0" y="0" width="4" height="4"/>
    <feTile x="0" y="0" width="100%" height="100%" />
    <feComposite in2="SourceAlpha" result="Pattern" operator="in" x="0" y="0" width="100%" height="100%"/>
    <feComposite in="SourceGraphic" in2="Pattern" operator="atop" x="0" y="0" width="100%" height="100%"/>
</filter>
  </defs>
''';

  StyleElement get style => new StyleElement()
    ..text = '''
memory-graph svg .stacked-line-rdr-line:nth-child(2n+${_offset+1})
  path:nth-child(1) {
  filter: url(#stroke-grid);
}''';
}
