// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of service;

// Some value smaller than the object ring, so requesting a large array
// doesn't result in an expired ref because the elements lapped it in the
// object ring.
const int kDefaultFieldLimit = 100;

/// Helper function for canceling a Future<StreamSubscription>.
Future cancelFutureSubscription(
    Future<StreamSubscription> subscriptionFuture) async {
  if (subscriptionFuture != null) {
    var subscription = await subscriptionFuture;
    return subscription.cancel();
  } else {
    return null;
  }
}

/// An RpcException represents an exceptional event that happened
/// while invoking an rpc.
abstract class RpcException implements Exception, M.BasicException {
  RpcException(this.message);

  String message;
}

/// A ServerRpcException represents an error returned by the VM.
class ServerRpcException extends RpcException implements M.RequestException {
  /// A list of well-known server error codes.
  static const kParseError = -32700;
  static const kInvalidRequest = -32600;
  static const kMethodNotFound = -32601;
  static const kInvalidParams = -32602;
  static const kInternalError = -32603;
  static const kFeatureDisabled = 100;
  static const kCannotAddBreakpoint = 102;
  static const kStreamAlreadySubscribed = 103;
  static const kStreamNotSubscribed = 104;
  static const kIsolateMustBeRunnable = 105;
  static const kIsolateMustBePaused = 106;
  static const kCannotResume = 107;
  static const kIsolateIsReloading = 108;
  static const kIsolateReloadBarred = 109;

  static const kFileSystemAlreadyExists = 1001;
  static const kFileSystemDoesNotExist = 1002;
  static const kFileDoesNotExist = 1003;

  int code;
  Map data;

  static _getMessage(Map errorMap) {
    Map data = errorMap['data'];
    if (data != null && data['details'] != null) {
      return data['details'];
    } else {
      return errorMap['message'];
    }
  }

  ServerRpcException.fromMap(Map errorMap) : super(_getMessage(errorMap)) {
    code = errorMap['code'];
    data = errorMap['data'];
  }

  String toString() => 'ServerRpcException(${message})';
}

/// A NetworkRpcException is used to indicate that an rpc has
/// been canceled due to network error.
class NetworkRpcException extends RpcException
    implements M.ConnectionException {
  NetworkRpcException(String message) : super(message);

  String toString() => 'NetworkRpcException(${message})';
}

Future<ServiceObject> ignoreNetworkErrors(Object error,
    [ServiceObject resultOnNetworkError = null]) {
  if (error is NetworkRpcException) {
    return new Future.value(resultOnNetworkError);
  }
  return new Future.error(error);
}

class MalformedResponseRpcException extends RpcException {
  MalformedResponseRpcException(String message, this.response) : super(message);

  Map response;

  String toString() => 'MalformedResponseRpcException(${message})';
}

class FakeVMRpcException extends RpcException {
  FakeVMRpcException(String message) : super(message);

  String toString() => 'FakeVMRpcException(${message})';
}

/// A [ServiceObject] represents a persistent object within the vm.
abstract class ServiceObject {
  static int LexicalSortName(ServiceObject o1, ServiceObject o2) {
    return o1.name.compareTo(o2.name);
  }

  List removeDuplicatesAndSortLexical(List<ServiceObject> list) {
    return list.toSet().toList()..sort(LexicalSortName);
  }

  /// The owner of this [ServiceObject].  This can be an [Isolate], a
  /// [VM], or null.
  ServiceObjectOwner get owner => _owner;
  ServiceObjectOwner _owner;

  /// The [VM] which owns this [ServiceObject].
  VM get vm => _owner.vm;

  /// The [Isolate] which owns this [ServiceObject].  May be null.
  Isolate get isolate => _owner.isolate;

  /// The id of this object.
  String get id => _id;
  String _id;

  /// The user-level type of this object.
  String get type => _type;
  String _type;

  /// The vm type of this object.
  String get vmType => _vmType;
  String _vmType;

  bool get isICData => vmType == 'ICData';
  bool get isMegamorphicCache => vmType == 'MegamorphicCache';
  bool get isInstructions => vmType == 'Instructions';
  bool get isObjectPool => vmType == 'ObjectPool';
  bool get isContext => type == 'Context';
  bool get isError => type == 'Error';
  bool get isInstance => type == 'Instance';
  bool get isSentinel => type == 'Sentinel';
  bool get isMessage => type == 'Message';

  // Kinds of Instance.
  bool get isAbstractType => false;
  bool get isNull => false;
  bool get isBool => false;
  bool get isDouble => false;
  bool get isString => false;
  bool get isInt => false;
  bool get isList => false;
  bool get isMap => false;
  bool get isTypedData => false;
  bool get isRegExp => false;
  bool get isMirrorReference => false;
  bool get isWeakProperty => false;
  bool get isClosure => false;
  bool get isStackTrace => false;
  bool get isSimdValue => false;
  bool get isPlainInstance => false;

  /// Has this object been fully loaded?
  bool get loaded => _loaded;
  bool _loaded = false;
  // TODO(turnidge): Make loaded observable and get rid of loading
  // from Isolate.

  /// Is this object cacheable?  That is, is it impossible for the [id]
  /// of this object to change?
  bool _canCache;
  bool get canCache => _canCache;

  /// Is this object immutable after it is [loaded]?
  bool get immutable => false;

  String name;
  String vmName;

  /// Creates an empty [ServiceObject].
  ServiceObject._empty(this._owner);

  /// Creates a [ServiceObject] initialized from [map].
  factory ServiceObject._fromMap(ServiceObjectOwner owner, Map map) {
    if (map == null) {
      return null;
    }
    if (!_isServiceMap(map)) {
      Logger.root.severe('Malformed service object: $map');
    }
    assert(_isServiceMap(map));
    var type = _stripRef(map['type']);
    var vmType = map['_vmType'] != null ? map['_vmType'] : type;
    var obj = null;
    assert(type != 'VM');
    switch (type) {
      case 'Breakpoint':
        obj = new Breakpoint._empty(owner);
        break;
      case 'Class':
        obj = new Class._empty(owner);
        break;
      case 'Code':
        obj = new Code._empty(owner);
        break;
      case 'Context':
        obj = new Context._empty(owner);
        break;
      case 'Counter':
        obj = new ServiceMetric._empty(owner);
        break;
      case 'Error':
        obj = new DartError._empty(owner);
        break;
      case 'Field':
        obj = new Field._empty(owner);
        break;
      case 'Frame':
        obj = new Frame._empty(owner);
        break;
      case 'Function':
        obj = new ServiceFunction._empty(owner);
        break;
      case 'Gauge':
        obj = new ServiceMetric._empty(owner);
        break;
      case 'Isolate':
        obj = new Isolate._empty(owner.vm);
        break;
      case 'Library':
        obj = new Library._empty(owner);
        break;
      case 'Message':
        obj = new ServiceMessage._empty(owner);
        break;
      case 'SourceLocation':
        obj = new SourceLocation._empty(owner);
        break;
      case '_Thread':
        obj = new Thread._empty(owner);
        break;
      case 'UnresolvedSourceLocation':
        obj = new UnresolvedSourceLocation._empty(owner);
        break;
      case 'Object':
        switch (vmType) {
          case 'ICData':
            obj = new ICData._empty(owner);
            break;
          case 'LocalVarDescriptors':
            obj = new LocalVarDescriptors._empty(owner);
            break;
          case 'MegamorphicCache':
            obj = new MegamorphicCache._empty(owner);
            break;
          case 'ObjectPool':
            obj = new ObjectPool._empty(owner);
            break;
          case 'PcDescriptors':
            obj = new PcDescriptors._empty(owner);
            break;
          case 'SingleTargetCache':
            obj = new SingleTargetCache._empty(owner);
            break;
          case 'SubtypeTestCache':
            obj = new SubtypeTestCache._empty(owner);
            break;
          case 'TokenStream':
            obj = new TokenStream._empty(owner);
            break;
          case 'UnlinkedCall':
            obj = new UnlinkedCall._empty(owner);
            break;
        }
        break;
      case 'Event':
        obj = new ServiceEvent._empty(owner);
        break;
      case 'Script':
        obj = new Script._empty(owner);
        break;
      case 'Socket':
        obj = new Socket._empty(owner);
        break;
      case 'Sentinel':
        obj = new Sentinel._empty(owner);
        break;
      case 'InstanceSet':
        obj = new InstanceSet._empty(owner);
        break;
      case 'TypeArguments':
        obj = new TypeArguments._empty(owner);
        break;
      case 'Instance':
        obj = new Instance._empty(owner);
        break;
      default:
        break;
    }
    if (obj == null) {
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

  Future<Map> _fetchDirect({int count: kDefaultFieldLimit}) {
    Map params = {
      'objectId': id,
      'count': count,
    };
    return isolate.invokeRpcNoUpgrade('getObject', params);
  }

  /// Reload [this]. Returns a future which completes to [this] or
  /// an exception.
  Future<ServiceObject> reload({int count: kDefaultFieldLimit}) {
    // TODO(turnidge): Checking for a null id should be part of the
    // "immutable" check.
    bool hasId = (id != null) && (id != '');
    bool isVM = this is VM;
    // We should always reload the VM.
    // We can't reload objects without an id.
    // We shouldn't reload an immutable and already loaded object.
    bool skipLoad = !isVM && (!hasId || (immutable && loaded));
    if (skipLoad) {
      return new Future.value(this);
    }
    if (_inProgressReload == null) {
      var completer = new Completer<ServiceObject>();
      _inProgressReload = completer.future;
      _fetchDirect(count: count).then((Map map) {
        var mapType = _stripRef(map['type']);
        if (mapType == 'Sentinel') {
          // An object may have been collected, etc.
          completer.complete(new ServiceObject._fromMap(owner, map));
        } else {
          // TODO(turnidge): Check for vmType changing as well?
          assert(mapType == _type);
          update(map);
          completer.complete(this);
        }
      }).catchError((e, st) {
        Logger.root.severe("Unable to reload object: $e\n$st");
        _inProgressReload = null;
        completer.completeError(e, st);
      }).whenComplete(() {
        // This reload is complete.
        _inProgressReload = null;
      });
    }
    return _inProgressReload;
  }

  /// Update [this] using [map] as a source. [map] can be a reference.
  void update(Map map) {
    assert(_isServiceMap(map));

    // Don't allow the type to change on an object update.
    var mapIsRef = _hasRef(map['type']);
    var mapType = _stripRef(map['type']);
    assert(_type == null || _type == mapType);

    _canCache = map['fixedId'] == true;
    if (_id != null && _id != map['id']) {
      // It is only safe to change an id when the object isn't cacheable.
      assert(!canCache);
    }
    _id = map['id'];

    _type = mapType;

    // When the response specifies a specific vmType, use it.
    // Otherwise the vmType of the response is the same as the 'user'
    // type.
    if (map.containsKey('_vmType')) {
      _vmType = _stripRef(map['_vmType']);
    } else {
      _vmType = _type;
    }

    _update(map, mapIsRef);
  }

  // Updates internal state from [map]. [map] can be a reference.
  void _update(Map map, bool mapIsRef);

  // Helper that can be passed to .catchError that ignores the error.
  _ignoreError(error, stackTrace) {
    // do nothing.
  }
}

abstract class HeapObject extends ServiceObject implements M.Object {
  Class clazz;
  int size;
  int retainedSize;

  HeapObject._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    if (map['class'] != null) {
      // Sent with refs for some types. Load it if available, but don't clobber
      // it with null for kinds that only send if for full responses.
      clazz = map['class'];
    }

    // Load the full class object if the isolate is runnable.
    if (clazz != null) {
      if (clazz.isolate.runnable) {
        // No one awaits on this request so we silence any network errors
        // that occur here but forward other errors.
        clazz.load().catchError((error) => ignoreNetworkErrors(error, clazz));
      }
    }

    if (mapIsRef) {
      return;
    }
    size = map['size'];
  }
}

class RetainingObject implements M.RetainingObject {
  int get retainedSize => object.retainedSize;
  final HeapObject object;
  RetainingObject(this.object);
}

abstract class ServiceObjectOwner extends ServiceObject
    implements M.ServiceObjectOwner {
  /// Creates an empty [ServiceObjectOwner].
  ServiceObjectOwner._empty(ServiceObjectOwner owner) : super._empty(owner);

  /// Builds a [ServiceObject] corresponding to the [id] from [map].
  /// The result may come from the cache.  The result will not necessarily
  /// be [loaded].
  ServiceObject getFromMap(Map map);

  Future<M.Object> invokeRpc(String method, Map params);
}

abstract class Location implements M.Location {
  Script get script;
  int get tokenPos;
}

/// A [SourceLocation] represents a location or range in the source code.
class SourceLocation extends ServiceObject
    implements Location, M.SourceLocation {
  Script script;
  int tokenPos;
  int endTokenPos;

  Future<int> getLine() async {
    await script.load();
    return script.tokenToLine(tokenPos);
  }

  Future<int> getColumn() async {
    await script.load();
    return script.tokenToCol(tokenPos);
  }

  SourceLocation._empty(ServiceObject owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    assert(!mapIsRef);
    _upgradeCollection(map, owner);
    script = map['script'];
    tokenPos = map['tokenPos'];
    endTokenPos = map['endTokenPos'];

    assert(script != null && tokenPos != null);
  }

  Future<String> toUserString() async {
    int line = await getLine();
    int column = await getColumn();
    return '${script.name}:${line}:${column}';
  }

  String toString() {
    if (endTokenPos == null) {
      return '${script.name}:token(${tokenPos})';
    } else {
      return '${script.name}:tokens(${tokenPos}-${endTokenPos})';
    }
  }
}

/// An [UnresolvedSourceLocation] represents a location in the source
// code which has not been precisely mapped to a token position.
class UnresolvedSourceLocation extends ServiceObject
    implements Location, M.UnresolvedSourceLocation {
  Script script;
  String scriptUri;
  int line;
  int column;
  int tokenPos;

  Future<int> getLine() async {
    if (tokenPos != null) {
      await script.load();
      return script.tokenToLine(tokenPos);
    } else {
      return line;
    }
  }

  Future<int> getColumn() async {
    if (tokenPos != null) {
      await script.load();
      return script.tokenToCol(tokenPos);
    } else {
      return column;
    }
  }

  UnresolvedSourceLocation._empty(ServiceObject owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    assert(!mapIsRef);
    _upgradeCollection(map, owner);
    script = map['script'];
    scriptUri = map['scriptUri'];
    line = map['line'];
    column = map['column'];
    tokenPos = map['tokenPos'];

    assert(script != null || scriptUri != null);
    assert(line != null || tokenPos != null);
  }

  Future<String> toUserString() async {
    StringBuffer sb = new StringBuffer();

    int line = await getLine();
    int column = await getColumn();

    if (script != null) {
      sb.write('${script.name}:');
    } else {
      sb.write('${scriptUri}:');
    }
    if (column != null) {
      sb.write('${line}:${column}');
    } else {
      sb.write('${line}');
    }
    return sb.toString();
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    if (script != null) {
      sb.write('${script.name}:');
    } else {
      sb.write('${scriptUri}:');
    }
    if (tokenPos != null) {
      sb.write('token(${tokenPos})');
    } else if (column != null) {
      sb.write('${line}:${column}');
    } else {
      sb.write('${line}');
    }
    sb.write('[unresolved]');
    return sb.toString();
  }
}

class _EventStreamState {
  VM _vm;
  String streamId;

  Function _onDone;

