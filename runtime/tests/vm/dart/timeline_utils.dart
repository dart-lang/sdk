// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;

import 'snapshot_test_helper.dart';

Future<List<TimelineEvent>> runAndCollectTimeline(
    String streams, List<String> args) async {
  return await withTempDir((String tmp) async {
    final String timelinePath = path.join(tmp, 'timeline.json');
    final p = await Process.run(Platform.executable, [
      ...Platform.executableArguments,
      '--trace_timeline',
      '--timeline_recorder=file:$timelinePath',
      '--timeline_streams=$streams',
      Platform.script.toFilePath(),
      ...args,
    ]);
    print(p.stdout);
    print(p.stderr);
    if (p.exitCode != 0) {
      throw 'Child process failed: ${p.exitCode}';
    }
    // On Android, --trace_timeline goes to syslog instead of stderr.
    if (!Platform.isAndroid) {
      if (!p.stderr.contains('Using the File timeline recorder')) {
        throw 'Failed to select file recorder';
      }
    }

    final timeline = jsonDecode(await new File(timelinePath).readAsString());
    if (timeline is! List) throw 'Timeline should be a JSON list';

    return parseTimeline(timeline);
  });
}

List<TimelineEvent> parseTimeline(List l) {
  final events = <TimelineEvent>[];

  for (final event in l) {
    events.add(TimelineEvent.from(event));
  }
  return events;
}

String findMainIsolateId(List<TimelineEvent> events) {
  return events
      .firstWhere((e) =>
          e.name == 'InitializeIsolate' && e.args['isolateName'] == 'main')
      .isolateId!;
}

class TimelineEvent {
  final String name;
  final String cat;
  final int tid;
  final int pid;
  final int ts;
  final int? tts;
  final String ph;
  final Map<String, String> args;

  TimelineEvent._(this.name, this.cat, this.tid, this.pid, this.ts, this.tts,
      this.ph, this.args);

  factory TimelineEvent.from(Map m) {
    return TimelineEvent._(
      m['name'] as String,
      m['cat'] as String,
      m['tid'] as int,
      m['pid'] as int,
      m['ts'] as int,
      m['tts'] as int?,
      m['ph'] as String,
      m['args'].cast<String, String>(),
    );
  }

  bool get isStart => ph == 'B';
  bool get isEnd => ph == 'E';

  String? get isolateId => args['isolateId'];

  String toString() =>
      'TimelineEvent($name, $cat, $tid, $pid, $ts, $tts, $ph, $args)';
}
