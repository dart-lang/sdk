// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

class ProcessInfo {
  final int pid;
  final String command;
  final String script;
  final String dartBinary;
  final int rss;
  final String? tag;

  ProcessInfo({
    required this.pid,
    required this.command,
    required this.script,
    required this.dartBinary,
    required this.rss,
    this.tag,
  });

  ProcessInfo.current({String? tag})
    : this(
        pid: io.pid,
        command: io.Platform.executableArguments.join(' '),
        script: io.Platform.script.toFilePath(),
        dartBinary: io.Platform.executable,
        rss: io.ProcessInfo.currentRss,
        tag: tag,
      );

  factory ProcessInfo.fromJson(Map<String, dynamic> json) => ProcessInfo(
    pid: json['pid'] as int,
    command: json['command'] as String,
    script: json['script'] as String,
    dartBinary: json['dartBinary'] as String,
    rss: json['rss'] as int,
    tag: json['tag'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'pid': pid,
    'command': command,
    'script': script,
    'dartBinary': dartBinary,
    'rss': rss,
    if (tag != null) 'tag': tag,
  };

  @override
  String toString() {
    final tagString = tag != null ? ' (tag: $tag)' : '';
    return '[PID: $pid, script: $script, RSS: $rss]$tagString';
  }
}
