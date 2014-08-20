// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of service;

/// A [ServiceObject] is an object known to the VM service and is tied
/// to an owning [Isolate].
abstract class ServiceObject extends Observable {
  static int LexicalSortName(ServiceObject o1, ServiceObject o2) {
    return o1.name.compareTo(o2.name);
  }

  List removeDuplicatesAndSortLexical(List<ServiceObject> list) {
    return list.toSet().toList()..sort(LexicalSortName);
  }

  /// The owner of this [ServiceObject].  This can be an [Isolate], a
  /// [VM], or null.
  @reflectable ServiceObjectOwner get owner => _owner;
  ServiceObjectOwner _owner;

  /// The [VM] which owns this [ServiceObject].
  @reflectable VM get vm => _owner.vm;

  /// The [Isolate] which owns this [ServiceObject].  May be null.
  @reflectable Isolate get isolate => _owner.isolate;

  /// The id of this object.
  @reflectable String get id => _id;
  String _id;

  /// The service type of this object.
  @reflectable String get serviceType => _serviceType;
  String _serviceType;

  /// The complete service url of this object.
  @reflectable String get link => _owner.relativeLink(_id);

  /// Has this object been fully loaded?
  bool get loaded => _loaded;
  bool _loaded = false;
  // TODO(turnidge): Make loaded observable and get rid of loading
  // from Isolate.

  /// Is this object cacheable?  That is, is it impossible for the [id]
  /// of this object to change?
  bool get canCache => false;

  /// Is this object immutable after it is [loaded]?
  bool get immutable => false;

  @observable String name;
  @observable String vmName;

  /// Creates an empty [ServiceObject].
  ServiceObject._empty(this._owner);

  /// Creates a [ServiceObject] initialized from [map].
  factory ServiceObject._fromMap(ServiceObjectOwner owner,
                                 ObservableMap map) {
    if (map == null) {
      return null;
    }
    if (!_isServiceMap(map)) {
      Logger.root.severe('Malformed service object: $map');
    }
    assert(_isServiceMap(map));
    var type = _stripRef(map['type']);
    var obj = null;
    assert(type != 'VM');
    switch (type) {
      case 'Class':
        obj = new Class._empty(owner);
        break;
      case 'Code':
        obj = new Code._empty(owner);
        break;
      case 'Error':
        obj = new DartError._empty(owner);
        break;
      case 'Function':
        obj = new ServiceFunction._empty(owner);
        break;
      case 'Isolate':
        obj = new Isolate._empty(owner.vm);
        break;
      case 'Library':
        obj = new Library._empty(owner);
        break;
      case 'ServiceError':
        obj = new ServiceError._empty(owner);
        break;
      case 'ServiceEvent':
        obj = new ServiceEvent._empty(owner);
        break;
      case 'ServiceException':
        obj = new ServiceException._empty(owner);
        break;
      case 'Script':
        obj = new Script._empty(owner);
        break;
      case 'Socket':
        obj = new Socket._empty(owner);
        break;
      default:
        obj = new ServiceMap._empty(owner);
    }
    obj.update(map);
    return obj;
  }

  /// If [this] was created from a reference, load the full object
  /// from the service by calling [reload]. Else, return [this].
  Future<ServiceObject> load() {
    if (loaded) {
      return new Future.value(this);
    }
    // Call reload which will fill in the entire object.
    return reload();
  }

  Future<ServiceObject> _inProgressReload;

  /// Reload [this]. Returns a future which completes to [this] or
  /// a [ServiceError].
  Future<ServiceObject> reload() {
    if (id == '') {
      // Errors don't have ids.
      assert(serviceType == 'Error');
      return new Future.value(this);
    }
    if (loaded && immutable) {
      return new Future.value(this);
    }
    if (_inProgressReload == null) {
      _inProgressReload = vm.getAsMap(link).then((ObservableMap map) {
          var mapType = _stripRef(map['type']);
          if (mapType != _serviceType) {
            // If the type changes, return a new object instead of
            // updating the existing one.
            assert(mapType == 'Error' || mapType == 'Null');
            return new ServiceObject._fromMap(owner, map);
          }
          update(map);
          return this;
      }).whenComplete(() {
          // This reload is complete.
          _inProgressReload = null;
      });
    }
    return _inProgressReload;
  }

  /// Update [this] using [map] as a source. [map] can be a reference.
  void update(ObservableMap map) {
    assert(_isServiceMap(map));

    // Don't allow the type to change on an object update.
    // TODO(turnidge): Make this a ServiceError?
    var mapIsRef = _hasRef(map['type']);
    var mapType = _stripRef(map['type']);
    assert(_serviceType == null || _serviceType == mapType);

    if (_id != null && _id != map['id']) {
      // It is only safe to change an id when the object isn't cacheable.
      assert(!canCache);
    }
    _id = map['id'];

    _serviceType = mapType;
    _update(map, mapIsRef);
  }

  // Updates internal state from [map]. [map] can be a reference.
  void _update(ObservableMap map, bool mapIsRef);

  String relativeLink(String id) {
    assert(id != null);
    return "${link}/${id}";
  }
}

abstract class Coverage {
  // Following getters and functions will be provided by [ServiceObject].
  ServiceObjectOwner get owner;
  String get serviceType;
  VM get vm;
  String relativeLink(String id);

  /// Default handler for coverage data.
  void processCoverageData(List coverageData) {
    coverageData.forEach((scriptCoverage) {
      assert(scriptCoverage['script'] != null);
      scriptCoverage['script']._processHits(scriptCoverage['hits']);
    });
  }

  Future refreshCoverage() {
    return vm.getAsMap(relativeLink('coverage')).then((ObservableMap map) {
      var coverageOwner = (serviceType == 'Isolate') ? this : owner;
      var coverage = new ServiceObject._fromMap(coverageOwner, map);
      assert(coverage.serviceType == 'CodeCoverage');
      var coverageList = coverage['coverage'];
      assert(coverageList != null);
      processCoverageData(coverageList);
    });
  }
}

abstract class ServiceObjectOwner extends ServiceObject {
  /// Creates an empty [ServiceObjectOwner].
  ServiceObjectOwner._empty(ServiceObjectOwner owner) : super._empty(owner);

  /// Builds a [ServiceObject] corresponding to the [id] from [map].
  /// The result may come from the cache.  The result will not necessarily
  /// be [loaded].
  ServiceObject getFromMap(ObservableMap map);

  /// Creates a link to [id] relative to [this].
  String relativeLink(String id);
}

/// State for a VM being inspected.
abstract class VM extends ServiceObjectOwner {
  @reflectable VM get vm => this;
  @reflectable Isolate get isolate => null;

  @reflectable Iterable<Isolate> get isolates => _isolateCache.values;

  @reflectable String get link => '$id';
  @reflectable String relativeLink(String id) => '$id';

  @observable String version = 'unknown';
  @observable String architecture = 'unknown';
  @observable double uptime = 0.0;
  @observable bool assertsEnabled = false;
  @observable bool typeChecksEnabled = false;
  @observable String pid = '';
  @observable DateTime lastUpdate;

  VM() : super._empty(null) {
    name = 'vm';
    vmName = 'vm';
    _cache['vm'] = this;
    update(toObservable({'id':'vm', 'type':'@VM'}));
  }

  final StreamController<ServiceException> exceptions =
      new StreamController.broadcast();
  final StreamController<ServiceError> errors =
      new StreamController.broadcast();
  final StreamController<ServiceEvent> events =
      new StreamController.broadcast();

  void postEventMessage(String eventMessage, [dynamic data]) {
      var map;
      try {
        map = _parseJSON(eventMessage);
        assert(!map.containsKey('_data'));
        if (data != null) {
          map['_data'] = data;
        }
      } catch (e, st) {
        Logger.root.severe('Ignoring malformed event message: ${eventMessage}');
        return;
      }
      if (map['type'] != 'ServiceEvent') {
        Logger.root.severe(
            "Expected 'ServiceEvent' but found '${map['type']}'");
        return;
      }

      // Extract the owning isolate from the event itself.
      String owningIsolateId = map['isolate']['id'];
      _getIsolate(owningIsolateId).then((owningIsolate) {
          if (owningIsolate == null) {
            // TODO(koda): Do we care about GC events in VM isolate?
            Logger.root.severe(
                'Ignoring event with unknown isolate id: $owningIsolateId');
          } else {
            var event = new ServiceObject._fromMap(owningIsolate, map);
            events.add(event);
          }
      });
  }

