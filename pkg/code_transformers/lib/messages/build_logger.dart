// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.messages.messages_logger;

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:barback/barback.dart';
import 'package:source_span/source_span.dart';

import 'messages.dart' show Message, MessageId, BuildLogEntry, LogEntryTable;

/// A [TransformLogger] used to track error and warning messages produced during
/// a build.
///
/// This logger records all messages that were logged and then forwards
/// the calls to an underlying [TransformLogger]. The internal records support
/// serializing the errors and emiting them to an asset (so they can be
/// presented to the user in a web-based client), clustering similar messages
/// together, sorting messages in order of importance, etc.
///
/// The logger also supports reporting error messages as warnings. Barback makes
/// error messages stop the transformation process, which sometimes can surprise
/// users. Turning errors into warnings is especially useful when used within
/// `pub serve`, where we would like the transformation to continue as far as it
/// can. When this flag is turned on, the level is still recorded as an error,
/// so a web client UI can still highlight their importance.
// TODO(sigmund): also cluster messages when they are reported on the
// command-line.
class BuildLogger implements TransformLogger {
  /// Underling transform that is currently active.
  final Transform _transform;

  /// Logs created during the current transform.
  final LogEntryTable _logs = new LogEntryTable();

  /// Whether to use `warning` or `error` when forwarding error messages to the
  /// underlying logger in `_transform.logger`.
  final bool convertErrorsToWarnings;

  /// Uri prefix to link for additional details. If set, messages logged through
  /// this logger will contain an additional sentence, telling users to find
  /// more details at `$detailsUri#packagename_id`.
  final String detailsUri;

  BuildLogger(this._transform, {this.convertErrorsToWarnings: false,
      this.detailsUri});

  /// Records a message at the fine level. If [msg] is a [Message] it is
  /// recorded directly, otherwise it is first converted to a [String].
  void fine(msg, {AssetId asset, SourceSpan span}) {
    msg = msg is Message ? msg : new Message.unknown('$msg');
    _transform.logger.fine(_snippet(msg), asset: asset, span: span);
    _logs.add(new BuildLogEntry(msg, span, LogLevel.FINE.name));
  }

  /// Records a message at the info level. If [msg] is a [Message] it is
  /// recorded directly, otherwise it is first converted to a [String].
  void info(msg, {AssetId asset, SourceSpan span}) {
    msg = msg is Message ? msg : new Message.unknown('$msg');
    _transform.logger.info(_snippet(msg), asset: asset, span: span);
    _logs.add(new BuildLogEntry(msg, span, LogLevel.INFO.name));
  }

  /// Records a warning message. If [msg] is a [Message] it is recorded
  /// directly, otherwise it is first converted to a [String].
  void warning(msg, {AssetId asset, SourceSpan span}) {
    msg = msg is Message ? msg : new Message.unknown('$msg');
    _transform.logger.warning(_snippet(msg), asset: asset, span: span);
    _logs.add(new BuildLogEntry(msg, span, LogLevel.WARNING.name));
  }

  /// Records an error message. If [msg] is a [Message] it is recorded
  /// directly, otherwise it is first converted to a [String].
  void error(msg, {AssetId asset, SourceSpan span}) {
    msg = msg is Message ? msg : new Message.unknown('$msg');
    if (convertErrorsToWarnings) {
      _transform.logger.warning(_snippet(msg), asset: asset, span: span);
    } else {
      _transform.logger.error(_snippet(msg), asset: asset, span: span);
    }
    _logs.add(new BuildLogEntry(msg, span, LogLevel.ERROR.name));
  }

  String _snippet(Message msg) {
    var s = msg.snippet;
    if (detailsUri == null) return s;
    var dot = s.endsWith('.') || s.endsWith('!') || s.endsWith('?') ? '' : '.';
    var hashTag = '${msg.id.package}_${msg.id.id}';
    return '$s$dot See $detailsUri#$hashTag for details.';
  }

  /// Outputs the log data to a JSON serialized file.
  Future writeOutput() {
    return _getNextLogAssetPath().then((path) {
      _transform.addOutput(new Asset.fromString(path,
          JSON.encode(_logs)));
    });
  }

  // Each phase outputs a new log file with an incrementing # appended, this
  // figures out the next # to use.
  Future<String> _getNextLogAssetPath([int nextNumber = 1]) {
    var nextAssetPath = _transform.primaryInput.id.addExtension(
        '${LOG_EXTENSION}.$nextNumber');
    return _transform.hasInput(nextAssetPath).then((exists) {
      if (!exists) return nextAssetPath;
      return _getNextLogAssetPath(++nextNumber);
    });
  }

  // Reads all log files for an Asset into [logs].
  static Future _readLogFilesForAsset(AssetId id, Transform transform,
      LogEntryTable entries, [nextNumber = 1]) {
    var nextAssetPath = id.addExtension('${LOG_EXTENSION}.$nextNumber');
    return transform.hasInput(nextAssetPath).then((exists) {
      if (!exists) return null;
      return transform.readInputAsString(nextAssetPath).then((data) {
        entries.addAll(new LogEntryTable.fromJson(JSON.decode(data)));
        return _readLogFilesForAsset(id, transform, entries, ++nextNumber);
      });
    });
  }

  // Combines all existing ._buildLogs.* files into a single ._buildLogs file.
  static Future combineLogFiles(Transform transform) {
    var entries = new LogEntryTable();
    var id = transform.primaryInput.id;
    return _readLogFilesForAsset(id, transform, entries).then((_) {
      return transform.addOutput(new Asset.fromString(
          id.addExtension(LOG_EXTENSION),
          JSON.encode(entries.toJson())));
    });
  }

  // Reads all logs for an asset and adds them to this loggers log output.
  Future addLogFilesFromAsset(AssetId id, [int nextNumber = 1]) {
    return _readLogFilesForAsset(id, _transform, _logs);
  }
}

/// Extension used for assets that contained serialized logs.
const String LOG_EXTENSION = '._buildLogs';
