// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.load_transformers;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:barback/barback.dart';
// TODO(nweiz): don't import from "src" once issue 14966 is fixed.
import 'package:barback/src/internal_asset.dart';
import 'package:source_maps/source_maps.dart';
import 'package:stack_trace/stack_trace.dart';

import '../barback.dart';
import '../dart.dart' as dart;
import '../log.dart' as log;
import '../utils.dart';
import 'build_environment.dart';
import 'excluding_transformer.dart';

/// A Dart script to run in an isolate.
///
/// This script serializes one or more transformers defined in a Dart library
/// and marshals calls to and from them with the host isolate.
const _TRANSFORMER_ISOLATE = """
import 'dart:async';
import 'dart:isolate';
import 'dart:convert';
import 'dart:mirrors';

import '<<URL_BASE>>/packages/source_maps/span.dart';
import '<<URL_BASE>>/packages/stack_trace/stack_trace.dart';
import '<<URL_BASE>>/packages/barback/barback.dart';
// TODO(nweiz): don't import from "src" once issue 14966 is fixed.
import '<<URL_BASE>>/packages/barback/src/internal_asset.dart';

/// Sets up the initial communication with the host isolate.
void main(_, SendPort replyTo) {
  var port = new ReceivePort();
  replyTo.send(port.sendPort);
  port.first.then((wrappedMessage) {
    _respond(wrappedMessage, (message) {
      var library = Uri.parse(message['library']);
      var configuration = JSON.decode(message['configuration']);
      var mode = new BarbackMode(message['mode']);
      return initialize(library, configuration, mode).
          map(_serializeTransformerOrGroup).toList();
    });
  });
}

/// Loads all the transformers and groups defined in [uri].
///
/// Loads the library, finds any Transformer or TransformerGroup subclasses in
/// it, instantiates them with [configuration] and [mode], and returns them.
Iterable initialize(Uri uri, Map configuration, BarbackMode mode) {
  var mirrors = currentMirrorSystem();
  var transformerClass = reflectClass(Transformer);
  var groupClass = reflectClass(TransformerGroup);

  // TODO(nweiz): if no valid transformers are found, throw an error message
  // describing candidates and why they were rejected.
  return mirrors.libraries[uri].declarations.values.map((declaration) {
    if (declaration is! ClassMirror) return null;
    var classMirror = declaration;
    if (classMirror.isPrivate) return null;
    if (classMirror.isAbstract) return null;
    if (!classIsA(classMirror, transformerClass) &&
        !classIsA(classMirror, groupClass)) {
      return null;
    }

    var constructor = getConstructor(classMirror, 'asPlugin');
    if (constructor == null) return null;
    if (constructor.parameters.isEmpty) {
      if (configuration.isNotEmpty) return null;
      return classMirror.newInstance(const Symbol('asPlugin'), []).reflectee;
    }
    if (constructor.parameters.length != 1) return null;

    return classMirror.newInstance(const Symbol('asPlugin'),
        [new BarbackSettings(configuration, mode)]).reflectee;
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
        primaryInput = deserializeAsset(transform['primaryInput']) {
    _logger = new TransformLogger((assetId, level, message, span) {
      _call(_port, {
        'type': 'log',
        'level': level.name,
        'message': message,
        'assetId': assetId == null ? null : _serializeId(assetId),
        'span': span == null ? null : _serializeSpan(span)
      });
    });
  }

  Future<Asset> getInput(AssetId id) {
    return _call(_port, {
      'type': 'getInput',
      'id': _serializeId(id)
    }).then(deserializeAsset);
  }

  Future<String> readInputAsString(AssetId id, {Encoding encoding}) {
    if (encoding == null) encoding = UTF8;
    return getInput(id).then((input) => input.readAsString(encoding: encoding));
  }

  Stream<List<int>> readInput(AssetId id) =>
      _futureStream(getInput(id).then((input) => input.read()));

  void addOutput(Asset output) {
    _call(_port, {
      'type': 'addOutput',
      'output': serializeAsset(output)
    });
  }
}

/// Returns the mirror for the root Object type.
ClassMirror get objectMirror => reflectClass(Object);

// TODO(nweiz): clean this up when issue 13248 is fixed.
MethodMirror getConstructor(ClassMirror classMirror, String constructor) {
  var name = new Symbol("\${MirrorSystem.getName(classMirror.simpleName)}"
      ".\$constructor");
  var candidate = classMirror.declarations[name];
  if (candidate is MethodMirror && candidate.isConstructor) return candidate;
  return null;
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
  port.listen((wrappedMessage) {
    _respond(wrappedMessage, (message) {
      if (message['type'] == 'isPrimary') {
        return transformer.isPrimary(deserializeAsset(message['asset']));
      } else {
        assert(message['type'] == 'apply');

        // Make sure we return null so that if the transformer's [apply] returns
        // a non-serializable value it doesn't cause problems.
        return transformer.apply(
            new ForeignTransform(message['transform'])).then((_) => null);
      }
    });
  });

  return {
    'type': 'Transformer',
    'toString': transformer.toString(),
    'port': port.sendPort
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

/// Converts a serializable map into an [AssetId].
AssetId _deserializeId(Map id) => new AssetId(id['package'], id['path']);

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

/// Responds to a message sent by [_call].
///
/// [wrappedMessage] is the raw message sent by [_call]. This unwraps it and
/// passes the contents of the message to [callback], then sends the return
/// value of [callback] back to [_call]. If [callback] returns a Future or
/// throws an error, that will also be sent.
void _respond(wrappedMessage, callback(message)) {
  var replyTo = wrappedMessage['replyTo'];
  new Future.sync(() => callback(wrappedMessage['message']))
      .then((result) => replyTo.send({'type': 'success', 'value': result}))
      .catchError((error, stackTrace) {
    // TODO(nweiz): at least MissingInputException should be preserved here.
    replyTo.send({
      'type': 'error',
      'error': CrossIsolateException.serialize(error, stackTrace)
    });
  });
}

/// Wraps [message] and sends it across [port], then waits for a response which
/// should be sent using [_respond].
///
/// The returned Future will complete to the value or error returned by
/// [_respond].
Future _call(SendPort port, message) {
  var receivePort = new ReceivePort();
  port.send({
    'message': message,
    'replyTo': receivePort.sendPort
  });

  return receivePort.first.then((response) {
    if (response['type'] == 'success') return response['value'];
    assert(response['type'] == 'error');
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

  /// The exception's stack chain, or `null` if no stack chain was available.
  final Chain stackTrace;

  /// Loads a [CrossIsolateException] from a serialized representation.
  ///
  /// [error] should be the result of [CrossIsolateException.serialize].
  CrossIsolateException.deserialize(Map error)
      : type = error['type'],
        message = error['message'],
        stackTrace = error['stack'] == null ? null :
            new Chain.parse(error['stack']);

  /// Serializes [error] to an object that can safely be passed across isolate
  /// boundaries.
  static Map serialize(error, [StackTrace stack]) {
    if (stack == null && error is Error) stack = error.stackTrace;
    return {
      'type': error.runtimeType.toString(),
      'message': getErrorMessage(error),
      'stack': stack == null ? null : new Chain.forTrace(stack).toString()
    };
  }

  String toString() => "\$message\\n\$stackTrace";
}

/// A regular expression to match the exception prefix that some exceptions'
/// [Object.toString] values contain.
final _exceptionPrefix = new RegExp(r'^([A-Z][a-zA-Z]*)?(Exception|Error): ');

/// Get a string description of an exception.
///
/// Many exceptions include the exception class name at the beginning of their
/// [toString], so we remove that if it exists.
String getErrorMessage(error) =>
  error.toString().replaceFirst(_exceptionPrefix, '');

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

Stream callbackStream(Stream callback()) {
  var subscription;
  var controller;
  controller = new StreamController(onListen: () {
    subscription = callback().listen(controller.add,
        onError: controller.addError,
        onDone: controller.close);
  },
      onCancel: () => subscription.cancel(),
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      sync: true);
  return controller.stream;
}
""";