  static final RegExp _currentIsolateMatcher = new RegExp(r'isolates/\d+');
  static final RegExp _currentObjectMatcher = new RegExp(r'isolates/\d+/');
  static final String _isolatesPrefix = 'isolates/';

  String _parseObjectId(String id) {
    Match m = _currentObjectMatcher.matchAsPrefix(id);
    if (m == null) {
      return null;
    }
    return m.input.substring(m.end);
  }

  String _parseIsolateId(String id) {
    Match m = _currentIsolateMatcher.matchAsPrefix(id);
    if (m == null) {
      return '';
    }
    return id.substring(0, m.end);
  }

  Map<String,ServiceObject> _cache = new Map<String,ServiceObject>();
  Map<String,Isolate> _isolateCache = new Map<String,Isolate>();

  ServiceObject getFromMap(ObservableMap map) {
    throw new UnimplementedError();
  }

  Future<ServiceObject> _getIsolate(String isolateId) {
    if (isolateId == '') {
      return new Future.value(null);
    }
    Isolate isolate = _isolateCache[isolateId];
    if (isolate != null) {
      return new Future.value(isolate);
    }
    // The isolate is not in the cache.  Reload the vm and see if the
    // requested isolate is found.
    return reload().then((result) {
        if (result is! VM) {
          return null;
        }
        assert(result == this);
        return _isolateCache[isolateId];
      });
  }

  Future<ServiceObject> get(String id) {
    assert(id.startsWith('/') == false);
    // Isolates are handled specially, since they can cache sub-objects.
    if (id.startsWith(_isolatesPrefix)) {
      String isolateId = _parseIsolateId(id);
      String objectId = _parseObjectId(id);
      return _getIsolate(isolateId).then((isolate) {
        if (isolate == null) {
          // The isolate does not exist.  Return the VM object instead.
          //
          // TODO(turnidge): Generate a service error?
          return this;
        }
        if (objectId == null) {
          return isolate.reload();
        } else {
          return isolate.get(objectId);
        }
      });
    }

    var obj = _cache[id];
    if (obj != null) {
      return obj.reload();
    }

    // Cache miss.  Get the object from the vm directly.
    return getAsMap(id).then((ObservableMap map) {
      var obj = new ServiceObject._fromMap(this, map);
      if (obj.canCache) {
        _cache.putIfAbsent(id, () => obj);
      }
      return obj;
    });
  }

  dynamic _reviver(dynamic key, dynamic value) {
    return value;
  }

  ObservableMap _parseJSON(String response) {
    var map;
    try {
      var decoder = new JsonDecoder(_reviver);
      map = decoder.convert(response);
    } catch (e, st) {
      return null;
    }
    return toObservable(map);
  }

  Future<ObservableMap> _processMap(ObservableMap map) {
    // Verify that the top level response is a service map.
    if (!_isServiceMap(map)) {
      return new Future.error(
            new ServiceObject._fromMap(this, toObservable({
        'type': 'ServiceException',
        'id': '',
        'kind': 'FormatException',
        'response': map,
        'message': 'Top level service responses must be service maps.',
      })));
    }
    // Preemptively capture ServiceError and ServiceExceptions.
    if (map['type'] == 'ServiceError') {
      return new Future.error(new ServiceObject._fromMap(this, map));
    } else if (map['type'] == 'ServiceException') {
      return new Future.error(new ServiceObject._fromMap(this, map));
    }
    // map is now guaranteed to be a non-error/exception ServiceObject.
    return new Future.value(map);
  }

  Future<ObservableMap> _decodeError(e) {
    return new Future.error(new ServiceObject._fromMap(this, toObservable({
      'type': 'ServiceException',
      'id': '',
      'kind': 'DecodeException',
      'response':
          'This is likely a result of a known V8 bug. Although the '
          'the bug has been fixed the fix may not be in your Chrome'
          ' version. For more information see dartbug.com/18385. '
          'Observatory is still functioning and you should try your'
          ' action again.',
      'message': 'Could not decode JSON: $e',
    })));
  }

  /// Gets [id] as an [ObservableMap] from the service directly. If
  /// an error occurs, the future is completed as an error with a
  /// ServiceError or ServiceException. Therefore any chained then() calls
  /// will only receive a map encoding a valid ServiceObject.
  Future<ObservableMap> getAsMap(String id) {
    return getString(id).then((response) {
      var map = _parseJSON(response);
      if (Tracer.current != null) {
        Tracer.current.trace("Received response for ${id}", map:map);
      }
      return _processMap(map);
    }).catchError((error) {
      // ServiceError, forward to VM's ServiceError stream.
      errors.add(error);
      return new Future.error(error);
    }, test: (e) => e is ServiceError).catchError((exception) {
      // ServiceException, forward to VM's ServiceException stream.
      exceptions.add(exception);
      return new Future.error(exception);
    }, test: (e) => e is ServiceException);
  }

  /// Get [id] as a [String] from the service directly. See [getAsMap].
  Future<String> getString(String id);
  /// Force the VM to disconnect.
  void disconnect();
  /// Completes when the VM first connects.
  Future get onConnect;
  /// Completes when the VM disconnects or there was an error connecting.
  Future get onDisconnect;

  void _update(ObservableMap map, bool mapIsRef) {
    if (mapIsRef) {
      return;
    }
    _loaded = true;
    version = map['version'];
    architecture = map['architecture'];
    uptime = map['uptime'];
    var dateInMillis = int.parse(map['date']);
    lastUpdate = new DateTime.fromMillisecondsSinceEpoch(dateInMillis);
    assertsEnabled = map['assertsEnabled'];
    pid = map['pid'];
    typeChecksEnabled = map['typeChecksEnabled'];
    _updateIsolates(map['isolates']);
  }

  void _updateIsolates(List newIsolates) {
    var oldIsolateCache = _isolateCache;
    var newIsolateCache = new Map<String,Isolate>();
    for (var isolateMap in newIsolates) {
      var isolateId = isolateMap['id'];
      var isolate = oldIsolateCache[isolateId];
      if (isolate != null) {
        newIsolateCache[isolateId] = isolate;
      } else {
        isolate = new ServiceObject._fromMap(this, isolateMap);
        newIsolateCache[isolateId] = isolate;
        Logger.root.info('New isolate \'${isolate.id}\'');
      }
    }
    // Update the individual isolates asynchronously.
    newIsolateCache.forEach((isolateId, isolate) {
      isolate.reload();
    });

    _isolateCache = newIsolateCache;
  }
}

/// Snapshot in time of tag counters.
class TagProfileSnapshot {
  final double seconds;
  final List<int> counters;
  int get sum => _sum;
  int _sum = 0;
  TagProfileSnapshot(this.seconds, int countersLength)
      : counters = new List<int>(countersLength);

  /// Set [counters] and update [sum].
  void set(List<int> counters) {
    this.counters.setAll(0, counters);
    for (var i = 0; i < this.counters.length; i++) {
      _sum += this.counters[i];
    }
  }

  /// Set [counters] with the delta from [counters] to [old_counters]
  /// and update [sum].
  void delta(List<int> counters, List<int> old_counters) {
    for (var i = 0; i < this.counters.length; i++) {
      this.counters[i] = counters[i] - old_counters[i];
      _sum += this.counters[i];
    }
  }

  /// Update [counters] with new maximum values seen in [counters].
  void max(List<int> counters) {
    for (var i = 0; i < counters.length; i++) {
      var c = counters[i];
      this.counters[i] = this.counters[i] > c ? this.counters[i] : c;
    }
  }

  /// Zero [counters].
  void zero() {
    for (var i = 0; i < counters.length; i++) {
      counters[i] = 0;
    }
  }
}

class TagProfile {
  final List<String> names = new List<String>();
  final List<TagProfileSnapshot> snapshots = new List<TagProfileSnapshot>();
  double get updatedAtSeconds => _seconds;
  double _seconds;
  TagProfileSnapshot _maxSnapshot;
  int _historySize;
  int _countersLength = 0;

  TagProfile(this._historySize);

  void _processTagProfile(double seconds, ObservableMap tagProfile) {
    _seconds = seconds;
    var counters = tagProfile['counters'];
    if (names.length == 0) {
      // Initialization.
      names.addAll(tagProfile['names']);
      _countersLength = tagProfile['counters'].length;
      for (var i = 0; i < _historySize; i++) {
        var snapshot = new TagProfileSnapshot(0.0, _countersLength);
        snapshot.zero();
        snapshots.add(snapshot);
      }
      // The counters monotonically grow, keep track of the maximum value.
      _maxSnapshot = new TagProfileSnapshot(0.0, _countersLength);
      _maxSnapshot.set(counters);
      return;
    }
    var snapshot = new TagProfileSnapshot(seconds, _countersLength);
    // We snapshot the delta from the current counters to the maximum counter
    // values.
    snapshot.delta(counters, _maxSnapshot.counters);
    _maxSnapshot.max(counters);
    snapshots.add(snapshot);
    // Only keep _historySize snapshots.
    if (snapshots.length > _historySize) {
      snapshots.removeAt(0);
    }
  }
}

