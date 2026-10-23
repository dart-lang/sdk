// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'engines.dart';
import 'gerrit.dart';
import 'git.dart';
import 'notifier.dart';
import 'process.dart';
import 'tool_proxy.dart';
import 'upstream.dart';
import 'version.dart';

/// The Gerrit hashtag identifying roll CLs uploaded by this tool.
const _rollHashtag = 'browser-roll';

/// How often to check normally, and after [_quietPeriod] without progress.
const _fastPoll = Duration(minutes: 1);
const _slowPoll = Duration(hours: 1);
const _quietPeriod = Duration(hours: 3);

/// Settings for a [BrowserRoller] run.
final class RollerOptions {
  /// The engines to consider rolling.
  final List<Engine> engines;

  /// Report what would happen without requesting builds or uploading CLs.
  final bool dryRun;

  /// Roll to any newer version, ignoring each engine's [RollPolicy].
  final bool ignoreCadence;

  /// Reviewers for roll CLs, in addition to the MPA approvers.
  final List<String> reviewers;

  RollerOptions({
    required this.engines,
    required this.dryRun,
    required this.ignoreCadence,
    required this.reviewers,
  });
}

/// Rolls the browsers and JS engines pinned in DEPS to newer versions:
///
/// 1. Compare each DEPS pin with the latest upstream release and the
///    engine's roll policy.
/// 2. Request CIPD packaging builds through the tool proxy for any new
///    versions whose packages are missing, and wait for them to finish.
/// 3. Upload a single CL updating DEPS, and wait for it to be approved and
///    land.
final class BrowserRoller {
  final GitCheckout checkout;
  final Upstream upstream;
  final ToolProxy toolProxy;
  final Gerrit gerrit;
  final Notifier notifier;
  final RollerOptions options;

  bool _hadErrors = false;

  BrowserRoller({
    required this.checkout,
    required this.upstream,
    required this.toolProxy,
    required this.gerrit,
    required this.notifier,
    required this.options,
  });

  /// Rolls the engines and returns whether it completed without errors.
  Future<bool> run() async {
    if (!options.dryRun) await _waitForCredentials();
    await checkout.fetchUpstream();
    final deps = DepsFile(await checkout.readUpstreamDeps());
    final statuses = await _collectStatuses(deps);
    _printStatuses(statuses);

    final rollable = [
      for (final status in statuses)
        if (status.shouldRoll) status,
    ];
    if (rollable.isEmpty) {
      print('Nothing to roll.');
      return !_hadErrors;
    }

    final existingChange = await _existingRollChange();
    if (existingChange != null) {
      if (!options.dryRun) await _waitForLanding(existingChange);
      return !_hadErrors;
    }

    final (ready, requests) = await _resolvePackages(rollable);
    final newChange = await _uploadIfReady(ready, requests);
    if (newChange != null) await _waitForLanding(newChange);
    return !_hadErrors;
  }

  // Step 1: compare pins with upstream releases.

  /// Returns the status of each engine in [RollerOptions.engines].
  ///
  /// Engines that follow another engine's version are evaluated after it.
  /// A followed engine is evaluated even if it wasn't selected, but it is
  /// only rolled if it was.
  Future<List<EngineStatus>> _collectStatuses(DepsFile deps) async {
    final selected = options.engines;
    final upstreamStatuses = {
      for (final status in await Future.wait([
        for (final engine in {for (final e in selected) e.versionLeader})
          if (engine.source case final UpstreamReleases source)
            _upstreamStatusOrNull(engine, source, deps),
      ]))
        if (status != null) status.engine: status,
    };
    return [
      for (final engine in selected)
        switch (engine.source) {
          UpstreamReleases() => upstreamStatuses[engine],
          SameVersionAs(:final leader) => switch (upstreamStatuses[leader]) {
              final leaderStatus? =>
                _followerStatus(engine, leaderStatus, deps),
              null => null,
            },
        },
    ].nonNulls.toList();
  }

