// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_transformers;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:barback/barback.dart';
import 'package:source_maps/source_maps.dart';

import '../barback.dart';
import '../dart.dart' as dart;
import '../log.dart' as log;
import '../utils.dart';
import 'server.dart';

/// A Dart script to run in an isolate.
///
/// This script serializes one or more transformers defined in a Dart library
/// and marshals calls to and from them with the host isolate.
const _TRANSFORMER_ISOLATE = """
import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'dart:mirrors';

import 'http://<<HOST_AND_PORT>>/packages/barback/barback.dart';

/// Sets up the initial communication with the host isolate.
void main() {
  port.receive((args, replyTo) {
    _sendFuture(replyTo, new Future.sync(() {
      var library = Uri.parse(args['library']);
      var configuration = JSON.decode(args['configuration']);
      return initialize(library, configuration).
          map(_serializeTransformerOrGroup).toList();
    }));
  });
}

/// Loads all the transformers and groups defined in [uri].
///
/// Loads the library, finds any Transformer or TransformerGroup subclasses in
/// it, instantiates them (with [configuration] if it's non-null), and returns
/// them.
Iterable initialize(Uri uri, Map configuration) {
  var mirrors = currentMirrorSystem();
  var transformerClass = reflectClass(Transformer);
  var groupClass = reflectClass(TransformerGroup);

  // TODO(nweiz): if no valid transformers are found, throw an error message
  // describing candidates and why they were rejected.
  return mirrors.libraries[uri].classes.values.map((classMirror) {
    if (classMirror.isPrivate) return null;
    if (isAbstract(classMirror)) return null;
    if (!classIsA(classMirror, transformerClass) &&
        !classIsA(classMirror, groupClass)) {
      return null;
    }

    var constructor = getConstructor(classMirror, 'asPlugin');
    if (constructor == null) return null;
    if (constructor.parameters.isEmpty) {
      if (configuration != null) return null;
      return classMirror.newInstance(const Symbol('asPlugin'), []).reflectee;
    }
    if (constructor.parameters.length != 1) return null;

    // If the constructor expects configuration and none was passed, it defaults
    // to an empty map.
    if (configuration == null) configuration = {};

    // TODO(nweiz): if the constructor accepts named parameters, automatically
    // destructure the configuration map.
    return classMirror.newInstance(const Symbol('asPlugin'), [configuration])
        .reflectee;
  }).where((classMirror) => classMirror != null);
}

/// A wrapper for a [Transform] that's in the host isolate.
///
/// This retrieves inputs from and sends outputs and logs to the host isolate.
class ForeignTransform implements Transform {
  /// The port with which we communicate with the host isolate.
  ///
  /// This port and all messages sent across it are specific to this transform.
  final SendPort _port;

  final Asset primaryInput;

  TransformLogger get logger => _logger;
  TransformLogger _logger;

  /// Creates a transform from a serializable map sent from the host isolate.
  ForeignTransform(Map transform)
      : _port = transform['port'],
        primaryInput = _deserializeAsset(transform['primaryInput']) {
    _logger = new TransformLogger((assetId, level, message, span) {
      _port.send({
        'type': 'log',
        'level': level.name,
        'message': message,
        'assetId': assetId == null ? null : _serializeId(assetId),
        'span': span == null ? null : _serializeSpan(span)
      });
    });
  }

  Future<Asset> getInput(AssetId id) {
    return _receiveFuture(_port.call({
      'type': 'getInput',
      'id': _serializeId(id)
    })).then(_deserializeAsset);
  }

  Future<String> readInputAsString(AssetId id, {Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return getInput(id).then((input) => input.readAsString(encoding: encoding));
  }

  Stream<List<int>> readInput(AssetId id) =>
      _futureStream(getInput(id).then((input) => input.read()));

  void addOutput(Asset output) {
    _port.send({
      'type': 'addOutput',
      'output': _serializeAsset(output)
    });
  }
}

/// Returns the mirror for the root Object type.
ClassMirror get objectMirror {
  if (_objectMirror == null) {
    _objectMirror = currentMirrorSystem()
        .libraries[Uri.parse('dart:core')]
        .classes[const Symbol('Object')];
  }
  return _objectMirror;
}
ClassMirror _objectMirror;

// TODO(nweiz): clean this up when issue 13248 is fixed.
MethodMirror getConstructor(ClassMirror classMirror, String constructor) {
  var name = new Symbol("\${MirrorSystem.getName(classMirror.simpleName)}"
      ".\$constructor");
  return classMirror.constructors[name];
}

// TODO(nweiz): get rid of this when issue 12439 is fixed.
/// Returns whether or not [mirror] is a subtype of [superclass].
///
/// This includes [superclass] being mixed in to or implemented by [mirror].
bool classIsA(ClassMirror mirror, ClassMirror superclass) {
  if (mirror == superclass) return true;
  if (mirror == objectMirror) return false;
  return classIsA(mirror.superclass, superclass) ||
      mirror.superinterfaces.any((int) => classIsA(int, superclass));
}

// TODO(nweiz): get rid of this when issue 12826 is fixed.
/// Returns whether or not [mirror] is an abstract class.
bool isAbstract(ClassMirror mirror) => mirror.members.values
    .any((member) => member is MethodMirror && member.isAbstract);

/// Converts [transformerOrGroup] into a serializable map.
Map _serializeTransformerOrGroup(transformerOrGroup) {
  if (transformerOrGroup is Transformer) {
    return _serializeTransformer(transformerOrGroup);
  } else {
    assert(transformerOrGroup is TransformerGroup);
    return _serializeTransformerGroup(transformerOrGroup);
  }
}

/// Converts [transformer] into a serializable map.
Map _serializeTransformer(Transformer transformer) {
  var port = new ReceivePort();
  port.receive((message, replyTo) {
    _sendFuture(replyTo, new Future.sync(() {
      if (message['type'] == 'isPrimary') {
        return transformer.isPrimary(_deserializeAsset(message['asset']));
      } else {
        assert(message['type'] == 'apply');
        return transformer.apply(
            new ForeignTransform(message['transform']));
      }
    }));
  });

  return {
    'type': 'Transformer',
    'toString': transformer.toString(),
    'port': port.toSendPort()
  };
}

// Converts [group] into a serializable map.
Map _serializeTransformerGroup(TransformerGroup group) {
  return {
    'type': 'TransformerGroup',
    'toString': group.toString(),
    'phases': group.phases.map((phase) {
      return phase.map(_serializeTransformerOrGroup).toList();
    }).toList()
  };
}

/// Converts a serializable map into an [Asset].
Asset _deserializeAsset(Map asset) {
  var box = new MessageBox();
  asset['sink'].add(box.sink);
  return new Asset.fromStream(_deserializeId(asset['id']), box.stream);
}

/// Converts a serializable map into an [AssetId].
AssetId _deserializeId(Map id) => new AssetId(id['package'], id['path']);

/// Converts [asset] into a serializable map.
Map _serializeAsset(Asset asset) {
  // We can't send IsolateStreams (issue 12437), so instead we send a sink and
  // get the isolate to send us back another sink.
  var box = new MessageBox();
  box.stream.first.then((sink) {
    asset.read().listen(sink.add,
        onError: sink.addError,
        onDone: sink.close);
  });

  return {
    'id': _serializeId(asset.id),
    'sink': box.sink
  };
}

/// Converts [id] into a serializable map.
Map _serializeId(AssetId id) => {'package': id.package, 'path': id.path};

/// Converts [span] into a serializable map.
Map _serializeSpan(Span span) {
  // TODO(nweiz): convert FileSpans to FileSpans.
  return {
    'type': 'fixed',
    'sourceUrl': span.sourceUrl,
    'start': _serializeLocation(span.start),
    'text': span.text,
    'isIdentifier': span.isIdentifier
  };
}

/// Converts [location] into a serializable map.
Map _serializeLocation(Location location) {
  // TODO(nweiz): convert FileLocations to FileLocations.
  return {
    'type': 'fixed',
    'sourceUrl': location.sourceUrl,
    'offset': location.offset,
    'line': location.line,
    'column': location.column
  };
}

/// Sends the result of [future] through [port].
///
/// This should be received on the other end using [_receiveFuture]. It
/// re-raises any exceptions on the other side as [CrossIsolateException]s.
void _sendFuture(SendPort port, Future future) {
  future.then((result) {
    port.send({'success': result});
  }).catchError((error) {
    // TODO(nweiz): at least MissingInputException should be preserved here.
    port.send({'error': CrossIsolateException.serialize(error)});
  });
}

/// Receives the result of [_sendFuture] from [portCall], which should be the
/// return value of [SendPort.call].
Future _receiveFuture(Future portCall) {
  return portCall.then((response) {
    if (response.containsKey('success')) return response['success'];
    return new Future.error(
        new CrossIsolateException.deserialize(response['error']));
  });
}

/// An exception that was originally raised in another isolate.
///
/// Exception objects can't cross isolate boundaries in general, so this class
/// wraps as much information as can be consistently serialized.
class CrossIsolateException implements Exception {
  /// The name of the type of exception thrown.
  ///
  /// This is the return value of [error.runtimeType.toString()]. Keep in mind
  /// that objects in different libraries may have the same type name.
  final String type;

  /// The exception's message, or its [toString] if it didn't expose a `message`
  /// property.
  final String message;

  /// The exception's stack trace, or `null` if no stack trace was available.
  final Trace stackTrace;

  /// Loads a [CrossIsolateException] from a map.
  ///
  /// [error] should be the result of [CrossIsolateException.serialize].
  CrossIsolateException.deserialize(Map error)
      : type = error['type'],
        message = error['message'],
        stackTrace = error['stack'] == null ? null :
            new Trace.parse(error['stack']);

  /// Serializes [error] to a map that can safely be passed across isolate
  /// boundaries.
  static Map serialize(error, [StackTrace stack]) {
    if (stack == null) stack = getAttachedStackTrace(error);
    return {
      'type': error.runtimeType.toString(),
      'message': getErrorMessage(error),
      'stack': stack == null ? null : stack.toString()
    };
  }

  String toString() => "\$message\\n\$stackTrace";
}

// Get a string description of an exception.
//
// Most exception types have a "message" property. We prefer this since
// it skips the "Exception:", "HttpException:", etc. prefix that calling
// toString() adds. But, alas, "message" isn't actually defined in the
// base Exception type so there's no easy way to know if it's available
// short of a giant pile of type tests for each known exception type.
//
// So just try it. If it throws, default to toString().
String getErrorMessage(error) {
  try {
    return error.message;
  } on NoSuchMethodError catch (_) {
    return error.toString();
  }
}

/// Returns a buffered stream that will emit the same values as the stream
/// returned by [future] once [future] completes. If [future] completes to an
/// error, the return value will emit that error and then close.
Stream _futureStream(Future<Stream> future) {
  var controller = new StreamController(sync: true);
  future.then((stream) {
    stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close);
  }).catchError((e, stackTrace) {
    controller.addError(e, stackTrace);
    controller.close();
  });
  return controller.stream;
}
""";