class HeapSpace extends Observable {
  @observable int used = 0;
  @observable int capacity = 0;
  @observable int external = 0;
  @observable int collections = 0;
  @observable double totalCollectionTimeInSeconds = 0.0;
  @observable double averageCollectionPeriodInMillis = 0.0;

  void update(Map heapMap) {
    used = heapMap['used'];
    capacity = heapMap['capacity'];
    external = heapMap['external'];
    collections = heapMap['collections'];
    totalCollectionTimeInSeconds = heapMap['time'];
    averageCollectionPeriodInMillis = heapMap['avgCollectionPeriodMillis'];
  }
}

/// State for a running isolate.
class Isolate extends ServiceObjectOwner with Coverage {
  @reflectable VM get vm => owner;
  @reflectable Isolate get isolate => this;
  @observable ObservableMap counters = new ObservableMap();

  String get link => '/${_id}';

  @observable ServiceEvent pauseEvent = null;
  bool get _isPaused => pauseEvent != null;

  @observable bool running = false;
  @observable bool idle = false;
  @observable bool loading = true;
  @observable bool ioEnabled = false;

  Map<String,ServiceObject> _cache = new Map<String,ServiceObject>();
  final TagProfile tagProfile = new TagProfile(20);

  Isolate._empty(ServiceObjectOwner owner) : super._empty(owner) {
    assert(owner is VM);
  }

  /// Creates a link to [id] relative to [this].
  @reflectable String relativeLink(String id) => '/${this.id}/$id';

  static const TAG_ROOT_ID = 'code/tag-0';

  /// Returns the Code object for the root tag.
  Code tagRoot() {
    // TODO(turnidge): Use get() here instead?
    return _cache[TAG_ROOT_ID];
  }

  void processProfile(ServiceMap profile) {
    assert(profile.serviceType == 'Profile');
    var codeTable = new List<Code>();
    var codeRegions = profile['codes'];
    for (var codeRegion in codeRegions) {
      Code code = codeRegion['code'];
      assert(code != null);
      codeTable.add(code);
    }
    _resetProfileData();
    _updateProfileData(profile, codeTable);
    var exclusiveTrie = profile['exclusive_trie'];
    if (exclusiveTrie != null) {
      profileTrieRoot = _processProfileTrie(exclusiveTrie, codeTable);
    }
  }

  void _resetProfileData() {
    _cache.values.forEach((value) {
        if (value is Code) {
          Code code = value;
          code.resetProfileData();
        }
      });
  }

  void _updateProfileData(ServiceMap profile, List<Code> codeTable) {
    var codeRegions = profile['codes'];
    var sampleCount = profile['samples'];
    for (var codeRegion in codeRegions) {
      Code code = codeRegion['code'];
      code.updateProfileData(codeRegion, codeTable, sampleCount);
    }
  }

  /// Fetches and builds the class hierarchy for this isolate. Returns the
  /// Object class object.
  Future<Class> getClassHierarchy() {
    return get('classes').then(_loadClasses).then(_buildClassHierarchy);
  }

  /// Given the class list, loads each class.
  Future<List<Class>> _loadClasses(ServiceMap classList) {
    assert(classList.serviceType == 'ClassList');
    var futureClasses = [];
    for (var cls in classList['members']) {
      // Skip over non-class classes.
      if (cls is Class) {
        futureClasses.add(cls.load());
      }
    }
    return Future.wait(futureClasses);
  }

  /// Builds the class hierarchy and returns the Object class.
  Future<Class> _buildClassHierarchy(List<Class> classes) {
    rootClasses.clear();
    objectClass = null;
    for (var cls in classes) {
      if (cls.superClass == null) {
        rootClasses.add(cls);
      }
      if ((cls.vmName == 'Object') && (cls.isPatch == false)) {
        objectClass = cls;
      }
    }
    assert(objectClass != null);
    return new Future.value(objectClass);
  }

  ServiceObject getFromMap(ObservableMap map) {
    if (map == null) {
      return null;
    }
    String id = map['id'];
    var obj = _cache[id];
    if (obj != null) {
      return obj;
    }
    // Build the object from the map directly.
    obj = new ServiceObject._fromMap(this, map);
    if (obj != null && obj.canCache) {
      _cache[id] = obj;
    }
    return obj;
  }

  Future<ServiceObject> get(String id) {
    // Do not allow null ids or empty ids.
    assert(id != null && id != '');
    var obj = _cache[id];
    if (obj != null) {
      return obj.reload();
    }
    // Cache miss.  Get the object from the vm directly.
    return vm.getAsMap(relativeLink(id)).then((ObservableMap map) {
      var obj = new ServiceObject._fromMap(this, map);
      if (obj.canCache) {
        _cache.putIfAbsent(id, () => obj);
      }
      return obj;
    });
  }

  @observable Class objectClass;
  @observable final rootClasses = new ObservableList<Class>();

  @observable Library rootLib;
  @observable ObservableList<Library> libraries =
      new ObservableList<Library>();
  @observable ObservableMap topFrame;

  @observable String name;
  @observable String vmName;
  @observable String mainPort;
  @observable Map entry;

  @observable final Map<String, double> timers =
      toObservable(new Map<String, double>());

  final HeapSpace newSpace = new HeapSpace();
  final HeapSpace oldSpace = new HeapSpace();

  @observable String fileAndLine;

  @observable DartError error;

  void updateHeapsFromMap(ObservableMap map) {
    newSpace.update(map['new']);
    oldSpace.update(map['old']);
  }

