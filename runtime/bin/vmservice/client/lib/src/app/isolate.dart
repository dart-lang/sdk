// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// State for a running isolate.
class Isolate extends Observable implements ServiceObject {
  final VM vm;
  String _id;
  String _serviceType = 'Isolate';
  Isolate get isolate => this;
  String get link => _id;
  String get id => _id;
  String get serviceType => _serviceType;

  Isolate(this.vm, this._id);

  /// Refresh [this]. Returns a future which completes to [this].
  Future refresh() {
    return vm.fetchMap(_id).then((m) => update(m)).then((_) => this);
  }

  /// Creates a link to [objectId] relative to [this].
  @reflectable String relativeLink(String objectId) => '$id/$objectId';
  /// Creates a relative link to [objectId] with a '#/' prefix.
  @reflectable String hashLink(String objectId) => '#/${relativeLink(objectId)}';

  @observable Profile profile;
  @observable final Map<String, Script> scripts =
      toObservable(new Map<String, Script>());
  @observable final List<Code> codes = new List<Code>();
  @observable String name;
  @observable String vmName;
  @observable Map entry;
  @observable String rootLib;
  @observable final Map<String, double> timers =
      toObservable(new Map<String, double>());

  @observable int newHeapUsed = 0;
  @observable int oldHeapUsed = 0;

  @observable Map topFrame = null;
  @observable String fileAndLine = null;

  Isolate.fromId(this.vm, this._id) : name = 'isolate' {}

  Isolate.fromMap(this.vm, Map map)
      : _id = map['id'], name = map['name'] {
  }

  void update(Map map) {
    if (map['type'] != 'Isolate') {
      Logger.root.severe('Unexpected message type in Isolate.update: ${map["type"]}');
      return;
    }
    if (map['rootLib'] == null ||
        map['timers'] == null ||
        map['heap'] == null) {
      Logger.root.severe("Malformed 'Isolate' response: $map");
      return;
    }
    rootLib = map['rootLib']['id'];
    vmName = map['name'];
    if (map['entry'] != null) {
      entry = map['entry'];
      name = entry['name'];
    } else {
      // fred
      name = 'root isolate';
    }
    if (map['topFrame'] != null) {
      topFrame = map['topFrame'];
    }

    var timerMap = {};
    map['timers'].forEach((timer) {
        timerMap[timer['name']] = timer['time'];
      });
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
    return null;
  }

  Code findCodeByName(String name) {
    for (var i = 0; i < codes.length; i++) {
      if (codes[i].name == name) {
        return codes[i];
      }
    }
    return null;
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

  // TODO(johnmccutchan): Remove this once everything is a ServiceObject.
  void _setModelResponse(String type, String modelName, dynamic model) {
    var response = {
      'type': type,
      modelName: model
    };
    vm.app.setResponse(response);
  }

  void _setResponseRequestError(HttpRequest request) {
     String error = '${request.status} ${request.statusText}';
     if (request.status == 0) {
       error = 'No service found. Did you run with --enable-vm-service ?';
     }
     vm.app.setResponseError(error, 'RequestError');
   }

  void _requestCatchError(e, st) {
     if (e is ProgressEvent) {
       _setResponseRequestError(e.target);
     } else {
       vm.app.setResponseError('$e $st');
     }
   }

  static final RegExp _codeMatcher = new RegExp(r'/code/');
  static bool isCodeId(objectId) => _codeMatcher.hasMatch(objectId);
  static int codeAddressFromRequest(String objectId) {
    Match m = _codeMatcher.matchAsPrefix(objectId);
    if (m == null) {
      return 0;
    }
    try {
      var a = int.parse(m.input.substring(m.end), radix: 16);
      return a;
    } catch (e) {
      return 0;
    }
  }

  /// Handle 'Code' requests
  void _getCode(String objectId) {
    var address = codeAddressFromRequest(objectId);
    if (address == 0) {
      vm.app.setResponseError('$objectId is not a valid code request.');
      return;
    }
    var code = isolate.findCodeByAddress(address);
    if (code != null) {
      Logger.root.info(
          'Found code with 0x${address.toRadixString(16)} in isolate.');
      _setModelResponse('Code', 'code', code);
      return;
    }
    getMap(objectId).then((map) {
      assert(map['type'] == 'Code');
      var code = new Code.fromMap(map);
      Logger.root.info(
          'Added code with 0x${address.toRadixString(16)} to isolate.');
      isolate.codes.add(code);
      _setModelResponse('Code', 'code', code);
    }).catchError(_requestCatchError);
  }

  static final RegExp _scriptMatcher = new RegExp(r'scripts/.+');
  static bool isScriptId(objectId) => _scriptMatcher.hasMatch(objectId);
  void _getScript(String objectId) {
    var script = scripts[objectId];
    if ((script != null) && !script.needsSource) {
      Logger.root.info('Found script ${script.scriptRef['name']} in isolate');
      _setModelResponse('Script', 'script', script);
      return;
    }
    if (script != null) {
      // The isolate has the script but no script source code.
      getMap(objectId).then((response) {
        assert(response['type'] == 'Script');
        script._processSource(response['source']);
        Logger.root.info(
            'Grabbed script ${script.scriptRef['name']} source.');
        _setModelResponse('Script', 'script', script);
      });
      return;
    }
    // New script.
    getMap(objectId).then((response) {
      assert(response['type'] == 'Script');
      var script = new Script.fromMap(response);
      Logger.root.info(
          'Added script ${script.scriptRef['name']} to isolate.');
      _setModelResponse('Script', 'script', script);
      scripts[objectId] = script;
    });
  }

  /// Requests [objectId] from [this]. Completes to a [ServiceObject].
  Future<ServiceObject> get(String objectId) {
    if (isCodeId(objectId)) {
      _getCode(objectId);
      // TODO(johnmccutchan): FIX.
      return null;
    }
    if (isScriptId(objectId)) {
      _getScript(objectId);
      // TODO(johnmccutchan): FIX.
      return null;
    }
    return vm.fetchMap(relativeLink(objectId)).then((m) =>
        upgradeToServiceObject(objectId, m));
  }

  /// Requests [objectId] from [this]. Completes to a [Map].
  Future<ObservableMap> getMap(String objectId) {
    return vm.fetchMap(relativeLink(objectId));
  }

  /// Upgrades response ([m]) for [objectId] to a [ServiceObject].
  ServiceObject upgradeToServiceObject(String objectId, Map m) {
    return new ServiceMap.fromMap(this, m);
  }
}
