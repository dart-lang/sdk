// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.log_entry_list;

import 'package:matcher/matcher.dart';

import 'call_matcher.dart';
import 'log_entry.dart';
import 'util.dart';

/**
* [StepValidator]s are used by [stepwiseValidate] in [LogEntryList], which
* iterates through the list and call the [StepValidator] function with the
* log [List] and position. The [StepValidator] should return the number of
* positions to advance upon success, or zero upon failure. When zero is
* returned an error is reported.
*/
typedef int StepValidator(List<LogEntry> logs, int pos);

/**
 * We do verification on a list of [LogEntry]s. To allow chaining
 * of calls to verify, we encapsulate such a list in the [LogEntryList]
 * class.
 */
class LogEntryList {
  String filter;
  List<LogEntry> logs;
  LogEntryList([this.filter]) {
    logs = new List<LogEntry>();
  }

  /** Add a [LogEntry] to the log. */
  add(LogEntry entry) => logs.add(entry);

  /** Get the first entry, or null if no entries. */
  get first => (logs == null || logs.length == 0) ? null : logs[0];

  /** Get the last entry, or null if no entries. */
  get last => (logs == null || logs.length == 0) ? null : logs.last;

  /** Creates a LogEntry predicate function from the argument. */
  Function _makePredicate(arg) {
    if (arg == null) {
      return (e) => true;
    } else if (arg is CallMatcher) {
      return (e) => arg.matches(e.methodName, e.args);
    } else if (arg is Function) {
      return arg;
    } else {
      throw new Exception("Invalid argument to _makePredicate.");
    }
  }

  /**
   * Create a new [LogEntryList] consisting of [LogEntry]s from
   * this list that match the specified [mockNameFilter] and [logFilter].
   * [mockNameFilter] can be null, a [String], a predicate [Function],
   * or a [Matcher]. If [mockNameFilter] is null, this is the same as
   * [anything].
   * If [logFilter] is null, all entries in the log will be returned.
   * Otherwise [logFilter] should be a [CallMatcher] or  predicate function
   * that takes a [LogEntry] and returns a bool.
   * If [destructive] is true, the log entries are removed from the
   * original list.
   */
  LogEntryList getMatches([mockNameFilter,
                          logFilter,
                          Matcher actionMatcher,
                          bool destructive = false]) {
    if (mockNameFilter == null) {
      mockNameFilter = anything;
    } else {
      mockNameFilter = wrapMatcher(mockNameFilter);
    }
    Function entryFilter = _makePredicate(logFilter);
    String filterName = qualifiedName(mockNameFilter, logFilter.toString());
    LogEntryList rtn = new LogEntryList(filterName);
    var matchState = {};
    for (var i = 0; i < logs.length; i++) {
      LogEntry entry = logs[i];
      if (mockNameFilter.matches(entry.mockName, matchState) &&
          entryFilter(entry)) {
        if (actionMatcher == null ||
            actionMatcher.matches(entry, matchState)) {
          rtn.add(entry);
          if (destructive) {
            int startIndex = i--;
            logs.removeRange(startIndex, startIndex + 1);
          }
        }
      }
    }
    return rtn;
  }

  /** Apply a unit test [Matcher] to the [LogEntryList]. */
  LogEntryList verify(Matcher matcher) {
    if (_mockFailureHandler == null) {
      _mockFailureHandler =
          new _MockFailureHandler(getOrCreateExpectFailureHandler());
    }
    expect(logs, matcher, reason: filter, failureHandler: _mockFailureHandler);
    return this;
  }

  /**
   * Iterate through the list and call the [validator] function with the
   * log [List] and position. The [validator] should return the number of
   * positions to advance upon success, or zero upon failure. When zero is
   * returned an error is reported. [reason] can be used to provide a
   * more descriptive failure message. If a failure occurred false will be
   * returned (unless the failure handler itself threw an exception);
   * otherwise true is returned.
   * The use case here is to perform more complex validations; for example
   * we may want to assert that the return value from some function is
   * later used as a parameter to a following function. If we filter the logs
   * to include just these two functions we can write a simple validator to
   * do this check.
   */
  bool stepwiseValidate(StepValidator validator, [String reason = '']) {
    if (_mockFailureHandler == null) {
      _mockFailureHandler =
          new _MockFailureHandler(getOrCreateExpectFailureHandler());
    }
    var i = 0;
    while (i < logs.length) {
      var n = validator(logs, i);
      if (n == 0) {
        if (reason.length > 0) {
          reason = ': $reason';
        }
        _mockFailureHandler.fail("Stepwise validation failed at $filter "
                                 "position $i$reason");
        return false;
      } else {
        i += n;
      }
    }
    return true;
  }

