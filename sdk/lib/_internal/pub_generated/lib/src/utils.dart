library pub.utils;
import 'dart:async';
import "dart:convert";
import 'dart:io';
@MirrorsUsed(targets: const ['pub.io', 'test_pub'])
import 'dart:mirrors';
import "package:crypto/crypto.dart";
import 'package:path/path.dart' as path;
import "package:stack_trace/stack_trace.dart";
import 'exceptions.dart';
import 'log.dart' as log;
export '../../asset/dart/utils.dart';
class Pair<E, F> {
  E first;
  F last;
  Pair(this.first, this.last);
  String toString() => '($first, $last)';
  bool operator ==(other) {
    if (other is! Pair) return false;
    return other.first == first && other.last == last;
  }
  int get hashCode => first.hashCode ^ last.hashCode;
}
class FutureGroup<T> {
  int _pending = 0;
  Completer<List<T>> _completer = new Completer<List<T>>();
  final List<Future<T>> futures = <Future<T>>[];
  bool completed = false;
  final List<T> _values = <T>[];
  Future<T> add(Future<T> task) {
    if (completed) {
      throw new StateError("The FutureGroup has already completed.");
    }
    _pending++;
    futures.add(task.then((value) {
      if (completed) return;
      _pending--;
      _values.add(value);
      if (_pending <= 0) {
        completed = true;
        _completer.complete(_values);
      }
    }).catchError((e, stackTrace) {
      if (completed) return;
      completed = true;
      _completer.completeError(e, stackTrace);
    }));
    return task;
  }
  Future<List> get future => _completer.future;
}
Future newFuture(callback()) => new Future.value().then((_) => callback());
Future captureErrors(Future callback(), {bool captureStackChains: false}) {
  var completer = new Completer();
  var wrappedCallback = () {
    new Future.sync(
        callback).then(completer.complete).catchError((e, stackTrace) {
      if (stackTrace != null) {
        stackTrace = new Chain.forTrace(stackTrace);
      } else {
        stackTrace = new Chain([]);
      }
      completer.completeError(e, stackTrace);
    });
  };
  if (captureStackChains) {
    Chain.capture(wrappedCallback, onError: completer.completeError);
  } else {
    runZoned(wrappedCallback, onError: (e, stackTrace) {
      if (stackTrace == null) {
        stackTrace = new Chain.current();
      } else {
        stackTrace = new Chain([new Trace.from(stackTrace)]);
      }
      completer.completeError(e, stackTrace);
    });
  }
  return completer.future;
}
Future waitAndPrintErrors(Iterable<Future> futures) {
  return Future.wait(futures.map((future) {
    return future.catchError((error, stackTrace) {
      log.exception(error, stackTrace);
      throw error;
    });
  })).catchError((error, stackTrace) {
    throw new SilentException(error, stackTrace);
  });
}
StreamTransformer onDoneTransformer(void onDone()) {
  return new StreamTransformer.fromHandlers(handleDone: (sink) {
    onDone();
    sink.close();
  });
}
String padRight(String source, int length) {
  final result = new StringBuffer();
  result.write(source);
  while (result.length < length) {
    result.write(' ');
  }
  return result.toString();
}
String namedSequence(String name, Iterable iter, [String plural]) {
  if (iter.length == 1) return "$name ${iter.single}";
  if (plural == null) plural = "${name}s";
  return "$plural ${toSentence(iter)}";
}
String toSentence(Iterable iter) {
  if (iter.length == 1) return iter.first.toString();
  return iter.take(iter.length - 1).join(", ") + " and ${iter.last}";
}
String pluralize(String name, int number, {String plural}) {
  if (number == 1) return name;
  if (plural != null) return plural;
  return '${name}s';
}
String quoteRegExp(String string) {
  for (var metacharacter in r"\^$.*+?()[]{}|".split("")) {
    string = string.replaceAll(metacharacter, "\\$metacharacter");
  }
  return string;
}
Uri baseUrlForAddress(InternetAddress address, int port) {
  if (address.isLoopback) {
    return new Uri(scheme: "http", host: "localhost", port: port);
  }
  if (address.type == InternetAddressType.IP_V6) {
    return new Uri(scheme: "http", host: "[${address.address}]", port: port);
  }
  return new Uri(scheme: "http", host: address.address, port: port);
}
bool isLoopback(String host) {
  if (host == 'localhost') return true;
  if (host.startsWith("[") && host.endsWith("]")) {
    host = host.substring(1, host.length - 1);
  }
  try {
    return new InternetAddress(host).isLoopback;
  } on ArgumentError catch (_) {
    return false;
  }
}
List flatten(Iterable nested) {
  var result = [];
  helper(list) {
    for (var element in list) {
      if (element is List) {
        helper(element);
      } else {
        result.add(element);
      }
    }
  }
  helper(nested);
  return result;
}
Set setMinus(Iterable minuend, Iterable subtrahend) {
  var minuendSet = new Set.from(minuend);
  minuendSet.removeAll(subtrahend);
  return minuendSet;
}
bool overlaps(Set set1, Set set2) {
  var smaller = set1.length > set2.length ? set1 : set2;
  var larger = smaller == set1 ? set2 : set1;
  return smaller.any(larger.contains);
}
List ordered(Iterable<Comparable> iter) {
  var list = iter.toList();
  list.sort();
  return list;
}
minBy(Iterable iter, Comparable f(element)) {
  var min = null;
  var minComparable = null;
  for (var element in iter) {
    var comparable = f(element);
    if (minComparable == null || comparable.compareTo(minComparable) < 0) {
      min = element;
      minComparable = comparable;
    }
  }
  return min;
}
Iterable<Pair> pairs(Iterable iter) {
  var previous = iter.first;
  return iter.skip(1).map((element) {
    var oldPrevious = previous;
    previous = element;
    return new Pair(oldPrevious, element);
  });
}
Map mapMap(Map map, {key(key, value), value(key, value)}) {
  if (key == null) key = (key, _) => key;
  if (value == null) value = (_, value) => value;
  var result = {};
  map.forEach((mapKey, mapValue) {
    result[key(mapKey, mapValue)] = value(mapKey, mapValue);
  });
  return result;
}
Future<Map> mapFromIterableAsync(Iterable iter, {key(element), value(element)})
    {
  if (key == null) key = (element) => element;
  if (value == null) value = (element) => element;
  var map = new Map();
  return Future.wait(iter.map((element) {
    return Future.wait(
        [
            new Future.sync(() => key(element)),
            new Future.sync(() => value(element))]).then((results) {
      map[results[0]] = results[1];
    });
  })).then((_) => map);
}
Map<dynamic, Set> transitiveClosure(Map<dynamic, Iterable> graph) {
  var result = {};
  graph.forEach((vertex, edges) {
    result[vertex] = new Set.from(edges)..add(vertex);
  });
  for (var vertex1 in graph.keys) {
    for (var vertex2 in graph.keys) {
      for (var vertex3 in graph.keys) {
        if (result[vertex2].contains(vertex1) &&
            result[vertex1].contains(vertex3)) {
          result[vertex2].add(vertex3);
        }
      }
    }
  }
  return result;
}
Set<String> createFileFilter(Iterable<String> files) {
  return files.expand((file) {
    var result = ["/$file"];
    if (Platform.operatingSystem == 'windows') result.add("\\$file");
    return result;
  }).toSet();
}
Set<String> createDirectoryFilter(Iterable<String> dirs) {
  return dirs.expand((dir) {
    var result = ["/$dir/"];
    if (Platform.operatingSystem == 'windows') {
      result
          ..add("/$dir\\")
          ..add("\\$dir/")
          ..add("\\$dir\\");
    }
    return result;
  }).toSet();
}
maxAll(Iterable iter, [int compare(element1, element2)]) {
  if (compare == null) compare = Comparable.compare;
  return iter.reduce(
      (max, element) => compare(element, max) > 0 ? element : max);
}
minAll(Iterable iter, [int compare(element1, element2)]) {
  if (compare == null) compare = Comparable.compare;
  return iter.reduce(
      (max, element) => compare(element, max) < 0 ? element : max);
}
String replace(String source, Pattern matcher, String fn(Match)) {
  var buffer = new StringBuffer();
  var start = 0;
  for (var match in matcher.allMatches(source)) {
    buffer.write(source.substring(start, match.start));
    start = match.end;
    buffer.write(fn(match));
  }
  buffer.write(source.substring(start));
  return buffer.toString();
}
bool endsWithPattern(String str, Pattern matcher) {
  for (var match in matcher.allMatches(str)) {
    if (match.end == str.length) return true;
  }
  return false;
}
String sha1(String source) {
  var sha = new SHA1();
  sha.add(source.codeUnits);
  return CryptoUtils.bytesToHex(sha.close());
}
void chainToCompleter(Future future, Completer completer) {
  future.then(completer.complete, onError: completer.completeError);
}
Future<Stream> validateStream(Stream stream) {
  var completer = new Completer<Stream>();
  var controller = new StreamController(sync: true);
  StreamSubscription subscription;
  subscription = stream.listen((value) {
    if (!completer.isCompleted) completer.complete(controller.stream);
    controller.add(value);
  }, onError: (error, [stackTrace]) {
    if (completer.isCompleted) {
      controller.addError(error, stackTrace);
      return;
    }
    completer.completeError(error, stackTrace);
    subscription.cancel();
  }, onDone: () {
    if (!completer.isCompleted) completer.complete(controller.stream);
    controller.close();
  });
  return completer.future;
}
Future streamFirst(Stream stream) {
  var completer = new Completer();
  var subscription;
  subscription = stream.listen((value) {
    subscription.cancel();
    completer.complete(value);
  }, onError: (e, [stackTrace]) {
    completer.completeError(e, stackTrace);
  }, onDone: () {
    completer.completeError(new StateError("No elements"), new Chain.current());
  }, cancelOnError: true);
  return completer.future;
}
Pair<Stream, StreamSubscription> streamWithSubscription(Stream stream) {
  var controller = stream.isBroadcast ?
      new StreamController.broadcast(sync: true) :
      new StreamController(sync: true);
  var subscription = stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close);
  return new Pair<Stream, StreamSubscription>(controller.stream, subscription);
}
Pair<Stream, Stream> tee(Stream stream) {
  var controller1 = new StreamController(sync: true);
  var controller2 = new StreamController(sync: true);
  stream.listen((value) {
    controller1.add(value);
    controller2.add(value);
  }, onError: (error, [stackTrace]) {
    controller1.addError(error, stackTrace);
    controller2.addError(error, stackTrace);
  }, onDone: () {
    controller1.close();
    controller2.close();
  });
  return new Pair<Stream, Stream>(controller1.stream, controller2.stream);
}
Stream mergeStreams(Stream stream1, Stream stream2) {
  var doneCount = 0;
  var controller = new StreamController(sync: true);
  for (var stream in [stream1, stream2]) {
    stream.listen(controller.add, onError: controller.addError, onDone: () {
      doneCount++;
      if (doneCount == 2) controller.close();
    });
  }
  return controller.stream;
}
final _trailingCR = new RegExp(r"\r$");
List<String> splitLines(String text) =>
    text.split("\n").map((line) => line.replaceFirst(_trailingCR, "")).toList();
