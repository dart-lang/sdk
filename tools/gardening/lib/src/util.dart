// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'cache.dart';
import 'cache_new.dart';
import 'logger.dart';

/// Checks that [haystack] contains substring [needle], case insensitive.
/// Throws an exception if either parameter is `null`.
bool containsIgnoreCase(String haystack, String needle) {
  if (haystack == null) {
    throw "Unexpected null as the first paramter value of containsIgnoreCase";
  }
  if (needle == null) {
    throw "Unexpected null as the second parameter value of containsIgnoreCase";
  }
  return haystack.toLowerCase().contains(needle.toLowerCase());
}

/// Split [text] using [infixes] as infix markers.
List<String> split(String text, List<String> infixes) {
  List<String> result = <String>[];
  int start = 0;
  for (String infix in infixes) {
    int index = text.indexOf(infix, start);
    if (index == -1)
      throw "'$infix' not found in '$text' from offset ${start}.";
    result.add(text.substring(start, index));
    start = index + infix.length;
  }
  result.add(text.substring(start));
  return result;
}

/// Pad [text] with spaces to the right to fit [length].
String padRight(String text, int length) {
  if (text.length < length) return '${text}${' ' * (length - text.length)}';
  return text;
}

/// Pad [text] with spaces to the left to fit [length].
String padLeft(String text, int length) {
  if (text.length < length) return '${' ' * (length - text.length)}${text}';
  return text;
}

bool LOG = const bool.fromEnvironment('LOG', defaultValue: false);

void log(Object text) {
  if (LOG) print(text);
}

Logger createLogger({bool verbose: false}) {
  return new StdOutLogger(verbose ? Level.debug : Level.info);
}

CreateCacheFunction createCacheFunction(Logger logger,
    {bool disableCache: false}) {
  return disableCache
      ? noCache()
      : initCache(Uri.base.resolve('temp/gardening-cache/'), logger);
}

class HttpException implements Exception {
  final Uri uri;
  final int statusCode;

  HttpException(this.uri, this.statusCode);

  String toString() => '$uri: $statusCode';
}

/// Reads the content of [uri] as text.
Future<String> readUriAsText(
    HttpClient client, Uri uri, Duration timeout) async {
  HttpClientRequest request = await client.getUrl(uri);
  HttpClientResponse response = await request.close();
  if (response.statusCode != 200) {
    response.drain();
    throw new HttpException(uri, response.statusCode);
  }
  if (timeout != null) {
    return response.timeout(timeout).transform(UTF8.decoder).join();
  } else {
    return response.transform(UTF8.decoder).join();
  }
}

class Flags {
  static const String cache = 'cache';
  static const String commit = 'commit';
  static const String help = 'help';
  static const String logdog = 'logdog';
  static const String noCache = 'no-cache';
  static const String verbose = 'verbose';
}

ArgParser createArgParser() {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag(Flags.help, help: "Help");
  argParser.addFlag(Flags.verbose,
      abbr: 'v', negatable: false, help: "Turn on logging output.");
  argParser.addFlag(Flags.noCache, help: "Disable caching.");
  argParser.addOption(Flags.cache,
      help: "Use <dir> for caching test output.\n"
          "Defaults to 'temp/gardening-cache/'.");
  argParser.addFlag(Flags.logdog,
      negatable: true,
      defaultsTo: true,
      help: "Pull test results from logdog.");
  return argParser;
}

void processArgResults(ArgResults argResults) {
  if (argResults[Flags.verbose]) {
    LOG = true;
  }
  if (argResults[Flags.cache] != null) {
    cache.base = Uri.base.resolve('${argResults[Flags.cache]}/');
  }
  if (argResults[Flags.noCache]) {
    cache.base = null;
  }
}

/// Strips un-wanted characters from string [category] from CBE json.
String sanitizeCategory(String category) {
  var reg = new RegExp(r"^[0-9]+(.*)\|all$");
  var match = reg.firstMatch(category);
  return match != null ? match.group(1) : category;
}

/// Returns a function (dynamic, StackTrace) -> Void, useful for printing
/// exceptions.
exceptionPrint(String message) {
  return (dynamic ex, {StackTrace st}) {
    if (message != null) {
      print(message);
    }
    print(ex);
    if (st != null) {
      print(st);
    } else if (ex is Error) {
      print(ex.stackTrace);
    }
  };
}

/// Zips two iterables to a new list, by calling [f]. [second] has to be at
/// least the same length as [first].
Iterable<T> zipWith<T, X, Y>(
    Iterable<X> first, Iterable<Y> second, T f(X x, Y y)) sync* {
  var yIterator = second.iterator;
  for (var x in first) {
    if (!yIterator.moveNext()) {
      throw new Exception("second have to be at least the same length of xs.");
    }
    yield f(x, yIterator.current);
  }
}

typedef T ErrorLogger<T>(error, StackTrace s);

/// errorLogger with a return-value, which can be used for onError and
/// catchError in futures.
ErrorLogger<T> errorLogger<T>(Logger logger, String message, T returnValue) {
  return (dynamic e, StackTrace s) {
    // TODO(mkroghj,johnniwinther): Pass [s] to [Logger.error] when in developer
    // mode.
    logger.error(message, e);
    return returnValue;
  };
}

/// Iterates over [items] and spawns [concurrent] x futures, by calling [f].d
/// When a future completes it will try to take the next in the list. The
/// function will complete when all items has been processed.
Future<Iterable<S>> waitWithThrottle<T, S>(
    Iterable items, int concurrent, Future<S> f(T item)) async {
  // Listify the items, to make sure length is constant.
  var inputs = items.toList();
  List<S> results = new List<S>(inputs.length);
  var current = 0;

  await Future.wait(new Iterable.generate(
      concurrent,
      (int _) => Future.doWhile(() async {
            if (current >= inputs.length) {
              return false;
            }
            int index = current++;
            results[index] = await f(inputs[index]);
            return true;
          })));

  return results;
}

/// Iterates over [items] and spawns [concurrent] x futures, by calling [f].
/// When a future completes it will try to take the next in the list. The
/// function will complete when all items has been processed.
Future<Iterable<S>> waitWithThrottle2<T, S>(
    Iterable items, int concurrent, Future<S> f(T item)) async {
  // Listify the items, to make sure length is constant.
  var remainingList = items.toList();
  List<S> resultList = new List<S>(remainingList.length);
  var finger = 0;
  var doWork = (continuation) async {
    if (finger >= remainingList.length) {
      return;
    }
    int thisFinger = finger++;
    resultList[thisFinger] = await f(remainingList[thisFinger]);
    await continuation(continuation);
  };
  await Future.wait(new Iterable.generate(concurrent, (_) => doWork(doWork)));
  return resultList;
}

/// Similar to Iterable.where, except, the function [f] returns a future boolean.
Future<Iterable<T>> futureWhere<T>(
    Iterable<T> items, Future<bool> f(T item)) async {
  List<bool> results =
      (await Future.wait(items.map((item) => f(item)))).toList();
  var index = 0;
  return items.where((item) => results[index++]).toList();
}

/// Run the python [script] with the provided [args].
Future<ProcessResult> runPython(String script, List<String> args) {
  if (Platform.isWindows) {
    args = []
      ..add(script)
      ..addAll(args);
    script = 'python.exe';
  }
  return Process.run(script, args);
}

/// Regular expression matches a Linux or Windows new line character.
final RegExp newLine = new RegExp(r'\r\n|\n');