/// Load and return all transformers and groups from the library identified by
/// [id].
///
/// [server] is used to serve any Dart files needed to load the transformers.
Future<Set> loadTransformers(BarbackServer server, TransformerId id) {
  var path = id.asset.path.replaceFirst('lib/', '');
  // TODO(nweiz): load from a "package:" URI when issue 12474 is fixed.
  var hostAndPort = '${server.address.address}:${server.port}';
  var uri = 'http://$hostAndPort/packages/${id.asset.package}/$path';
  var code = 'import "$uri";' +
      _TRANSFORMER_ISOLATE.replaceAll('<<HOST_AND_PORT>>', hostAndPort);
  log.fine("Loading transformers from ${id.asset}");
  return dart.runInIsolate(code).then((sendPort) {
    return _receiveFuture(sendPort.call({
      'library': uri,
      // TODO(nweiz): support non-JSON-encodable configuration maps.
      'configuration': JSON.encode(id.configuration)
    })).then((transformers) {
      transformers = transformers.map(_deserializeTransformerOrGroup).toSet();
      log.fine("Transformers from ${id.asset}: $transformers");
      return transformers;
    });
  }).catchError((error) {
    if (error is! dart.CrossIsolateException) throw error;
    if (error.type != 'IsolateSpawnException') throw error;
    // TODO(nweiz): don't parse this as a string once issues 12617 and 12689 are
    // fixed.
    if (!error.message.split('\n')[1].startsWith('import "$uri";')) {
      throw error;
    }

    // If there was an IsolateSpawnException and the import that actually failed
    // was the one we were loading transformers from, throw an application
    // exception with a more user-friendly message.
    fail('Transformer library "package:${id.asset.package}/$path" not found.');
  });
}

