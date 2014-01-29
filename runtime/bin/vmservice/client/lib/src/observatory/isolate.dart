// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;


/// State for a running isolate.
class Isolate extends Observable {
  static ObservatoryApplication _application;
  
  @observable Profile profile;
  @observable final Map<String, Script> scripts =
      toObservable(new Map<String, Script>());
  @observable final List<Code> codes = new List<Code>();
  @observable String id;
  @observable String name;
  @observable Map entry;
  @observable String rootLib;
  @observable final Map<String, double> timers =
      toObservable(new Map<String, double>());

  @observable int newHeapUsed = 0;
  @observable int oldHeapUsed = 0;

  @observable Map topFrame = null;
  @observable String fileAndLine = null;
  
  Isolate.fromId(this.id) : name = '' {}
  
  Isolate.fromMap(Map map)
      : id = map['id'], name = map['name'] {
  }

  void refresh() {
    var request = '/$id/';
    _application.requestManager.requestMap(request).then((map) {
        update(map);
      }).catchError((e, trace) {
          Logger.root.severe('Error while updating isolate summary: $e\n$trace');
      });
  }
  
  void update(Map map) {
    if (map['type'] != 'Isolate') {
      Logger.root.severe('Unexpected message type in Isolate.update: ${map["type"]}');
      return;
    }
    if (map['name'] == null ||
        map['rootLib'] == null ||
        map['timers'] == null ||
        map['heap'] == null) {
      Logger.root.severe("Malformed 'Isolate' response: $map");
      return;
    }
    name = map['name'];
    rootLib = map['rootLib']['id'];
    if (map['entry'] != null) {
      entry = map['entry'];
    }
    if (map['topFrame'] != null) {
      topFrame = map['topFrame'];
    }

    var timerMap = {};
    map['timers'].forEach((timer) {
        timerMap[timer['name']] = timer['time'];
      });
    print(timerMap);
    timers['total'] = timerMap['time_total_runtime'];
    timers['compile'] = timerMap['time_compilation'];
    timers['gc'] = 0.0;  // TODO(turnidge): Export this from VM.
    timers['init'] = (timerMap['time_script_loading'] +
                      timerMap['time_creating_snapshot'] +
                      timerMap['time_isolate_initialization'] +
                      timerMap['time_bootstrap']);
    timers['dart'] = timerMap['time_dart_execution'];

    newHeapUsed = map['heap']['usedNew'];
    oldHeapUsed = map['heap']['usedOld'];
  }

  String toString() => '$id';

  Code findCodeByAddress(int address) {
    for (var i = 0; i < codes.length; i++) {
      if (codes[i].contains(address)) {
        return codes[i];
      }
    }
  }

  Code findCodeByName(String name) {
    for (var i = 0; i < codes.length; i++) {
      if (codes[i].name == name) {
        return codes[i];
      }
    }
  }

  void resetCodeTicks() {
    Logger.root.info('Reset all code ticks.');
    for (var i = 0; i < codes.length; i++) {
      codes[i].resetTicks();
    }
  }

  void updateCoverage(List coverages) {
    for (var coverage in coverages) {
      var id = coverage['script']['id'];
      var script = scripts[id];
      if (script == null) {
        script = new Script.fromMap(coverage['script']);
        scripts[id] = script;
      }
      assert(script != null);
      script._processCoverageHits(coverage['hits']);
    }
  }
}