/// Load and return all transformers and groups from the library identified by
/// [id].
Future<Set> loadTransformers(BuildEnvironment environment, TransformerId id) {
  return id.getAssetId(environment.barback).then((assetId) {
    var path = assetId.path.replaceFirst('lib/', '');
    // TODO(nweiz): load from a "package:" URI when issue 12474 is fixed.

    // We could load the transformers from any server, since they all serve the
    // packages' library files. We choose the first one arbitrarily.
    var baseUrl = baseUrlForAddress(environment.servers.first.address,
                                    environment.servers.first.port);
    var uri = '$baseUrl/packages/${id.package}/$path';
    var code = 'import "$uri";\n' +
        _TRANSFORMER_ISOLATE.replaceAll('<<URL_BASE>>', baseUrl);
    log.fine("Loading transformers from $assetId");

    var port = new ReceivePort();
    return dart.runInIsolate(code, port.sendPort)
        .then((_) => port.first)
        .then((sendPort) {
      return _call(sendPort, {
        'library': uri,
        'mode': environment.mode.name,
        // TODO(nweiz): support non-JSON-encodable configuration maps.
        'configuration': JSON.encode(id.configuration)
      }).then((transformers) {
        transformers = transformers.map(
            (transformer) => _deserializeTransformerOrGroup(transformer, id))
            .toSet();
        log.fine("Transformers from $assetId: $transformers");
        return transformers;
      });
    }).catchError((error, stackTrace) {
      if (error is! dart.CrossIsolateException) throw error;
      if (error.type != 'IsolateSpawnException') throw error;
      // TODO(nweiz): don't parse this as a string once issues 12617 and 12689
      // are fixed.
      if (!error.message.split('\n')[1].startsWith('import "$uri";')) {
        throw error;
      }

      // If there was an IsolateSpawnException and the import that actually
      // failed was the one we were loading transformers from, throw an
      // application exception with a more user-friendly message.
      fail('Transformer library "package:${id.package}/$path" not found.',
          error, stackTrace);
    });
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
    return _call(_port, {
      'type': 'isPrimary',
      'asset': serializeAsset(asset)
    });
  }

  Future apply(Transform transform) {
    return _call(_port, {
      'type': 'apply',
      'transform': _serializeTransform(transform)
    });
  }

  String toString() => _toString;
}

/// A wrapper for a transformer group that's in a different isolate.
class _ForeignGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  /// The result of calling [toString] on the transformer group in the isolate.
  final String _toString;

  _ForeignGroup(TransformerId id, Map map)
      : phases = map['phases'].map((phase) {
          return phase.map((transformer) => _deserializeTransformerOrGroup(
              transformer, id)).toList();
        }).toList(),
        _toString = map['toString'];

  String toString() => _toString;
}

