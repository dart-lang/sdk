// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of service;

/// A [ServiceObject] is an object known to the VM service and is tied
/// to an owning [Isolate].
abstract class ServiceObject extends Observable {
  Isolate _isolate;

  /// Owning isolate.
  @reflectable Isolate get isolate => _isolate;

  /// Owning vm.
  @reflectable VM get vm => _isolate.vm;

  /// The complete service url of this object.
  @reflectable String get link => isolate.relativeLink(_id);

  /// The complete service url of this object with a '#/' prefix.
  @reflectable String get hashLink => isolate.relativeHashLink(_id);
  set hashLink(var o) { /* silence polymer */ }

  String _id;
  /// The id of this object.
  @reflectable String get id => _id;

  String _serviceType;
  /// The service type of this object.
  @reflectable String get serviceType => _serviceType;

  bool _ref;

  @observable String name;
  @observable String vmName;

  ServiceObject(this._isolate, this._id, this._serviceType) {
    _ref = isRefType(_serviceType);
    _serviceType = stripRef(_serviceType);
    _created();
  }

  ServiceObject.fromMap(this._isolate, ObservableMap m) {
    assert(isServiceMap(m));
    _id = m['id'];
    _ref = isRefType(m['type']);
    _serviceType = stripRef(m['type']);
    _created();
    update(m);
  }

  /// If [this] was created from a reference, load the full object
  /// from the service by calling [reload]. Else, return [this].
  Future<ServiceObject> load() {
    if (!_ref) {
      // Not a reference.
      return new Future.value(this);
    }
    // Call reload which will fill in the entire object.
    return reload();
  }

  /// Reload [this]. Returns a future which completes to [this] or
  /// a [ServiceError].
  Future<ServiceObject> reload() {
    assert(isolate != null);
    if (id == '') {
      // Errors don't have ids.
      assert(serviceType == 'Error');
      return new Future.value(this);
    }
    return isolate.vm.getAsMap(link).then(update);
  }

  /// Update [this] using [m] as a source. [m] can be a reference.
  ServiceObject update(ObservableMap m) {
    // Assert that m is a service map.
    assert(ServiceObject.isServiceMap(m));
    if ((m['type'] == 'Error') && (_serviceType != 'Error')) {
      // Got an unexpected error. Don't update the object.
      return _upgradeToServiceObject(vm, isolate, m);
    }
    // TODO(johnmccutchan): Should we allow for a ServiceObject's id
    // or type to change?
    _id = m['id'];
    _serviceType = stripRef(m['type']);
    _update(m);
    return this;
  }

  // update internal state from [map]. [map] can be a reference.
  void _update(ObservableMap map);

  /// Returns true if [this] has only been partially initialized via
  /// a reference. See [load].
  bool isRef() => _ref;

  void _created() {
    var refNotice = _ref ? ' Created from reference.' : '';
    Logger.root.info('Created ServiceObject for \'${_id}\' with type '
                     '\'${_serviceType}\'.' + refNotice);
  }

  /// Returns true if [map] is a service map. i.e. it has the following keys:
  /// 'id' and a 'type'.
  static bool isServiceMap(ObservableMap m) {
    return (m != null) && (m['id'] != null) && (m['type'] != null);
  }

  /// Returns true if [type] is a reference type. i.e. it begins with an
  /// '@' character.
  static bool isRefType(String type) {
    return type.startsWith('@');
  }

  /// Returns the unreffed version of [type].
  static String stripRef(String type) {
    if (!isRefType(type)) {
      return type;
    }
    // Strip off the '@' character.
    return type.substring(1);
  }
}

/// State for a VM being inspected.
abstract class VM extends Observable {
  @reflectable IsolateList _isolates;
  @reflectable IsolateList get isolates => _isolates;

  void _initOnce() {
    assert(_isolates == null);
    _isolates = new IsolateList(this);
  }

  VM() {
    _initOnce();
  }

