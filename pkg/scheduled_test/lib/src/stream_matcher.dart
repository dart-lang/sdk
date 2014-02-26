// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test.stream_matcher;

import 'dart:async';
import 'dart:collection';

import '../scheduled_stream.dart';
import '../scheduled_test.dart';
import 'utils.dart';

/// An abstract superclass for matchers that validate and consume zero or more
/// values emitted by a [ScheduledStream].
///
/// [StreamMatcher]s are most commonly used by passing them to
/// [ScheduledStream.expect].
abstract class StreamMatcher {
  /// Wrap a [Matcher], [StreamMatcher] or [Object] in a [StreamMatcher].
  ///
  /// If this isn't a [StreamMatcher], a [nextValue] matcher is used.
  factory StreamMatcher.wrap(matcher) =>
      matcher is StreamMatcher ? matcher : nextValue(matcher);

  /// Tries to match [this] against [stream].
  ///
  /// If the match succeeds, this returns `null`. If it fails, this returns a
  /// [Description] describing the failure.
  Future<Description> tryMatch(ScheduledStream stream);

  String toString();
}

/// A matcher that consumes and matches a single value.
///
/// [matcher] can be a [Matcher] or an [Object], but not a [StreamMatcher].
StreamMatcher nextValue(matcher) => new _NextValueMatcher(matcher);

/// A matcher that consumes [n] values and matches a list containing those
/// objects against [matcher].
///
/// [matcher] can be a [Matcher] or an [Object], but not a [StreamMatcher].
StreamMatcher nextValues(int n, matcher) => new _NextValuesMatcher(n, matcher);

/// A matcher that matches several sub-matchers in sequence.
///
/// Each element of [streamMatchers] can be a [StreamMatcher], a [Matcher], or
/// an [Object].
StreamMatcher inOrder(Iterable streamMatchers) {
  streamMatchers = streamMatchers.toList();
  if (streamMatchers.length == 1) {
    return new StreamMatcher.wrap(streamMatchers.first);
  } else {
    return new _InOrderMatcher(streamMatchers);
  }
}

/// A matcher that consumes values emitted by a stream until one matching
/// [matcher] is emitted.
///
/// This will fail if the stream never emits a value that matches [matcher].
///
/// [matcher] can be a [Matcher] or an [Object], but not a [StreamMatcher].
StreamMatcher consumeThrough(matcher) => new _ConsumeThroughMatcher(matcher);

/// A matcher that consumes values emitted by a stream as long as they match
/// [matcher].
///
/// This matcher will always match a stream. It exists to consume values.
///
/// [matcher] can be a [Matcher] or an [Object], but not a [StreamMatcher].
StreamMatcher consumeWhile(matcher) => new _ConsumeWhileMatcher(matcher);

/// A matcher that matches either [streamMatcher1], [streamMatcher2], or both.
///
/// If both matchers match the stream, the one that consumed more values will be
/// used.
///
/// Both [streamMatcher1] and [streamMatcher2] can be a [StreamMatcher], a
/// [Matcher], or an [Object].
StreamMatcher either(streamMatcher1, streamMatcher2) =>
  new _EitherMatcher(streamMatcher1, streamMatcher2);

/// A matcher that consumes [streamMatcher] if it matches, or nothing otherwise.
///
/// This matcher will always match a stream. It exists to consume values that
/// may or may not be emitted by a stream.
///
/// [streamMatcher] can be a [StreamMatcher], a [Matcher], or an [Object].
StreamMatcher allow(streamMatcher) => new _AllowMatcher(streamMatcher);

/// A matcher that asserts that a stream never emits values matching
/// [streamMatcher].
///
/// This will consume the remainder of a stream.
///
/// [streamMatcher] can be a [StreamMatcher], a [Matcher], or an [Object].
StreamMatcher never(streamMatcher) => new _NeverMatcher(streamMatcher);

/// A matcher that matches a stream that emits no more values.
StreamMatcher get isDone => new _IsDoneMatcher();