  // A list of all subscribed controllers for this stream.
  List _controllers = [];

  // Completes when the listen rpc is finished.
  Future _listenFuture;

  // Completes when then cancel rpc is finished.
  Future _cancelFuture;

  _EventStreamState(this._vm, this.streamId, this._onDone);

  Future _cancelController(StreamController controller) {
    _controllers.remove(controller);
    if (_controllers.isEmpty) {
      assert(_listenFuture != null);
      _listenFuture = null;
      _cancelFuture = _vm._streamCancel(streamId);
      _cancelFuture.then((_) {
        if (_controllers.isEmpty) {
          // No new listeners showed up during cancelation.
          _onDone();
        }
      }).catchError((e) {
        /* ignore */
      });
    }
    // No need to wait for _cancelFuture here.
    return new Future.value(null);
  }

  Future<Stream> addStream() async {
    var controller;
    controller =
        new StreamController(onCancel: () => _cancelController(controller));
    _controllers.add(controller);
    if (_cancelFuture != null) {
      try {
        await _cancelFuture;
      } on NetworkRpcException catch (_) {/* ignore */}
    }
    if (_listenFuture == null) {
      _listenFuture = _vm._streamListen(streamId);
    }
    try {
      await _listenFuture;
    } on NetworkRpcException catch (_) {/* ignore */}
    return controller.stream;
  }

  void addEvent(ServiceEvent event) {
    for (var controller in _controllers) {
      controller.add(event);
    }
  }
}

/// State for a VM being inspected.
abstract class VM extends ServiceObjectOwner implements M.VM {
  VM get vm => this;
  Isolate get isolate => null;

  // TODO(turnidge): The connection should not be stored in the VM object.
  bool get isDisconnected;
  bool get isConnected;

  // Used for verbose logging.
  bool verbose = false;

  // TODO(johnmccutchan): Ensure that isolates do not end up in _cache.
  Map<String, ServiceObject> _cache = new Map<String, ServiceObject>();
  final Map<String, Isolate> _isolateCache = <String, Isolate>{};

  // The list of live isolates, ordered by isolate start time.
  final List<Isolate> isolates = <Isolate>[];

  final List<Service> services = <Service>[];

  String version = 'unknown';
  String hostCPU;
  String targetCPU;
  int architectureBits;
  bool assertsEnabled = false;
  bool typeChecksEnabled = false;
  int nativeZoneMemoryUsage = 0;
  int pid = 0;
  int heapAllocatedMemoryUsage = 0;
  int heapAllocationCount = 0;
  int maxRSS = 0;
  bool profileVM = false;
  DateTime startTime;
  DateTime refreshTime;
  Duration get upTime {
    if (startTime == null) {
      return null;
    }
    return (new DateTime.now().difference(startTime));
  }

  VM() : super._empty(null) {
    update({'name': 'vm', 'type': '@VM'});
  }

  void postServiceEvent(String streamId, Map response, ByteData data) {
    var map = response;
    assert(!map.containsKey('_data'));
    if (data != null) {
      map['_data'] = data;
    }
    if (map['type'] != 'Event') {
      Logger.root.severe("Expected 'Event' but found '${map['type']}'");
      return;
    }

    var eventIsolate = map['isolate'];
    var event;
    if (eventIsolate == null) {
      event = new ServiceObject._fromMap(vm, map);
    } else {
      // getFromMap creates the Isolate if it hasn't been seen already.
      var isolate = getFromMap(map['isolate']);
      event = new ServiceObject._fromMap(isolate, map);
      if (event.kind == ServiceEvent.kIsolateExit) {
        _isolateCache.remove(isolate.id);
        _buildIsolateList();
      }
      if (event.kind == ServiceEvent.kIsolateRunnable) {
        // Force reload once the isolate becomes runnable so that we
        // update the root library.
        isolate.reload();
      }
    }
    var eventStream = _eventStreams[streamId];
    if (eventStream != null) {
      eventStream.addEvent(event);
    } else {
      Logger.root.warning("Ignoring unexpected event on stream '${streamId}'");
    }
  }

  int _compareIsolates(Isolate a, Isolate b) {
    var aStart = a.startTime;
    var bStart = b.startTime;
    if (aStart == null) {
      if (bStart == null) {
        return 0;
      } else {
        return 1;
      }
    }
    if (bStart == null) {
      return -1;
    }
    return aStart.compareTo(bStart);
  }

  void _buildIsolateList() {
    var isolateList = _isolateCache.values.toList();
    isolateList.sort(_compareIsolates);
    isolates.clear();
    isolates.addAll(isolateList);
  }

  void _removeDeadIsolates(List newIsolates) {
    // Build a set of new isolates.
    var newIsolateSet = new Set();
    newIsolates.forEach((iso) => newIsolateSet.add(iso.id));

    // Remove any old isolates which no longer exist.
    List toRemove = [];
    _isolateCache.forEach((id, _) {
      if (!newIsolateSet.contains(id)) {
        toRemove.add(id);
      }
    });
    toRemove.forEach((id) => _isolateCache.remove(id));
    _buildIsolateList();
  }

  static final String _isolateIdPrefix = 'isolates/';

  ServiceObject getFromMap(Map map) {
    if (map == null) {
      return null;
    }
    var type = _stripRef(map['type']);
    if (type == 'VM') {
      // Update this VM object.
      update(map);
      return this;
    }

    String id = map['id'];
    if ((id != null) && id.startsWith(_isolateIdPrefix)) {
      // Check cache.
      var isolate = _isolateCache[id];
      if (isolate == null) {
        // Add new isolate to the cache.
        isolate = new ServiceObject._fromMap(this, map);
        _isolateCache[id] = isolate;
        _buildIsolateList();

        // Eagerly load the isolate.
        isolate.load().catchError((e, stack) {
          Logger.root.info('Eagerly loading an isolate failed: $e\n$stack');
        });
      } else {
        isolate.update(map);
      }
      return isolate;
    }

    // Build the object from the map directly.
    return new ServiceObject._fromMap(this, map);
  }

  // Note that this function does not reload the isolate if it found
  // in the cache.
  Future<ServiceObject> getIsolate(String isolateId) {
    if (!loaded) {
      // Trigger a VM load, then get the isolate.
      return load().then((_) => getIsolate(isolateId)).catchError(_ignoreError);
    }
    return new Future.value(_isolateCache[isolateId]);
  }

  // Implemented in subclass.
  Future<Map> invokeRpcRaw(String method, Map params);

  Future<Map> invokeRpcNoUpgrade(String method, Map params) {
    return invokeRpcRaw(method, params).then((Map response) {
      var map = response;
      if (Tracer.current != null) {
        Tracer.current
            .trace("Received response for ${method}/${params}}", map: map);
      }
      if (!_isServiceMap(map)) {
        var exception = new MalformedResponseRpcException(
            "Response is missing the 'type' field", map);
        return new Future.error(exception);
      }
      return new Future.value(map);
    }).catchError((e) {
      // Errors pass through.
      return new Future.error(e);
    });
  }

  Future<dynamic> invokeRpc(String method, Map params) {
    return invokeRpcNoUpgrade(method, params).then((Map response) {
      var obj = new ServiceObject._fromMap(this, response);
      if ((obj != null) && obj.canCache) {
        String objId = obj.id;
        _cache.putIfAbsent(objId, () => obj);
      }
      return obj;
    }).catchError((e) {
      return new Future.error(e);
    });
  }

  void _dispatchEventToIsolate(ServiceEvent event) {
    var isolate = event.isolate;
    if (isolate != null) {
      isolate._onEvent(event);
    }
  }

  void _updateService(ServiceEvent event) {
    switch (event.kind) {
      case ServiceEvent.kServiceRegistered:
        services.add(new Service(event.alias, event.method, event.service));
        break;
      case ServiceEvent.kServiceUnregistered:
        services.removeWhere((s) => s.method == event.method);
        break;
    }
  }

  Future<Map> _fetchDirect({int count: kDefaultFieldLimit}) async {
    if (!loaded) {
      // The vm service relies on these events to keep the VM and
      // Isolate types up to date.
      try {
        await listenEventStream(kVMStream, _dispatchEventToIsolate);
        await listenEventStream(kIsolateStream, _dispatchEventToIsolate);
        await listenEventStream(kDebugStream, _dispatchEventToIsolate);
        await listenEventStream(_kGraphStream, _dispatchEventToIsolate);
        await listenEventStream(kServiceStream, _updateService);
      } on FakeVMRpcException catch (_) {
        // ignore FakeVMRpcExceptions here.
      } on NetworkRpcException catch (_) {
        // ignore network errors here.
      }
    }
    return await invokeRpcNoUpgrade('getVM', {});
  }

  Future setName(String newName) {
    return invokeRpc('setVMName', {'name': newName});
  }

  Future<ServiceObject> getFlagList() {
    return invokeRpc('getFlagList', {});
  }

  Future<ServiceObject> _streamListen(String streamId) {
    Map params = {
      'streamId': streamId,
    };
    // Ignore network errors on stream listen.
    return invokeRpc('streamListen', params)
        .catchError((e) => ignoreNetworkErrors(e));
  }

  Future<ServiceObject> _streamCancel(String streamId) {
    Map params = {
      'streamId': streamId,
    };
    // Ignore network errors on stream cancel.
    return invokeRpc('streamCancel', params)
        .catchError((e) => ignoreNetworkErrors(e));
  }

  // A map from stream id to event stream state.
  Map<String, _EventStreamState> _eventStreams = {};

  // Well-known stream ids.
  static const kVMStream = 'VM';
  static const kIsolateStream = 'Isolate';
  static const kTimelineStream = 'Timeline';
  static const kDebugStream = 'Debug';
  static const kGCStream = 'GC';
  static const kStdoutStream = 'Stdout';
  static const kStderrStream = 'Stderr';
  static const _kGraphStream = '_Graph';
  static const kServiceStream = '_Service';

  /// Returns a single-subscription Stream object for a VM event stream.
  Future<Stream> getEventStream(String streamId) async {
    var eventStream = _eventStreams.putIfAbsent(
        streamId,
        () => new _EventStreamState(
            this, streamId, () => _eventStreams.remove(streamId)));
    Stream stream = await eventStream.addStream();
    return stream;
  }

  /// Helper function for listening to an event stream.
  Future<StreamSubscription> listenEventStream(
      String streamId, Function function) async {
    var stream = await getEventStream(streamId);
    return stream.listen(function);
  }

  /// Force the VM to disconnect.
  void disconnect();

  /// Completes when the VM first connects.
  Future get onConnect;

  /// Completes when the VM disconnects or there was an error connecting.
  Future get onDisconnect;

  void _update(Map map, bool mapIsRef) {
    name = map['name'];
    vmName = map.containsKey('_vmName') ? map['_vmName'] : name;
    if (mapIsRef) {
      return;
    }
    // Note that upgrading the collection creates any isolates in the
    // isolate list which are new.
    _upgradeCollection(map, vm);

    _loaded = true;
    version = map['version'];
    hostCPU = map['hostCPU'];
    targetCPU = map['targetCPU'];
    architectureBits = map['architectureBits'];
    int startTimeMillis = map['startTime'];
    startTime = new DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
    refreshTime = new DateTime.now();
    if (map['_nativeZoneMemoryUsage'] != null) {
      nativeZoneMemoryUsage = map['_nativeZoneMemoryUsage'];
    }
    pid = map['pid'];
    if (map['_heapAllocatedMemoryUsage'] != null) {
      heapAllocatedMemoryUsage = map['_heapAllocatedMemoryUsage'];
    }
    if (map['_heapAllocationCount'] != null) {
      heapAllocationCount = map['_heapAllocationCount'];
    }
    maxRSS = map['_maxRSS'];
    profileVM = map['_profilerMode'] == 'VM';
    assertsEnabled = map['_assertsEnabled'];
    typeChecksEnabled = map['_typeChecksEnabled'];
    _removeDeadIsolates(map['isolates']);
  }

  // Reload all isolates.
  Future reloadIsolates() {
    var reloads = [];
    for (var isolate in isolates) {
      var reload = isolate.reload().catchError((e) {
        Logger.root.info('Bulk reloading of isolates failed: $e');
      });
      reloads.add(reload);
    }
    return Future.wait(reloads);
  }
}

class FakeVM extends VM {
  String get displayName => name;

  final Map _responses = {};
  FakeVM(Map responses) {
    if (responses == null) {
      return;
    }
    responses.forEach((uri, response) {
      // Encode as string.
      _responses[_canonicalizeUri(Uri.parse(uri))] = response;
    });
  }

  String _canonicalizeUri(Uri uri) {
    // We use the uri as the key to the response map. Uri parameters can be
    // serialized in any order, this function canonicalizes the uri parameters
    // so they are serialized in sorted-by-parameter-name order.
    var method = uri.path;
    // Create a map sorted on insertion order.
    var parameters = new Map();
    // Sort keys.
    var sortedKeys = uri.queryParameters.keys.toList();
    sortedKeys.sort();
    // Filter keys to remove any private options.
    sortedKeys.removeWhere((k) => k.startsWith('_'));
    // Insert parameters in sorted order.
    for (var key in sortedKeys) {
      parameters[key] = uri.queryParameters[key];
    }
    // Return canonical uri.
    return new Uri(path: method, queryParameters: parameters).toString();
  }

  /// Force the VM to disconnect.
  void disconnect() {
    _onDisconnect.complete(this);
  }

  // Always connected.
  Future _onConnect;
  Future get onConnect {
    if (_onConnect != null) {
      return _onConnect;
    }
    _onConnect = new Future.value(this);
    return _onConnect;
  }

  bool get isConnected => !isDisconnected;
  // Only complete when requested.
  Completer _onDisconnect = new Completer();
  Future get onDisconnect => _onDisconnect.future;
  bool get isDisconnected => _onDisconnect.isCompleted;