  /**
   * Turn the logs into human-readable text. If [baseTime] is specified
   * then each entry is prefixed with the offset from that time in
   * milliseconds; otherwise the time of day is used.
   */
  String toString([DateTime baseTime]) {
    String s = '';
    for (var e in logs) {
      s = '$s${e.toString(baseTime)}\n';
    }
    return s;
  }

  /**
   *  Find the first log entry that satisfies [logFilter] and
   *  return its position. A search [start] position can be provided
   *  to allow for repeated searches. [logFilter] can be a [CallMatcher],
   *  or a predicate function that takes a [LogEntry] argument and returns
   *  a bool. If [logFilter] is null, it will match any [LogEntry].
   *  If no entry is found, then [failureReturnValue] is returned.
   *  After each check the position is updated by [skip], so using
   *  [skip] of -1 allows backward searches, using a [skip] of 2 can
   *  be used to check pairs of adjacent entries, and so on.
   */
  int findLogEntry(logFilter, [int start = 0, int failureReturnValue = -1,
      skip = 1]) {
    logFilter = _makePredicate(logFilter);
    int pos = start;
    while (pos >= 0 && pos < logs.length) {
      if (logFilter(logs[pos])) {
        return pos;
      }
      pos += skip;
    }
    return failureReturnValue;
  }

  /**
   * Returns log events that happened up to the first one that
   * satisfies [logFilter]. If [inPlace] is true, then returns
   * this LogEntryList after removing the from the first satisfier;
   * onwards otherwise a new list is created. [description]
   * is used to create a new name for the resulting list.
   * [defaultPosition] is used as the index of the matching item in
   * the case that no match is found.
   */
  LogEntryList _head(logFilter, bool inPlace,
                     String description, int defaultPosition) {
    if (filter != null) {
      description = '$filter $description';
    }
    int pos = findLogEntry(logFilter, 0, defaultPosition);
    if (inPlace) {
      if (pos < logs.length) {
        logs.removeRange(pos, logs.length);
      }
      filter = description;
      return this;
    } else {
      LogEntryList newList = new LogEntryList(description);
      for (var i = 0; i < pos; i++) {
        newList.logs.add(logs[i]);
      }
      return newList;
    }
  }

  /**
   * Returns log events that happened from the first one that
   * satisfies [logFilter]. If [inPlace] is true, then returns
   * this LogEntryList after removing the entries up to the first
   * satisfier; otherwise a new list is created. [description]
   * is used to create a new name for the resulting list.
   * [defaultPosition] is used as the index of the matching item in
   * the case that no match is found.
   */
  LogEntryList _tail(logFilter, bool inPlace,
                     String description, int defaultPosition) {
    if (filter != null) {
      description = '$filter $description';
    }
    int pos = findLogEntry(logFilter, 0, defaultPosition);
    if (inPlace) {
      if (pos > 0) {
        logs.removeRange(0, pos);
      }
      filter = description;
      return this;
    } else {
      LogEntryList newList = new LogEntryList(description);
      while (pos < logs.length) {
        newList.logs.add(logs[pos++]);
      }
      return newList;
    }
  }

  /**
   * Returns log events that happened after [when]. If [inPlace]
   * is true, then it returns this LogEntryList after removing
   * the entries that happened up to [when]; otherwise a new
   * list is created.
   */
  LogEntryList after(DateTime when, [bool inPlace = false]) =>
      _tail((e) => e.time.isAfter(when), inPlace, 'after $when', logs.length);

  /**
   * Returns log events that happened from [when] onwards. If
   * [inPlace] is true, then it returns this LogEntryList after
   * removing the entries that happened before [when]; otherwise
   * a new list is created.
   */
  LogEntryList from(DateTime when, [bool inPlace = false]) =>
      _tail((e) => !e.time.isBefore(when), inPlace, 'from $when', logs.length);

  /**
   * Returns log events that happened until [when]. If [inPlace]
   * is true, then it returns this LogEntryList after removing
   * the entries that happened after [when]; otherwise a new
   * list is created.
   */
  LogEntryList until(DateTime when, [bool inPlace = false]) =>
      _head((e) => e.time.isAfter(when), inPlace, 'until $when', logs.length);

  /**
   * Returns log events that happened before [when]. If [inPlace]
   * is true, then it returns this LogEntryList after removing
   * the entries that happened from [when] onwards; otherwise a new
   * list is created.
   */
  LogEntryList before(DateTime when, [bool inPlace = false]) =>
      _head((e) => !e.time.isBefore(when),
            inPlace,
            'before $when',
            logs.length);

  /**
   * Returns log events that happened after [logEntry]'s time.
   * If [inPlace] is true, then it returns this LogEntryList after
   * removing the entries that happened up to [when]; otherwise a new
   * list is created. If [logEntry] is null the current time is used.
   */
  LogEntryList afterEntry(LogEntry logEntry, [bool inPlace = false]) =>
      after(logEntry == null ? new DateTime.now() : logEntry.time);