/// See [nextValue].
class _NextValueMatcher implements StreamMatcher {
  final Matcher _matcher;

  _NextValueMatcher(matcher)
      : _matcher = wrapMatcher(matcher);

  Future<Description> tryMatch(ScheduledStream stream) {
    return stream.hasNext.then((hasNext) {
      if (!hasNext) {
        return new StringDescription("unexpected end of stream");
      }
      return stream.next().then((value) {
        var matchState = {};
        if (_matcher.matches(value, matchState)) return null;
        return _matcher.describeMismatch(value, new StringDescription(),
            matchState, false);
      });
    });
  }

  String toString() => _matcher.describe(new StringDescription()).toString();
}

/// See [nextValues].
class _NextValuesMatcher implements StreamMatcher {
  final int _n;
  final Matcher _matcher;

  _NextValuesMatcher(this._n, matcher)
      : _matcher = wrapMatcher(matcher);

  Future<Description> tryMatch(ScheduledStream stream) {
    var collectedValues = [];
    collectValues(count) {
      if (count == 0) return null;

      return stream.hasNext.then((hasNext) {
        if (!hasNext) return new StringDescription('unexpected end of stream');

        return stream.next().then((value) {
          collectedValues.add(value);
          return collectValues(count - 1);
        });
      });
    }

    return collectValues(_n).then((failure) {
      if (failure != null) return failure;
      var matchState = {};
      if (_matcher.matches(collectedValues, matchState)) return null;
      return _matcher.describeMismatch(collectedValues, new StringDescription(),
          matchState, false);
    });
  }

  String toString() {
    return new StringDescription('$_n values that ')
        .addDescriptionOf(_matcher)
        .toString();
  }
}

/// See [inOrder].
class _InOrderMatcher implements StreamMatcher {
  final List<StreamMatcher> _matchers;

  _InOrderMatcher(Iterable streamMatchers)
      : _matchers = streamMatchers.map((matcher) =>
          new StreamMatcher.wrap(matcher)).toList();

  Future<Description> tryMatch(ScheduledStream stream) {
    var matchers = new Queue.from(_matchers);

    matchNext() {
      if (matchers.isEmpty) return new Future.value();
      var matcher = matchers.removeFirst();
      return matcher.tryMatch(stream).then((failure) {
        if (failure == null) return matchNext();
        var newFailure = new StringDescription(
              'matcher #${_matchers.length - matchers.length} failed');
        if (failure.length != 0) newFailure.add(':\n$failure');
        return newFailure;
      });
    }

    return matchNext();
  }

  String toString() => _matchers
      .map((matcher) => prefixLines(matcher.toString(), firstPrefix: '* '))
      .join('\n');
}

/// See [consumeThrough].
class _ConsumeThroughMatcher implements StreamMatcher {
  final Matcher _matcher;

  _ConsumeThroughMatcher(matcher)
      : _matcher = wrapMatcher(matcher);

  Future<Description> tryMatch(ScheduledStream stream) {
    consumeNext() {
      return stream.hasNext.then((hasNext) {
        if (!hasNext) return new StringDescription("unexpected end of stream");

        return stream.next().then((value) {
          if (_matcher.matches(value, {})) return null;
          return consumeNext();
        });
      });
    }

    return consumeNext();
  }

  String toString() {
    return new StringDescription('values followed by ')
        .addDescriptionOf(_matcher).toString();
  }
}

/// See [consumeWhile].
class _ConsumeWhileMatcher implements StreamMatcher {
  final Matcher _matcher;

  _ConsumeWhileMatcher(matcher)
      : _matcher = wrapMatcher(matcher);

  Future<Description> tryMatch(ScheduledStream stream) {
    consumeNext() {
      return stream.hasNext.then((hasNext) {
        if (!hasNext) return new Future.value();

        return _peek(stream).then((value) {
          if (!_matcher.matches(value, {})) return null;
          return stream.next().then((_) => consumeNext());
        });
      });
    }

    return consumeNext();
  }