/// A wrapper for a transformer that's in a different isolate.
class _ForeignTransformer extends Transformer {
  /// The port with which we communicate with the child isolate.
  ///
  /// This port and all messages sent across it are specific to this
  /// transformer.
  final SendPort _port;

  /// The result of calling [toString] on the transformer in the isolate.
  final String _toString;

  _ForeignTransformer(Map map)
      : _port = map['port'],
        _toString = map['toString'];

  Future<bool> isPrimary(Asset asset) {
    return _receiveFuture(_port.call({
      'type': 'isPrimary',
      'asset': _serializeAsset(asset)
    }));
  }

  Future apply(Transform transform) {
    return _receiveFuture(_port.call({
      'type': 'apply',
      'transform': _serializeTransform(transform)
    }));
  }

  String toString() => _toString;
}

/// A wrapper for a transformer group that's in a different isolate.
class _ForeignGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  /// The result of calling [toString] on the transformer group in the isolate.
  final String _toString;

  _ForeignGroup(Map map)
      : phases = map['phases'].map((phase) {
          return phase.map(_deserializeTransformerOrGroup).toList();
        }).toList(),
        _toString = map['toString'];

  String toString() => _toString;
}

/// Converts a serializable map into a [Transformer] or a [TransformerGroup].
_deserializeTransformerOrGroup(Map map) {
  if (map['type'] == 'Transformer') return new _ForeignTransformer(map);
  assert(map['type'] == 'TransformerGroup');
  return new _ForeignGroup(map);
}