  /// Get [id] as an [ObservableMap] from the service directly.
  Future<ObservableMap> getAsMap(String id) {
    return getString(id).then((response) {
      try {
        var map = JSON.decode(response);
        Logger.root.info('Decoded $id');
        return toObservable(map);
      } catch (e, st) {
        return toObservable({
          'type': 'Error',
          'id': '',
          'kind': 'DecodeError',
          'message': '$e',
        });
      }
    }).catchError((error) {
      return toObservable({
        'type': 'Error',
        'id': '',
        'kind': 'LastResort',
        'message': '$error'
      });
    });
  }

  /// Get [id] as a [String] from the service directly. See [getAsMap].
  Future<String> getString(String id);
}

/// State for a running isolate.
class Isolate extends ServiceObject {
  final VM vm;
  String get link => _id;
  String get hashLink => '#/$_id';

  ScriptCache _scripts;
  /// Script cache.
  ScriptCache get scripts => _scripts;
  CodeCache _codes;
  /// Code cache.
  CodeCache get codes => _codes;
  /// Class cache.
  ClassCache _classes;
  ClassCache get classes => _classes;
  /// Function cache.
  FunctionCache _functions;
  FunctionCache get functions => _functions;

  void _initOnce() {
    // Only called once.
    assert(_isolate == null);
    _isolate = this;
    _scripts = new ScriptCache(this);
    _codes = new CodeCache(this);
    _classes = new ClassCache(this);
    _functions = new FunctionCache(this);
  }

  Isolate.fromId(this.vm, String id) : super(null, id, '@Isolate') {
    _initOnce();
  }

  Isolate.fromMap(this.vm, Map map) : super.fromMap(null, map) {
    _initOnce();
  }

  /// Creates a link to [id] relative to [this].
  @reflectable String relativeLink(String id) => '${this.id}/$id';
  /// Creates a relative link to [id] with a '#/' prefix.
  @reflectable String relativeHashLink(String id) => '#/${relativeLink(id)}';

  Future<ScriptCache> refreshCoverage() {
    return get('coverage').then(_scripts._processCoverage);
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
    _codes._resetProfileData();
    _codes._updateProfileData(profile, codeTable);
    var exclusiveTrie = profile['exclusive_trie'];
    if (exclusiveTrie != null) {
      profileTrieRoot = _processProfileTrie(exclusiveTrie, codeTable);
    }
  }

  Future<ServiceObject> getDirect(String serviceId) {
    return vm.getAsMap(relativeLink(serviceId)).then((ObservableMap m) {
        return _upgradeToServiceObject(vm, this, m);
    });
  }

  /// Requests [serviceId] from [this]. Completes to a [ServiceObject].
  /// Can return pre-existing, cached, [ServiceObject]s.
  Future<ServiceObject> get(String serviceId) {
    if (serviceId == '') {
      return reload();
    }
    if (_scripts.cachesId(serviceId)) {
      return _scripts.get(serviceId);
    }
    if (_codes.cachesId(serviceId)) {
      return _codes.get(serviceId);
    }
    if (_classes.cachesId(serviceId)) {
      return _classes.get(serviceId);
    }
    if (_functions.cachesId(serviceId)) {
      return _functions.get(serviceId);
    }
    return getDirect(serviceId);
  }

  @observable ServiceMap rootLib;
  @observable ObservableMap topFrame;

  @observable String name;
  @observable String vmName;
  @observable Map entry;

  @observable final Map<String, double> timers =
      toObservable(new Map<String, double>());

  @observable int newHeapUsed = 0;
  @observable int oldHeapUsed = 0;
  @observable int newHeapCapacity = 0;
  @observable int oldHeapCapacity = 0;

  @observable String fileAndLine;

