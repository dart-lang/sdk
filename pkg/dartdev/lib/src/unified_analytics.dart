// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:unified_analytics/unified_analytics.dart';

import 'sdk.dart';
import 'telemetry/project_cache.dart';
import 'telemetry/pubspec_scanner.dart';

export 'telemetry/pubspec_scanner.dart' show PubspecTelemetry;

const String _dartDirectoryName = '.dart';

const int _ttlSeconds = 60 * 60 * 24; // 24 hours

const String analyticsDisabledNoticeMessage =
    'Analytics reporting disabled. '
    'In order to enable it, run: dart --enable-analytics';

/// Safely retrieves or computes pubspec telemetry for [dir] using [cache].
///
/// If [dir] is `null`, defaults to [Directory.current].
/// If [cache] is `null`, defaults to a newly instantiated [ProjectTelemetryCache].
///
/// Uses [ProjectTelemetryCache] to avoid re-scanning on every CLI invocation.
/// Returns `null` if no pubspec is found, if the telemetry should be throttled, or if any error occurs.
PubspecTelemetry? collectPubspecTelemetry({
  Directory? dir,
  ProjectTelemetryCache? cache,
  @visibleForTesting int? nowSeconds,
}) {
  try {
    final targetDir = dir ?? Directory.current;
    final pubspecFile = findPubspecFile(targetDir);
    if (pubspecFile == null) return null;

    final rootPath = pubspecFile.parent.path;
    final projectCache = cache ?? ProjectTelemetryCache();

    final contentHash = ProjectTelemetryCache.hash(
      pubspecFile.readAsStringSync(),
    );
    final cached = projectCache.getEntry(rootPath);
    if (cached != null) {
      final now = nowSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isExpired =
          now - cached.lastSentSeconds >= _ttlSeconds ||
          now < cached.lastSentSeconds;

      if (!isExpired && cached.contentHash == contentHash) {
        return null; // Throttle telemetry if content is unchanged within 24 hours.
      }
    }

    final scanned = scanPubspecTelemetry(pubspecFile.parent);
    if (scanned != null) {
      projectCache.set(
        rootPath,
        scanned,
        contentHash: contentHash,
        nowSeconds: nowSeconds,
      );
    }
    return scanned;
  } catch (_) {
    return null;
  }
}

/// Create the `Analytics` instance to be used to report analytics.
///
/// [agent] is the name of the AI coding agent executing the tool, if any (see
/// [AiAgent.detectAgentName]).
Analytics createUnifiedAnalytics({
  bool disableAnalytics = false,
  String? agent,
}) {
  if (disableAnalytics) {
    return NoOpAnalytics();
  }
  return Analytics(
    tool: DashTool.dartTool,
    dartVersion: Runtime.runtime.version,
    agent: agent,
  );
}

/// Returns whether dartdev should print the analytics consent message for this
/// run.
///
/// [consentPending] must be read from [Analytics.shouldShowMessage] *before*
/// [Analytics.clientShowedMessage] is called, since that call clears it.
///
/// [botSuppressed] is true when running on a bot and analytics aren't being
/// explicitly tested.
bool shouldPrintConsentMessage({
  required bool consentPending,
  required bool hasTerminal,
  required bool botSuppressed,
}) => consentPending && hasTerminal && !botSuppressed;

/// Returns whether sub-tools should be suppressed (via
/// `DASH__SUPPRESS_ANALYTICS`).
///
/// Sub-tools that inherit dartdev's environment (for example, programs
/// started with `dart run`) report under the label in `DASH__TOOL`, which
/// defaults to `dart-tool`. When dartdev shows the consent message, it
/// records consent for `dart-tool` in the config file right away, but it does
/// not send anything itself for the rest of the run. Without suppression, a
/// sub-tool reporting under `dart-tool` that starts during that same run would
/// read the freshly recorded consent and start sending. So when
/// [showsConsentMessage] is true, sub-tools are suppressed for this run as
/// well. (If `DASH__TOOL` was inherited with a different label, this
/// over-suppresses for one run, which is harmless.)
///
/// When consent is pending but the message is *not* shown (for example, when
/// stdout has no terminal), nothing is recorded, so sub-tools reporting under
/// `dart-tool` still see consent as pending and won't send. They are
/// deliberately not suppressed in that case, so that a sub-tool which shows
/// its own consent prompt (such as the analysis server's LSP prompt for IDE
/// users) can still do so.
bool shouldSuppressSubtools({
  required bool suppressAnalytics,
  required bool showsConsentMessage,
}) => suppressAnalytics || showsConsentMessage;

String userHomeDir() {
  var envKey = Platform.operatingSystem == 'windows' ? 'APPDATA' : 'HOME';
  var value = Platform.environment[envKey];
  return value ?? '.';
}

/// Return the user's home directory for the current platform.
Directory? get homeDir {
  var dir = Directory(userHomeDir());
  return dir.existsSync() ? dir : null;
}

/// The directory used to store the analytics settings file.
///
/// Typically, the directory is `~/.dart/` (and the settings file is
/// `dartdev.json`).
///
/// This can return null under some conditions, including when the user's home
/// directory does not exist.
Directory? getDartStorageDirectory() {
  var dir = homeDir;
  if (dir == null) {
    return null;
  } else {
    return Directory(path.join(dir.path, _dartDirectoryName));
  }
}

/// The method used by dartdev to determine if this machine is a bot such as a
/// CI machine.
///
/// [environment] defaults to [Platform.environment].
bool isBot({Map<String, String>? environment}) =>
    Analytics.isBot(environment ?? Platform.environment);