  /**
   * Returns log events that happened from [logEntry]'s time onwards.
   * If [inPlace] is true, then it returns this LogEntryList after
   * removing the entries that happened before [when]; otherwise
   * a new list is created. If [logEntry] is null the current time is used.
   */
  LogEntryList fromEntry(LogEntry logEntry, [bool inPlace = false]) =>
      from(logEntry == null ? new DateTime.now() : logEntry.time);

  /**
   * Returns log events that happened until [logEntry]'s time. If
   * [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened after [when]; otherwise a new
   * list is created. If [logEntry] is null the epoch time is used.
   */
  LogEntryList untilEntry(LogEntry logEntry, [bool inPlace = false]) =>
      until(logEntry == null ?
          new DateTime.fromMillisecondsSinceEpoch(0) : logEntry.time);

  /**
   * Returns log events that happened before [logEntry]'s time. If
   * [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened from [when] onwards; otherwise a new
   * list is created. If [logEntry] is null the epoch time is used.
   */
  LogEntryList beforeEntry(LogEntry logEntry, [bool inPlace = false]) =>
      before(logEntry == null ?
          new DateTime.fromMillisecondsSinceEpoch(0) : logEntry.time);

  /**
   * Returns log events that happened after the first event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened earlier; otherwise a new list is created.
   */
  LogEntryList afterFirst(LogEntryList segment, [bool inPlace = false]) =>
      afterEntry(segment.first, inPlace);

  /**
   * Returns log events that happened after the last event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened earlier; otherwise a new list is created.
   */
  LogEntryList afterLast(LogEntryList segment, [bool inPlace = false]) =>
      afterEntry(segment.last, inPlace);

  /**
   * Returns log events that happened from the time of the first event in
   * [segment] onwards. If [inPlace] is true, then it returns this
   * LogEntryList after removing the earlier entries; otherwise a new list
   * is created.
   */
  LogEntryList fromFirst(LogEntryList segment, [bool inPlace = false]) =>
      fromEntry(segment.first, inPlace);

  /**
   * Returns log events that happened from the time of the last event in
   * [segment] onwards. If [inPlace] is true, then it returns this
   * LogEntryList after removing the earlier entries; otherwise a new list
   * is created.
   */
  LogEntryList fromLast(LogEntryList segment, [bool inPlace = false]) =>
      fromEntry(segment.last, inPlace);

  /**
   * Returns log events that happened until the first event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList untilFirst(LogEntryList segment, [bool inPlace = false]) =>
      untilEntry(segment.first, inPlace);

  /**
   * Returns log events that happened until the last event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList untilLast(LogEntryList segment, [bool inPlace = false]) =>
      untilEntry(segment.last, inPlace);

  /**
   * Returns log events that happened before the first event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList beforeFirst(LogEntryList segment, [bool inPlace = false]) =>
      beforeEntry(segment.first, inPlace);

  /**
   * Returns log events that happened before the last event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList beforeLast(LogEntryList segment, [bool inPlace = false]) =>
      beforeEntry(segment.last, inPlace);

  /**
   * Iterate through the LogEntryList looking for matches to the entries
   * in [keys]; for each match found the closest [distance] neighboring log
   * entries that match [mockNameFilter] and [logFilter] will be included in
   * the result. If [isPreceding] is true we use the neighbors that precede
   * the matched entry; else we use the neighbors that followed.
   * If [includeKeys] is true then the entries in [keys] that resulted in
   * entries in the output list are themselves included in the output list. If
   * [distance] is zero then all matches are included.
   */
  LogEntryList _neighboring(bool isPreceding,
                            LogEntryList keys,
                            mockNameFilter,
                            logFilter,
                            int distance,
                            bool includeKeys) {
    String filterName = 'Calls to '
        '${qualifiedName(mockNameFilter, logFilter.toString())} '
        '${isPreceding?"preceding":"following"} ${keys.filter}';

    LogEntryList rtn = new LogEntryList(filterName);

    // Deal with the trivial case.
    if (logs.length == 0 || keys.logs.length == 0) {
      return rtn;
    }

    // Normalize the mockNameFilter and logFilter values.
    if (mockNameFilter == null) {
      mockNameFilter = anything;
    } else {
      mockNameFilter = wrapMatcher(mockNameFilter);
    }
    logFilter = _makePredicate(logFilter);

    // The scratch list is used to hold matching entries when we
    // are doing preceding neighbors. The remainingCount is used to
    // keep track of how many matching entries we can still add in the
    // current segment (0 if we are doing doing following neighbors, until
    // we get our first key match).
    List scratch = null;
    int remainingCount = 0;
    if (isPreceding) {
      scratch = new List();
      remainingCount = logs.length;
    }

    var keyIterator = keys.logs.iterator;
    keyIterator.moveNext();
    LogEntry keyEntry = keyIterator.current;
    Map matchState = {};

    for (LogEntry logEntry in logs) {
      // If we have a log entry match, copy the saved matches from the
      // scratch buffer into the return list, as well as the matching entry,
      // if appropriate, and reset the scratch buffer. Continue processing
      // from the next key entry.
      if (keyEntry == logEntry) {
        if (scratch != null) {
          int numToCopy = scratch.length;
          if (distance > 0 && distance < numToCopy) {
            numToCopy = distance;
          }
          for (var i = scratch.length - numToCopy; i < scratch.length; i++) {
            rtn.logs.add(scratch[i]);
          }
          scratch.clear();
        } else {
          remainingCount = distance > 0 ? distance : logs.length;
        }
        if (includeKeys) {
          rtn.logs.add(keyEntry);
        }
        if (keyIterator.moveNext()) {
          keyEntry = keyIterator.current;
        } else if (isPreceding) { // We're done.
          break;
        }
      } else if (remainingCount > 0 &&
                 mockNameFilter.matches(logEntry.mockName, matchState) &&
                 logFilter(logEntry)) {
        if (scratch != null) {
          scratch.add(logEntry);
        } else {
          rtn.logs.add(logEntry);
          --remainingCount;
        }
      }
    }
    return rtn;
  }