  Future<Map> invokeRpcRaw(String method, Map params) {
    if (params.isEmpty) {
      params = null;
    }
    var key = _canonicalizeUri(new Uri(path: method, queryParameters: params));
    var response = _responses[key];
    if (response == null) {
      return new Future.error(new FakeVMRpcException(
          "Unable to find key '${key}' in cached response set"));
    }
    return new Future.value(response);
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

  void _processTagProfile(double seconds, Map tagProfile) {
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

class InboundReferences implements M.InboundReferences {
  final Iterable<InboundReference> elements;

  InboundReferences(ServiceMap map)
      : this.elements =
            map['references'].map((rmap) => new InboundReference(rmap));
}

class InboundReference implements M.InboundReference {
  final HeapObject source;
  final Instance parentField;
  final int parentListIndex;
  final int parentWordOffset;

  InboundReference(ServiceMap map)
      : source = map['source'],
        parentField = map['parentField'],
        parentListIndex = map['parentListIndex'],
        parentWordOffset = map['_parentWordOffset'];
}

class RetainingPath implements M.RetainingPath {
  final Iterable<RetainingPathItem> elements;

  RetainingPath(ServiceMap map)
      : this.elements =
            map['elements'].map((rmap) => new RetainingPathItem(rmap));
}

class RetainingPathItem implements M.RetainingPathItem {
  final HeapObject source;
  final Instance parentField;
  final int parentListIndex;
  final int parentWordOffset;

  RetainingPathItem(ServiceMap map)
      : source = map['value'],
        parentField = map['parentField'],
        parentListIndex = map['parentListIndex'],
        parentWordOffset = map['_parentWordOffset'];
}

class Ports implements M.Ports {
  final Iterable<Port> elements;

  Ports(ServiceMap map)
      : this.elements = map['ports'].map((rmap) => new Port(rmap));
}

class Port implements M.Port {
  final String name;
  final HeapObject handler;

  Port(ServiceMap map)
      : name = map['name'],
        handler = map['handler'];
}

class PersistentHandles implements M.PersistentHandles {
  final Iterable<PersistentHandle> elements;
  final Iterable<WeakPersistentHandle> weakElements;

  PersistentHandles(ServiceMap map)
      : this.elements =
            map['persistentHandles'].map((rmap) => new PersistentHandle(rmap)),
        this.weakElements = map['weakPersistentHandles']
            .map((rmap) => new WeakPersistentHandle(rmap));
}

class PersistentHandle implements M.PersistentHandle {
  final HeapObject object;

  PersistentHandle(ServiceMap map) : object = map['object'];
}

class WeakPersistentHandle implements M.WeakPersistentHandle {
  final int externalSize;
  final String peer;
  final String callbackSymbolName;
  final String callbackAddress;
  final HeapObject object;

  WeakPersistentHandle(ServiceMap map)
      : externalSize = int.parse(map['externalSize']),
        peer = map['peer'],
        callbackSymbolName = map['callbackSymbolName'],
        callbackAddress = map['callbackAddress'],
        object = map['object'];
}

class HeapSpace implements M.HeapSpace {
  int used = 0;
  int capacity = 0;
  int external = 0;
  int collections = 0;
  double totalCollectionTimeInSeconds = 0.0;
  double averageCollectionPeriodInMillis = 0.0;

  Duration get avgCollectionTime {
    final mcs = totalCollectionTimeInSeconds *
        Duration.MICROSECONDS_PER_SECOND /
        math.max(collections, 1);
    return new Duration(microseconds: mcs.ceil());
  }

  Duration get totalCollectionTime {
    final mcs = totalCollectionTimeInSeconds * Duration.MICROSECONDS_PER_SECOND;
    return new Duration(microseconds: mcs.ceil());
  }

  Duration get avgCollectionPeriod {
    final mcs =
        averageCollectionPeriodInMillis * Duration.MICROSECONDS_PER_MILLISECOND;
    return new Duration(microseconds: mcs.ceil());
  }

  void update(Map heapMap) {
    used = heapMap['used'];
    capacity = heapMap['capacity'];
    external = heapMap['external'];
    collections = heapMap['collections'];
    totalCollectionTimeInSeconds = heapMap['time'];
    averageCollectionPeriodInMillis = heapMap['avgCollectionPeriodMillis'];
  }
}

class RawHeapSnapshot {
  final chunks;
  final count;
  RawHeapSnapshot(this.chunks, this.count);
}

/// State for a running isolate.
class Isolate extends ServiceObjectOwner implements M.Isolate {
  static const kLoggingStream = '_Logging';
  static const kExtensionStream = 'Extension';

  VM get vm => owner;
  Isolate get isolate => this;
  int number;
  int originNumber;
  DateTime startTime;
  Duration get upTime {
    if (startTime == null) {
      return null;
    }
    return (new DateTime.now().difference(startTime));
  }

  Map counters = {};

  void _updateRunState() {
    topFrame = M.topFrame(pauseEvent);
    paused = (pauseEvent != null && !(pauseEvent is M.ResumeEvent));
    running = (!paused && topFrame != null);
    idle = (!paused && topFrame == null);
  }

  M.DebugEvent pauseEvent = null;
  bool paused = false;
  bool running = false;
  bool idle = false;
  bool loading = true;
  bool runnable = false;
  bool ioEnabled = false;
  M.IsolateStatus get status {
    if (paused) {
      return M.IsolateStatus.paused;
    }
    if (running) {
      return M.IsolateStatus.running;
    }
    if (idle) {
      return M.IsolateStatus.idle;
    }
    return M.IsolateStatus.loading;
  }

  final List<String> extensionRPCs = new List<String>();

  Map<String, ServiceObject> _cache = new Map<String, ServiceObject>();
  final TagProfile tagProfile = new TagProfile(20);

  Isolate._empty(ServiceObjectOwner owner) : super._empty(owner) {
    assert(owner is VM);
  }

  void resetCachedProfileData() {
    _cache.values.forEach((value) {
      if (value is Code) {
        Code code = value;
        code.profile = null;
      } else if (value is ServiceFunction) {
        ServiceFunction function = value;
        function.profile = null;
      }
    });
  }

  static const kCallSitesReport = '_CallSites';
  static const kPossibleBreakpointsReport = 'PossibleBreakpoints';
  static const kProfileReport = '_Profile';

  Future<ServiceMap> getSourceReport(List<String> report_kinds,
      [Script script, int startPos, int endPos]) {
    var params = {'reports': report_kinds};
    if (script != null) {
      params['scriptId'] = script.id;
    }
    if (startPos != null) {
      params['tokenPos'] = startPos;
    }
    if (endPos != null) {
      params['endTokenPos'] = endPos;
    }
    return invokeRpc('getSourceReport', params);
  }

  Future<ServiceMap> reloadSources(
      {String rootLibUri, String packagesUri, bool pause}) {
    Map<String, dynamic> params = <String, dynamic>{};
    if (rootLibUri != null) {
      params['rootLibUri'] = rootLibUri;
    }
    if (packagesUri != null) {
      params['packagesUri'] = packagesUri;
    }
    if (pause != null) {
      params['pause'] = pause;
    }
    return invokeRpc('reloadSources', params).then((result) {
      _cache.clear();
      return result;
    });
  }

  void _handleIsolateReloadEvent(ServiceEvent event) {
    if (event.reloadError == null) {
      _cache.clear();
    }
  }

  Future collectAllGarbage() {
    return invokeRpc('_collectAllGarbage', {});
  }

  /// Fetches and builds the class hierarchy for this isolate. Returns the
  /// Object class object.
  Future<Class> getClassHierarchy() {
    return invokeRpc('getClassList', {})
        .then(_loadClasses)
        .then(_buildClassHierarchy);
  }

  Future<ServiceObject> getPorts() {
    return invokeRpc('_getPorts', {});
  }

  Future<ServiceObject> getPersistentHandles() {
    return invokeRpc('_getPersistentHandles', {});
  }

  Future<List<Class>> getClassRefs() async {
    ServiceMap classList = await invokeRpc('getClassList', {});
    assert(classList.type == 'ClassList');
    var classRefs = [];
    for (var cls in classList['classes']) {
      // Skip over non-class classes.
      if (cls is Class) {
        _classesByCid[cls.vmCid] = cls;
        classRefs.add(cls);
      }
    }
    return classRefs;
  }

  /// Given the class list, loads each class.
  Future<List<Class>> _loadClasses(ServiceMap classList) {
    assert(classList.type == 'ClassList');
    var futureClasses = [];
    for (var cls in classList['classes']) {
      // Skip over non-class classes.
      if (cls is Class) {
        _classesByCid[cls.vmCid] = cls;
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
      if (cls.superclass == null) {
        rootClasses.add(cls);
      }
      if ((cls.vmName == 'Object') &&
          (cls.isPatch == false) &&
          (cls.library.uri == 'dart:core')) {
        objectClass = cls;
      }
    }
    assert(objectClass != null);
    return new Future.value(objectClass);
  }

  Class getClassByCid(int cid) => _classesByCid[cid];

  ServiceObject getFromMap(Map map) {
    if (map == null) {
      return null;
    }
    var mapType = _stripRef(map['type']);
    if (mapType == 'Isolate') {
      // There are sometimes isolate refs in ServiceEvents.
      return vm.getFromMap(map);
    }
    String mapId = map['id'];
    var obj = (mapId != null) ? _cache[mapId] : null;
    if (obj != null) {
      obj.update(map);
      return obj;
    }
    // Build the object from the map directly.
    obj = new ServiceObject._fromMap(this, map);
    if ((obj != null) && obj.canCache) {
      _cache[mapId] = obj;
    }
    return obj;
  }

  Future<Map> invokeRpcNoUpgrade(String method, Map params) {
    params['isolateId'] = id;
    return vm.invokeRpcNoUpgrade(method, params);
  }

  Future<dynamic> invokeRpc(String method, Map params) {
    return invokeRpcNoUpgrade(method, params).then((Map response) {
      return getFromMap(response);
    });
  }

  Future<ServiceObject> getObject(String objectId,
      {bool reload: true, int count: kDefaultFieldLimit}) {
    assert(objectId != null && objectId != '');
    var obj = _cache[objectId];
    if (obj != null) {
      if (reload) {
        return obj.reload(count: count);
      }
      // Returned cached object.
      return new Future.value(obj);
    }
    Map params = {
      'objectId': objectId,
      'count': count,
    };
    return isolate.invokeRpc('getObject', params);
  }

  Future<Map> _fetchDirect({int count: kDefaultFieldLimit}) async {
    return invokeRpcNoUpgrade('getIsolate', {});
  }

  Class objectClass;
  final rootClasses = <Class>[];
  Map<int, Class> _classesByCid = new Map<int, Class>();

  Library rootLibrary;
  List<Library> libraries = <Library>[];
  Frame topFrame;

  String name;
  String vmName;
  ServiceFunction entry;

  final HeapSpace newSpace = new HeapSpace();
  final HeapSpace oldSpace = new HeapSpace();

  String fileAndLine;

  DartError error;
  StreamController _snapshotFetch;

  List<ByteData> _chunksInProgress;

  List<Thread> get threads => _threads;
  final List<Thread> _threads = new List<Thread>();

  int get zoneHighWatermark => _zoneHighWatermark;
  int _zoneHighWatermark = 0;

  int get numZoneHandles => _numZoneHandles;
  int _numZoneHandles;

  int get numScopedHandles => _numScopedHandles;
  int _numScopedHandles;

  void _loadHeapSnapshot(ServiceEvent event) {
    if (_snapshotFetch == null || _snapshotFetch.isClosed) {
      // No outstanding snapshot request. Presumably another client asked for a
      // snapshot.
      Logger.root.info("Dropping unsolicited heap snapshot chunk");
      return;
    }

    // Occasionally these actually arrive out of order.
    var chunkIndex = event.chunkIndex;
    var chunkCount = event.chunkCount;
    if (_chunksInProgress == null) {
      _chunksInProgress = new List(chunkCount);
    }
    _chunksInProgress[chunkIndex] = event.data;
    _snapshotFetch.add([chunkIndex, chunkCount]);

    for (var i = 0; i < chunkCount; i++) {
      if (_chunksInProgress[i] == null) return;
    }

    var loadedChunks = _chunksInProgress;
    _chunksInProgress = null;

    if (_snapshotFetch != null) {
      _snapshotFetch.add(new RawHeapSnapshot(loadedChunks, event.nodeCount));
      _snapshotFetch.close();
    }
  }

  static String _rootsToString(M.HeapSnapshotRoots roots) {
    switch (roots) {
      case M.HeapSnapshotRoots.user:
        return "User";
      case M.HeapSnapshotRoots.vm:
        return "VM";
    }
    return null;
  }

  Stream fetchHeapSnapshot(M.HeapSnapshotRoots roots, bool collectGarbage) {
    if (_snapshotFetch == null || _snapshotFetch.isClosed) {
      _snapshotFetch = new StreamController.broadcast();
      // isolate.vm.streamListen('_Graph');
      isolate.invokeRpcNoUpgrade('_requestHeapSnapshot',
          {'roots': _rootsToString(roots), 'collectGarbage': collectGarbage});
    }
    return _snapshotFetch.stream;
  }

  void updateHeapsFromMap(Map map) {
    newSpace.update(map['new']);
    oldSpace.update(map['old']);
  }

  void _update(Map map, bool mapIsRef) {
    name = map['name'];
    vmName = map.containsKey('_vmName') ? map['_vmName'] : name;
    number = int.parse(map['number'], onError: (_) => null);
    if (mapIsRef) {
      return;
    }
    _loaded = true;
    loading = false;
    runnable = map['runnable'] == true;
    _upgradeCollection(map, isolate);
    originNumber = int.parse(map['_originNumber'], onError: (_) => null);
    rootLibrary = map['rootLib'];
    if (map['entry'] != null) {
      entry = map['entry'];
    }
    var savedStartTime = startTime;
    int startTimeInMillis = map['startTime'];
    startTime = new DateTime.fromMillisecondsSinceEpoch(startTimeInMillis);
    var countersMap = map['_tagCounters'];
    if (countersMap != null) {
      var names = countersMap['names'];
      var counts = countersMap['counters'];
      assert(names.length == counts.length);
      var sum = 0;
      for (var i = 0; i < counts.length; i++) {
        sum += counts[i];
      }
      var _counters = {};
      if (sum == 0) {
        for (var i = 0; i < names.length; i++) {
          _counters[names[i]] = '0.0%';
        }
      } else {
        for (var i = 0; i < names.length; i++) {
          _counters[names[i]] =
              (counts[i] / sum * 100.0).toStringAsFixed(2) + '%';
        }
      }
      counters = _counters;
    }

    updateHeapsFromMap(map['_heaps']);
    _updateBreakpoints(map['breakpoints']);
    if (map['_debuggerSettings'] != null) {
      exceptionsPauseInfo = map['_debuggerSettings']['_exceptions'];
    } else {
      exceptionsPauseInfo = "none";
    }

    var newPauseEvent = map['pauseEvent'];
    assert((pauseEvent == null) ||
        (newPauseEvent == null) ||
        !newPauseEvent.timestamp.isBefore(pauseEvent.timestamp));
    pauseEvent = createEventFromServiceEvent(newPauseEvent);
    _updateRunState();
    error = map['error'];

    libraries.clear();
    libraries.addAll(map['libraries']);
    libraries.sort(ServiceObject.LexicalSortName);
    if (savedStartTime == null) {
      vm._buildIsolateList();
    }

    extensionRPCs.clear();
    if (map['extensionRPCs'] != null) {
      extensionRPCs.addAll(map['extensionRPCs']);
    }

    threads.clear();
    if (map['_threads'] != null) {
      threads.addAll(map['_threads']);
    }

    int currentZoneHighWatermark = 0;
    for (var i = 0; i < threads.length; i++) {
      currentZoneHighWatermark += threads[i].zoneHighWatermark;
    }

    if (currentZoneHighWatermark > _zoneHighWatermark) {
      _zoneHighWatermark = currentZoneHighWatermark;
    }

    _numZoneHandles = map['_numZoneHandles'];
    _numScopedHandles = map['_numScopedHandles'];
  }

  Future<TagProfile> updateTagProfile() {
    return isolate.invokeRpcNoUpgrade('_getTagProfile', {}).then((Map map) {
      var seconds = new DateTime.now().millisecondsSinceEpoch / 1000.0;
      tagProfile._processTagProfile(seconds, map);
      return tagProfile;
    });
  }

  Map<int, Breakpoint> breakpoints = <int, Breakpoint>{};
  String exceptionsPauseInfo;

  void _updateBreakpoints(List newBpts) {
    // Build a set of new breakpoints.
    var newBptSet = new Set();
    newBpts.forEach((bpt) => newBptSet.add(bpt.number));

    // Remove any old breakpoints which no longer exist.
    List toRemove = [];
    breakpoints.forEach((key, _) {
      if (!newBptSet.contains(key)) {
        toRemove.add(key);
      }
    });
    toRemove.forEach((key) => breakpoints.remove(key));

    // Add all new breakpoints.
    newBpts.forEach((bpt) => (breakpoints[bpt.number] = bpt));
  }

  void _addBreakpoint(Breakpoint bpt) {
    breakpoints[bpt.number] = bpt;
  }

  void _removeBreakpoint(Breakpoint bpt) {
    breakpoints.remove(bpt.number);
    bpt.remove();
  }

  void _onEvent(ServiceEvent event) {
    switch (event.kind) {
      case ServiceEvent.kIsolateStart:
      case ServiceEvent.kIsolateRunnable:
      case ServiceEvent.kIsolateExit:
      case ServiceEvent.kInspect:
        // Handled elsewhere.
        break;
      case ServiceEvent.kIsolateReload:
        _handleIsolateReloadEvent(event);
        break;
      case ServiceEvent.kBreakpointAdded:
        _addBreakpoint(event.breakpoint);
        break;

      case ServiceEvent.kIsolateUpdate:
      case ServiceEvent.kBreakpointResolved:
      case ServiceEvent.kDebuggerSettingsUpdate:
        // Update occurs as side-effect of caching.
        break;

      case ServiceEvent.kBreakpointRemoved:
        _removeBreakpoint(event.breakpoint);
        break;

      case ServiceEvent.kPauseStart:
      case ServiceEvent.kPauseExit:
      case ServiceEvent.kPauseBreakpoint:
      case ServiceEvent.kPauseInterrupted:
      case ServiceEvent.kPauseException:
      case ServiceEvent.kPausePostRequest:
      case ServiceEvent.kNone:
      case ServiceEvent.kResume:
        assert((pauseEvent == null) ||
            !event.timestamp.isBefore(pauseEvent.timestamp));
        pauseEvent = createEventFromServiceEvent(event);
        _updateRunState();
        break;

      case ServiceEvent.kGraph:
        _loadHeapSnapshot(event);
        break;

      case ServiceEvent.kGC:
        // Ignore GC events for now.
        break;

      default:
        // Log unexpected events.
        Logger.root.severe('Unexpected event: $event');
        break;
    }
  }

  Future<ServiceObject> addBreakpoint(Script script, int line, [int col]) {
    Map params = {
      'scriptId': script.id,
      'line': line,
    };
    if (col != null) {
      params['column'] = col;
    }
    return invokeRpc('addBreakpoint', params);
  }

  Future<ServiceObject> addBreakpointByScriptUri(String uri, int line,
      [int col]) {
    Map params = {
      'scriptUri': uri,
      'line': line.toString(),
    };
    if (col != null) {
      params['column'] = col.toString();
    }
    return invokeRpc('addBreakpointWithScriptUri', params);
  }

  Future<ServiceObject> addBreakpointAtEntry(ServiceFunction function) {
    return invokeRpc('addBreakpointAtEntry', {'functionId': function.id});
  }

  Future<ServiceObject> addBreakOnActivation(Instance closure) {
    return invokeRpc('_addBreakpointAtActivation', {'objectId': closure.id});
  }

  Future removeBreakpoint(Breakpoint bpt) {
    return invokeRpc('removeBreakpoint', {'breakpointId': bpt.id});
  }

  Future pause() {
    return invokeRpc('pause', {});
  }

  Future resume() {
    return invokeRpc('resume', {});
  }

  Future stepInto() {
    return invokeRpc('resume', {'step': 'Into'});
  }

  Future stepOver() {
    return invokeRpc('resume', {'step': 'Over'});
  }

  Future stepOverAsyncSuspension() {
    return invokeRpc('resume', {'step': 'OverAsyncSuspension'});
  }

  Future stepOut() {
    return invokeRpc('resume', {'step': 'Out'});
  }

  Future rewind(int count) {
    return invokeRpc('resume', {'step': 'Rewind', 'frameIndex': count});
  }

  Future setName(String newName) {
    return invokeRpc('setName', {'name': newName});
  }

  Future setExceptionPauseMode(String mode) {
    return invokeRpc('setExceptionPauseMode', {'mode': mode});
  }

  Future<ServiceMap> getStack() {
    return invokeRpc('getStack', {});
  }

  Future<ObjectStore> getObjectStore() {
    return invokeRpcNoUpgrade('_getObjectStore', {}).then((map) {
      ObjectStore objectStore = new ObjectStore._empty(this);
      objectStore._update(map, false);
      return objectStore;
    });
  }

  Future<ServiceObject> eval(ServiceObject target, String expression,
      {Map<String, ServiceObject> scope}) {
    Map params = {
      'targetId': target.id,
      'expression': expression,
    };
    if (scope != null) {
      Map<String, String> scopeWithIds = new Map();
      scope.forEach((String name, ServiceObject object) {
        scopeWithIds[name] = object.id;
      });
      params["scope"] = scopeWithIds;
    }
    return invokeRpc('evaluate', params);
  }

  Future<ServiceObject> evalFrame(int frameIndex, String expression,
      {Map<String, ServiceObject> scope}) {
    Map params = {
      'frameIndex': frameIndex,
      'expression': expression,
    };
    if (scope != null) {
      Map<String, String> scopeWithIds = new Map();
      scope.forEach((String name, ServiceObject object) {
        scopeWithIds[name] = object.id;
      });
      params["scope"] = scopeWithIds;
    }
    return invokeRpc('evaluateInFrame', params);
  }

  Future<ServiceObject> getReachableSize(ServiceObject target) {
    Map params = {
      'targetId': target.id,
    };
    return invokeRpc('_getReachableSize', params);
  }

  Future<ServiceObject> getRetainedSize(ServiceObject target) {
    Map params = {
      'targetId': target.id,
    };
    return invokeRpc('_getRetainedSize', params);
  }

  Future<ServiceObject> getRetainingPath(ServiceObject target, var limit) {
    Map params = {
      'targetId': target.id,
      'limit': limit.toString(),
    };
    return invokeRpc('_getRetainingPath', params);
  }

  Future<ServiceObject> getInboundReferences(ServiceObject target, var limit) {
    Map params = {
      'targetId': target.id,
      'limit': limit.toString(),
    };
    return invokeRpc('_getInboundReferences', params);
  }

  Future<ServiceObject> getTypeArgumentsList(bool onlyWithInstantiations) {
    Map params = {
      'onlyWithInstantiations': onlyWithInstantiations,
    };
    return invokeRpc('_getTypeArgumentsList', params);
  }

  Future<ServiceObject> getInstances(Class cls, var limit) {
    Map params = {
      'classId': cls.id,
      'limit': limit.toString(),
    };
    return invokeRpc('_getInstances', params);
  }

  Future<ServiceObject> getObjectByAddress(String address, [bool ref = true]) {
    Map params = {
      'address': address,
      'ref': ref,
    };
    return invokeRpc('_getObjectByAddress', params);
  }

  final Map<String, ServiceMetric> dartMetrics = <String, ServiceMetric>{};

  final Map<String, ServiceMetric> nativeMetrics = <String, ServiceMetric>{};

  Future<Map<String, ServiceMetric>> _refreshMetrics(
      String metricType, Map<String, ServiceMetric> metricsMap) {
    return invokeRpc('_getIsolateMetricList', {'type': metricType})
        .then((result) {
      // Clear metrics map.
      metricsMap.clear();
      // Repopulate metrics map.
      var metrics = result['metrics'];
      for (var metric in metrics) {
        metricsMap[metric.id] = metric;
      }
      return metricsMap;
    });
  }

  Future<Map<String, ServiceMetric>> refreshDartMetrics() {
    return _refreshMetrics('Dart', dartMetrics);
  }

  Future<Map<String, ServiceMetric>> refreshNativeMetrics() {
    return _refreshMetrics('Native', nativeMetrics);
  }

  Future refreshMetrics() {
    return Future.wait([refreshDartMetrics(), refreshNativeMetrics()]);
  }

  String toString() => "Isolate($name)";
}

class NamedField implements M.NamedField {
  final String name;
  final M.ObjectRef value;
  NamedField(this.name, this.value);
}

class ObjectStore extends ServiceObject implements M.ObjectStore {
  List<NamedField> fields = new List<NamedField>();

  ObjectStore._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    // Extract full properties.
    _upgradeCollection(map, isolate);

    if (mapIsRef) {
      return;
    }

    fields.clear();
    map['fields'].forEach((key, value) {
      fields.add(new NamedField(key, value));
    });
    _loaded = true;
  }
}

/// A [ServiceObject] which implements [Map].
class ServiceMap extends ServiceObject implements Map, M.UnknownObjectRef {
  final Map _map = {};
  static String objectIdRingPrefix = 'objects/';

  bool get immutable => false;

  ServiceMap._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _loaded = !mapIsRef;

    _upgradeCollection(map, owner);
    // TODO(turnidge): Currently _map.clear() prevents us from
    // upgrading an already upgraded submap.  Is clearing really the
    // right thing to do here?
    _map.clear();
    _map.addAll(map);

    name = _map['name'];
    vmName = (_map.containsKey('_vmName') ? _map['_vmName'] : name);
  }

  // TODO(turnidge): These are temporary until we have a proper root
  // object for all dart heap objects.
  int get size => _map['size'];
  int get clazz => _map['class'];

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

  String toString() => "ServiceMap($_map)";
}

M.ErrorKind stringToErrorKind(String value) {
  switch (value) {
    case 'UnhandledException':
      return M.ErrorKind.unhandledException;
    case 'LanguageError':
      return M.ErrorKind.unhandledException;
    case 'InternalError':
      return M.ErrorKind.internalError;
    case 'TerminationError':
      return M.ErrorKind.terminationError;
  }
  Logger.root.severe('Unrecognized error kind: $value');
  throw new FallThroughError();
}

/// A [DartError] is peered to a Dart Error object.
class DartError extends ServiceObject implements M.Error {
  DartError._empty(ServiceObject owner) : super._empty(owner);

  M.ErrorKind kind;
  final M.ClassRef clazz = null;
  final int size = null;
  String message;
  Instance exception;
  Instance stacktrace;

  void _update(Map map, bool mapIsRef) {
    message = map['message'];
    kind = stringToErrorKind(map['kind']);
    exception = new ServiceObject._fromMap(owner, map['exception']);
    stacktrace = new ServiceObject._fromMap(owner, map['stacktrace']);
    name = 'DartError($message)';
    vmName = name;
  }

  String toString() => 'DartError($message)';
}

Level _findLogLevel(int value) {
  for (var level in Level.LEVELS) {
    if (level.value == value) {
      return level;
    }
  }
  return new Level('$value', value);
}

/// A [ServiceEvent] is an asynchronous event notification from the vm.
class ServiceEvent extends ServiceObject {
  /// The possible 'kind' values.
  static const kVMUpdate = 'VMUpdate';
  static const kIsolateStart = 'IsolateStart';
  static const kIsolateRunnable = 'IsolateRunnable';
  static const kIsolateExit = 'IsolateExit';
  static const kIsolateUpdate = 'IsolateUpdate';
  static const kIsolateReload = 'IsolateReload';
  static const kIsolateSpawn = 'IsolateSpawn';
  static const kServiceExtensionAdded = 'ServiceExtensionAdded';
  static const kPauseStart = 'PauseStart';
  static const kPauseExit = 'PauseExit';
  static const kPauseBreakpoint = 'PauseBreakpoint';
  static const kPauseInterrupted = 'PauseInterrupted';
  static const kPauseException = 'PauseException';
  static const kPausePostRequest = 'PausePostRequest';
  static const kNone = 'None';
  static const kResume = 'Resume';
  static const kBreakpointAdded = 'BreakpointAdded';
  static const kBreakpointResolved = 'BreakpointResolved';
  static const kBreakpointRemoved = 'BreakpointRemoved';
  static const kGraph = '_Graph';
  static const kGC = 'GC';
  static const kInspect = 'Inspect';
  static const kDebuggerSettingsUpdate = '_DebuggerSettingsUpdate';
  static const kConnectionClosed = 'ConnectionClosed';
  static const kLogging = '_Logging';
  static const kExtension = 'Extension';
  static const kServiceRegistered = 'ServiceRegistered';
  static const kServiceUnregistered = 'ServiceUnregistered';

  ServiceEvent._empty(ServiceObjectOwner owner) : super._empty(owner);

  ServiceEvent.connectionClosed(this.reason) : super._empty(null) {
    kind = kConnectionClosed;
  }

  String kind;
  DateTime timestamp;
  List<M.Breakpoint> pauseBreakpoints;
  Breakpoint breakpoint;
  Frame topFrame;
  DartError error;
  String extensionRPC;
  Instance exception;
  DartError reloadError;
  bool atAsyncSuspension;
  Instance inspectee;
  ByteData data;
  int count;
  String reason;
  String exceptions;
  String bytesAsString;
  Map logRecord;
  String extensionKind;
  Map extensionData;
  List timelineEvents;
  String spawnToken;
  String spawnError;
  String editor;
  ServiceObject object;
  String method;
  String service;
  String alias;

  int chunkIndex, chunkCount, nodeCount;

  bool get isPauseEvent {
    return (kind == kPauseStart ||
        kind == kPauseExit ||
        kind == kPauseBreakpoint ||
        kind == kPauseInterrupted ||
        kind == kPauseException ||
        kind == kPausePostRequest ||
        kind == kNone);
  }

  void _update(Map map, bool mapIsRef) {
    _loaded = true;
    _upgradeCollection(map, owner);

    assert(map['isolate'] == null || owner == map['isolate']);
    timestamp = new DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
    kind = map['kind'];
    name = 'ServiceEvent $kind';
    vmName = name;
    if (map['breakpoint'] != null) {
      breakpoint = map['breakpoint'];
    }
    if (map['pauseBreakpoints'] != null) {
      pauseBreakpoints = map['pauseBreakpoints'];
      if (pauseBreakpoints.length > 0) {
        breakpoint = pauseBreakpoints[0];
      }
    } else {
      pauseBreakpoints = const [];
    }
    if (map['error'] != null) {
      error = map['error'];
    }
    if (map['extensionRPC'] != null) {
      extensionRPC = map['extensionRPC'];
    }
    topFrame = map['topFrame'];
    if (map['exception'] != null) {
      exception = map['exception'];
    }
    atAsyncSuspension = map['atAsyncSuspension'] != null;
    if (map['inspectee'] != null) {
      inspectee = map['inspectee'];
    }
    if (map['_data'] != null) {
      data = map['_data'];
    }
    if (map['chunkIndex'] != null) {
      chunkIndex = map['chunkIndex'];
    }
    if (map['chunkCount'] != null) {
      chunkCount = map['chunkCount'];
    }
    if (map['nodeCount'] != null) {
      nodeCount = map['nodeCount'];
    }
    if (map['count'] != null) {
      count = map['count'];
    }
    reloadError = map['reloadError'];
    if (map['_debuggerSettings'] != null &&
        map['_debuggerSettings']['_exceptions'] != null) {
      exceptions = map['_debuggerSettings']['_exceptions'];
    }
    if (map['bytes'] != null) {
      var bytes = BASE64.decode(map['bytes']);
      bytesAsString = UTF8.decode(bytes);
    }
    if (map['logRecord'] != null) {
      logRecord = map['logRecord'];
      logRecord['time'] =
          new DateTime.fromMillisecondsSinceEpoch(logRecord['time']);
      logRecord['level'] = _findLogLevel(logRecord['level']);
    }
    if (map['extensionKind'] != null) {
      extensionKind = map['extensionKind'];
      extensionData = map['extensionData'];
    }
    if (map['timelineEvents'] != null) {
      timelineEvents = map['timelineEvents'];
    }
    if (map['spawnToken'] != null) {
      spawnToken = map['spawnToken'];
    }
    if (map['spawnError'] != null) {
      spawnError = map['spawnError'];
    }
    if (map['editor'] != null) {
      editor = map['editor'];
    }
    if (map['object'] != null) {
      object = map['object'];
    }
    if (map['service'] != null) {
      service = map['service'];
    }
    if (map['method'] != null) {
      method = map['method'];
    }
    if (map['alias'] != null) {
      alias = map['alias'];
    }
  }

  String toString() {
    var ownerName = owner.id != null ? owner.id.toString() : owner.name;
    if (data == null) {
      return "ServiceEvent(owner='${ownerName}', kind='${kind}', "
          "time=${timestamp})";
    } else {
      return "ServiceEvent(owner='${ownerName}', kind='${kind}', "
          "data.lengthInBytes=${data.lengthInBytes}, time=${timestamp})";
    }
  }
}

class Breakpoint extends ServiceObject implements M.Breakpoint {
  Breakpoint._empty(ServiceObjectOwner owner) : super._empty(owner);

  final M.ClassRef clazz = null;
  final int size = null;

  // TODO(turnidge): Add state to track if a breakpoint has been
  // removed from the program.  Remove from the cache when deleted.
  bool get immutable => false;

  // A unique integer identifier for this breakpoint.
  int number;

  // Either SourceLocation or UnresolvedSourceLocation.
  Location location;

  // The breakpoint is in a file which is not yet loaded.
  bool latent;

  // The breakpoint has been assigned to a final source location.
  bool resolved;

  // The breakpoint was synthetically created as part of an
  // 'OverAsyncContinuation' resume request.
  bool isSyntheticAsyncContinuation;

  void _update(Map map, bool mapIsRef) {
    _loaded = true;
    _upgradeCollection(map, owner);

    var newNumber = map['breakpointNumber'];
    // number never changes.
    assert((number == null) || (number == newNumber));
    number = newNumber;
    resolved = map['resolved'];

    var oldLocation = location;
    var newLocation = map['location'];
    if (oldLocation is UnresolvedSourceLocation &&
        newLocation is SourceLocation) {
      // Breakpoint has been resolved.  Remove old breakpoint.
      var oldScript = oldLocation.script;
      if (oldScript != null && oldScript.loaded) {
        oldScript._removeBreakpoint(this);
      }
    }
    location = newLocation;
    var newScript = location.script;
    if (newScript != null && newScript.loaded) {
      newScript._addBreakpoint(this);
    }

    isSyntheticAsyncContinuation = map['isSyntheticAsyncContinuation'] != null;

    assert(resolved || location is UnresolvedSourceLocation);
  }

  void remove() {
    location.script._removeBreakpoint(this);
  }

  String toString() {
    if (number != null) {
      if (isSyntheticAsyncContinuation) {
        return 'Synthetic Async Continuation Breakpoint ${number}';
      } else {
        return 'Breakpoint ${number} at ${location}';
      }
    } else {
      return 'Uninitialized breakpoint';
    }
  }
}

class LibraryDependency implements M.LibraryDependency {
  final bool isImport;
  final bool isDeferred;
  final String prefix;
  final Library target;

  bool get isExport => !isImport;

  LibraryDependency._(this.isImport, this.isDeferred, this.prefix, this.target);

  static _fromMap(map) => new LibraryDependency._(
      map["isImport"], map["isDeferred"], map["prefix"], map["target"]);
}

class Library extends HeapObject implements M.Library {
  String uri;
  final dependencies = <LibraryDependency>[];
  final scripts = <Script>[];
  final classes = <Class>[];
  final variables = <Field>[];
  final functions = <ServiceFunction>[];
  bool _debuggable;
  bool get debuggable => _debuggable;
  bool get immutable => false;

  bool isDart(String libraryName) {
    return uri == 'dart:$libraryName';
  }

  Library._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    uri = map['uri'];
    var shortUri = uri;
    if (uri.startsWith('file://') || uri.startsWith('http://')) {
      shortUri = uri.substring(uri.lastIndexOf('/') + 1);
    }
    name = map['name'];
    if (name.isEmpty) {
      // When there is no name for a library, use the shortUri.
      name = shortUri;
    }
    vmName = (map.containsKey('_vmName') ? map['_vmName'] : name);
    if (mapIsRef) {
      return;
    }
    _loaded = true;
    _debuggable = map['debuggable'];
    dependencies.clear();
    dependencies.addAll(map["dependencies"].map(LibraryDependency._fromMap));
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

  Future<ServiceObject> evaluate(String expression, {Map scope}) {
    return isolate.eval(this, expression, scope: scope);
  }

  Script get rootScript {
    for (Script script in scripts) {
      if (script.uri == uri) return script;
    }
    return null;
  }

  String toString() => "Library($uri)";
}

class AllocationCount implements M.AllocationCount {
  int instances = 0;
  int bytes = 0;

  void reset() {
    instances = 0;
    bytes = 0;
  }

  bool get empty => (instances == 0) && (bytes == 0);
  bool get notEmpty => (instances != 0) || (bytes != 0);
}

class Allocations implements M.Allocations {
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
  bool get notEmpty => accumulated.notEmpty || current.notEmpty;
}

class Class extends HeapObject implements M.Class {
  Library library;

  bool isAbstract;
  bool isConst;
  bool isFinalized;
  bool isPatch;
  bool isImplemented;

  SourceLocation location;

  DartError error;
  int vmCid;

  final Allocations newSpace = new Allocations();
  final Allocations oldSpace = new Allocations();
  final AllocationCount promotedByLastNewGC = new AllocationCount();

  bool get hasAllocations => newSpace.notEmpty || oldSpace.notEmpty;
  bool get hasNoAllocations => newSpace.empty && oldSpace.empty;
  bool traceAllocations = false;
  final fields = <Field>[];
  final functions = <ServiceFunction>[];

  Class superclass;
  final interfaces = <Instance>[];
  final subclasses = <Class>[];

  Instance superType;
  Instance mixin;

  bool get immutable => false;

  Class._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    name = map['name'];
    vmName = (map.containsKey('_vmName') ? map['_vmName'] : name);
    if (vmName == '::') {
      name = 'top-level-class'; // Better than ''
    }
    var idPrefix = "classes/";
    assert(id.startsWith(idPrefix));
    vmCid = int.parse(id.substring(idPrefix.length));

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

    location = map['location'];
    isAbstract = map['abstract'];
    isConst = map['const'];
    isFinalized = map['_finalized'];
    isPatch = map['_patch'];
    isImplemented = map['_implemented'];

    subclasses.clear();
    subclasses.addAll(map['subclasses']);
    subclasses.sort(ServiceObject.LexicalSortName);

    interfaces.clear();
    interfaces.addAll(map['interfaces']);
    interfaces.sort(ServiceObject.LexicalSortName);

    fields.clear();
    fields.addAll(map['fields']);
    fields.sort(ServiceObject.LexicalSortName);

    functions.clear();
    functions.addAll(map['functions']);
    functions.sort(ServiceObject.LexicalSortName);

    superclass = map['super'];
    // Work-around Object not tracking its subclasses in the VM.
    if (superclass != null && superclass.name == "Object") {
      superclass._addSubclass(this);
    }
    superType = map['superType'];
    mixin = map['mixin'];

    error = map['error'];

    traceAllocations =
        (map['_traceAllocations'] != null) ? map['_traceAllocations'] : false;

    var allocationStats = map['_allocationStats'];
    if (allocationStats != null) {
      newSpace.update(allocationStats['new']);
      oldSpace.update(allocationStats['old']);
      promotedByLastNewGC.instances = allocationStats['promotedInstances'];
      promotedByLastNewGC.bytes = allocationStats['promotedBytes'];
    }
  }

  void _addSubclass(Class subclass) {
    if (subclasses.contains(subclass)) {
      return;
    }
    subclasses.add(subclass);
    subclasses.sort(ServiceObject.LexicalSortName);
  }

  Future<ServiceObject> evaluate(String expression, {Map scope}) {
    return isolate.eval(this, expression, scope: scope);
  }

  Future<ServiceObject> setTraceAllocations(bool enable) {
    return isolate.invokeRpc('_setTraceClassAllocation', {
      'enable': enable,
      'classId': id,
    });
  }

  Future<ServiceObject> getAllocationSamples([String tags = 'None']) {
    var params = {'tags': tags, 'classId': id};
    return isolate.invokeRpc('_getAllocationSamples', params);
  }

  String toString() => 'Class($vmName)';
}

M.InstanceKind stringToInstanceKind(String s) {
  switch (s) {
    case 'PlainInstance':
      return M.InstanceKind.plainInstance;
    case 'Null':
      return M.InstanceKind.vNull;
    case 'Bool':
      return M.InstanceKind.bool;
    case 'Double':
      return M.InstanceKind.double;
    case 'Int':
      return M.InstanceKind.int;
    case 'String':
      return M.InstanceKind.string;
    case 'List':
      return M.InstanceKind.list;
    case 'Map':
      return M.InstanceKind.map;
    case 'Float32x4':
      return M.InstanceKind.float32x4;
    case 'Float64x2':
      return M.InstanceKind.float64x2;
    case 'Int32x4':
      return M.InstanceKind.int32x4;
    case 'Uint8ClampedList':
      return M.InstanceKind.uint8ClampedList;
    case 'Uint8List':
      return M.InstanceKind.uint8List;
    case 'Uint16List':
      return M.InstanceKind.uint16List;
    case 'Uint32List':
      return M.InstanceKind.uint32List;
    case 'Uint64List':
      return M.InstanceKind.uint64List;
    case 'Int8List':
      return M.InstanceKind.int8List;
    case 'Int16List':
      return M.InstanceKind.int16List;
    case 'Int32List':
      return M.InstanceKind.int32List;
    case 'Int64List':
      return M.InstanceKind.int64List;
    case 'Float32List':
      return M.InstanceKind.float32List;
    case 'Float64List':
      return M.InstanceKind.float64List;
    case 'Int32x4List':
      return M.InstanceKind.int32x4List;
    case 'Float32x4List':
      return M.InstanceKind.float32x4List;
    case 'Float64x2List':
      return M.InstanceKind.float64x2List;
    case 'StackTrace':
      return M.InstanceKind.stackTrace;
    case 'Closure':
      return M.InstanceKind.closure;
    case 'MirrorReference':
      return M.InstanceKind.mirrorReference;
    case 'RegExp':
      return M.InstanceKind.regExp;
    case 'WeakProperty':
      return M.InstanceKind.weakProperty;
    case 'Type':
      return M.InstanceKind.type;
    case 'TypeParameter':
      return M.InstanceKind.typeParameter;
    case 'TypeRef':
      return M.InstanceKind.typeRef;
    case 'BoundedType':
      return M.InstanceKind.boundedType;
  }
  Logger.root.severe("Unrecognized InstanceKind: '$s'");
  throw new FallThroughError();
}

class Guarded<T> implements M.Guarded<T> {
  bool get isValue => asValue != null;
  bool get isSentinel => asSentinel != null;
  final Sentinel asSentinel;
  final T asValue;