Stream<String> streamToLines(Stream<String> stream) {
  var buffer = new StringBuffer();
  return stream.transform(
      new StreamTransformer.fromHandlers(handleData: (chunk, sink) {
    var lines = splitLines(chunk);
    var leftover = lines.removeLast();
    for (var line in lines) {
      if (!buffer.isEmpty) {
        buffer.write(line);
        line = buffer.toString();
        buffer = new StringBuffer();
      }
      sink.add(line);
    }
    buffer.write(leftover);
  }, handleDone: (sink) {
    if (!buffer.isEmpty) sink.add(buffer.toString());
    sink.close();
  }));
}
Future<Iterable> futureWhere(Iterable iter, test(value)) {
  return Future.wait(iter.map((e) {
    var result = test(e);
    if (result is! Future) result = new Future.value(result);
    return result.then((result) => new Pair(e, result));
  })).then(
      (pairs) =>
          pairs.where(
              (pair) => pair.last)).then((pairs) => pairs.map((pair) => pair.first));
}
List<String> split1(String toSplit, String pattern) {
  if (toSplit.isEmpty) return <String>[];
  var index = toSplit.indexOf(pattern);
  if (index == -1) return [toSplit];
  return [
      toSplit.substring(0, index),
      toSplit.substring(index + pattern.length)];
}
Uri addQueryParameters(Uri url, Map<String, String> parameters) {
  var queryMap = queryToMap(url.query);
  queryMap.addAll(parameters);
  return url.resolve("?${mapToQuery(queryMap)}");
}
Map<String, String> queryToMap(String queryList) {
  var map = {};
  for (var pair in queryList.split("&")) {
    var split = split1(pair, "=");
    if (split.isEmpty) continue;
    var key = urlDecode(split[0]);
    var value = split.length > 1 ? urlDecode(split[1]) : "";
    map[key] = value;
  }
  return map;
}
String mapToQuery(Map<String, String> map) {
  var pairs = <List<String>>[];
  map.forEach((key, value) {
    key = Uri.encodeQueryComponent(key);
    value =
        (value == null || value.isEmpty) ? null : Uri.encodeQueryComponent(value);
    pairs.add([key, value]);
  });
  return pairs.map((pair) {
    if (pair[1] == null) return pair[0];
    return "${pair[0]}=${pair[1]}";
  }).join("&");
}
Set unionAll(Iterable<Set> sets) =>
    sets.fold(new Set(), (union, set) => union.union(set));
