import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

// These packages are effectively pinned - they often require manual work when
// rolling.
// TODO(devoncarew): Keep this metadata in the DEPS file.
const Set<String> pinned = {
  'dart_style',
  'linter',
  'pub',
};

void main(List<String> args) async {
  // Validate we're running from the repo root.
  if (!File('README.dart-sdk').existsSync() || !File('DEPS').existsSync()) {
    stderr.writeln('Please run this script from the root of the SDK repo.');
    exit(1);
  }

  final gclient = GClientHelper();

  final deps = await gclient.getPackageDependencies();
  print('${deps.length} non-pinned package dependencies found.');
  print('');

  deps.sort((a, b) => a.name.compareTo(b.name));

  for (var dep in deps) {
    final git = GitHelper(dep.relativePath);

    await git.fetch();

    var commit = await git.findLatestUnsyncedCommit();
    if (commit.isNotEmpty) {
      var gitLog = await git.calculateUnsyncedCommits();
      var currentHash = await gclient.getHash(dep);

      // Construct the github diff URL.
      print('${dep.name} (${dep.getGithubDiffUrl(currentHash, commit)}):');

      // Print out the new commits.
      print(gitLog.split('\n').map((l) => '  $l').join('\n').trimRight());

      // Update the DEPS file.
      await gclient.setHash(dep, commit);

      print('');
    }
  }
}

class GitHelper {
  final String dir;

  GitHelper(this.dir);

  Future<String> fetch() {
    return exec(['git', 'fetch'], cwd: dir);
  }

  Future<String> findLatestUnsyncedCommit() async {
    // git log HEAD..origin --format=%H -1

    var result = await exec(
      [
        'git',
        'log',
        'HEAD..origin',
        '--format=%H',
        '-1',
      ],
      cwd: dir,
    );
    return result.trim();
  }

  Future<String> calculateUnsyncedCommits() async {
    // git log HEAD..origin --format="%h  %ad  %aN  %s" -1
    var result = await exec(
      [
        'git',
        'log',
        'HEAD..origin',
        '--format=%h  %ad  %aN  %s',
      ],
      cwd: dir,
    );
    return result.trim();
  }
}

class GClientHelper {
  Future<List<PackageDependency>> getPackageDependencies() async {
    // gclient revinfo --output-json=<file> --ignore-dep-type=cipd

    final tempDir = Directory.systemTemp.createTempSync();
    final outFile = File(path.join(tempDir.path, 'deps.json'));

    await exec([
      'gclient',
      'revinfo',
      '--output-json=${outFile.path}',
      '--ignore-dep-type=cipd',
    ]);
    Map<String, dynamic> m = jsonDecode(outFile.readAsStringSync());
    tempDir.deleteSync(recursive: true);

    return m.entries.map((entry) {
      return PackageDependency(
        entry: entry.key,
        url: (entry.value as Map)['url'],
        rev: (entry.value as Map)['rev'],
      );
    }).where((PackageDependency deps) {
      return deps.entry.startsWith('sdk/third_party/pkg/') ||
          deps.entry.startsWith('sdk/third_party/pkg_tested/');
    }).where((PackageDependency deps) {
      return !pinned.contains(deps.name);
    }).toList();
  }

  Future<String> getHash(PackageDependency dep) async {
    // DEPOT_TOOLS_UPDATE=0 gclient getdep --var=path_rev
    var depName = dep.name;
    var result = await exec(
      [
        'gclient',
        'getdep',
        '--var=${depName}_rev',
      ],
      environment: {
        'DEPOT_TOOLS_UPDATE': '0',
      },
    );
    return result.trim();
  }

  Future<String> setHash(PackageDependency dep, String hash) async {
    // gclient setdep --var=args_rev=9879dsf7g9d87d9f8g7
    var depName = dep.name;
    return await exec(
      [
        'gclient',
        'setdep',
        '--var=${depName}_rev=$hash',
      ],
      environment: {
        'DEPOT_TOOLS_UPDATE': '0',
      },
    );
  }
}

class PackageDependency {
  final String entry;
  final String url;
  final String? rev;

  PackageDependency({
    required this.entry,
    required this.url,
    required this.rev,
  });

  String get name => entry.substring(entry.lastIndexOf('/') + 1);

  String get relativePath => entry.substring('sdk/'.length);

  String getGithubDiffUrl(String fromCommit, String toCommit) {
    // https://github.com/dart-lang/<repo>/compare/<old>..<new>
    final from = fromCommit.substring(0, 7);
    final to = toCommit.substring(0, 7);

    var repo = url.substring(url.lastIndexOf('/') + 1);
    if (repo.endsWith('git')) {
      repo = repo.substring(0, repo.length - '.git'.length);
    }

    var org = 'dart-lang';
    if (url.contains('/external/')) {
      // https://dart.googlesource.com/external/github.com/google/webdriver.dart.git
      final parts = url.split('/');
      org = parts[parts.length - 2];
    }

    // TODO(devoncarew): Eliminate this special-casing; see #48830.
    const orgOverrides = {
      'platform.dart': 'google',
    };
    if (orgOverrides.containsKey(repo)) {
      org = orgOverrides[repo]!;
    }

    return 'https://github.com/$org/$repo/compare/$from..$to';
  }

  @override
  String toString() => '${rev?.substring(0, 8)} $relativePath';
}

Future<String> exec(
  List<String> cmd, {
  String? cwd,
  Map<String, String>? environment,
}) async {
  var result = await Process.run(
    cmd.first,
    cmd.sublist(1),
    workingDirectory: cwd,
    environment: environment,
  );
  if (result.exitCode != 0) {
    var cwdLocation = cwd == null ? '' : ' ($cwd)';
    print('${cmd.join(' ')}$cwdLocation');

    if ((result.stdout as String).isNotEmpty) {
      stdout.write(result.stdout);
    }
    if ((result.stderr as String).isNotEmpty) {
      stderr.write(result.stderr);
    }
    exit(1);
  }
  return result.stdout;
}