  factory Guarded(ServiceObject obj) {
    if (obj is Sentinel) {
      return new Guarded.fromSentinel(obj);
    } else if (obj is T) {
      return new Guarded.fromValue(obj);
    }
    throw new Exception('${obj.type} is neither Sentinel or $T');
  }

  Guarded.fromSentinel(this.asSentinel) : asValue = null;
  Guarded.fromValue(this.asValue) : asSentinel = null;
}

class BoundField implements M.BoundField {
  final Field decl;
  final Guarded<Instance> value;
  BoundField(this.decl, value) : value = new Guarded(value);
}

class NativeField implements M.NativeField {
  final int value;
  NativeField(this.value);
}

class MapAssociation implements M.MapAssociation {
  final Guarded<Instance> key;
  final Guarded<Instance> value;
  MapAssociation(key, value)
      : key = new Guarded(key),
        value = new Guarded(value);
}

class Instance extends HeapObject implements M.Instance {
  M.InstanceKind kind;
  String valueAsString; // If primitive.
  bool valueAsStringIsTruncated;
  ServiceFunction closureFunction; // If a closure.
  Context closureContext; // If a closure.
  int length; // If a List, Map or TypedData.
  int count;
  int offset;
  Instance pattern; // If a RegExp.

  String name;
  Class typeClass;
  Class parameterizedClass;
  TypeArguments typeArguments;
  int parameterIndex;
  Instance targetType;
  Instance bound;

