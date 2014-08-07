// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.src.build.wrapped_logger;

import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';
import 'package:source_span/source_span.dart';

import 'common.dart' as common;

/// A simple class to wrap one TransformLogger with another one that writes all
/// logs to a file and then forwards the calls to the child.
class WrappedLogger implements TransformLogger {
  Transform _transform;
  List<Map> _logs = new List<Map>();

  bool convertErrorsToWarnings;

  WrappedLogger(this._transform, {this.convertErrorsToWarnings: false});

  void info(String message, {AssetId asset, SourceSpan span}) {
    _transform.logger.info(message, asset: asset, span: span);
    _addLog(asset, LogLevel.INFO, message, span);
  }

  void fine(String message, {AssetId asset, SourceSpan span}) {
    _transform.logger.fine(message, asset: asset, span: span);
    _addLog(asset, LogLevel.FINE, message, span);
  }

  void warning(String message, {AssetId asset, SourceSpan span}) {
    _transform.logger.warning(message, asset: asset, span: span);
    _addLog(asset, LogLevel.WARNING, message, span);
  }

  void error(String message, {AssetId asset, SourceSpan span}) {
    if (convertErrorsToWarnings) {
      _transform.logger.warning(message, asset: asset, span: span);
    } else {
      _transform.logger.error(message, asset: asset, span: span);
    }
    _addLog(asset, LogLevel.ERROR, message, span);
  }

  /// Outputs the log data to a JSON serialized file.
  Future writeOutput() {
    return getNextLogAssetPath().then((path) {
      _transform.addOutput(new Asset.fromString(path, JSON.encode(_logs)));
    });
  }

  // Each phase outputs a new log file with an incrementing # appended, this
  // figures out the next # to use.
  Future<String> getNextLogAssetPath([int nextNumber = 1]) {
    var nextAssetPath = _transform.primaryInput.id.addExtension(
        '${common.LOG_EXTENSION}.$nextNumber');
    return _transform.hasInput(nextAssetPath).then((exists) {
      if (!exists) return nextAssetPath;
      return getNextLogAssetPath(++nextNumber);
    });
  }

  // Combines all existing ._buildLogs.* files into a single ._buildLogs file.
  static Future combineLogFiles(
      Transform transform, [int nextNumber = 1, List<Map> logs]) {
    if (logs == null) logs = new List<Map>();
    var primaryInputId = transform.primaryInput.id;
    var nextAssetPath =
        primaryInputId.addExtension('${common.LOG_EXTENSION}.$nextNumber');
    return transform.readInputAsString(nextAssetPath).then(
        (data) {
          logs.addAll(JSON.decode(data));
          return combineLogFiles(transform, ++nextNumber, logs);
        },
        onError: (_) {
          transform.addOutput(new Asset.fromString(
              primaryInputId.addExtension(common.LOG_EXTENSION),
              JSON.encode(logs)));
        });
  }

  void _addLog(AssetId assetId, LogLevel level, String message,
               SourceSpan span) {
    var data = {
        'level': level.name,
        'message': message,
    };
    if (assetId != null) {
      data['assetId'] = {
          'package': assetId.package,
          'path': assetId.path,
      };
    }
    if (span != null) {
      data['span'] = {
          'location': span.start.toolString,
          'text': new HtmlEscape().convert(span.text),
      };
    }
    _logs.add(data);
  }
}