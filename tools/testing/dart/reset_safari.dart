// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper program for killing and resetting all Safari settings to a known
/// state that works well for testing dart2js output in Safari.
///
/// Warning: this will delete all your Safari settings and bookmarks.
library testing.reset_safari;

import 'dart:async' show Future, Timer;

import 'dart:io' show Directory, File, Platform, Process;

const String defaultSafariBundleLocation = "/Applications/Safari.app/";

const String relativeSafariLocation = "Contents/MacOS/Safari";

const String lsofLocation = "/usr/sbin/lsof";

const String killLocation = "/bin/kill";

const String pkillLocation = "/usr/bin/pkill";

const String safari = "com.apple.Safari";

const String defaultsLocation = "/usr/bin/defaults";

final List<String> safariSettings = <String>[
  "Library/Caches/$safari",
  "Library/Safari",
  "Library/Saved Application State/$safari.savedState",
  "Library/Caches/Metadata/Safari",
  "Library/Preferences/$safari.plist",
];

const Duration defaultPollDelay = const Duration(milliseconds: 1);

final String cpgi = "$safari.ContentPageGroupIdentifier";

final String knownSafariPreference = '''
{
    DefaultBrowserPromptingState2 = 2;
    StartPageViewControllerMode = 0;
    TestDriveOriginBrowser = 1;
    TestDriveUserDecision = 2;
    TestDriveState = 3;
    AlwaysRestoreSessionAtLaunch = 0;
    NewTabBehavior = 1;
    NewWindowBehavior = 1;
    LastSafariVersionWithWelcomePage = "9.0";
    OpenNewTabsInFront = 0;
    TabCreationPolicy = 0;

    IncludeDevelopMenu = 1;
    WebKitDeveloperExtrasEnabledPreferenceKey = 1;
    "$cpgi.WebKit2DeveloperExtrasEnabled" = 1;

    AutoFillCreditCardData = 0;
    AutoFillMiscellaneousForms = 0;
    AutoFillPasswords = 0;

    SuppressSearchSuggestions = 1;

    PreloadTopHit = 0;
    ShowFavoritesUnderSmartSearchField = 0;
    WebsiteSpecificSearchEnabled = 0;

    WarnAboutFraudulentWebsites = 0;


    WebKitJavaScriptEnabled = 1;
    "$cpgi.WebKit2JavaScriptEnabled" = 1;

    WebKitJavaScriptCanOpenWindowsAutomatically = 1;
    "$cpgi.WebKit2JavaScriptCanOpenWindowsAutomatically" = 1;

    "$cpgi.WebKit2WebGLEnabled" = 1;
    WebGLDefaultLoadPolicy = WebGLPolicyAllowNoSecurityRestrictions;

    "$cpgi.WebKit2PluginsEnabled" = 0;

    BlockStoragePolicy = 1;
    WebKitStorageBlockingPolicy = 0;
    "$cpgi.WebKit2StorageBlockingPolicy" = 0;


    SafariGeolocationPermissionPolicy = 0;

    CanPromptForPushNotifications = 0;

    InstallExtensionUpdatesAutomatically = 0;

    ShowFullURLInSmartSearchField = 1;

    "$cpgi.WebKit2PlugInSnapshottingEnabled" = 0;
}
''';

Future<Null> get pollDelay => new Future.delayed(defaultPollDelay);

String signalArgument(String defaultSignal,
    {bool force: false, bool testOnly: false}) {
  if (force && testOnly) {
    throw new ArgumentError("[force] and [testOnly] can't both be true.");
  }
  if (force) return "-KILL";
  if (testOnly) return "-0";
  return defaultSignal;
}

Future<int> kill(List<String> pids,
    {bool force: false, bool testOnly: false}) async {
  var arguments = [signalArgument("-TERM", force: force, testOnly: testOnly)]
    ..addAll(pids);
  var result = await Process.run(killLocation, arguments);
  return result.exitCode;
}

Future<int> pkill(String pattern,
    {bool force: false, bool testOnly: false}) async {
  var arguments = [
    signalArgument("-HUP", force: force, testOnly: testOnly),
    pattern
  ];
  var result = await Process.run(pkillLocation, arguments);
  return result.exitCode;
}

Uri validatedBundleName(Uri bundle) {
  if (bundle == null) return Uri.base.resolve(defaultSafariBundleLocation);
  if (!bundle.path.endsWith("/")) {
    throw new ArgumentError("Bundle ('$bundle') must end with a slash ('/').");
  }
  return bundle;
}

Future<Null> killSafari({Uri bundle}) async {
  bundle = validatedBundleName(bundle);
  var safariBinary = bundle.resolve(relativeSafariLocation);
  var result =
      await Process.run(lsofLocation, ["-t", safariBinary.toFilePath()]);
  if (result.exitCode == 0) {
    var stdout = result.stdout as String;
    var pids =
        stdout.split("\n").where((String line) => !line.isEmpty).toList();
    var timer = new Timer(const Duration(seconds: 10), () {
      print("Kill -9 Safari $pids");
      kill(pids, force: true);
    });
    var exitCode = await kill(pids);
    while (exitCode == 0) {
      await pollDelay;
      print("Polling Safari $pids");
      exitCode = await kill(pids, testOnly: true);
    }
    timer.cancel();
  }
  var timer = new Timer(const Duration(seconds: 10), () {
    print("Kill -9 $safari");
    pkill(safari, force: true);
  });
  var exitCode = await pkill(safari);
  while (exitCode == 0) {
    await pollDelay;
    print("Polling $safari");
    exitCode = await pkill(safari, testOnly: true);
  }
  timer.cancel();
}

Future<Null> deleteIfExists(Uri uri) async {
  var directory = new Directory.fromUri(uri);
  if (await directory.exists()) {
    print("Deleting directory '$uri'.");
    await directory.delete(recursive: true);
  } else {
    var file = new File.fromUri(uri);
    if (await file.exists()) {
      print("Deleting file '$uri'.");
      await file.delete();
    } else {
      print("File '$uri' not found.");
    }
  }
}

Future<Null> resetSafariSettings() async {
  var home = Platform.environment["HOME"];
  if (!home.endsWith("/")) {
    home = "$home/";
  }
  var homeDirectory = Uri.base.resolve(home);
  for (String setting in safariSettings) {
    await deleteIfExists(homeDirectory.resolve(setting));
  }
  var result = await Process
      .run(defaultsLocation, <String>["write", safari, knownSafariPreference]);
  if (result.exitCode != 0) {
    throw "Unable to reset Safari settings: ${result.stdout}${result.stderr}";
  }
}

Future<Null> killAndResetSafari({Uri bundle}) async {
  bundle = validatedBundleName(bundle);
  await killSafari(bundle: bundle);
  await resetSafariSettings();
}

Future<Null> main() async {
  await killAndResetSafari();
}