  void _update(ObservableMap map, bool mapIsRef) {
    mainPort = map['mainPort'];
    name = map['name'];
    vmName = map['name'];
    if (mapIsRef) {
      return;
    }
    _loaded = true;
    loading = false;

    reloadBreakpoints();

    // Remap DebuggerEvent to ServiceEvent so that the observatory can
    // work against 1.5 vms in the short term.
    //
    // TODO(turnidge): Remove this when no longer needed.
    var pause = map['pauseEvent'];
    if (pause != null) {
      if (pause['type'] == 'DebuggerEvent') {
        pause['type'] = 'ServiceEvent';
      }
    }

    _upgradeCollection(map, isolate);
    if (map['rootLib'] == null ||
        map['timers'] == null ||
        map['heaps'] == null) {
      Logger.root.severe("Malformed 'Isolate' response: $map");
      return;
    }
    rootLib = map['rootLib'];
    if (map['entry'] != null) {
      entry = map['entry'];
    }
    if (map['topFrame'] != null) {
      topFrame = map['topFrame'];
    } else {
      topFrame = null ;
    }

    var countersMap = map['tagCounters'];
    if (countersMap != null) {
      var names = countersMap['names'];
      var counts = countersMap['counters'];
      assert(names.length == counts.length);
      var sum = 0;
      for (var i = 0; i < counts.length; i++) {
        sum += counts[i];
      }
      // TODO: Why does this not work without this?
      counters = toObservable({});
      if (sum == 0) {
        for (var i = 0; i < names.length; i++) {
          counters[names[i]] = '0.0%';
        }
      } else {
        for (var i = 0; i < names.length; i++) {
          counters[names[i]] =
              (counts[i] / sum * 100.0).toStringAsFixed(2) + '%';
        }
      }
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

    updateHeapsFromMap(map['heaps']);

    List features = map['features'];
    if (features != null) {
      for (var feature in features) {
        if (feature == 'io') {
          ioEnabled = true;
        }
      }
    }
    // Isolate status
    pauseEvent = map['pauseEvent'];
    running = (!_isPaused && map['topFrame'] != null);
    idle = (!_isPaused && map['topFrame'] == null);
    error = map['error'];

    libraries.clear();
    libraries.addAll(map['libraries']);
    libraries.sort(ServiceObject.LexicalSortName);
  }

  Future<TagProfile> updateTagProfile() {
    return vm.getAsMap(relativeLink('profile/tag')).then((ObservableMap m) {
      var seconds = new DateTime.now().millisecondsSinceEpoch / 1000.0;
      tagProfile._processTagProfile(seconds, m);
      return tagProfile;
    });
  }

  @reflectable CodeTrieNode profileTrieRoot;
  // The profile trie is serialized as a list of integers. Each node
  // is recreated by consuming some portion of the list. The format is as
  // follows:
  // [0] index into codeTable of code object.
  // [1] tick count (number of times this stack frame occured).
  // [2] child node count
  // Reading the trie is done by recursively reading the tree depth-first
  // pre-order.
  CodeTrieNode _processProfileTrie(List<int> data, List<Code> codeTable) {
    // Setup state shared across calls to _readTrieNode.
    _trieDataCursor = 0;
    _trieData = data;
    if (_trieData == null) {
      return null;
    }
    if (_trieData.length < 3) {
      // Not enough integers for 1 node.
      return null;
    }
    // Read the tree, returns the root node.
    return _readTrieNode(codeTable);
  }
  int _trieDataCursor;
  List<int> _trieData;
  CodeTrieNode _readTrieNode(List<Code> codeTable) {
    // Read index into code table.
    var index = _trieData[_trieDataCursor++];
    // Lookup code object.
    var code = codeTable[index];
    // Frame counter.
    var count = _trieData[_trieDataCursor++];
    // Create node.
    var node = new CodeTrieNode(code, count);
    // Number of children.
    var children = _trieData[_trieDataCursor++];
    // Recursively read child nodes.
    for (var i = 0; i < children; i++) {
      var child = _readTrieNode(codeTable);
      node.children.add(child);
      node.summedChildCount += child.count;
    }
    return node;
  }

  ServiceMap breakpoints;

  void _removeBreakpoint(ServiceMap bpt) {
    var script = bpt['location']['script'];
    var tokenPos = bpt['location']['tokenPos'];
    assert(tokenPos != null);
    if (script.loaded) {
      var line = script.tokenToLine(tokenPos);
      assert(line != null);
      assert(script.lines[line - 1].bpt == bpt);
      script.lines[line - 1].bpt = null;
    }
  }

  void _addBreakpoint(ServiceMap bpt) {
    var script = bpt['location']['script'];
    var tokenPos = bpt['location']['tokenPos'];
    assert(tokenPos != null);
    if (script.loaded) {
      var line = script.tokenToLine(tokenPos);
      assert(line != null);
      assert(script.lines[line - 1].bpt == null);
      script.lines[line - 1].bpt = bpt;
    } else {
      // Load the script and then plop in the breakpoint.
      script.load().then((_) {
          _addBreakpoint(bpt);
      });
    }
  }

  void _updateBreakpoints(ServiceMap newBreakpoints) {
    // Remove all of the old breakpoints from the Script lines.
    if (breakpoints != null) {
      for (var bpt in breakpoints['breakpoints']) {
        _removeBreakpoint(bpt);
      }
    }
    // Add all of the new breakpoints to the Script lines.
    for (var bpt in newBreakpoints['breakpoints']) {
      _addBreakpoint(bpt);
    }
    breakpoints = newBreakpoints;
  }

  Future<ServiceObject> _inProgressReloadBpts;

  Future reloadBreakpoints() {
    // TODO(turnidge): Can reusing the Future here ever cause us to
    // get stale breakpoints?
    if (_inProgressReloadBpts == null) {
      _inProgressReloadBpts =
          get('debug/breakpoints').then((newBpts) {
              _updateBreakpoints(newBpts);
          }).whenComplete(() {
              _inProgressReloadBpts = null;
          });
    }
    return _inProgressReloadBpts;
  }

  Future<ServiceObject> setBreakpoint(Script script, int line) {
    return get(script.id + "/setBreakpoint?line=${line}").then((result) {
        if (result is DartError) {
          // Unable to set a breakpoint at desired line.
          script.lines[line - 1].possibleBpt = false;
        }
        return reloadBreakpoints();
      });
  }

  Future clearBreakpoint(ServiceMap bpt) {
    return get('${bpt.id}/clear').then((result) {
        if (result is DartError) {
          // TODO(turnidge): Handle this more gracefully.
          Logger.root.severe(result.message);
        }
        if (pauseEvent != null &&
            pauseEvent.breakpoint != null &&
            (pauseEvent.breakpoint['id'] == bpt['id'])) {
          return isolate.reload();
        } else {
          return reloadBreakpoints();
        }
      });
  }

  Future pause() {
    return get("debug/pause").then((result) {
        if (result is DartError) {
          // TODO(turnidge): Handle this more gracefully.
          Logger.root.severe(result.message);
        }
        return isolate.reload();
      });
  }

  Future resume() {
    return get("debug/resume").then((result) {
        if (result is DartError) {
          // TODO(turnidge): Handle this more gracefully.
          Logger.root.severe(result.message);
        }
        return isolate.reload();
      });
  }

  Future stepInto() {
    print('isolate.stepInto');
    return get("debug/resume?step=into").then((result) {
        if (result is DartError) {
          // TODO(turnidge): Handle this more gracefully.
          Logger.root.severe(result.message);
        }
        return isolate.reload();
      });
  }

  Future stepOver() {
    return get("debug/resume?step=over").then((result) {
        if (result is DartError) {
          // TODO(turnidge): Handle this more gracefully.
          Logger.root.severe(result.message);
        }
        return isolate.reload();
      });
  }

  Future stepOut() {
    return get("debug/resume?step=out").then((result) {
        if (result is DartError) {
          // TODO(turnidge): Handle this more gracefully.
          Logger.root.severe(result.message);
        }
        return isolate.reload();
      });
  }
}

/// A [ServiceObject] which implements [ObservableMap].
class ServiceMap extends ServiceObject implements ObservableMap {
  final ObservableMap _map = new ObservableMap();
  static String objectIdRingPrefix = 'objects/';

  bool get canCache {
    return (_serviceType == 'Class' ||
            _serviceType == 'Function' ||
            _serviceType == 'Field') &&
           !_id.startsWith(objectIdRingPrefix);
  }
  bool get immutable => false;

  ServiceMap._empty(ServiceObjectOwner owner) : super._empty(owner);

  String toString() => _map.toString();

  void _upgradeValues() {
    assert(owner != null);
    _upgradeCollection(_map, owner);
  }

  void _update(ObservableMap map, bool mapIsRef) {
    _loaded = !mapIsRef;

    // TODO(turnidge): Currently _map.clear() prevents us from
    // upgrading an already upgraded submap.  Is clearing really the
    // right thing to do here?
    _map.clear();
    _map.addAll(map);

    name = _map['user_name'];
    vmName = _map['name'];
    _upgradeValues();
  }

  // Forward Map interface calls.
  void addAll(Map other) => _map.addAll(other);
  void clear() => _map.clear();
  bool containsValue(v) => _map.containsValue(v);
  bool containsKey(k) => _map.containsKey(k);
  void forEach(Function f) => _map.forEach(f);
  putIfAbsent(key, Function ifAbsent) => _map.putIfAbsent(key, ifAbsent);
  void remove(key) => _map.remove(key);
  operator [](k) => _map[k];
  operator []=(k, v) => _map[k] = v;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  Iterable get keys => _map.keys;
  Iterable get values => _map.values;
  int get length => _map.length;

  // Forward ChangeNotifier interface calls.
  bool deliverChanges() => _map.deliverChanges();
  void notifyChange(ChangeRecord record) => _map.notifyChange(record);
  notifyPropertyChange(Symbol field, Object oldValue, Object newValue) =>
      _map.notifyPropertyChange(field, oldValue, newValue);
  void observed() => _map.observed();
  void unobserved() => _map.unobserved();
  Stream<List<ChangeRecord>> get changes => _map.changes;
  bool get hasObservers => _map.hasObservers;
}

/// A [DartError] is peered to a Dart Error object.
class DartError extends ServiceObject {
  DartError._empty(ServiceObject owner) : super._empty(owner);

  @observable String kind;
  @observable String message;
  @observable ServiceMap exception;
  @observable ServiceMap stacktrace;

  void _update(ObservableMap map, bool mapIsRef) {
    kind = map['kind'];
    message = map['message'];
    exception = new ServiceObject._fromMap(owner, map['exception']);
    stacktrace = new ServiceObject._fromMap(owner, map['stacktrace']);
    name = 'DartError $kind';
    vmName = name;
  }
}

/// A [ServiceError] is an error that was triggered in the service
/// server or client. Errors are prorammer mistakes that could have
/// been prevented, for example, requesting a non-existant path over the
/// service.
class ServiceError extends ServiceObject {
  ServiceError._empty(ServiceObjectOwner owner) : super._empty(owner);