  void _update(ObservableMap map) {
    upgradeCollection(map, vm, this);
    _ref = false;
    if (map['rootLib'] == null ||
        map['timers'] == null ||
        map['heap'] == null) {
      Logger.root.severe("Malformed 'Isolate' response: $map");
      return;
    }
    rootLib = map['rootLib'];
    vmName = map['name'];
    if (map['entry'] != null) {
      entry = map['entry'];
      name = entry['name'];
    } else {
      // fred
      name = 'root';
    }
    if (map['topFrame'] != null) {
      topFrame = map['topFrame'];
    } else {
      topFrame = null ;
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
    newHeapCapacity = map['heap']['capacityNew'];
    oldHeapCapacity = map['heap']['capacityOld'];
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
}

// TODO(johnmccutchan): Make this into an IsolateCache.
class IsolateList extends ServiceObject {
  final VM _vm;
  VM get vm => _vm;
  @observable final isolates = new ObservableMap<String, Isolate>();
  IsolateList(this._vm) : super(null, 'isolates', 'IsolateList') {
    name = 'IsolateList';
    vmName = name;
  }
  IsolateList.fromMap(this._vm, Map m) : super.fromMap(null, m) {
    name = 'IsolateList';
    vmName = name;
  }

  Future<ServiceObject> reload() {
    return vm.getAsMap(id).then(update);
  }

  void _update(ObservableMap map) {
    _updateIsolates(map['members']);
  }

  void _updateIsolates(List<Map> members) {
     // Find dead isolates.
     var deadIsolates = [];
     isolates.forEach((k, v) {
       if (!_foundIsolateInMembers(k, members)) {
         deadIsolates.add(k);
       }
     });
     // Remove them.
     deadIsolates.forEach((id) {
       isolates.remove(id);
       Logger.root.info('Isolate \'$id\' has gone away.');
     });

     // Add new isolates.
     members.forEach((map) {
       var id = map['id'];
       var isolate = isolates[id];
       if (isolate == null) {
         isolate = new Isolate.fromMap(vm, map);
         Logger.root.info('Created ServiceObject for \'${isolate.id}\' with '
                          'type \'${isolate.serviceType}\'');
         isolates[id] = isolate;
       }
     });

     // After updating the isolate list, refresh each isolate.
     _refreshIsolates();
   }

  void _refreshIsolates() {
    // This is technically asynchronous but we don't need to wait for
    // the result.
    isolates.forEach((k, Isolate isolate) {
      isolate.reload();
    });
  }

  Isolate getIsolate(String id) {
    assert(id.startsWith('isolates/'));
    var isolate = isolates[id];
    if (isolate != null) {
      return isolate;
    }
    isolate = new Isolate.fromId(vm, id);
    isolates[id] = isolate;
    isolate.load();
    return isolate;
  }

  Isolate getIsolateFromMap(ObservableMap m) {
    assert(ServiceObject.isServiceMap(m));
    String id = m['id'];
    assert(id.startsWith('isolates/'));
    var isolate = isolates[id];
    if (isolate != null) {
      isolate.update(m);
      return isolate;
    }
    isolate = new Isolate.fromMap(vm, m);
    isolates[id] = isolate;
    isolate.load();
    return isolate;
  }

  static bool _foundIsolateInMembers(String id, List<Map> members) {
    return members.any((E) => E['id'] == id);
  }
}


/// A [ServiceObject] which implements [ObservableMap].
class ServiceMap extends ServiceObject implements ObservableMap {
  final ObservableMap _map = new ObservableMap();
  ServiceMap(Isolate isolate, String id, String serviceType) :
      super(isolate, id, serviceType) {
  }

  ServiceMap.fromMap(Isolate isolate, ObservableMap m) :
      super.fromMap(isolate, m);

  String toString() => _map.toString();

  void _upgradeValues() {
    assert(isolate != null);
    upgradeCollection(_map, vm, isolate);
  }

  void _update(ObservableMap m) {
    _map.clear();
    _map.addAll(m);
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

class ServiceError extends ServiceObject {
  ServiceError.fromMap(Isolate isolate, Map m) : super.fromMap(isolate, m);

  @observable String kind;
  @observable String message;

  void _update(ObservableMap map) {
    kind = map['kind'];
    message = map['message'];
    name = 'ServiceError $kind';
    vmName = name;
  }

  // TODO: stackTrace?
}

class ScriptLine {
  @reflectable final int line;
  @reflectable final String text;
  ScriptLine(this.line, this.text);
}

class Script extends ServiceObject {
  @reflectable final lines = new ObservableList<ScriptLine>();
  @reflectable final hits = new ObservableMap<int, int>();
  @observable ServiceObject library;
  @observable String kind;

  String _shortUrl;
  String _url;

  Script.fromMap(Isolate isolate, Map m) : super.fromMap(isolate, m);

  void _update(ObservableMap m) {
    // Assert that m is a service map.
    assert(ServiceObject.isServiceMap(m));
    if ((m['type'] == 'Error') && (m['kind'] == 'NotFoundError')) {
      // TODO(johnmccutchan): Find out why dart:core/identical.dart can't
      // be found but shows up in coverage. i.e. a function has reference
      // to script that no library does.
      Logger.root.info(m['message']);
      return;
    }
    // Assert that the id hasn't changed.
    assert(m['id'] == _id);
    // Assert that the type hasn't changed.
    assert(ServiceObject.stripRef(m['type']) == _serviceType);
    _url = m['name'];
    _shortUrl = _url.substring(_url.lastIndexOf('/') + 1);
    name = _shortUrl;
    vmName = _url;
    kind = m['kind'];
    _processSource(m['source']);
  }

  void _processHits(List scriptHits) {
    if (_ref) {
      // Eagerly grab script source.
      load();
    }
    // Update hits table.
    for (var i = 0; i < scriptHits.length; i += 2) {
      var line = scriptHits[i];
      var hit = scriptHits[i + 1]; // hit status.
      assert(line >= 1); // Lines start at 1.
      hits[line] = hit;
    }
  }

  void _processSource(String source) {
    // Preemptyively mark that this is a reference.
    _ref = true;
    if (source == null) {
      return;
    }
    var sourceLines = source.split('\n');
    if (sourceLines.length == 0) {
      return;
    }
    // We have the source to the script. This is no longer a reference.
    _ref = false;
    lines.clear();
    Logger.root.info('Adding ${sourceLines.length} source lines for ${_url}');
    for (var i = 0; i < sourceLines.length; i++) {
      lines.add(new ScriptLine(i + 1, sourceLines[i]));
    }
  }


}

class CodeTick {
  final int address;
  final int exclusiveTicks;
  final int inclusiveTicks;
  CodeTick(this.address, this.exclusiveTicks, this.inclusiveTicks);
}


class CodeInstruction extends Observable {
  @observable final int address;
  @observable final String machine;
  @observable final String human;

  static String formatPercent(num a, num total) {
    var percent = 100.0 * (a / total);
    return '${percent.toStringAsFixed(2)}%';
  }

  CodeInstruction(this.address, this.machine, this.human);

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
  @observable ServiceMap function;
  String name;
  String vmName;

  Code.fromMap(Isolate isolate, Map map) : super.fromMap(isolate, map);

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

  void _update(ObservableMap m) {
    assert(ServiceObject.isServiceMap(m));
    assert(m['id'] == _id);
    assert(ServiceObject.stripRef(m['type']) == _serviceType);
    name = m['user_name'];
    vmName = m['name'];
    kind = CodeKind.fromString(m['kind']);
    startAddress = int.parse(m['start'], radix:16);
    endAddress = int.parse(m['end'], radix:16);
    function = _upgradeToServiceObject(vm, isolate, m['function']);
    objectPool = _upgradeToServiceObject(vm, isolate, m['object_pool']);
    var disassembly = m['disassembly'];
    if (disassembly != null) {
      _processDisassembly(disassembly);
    }
    // We are a reference if we don't have instructions and are Dart code.
    _ref = (instructions.length == 0) && (kind == CodeKind.Dart);
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
}