  Iterable<BoundField> fields;
  var nativeFields;
  Iterable<Guarded<HeapObject>> elements; // If a List.
  Iterable<MapAssociation> associations; // If a Map.
  Iterable<dynamic> typedElements; // If a TypedData.
  HeapObject referent; // If a MirrorReference.
  Instance key; // If a WeakProperty.
  Instance value; // If a WeakProperty.
  Breakpoint activationBreakpoint; // If a Closure.
  ServiceFunction oneByteFunction; // If a RegExp.
  ServiceFunction twoByteFunction; // If a RegExp.
  ServiceFunction externalOneByteFunction; // If a RegExp.
  ServiceFunction externalTwoByteFunction; // If a RegExp.
  Instance oneByteBytecode; // If a RegExp.
  Instance twoByteBytecode; // If a RegExp.
  bool isCaseSensitive; // If a RegExp.
  bool isMultiLine; // If a RegExp.

  bool get isAbstractType => M.isAbstractType(kind);
  bool get isNull => kind == M.InstanceKind.vNull;
  bool get isBool => kind == M.InstanceKind.bool;
  bool get isDouble => kind == M.InstanceKind.double;
  bool get isString => kind == M.InstanceKind.string;
  bool get isInt => kind == M.InstanceKind.int;
  bool get isList => kind == M.InstanceKind.list;
  bool get isMap => kind == M.InstanceKind.map;
  bool get isTypedData {
    return M.isTypedData(kind);
  }

  bool get isSimdValue {
    return M.isSimdValue(kind);
  }

  bool get isRegExp => kind == M.InstanceKind.regExp;
  bool get isMirrorReference => kind == M.InstanceKind.mirrorReference;
  bool get isWeakProperty => kind == M.InstanceKind.weakProperty;
  bool get isClosure => kind == M.InstanceKind.closure;
  bool get isStackTrace => kind == M.InstanceKind.stackTrace;
  bool get isStackOverflowError {
    if (clazz == null) {
      return false;
    }
    if (clazz.library == null) {
      return false;
    }
    return (clazz.name == 'StackOverflowError') && clazz.library.isDart('core');
  }

  bool get isOutOfMemoryError {
    if (clazz == null) {
      return false;
    }
    if (clazz.library == null) {
      return false;
    }
    return (clazz.name == 'OutOfMemoryError') && clazz.library.isDart('core');
  }

  // TODO(turnidge): Is this properly backwards compatible when new
  // instance kinds are added?
  bool get isPlainInstance => kind == 'PlainInstance';

  Instance._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    // Extract full properties.1
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    kind = stringToInstanceKind(map['kind']);
    valueAsString = map['valueAsString'];
    // Coerce absence to false.
    valueAsStringIsTruncated = map['valueAsStringIsTruncated'] == true;
    closureFunction = map['closureFunction'];
    closureContext = map['closureContext'];
    name = map['name'];
    length = map['length'];
    pattern = map['pattern'];
    typeClass = map['typeClass'];