  @observable String kind;
  @observable String message;

  void _update(ObservableMap map, bool mapIsRef) {
    _loaded = true;
    kind = map['kind'];
    message = map['message'];
    name = 'ServiceError $kind';
    vmName = name;
  }
}

/// A [ServiceException] is an exception that was triggered in the service
/// server or client. Exceptions are events that should be handled,
/// for example, an isolate went away or the connection to the VM was lost.
class ServiceException extends ServiceObject {
  ServiceException._empty(ServiceObject owner) : super._empty(owner);

  @observable String kind;
  @observable String message;
  @observable dynamic response;

  void _update(ObservableMap map, bool mapIsRef) {
    kind = map['kind'];
    message = map['message'];
    response = map['response'];
    name = 'ServiceException $kind';
    vmName = name;
  }
}

/// A [ServiceEvent] is an asynchronous event notification from the vm.
class ServiceEvent extends ServiceObject {
  ServiceEvent._empty(ServiceObjectOwner owner) : super._empty(owner);

  @observable String eventType;
  @observable ServiceMap breakpoint;
  @observable ServiceMap exception;
  @observable ByteData data;

  void _update(ObservableMap map, bool mapIsRef) {
    _loaded = true;
    _upgradeCollection(map, owner);
    eventType = map['eventType'];
    name = 'ServiceEvent $eventType';
    vmName = name;
    if (map['breakpoint'] != null) {
      breakpoint = map['breakpoint'];
    }
    if (map['exception'] != null) {
      exception = map['exception'];
    }
    if (map['_data'] != null) {
      data = map['_data'];
    }
  }
  
  String toString() {
    return 'ServiceEvent of type $eventType with '
        '${data == null ? 0 : data.lengthInBytes} bytes of binary data';
  }
}

class Library extends ServiceObject with Coverage {
  @observable String url;
  @reflectable final imports = new ObservableList<Library>();
  @reflectable final scripts = new ObservableList<Script>();
  @reflectable final classes = new ObservableList<Class>();
  @reflectable final variables = new ObservableList<ServiceMap>();
  @reflectable final functions = new ObservableList<ServiceFunction>();

  bool get canCache => true;
  bool get immutable => false;

  Library._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(ObservableMap map, bool mapIsRef) {
    url = map['url'];
    var shortUrl = url;
    if (url.startsWith('file://') ||
        url.startsWith('http://')) {
      shortUrl = url.substring(url.lastIndexOf('/') + 1);
    }
    name = map['user_name'];
    if (name.isEmpty) {
      name = shortUrl;
    }
    vmName = map['name'];
    if (mapIsRef) {
      return;
    }
    _loaded = true;
    _upgradeCollection(map, isolate);
    imports.clear();
    imports.addAll(removeDuplicatesAndSortLexical(map['imports']));
    scripts.clear();
    scripts.addAll(removeDuplicatesAndSortLexical(map['scripts']));
    classes.clear();
    classes.addAll(map['classes']);
    classes.sort(ServiceObject.LexicalSortName);
    variables.clear();
    variables.addAll(map['variables']);
    variables.sort(ServiceObject.LexicalSortName);
    functions.clear();
    functions.addAll(map['functions']);
    functions.sort(ServiceObject.LexicalSortName);
  }
}

class AllocationCount extends Observable {
  @observable int instances = 0;
  @observable int bytes = 0;

  void reset() {
    instances = 0;
    bytes = 0;
  }

  bool get empty => (instances == 0) && (bytes == 0);
}

class Allocations {
  // Indexes into VM provided array. (see vm/class_table.h).
  static const ALLOCATED_BEFORE_GC = 0;
  static const ALLOCATED_BEFORE_GC_SIZE = 1;
  static const LIVE_AFTER_GC = 2;
  static const LIVE_AFTER_GC_SIZE = 3;
  static const ALLOCATED_SINCE_GC = 4;
  static const ALLOCATED_SINCE_GC_SIZE = 5;
  static const ACCUMULATED = 6;
  static const ACCUMULATED_SIZE = 7;

  final AllocationCount accumulated = new AllocationCount();
  final AllocationCount current = new AllocationCount();

  void update(List stats) {
    accumulated.instances = stats[ACCUMULATED];
    accumulated.bytes = stats[ACCUMULATED_SIZE];
    current.instances = stats[LIVE_AFTER_GC] + stats[ALLOCATED_SINCE_GC];
    current.bytes = stats[LIVE_AFTER_GC_SIZE] + stats[ALLOCATED_SINCE_GC_SIZE];
  }

  bool get empty => accumulated.empty && current.empty;
}

class Class extends ServiceObject with Coverage {
  @observable Library library;
  @observable Script script;
  @observable Class superClass;

  @observable bool isAbstract;
  @observable bool isConst;
  @observable bool isFinalized;
  @observable bool isPatch;
  @observable bool isImplemented;

  @observable int tokenPos;
  @observable int endTokenPos;

  @observable ServiceMap error;

  final Allocations newSpace = new Allocations();
  final Allocations oldSpace = new Allocations();
  final AllocationCount promotedByLastNewGC = new AllocationCount();

  bool get hasNoAllocations => newSpace.empty && oldSpace.empty;

  @reflectable final children = new ObservableList<Class>();
  @reflectable final subClasses = new ObservableList<Class>();
  @reflectable final fields = new ObservableList<ServiceMap>();
  @reflectable final functions = new ObservableList<ServiceFunction>();
  @reflectable final interfaces = new ObservableList<Class>();

  bool get canCache => true;
  bool get immutable => false;

  Class._empty(ServiceObjectOwner owner) : super._empty(owner);

  String toString() {
    return 'Service Class: $vmName';
  }

  void _update(ObservableMap map, bool mapIsRef) {
    name = map['user_name'];
    vmName = map['name'];

    if (mapIsRef) {
      return;
    }

    // We are fully loaded.
    _loaded = true;

    // Extract full properties.
    _upgradeCollection(map, isolate);

    // Some builtin classes aren't associated with a library.
    if (map['library'] is Library) {
      library = map['library'];
    } else {
      library = null;
    }

    script = map['script'];

    isAbstract = map['abstract'];
    isConst = map['const'];
    isFinalized = map['finalized'];
    isPatch = map['patch'];
    isImplemented = map['implemented'];

    tokenPos = map['tokenPos'];
    endTokenPos = map['endTokenPos'];

    subClasses.clear();
    subClasses.addAll(map['subclasses']);
    subClasses.sort(ServiceObject.LexicalSortName);

    fields.clear();
    fields.addAll(map['fields']);
    fields.sort(ServiceObject.LexicalSortName);

    functions.clear();
    functions.addAll(map['functions']);
    functions.sort(ServiceObject.LexicalSortName);

    superClass = map['super'];
    if (superClass != null) {
      superClass._addToChildren(this);
    }
    error = map['error'];

    var allocationStats = map['allocationStats'];
    if (allocationStats != null) {
      newSpace.update(allocationStats['new']);
      oldSpace.update(allocationStats['old']);
      promotedByLastNewGC.instances = allocationStats['promotedInstances'];
      promotedByLastNewGC.bytes = allocationStats['promotedBytes'];
    }
  }

  void _addToChildren(Class cls) {
    if (children.contains(cls)) {
      return;
    }
    children.add(cls);
  }

  Future<ServiceObject> get(String command) {
    return isolate.get(id + "/$command");
  }
}

// TODO(koda): Sync this with VM.
class FunctionKind {
  final String _strValue;
  FunctionKind._internal(this._strValue);
  toString() => _strValue;
  bool isFake() => [kCollected, kNative, kTag, kReused].contains(this);

  static FunctionKind fromJSON(String value) {
    switch(value) {
      case 'kRegularFunction': return kRegularFunction;
      case 'kClosureFunction': return kClosureFunction;
      case 'kGetterFunction': return kGetterFunction;
      case 'kSetterFunction': return kSetterFunction;
      case 'kConstructor': return kConstructor;
      case 'kImplicitGetter': return kImplicitGetterFunction;
      case 'kImplicitSetter': return kImplicitSetterFunction;
      case 'kStaticInitializer': return kStaticInitializer;
      case 'kMethodExtractor': return kMethodExtractor;
      case 'kNoSuchMethodDispatcher': return kNoSuchMethodDispatcher;
      case 'kInvokeFieldDispatcher': return kInvokeFieldDispatcher;
      case 'Collected': return kCollected;
      case 'Native': return kNative;
      case 'Tag': return kTag;
      case 'Reused': return kReused;
    }
    return kUNKNOWN;
  }

