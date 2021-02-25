// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:usage/usage.dart';

/// The [String] identifier `dartdev`, used as the category in the events sent
/// to analytics.
const String _dartdev = 'dartdev';

/// The collection of custom dimensions understood by the analytics backend.
/// When adding to this list, first ensure that the custom dimension is defined
/// in the backend (or will be defined shortly after the relevant PR lands).
///
/// The pattern here matches the flutter cli.
///
/// Note: do not re-order the elements in this enum!
enum _CustomDimensions {
  commandExitCode, // cd1
  enabledExperiments, // cd2
  commandFlags, // cd3
}

String _cdKey(_CustomDimensions cd) => 'cd${cd.index + 1}';

Map<String, String> _useCdKeys(Map<_CustomDimensions, String> parameters) {
  return parameters.map(
    (_CustomDimensions k, String v) => MapEntry<String, String>(_cdKey(k), v),
  );
}

/// Sends a usage event on [analytics].
///
/// [command] is the top-level command name being executed here, 'analyze' and
/// 'pub' are examples.
///
/// [action] is the command, and optionally the subcommand, joined with '/',
/// an example here is 'pub/get'.
///
/// [label] is not used yet used when reporting dartdev analytics, but the API
/// is included here for possible future use.
///
/// [exitCode] is the exit code returned from this invocation of dartdev.
///
/// [specifiedExperiements] are the experiments passed into the dartdev
/// command. If the command doesn't use the experiments, they are not reported.
///
/// [commandFlags] are the flags (no values) used to run this command.
Future<void> sendUsageEvent(
  Analytics analytics,
  String action, {
  String label,
  List<String> specifiedExperiments,
  @required int exitCode,
  @required List<String> commandFlags,
}) {
  /// The category stores the name of this cli tool, 'dartdev'. This matches the
  /// pattern from the flutter cli tool which always passes 'flutter' as the
  /// category.
  final category = _dartdev;
  commandFlags =
      commandFlags?.where((e) => e != 'enable-experiment')?.toList() ?? [];
  specifiedExperiments = specifiedExperiments?.toList() ?? [];

  // Sort the flag lists to slightly reduce the explosion of possibilities.
  commandFlags..sort();
  specifiedExperiments.sort();

  // Insert a seperator before and after the flags list to make it easier to filter
  // for a specific flag:
  final enabledExperimentsString = ' ${specifiedExperiments.join(' ')} ';
  final commandFlagsString = ' ${commandFlags.join(' ')} ';

  final Map<String, String> parameters = _useCdKeys(<_CustomDimensions, String>{
    if (exitCode != null)
      _CustomDimensions.commandExitCode: exitCode.toString(),
    if (specifiedExperiments.isNotEmpty)
      _CustomDimensions.enabledExperiments: enabledExperimentsString,
    if (commandFlags.isNotEmpty)
      _CustomDimensions.commandFlags: commandFlagsString,
  });
  return analytics.sendEvent(
    category,
    action,
    label: label,
    parameters: parameters,
  );
}