  String toString() {
    return new StringDescription('any number of ')
        .addDescriptionOf(_matcher).toString();
  }
}

/// See [either].
class _EitherMatcher implements StreamMatcher {
  final StreamMatcher _matcher1;
  final StreamMatcher _matcher2;

  _EitherMatcher(streamMatcher1, streamMatcher2)
      : _matcher1 = new StreamMatcher.wrap(streamMatcher1),
        _matcher2 = new StreamMatcher.wrap(streamMatcher2);

  Future<Description> tryMatch(ScheduledStream stream) {
    var stream1 = stream.fork();
    var stream2 = stream.fork();

    return Future.wait([
      _matcher1.tryMatch(stream1).whenComplete(stream1.close),
      _matcher2.tryMatch(stream2).whenComplete(stream2.close)
    ]).then((failures) {
      var failure1 = failures.first;
      var failure2 = failures.last;

      // If both matchers matched, use the one that consumed more of the stream.
      if (failure1 == null && failure2 == null) {
        if (stream1.emittedValues.length >= stream2.emittedValues.length) {
          return _matcher1.tryMatch(stream);
        } else {
          return _matcher2.tryMatch(stream);
        }
      } else if (failure1 == null) {
        return _matcher1.tryMatch(stream);
      } else if (failure2 == null) {
        return _matcher2.tryMatch(stream);
      } else {
        return new StringDescription('both\n')
            .add(prefixLines(failure1.toString(), prefix: '  '))
            .add('\nand\n')
            .add(prefixLines(failure2.toString(), prefix: '  '))
            .toString();
      }
    });
  }

  String toString() {
    return new StringDescription('either\n')
        .add(prefixLines(_matcher1.toString(), prefix: '  '))
        .add('\nor\n')
        .add(prefixLines(_matcher2.toString(), prefix: '  '))
        .toString();
  }
}

/// See [allow].
class _AllowMatcher implements StreamMatcher {
  final StreamMatcher _matcher;

  _AllowMatcher(streamMatcher)
      : _matcher = new StreamMatcher.wrap(streamMatcher);

  Future<Description> tryMatch(ScheduledStream stream) {
    var fork = stream.fork();
    return _matcher.tryMatch(fork).whenComplete(fork.close).then((failure) {
      if (failure != null) return null;
      return _matcher.tryMatch(stream);
    });
  }

  String toString() {
    return new StringDescription('allow\n')
        .add(prefixLines(_matcher.toString()))
        .toString();
  }
}

/// See [never].
class _NeverMatcher implements StreamMatcher {
  final StreamMatcher _matcher;

  _NeverMatcher(streamMatcher)
      : _matcher = new StreamMatcher.wrap(streamMatcher);

  Future<Description> tryMatch(ScheduledStream stream) {
    consumeNext() {
      return stream.hasNext.then((hasNext) {
        if (!hasNext) return new Future.value();

        var fork = stream.fork();
        return _matcher.tryMatch(fork).whenComplete(fork.close)
            .then((failure) {
          if (failure != null) {
            return stream.next().then((_) => consumeNext());
          }

          return new StringDescription("matched\n")
              .add(prefixLines(_matcher.toString(), prefix: '  '));
        });
      });
    }

    return consumeNext();
  }

  String toString() =>
    'never\n${prefixLines(_matcher.toString(), prefix: '  ')}';
}

/// See [isDone].
class _IsDoneMatcher implements StreamMatcher {
  _IsDoneMatcher();

  Future<Description> tryMatch(ScheduledStream stream) {
    return stream.hasNext.then((hasNext) {
      if (!hasNext) return null;
      return new StringDescription("stream wasn't finished");
    });
  }

  String toString() => 'is done';
}

/// Returns a [Future] that completes to the next value emitted by [stream]
/// without actually consuming that value.
Future _peek(ScheduledStream stream) {
  var fork = stream.fork();
  return fork.next().whenComplete(fork.close);
}