bool urisEqual(Uri uri1, Uri uri2) =>
    canonicalizeUri(uri1) == canonicalizeUri(uri2);
Uri canonicalizeUri(Uri uri) {
  return uri;
}
String nicePath(String inputPath) {
  var relative = path.relative(inputPath);
  var split = path.split(relative);
  if (split.length > 1 && split[0] == '..' && split[1] == '..') {
    return path.absolute(inputPath);
  }
  return relative;
}
String niceDuration(Duration duration) {
  var result = duration.inMinutes > 0 ? "${duration.inMinutes}:" : "";
  var s = duration.inSeconds % 59;
  var ms = (duration.inMilliseconds % 1000) ~/ 100;
  return result + "$s.${ms}s";
}
String urlDecode(String encoded) =>
    Uri.decodeComponent(encoded.replaceAll("+", " "));
Future awaitObject(object) {
  if (object is Future) return object.then(awaitObject);
  if (object is Iterable) {
    return Future.wait(object.map(awaitObject).toList());
  }
  if (object is! Map) return new Future.value(object);
  var pairs = <Future<Pair>>[];
  object.forEach((key, value) {
    pairs.add(awaitObject(value).then((resolved) => new Pair(key, resolved)));
  });
  return Future.wait(pairs).then((resolvedPairs) {
    var map = {};
    for (var pair in resolvedPairs) {
      map[pair.first] = pair.last;
    }
    return map;
  });
}
String libraryPath(String libraryName) {
  var lib = currentMirrorSystem().findLibrary(new Symbol(libraryName));
  return path.fromUri(lib.uri);
}
bool get canUseSpecialChars =>
    !runningAsTest &&
        Platform.operatingSystem != 'windows' &&
        stdioType(stdout) == StdioType.TERMINAL;