  static FunctionKind kRegularFunction = new FunctionKind._internal('function');
  static FunctionKind kClosureFunction = new FunctionKind._internal('closure function');
  static FunctionKind kGetterFunction = new FunctionKind._internal('getter function');
  static FunctionKind kSetterFunction = new FunctionKind._internal('setter function');
  static FunctionKind kConstructor = new FunctionKind._internal('constructor');
  static FunctionKind kImplicitGetterFunction = new FunctionKind._internal('implicit getter function');
  static FunctionKind kImplicitSetterFunction = new FunctionKind._internal('implicit setter function');
  static FunctionKind kStaticInitializer = new FunctionKind._internal('static initializer');
  static FunctionKind kMethodExtractor = new FunctionKind._internal('method extractor');
  static FunctionKind kNoSuchMethodDispatcher = new FunctionKind._internal('noSuchMethod dispatcher');
  static FunctionKind kInvokeFieldDispatcher = new FunctionKind._internal('invoke field dispatcher');
  static FunctionKind kCollected = new FunctionKind._internal('Collected');
  static FunctionKind kNative = new FunctionKind._internal('Native');
  static FunctionKind kTag = new FunctionKind._internal('Tag');
  static FunctionKind kReused = new FunctionKind._internal('Reused');
  static FunctionKind kUNKNOWN = new FunctionKind._internal('UNKNOWN');
}

class ServiceFunction extends ServiceObject with Coverage {
  @observable Class owningClass;
  @observable Library owningLibrary;
  @observable bool isStatic;
  @observable bool isConst;
  @observable ServiceFunction parent;
  @observable Script script;
  @observable int tokenPos;
  @observable int endTokenPos;
  @observable Code code;
  @observable Code unoptimizedCode;
  @observable bool isOptimizable;
  @observable bool isInlinable;
  @observable FunctionKind kind;
  @observable int deoptimizations;
  @observable String qualifiedName;
  @observable int usageCounter;
  @observable bool isDart;

  ServiceFunction._empty(ServiceObject owner) : super._empty(owner);

  void _update(ObservableMap map, bool mapIsRef) {
    name = map['user_name'];
    vmName = map['name'];

    _upgradeCollection(map, isolate);

    owningClass = map.containsKey('owningClass') ? map['owningClass'] : null;
    owningLibrary = map.containsKey('owningLibrary') ? map['owningLibrary'] : null;
    kind = FunctionKind.fromJSON(map['kind']);
    isDart = !kind.isFake();

    if (mapIsRef) { return; }

    isStatic = map['isStatic'];
    isConst = map['isConst'];
    parent = map['parent'];
    script = map['script'];
    tokenPos = map['tokenPos'];
    endTokenPos = map['endTokenPos'];
    code = _convertNull(map['code']);
    unoptimizedCode = _convertNull(map['unoptimized_code']);
    isOptimizable = map['is_optimizable'];
    isInlinable = map['is_inlinable'];
    deoptimizations = map['deoptimizations'];
    usageCounter = map['usage_counter'];

    if (parent == null) {
      qualifiedName = (owningClass != null) ?
          "${owningClass.name}.${name}" :
          name;
    } else {
      qualifiedName = "${parent.qualifiedName}.${name}";
    }

  }
}

class ScriptLine extends Observable {
  final Script script;
  final int line;
  final String text;
  @observable int hits;
  @observable ServiceMap bpt;
  @observable bool possibleBpt = true;

  static bool _isTrivialToken(String token) {
    if (token == 'else') {
      return true;
    }
    for (var c in token.split('')) {
      switch (c) {
        case '{':
        case '}':
        case '(':
        case ')':
        case ';':
          break;
        default:
          return false;
      }
    }
    return true;
  }

  static bool _isTrivialLine(String text) {
    var wsTokens = text.split(new RegExp(r"(\s)+"));
    for (var wsToken in wsTokens) {
      var tokens = wsToken.split(new RegExp(r"(\b)"));
      for (var token in tokens) {
        if (!_isTrivialToken(token)) {
          return false;
        }
      }
    }
    return true;
  }

  ScriptLine(this.script, this.line, this.text) {
    possibleBpt = !_isTrivialLine(text);
    
    // TODO(turnidge): This is not so efficient.  Consider improving.
    for (var bpt in this.script.isolate.breakpoints['breakpoints']) {
      var bptScript = bpt['location']['script'];
      var bptTokenPos = bpt['location']['tokenPos'];
      if (bptScript == this.script &&
          bptScript.tokenToLine(bptTokenPos) == line) {
        this.bpt = bpt;
      }
    }
  }
}

class Script extends ServiceObject with Coverage {
  final lines = new ObservableList<ScriptLine>();
  final _hits = new Map<int, int>();
  @observable String kind;
  @observable int firstTokenPos;
  @observable int lastTokenPos;
  @observable Library owningLibrary;
  bool get canCache => true;
  bool get immutable => true;

  String _shortUrl;
  String _url;

  Script._empty(ServiceObjectOwner owner) : super._empty(owner);

  ScriptLine getLine(int line) {
    assert(line >= 1);
    return lines[line - 1];
  }

  /// This function maps a token position to a line number.
  int tokenToLine(int token) => _tokenToLine[token];
  Map _tokenToLine = {};

  /// This function maps a token position to a column number.
  int tokenToCol(int token) => _tokenToCol[token];
  Map _tokenToCol = {};

  void _update(ObservableMap map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    kind = map['kind'];
    _url = map['name'];
    _shortUrl = _url.substring(_url.lastIndexOf('/') + 1);
    name = _shortUrl;
    vmName = _url;
    if (mapIsRef) {
      return;
    }
    _processSource(map['source']);
    _parseTokenPosTable(map['tokenPosTable']);
    owningLibrary = map['owning_library'];
  }

  void _parseTokenPosTable(List<List<int>> table) {
    if (table == null) {
      return;
    }
    _tokenToLine.clear();
    _tokenToCol.clear();
    firstTokenPos = null;
    lastTokenPos = null;
    var lineSet = new Set();

    for (var line in table) {
      // Each entry begins with a line number...
      var lineNumber = line[0];
      lineSet.add(lineNumber);
      for (var pos = 1; pos < line.length; pos += 2) {
        // ...and is followed by (token offset, col number) pairs.
        var tokenOffset = line[pos];
        var colNumber = line[pos+1];
        if (firstTokenPos == null) {
          // Mark first token position.
          firstTokenPos = tokenOffset;
          lastTokenPos = tokenOffset;
        } else {
          // Keep track of max and min token positions.
          firstTokenPos = (firstTokenPos <= tokenOffset) ?
              firstTokenPos : tokenOffset;
          lastTokenPos = (lastTokenPos >= tokenOffset) ?
              lastTokenPos : tokenOffset;
        }
        _tokenToLine[tokenOffset] = lineNumber;
        _tokenToCol[tokenOffset] = colNumber;
      }
    }

    for (var line in lines) {
      // Remove possible breakpoints on lines with no tokens.
      if (!lineSet.contains(line.line)) {
        line.possibleBpt = false;
      }
    }
  }

  void _processHits(List scriptHits) {
    // Update hits table.
    for (var i = 0; i < scriptHits.length; i += 2) {
      var line = scriptHits[i];
      var hit = scriptHits[i + 1]; // hit status.
      assert(line >= 1); // Lines start at 1.
      var oldHits = _hits[line];
      if (oldHits != null) {
        hit += oldHits;
      }
      _hits[line] = hit;
    }
    _applyHitsToLines();
  }

  void _processSource(String source) {
    // Preemptyively mark that this is not loaded.
    _loaded = false;
    if (source == null) {
      return;
    }
    var sourceLines = source.split('\n');
    if (sourceLines.length == 0) {
      return;
    }
    // We have the source to the script. This is now loaded.
    _loaded = true;
    lines.clear();
    Logger.root.info('Adding ${sourceLines.length} source lines for ${_url}');
    for (var i = 0; i < sourceLines.length; i++) {
      lines.add(new ScriptLine(this, i + 1, sourceLines[i]));
    }
    _applyHitsToLines();
  }

  void _applyHitsToLines() {
    for (var line in lines) {
      var hits = _hits[line.line];
      line.hits = hits;
    }
  }
}

class CodeTick {
  final int address;
  final int exclusiveTicks;
  final int inclusiveTicks;
  CodeTick(this.address, this.exclusiveTicks, this.inclusiveTicks);
}


class PcDescriptor extends Observable {
  final int address;
  @reflectable final int deoptId;
  @reflectable final int tokenPos;
  @reflectable final int tryIndex;
  @reflectable final String kind;
  @observable Script script;
  @observable String formattedLine;
  PcDescriptor(this.address, this.deoptId, this.tokenPos, this.tryIndex,
               this.kind);

