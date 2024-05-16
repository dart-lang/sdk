> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

These instructions supplement https://dart.dev/get-dart with additional details for how to install beta and dev releases with brew (on MacOS), choco (on Windows), and apt-get (on Linux). Note that on all platforms you can also download SDK archives from all channels at https://dart.dev/tools/sdk/archive.

# Installing and upgrading on macOS with Homebrew

## Installing

To install a **stable channel** release, use the `dart` formula:

```terminal
$ brew tap dart-lang/dart
$ brew install dart
```

To install a **beta channel** release, use the `dart-beta` formula:

```terminal
$ brew install dart-beta
```

To install a **dev channel** release, use the `dart` formula and `--head`:

```terminal
$ brew install --head dart
```

## Upgrading

To upgrade when a new release of Dart is available run:

```terminal
# On the stable channel
$ brew upgrade dart # replace dart with dart-beta if you are on the beta channel.

# On the dev channel
$ brew reinstall dart
```

## Switching channels

When switching channels (e.g. from stable to beta), first unlink the current release:

```terminal
# stable or dev to beta
$ brew unlink dart # replace dart with dart-beta if you are on the beta channel.

# dev to stable
$ brew install -f dart
```

Then install using the command listed under Installing above.

# Installing and upgrading on Windows with Chocolatey

To use [Chocolatey][] to install a **stable** release of the Dart SDK, run this
command:

```terminal
C:\> choco install dart-sdk
```

To install a **beta** release, run this command (you'll need the exact version
number):

```terminal
C:\> choco install dart-sdk --pre --version 2.8.0.20-c-011-beta
```

To install a **dev** release, run this command:

```terminal
C:\> choco install dart-sdk --pre
```

To **upgrade** the Dart SDK, run this command
(add `--pre` to upgrade the dev release):

```terminal
C:\> choco upgrade dart-sdk
```

# Installing and upgrading on Linux with `apt-get`

To use `apt-get` to install Dart SDK packages, you first need to do this one time setup:

```
$ apt-get -q update && apt-get install --no-install-recommends -y -q gnupg2 curl git ca-certificates apt-transport-https openssh-client && \
  curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list && \
  curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_testing.list > /etc/apt/sources.list.d/dart_testing.list && \
  curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_unstable.list > /etc/apt/sources.list.d/dart_unstable.list && \
  apt-get update
```

Then, there are multiple ways to install the different channels from `apt-get`:
```
$ apt-get -t unstable install dart # installs the latest dev dart
$ apt-get -t testing install dart # installs the latest beta dart
$ apt-get -t stable install dart # installs the latest stable dart
$ apt-get install dart # installs the latest version of dart
```

You can also install a specific version of Dart like this:
```
$ apt-get install dart=2.9.0-4.0.dev-1
```

[Chocolatey]: https://chocolatey.org