    if (mapIsRef) {
      return;
    }

    count = map['count'];
    offset = map['offset'];
    isCaseSensitive = map['isCaseSensitive'];
    isMultiLine = map['isMultiLine'];
    bool isCompiled = map['_oneByteFunction'] is ServiceFunction;
    oneByteFunction = isCompiled ? map['_oneByteFunction'] : null;
    twoByteFunction = isCompiled ? map['_twoByteFunction'] : null;
    externalOneByteFunction =
        isCompiled ? map['_externalOneByteFunction'] : null;
    externalTwoByteFunction =
        isCompiled ? map['_externalTwoByteFunction'] : null;
    oneByteBytecode = map['_oneByteBytecode'];
    twoByteBytecode = map['_twoByteBytecode'];

    if (map['fields'] != null) {
      fields = map['fields']
          .map((f) => new BoundField(f['decl'], f['value']))
          .toList();
    } else {
      fields = null;
    }
    if (map['_nativeFields'] != null) {
      nativeFields =
          map['_nativeFields'].map((f) => new NativeField(f['value'])).toList();
    } else {
      nativeFields = null;
    }
    if (map['elements'] != null) {
      // Should be:
      // elements = map['elements'].map((e) => new Guarded<Instance>(e)).toList();
      // some times we obtain object that are not InstanceRef
      elements =
          map['elements'].map((e) => new Guarded<ServiceObject>(e)).toList();
    } else {
      elements = null;
    }
    if (map['associations'] != null) {
      associations = map['associations']
          .map((a) => new MapAssociation(a['key'], a['value']))
          .toList();
    } else {
      associations = null;
    }
    ;
    if (map['bytes'] != null) {
      Uint8List bytes = BASE64.decode(map['bytes']);
      switch (map['kind']) {
        case "Uint8ClampedList":
          typedElements = bytes.buffer.asUint8ClampedList();
          break;
        case "Uint8List":
          typedElements = bytes.buffer.asUint8List();
          break;
        case "Uint16List":
          typedElements = bytes.buffer.asUint16List();
          break;
        case "Uint32List":
          typedElements = bytes.buffer.asUint32List();
          break;
        case "Uint64List":
          typedElements = bytes.buffer.asUint64List();
          break;
        case "Int8List":
          typedElements = bytes.buffer.asInt8List();
          break;
        case "Int16List":
          typedElements = bytes.buffer.asInt16List();
          break;
        case "Int32List":
          typedElements = bytes.buffer.asInt32List();
          break;
        case "Int64List":
          typedElements = bytes.buffer.asInt64List();
          break;
        case "Float32List":
          typedElements = bytes.buffer.asFloat32List();
          break;
        case "Float64List":
          typedElements = bytes.buffer.asFloat64List();
          break;
        case "Int32x4List":
          typedElements = bytes.buffer.asInt32x4List();
          break;
        case "Float32x4List":
          typedElements = bytes.buffer.asFloat32x4List();
          break;
        case "Float64x2List":
          typedElements = bytes.buffer.asFloat64x2List();
          break;
      }
    } else {
      typedElements = null;
    }
    parameterizedClass = map['parameterizedClass'];
    typeArguments = map['typeArguments'];
    parameterIndex = map['parameterIndex'];
    targetType = map['targetType'];
    bound = map['bound'];

    referent = map['mirrorReferent'];
    key = map['propertyKey'];
    value = map['propertyValue'];
    activationBreakpoint = map['_activationBreakpoint'];

    // We are fully loaded.
    _loaded = true;
  }

  String get shortName {
    if (isClosure) {
      return closureFunction.qualifiedName;
    }
    if (valueAsString != null) {
      return valueAsString;
    }
    return 'a ${clazz.name}';
  }

  Future<ServiceObject> evaluate(String expression, {Map scope}) {
    return isolate.eval(this, expression, scope: scope);
  }

  String toString() => 'Instance($shortName)';
}

class Context extends HeapObject implements M.Context {
  Context parentContext;
  int length;
  Iterable<ContextElement> variables;

  Context._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    // Extract full properties.
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    length = map['length'];
    parentContext = map['parent'];

    if (mapIsRef) {
      return;
    }

    variables = (map['variables'] ?? const [])
        .map((element) => new ContextElement(element));

    // We are fully loaded.
    _loaded = true;
  }

  String toString() => 'Context($length)';
}

class ContextElement extends M.ContextElement {
  final Guarded<Instance> value;

  ContextElement(Map map) : value = new Guarded<Instance>(map['value']);
}

M.FunctionKind stringToFunctionKind(String value) {
  switch (value) {
    case 'RegularFunction':
      return M.FunctionKind.regular;
    case 'ClosureFunction':
      return M.FunctionKind.closure;
    case 'ImplicitClosureFunction':
      return M.FunctionKind.implicitClosure;
    case 'GetterFunction':
      return M.FunctionKind.getter;
    case 'SetterFunction':
      return M.FunctionKind.setter;
    case 'Constructor':
      return M.FunctionKind.constructor;
    case 'ImplicitGetter':
      return M.FunctionKind.implicitGetter;
    case 'ImplicitSetter':
      return M.FunctionKind.implicitSetter;
    case 'ImplicitStaticFinalGetter':
      return M.FunctionKind.implicitStaticFinalGetter;
    case 'IrregexpFunction':
      return M.FunctionKind.irregexpFunction;
    case 'StaticInitializer':
      return M.FunctionKind.staticInitializer;
    case 'MethodExtractor':
      return M.FunctionKind.methodExtractor;
    case 'NoSuchMethodDispatcher':
      return M.FunctionKind.noSuchMethodDispatcher;
    case 'InvokeFieldDispatcher':
      return M.FunctionKind.invokeFieldDispatcher;
    case 'Collected':
      return M.FunctionKind.collected;
    case 'Native':
      return M.FunctionKind.native;
    case 'Stub':
      return M.FunctionKind.stub;
    case 'Tag':
      return M.FunctionKind.tag;
    case 'SignatureFunction':
      return M.FunctionKind.signatureFunction;
  }
  Logger.root.severe('Unrecognized function kind: $value');
  throw new FallThroughError();
}

class ServiceFunction extends HeapObject implements M.Function {
  // owner is a Library, Class, or ServiceFunction.
  M.ObjectRef dartOwner;
  Library library;
  bool isStatic;
  bool isConst;
  SourceLocation location;
  Code code;
  Code unoptimizedCode;
  bool isOptimizable;
  bool isInlinable;
  bool hasIntrinsic;
  bool isRecognized;
  bool isNative;
  M.FunctionKind kind;
  int deoptimizations;
  String qualifiedName;
  int usageCounter;
  bool isDart;
  ProfileFunction profile;
  Instance icDataArray;
  Field field;

  bool get immutable => false;

  ServiceFunction._empty(ServiceObject owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, owner);
    super._update(map, mapIsRef);

    name = map['name'];
    vmName = (map.containsKey('_vmName') ? map['_vmName'] : name);

    dartOwner = map['owner'];
    kind = stringToFunctionKind(map['_kind']);
    isDart = M.isDartFunction(kind);

    if (dartOwner is ServiceFunction) {
      ServiceFunction ownerFunction = dartOwner;
      library = ownerFunction.library;
      qualifiedName = "${ownerFunction.qualifiedName}.${name}";
    } else if (dartOwner is Class) {
      Class ownerClass = dartOwner;
      library = ownerClass.library;
      qualifiedName = "${ownerClass.name}.${name}";
    } else {
      library = dartOwner;
      qualifiedName = name;
    }

    hasIntrinsic = map['_intrinsic'];
    isNative = map['_native'];

    if (mapIsRef) {
      return;
    }

    _loaded = true;
    isStatic = map['static'];
    isConst = map['const'];
    location = map['location'];
    code = map['code'];
    isOptimizable = map['_optimizable'];
    isInlinable = map['_inlinable'];
    isRecognized = map['_recognized'];
    unoptimizedCode = map['_unoptimizedCode'];
    deoptimizations = map['_deoptimizations'];
    usageCounter = map['_usageCounter'];
    icDataArray = map['_icDataArray'];
    field = map['_field'];
  }

  ServiceFunction get homeMethod {
    var m = this;
    while (m.dartOwner is ServiceFunction) {
      m = m.dartOwner;
    }
    return m;
  }
}

M.SentinelKind stringToSentinelKind(String s) {
  switch (s) {
    case 'Collected':
      return M.SentinelKind.collected;
    case 'Expired':
      return M.SentinelKind.expired;
    case 'NotInitialized':
      return M.SentinelKind.notInitialized;
    case 'BeingInitialized':
      return M.SentinelKind.initializing;
    case 'OptimizedOut':
      return M.SentinelKind.optimizedOut;
    case 'Free':
      return M.SentinelKind.free;
  }
  Logger.root.severe("Unrecognized SentinelKind: '$s'");
  throw new FallThroughError();
}

class Sentinel extends ServiceObject implements M.Sentinel {
  M.SentinelKind kind;
  String valueAsString;

  Sentinel._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    // Extract full properties.
    _upgradeCollection(map, isolate);

    kind = stringToSentinelKind(map['kind']);
    valueAsString = map['valueAsString'];
    _loaded = true;
  }

  String toString() => 'Sentinel($kind)';
  String get shortName => valueAsString;
}

class Thread extends ServiceObject implements M.Thread {
  M.ThreadKind get kind => _kind;
  M.ThreadKind _kind;
  String get kindString => _kindString;
  String _kindString;
  int get zoneHighWatermark => _zoneHighWatermark;
  int _zoneHighWatermark;
  int get zoneCapacity => _zoneCapacity;
  int _zoneCapacity;

  Thread._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    String rawKind = map['kind'];

    switch (rawKind) {
      case "kUnknownTask":
        _kind = M.ThreadKind.unknownTask;
        _kindString = 'unknown';
        break;
      case "kMutatorTask":
        _kind = M.ThreadKind.mutatorTask;
        _kindString = 'mutator';
        break;
      case "kCompilerTask":
        _kind = M.ThreadKind.compilerTask;
        _kindString = 'compiler';
        break;
      case "kSweeperTask":
        _kind = M.ThreadKind.sweeperTask;
        _kindString = 'sweeper';
        break;
      case "kMarkerTask":
        _kind = M.ThreadKind.markerTask;
        _kindString = 'marker';
        break;
      default:
        assert(false);
    }

    _zoneHighWatermark = int.parse(map['_zoneHighWatermark']);
    _zoneCapacity = int.parse(map['_zoneCapacity']);
  }
}

class Zone implements M.Zone {
  int get capacity => _capacity;
  int _capacity;
  int get used => _used;
  int _used;

  Zone(this._capacity, this._used);
}

class Field extends HeapObject implements M.Field {
  // Library or Class.
  HeapObject dartOwner;
  Library library;
  Instance declaredType;
  bool isStatic;
  bool isFinal;
  bool isConst;
  Instance staticValue;
  String name;
  String vmName;

  bool guardNullable;
  M.GuardClassKind guardClassKind;
  Class guardClass;
  String guardLength;
  SourceLocation location;

  Field._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    // Extract full properties.
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    name = map['name'];
    vmName = (map.containsKey('_vmName') ? map['_vmName'] : name);
    dartOwner = map['owner'];
    declaredType = map['declaredType'];
    isStatic = map['static'];
    isFinal = map['final'];
    isConst = map['const'];

    if (dartOwner is Class) {
      Class ownerClass = dartOwner;
      library = ownerClass.library;
    } else {
      library = dartOwner;
    }

    if (mapIsRef) {
      return;
    }
    staticValue = map['staticValue'];

    guardNullable = map['_guardNullable'];
    if (map['_guardClass'] is Class) {
      guardClass = map['_guardClass'];
      guardClassKind = M.GuardClassKind.single;
    } else {
      switch (map['_guardClass']) {
        case 'various':
          guardClassKind = M.GuardClassKind.dynamic;
          break;
        case 'unknown':
        default:
          guardClassKind = M.GuardClassKind.unknown;
          break;
      }
    }

    guardLength = map['_guardLength'];
    location = map['location'];
    _loaded = true;
  }

  String toString() => 'Field(${dartOwner.name}.$name)';
}

class ScriptLine {
  final Script script;
  final int line;
  final String text;
  Set<Breakpoint> breakpoints;

  ScriptLine(this.script, this.line, this.text);

  bool get isBlank {
    return text.isEmpty || text.trim().isEmpty;
  }

  bool _isTrivial = null;
  bool get isTrivial {
    if (_isTrivial == null) {
      _isTrivial = _isTrivialLine(text);
    }
    return _isTrivial;
  }

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
    if (text.trimLeft().startsWith('//')) {
      return true;
    }
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

  void addBreakpoint(Breakpoint bpt) {
    if (breakpoints == null) {
      breakpoints = new Set<Breakpoint>();
    }
    breakpoints.add(bpt);
  }

  void removeBreakpoint(Breakpoint bpt) {
    assert(breakpoints != null && breakpoints.contains(bpt));
    breakpoints.remove(bpt);
    if (breakpoints.isEmpty) {
      breakpoints = null;
    }
  }
}

class CallSite {
  final String name;
  // TODO(turnidge): Use SourceLocation here instead.
  final Script script;
  final int tokenPos;
  final List<CallSiteEntry> entries;

  CallSite(this.name, this.script, this.tokenPos, this.entries);

  int get line => script.tokenToLine(tokenPos);
  int get column => script.tokenToCol(tokenPos);

  int get aggregateCount {
    var count = 0;
    for (var entry in entries) {
      count += entry.count;
    }
    return count;
  }

  factory CallSite.fromMap(Map siteMap, Script script) {
    var name = siteMap['name'];
    var tokenPos = siteMap['tokenPos'];
    var entries = new List<CallSiteEntry>();
    for (var entryMap in siteMap['cacheEntries']) {
      entries.add(new CallSiteEntry.fromMap(entryMap));
    }
    return new CallSite(name, script, tokenPos, entries);
  }

  operator ==(other) {
    return (script == other.script) && (tokenPos == other.tokenPos);
  }

  int get hashCode => (script.hashCode << 8) | tokenPos;

  String toString() => "CallSite($name, $tokenPos)";
}

class CallSiteEntry {
  final /* Class | Library */ receiver;
  final int count;
  final ServiceFunction target;

  CallSiteEntry(this.receiver, this.count, this.target);

  factory CallSiteEntry.fromMap(Map entryMap) {
    return new CallSiteEntry(
        entryMap['receiver'], entryMap['count'], entryMap['target']);
  }

  String toString() => "CallSiteEntry(${receiver.name}, $count)";
}

/// The location of a local variable reference in a script.
class LocalVarLocation {
  final int line;
  final int column;
  final int endColumn;
  LocalVarLocation(this.line, this.column, this.endColumn);
}

class Script extends HeapObject implements M.Script {
  final lines = <ScriptLine>[];
  String uri;
  String kind;
  DateTime loadTime;
  int firstTokenPos;
  int lastTokenPos;
  int lineOffset;
  int columnOffset;
  Library library;

  String source;

  bool get immutable => true;

  String _shortUri;

  Script._empty(ServiceObjectOwner owner) : super._empty(owner);

  /// Retrieves line number [line] if it exists.
  ScriptLine getLine(int line) {
    assert(_loaded);
    assert(line >= 1);
    return lines[line - lineOffset - 1];
  }