  @reflectable String formattedDeoptId() {
    if (deoptId == -1) {
      return 'N/A';
    }
    return deoptId.toString();
  }

  @reflectable String formattedTokenPos() {
    if (tokenPos == -1) {
      return '';
    }
    return tokenPos.toString();
  }

  void processScript(Script script) {
    this.script = null;
    if (tokenPos == -1) {
      return;
    }
    var line = script.tokenToLine(tokenPos);
    if (line == null) {
      return;
    }
    this.script = script;
    var scriptLine = script.getLine(line);
    formattedLine = scriptLine.text;
  }
}

class CodeInstruction extends Observable {
  @observable final int address;
  @observable final String machine;
  @observable final String human;
  @observable CodeInstruction jumpTarget;
  @reflectable List<PcDescriptor> descriptors =
      new ObservableList<PcDescriptor>();

  static String formatPercent(num a, num total) {
    var percent = 100.0 * (a / total);
    return '${percent.toStringAsFixed(2)}%';
  }

  CodeInstruction(this.address, this.machine, this.human);

  @reflectable bool get isComment => address == 0;
  @reflectable bool get hasDescriptors => descriptors.length > 0;

  @reflectable String formattedAddress() {
    if (address == 0) {
      return '';
    }
    return '0x${address.toRadixString(16)}';
  }

  @reflectable String formattedInclusive(Code code) {
    if (code == null) {
      return '';
    }
    var tick = code.addressTicks[address];
    if (tick == null) {
      return '';
    }
    // Don't show inclusive ticks if they are the same as exclusive ticks.
    if (tick.inclusiveTicks == tick.exclusiveTicks) {
      return '';
    }
    var pcent = formatPercent(tick.inclusiveTicks, code.totalSamplesInProfile);
    return '$pcent (${tick.inclusiveTicks})';
  }

  @reflectable String formattedExclusive(Code code) {
    if (code == null) {
      return '';
    }
    var tick = code.addressTicks[address];
    if (tick == null) {
      return '';
    }
    var pcent = formatPercent(tick.exclusiveTicks, code.totalSamplesInProfile);
    return '$pcent (${tick.exclusiveTicks})';
  }

  bool _isJumpInstruction() {
    return human.startsWith('j');
  }

  int _getJumpAddress() {
    assert(_isJumpInstruction());
    var chunks = human.split(' ');
    if (chunks.length != 2) {
      // We expect jump instructions to be of the form 'j.. address'.
      return 0;
    }
    var address = chunks[1];
    if (address.startsWith('0x')) {
      // Chop off the 0x.
      address = address.substring(2);
    }
    try {
      return int.parse(address, radix:16);
    } catch (_) {
      return 0;
    }
  }

  void _resolveJumpTarget(List<CodeInstruction> instructions) {
    if (!_isJumpInstruction()) {
      return;
    }
    int address = _getJumpAddress();
    if (address == 0) {
      // Could not determine jump address.
      Logger.root.severe('Could not determine jump address for $human');
      return;
    }
    for (var i = 0; i < instructions.length; i++) {
      var instruction = instructions[i];
      if (instruction.address == address) {
        jumpTarget = instruction;
        return;
      }
    }
    Logger.root.severe(
        'Could not find instruction at ${address.toRadixString(16)}');
  }
}

class CodeKind {
  final _value;
  const CodeKind._internal(this._value);
  String toString() => '$_value';

  static CodeKind fromString(String s) {
    if (s == 'Native') {
      return Native;
    } else if (s == 'Dart') {
      return Dart;
    } else if (s == 'Collected') {
      return Collected;
    } else if (s == 'Reused') {
      return Reused;
    } else if (s == 'Tag') {
      return Tag;
    }
    Logger.root.warning('Unknown code kind $s');
    throw new FallThroughError();
  }
  static const Native = const CodeKind._internal('Native');
  static const Dart = const CodeKind._internal('Dart');
  static const Collected = const CodeKind._internal('Collected');
  static const Reused = const CodeKind._internal('Reused');
  static const Tag = const CodeKind._internal('Tag');
}

class CodeCallCount {
  final Code code;
  final int count;
  CodeCallCount(this.code, this.count);
}

class CodeTrieNode {
  final Code code;
  final int count;
  final children = new List<CodeTrieNode>();
  int summedChildCount = 0;
  CodeTrieNode(this.code, this.count);
}

class Code extends ServiceObject {
  @observable CodeKind kind;
  @observable int totalSamplesInProfile = 0;
  @reflectable int exclusiveTicks = 0;
  @reflectable int inclusiveTicks = 0;
  @reflectable int startAddress = 0;
  @reflectable int endAddress = 0;
  @reflectable final callers = new List<CodeCallCount>();
  @reflectable final callees = new List<CodeCallCount>();
  @reflectable final instructions = new ObservableList<CodeInstruction>();
  @reflectable final addressTicks = new ObservableMap<int, CodeTick>();
  @observable String formattedInclusiveTicks = '';
  @observable String formattedExclusiveTicks = '';
  @observable ServiceMap objectPool;
  @observable ServiceFunction function;
  @observable Script script;
  @observable bool isOptimized = false;
  String name;
  String vmName;

  bool get canCache => true;
  bool get immutable => true;

  Code._empty(ServiceObjectOwner owner) : super._empty(owner);

  // Reset all data associated with a profile.
  void resetProfileData() {
    totalSamplesInProfile = 0;
    exclusiveTicks = 0;
    inclusiveTicks = 0;
    formattedInclusiveTicks = '';
    formattedExclusiveTicks = '';
    callers.clear();
    callees.clear();
    addressTicks.clear();
  }

  void _updateDescriptors(Script script) {
    this.script = script;
    for (var instruction in instructions) {
      for (var descriptor in instruction.descriptors) {
        descriptor.processScript(script);
      }
    }
  }

  void loadScript() {
    if (script != null) {
      // Already done.
      return;
    }
    if (kind != CodeKind.Dart){
      return;
    }
    if (function == null) {
      return;
    }
    if (function.script == null) {
      // Attempt to load the function.
      function.load().then((func) {
        var script = function.script;
        if (script == null) {
          // Function doesn't have an associated script.
          return;
        }
        // Load the script and then update descriptors.
        script.load().then(_updateDescriptors);
      });
      return;
    }
    // Load the script and then update descriptors.
    function.script.load().then(_updateDescriptors);
  }

  /// Reload [this]. Returns a future which completes to [this] or
  /// a [ServiceError].
  Future<ServiceObject> reload() {
    assert(kind != null);
    if (kind == CodeKind.Dart) {
      // We only reload Dart code.
      return super.reload();
    }
    return new Future.value(this);
  }

  void _resolveCalls(List<CodeCallCount> calls, List data, List<Code> codes) {
    // Assert that this has been cleared.
    assert(calls.length == 0);
    // Resolve.
    for (var i = 0; i < data.length; i += 2) {
      var index = int.parse(data[i]);
      var count = int.parse(data[i + 1]);
      assert(index >= 0);
      assert(index < codes.length);
      calls.add(new CodeCallCount(codes[index], count));
    }
    // Sort to descending count order.
    calls.sort((a, b) => b.count - a.count);
  }


  static String formatPercent(num a, num total) {
    var percent = 100.0 * (a / total);
    return '${percent.toStringAsFixed(2)}%';
  }

  void updateProfileData(Map profileData,
                         List<Code> codeTable,
                         int sampleCount) {
    // Assert we have a CodeRegion entry.
    assert(profileData['type'] == 'CodeRegion');
    // Assert we are handed profile data for this code object.
    assert(profileData['code'] == this);
    totalSamplesInProfile = sampleCount;
    inclusiveTicks = int.parse(profileData['inclusive_ticks']);
    exclusiveTicks = int.parse(profileData['exclusive_ticks']);
    _resolveCalls(callers, profileData['callers'], codeTable);
    _resolveCalls(callees, profileData['callees'], codeTable);
    var ticks = profileData['ticks'];
    if (ticks != null) {
      _processTicks(ticks);
    }
    formattedInclusiveTicks =
        '${formatPercent(inclusiveTicks, totalSamplesInProfile)} '
        '($inclusiveTicks)';
    formattedExclusiveTicks =
        '${formatPercent(exclusiveTicks, totalSamplesInProfile)} '
        '($exclusiveTicks)';
  }