  Future<EngineStatus?> _upstreamStatusOrNull(
    Engine engine,
    UpstreamReleases source,
    DepsFile deps,
  ) async {
    try {
      final current = engine.pinnedVersion(deps);
      final latest = await source.fetchLatest(upstream, current);
      return EngineStatus(
        engine: engine,
        current: current,
        latest: latest,
        holdReason: await _holdReason(
          engine,
          source.policy,
          current,
          latest.version,
        ),
      );
    } catch (e) {
      await _reportFailure(
        'failed to check ${engine.displayName}',
        details: '$e',
      );
      return null;
    }
  }

  /// Returns why rolling [engine] from [current] to [latest] should wait, or
  /// `null` if it should roll now.
  Future<String?> _holdReason(
    Engine engine,
    RollPolicy policy,
    Version current,
    Version latest,
  ) async {
    if (!(latest > current)) return 'up to date';
    if (options.ignoreCadence) return null;
    final pinAge = await checkout.depsVarAge(engine.depsVar);
    return policy.holdReason(current, latest, pinAge);
  }

  /// Returns the status of [engine], which pins the same version as the
  /// engine of [leader].
  ///
  /// It rolls to the leader's new version when the leader rolls, and
  /// otherwise catches up to the leader's current pin if it fell behind.
  EngineStatus _followerStatus(
    Engine engine,
    EngineStatus leader,
    DepsFile deps,
  ) {
    final current = engine.pinnedVersion(deps);
    final leaderRolls =
        leader.shouldRoll && options.engines.contains(leader.engine);
    final target = leaderRolls ? leader.target : leader.current;
    return EngineStatus(
      engine: engine,
      current: current,
      latest: Release(target),
      holdReason: target > current
          ? null
          : 'up to date with ${leader.engine.displayName}',
    );
  }

  void _printStatuses(List<EngineStatus> statuses) {
    for (final status in statuses) {
      final versions = '${status.current} -> ${status.target}';
      final decision = status.holdReason ?? 'ROLL';
      print('${status.engine.name.padRight(8)} ${versions.padRight(36)} '
          '$decision');
    }
  }

  // Step 2: make sure the CIPD packages exist.

  /// Requests packaging builds for engines in [rollable] whose CIPD packages
  /// are missing, waits for those builds to finish, and returns the engines
  /// whose packages are ready to roll (along with the build requests).
  ///
  /// Engines with the same [Engine.versionLeader] are only ready once all of
  /// their packages exist, so that they roll in the same CL.
  Future<(List<EngineStatus>, List<BuildRequest>)> _resolvePackages(
    List<EngineStatus> rollable,
  ) async {
    final missingPackages = await Future.wait([
      for (final status in rollable) status.missingCipdPackages(),
    ]);
    final withPackages = <EngineStatus>[];
    final needBuilds = <EngineStatus>[];
    for (final (i, status) in rollable.indexed) {
      if (missingPackages[i].isEmpty) {
        withPackages.add(status);
      } else {
        print('${status.engine.name} ${status.target}: missing CIPD packages '
            '${missingPackages[i].join(', ')}');
        needBuilds.add(status);
      }
    }
    final pending = await _requestBuilds(needBuilds);
    try {
      withPackages.addAll(await _waitForBuilds(pending));
    } finally {
      for (final request in pending) {
        request.kill();
      }
    }
    final missing = [
      for (final status in rollable)
        if (!withPackages.contains(status)) status.engine,
    ];
    final ready = [
      for (final status in withPackages)
        if (!_isWaitingOnLinkedEngine(status.engine, missing)) status,
    ];
    return (ready, pending);
  }

