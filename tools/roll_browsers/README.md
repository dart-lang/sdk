# roll_browsers

A tool that automates rolling the browsers and JS engines pinned in `DEPS`,
following [go/dart-engprod/browsers.md](http://go/dart-engprod/browsers.md).

The entry point is [`tools/roll_browsers.dart`](../roll_browsers.dart); this
directory holds its implementation.

The tool relies on Google-internal infrastructure (LOAS credentials, the
dart-eng tool proxy, MPA and Google Chat), so it can only be run by Googlers.

## What it does

For each engine, the tool:

1. Compares the version pinned in `DEPS` on `origin/main` with the latest
   upstream release and decides whether to roll, based on the engine's roll
   policy.
2. Checks whether the CIPD packages for the new version exist. For any that
   are missing, it requests a packaging build through the dart-eng tool proxy,
   which needs MPA approval, and waits until the packages are published.
3. Uploads a single CL updating `DEPS` with the relevant trybots, a CQ dry run
   and Auto-Submit, and waits for it to be approved and land. The MPA approvers
   are added as reviewers, and the CL is sent to the commit queue once it is
   approved if Auto-Submit hasn't already done so.

Roll CLs are tagged with the `browser-roll` hashtag. If one is already open,
the tool waits for it to land instead of uploading another.

The CL is committed in a temporary git worktree, so the working tree and
current branch of the checkout running the tool are never touched.

### Engines and roll policy

| Engine    | `DEPS` variable | Upstream source              | Rolls when                                  |
| --------- | --------------- | ---------------------------- | ------------------------------------------- |
| `chrome`  | `chrome_tag`    | Chrome for Testing beta      | New major version, or pin is 14+ days old   |
| `firefox` | `firefox_tag`   | Firefox stable               | New major version, or pin is 14+ days old   |
| `d8`      | `d8_tag`        | V8 canary (all platforms)    | Pin is 30+ days old                         |
| `jsshell` | `jsshell_tag`   | Same version as Firefox      | Firefox rolls, or it is behind Firefox      |
| `jsc`     | `jsc_tag`       | WebKitGTK JSC builds         | Pin is 30+ days old                         |

The pin age is the time since the `DEPS` variable last changed on
`origin/main`. Engines that share a version (Firefox and jsshell) always roll
in the same CL.

### Chat notifications

Each run posts to a single thread in the Dart Web team Google Chat space (or
the space given by `--chat-space`), sent as the user running the tool. The
thread starts with the batched MPA approval links, or with the roll CL if no
builds were needed. The roll CL, any failures (including CQ failures) and a
final message when the CL lands are posted as replies.

## Prerequisites

- Valid LOAS credentials (`gcert`). If they expire during a run, the tool
  pauses until they are renewed.
- `depot_tools` on the `PATH` (for `git cl`) and the `cipd` client.
- `tool-proxy-cli` on the `PATH`, with access to the dart-eng tool proxy.

## Running the tool

From an SDK checkout, run:

```
dart tools/roll_browsers.dart
```

Use `--dry-run` first to see what would be rolled without requesting builds,
uploading CLs or posting to chat:

```
dart tools/roll_browsers.dart --dry-run
```

A run can take a long time, since it waits for MPA approvals (up to 48 hours),
packaging builds and the roll CL to land. It checks for progress every minute,
backing off to every hour after three hours without progress, so it is best
run somewhere it can be left alone, such as a `tmux` session.

The tool exits with a non-zero exit code if any step failed.

### Options

- `--only=<engine>`: Only consider the given engines (`chrome`, `firefox`,
  `d8`, `jsshell`, `jsc`). Can be repeated.
- `-n`, `--dry-run`: Report what would happen without side effects.
- `--ignore-cadence`: Roll to any newer version, ignoring the roll policy.
- `-r`, `--reviewer=<email>`: Add a reviewer to the roll CL. Can be repeated.
- `--chat-space=<id>`: The Google Chat space to post the run's thread to.
- `--reason=<text>`: The justification for the tool proxy MPA requests.
- `-h`, `--help`: Show usage information.

## Code layout

- [`roller.dart`](roller.dart): The overall roll flow (`BrowserRoller`).
- [`engines.dart`](engines.dart): The engine definitions, roll policies,
  CIPD packages and trybots, and `DEPS` parsing.
- [`upstream.dart`](upstream.dart): Looks up the latest upstream releases.
- [`tool_proxy.dart`](tool_proxy.dart): Requests CIPD packaging builds and
  looks up MPA approvers.
- [`gerrit.dart`](gerrit.dart): Finds, uploads and tracks roll CLs.
- [`git.dart`](git.dart): Git operations on the SDK checkout.
- [`notifier.dart`](notifier.dart): Posts the run's Google Chat thread.
- [`process.dart`](process.dart): Subprocess and credential helpers.
- [`version.dart`](version.dart): Dotted version parsing and comparison.

To add an engine, define it in `engines.dart` and add it to `allEngines`. Its
`name` must match the tool proxy `browser` grant and the
`dart-internal/ci/<name>` packaging builder.