/// Converts [transform] into a serializable map.
Map _serializeTransform(Transform transform) {
  var receivePort = new ReceivePort();
  receivePort.receive((message, replyTo) {
    if (message['type'] == 'getInput') {
      _sendFuture(replyTo, transform.getInput(_deserializeId(message['id']))
          .then(_serializeAsset));
    } else if (message['type'] == 'addOutput') {
      transform.addOutput(_deserializeAsset(message['output']));
    } else {
      assert(message['type'] == 'log');

      var method;
      if (message['level'] == 'Info') {
        method = transform.logger.info;
      } else if (message['level'] == 'Warning') {
        method = transform.logger.warning;
      } else {
        assert(message['level'] == 'Error');
        method = transform.logger.error;
      }

      var assetId = message['assetId'] == null ? null :
        _deserializeId(message['assetId']);
      var span = message['span'] == null ? null :
        _deserializeSpan(message['span']);
      method(message['message'], asset: assetId, span: span);
    }
  });

  return {
    'port': receivePort.toSendPort(),
    'primaryInput': _serializeAsset(transform.primaryInput)
  };
}

/// Converts a serializable map into an [Asset].
Asset _deserializeAsset(Map asset) {
  var box = new MessageBox();
  asset['sink'].add(box.sink);
  return new Asset.fromStream(_deserializeId(asset['id']), box.stream);
}

/// Converts a serializable map into an [AssetId].
AssetId _deserializeId(Map id) => new AssetId(id['package'], id['path']);

/// Converts a serializable map into a [Span].
Span _deserializeSpan(Map span) {
  assert(span['type'] == 'fixed');
  var location = _deserializeLocation(span['start']);
  return new FixedSpan(span['sourceUrl'], location.offset, location.line,
      location.column, text: span['text'], isIdentifier: span['isIdentifier']);
}

/// Converts a serializable map into a [Location].
Location _deserializeLocation(Map location) {
  assert(location['type'] == 'fixed');
  return new FixedLocation(location['offset'], location['sourceUrl'],
      location['line'], location['column']);
}

// TODO(nweiz): add custom serialization code for assets that can be more
// efficiently serialized.
/// Converts [asset] into a serializable map.
Map _serializeAsset(Asset asset) {
  // We can't send IsolateStreams (issue 12437), so instead we send a sink and
  // get the isolate to send us back another sink.
  var box = new MessageBox();
  box.stream.first.then((sink) {
    asset.read().listen(sink.add,
        onError: sink.addError,
        onDone: sink.close);
  });

  return {
    'id': _serializeId(asset.id),
    'sink': box.sink
  };
}

/// Converts [id] into a serializable map.
Map _serializeId(AssetId id) => {'package': id.package, 'path': id.path};

/// Sends the result of [future] through [port].
///
/// This should be received on the other end using [_receiveFuture]. It
/// re-raises any exceptions on the other side as [dart.CrossIsolateException]s.
void _sendFuture(SendPort port, Future future) {
  future.then((result) {
    port.send({'success': result});
  }).catchError((error) {
    // TODO(nweiz): at least MissingInputException should be preserved here.
    port.send({'error': dart.CrossIsolateException.serialize(error)});
  });
}

/// Receives the result of [_sendFuture] from [portCall], which should be the
/// return value of [SendPort.call].
Future _receiveFuture(Future portCall) {
  return portCall.then((response) {
    if (response.containsKey('success')) return response['success'];
    return new Future.error(
        new dart.CrossIsolateException.deserialize(response['error']));
  });
}