  /// Starts CIPD packaging builds for [statuses], posts all of their MPA
  /// approval links in a single message, and returns the requests that may
  /// still produce packages.
  Future<List<BuildRequest>> _requestBuilds(List<EngineStatus> statuses) async {
    if (statuses.isEmpty) return const [];
    if (options.dryRun) {
      for (final status in statuses) {
        print('[dry-run] Would request a CIPD build of ${status.buildName}.');
      }
      return const [];
    }
    await _waitForCredentials(minRemaining: const Duration(hours: 1));
    final requests = await Future.wait([
      for (final status in statuses) toolProxy.startBuild(status),
    ]);
    final approvalUrls = await Future.wait([
      for (final request in requests) request.waitForApprovalUrl(),
    ]);
    final approvals = <String>[];
    for (final (i, url) in approvalUrls.indexed) {
      if (url == null) continue;
      final status = requests[i].status;
      print('${status.buildName}: MPA approval needed at $url');
      approvals.add('• ${status.rollSummary}: $url');
    }
    if (approvals.isNotEmpty) {
      await notifier.post('MPA approval needed to build the CIPD packages '
          'for a browser roll:\n${approvals.join('\n')}');
    }
    final pending = <BuildRequest>[];
    for (final request in requests) {
      if (request.approvalUrl != null || request.exitCode == 0) {
        pending.add(request);
      } else if (request.exitCode != null) {
        await _reportRequestFailure(request);
      } else {
        await _reportFailure(
          'no MPA link for the ${request.status.buildName} CIPD build',
          details: 'tool-proxy-cli is still running but has not printed an '
              'approval link yet.\n\n${request.outputTail()}',
        );
        pending.add(request);
      }
    }
    return pending;
  }

  /// Polls until every build in [pending] either produces its CIPD packages
  /// or fails, returning the engines whose packages are ready.
  Future<List<EngineStatus>> _waitForBuilds(List<BuildRequest> pending) async {
    if (pending.isEmpty) return const [];
    await notifier.flush();
    print('Waiting for the CIPD builds of '
        '${pending.map((r) => r.status.buildName).join(', ')}.');
    final ready = <EngineStatus>[];
    final remaining = pending.toList();
    final triggered = <BuildRequest>{};
    var lastProgress = DateTime.now();
    while (remaining.isNotEmpty) {
      await _sleep(lastProgress);
      for (final request in remaining.toList()) {
        final status = request.status;
        if (request.exitCode == 0 && triggered.add(request)) {
          print('${status.buildName}: MPA request approved, build triggered.');
          lastProgress = DateTime.now();
        }
        if ((await status.missingCipdPackages()).isEmpty) {
          print('${status.buildName}: CIPD packages are available.');
          request.kill();
          ready.add(status);
          remaining.remove(request);
          lastProgress = DateTime.now();
        } else if (request.exitCode case final code? when code != 0) {
          await _reportRequestFailure(request);
          remaining.remove(request);
          lastProgress = DateTime.now();
        } else if (request.hasTimedOut) {
          await _reportBuildTimeout(status);
          remaining.remove(request);
          lastProgress = DateTime.now();
        }
      }
    }
    return ready;
  }

  /// Whether [engine] must wait for a linked engine in [missing].
  bool _isWaitingOnLinkedEngine(Engine engine, Iterable<Engine> missing) {
    final blocking = [
      for (final other in missing)
        if (other.versionLeader == engine.versionLeader) other.name,
    ];
    if (blocking.isEmpty) return false;
    print('${engine.name}: waiting for ${blocking.join(', ')} CIPD packages '
        'so they roll together.');
    return true;
  }

  Future<void> _reportRequestFailure(BuildRequest request) => _reportFailure(
        'requesting the ${request.status.buildName} CIPD build failed',
        details: 'tool-proxy-cli exited with code '
            '${request.exitCode ?? 'unknown'}.\n\n'
            '${request.outputTail()}',
      );

  Future<void> _reportBuildTimeout(EngineStatus status) => _reportFailure(
        'the ${status.buildName} CIPD build did not produce packages',
        details: 'The build was triggered but its CIPD packages are still '
            'missing.\n'
            'Builders: https://ci.chromium.org/ui/p/dart-internal/builders/'
            'ci/${status.engine.name}',
      );