/// Converts a serializable map into a [Transformer] or a [TransformerGroup].
_deserializeTransformerOrGroup(Map map, TransformerId id) {
  if (map['type'] == 'Transformer') {
    var transformer = new _ForeignTransformer(map);
    return ExcludingTransformer.wrap(transformer, id.includes, id.excludes);
  }

  assert(map['type'] == 'TransformerGroup');
  return new _ForeignGroup(id, map);
}

/// Converts [transform] into a serializable map.
Map _serializeTransform(Transform transform) {
  var receivePort = new ReceivePort();
  receivePort.listen((wrappedMessage) {
    _respond(wrappedMessage, (message) {
      if (message['type'] == 'getInput') {
        return transform.getInput(_deserializeId(message['id']))
            .then((asset) => serializeAsset(asset));
      }

      if (message['type'] == 'addOutput') {
        transform.addOutput(deserializeAsset(message['output']));
        return null;
      }

      assert(message['type'] == 'log');
      var method;
      if (message['level'] == 'Info') {
        method = transform.logger.info;
      } else if (message['level'] == 'Fine') {
        method = transform.logger.fine;
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
    });
  });

  return {
    'port': receivePort.sendPort,
    'primaryInput': serializeAsset(transform.primaryInput)
  };
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

/// Converts [id] into a serializable map.
Map _serializeId(AssetId id) => {'package': id.package, 'path': id.path};

/// Responds to a message sent by [_call].
///
/// [wrappedMessage] is the raw message sent by [_call]. This unwraps it and
/// passes the contents of the message to [callback], then sends the return
/// value of [callback] back to [_call]. If [callback] returns a Future or
/// throws an error, that will also be sent.
void _respond(wrappedMessage, callback(message)) {
  var replyTo = wrappedMessage['replyTo'];
  syncFuture(() => callback(wrappedMessage['message']))
      .then((result) => replyTo.send({'type': 'success', 'value': result}))
      .catchError((error, stackTrace) {
    // TODO(nweiz): at least MissingInputException should be preserved here.
    replyTo.send({
      'type': 'error',
      'error': dart.CrossIsolateException.serialize(error, stackTrace)
    });
  });
}

/// Wraps [message] and sends it across [port], then waits for a response which
/// should be sent using [_respond].
///
/// The returned Future will complete to the value or error returned by
/// [_respond].
Future _call(SendPort port, message) {
  var receivePort = new ReceivePort();
  port.send({
    'message': message,
    'replyTo': receivePort.sendPort
  });

  return Chain.track(receivePort.first).then((response) {
    if (response['type'] == 'success') return response['value'];
    assert(response['type'] == 'error');
    return new Future.error(
        new dart.CrossIsolateException.deserialize(response['error']),
        new Chain.current());
  });
}
