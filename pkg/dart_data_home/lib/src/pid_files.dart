// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// Create a pid file for the current process in the [directory] with [content].
///
/// This function will additionally purge any stale pid files in the
/// [directory].
///
/// Returns `true` if pid file was successfully created.
///
/// Throws an error if a pid file for the current process have been already
/// created.
bool createPidFile(String directory, String content) {
  if (_pidFile != null) {
    throw StateError('Already created pid file for the current process');
  }
  try {
    final dataDir = Directory(directory);
    dataDir.createSync(recursive: true);
    final pidFile = File(p.join(dataDir.path, '$pid'));
    // It is extremely unlikely that we retry this more than couple of times,
    // but it is possible to hit this case if another process is constantly
    // calling _purgeStalePidFiles which consistently deletes the pid file we
    // are creating.
    for (var attempt = 0; attempt < 10 && _pidFile == null; attempt++) {
      RandomAccessFile? raf;
      try {
        raf = pidFile.openSync(mode: FileMode.writeOnly);
        // On Windows it is enough to keep the file open to prevent its deletion
        // by another process, so we do not need to lock it. On POSIX systems
        // we use advisory file locks instead to synchronize between one process
        // creating a pid-file and another process trying to check if the
        // pid-file is stale or not (see _purgeStalePidFiles below).
        if (!Platform.isWindows) {
          raf.lockSync();
        }
        raf
          ..writeStringSync(content)
          ..flushSync();
        // On Windows we are good to go: keep the file open so that
        // _purgeStalePidFiles can detect that the file is not stale.
        //
        // On POSIX we need to check if open followed by lock has raced
        // with another process deleting a stale pid-file: another process
        // might have opened - locked - deleted - unlocked the file after
        // we opened it but before we locked it. This way we end up with a
        // file descriptor corresponding to a deleted file. Check that
        // the path still exists - if it does not, retry pid file creation.
        //
        // Caveat: we must never open pid file corresponding to the current
        // process because closing it again will release all file locks
        // acquired by the current process and break the logic in
        // _purgeStalePidFiles - even though we have another file descriptor
        // for the same file still open in the current process.
        if (Platform.isWindows || pidFile.existsSync()) {
          // We have successfully created a pid file for the current process.
          // Keep the file open to keep the lock on the file so that
          // _purgeStalePidFiles can detect that the file is not stale.
          _pidFile = raf;
        }
      } catch (e) {
        // Ignore
      } finally {
        // We lost the race: We created file but before we could lock it another
        // process deleted it.
        //
        // We have to close our fd, and try again in next loop iteration.
        if (raf != _pidFile) {
          raf?.closeSync();
        }
      }
    }
    _purgeStalePidFiles(dataDir);
  } catch (_) {}

  return _pidFile != null;
}

/// Loads content of all pid files in the given [directory] excluding the pid
/// file of the current process.
///
/// Returns a map where keys are pids and values are content of the pid file.
///
/// This function will purge all stale pid files in the [directory].
Map<int, String> listPidFiles(String directory) {
  final currentPid = pid;
  final result = <int, String>{};
  try {
    final dataDir = Directory(directory);
    if (dataDir.existsSync()) {
      _purgeStalePidFiles(dataDir);
      for (final file in dataDir.listSync().whereType<File>()) {
        final pid = int.tryParse(p.basename(file.path));
        if (pid == null || pid == currentPid) {
          continue;
        }
        try {
          // Caveat: on POSIX systems must never read the pid file
          // corresponding to the current process because reading it will
          // open and close it - and closing it will release all file
          // locks associated with this file held by the current process even
          // if they were acquired through other still open file descriptors
          // and this will break the logic _purgeStalePidFiles.
          //
          // It's okay to read pid files of other processes though as this
          // will not affect locks held by other processes.
          assert(pid != currentPid);
          result[pid] = file.readAsStringSync();
        } catch (_) {}
      }
    }
  } catch (_) {}
  return result;
}

RandomAccessFile? _pidFile;

/// Purge all stale pid files in the given [dir] except for the one
/// corresponding to the current process.
void _purgeStalePidFiles(Directory dir) {
  final currentPid = pid;
  for (final file in dir.listSync().whereType<File>()) {
    final pid = int.tryParse(p.basename(file.path));
    if (pid == null || pid == currentPid) {
      continue;
    }

    RandomAccessFile? raf;
    try {
      // On Windows we rely on the fact that deleting a file can only succeed
      // if no process has it open. The original process which created pid
      // file will keep it open for write - so trying to delete it will fail
      // as long as the process is alive.
      //
      // On POSIX we use file locks to detect if PID file is stale or not:
      // original owner keeps the file locked until it exits. This means
      // that if we manage to lock the file - the owner has exited.
      if (!Platform.isWindows) {
        raf = file.openSync(mode: FileMode.writeOnlyAppend);
        raf.lockSync();
      }
      file.deleteSync();
    } catch (_) {
      // Ignore any exceptions.
    } finally {
      raf?.closeSync();
    }
  }
}