  /**
   * Iterate through the LogEntryList looking for matches to the entries
   * in [keys]; for each match found the closest [distance] prior log entries
   * that match [mocknameFilter] and [logFilter] will be included in the result.
   * If [includeKeys] is true then the entries in [keys] that resulted in
   * entries in the output list are themselves included in the output list. If
   * [distance] is zero then all matches are included.
   *
   * The idea here is that you could find log entries that are related to
   * other logs entries in some temporal sense. For example, say we have a
   * method commit() that returns -1 on failure. Before commit() gets called
   * the value being committed is created by process(). We may want to find
   * the calls to process() that preceded calls to commit() that failed.
   * We could do this with:
   *
   *      print(log.preceding(log.getLogs(callsTo('commit'), returning(-1)),
   *          logFilter: callsTo('process')).toString());
   *
   * We might want to include the details of the failing calls to commit()
   * to see what parameters were passed in, in which case we would set
   * [includeKeys].
   *
   * As another simple example, say we wanted to know the three method
   * calls that immediately preceded each failing call to commit():
   *
   *     print(log.preceding(log.getLogs(callsTo('commit'), returning(-1)),
   *         distance: 3).toString());
   */
  LogEntryList preceding(LogEntryList keys,
                         {mockNameFilter: null,
                         logFilter: null,
                         int distance: 1,
                         bool includeKeys: false}) =>
      _neighboring(true, keys, mockNameFilter, logFilter,
          distance, includeKeys);

  /**
   * Iterate through the LogEntryList looking for matches to the entries
   * in [keys]; for each match found the closest [distance] subsequent log
   * entries that match [mocknameFilter] and [logFilter] will be included in
   * the result. If [includeKeys] is true then the entries in [keys] that
   * resulted in entries in the output list are themselves included in the
   * output list. If [distance] is zero then all matches are included.
   * See [preceding] for a usage example.
   */
  LogEntryList following(LogEntryList keys,
                         {mockNameFilter: null,
                         logFilter: null,
                         int distance: 1,
                         bool includeKeys: false}) =>
      _neighboring(false, keys, mockNameFilter, logFilter,
          distance, includeKeys);
}

_MockFailureHandler _mockFailureHandler = null;

/**
 * The failure handler for the [expect()] calls that occur in [verify()]
 * methods in the mock objects. This calls the real failure handler used
 * by the unit test library after formatting the error message with
 * the custom formatter.
 */
class _MockFailureHandler implements FailureHandler {
  FailureHandler proxy;
  _MockFailureHandler(this.proxy);
  void fail(String reason) {
    proxy.fail(reason);
  }
  void failMatch(actual, Matcher matcher, String reason,
                 Map matchState, bool verbose) {
    proxy.fail(_mockingErrorFormatter(actual, matcher, reason,
        matchState, verbose));
  }
}

/**
 * The error formatter for mocking is a bit different from the default one
 * for unit testing; instead of the third argument being a 'reason'
 * it is instead a [signature] describing the method signature filter
 * that was used to select the logs that were verified.
 */
String _mockingErrorFormatter(actual, Matcher matcher, String signature,
                              Map matchState, bool verbose) {
  var description = new StringDescription();
  description.add('Expected ${signature} ').addDescriptionOf(matcher).
      add('\n     but: ');
  matcher.describeMismatch(actual, description, matchState, verbose).add('.');
  return description.toString();
}
