// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:leak_tracker/src/usage_tracking/model.dart';
import 'package:leak_tracker/src/usage_tracking/usage_tracking.dart';

void configureMemoryUsageTracking(
  List<String> arguments,
  UsageCallback callback,
) {
  final config = UsageTrackingConfig(
    interval: const Duration(seconds: 1),
    usageEventsConfig: UsageEventsConfig(
      callback,
      deltaMb: 512,
    ),
    autoSnapshottingConfig: parseAutoSnapshottingConfig(arguments),
  );
  trackMemoryUsage(config);
}

/// Parses the config for autosnapshotting from CLI [args].
///
/// See example of config in tests for this function.
///
/// If there is no argument that starts with '--autosnapshotting=', returns null.
///
/// In case of error throws exception.
AutoSnapshottingConfig? parseAutoSnapshottingConfig(List<String> args) {
  const argName = 'autosnapshotting';
  var arg = args.firstWhereOrNull((a) => a.startsWith('$argName-'));

  if (arg == null) return null;

  arg = arg.replaceAll('-', '=');
  arg = '--$arg';

  var parser = ArgParser()..addMultiOption(argName, splitCommas: true);
  final parsedArgs = parser.parse([arg]);
  assert(parsedArgs.options.contains(argName));
  final values = parsedArgs[argName] as List<String>;

  if (values.isEmpty) return null;

  final items = Map.fromEntries(values.map((e) {
    final keyValue = e.split('=');
    if (keyValue.length != 2) {
      throw ArgumentError(
        'Invalid auto-snapshotting config: $values.\n'
        'Expected "key-value", got "$e".',
      );
    }
    final keyString = keyValue[0];
    try {
      final key = _Keys.values.byName(keyString);

      return MapEntry(key, keyValue[1]);
    } on ArgumentError {
      throw ArgumentError('Invalid auto-snapshotting key: $keyString".');
    }
  }));
  if (!items.containsKey(_Keys.dir)) {
    throw ArgumentError(
        '${_Keys.dir.name} should be provided for auto-snapshotting.');
  }
  return AutoSnapshottingConfig(
    thresholdMb: _parseKey(_Keys.thresholdMb, items, 7000),
    increaseMb: _parseKey(_Keys.increaseMb, items, 500),
    directory: items[_Keys.dir]!,
    directorySizeLimitMb: _parseKey(_Keys.dirLimitMb, items, 30000),
    minDelayBetweenSnapshots: Duration(
      seconds: _parseKey(_Keys.delaySec, items, 20),
    ),
  );
}

int _parseKey(_Keys key, Map<_Keys, String> items, int defaultValue) {
  final value = items[key];
  if (value == null || value.trim().isEmpty) return defaultValue;
  final result = int.tryParse(value);
  if (result == null) {
    throw ArgumentError(
        'Invalid auto-snapshotting value for ${key.name}: $value.');
  }
  return result;
}

enum _Keys {
  thresholdMb,
  increaseMb,
  dir,
  dirLimitMb,
  delaySec,
}