String getSpecial(String special, [String onWindows = '']) =>
    canUseSpecialChars ? special : onWindows;
String prefixLines(String text, {String prefix: '| ', String firstPrefix}) {
  var lines = text.split('\n');
  if (firstPrefix == null) {
    return lines.map((line) => '$prefix$line').join('\n');
  }
  var firstLine = "$firstPrefix${lines.first}";
  lines = lines.skip(1).map((line) => '$prefix$line').toList();
  lines.insert(0, firstLine);
  return lines.join('\n');
}
bool runningAsTest = Platform.environment.containsKey('_PUB_TESTING');
bool get isAprilFools {
  if (runningAsTest) return false;
  var date = new DateTime.now();
  return date.month == 4 && date.day == 1;
}
Future resetStack(fn()) {
  var completer = new Completer();
  newFuture(fn).then((val) {
    scheduleMicrotask(() => completer.complete(val));
  }).catchError((err, stackTrace) {
    scheduleMicrotask(() => completer.completeError(err, stackTrace));
  });
  return completer.future;
}
final _unquotableYamlString = new RegExp(r"^[a-zA-Z_-][a-zA-Z_0-9-]*$");
String yamlToString(data) {
  var buffer = new StringBuffer();
  _stringify(bool isMapValue, String indent, data) {
    if (data is Map && !data.isEmpty) {
      if (isMapValue) {
        buffer.writeln();
        indent += '  ';
      }
      var keys = data.keys.toList();
      keys.sort((a, b) => a.toString().compareTo(b.toString()));
      var first = true;
      for (var key in keys) {
        if (!first) buffer.writeln();
        first = false;
        var keyString = key;
        if (key is! String || !_unquotableYamlString.hasMatch(key)) {
          keyString = JSON.encode(key);
        }
        buffer.write('$indent$keyString:');
        _stringify(true, indent, data[key]);
      }
      return;
    }
    var string = data;
    if (data is! String || !_unquotableYamlString.hasMatch(data)) {
      string = JSON.encode(data);
    }
    if (isMapValue) {
      buffer.write(' $string');
    } else {
      buffer.write('$indent$string');
    }
  }
  _stringify(false, '', data);
  return buffer.toString();
}
void fail(String message, [innerError, StackTrace innerTrace]) {
  if (innerError != null) {
    throw new WrappedException(message, innerError, innerTrace);
  } else {
    throw new ApplicationException(message);
  }
}
void dataError(String message) => throw new DataException(message);