  // Step 3: upload the DEPS roll and wait for it to land.

  Future<GerritChange?> _existingRollChange() async {
    final open = await gerrit.openChanges(hashtag: _rollHashtag);
    if (open.isEmpty) return null;
    print('Not uploading a roll while one is open: ${open.join(', ')}');
    return open.first;
  }

  /// Uploads a CL rolling [rolls] on top of the latest `origin/main` and
  /// returns it, or `null` if [rolls] is empty or in a dry run.
  Future<GerritChange?> _uploadIfReady(
    List<EngineStatus> rolls,
    List<BuildRequest> requests,
  ) async {
    if (rolls.isEmpty) return null;
    final message = _rollCommitMessage(rolls);
    if (options.dryRun) {
      print('[dry-run] Would upload a CL with reviewers '
          '[${options.reviewers.join(', ')}] and message:\n\n$message');
      return null;
    }
    await _waitForCredentials();
    final existing = await _existingRollChange();
    if (existing != null) return existing;

    // Re-fetch origin/main in case commits landed while waiting for builds.
    await checkout.fetchUpstream();
    final deps = DepsFile(await checkout.readUpstreamDeps());
    final updatedDeps = rolls.fold(
      deps,
      (deps, roll) => roll.engine.withPinnedVersion(deps, roll.target),
    );
    if (updatedDeps.contents == deps.contents) {
      print('DEPS on origin/main is already up to date.');
      return null;
    }
    final reviewers = {
      ...options.reviewers,
      ...await _buildApprovers(rolls, requests),
    };
    final change = await gerrit.uploadDepsChange(
      checkout: checkout,
      depsContents: updatedDeps.contents,
      commitMessage: message,
      reviewers: reviewers,
      hashtags: const ['web', _rollHashtag],
    );
    await notifier.post('Browser roll CL ready for review: ${change.url}\n'
        '${rolls.map((roll) => '• ${roll.rollSummary}').join('\n')}');
    return change;
  }

  /// Returns who approved the MPA requests for the CIPD builds of [rolls].
  ///
  /// Rolls whose packages were already built have no approver. Lookup
  /// failures are printed but don't block the roll.
  Future<Set<String>> _buildApprovers(
    List<EngineStatus> rolls,
    List<BuildRequest> requests,
  ) async {
    final approvers = <String>{};
    for (final request in requests) {
      if (!rolls.contains(request.status)) continue;
      try {
        approvers.addAll(await request.approvers());
      } on Exception catch (e) {
        print('Could not look up MPA approvers for '
            '${request.status.buildName}: $e');
      }
    }
    return approvers;
  }

  /// Polls [change] until it lands or is abandoned, reporting failed CQ runs
  /// (including the dry run started on upload) and sending it to the commit
  /// queue once it is approved.
  ///
  /// The CL has Auto-Submit, which normally sends it to the commit queue on
  /// approval; this makes sure it gets there even if that doesn't happen. A
  /// failed full run is never retried automatically, so a human can decide
  /// whether to fix and re-queue the CL or abandon it.
  Future<void> _waitForLanding(GerritChange change) async {
    await notifier.flush();
    print('Waiting for $change to be approved and land.');
    var lastProgress = DateTime.now();
    var reachedCommitQueue = false;
    final reportedFailures = <String>{};
    (bool, bool)? lastSeen;
    while (true) {
      if (await _reviewStateOrNull(change) case final state?) {
        switch (state.status) {
          case ChangeStatus.merged:
            print('$change landed.');
            await notifier.post('✅ Browser roll CL landed: $change');
            return;
          case ChangeStatus.abandoned:
            print('$change was abandoned.');
            return;
          case ChangeStatus.open:
            break;
        }
        for (final failure in state.cqFailures) {
          if (reportedFailures.add(failure.id)) {
            await _reportCqFailure(change, failure);
            lastProgress = DateTime.now();
          }
        }
        final seen = (state.approved, state.inCommitQueue);
        if (lastSeen != null && seen != lastSeen) lastProgress = DateTime.now();
        lastSeen = seen;
        reachedCommitQueue = reachedCommitQueue ||
            state.inCommitQueue ||
            state.cqFailures.any((failure) => !failure.dryRun);
        if (state.approved && !reachedCommitQueue) {
          reachedCommitQueue = true;
          if (!await _sendToCommitQueue(change)) return;
        }
      }
      await _sleep(lastProgress);
    }
  }

