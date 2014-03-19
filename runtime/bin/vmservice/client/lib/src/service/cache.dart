// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of service;

/// Abstract [ServiceObjectCache].
abstract class ServiceObjectCache<T extends ServiceObject> {
  final Isolate isolate;
  final _cache = new ObservableMap<String, T>();

  ServiceObjectCache(this.isolate) {
    assert(isolate != null);
  }

  /// Returns true if [this] caches objects with this [id].
  bool cachesId(String id);

  /// Upgrades [obj] into a [T].
  T _upgrade(ObservableMap map);

  /// Returns true if [this] has [id] in its cache.
  bool contains(String id) {
    assert(cachesId(id));
    return _cache[id] != null;
  }

  /// Gets [id] from the cache. Returns null if not contained.
  T operator[](String id) {
    assert(cachesId(id));
    return _cache[id];
  }

  /// Caches [serviceObject] with [id].
  operator[]=(String id, T serviceObject) {
    assert(cachesId(id));
    _cache[id] = serviceObject;
  }

  /// Gets [id] from the cache or makes a network request for [id].
  Future<T> get(String id) {
    assert(cachesId(id));
    T cached = _cache[id];
    if (cached != null) {
      return cached.load();
    }
    return isolate.getDirect(id);
  }

  /// If [obj] is cached, return the cached object. Otherwise, upgrades [obj]
  /// and adds the upgraded value to the cache.
  T putIfAbsent(ObservableMap obj) {
    assert(ServiceObject.isServiceMap(obj));
    String id = obj['id'];
    var type = obj['type'];
    if (!cachesId(id)) {
      Logger.root.warning('Cache does not cache this id: $id');
    }
    assert(cachesId(id));
    if (contains(id)) {
      return this[id];
    }
    return _addToCache(_upgrade(obj));
  }

  T _addToCache(T so) {
    this[so.id] = so;
    return so;
  }
}

class ScriptCache extends ServiceObjectCache<Script> {
  ScriptCache(Isolate isolate) : super(isolate);

  bool cachesId(String id) => _matcher.hasMatch(id);
  Script _upgrade(ObservableMap obj) => new Script.fromMap(isolate, obj);
  static final RegExp _matcher = new RegExp(r'scripts/.+');

  void _processCoverage(ServiceMap coverage) {
    assert(coverage.serviceType == 'CodeCoverage');
    var coverageList = coverage['coverage'];
    assert(coverageList != null);
    coverageList.forEach((scriptCoverage) {
      _processScriptCoverage(scriptCoverage);
    });
  }

  void _processScriptCoverage(ObservableMap scriptCoverage) {
    // Because the coverage data was upgraded into a ServiceObject,
    // the script can be directly accessed.
    Script script = scriptCoverage['script'];
    script._processHits(scriptCoverage['hits']);
  }
}

class CodeCache extends ServiceObjectCache<Code> {
  CodeCache(Isolate isolate) : super(isolate);

  bool cachesId(String id) => _matcher.hasMatch(id);
  Code _upgrade(ObservableMap obj) => new Code.fromMap(isolate, obj);

  static final RegExp _matcher = new RegExp(r'code/.+');

  List<Code> topExclusive(int count) {
    var codeList = _cache.values.toList();
    codeList.sort((Code a, Code b) {
      return b.exclusiveTicks - a.exclusiveTicks;
    });
    if (codeList.length < count) {
      return codeList;
    }
    codeList.length = count;
    return codeList;
  }

  static const TAG_ROOT_ID = 'code/tag-0';

  /// Returns the Code object for the root tag.
  Code tagRoot() {
    return _cache[TAG_ROOT_ID];
  }

  void _resetProfileData() {
    _cache.forEach((k, Code code) {
      code.resetProfileData();
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
}

class ClassCache extends ServiceObjectCache<ServiceMap> {
  ClassCache(Isolate isolate) : super(isolate);

  bool cachesId(String id) => _matcher.hasMatch(id);
  bool cachesType(String type) => ServiceObject.stripRef(type) == 'Class';
  ServiceMap _upgrade(ObservableMap obj) =>
      new ServiceMap.fromMap(isolate, obj);

  static final RegExp _matcher = new RegExp(r'classes/\d+$');
}

class FunctionCache extends ServiceObjectCache<ServiceMap> {
  FunctionCache(Isolate isolate) : super(isolate);

  bool cachesId(String id) => _matcher.hasMatch(id);

  bool cachesType(String type) => ServiceObject.stripRef(type) == 'Function';
  ServiceMap _upgrade(ObservableMap obj) =>
      new ServiceMap.fromMap(isolate, obj);

  static final RegExp _matcher =
      new RegExp(r'^functions/native-.+|'
                 r'^functions/collected-.+|'
                 r'^functions/reused-.+|'
                 r'^functions/stub-.+|'
                 r'^functions/tag-.+|'
                 r'^classes/\d+/functions/.+|'
                 r'^classes/\d+/closures/.+|'
                 r'^classes/\d+/implicit_closures/.+|'
                 r'^classes/\d+/dispatchers/.+');
}