  void _update(ObservableMap m, bool mapIsRef) {
    name = m['user_name'];
    vmName = m['name'];
    isOptimized = m['isOptimized'] != null ? m['isOptimized'] : false;
    kind = CodeKind.fromString(m['kind']);
    startAddress = int.parse(m['start'], radix:16);
    endAddress = int.parse(m['end'], radix:16);
    function = isolate.getFromMap(m['function']);
    objectPool = isolate.getFromMap(m['object_pool']);
    var disassembly = m['disassembly'];
    if (disassembly != null) {
      _processDisassembly(disassembly);
    }
    var descriptors = m['descriptors'];
    if (descriptors != null) {
      descriptors = descriptors['members'];
      _processDescriptors(descriptors);
    }
    // We are loaded if we have instructions or are not Dart code.
    _loaded = (instructions.length != 0) || (kind != CodeKind.Dart);
    hasDisassembly = (instructions.length != 0) && (kind == CodeKind.Dart);
  }

  @observable bool hasDisassembly = false;

  void _processDisassembly(List<String> disassembly){
    assert(disassembly != null);
    instructions.clear();
    assert((disassembly.length % 3) == 0);
    for (var i = 0; i < disassembly.length; i += 3) {
      var address = 0;  // Assume code comment.
      var machine = disassembly[i + 1];
      var human = disassembly[i + 2];
      if (disassembly[i] != '') {
        // Not a code comment, extract address.
        address = int.parse(disassembly[i]);
      }
      var instruction = new CodeInstruction(address, machine, human);
      instructions.add(instruction);
    }
    for (var instruction in instructions) {
      instruction._resolveJumpTarget(instructions);
    }
  }

  void _processDescriptor(Map d) {
    var address = int.parse(d['pc'], radix:16);
    var deoptId = d['deoptId'];
    var tokenPos = d['tokenPos'];
    var tryIndex = d['tryIndex'];
    var kind = d['kind'].trim();
    for (var instruction in instructions) {
      if (instruction.address == address) {
        instruction.descriptors.add(new PcDescriptor(address,
                                                     deoptId,
                                                     tokenPos,
                                                     tryIndex,
                                                     kind));
        return;
      }
    }
    Logger.root.warning(
        'Could not find instruction with pc descriptor address: $address');
  }

  void _processDescriptors(List<Map> descriptors) {
    for (Map descriptor in descriptors) {
      _processDescriptor(descriptor);
    }
  }

  void _processTicks(List<String> profileTicks) {
    assert(profileTicks != null);
    assert((profileTicks.length % 3) == 0);
    for (var i = 0; i < profileTicks.length; i += 3) {
      var address = int.parse(profileTicks[i], radix:16);
      var exclusive = int.parse(profileTicks[i + 1]);
      var inclusive = int.parse(profileTicks[i + 2]);
      var tick = new CodeTick(address, exclusive, inclusive);
      addressTicks[address] = tick;
    }
  }

  /// Returns true if [address] is contained inside [this].
  bool contains(int address) {
    return (address >= startAddress) && (address < endAddress);
  }

  /// Sum all caller counts.
  int sumCallersCount() => _sumCallCount(callers);
  /// Specific caller count.
  int callersCount(Code code) => _callCount(callers, code);
  /// Sum of callees count.
  int sumCalleesCount() => _sumCallCount(callees);
  /// Specific callee count.
  int calleesCount(Code code) => _callCount(callees, code);

  int _sumCallCount(List<CodeCallCount> calls) {
    var sum = 0;
    for (CodeCallCount caller in calls) {
      sum += caller.count;
    }
    return sum;
  }

  int _callCount(List<CodeCallCount> calls, Code code) {
    for (CodeCallCount caller in calls) {
      if (caller.code == code) {
        return caller.count;
      }
    }
    return 0;
  }

  @reflectable bool get isDartCode => kind == CodeKind.Dart;
}


class SocketKind {
  final _value;
  const SocketKind._internal(this._value);
  String toString() => '$_value';

  static SocketKind fromString(String s) {
    if (s == 'Listening') {
      return Listening;
    } else if (s == 'Normal') {
      return Normal;
    } else if (s == 'Pipe') {
      return Pipe;
    } else if (s == 'Internal') {
      return Internal;
    }
    Logger.root.warning('Unknown socket kind $s');
    throw new FallThroughError();
  }
  static const Listening = const SocketKind._internal('Listening');
  static const Normal = const SocketKind._internal('Normal');
  static const Pipe = const SocketKind._internal('Pipe');
  static const Internal = const SocketKind._internal('Internal');
}

/// A snapshot of statistics associated with a [Socket].
class SocketStats {
  @reflectable final int bytesRead;
  @reflectable final int bytesWritten;
  @reflectable final int readCalls;
  @reflectable final int writeCalls;
  @reflectable final int available;

  SocketStats(this.bytesRead, this.bytesWritten,
              this.readCalls, this.writeCalls,
              this.available);
}

/// A peer to a Socket in dart:io. Sockets can represent network sockets or
/// OS pipes. Each socket is owned by another ServceObject, for example,
/// a process or an HTTP server.
class Socket extends ServiceObject {
  Socket._empty(ServiceObjectOwner owner) : super._empty(owner);

  bool get canCache => true;

  ServiceObject socketOwner;

  @reflectable bool get isPipe => (kind == SocketKind.Pipe);

  @observable SocketStats latest;
  @observable SocketStats previous;

  @observable SocketKind kind;

  @observable String protocol = '';

  @observable bool readClosed = false;
  @observable bool writeClosed = false;
  @observable bool closing = false;

  /// Listening for connections.
  @observable bool listening = false;

  @observable int fd;

  @observable String localAddress;
  @observable int localPort;
  @observable String remoteAddress;
  @observable int remotePort;

  // Updates internal state from [map]. [map] can be a reference.
  void _update(ObservableMap map, bool mapIsRef) {
    name = map['name'];
    vmName = map['name'];

    kind = SocketKind.fromString(map['kind']);

    if (mapIsRef) {
      return;
    }

    _loaded = true;

    _upgradeCollection(map, isolate);

    readClosed = map['readClosed'];
    writeClosed = map['writeClosed'];
    closing = map['closing'];
    listening = map['listening'];

    protocol = map['protocol'];

    localAddress = map['localAddress'];
    localPort = map['localPort'];
    remoteAddress = map['remoteAddress'];
    remotePort = map['remotePort'];

    fd = map['fd'];
    socketOwner = map['owner'];
  }
}

// Convert any ServiceMaps representing a null instance into an actual null.
_convertNull(obj) {
  if (obj is ServiceMap &&
      obj.serviceType == 'Null') {
    return null;
  }
  return obj;
}

// Returns true if [map] is a service map. i.e. it has the following keys:
// 'id' and a 'type'.
bool _isServiceMap(ObservableMap m) {
  return (m != null) && (m['id'] != null) && (m['type'] != null);
}

bool _hasRef(String type) => type.startsWith('@');
String _stripRef(String type) => (_hasRef(type) ? type.substring(1) : type);

/// Recursively upgrades all [ServiceObject]s inside [collection] which must
/// be an [ObservableMap] or an [ObservableList]. Upgraded elements will be
/// associated with [vm] and [isolate].
void _upgradeCollection(collection, ServiceObjectOwner owner) {
  if (collection is ServiceMap) {
    return;
  }
  if (collection is ObservableMap) {
    _upgradeObservableMap(collection, owner);
  } else if (collection is ObservableList) {
    _upgradeObservableList(collection, owner);
  }
}

void _upgradeObservableMap(ObservableMap map, ServiceObjectOwner owner) {
  map.forEach((k, v) {
    if ((v is ObservableMap) && _isServiceMap(v)) {
      map[k] = owner.getFromMap(v);
    } else if (v is ObservableList) {
      _upgradeObservableList(v, owner);
    } else if (v is ObservableMap) {
      _upgradeObservableMap(v, owner);
    }
  });
}

void _upgradeObservableList(ObservableList list, ServiceObjectOwner owner) {
  for (var i = 0; i < list.length; i++) {
    var v = list[i];
    if ((v is ObservableMap) && _isServiceMap(v)) {
      list[i] = owner.getFromMap(v);
    } else if (v is ObservableList) {
      _upgradeObservableList(v, owner);
    } else if (v is ObservableMap) {
      _upgradeObservableMap(v, owner);
    }
  }
}