  Future<void> _reportCqFailure(GerritChange change, CqFailure failure) =>
      _reportFailure(
        failure.dryRun
            ? 'the roll CL failed the CQ dry run'
            : 'the roll CL failed the CQ',
        details: '$change\n\n${failure.reason}\n\n'
            'Still waiting for the CL to land. Fix the failures and vote '
            'Commit-Queue+2 to retry, or abandon it.',
      );

  Future<ReviewState?> _reviewStateOrNull(GerritChange change) async {
    try {
      return await gerrit.reviewState(change);
    } on Exception catch (e) {
      print('Could not check $change: $e');
      return null;
    }
  }

  /// Votes Commit-Queue+2 on [change], returning whether it succeeded.
  Future<bool> _sendToCommitQueue(GerritChange change) async {
    print('$change was approved; sending it to the commit queue.');
    await _waitForCredentials();
    try {
      await gerrit.sendToCommitQueue(checkout, change);
      return true;
    } on ProcessFailure catch (e) {
      await _reportFailure(
        'could not send the roll CL to the commit queue',
        details: '$change\n\n$e',
      );
      return false;
    }
  }

  /// Sleeps between poll checks: every [_fastPoll] normally, or every
  /// [_slowPoll] once nothing has changed for [_quietPeriod].
  Future<void> _sleep(DateTime lastProgress) {
    final quiet = DateTime.now().difference(lastProgress) >= _quietPeriod;
    return Future<void>.delayed(quiet ? _slowPoll : _fastPoll);
  }

  /// Waits until LOAS credentials (`gcert`) are valid for at least
  /// [minRemaining], checking every [_fastPoll].
  Future<void> _waitForCredentials({
    Duration minRemaining = const Duration(minutes: 5),
  }) async {
    if (await hasLoasCredentials(minRemaining: minRemaining)) return;
    print('LOAS credentials have expired; waiting for `gcert` to be renewed.');
    while (!await hasLoasCredentials(minRemaining: minRemaining)) {
      await Future<void>.delayed(_fastPoll);
    }
    print('LOAS credentials renewed; resuming.');
  }

  /// Posts a failure to the run's chat thread and fails the run.
  Future<void> _reportFailure(String summary, {String? details}) async {
    _hadErrors = true;
    await notifier.reportFailure(summary, details: details);
  }
}

/// The commit message of a CL rolling [rolls], including the trybots for
/// just the engines being rolled.
String _rollCommitMessage(List<EngineStatus> rolls) {
  final names = [for (final roll in rolls) roll.engine.displayName];
  final trybots = {for (final roll in rolls) ...roll.engine.trybots};
  final subjectNames = switch (names) {
    [final only] => only,
    [...final head, final last] => '${head.join(', ')} and $last',
    [] => '',
  };
  return [
    '[web] Update $subjectNames versions in DEPS',
    '',
    for (final roll in rolls)
      '${roll.engine.depsVar}: ${roll.current} -> ${roll.target}',
    '',
    'Uploaded by tools/roll_browsers.dart, see go/dart-engprod/browsers.md.',
    if (trybots.isNotEmpty) ...[
      '',
      'Cq-Include-Trybots: dart/try:${trybots.join(',')}',
    ],
  ].join('\n');
}