  /// This function maps a token position to a line number.
  /// The VM considers the first line to be line 1.
  int tokenToLine(int tokenPos) => _tokenToLine[tokenPos];
  Map _tokenToLine = {};

  /// This function maps a token position to a column number.
  /// The VM considers the first column to be column 1.
  int tokenToCol(int tokenPos) => _tokenToCol[tokenPos];
  Map _tokenToCol = {};

  int guessTokenLength(int line, int column) {
    String source = getLine(line).text;

    var pos = column;
    if (pos >= source.length) {
      return null;
    }

    var c = source.codeUnitAt(pos);
    if (c == 123) return 1; // { - Map literal

    if (c == 91) return 1; // [ - List literal, index, index assignment

    if (c == 40) return 1; // ( - Closure call

    if (_isOperatorChar(c)) {
      while (++pos < source.length && _isOperatorChar(source.codeUnitAt(pos)));
      return pos - column;
    }

    if (_isInitialIdentifierChar(c)) {
      while (
          ++pos < source.length && _isIdentifierChar(source.codeUnitAt(pos)));
      return pos - column;
    }

    return null;
  }

  static bool _isOperatorChar(int c) {
    switch (c) {
      case 25: // %
      case 26: // &
      case 42: // *
      case 43: // +
      case 45: // -:
      case 47: // /
      case 60: // <
      case 61: // =
      case 62: // >
      case 94: // ^
      case 124: // |
      case 126: // ~
        return true;
      default:
        return false;
    }
  }

  static bool _isInitialIdentifierChar(int c) {
    if (c >= 65 && c <= 90) return true; // Upper
    if (c >= 97 && c <= 122) return true; // Lower
    if (c == 95) return true; // Underscore
    if (c == 36) return true; // Dollar
    return false;
  }

  static bool _isIdentifierChar(int c) {
    if (_isInitialIdentifierChar(c)) return true;
    return c >= 48 && c <= 57; // Digit
  }

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    uri = map['uri'];
    kind = map['_kind'];
    _shortUri = uri.substring(uri.lastIndexOf('/') + 1);
    name = _shortUri;
    vmName = uri;
    if (mapIsRef) {
      return;
    }
    _loaded = true;
    int loadTimeMillis = map['_loadTime'];
    loadTime = new DateTime.fromMillisecondsSinceEpoch(loadTimeMillis);
    lineOffset = map['lineOffset'];
    columnOffset = map['columnOffset'];
    _parseTokenPosTable(map['tokenPosTable']);
    source = map['source'];
    _processSource(map['source']);
    library = map['library'];
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
        var colNumber = line[pos + 1];
        if (firstTokenPos == null) {
          // Mark first token position.
          firstTokenPos = tokenOffset;
          lastTokenPos = tokenOffset;
        } else {
          // Keep track of max and min token positions.
          firstTokenPos =
              (firstTokenPos <= tokenOffset) ? firstTokenPos : tokenOffset;
          lastTokenPos =
              (lastTokenPos >= tokenOffset) ? lastTokenPos : tokenOffset;
        }
        _tokenToLine[tokenOffset] = lineNumber;
        _tokenToCol[tokenOffset] = colNumber;
      }
    }
  }

  void _processSource(String source) {
    if (source == null) {
      return;
    }
    var sourceLines = source.split('\n');
    if (sourceLines.length == 0) {
      return;
    }
    lines.clear();
    Logger.root.info('Adding ${sourceLines.length} source lines for ${uri}');
    for (var i = 0; i < sourceLines.length; i++) {
      lines.add(new ScriptLine(this, i + lineOffset + 1, sourceLines[i]));
    }
    for (var bpt in isolate.breakpoints.values) {
      if (bpt.location.script == this) {
        _addBreakpoint(bpt);
      }
    }
  }

  // Note, this may return source beyond the token length if [guessTokenLength]
  // fails.
  String getToken(int tokenPos) {
    final int line = tokenToLine(tokenPos);
    int column = tokenToCol(tokenPos);
    if ((line == null) || (column == null)) {
      return null;
    }
    // Line and column numbers start at 1 in the VM.
    column -= 1;
    String sourceLine = getLine(line).text;
    if (sourceLine == null) {
      return null;
    }
    final int length = guessTokenLength(line, column);
    if (length == null) {
      return sourceLine.substring(column);
    } else {
      return sourceLine.substring(column, column + length);
    }
  }

  void _addBreakpoint(Breakpoint bpt) {
    var line;
    if (bpt.location.tokenPos != null) {
      line = tokenToLine(bpt.location.tokenPos);
    } else {
      UnresolvedSourceLocation loc = bpt.location;
      line = loc.line;
    }
    getLine(line).addBreakpoint(bpt);
  }

  void _removeBreakpoint(Breakpoint bpt) {
    var line;
    if (bpt.location.tokenPos != null) {
      line = tokenToLine(bpt.location.tokenPos);
    } else {
      UnresolvedSourceLocation loc = bpt.location;
      line = loc.line;
    }
    if (line != null) {
      getLine(line).removeBreakpoint(bpt);
    }
  }

  List<LocalVarLocation> scanLineForLocalVariableLocations(Pattern pattern,
      String name, String lineContents, int lineNumber, int columnOffset) {
    var r = <LocalVarLocation>[];

    pattern.allMatches(lineContents).forEach((Match match) {
      // We have a match but our regular expression may have matched extra
      // characters on either side of the name. Tighten the location.
      var nameStart = match.input.indexOf(name, match.start);
      var column = nameStart + columnOffset;
      var endColumn = column + name.length;
      var localVarLocation =
          new LocalVarLocation(lineNumber, column, endColumn);
      r.add(localVarLocation);
    });

    return r;
  }

  List<LocalVarLocation> scanForLocalVariableLocations(
      String name, int tokenPos, int endTokenPos) {
    // A pattern that matches:
    // start of line OR non-(alpha numeric OR period) character followed by
    // name followed by
    // a non-alpha numerc character.
    //
    // NOTE: This pattern can over match on both ends. This is corrected for
    // [scanLineForLocalVariableLocationse].
    var pattern = new RegExp("(^|[^A-Za-z0-9\.])$name[^A-Za-z0-9]");

    // Result.
    var r = <LocalVarLocation>[];

    // Limits.
    final lastLine = tokenToLine(endTokenPos);
    if (lastLine == null) {
      return r;
    }

    var lastColumn = tokenToCol(endTokenPos);
    if (lastColumn == null) {
      return r;
    }
    // Current scan position.
    var line = tokenToLine(tokenPos);
    if (line == null) {
      return r;
    }
    var column = tokenToCol(tokenPos);
    if (column == null) {
      return r;
    }

    // Move back by name length.
    // TODO(johnmccutchan): Fix LocalVarDescriptor to set column before the
    // identifier name.
    column = math.max(0, column - name.length);

    var lineContents;

    if (line == lastLine) {
      // Only one line.
      if (!getLine(line).isTrivial) {
        // TODO(johnmccutchan): end token pos -> column can lie for snapshotted
        // code. e.g.:
        // io_sink.dart source line 23 ends at column 39
        // io_sink.dart snapshotted source line 23 ends at column 35.
        lastColumn = math.min(getLine(line).text.length, lastColumn);
        lineContents = getLine(line).text.substring(column, lastColumn - 1);
        return scanLineForLocalVariableLocations(
            pattern, name, lineContents, line, column);
      }
    }

    // Scan first line.
    if (!getLine(line).isTrivial) {
      lineContents = getLine(line).text.substring(column);
      r.addAll(scanLineForLocalVariableLocations(
          pattern, name, lineContents, line++, column));
    }

    // Scan middle lines.
    while (line < (lastLine - 1)) {
      if (getLine(line).isTrivial) {
        line++;
        continue;
      }
      lineContents = getLine(line).text;
      r.addAll(scanLineForLocalVariableLocations(
          pattern, name, lineContents, line++, 0));
    }

    // Scan last line.
    if (!getLine(line).isTrivial) {
      // TODO(johnmccutchan): end token pos -> column can lie for snapshotted
      // code. e.g.:
      // io_sink.dart source line 23 ends at column 39
      // io_sink.dart snapshotted source line 23 ends at column 35.
      lastColumn = math.min(getLine(line).text.length, lastColumn);
      lineContents = getLine(line).text.substring(0, lastColumn - 1);
      r.addAll(scanLineForLocalVariableLocations(
          pattern, name, lineContents, line, 0));
    }
    return r;
  }
}

class PcDescriptor {
  final int pcOffset;
  final int deoptId;
  final int tokenPos;
  final int tryIndex;
  final String kind;
  Script script;
  String formattedLine;
  PcDescriptor(
      this.pcOffset, this.deoptId, this.tokenPos, this.tryIndex, this.kind);

  String formattedDeoptId() {
    if (deoptId == -1) {
      return 'N/A';
    }
    return deoptId.toString();
  }

  String formattedTokenPos() {
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

class PcDescriptors extends ServiceObject implements M.PcDescriptorsRef {
  Class clazz;
  int size;
  bool get immutable => true;
  final List<PcDescriptor> descriptors = <PcDescriptor>[];

  PcDescriptors._empty(ServiceObjectOwner owner) : super._empty(owner) {}

  void _update(Map m, bool mapIsRef) {
    if (mapIsRef) {
      return;
    }
    _upgradeCollection(m, isolate);
    clazz = m['class'];
    size = m['size'];
    descriptors.clear();
    for (var descriptor in m['members']) {
      var pcOffset = int.parse(descriptor['pcOffset'], radix: 16);
      var deoptId = descriptor['deoptId'];
      var tokenPos = descriptor['tokenPos'];
      var tryIndex = descriptor['tryIndex'];
      var kind = descriptor['kind'].trim();
      descriptors
          .add(new PcDescriptor(pcOffset, deoptId, tokenPos, tryIndex, kind));
    }
  }
}

class LocalVarDescriptor implements M.LocalVarDescriptorsRef {
  final String id;
  final String name;
  final int index;
  final int declarationPos;
  final int beginPos;
  final int endPos;
  final int scopeId;
  final String kind;

  LocalVarDescriptor(this.id, this.name, this.index, this.declarationPos,
      this.beginPos, this.endPos, this.scopeId, this.kind);
}

class LocalVarDescriptors extends ServiceObject {
  Class clazz;
  int size;
  bool get immutable => true;
  final List<LocalVarDescriptor> descriptors = <LocalVarDescriptor>[];
  LocalVarDescriptors._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map m, bool mapIsRef) {
    if (mapIsRef) {
      return;
    }
    _upgradeCollection(m, isolate);
    clazz = m['class'];
    size = m['size'];
    descriptors.clear();
    for (var descriptor in m['members']) {
      var id = descriptor['name'];
      var name = descriptor['name'];
      var index = descriptor['index'];
      var declarationPos = descriptor['declarationTokenPos'];
      var beginPos = descriptor['scopeStartTokenPos'];
      var endPos = descriptor['scopeEndTokenPos'];
      var scopeId = descriptor['scopeId'];
      var kind = descriptor['kind'].trim();
      descriptors.add(new LocalVarDescriptor(
          id, name, index, declarationPos, beginPos, endPos, scopeId, kind));
    }
  }
}

class ObjectPool extends HeapObject implements M.ObjectPool {
  bool get immutable => false;

  int length;
  List<ObjectPoolEntry> entries;

  ObjectPool._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    length = map['length'];
    if (mapIsRef) {
      return;
    }
    entries = map['_entries'].map((map) => new ObjectPoolEntry(map));
  }
}

class ObjectPoolEntry implements M.ObjectPoolEntry {
  final int offset;
  final M.ObjectPoolEntryKind kind;
  final M.ObjectRef asObject;
  final int asInteger;

  factory ObjectPoolEntry(map) {
    M.ObjectPoolEntryKind kind = stringToObjectPoolEntryKind(map['kind']);
    int offset = map['offset'];
    switch (kind) {
      case M.ObjectPoolEntryKind.object:
        return new ObjectPoolEntry._fromObject(map['value'], offset);
      default:
        return new ObjectPoolEntry._fromInteger(kind, map['value'], offset);
    }
  }

  ObjectPoolEntry._fromObject(this.asObject, this.offset)
      : kind = M.ObjectPoolEntryKind.object,
        asInteger = null;

  ObjectPoolEntry._fromInteger(this.kind, this.asInteger, this.offset)
      : asObject = null;
}

M.ObjectPoolEntryKind stringToObjectPoolEntryKind(String kind) {
  switch (kind) {
    case 'Object':
      return M.ObjectPoolEntryKind.object;
    case 'Immediate':
      return M.ObjectPoolEntryKind.immediate;
    case 'NativeEntry':
      return M.ObjectPoolEntryKind.nativeEntry;
  }
  throw new Exception('Unknown ObjectPoolEntryKind ($kind)');
}

class ICData extends HeapObject implements M.ICData {
  HeapObject dartOwner;
  String selector;
  Instance argumentsDescriptor;
  Instance entries;

  bool get immutable => false;

  ICData._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    dartOwner = map['_owner'];
    selector = map['_selector'];
    if (mapIsRef) {
      return;
    }
    argumentsDescriptor = map['_argumentsDescriptor'];
    entries = map['_entries'];
  }
}

class UnlinkedCall extends HeapObject implements M.UnlinkedCall {
  String selector;
  Instance argumentsDescriptor;

  bool get immutable => false;

  UnlinkedCall._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    selector = map['_selector'];
    if (mapIsRef) {
      return;
    }
    argumentsDescriptor = map['_argumentsDescriptor'];
  }
}

class SingleTargetCache extends HeapObject implements M.SingleTargetCache {
  Code target;
  int lowerLimit;
  int upperLimit;

  bool get immutable => false;

  SingleTargetCache._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    target = map['_target'];
    if (mapIsRef) {
      return;
    }
    lowerLimit = map['_lowerLimit'];
    upperLimit = map['_upperLimit'];
  }
}

class SubtypeTestCache extends HeapObject implements M.SubtypeTestCache {
  Instance cache;

  bool get immutable => false;

  SubtypeTestCache._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    if (mapIsRef) {
      return;
    }
    cache = map['_cache'];
  }
}

class TypeArguments extends HeapObject implements M.TypeArguments {
  HeapObject dartOwner;
  String name;
  Iterable<Instance> types;

  TypeArguments._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    dartOwner = map['_owner'];
    name = map['name'];
    if (mapIsRef) {
      return;
    }
    types = map['types'];
  }
}

class InstanceSet extends HeapObject implements M.InstanceSet {
  HeapObject dartOwner;
  int count;
  Iterable<HeapObject> samples;

  InstanceSet._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    if (mapIsRef) {
      return;
    }
    count = map['totalCount'];
    samples = map['samples'];
  }
}

class MegamorphicCache extends HeapObject implements M.MegamorphicCache {
  int mask;
  Instance buckets;
  String selector;
  Instance argumentsDescriptor;

  bool get immutable => false;

  MegamorphicCache._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    selector = map['_selector'];
    if (mapIsRef) {
      return;
    }

    mask = map['_mask'];
    buckets = map['_buckets'];
    argumentsDescriptor = map['_argumentsDescriptor'];
  }
}

class TokenStream extends HeapObject implements M.TokenStreamRef {
  bool get immutable => true;

  String privateKey;

  TokenStream._empty(ServiceObjectOwner owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    _upgradeCollection(map, isolate);
    super._update(map, mapIsRef);

    if (mapIsRef) {
      return;
    }
    privateKey = map['privateKey'];
  }
}

class CodeInstruction {
  final int address;
  final int pcOffset;
  final String machine;
  final String human;
  final ServiceObject object;
  CodeInstruction jumpTarget;
  List<PcDescriptor> descriptors = <PcDescriptor>[];

  CodeInstruction(
      this.address, this.pcOffset, this.machine, this.human, this.object);

  bool get isComment => address == 0;
  bool get hasDescriptors => descriptors.length > 0;

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
      return int.parse(address, radix: 16);
    } catch (_) {
      return 0;
    }
  }

  void _resolveJumpTarget(
      List<CodeInstruction> instructionsByAddressOffset, int startAddress) {
    if (!_isJumpInstruction()) {
      return;
    }
    int address = _getJumpAddress();
    if (address == 0) {
      return;
    }
    var relativeAddress = address - startAddress;
    if (relativeAddress < 0) {
      Logger.root.warning('Bad address resolving jump target $relativeAddress');
      return;
    }
    if (relativeAddress >= instructionsByAddressOffset.length) {
      Logger.root.warning('Bad address resolving jump target $relativeAddress');
      return;
    }
    jumpTarget = instructionsByAddressOffset[relativeAddress];
  }
}

M.CodeKind stringToCodeKind(String s) {
  if (s == 'Native') {
    return M.CodeKind.native;
  } else if (s == 'Dart') {
    return M.CodeKind.dart;
  } else if (s == 'Collected') {
    return M.CodeKind.collected;
  } else if (s == 'Tag') {
    return M.CodeKind.tag;
  } else if (s == 'Stub') {
    return M.CodeKind.stub;
  }
  Logger.root.severe("Unrecognized code kind: '$s'");
  throw new FallThroughError();
}

class CodeInlineInterval {
  final int start;
  final int end;
  final List<ServiceFunction> functions = new List<ServiceFunction>();
  bool contains(int pc) => (pc >= start) && (pc < end);
  CodeInlineInterval(this.start, this.end);
}

class Code extends HeapObject implements M.Code {
  M.CodeKind kind;
  ObjectPool objectPool;
  ServiceFunction function;
  Script script;
  bool isOptimized;
  bool hasIntrinsic;
  bool isNative;

  int startAddress = 0;
  int endAddress = 0;
  final instructions = <CodeInstruction>[];
  List<CodeInstruction> instructionsByAddressOffset;

  ProfileCode profile;
  final List<CodeInlineInterval> inlineIntervals = <CodeInlineInterval>[];
  final List<ServiceFunction> inlinedFunctions = <ServiceFunction>[];

  bool get immutable => true;

  Code._empty(ServiceObjectOwner owner) : super._empty(owner);

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
    if (kind != M.CodeKind.dart) {
      return;
    }
    if (function == null) {
      return;
    }
    if ((function.location == null) || (function.location.script == null)) {
      // Attempt to load the function.
      function.load().then((func) {
        var script = function.location.script;
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
    function.location.script.load().then(_updateDescriptors);
  }

  /// Reload [this]. Returns a future which completes to [this] or an
  /// exception.
  Future<ServiceObject> reload({int count: kDefaultFieldLimit}) {
    assert(kind != null);
    if (isDartCode) {
      // We only reload Dart code.
      return super.reload(count: count);
    }
    return new Future.value(this);
  }

  void _update(Map m, bool mapIsRef) {
    name = m['name'];
    vmName = (m.containsKey('_vmName') ? m['_vmName'] : name);
    isOptimized = m['_optimized'];
    kind = stringToCodeKind(m['kind']);
    hasIntrinsic = m['_intrinsic'];
    isNative = m['_native'];
    if (mapIsRef) {
      return;
    }
    _loaded = true;
    startAddress = int.parse(m['_startAddress'], radix: 16);
    endAddress = int.parse(m['_endAddress'], radix: 16);
    function = isolate.getFromMap(m['function']);
    objectPool = isolate.getFromMap(m['_objectPool']);
    var disassembly = m['_disassembly'];
    if (disassembly != null) {
      _processDisassembly(disassembly);
    }
    var descriptors = m['_descriptors'];
    if (descriptors != null) {
      descriptors = descriptors['members'];
      _processDescriptors(descriptors);
    }
    hasDisassembly = (instructions.length != 0) && (kind == M.CodeKind.dart);
    inlinedFunctions.clear();
    var inlinedFunctionsTable = m['_inlinedFunctions'];
    var inlinedIntervals = m['_inlinedIntervals'];
    if (inlinedFunctionsTable != null) {
      // Iterate and upgrade each ServiceFunction.
      for (var i = 0; i < inlinedFunctionsTable.length; i++) {
        // Upgrade each function and set it back in the list.
        var func = isolate.getFromMap(inlinedFunctionsTable[i]);
        inlinedFunctionsTable[i] = func;
        if (!inlinedFunctions.contains(func)) {
          inlinedFunctions.add(func);
        }
      }
    }
    if ((inlinedIntervals == null) || (inlinedFunctionsTable == null)) {
      // No inline information.
      inlineIntervals.clear();
      return;
    }
    _processInline(inlinedFunctionsTable, inlinedIntervals);

    _upgradeCollection(m, isolate);
    super._update(m, mapIsRef);
  }

  CodeInlineInterval findInterval(int pc) {
    for (var i = 0; i < inlineIntervals.length; i++) {
      var interval = inlineIntervals[i];
      if (interval.contains(pc)) {
        return interval;
      }
    }
    return null;
  }

  void _processInline(List<ServiceFunction> inlinedFunctionsTable,
      List<List<int>> inlinedIntervals) {
    for (var i = 0; i < inlinedIntervals.length; i++) {
      var inlinedInterval = inlinedIntervals[i];
      var start = inlinedInterval[0] + startAddress;
      var end = inlinedInterval[1] + startAddress;
      var codeInlineInterval = new CodeInlineInterval(start, end);
      for (var i = 2; i < inlinedInterval.length - 1; i++) {
        var inline_id = inlinedInterval[i];
        if (inline_id < 0) {
          continue;
        }
        var function = inlinedFunctionsTable[inline_id];
        codeInlineInterval.functions.add(function);
      }
      inlineIntervals.add(codeInlineInterval);
    }
  }

  bool hasDisassembly = false;

  void _processDisassembly(List disassembly) {
    assert(disassembly != null);
    instructions.clear();
    instructionsByAddressOffset = new List(endAddress - startAddress);

    assert((disassembly.length % 4) == 0);
    for (var i = 0; i < disassembly.length; i += 4) {
      var address = 0; // Assume code comment.
      var machine = disassembly[i + 1];
      var human = disassembly[i + 2];
      var object = disassembly[i + 3];
      if (object != null) {
        object = new ServiceObject._fromMap(owner, object);
      }
      var pcOffset = 0;
      if (disassembly[i] != null) {
        // Not a code comment, extract address.
        address = int.parse(disassembly[i], radix: 16);
        pcOffset = address - startAddress;
      }
      var instruction =
          new CodeInstruction(address, pcOffset, machine, human, object);
      instructions.add(instruction);
      if (disassembly[i] != null) {
        // Not a code comment.
        instructionsByAddressOffset[pcOffset] = instruction;
      }
    }
    for (var instruction in instructions) {
      instruction._resolveJumpTarget(instructionsByAddressOffset, startAddress);
    }
  }

  void _processDescriptors(List<Map> descriptors) {
    for (Map descriptor in descriptors) {
      var pcOffset = int.parse(descriptor['pcOffset'], radix: 16);
      var address = startAddress + pcOffset;
      var deoptId = descriptor['deoptId'];
      var tokenPos = descriptor['tokenPos'];
      var tryIndex = descriptor['tryIndex'];
      var kind = descriptor['kind'].trim();

      var instruction = instructionsByAddressOffset[address - startAddress];
      if (instruction != null) {
        instruction.descriptors
            .add(new PcDescriptor(pcOffset, deoptId, tokenPos, tryIndex, kind));
      } else {
        Logger.root.warning(
            'Could not find instruction with pc descriptor address: $address');
      }
    }
  }

  /// Returns true if [address] is contained inside [this].
  bool contains(int address) {
    return (address >= startAddress) && (address < endAddress);
  }

  bool get isDartCode => (kind == M.CodeKind.dart) || (kind == M.CodeKind.stub);

  String toString() => 'Code($kind, $name)';
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
  final int bytesRead;
  final int bytesWritten;
  final int readCalls;
  final int writeCalls;
  final int available;

  SocketStats(this.bytesRead, this.bytesWritten, this.readCalls,
      this.writeCalls, this.available);
}

/// A peer to a Socket in dart:io. Sockets can represent network sockets or
/// OS pipes. Each socket is owned by another ServceObject, for example,
/// a process or an HTTP server.
class Socket extends ServiceObject {
  Socket._empty(ServiceObjectOwner owner) : super._empty(owner);

  ServiceObject socketOwner;

  bool get isPipe => (kind == SocketKind.Pipe);

  SocketStats latest;
  SocketStats previous;

  SocketKind kind;

  String protocol = '';

  bool readClosed = false;
  bool writeClosed = false;
  bool closing = false;

  /// Listening for connections.
  bool listening = false;

  int fd;

  String localAddress;
  int localPort;
  String remoteAddress;
  int remotePort;

  // Updates internal state from [map]. [map] can be a reference.
  void _update(Map map, bool mapIsRef) {
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

class ServiceMetric extends ServiceObject implements M.Metric {
  ServiceMetric._empty(ServiceObjectOwner owner) : super._empty(owner) {}

  bool get immutable => false;

  Future<Map> _fetchDirect({int count: kDefaultFieldLimit}) {
    assert(owner is Isolate);
    return isolate.invokeRpcNoUpgrade('_getIsolateMetric', {'metricId': id});
  }

  String description;
  double value = 0.0;
  // Only a gauge has a non-null min and max.
  double min;
  double max;

  bool get isGauge => (min != null) && (max != null);

  void _update(Map map, bool mapIsRef) {
    name = map['name'];
    description = map['description'];
    vmName = map['name'];
    value = map['value'];
    min = map['min'];
    max = map['max'];
  }

  String toString() => "ServiceMetric($_id)";
}

Future<Null> printFrames(List<Frame> frames) async {
  for (int i = 0; i < frames.length; i++) {
    final Frame frame = frames[i];
    String frameText = await frame.toUserString();
    print('#${i.toString().padLeft(3)}: $frameText');
  }
}

class Frame extends ServiceObject implements M.Frame {
  M.FrameKind kind = M.FrameKind.regular;
  int index;
  ServiceFunction function;
  SourceLocation location;
  Code code;
  List<ServiceMap> variables = <ServiceMap>[];
  String marker;

  Frame._empty(ServiceObject owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    assert(!mapIsRef);
    _loaded = true;
    _upgradeCollection(map, owner);
    this.kind = _fromString(map['kind']);
    this.marker = map['marker'];
    this.index = map['index'];
    this.function = map['function'];
    this.location = map['location'];
    this.code = map['code'];
    this.variables = map['vars'] ?? [];
  }

  M.FrameKind _fromString(String frameKind) {
    if (frameKind == null) {
      return M.FrameKind.regular;
    }
    switch (frameKind) {
      case 'Regular':
        return M.FrameKind.regular;
      case 'AsyncCausal':
        return M.FrameKind.asyncCausal;
      case 'AsyncSuspensionMarker':
        return M.FrameKind.asyncSuspensionMarker;
      case 'AsyncActivation':
        return M.FrameKind.asyncActivation;
      default:
        throw new UnsupportedError('Unknown FrameKind: $frameKind');
    }
  }

  String toString() {
    if (function != null) {
      return "Frame([$kind] ${function.qualifiedName} $location)";
    } else if (location != null) {
      return "Frame([$kind] $location)";
    } else {
      return "Frame([$kind])";
    }
  }

  Future<String> toUserString() async {
    if (function != null) {
      return "Frame([$kind] ${function.qualifiedName} "
          "${await location.toUserString()})";
    } else if (location != null) {
      return "Frame([$kind] ${await location.toUserString()}";
    } else {
      return "Frame([$kind])";
    }
  }
}

class ServiceMessage extends ServiceObject {
  int index;
  String messageObjectId;
  int size;
  ServiceFunction handler;
  SourceLocation location;

  ServiceMessage._empty(ServiceObject owner) : super._empty(owner);

  void _update(Map map, bool mapIsRef) {
    assert(!mapIsRef);
    _loaded = true;
    _upgradeCollection(map, owner);
    this.messageObjectId = map['messageObjectId'];
    this.index = map['index'];
    this.size = map['size'];
    this.handler = map['handler'];
    this.location = map['location'];
  }
}

// Helper function to extract possible breakpoint locations from a
// SourceReport for some script.
Set<int> getPossibleBreakpointLines(ServiceMap report, Script script) {
  var result = new Set<int>();
  int scriptIndex;
  int numScripts = report['scripts'].length;
  for (scriptIndex = 0; scriptIndex < numScripts; scriptIndex++) {
    if (report['scripts'][scriptIndex].id == script.id) {
      break;
    }
  }
  if (scriptIndex == numScripts) {
    return result;
  }
  var ranges = report['ranges'];
  if (ranges != null) {
    for (var range in ranges) {
      if (range['scriptIndex'] != scriptIndex) {
        continue;
      }
      if (range['compiled']) {
        var possibleBpts = range['possibleBreakpoints'];
        if (possibleBpts != null) {
          for (var tokenPos in possibleBpts) {
            result.add(script.tokenToLine(tokenPos));
          }
        }
      } else {
        int startLine = script.tokenToLine(range['startPos']);
        int endLine = script.tokenToLine(range['endPos']);
        for (int line = startLine; line <= endLine; line++) {
          if (!script.getLine(line).isTrivial) {
            result.add(line);
          }
        }
      }
    }
  }
  return result;
}

// Returns true if [map] is a service map. i.e. it has the following keys:
// 'id' and a 'type'.
bool _isServiceMap(Map m) {
  return (m != null) && (m['type'] != null);
}

bool _hasRef(String type) => type.startsWith('@');
String _stripRef(String type) => (_hasRef(type) ? type.substring(1) : type);

/// Recursively upgrades all [ServiceObject]s inside [collection] which must
/// be an [Map] or an [List]. Upgraded elements will be
/// associated with [vm] and [isolate].
void _upgradeCollection(collection, ServiceObjectOwner owner) {
  if (collection is ServiceMap) {
    return;
  }
  if (collection is Map) {
    _upgradeMap(collection, owner);
  } else if (collection is List) {
    _upgradeList(collection, owner);
  }
}

void _upgradeMap(Map map, ServiceObjectOwner owner) {
  map.forEach((k, v) {
    if ((v is Map) && _isServiceMap(v)) {
      map[k] = owner.getFromMap(v);
    } else if (v is List) {
      _upgradeList(v, owner);
    } else if (v is Map) {
      _upgradeMap(v, owner);
    }
  });
}

void _upgradeList(List list, ServiceObjectOwner owner) {
  for (var i = 0; i < list.length; i++) {
    var v = list[i];
    if ((v is Map) && _isServiceMap(v)) {
      list[i] = owner.getFromMap(v);
    } else if (v is List) {
      _upgradeList(v, owner);
    } else if (v is Map) {
      _upgradeMap(v, owner);
    }
  }
}

class Service implements M.Service {
  final String alias;
  final String method;
  final String service;

  Service(this.alias, this.method, this.service) {
    assert(this.alias != null);
    assert(this.method != null);
    assert(this.service != null);
  }
}
