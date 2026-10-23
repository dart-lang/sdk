#!/usr/bin/env python3
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Top-level presubmit script for Dart.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import datetime
import importlib.util
import json
import importlib.machinery
import os
import os.path
import re
from typing import Callable
import scm
import subprocess
import tempfile
import platform

USE_PYTHON3 = True


def is_cpp_file(path):
    return path.endswith('.cc') or path.endswith('.h')


def is_dart_file(path):
    return path.endswith('.dart')


def get_old_contents(input_api, path):
    local_root = input_api.change.RepositoryRoot()
    upstream = input_api.change._upstream
    return scm.GIT.Capture(['show', upstream + ':' + path],
                           cwd=local_root,
                           strip_out=False)


def files_to_check_for_format(input_api, extension, exclude_folders):
    files = []
    exclude_folders += [
        "pkg/front_end/testcases/", "pkg/front_end/parser_testcases/"
    ]
    for git_file in input_api.AffectedTextFiles():
        local_path = git_file.LocalPath()
        if not local_path.endswith(extension):
            continue
        if any([local_path.startswith(f) for f in exclude_folders]):
            continue
        files.append(git_file)
    return files


def _CheckFormat(input_api, identification, extension, windows,
                 hasFormatErrors: Callable[[str, list, str],
                                           bool], exclude_folders):
    files = files_to_check_for_format(input_api, extension, exclude_folders)
    if not files:
        return [], []

    # Check for formatting errors in bulk first. This is orders of magnitude
    # faster than checking file-by-file on large changes with hundreds of files.
    if not hasFormatErrors(filenames=[f.AbsoluteLocalPath() for f in files]):
        return [], []

    print("Formatting errors found, comparing against old versions.")
    unformatted_files = []
    warnings = []
    for git_file in files:
        filename = git_file.AbsoluteLocalPath()
        if hasFormatErrors(filename=filename):
            old_version_has_errors = False
            try:
                path = git_file.LocalPath()
                if windows:
                    # Git expects a linux style path.
                    path = path.replace(os.sep, '/')
                if hasFormatErrors(contents=get_old_contents(input_api, path)):
                    old_version_has_errors = True
            except subprocess.CalledProcessError as e:
                old_version_has_errors = False

            if old_version_has_errors:
                warnings.append("%s has existing and possibly new %s issues" %
                                (git_file.LocalPath(), identification))
            else:
                unformatted_files.append(filename)

    return unformatted_files, warnings


def load_source(modname, filename):
    loader = importlib.machinery.SourceFileLoader(modname, filename)
    spec = importlib.util.spec_from_file_location(modname,
                                                  filename,
                                                  loader=loader)
    module = importlib.util.module_from_spec(spec)
    # The module is always executed and not cached in sys.modules.
    # Uncomment the following line to cache the module.
    # sys.modules[module.__name__] = module
    loader.exec_module(module)
    return module


def _CheckDartFormat(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    utils = load_source('utils', os.path.join(local_root, 'tools', 'utils.py'))

    dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')

    windows = utils.GuessOS() == 'win32'
    if windows:
        dart += '.exe'

    if not os.path.isfile(dart):
        return [
            output_api.PresubmitError(
                'dart not found (please ensure to use a gclient based '
                'checkout of dart-lang/sdk): %s' % dart)
        ]

    def HasFormatErrors(filename: str = None,
                        filenames: list = None,
                        contents: str = None):
        # Don't look for formatting errors in multitests. Since those are very
        # sensitive to whitespace, many cannot be reformatted without breaking
        # them.
        def skip_file(path):
            if path.endswith('_test.dart'):
                with open(path, encoding='utf-8') as f:
                    contents = f.read()
                    if '//#' in contents:
                        return True
            return False

        if filename and skip_file(filename):
            return False

        args = [
            dart,
            'format',
            '--set-exit-if-changed',
            '--output=none',
            '--summary=none',
        ]

        # TODO(https://github.com/dart-lang/sdk/issues/46947): Remove this hack.
        if windows and contents:
            f = tempfile.NamedTemporaryFile(
                encoding='utf-8',
                delete=False,
                mode='w',
                suffix='.dart',
            )
            try:
                f.write(contents)
                f.close()
                args.append(f.name)
                process = subprocess.run(args)
            finally:
                os.unlink(f.name)
        elif contents:
            process = subprocess.run(args, input=contents, text=True)
        elif filenames:
            args += [f for f in filenames if not skip_file(f)]
            process = subprocess.run(args)
        else:
            args.append(filename)
            process = subprocess.run(args)

        # Check for exit code 1 explicitly to distinguish it from a syntax error
        # in the file (exit code 65). The repo contains many Dart files that are
        # known to have syntax errors for testing purposes and which can't be
        # parsed and formatted. Don't treat those as errors.
        return process.returncode == 1

    unformatted_files, warnings = _CheckFormat(input_api, "dart format",
                                               ".dart", windows,
                                               HasFormatErrors, [])

    results = [output_api.PresubmitPromptWarning(w) for w in warnings]
    if unformatted_files:
        lineSep = " \\\n"
        if windows:
            lineSep = " ^\n"
        results.append(
            output_api.PresubmitError(
                'File output does not match dart format.\n'
                'Fix these issues with:\n'
                '%s format %s' % (dart, lineSep.join(unformatted_files))))

    return results


def _CheckStatusFiles(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    utils = load_source('utils', os.path.join(local_root, 'tools', 'utils.py'))

    dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
    lint = os.path.join(local_root, 'pkg', 'status_file', 'bin', 'lint.dart')

    windows = utils.GuessOS() == 'win32'
    if windows:
        dart += '.exe'

    if not os.path.isfile(dart):
        return [
            output_api.PresubmitError(
                'dart not found (please ensure to use a gclient based '
                'checkout of dart-lang/sdk): %s' % dart)
        ]

    if not os.path.isfile(lint):
        return [
            output_api.PresubmitError(
                'Status file linter not found (please ensure to use a '
                'gclient based checkout of dart-lang/sdk): %s' % lint)
        ]

    def HasFormatErrors(filename=None, filenames=None, contents=None):
        if filenames:
            # The status file linter doesn't support checking files in bulk.
            # Returning `True` causes `_CheckFormat` to fallback to check
            # formatting file by file below.
            return True
        args = [dart, lint] + (['-t'] if contents else [filename])
        process = subprocess.run(args, input=contents, text=True)
        return process.returncode != 0

    exclude_folders = [
        "pkg/status_file/test/data/",
        "pkg/front_end/",
    ]
    unformatted_files, warnings = _CheckFormat(input_api, "status file",
                                               ".status", windows,
                                               HasFormatErrors, exclude_folders)

    results = [output_api.PresubmitPromptWarning(w) for w in warnings]
    if unformatted_files:
        normalize = os.path.join(local_root, 'pkg', 'status_file', 'bin',
                                 'normalize.dart')
        lineSep = " \\\n"
        if windows:
            lineSep = " ^\n"
        results.append(
            output_api.PresubmitError(
                'Status files are not normalized.\n'
                'Fix these issues with:\n'
                '%s %s -w%s%s' %
                (dart, normalize, lineSep, lineSep.join(unformatted_files))))

    return results


def _CheckValidHostsInDEPS(input_api, output_api):
    """Checks that DEPS file deps are from allowed_hosts."""
    # Run only if DEPS file has been modified to annoy fewer bystanders.
    if all(f.LocalPath() != 'DEPS' for f in input_api.AffectedFiles()):
        return []
    # Outsource work to gclient verify
    try:
        input_api.subprocess.check_output(['gclient', 'verify'])
        return []
    except input_api.subprocess.CalledProcessError as error:
        return [
            output_api.PresubmitError(
                'DEPS file must have only dependencies from allowed hosts.',
                long_text=error.output)
        ]


def _CheckLayering(input_api, output_api):
    """Run VM layering check.

  This check validates that sources from one layer do not reference sources
  from another layer accidentally.
  """

    # Run only if .cc or .h file was modified.
    if all(not is_cpp_file(f.LocalPath()) for f in input_api.AffectedFiles()):
        return []

    local_root = input_api.change.RepositoryRoot()
    compiler_layering_check = load_source(
        'compiler_layering_check',
        os.path.join(local_root, 'runtime', 'tools',
                     'compiler_layering_check.py'))
    errors = compiler_layering_check.DoCheck(local_root)
    embedder_layering_check = load_source(
        'embedder_layering_check',
        os.path.join(local_root, 'runtime', 'tools',
                     'embedder_layering_check.py'))
    errors += embedder_layering_check.DoCheck(local_root)
    if errors:
        return [
            output_api.PresubmitError(
                'Layering check violation for C++ sources.',
                long_text='\n'.join(errors))
        ]

    return []


def _ClangToolPath(name):
    """Returns the clang tool path for this host, or None if not enabled here."""
    system, machine = platform.system(), platform.machine()
    if system == 'Linux' and machine == 'x86_64':
        plat = 'linux-x64'
    elif system == 'Darwin':
        plat = 'mac-arm64' if machine == 'arm64' else 'mac-x64'
    elif system == 'Windows':
        plat = 'win-x64'
        name = name + '.exe'
    else:
        return None
    path = 'buildtools/%s/clang/bin/%s' % (plat, name)
    return path if os.path.isfile(path) else None


def _CheckClangTidy(input_api, output_api):
    """Run clang-tidy on VM changes."""

    # Run only for modified .cc or .h files.
    files = []
    for f in input_api.AffectedFiles():
        path = f.LocalPath()
        if is_cpp_file(path) and os.path.isfile(path): files.append(path)

    if not files:
        return []

    # clang-tidy currently only runs on linux-x64.
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        return [
            output_api.PresubmitNotifyResult(
                'clang-tidy not enabled on this platform.')
        ]

    args = [
        'tools/sdks/dart-sdk/bin/dart',
        'runtime/tools/run_clang_tidy.dart',
    ]
    args.extend(files)
    stdout = input_api.subprocess.check_output(args).strip()
    if not stdout:
        return []

    return [
        output_api.PresubmitError(
            'The `clang-tidy` linter revealed issues:',
            long_text=stdout)
    ]


def _CheckClangFormat(input_api, output_api):
    """Run clang-format on VM changes."""

    # Run only for modified .cc or .h files, except for DEPS changes.
    files = []
    is_deps = False
    for f in input_api.AffectedFiles():
        path = f.LocalPath()
        if path == 'DEPS' and any(
                map(lambda content: 'clang' in content[1],
                    f.ChangedContents())):
            is_deps = True
            break
        if is_cpp_file(path) and os.path.isfile(
                path) and not path.startswith('third_party/'):
            files.append(path)

    if not is_deps and not files:
        return []

    clang_format = _ClangToolPath('clang-format')
    if clang_format is None:
        return [
            output_api.PresubmitNotifyResult(
                'clang-format not enabled on this platform.')
        ]

    if is_deps:
        find_args = [
            'find',
            'runtime/',
            '-iname',
            '*.h',
            '-o',
            '-iname',
            '*.cc',
        ]
        files = subprocess.check_output(find_args, text=True).split()

    if not files:
        return []

    args = [
        clang_format,
        '--dry-run',
        '--Werror',
    ]
    args.extend(files)
    stdout = input_api.subprocess.check_output(args).strip()
    if not stdout:
        return []

    return [
        output_api.PresubmitError('The `clang-format` revealed issues:',
                                  long_text=stdout)
    ]


def _CheckAnalyzerFiles(input_api, output_api):
    """Run analyzer checks on source files."""

    # Verify the "error fix status" file.
    code_files = [
        "pkg/analyzer/lib/src/diagnostic/diagnostic_code_values.g.dart",
        "pkg/linter/lib/src/rules.dart",
    ]

    if any(f.LocalPath() in code_files for f in input_api.AffectedFiles()):
        args = [
            "tools/sdks/dart-sdk/bin/dart",
            "pkg/analysis_server/tool/presubmit/verify_error_fix_status.dart",
        ]
        stdout = input_api.subprocess.check_output(args).strip()
        if not stdout:
            return []

        return [
            output_api.PresubmitError(
                "The verify_error_fix_status Analyzer tool revealed issues:",
                long_text=stdout)
        ]

    # TODO(srawlins): Check more:
    # * "verify_sorted" for individual modified (not deleted) files in
    #   Analyzer-team-owned directories.
    # * "verify_tests" for individual modified (not deleted) test files in
    #   Analyzer-team-owned directories.
    # * Verify that `messages/generate.dart` does not produce different
    #   content, when `pkg/analyzer/messages.yaml` is modified.
    # * Verify that `diagnostics/generate.dart` does not produce different
    #   content, when `pkg/analyzer/messages.yaml` is modified.
    # * Maybe "verify_no_solo" for individual modified (not deleted test files
    #   in Analyzer-team-owned directories.

    # No files are relevant.
    return []


def _CheckTestMatrixValid(input_api, output_api):
    """Run script to check that the test matrix has no errors."""

    def test_matrix_filter(affected_file):
        """Only run test if either the test matrix or the code that
           validates it was modified."""
        path = affected_file.LocalPath()
        return (path == 'tools/bots/test_matrix.json' or
                path == 'tools/validate_test_matrix.dart' or
                path.startswith('pkg/smith/'))

    if len(
            input_api.AffectedFiles(
                include_deletes=False, file_filter=test_matrix_filter)) == 0:
        return []

    command = [
        'tools/sdks/dart-sdk/bin/dart',
        'tools/validate_test_matrix.dart',
    ]
    stdout = input_api.subprocess.check_output(command).strip()
    if not stdout:
        return []
    else:
        return [
            output_api.PresubmitError(
                'The test matrix is not valid:', long_text=stdout)
        ]


def _CheckCopyrightYear(input_api, output_api):
    """Check copyright year in new files."""

    files = []
    year = str(datetime.datetime.now().year)
    for f in input_api.AffectedFiles(include_deletes=False):
        path = f.LocalPath()
        if (is_dart_file(path) or is_cpp_file(path)
           ) and f.Action() == 'A' and os.path.isfile(path):
            with open(path, encoding='utf-8') as f:
                first_line = f.readline()
                if 'Copyright' in first_line and year not in first_line:
                    files.append(path)

    if not files:
        return []

    return [
        output_api.PresubmitPromptWarning(
            'Copyright year for new files should be ' + year + ':\n' +
            '\n'.join(files))
    ]


def _CheckDevCompilerSync(input_api, output_api):
    """Make sure that any changes in the original and the temporary forked
    version of the DDC compiler are kept in sync. If a CL touches the
    compiler.dart there should probably be in a change in compiler_new.dart
    as well.
    """
    OLD = "pkg/dev_compiler/lib/src/kernel/compiler.dart"
    NEW = "pkg/dev_compiler/lib/src/kernel/compiler_new.dart"

    files = [git_file.LocalPath() for git_file in input_api.AffectedTextFiles()]

    if (OLD in files and NEW not in files):
        return [
            output_api.PresubmitPromptWarning(
                "Make sure to keep the original and temporary forked versions "
                "of compiler.dart in sync.\n"
                "You may need to copy or adapt changes between these files:\n" +
                "\n".join([OLD, NEW]))
        ]

    return []


def _CheckDartApiWinCSync(input_api, output_api):
    """Ensure that dart_api_win.c is up-to-date."""
    GENERATOR = "runtime/tools/generate_dart_api_win_c.dart"
    DART_API_H = "runtime/include/dart_api.h"
    DART_NATIVe_API_H = "runtime/include/dart_native_api.h"

    files = [git_file.LocalPath() for git_file in input_api.AffectedTextFiles()]

    if (GENERATOR in files or DART_API_H in files or
            DART_NATIVe_API_H in files):
        # Run the generator with `--check-up-to-date` to see if the output is
        # up-to-date.
        args = [
            "tools/sdks/dart-sdk/bin/dart",
            GENERATOR,
            "--check-up-to-date",
        ]
        try:
            subprocess.run(args, check=True)
        except subprocess.CalledProcessError as e:
            return [
                output_api.PresubmitError(
                    f"Make sure to re-run {GENERATOR} when it or its inputs "
                    "change.")
            ]

    return []


def _CheckStressTestListEntriesExist(input_api, output_api):
    """Ensure that stress_test_list.json only lists files that exist."""
    STRESS_TEST_LIST = "runtime/tests/concurrency/stress_test_list.json"

    # Run only if the list was modified or the CL deletes (or renames) files.
    if not any(f.LocalPath() == STRESS_TEST_LIST or f.Action() == 'D'
               for f in input_api.AffectedFiles()):
        return []

    local_root = input_api.change.RepositoryRoot()
    list_path = os.path.join(local_root, STRESS_TEST_LIST)
    if not os.path.isfile(list_path):
        return []

    # Entries are relative to the directory containing the list.
    list_dir = os.path.dirname(list_path)
    with open(list_path, encoding='utf-8') as f:
        entries = json.load(f)
    missing = [
        entry for entry in entries
        if not os.path.isfile(os.path.join(list_dir, entry))
    ]
    if not missing:
        return []

    return [
        output_api.PresubmitError(
            f"{STRESS_TEST_LIST} lists files that do not exist. Remove these "
            "entries (or update them if the tests were moved):",
            long_text="\n".join(missing))
    ]


# Directories whose changes require a TEST=/Tested: description. Keep in sync
# with the Gerrit "Commit-Message-Has-TEST" submit requirement, which is the
# source of truth and lives in the project config on refs/meta/config:
#   git fetch <remote> refs/meta/config && git show FETCH_HEAD:project.config
_TEST_REQUIRED_DIRS = (
    'runtime/vm/',
    'runtime/bin/',
    'runtime/lib/',
    'runtime/include/',
    'runtime/observatory/',
    'runtime/observatory_2/',
    'pkg/vm/',
    'sdk/lib/_internal/vm/',
)


def _CheckHasTestField(input_api, output_api):
    """Warns when a CL touching Dart VM sources lacks a TEST=/Tested: line.

    Early upload-time reminder mirroring the Gerrit Commit-Message-Has-TEST
    submit requirement (which stays the authoritative check). See
    docs/Gerrit-Submit-Requirements.md#commit-message-has-test.
    """
    if not any(
            f.LocalPath().startswith(_TEST_REQUIRED_DIRS)
            for f in input_api.AffectedFiles()):
        return []

    # Pure reverts restore already-tested code and are exempt.
    if input_api.change.DescriptionText().lstrip().startswith('Revert "'):
        return []

    # A `TEST=`/`TESTED=` line or a `Tested:` footer satisfies the rule.
    has_test = bool(
        input_api.change.tags.get('TEST') or
        input_api.change.tags.get('TESTED'))
    has_tested_footer = bool(
        input_api.change.GitFootersFromDescription().get('Tested'))
    if has_test or has_tested_footer:
        return []

    return [
        output_api.PresubmitPromptWarning(
            'This CL touches Dart VM sources but has no TEST= line or Tested: '
            'footer describing how it was tested. Add one, e.g.:\n'
            '  TEST=vm/cc/MyNewUnitTest\n'
            '  TEST=ci   (existing CI coverage is sufficient)\n'
            'See docs/Gerrit-Submit-Requirements.md#commit-message-has-test.')
    ]


# Lines in the commit message controlling automated publishing of packages in
# pkg/ and third_party/pkg/, see docs/Publishing-SDK-packages.md. Anchored at
# the start of the line so that quoted lines in reverts (`> PUBLISH=...`) are
# ignored.
_PUBLISH_RE = re.compile(r'^PUBLISH=([a-z0-9_]+)-v(\S+)$')
_SKIP_PUBLISH_RE = re.compile(r'^SKIP_PUBLISH=([a-z0-9_]+)$')
_PUBLISH_LIKE_RE = re.compile(r'^\s*(SKIP_)?PUBLISH\s*=')
_PKG_PUBSPEC_RE = re.compile(
    r'^(?:pkg|third_party/pkg)/([a-z0-9_]+)/pubspec\.yaml$')
_CHANGELOG_VERSION_RE = re.compile(r'^#{1,2}\s+v?([0-9]\S*)')


def _PubspecField(lines, key):
    """Returns the scalar value of a top-level pubspec field, or None."""
    field = re.compile(r'^' + key + r':\s*[\'"]?([^\'"\s#]+)')
    for line in lines:
        m = field.match(line)
        if m:
            return m.group(1)
    return None


def _IsReleaseVersion(version):
    return not version.endswith(('-wip', '-dev'))


def _HasPublishTo(lines):
    """Whether the pubspec has a publish_to field (and is not published)."""
    return any(line.startswith('publish_to:') for line in lines)


def _TrackedPubspec(input_api, pkg):
    """Returns the path of the pubspec.yaml tracked in git for pkg, or None.

    Packages from DEPS are present on disk but not tracked, so they are never
    returned.
    """
    candidates = [
        'pkg/%s/pubspec.yaml' % pkg,
        'third_party/pkg/%s/pubspec.yaml' % pkg,
    ]
    tracked = scm.GIT.Capture(['ls-files', '--'] + candidates,
                              cwd=input_api.change.RepositoryRoot()).split()
    return tracked[0] if tracked else None


def _CheckPackagePublish(input_api, output_api):
    """Checks PUBLISH= lines for packages that are published to pub.dev.

    A PUBLISH=<package>-v<version> line in the commit message causes the
    package to be published once the commit lands on main, see
    docs/Publishing-SDK-packages.md. This check requires such a line (or
    SKIP_PUBLISH=<package>) when the version of a publishable package is
    changed to a release version, and validates PUBLISH= lines against the
    pubspec and changelog.
    """
    # Packages are only published from main.
    gerrit = input_api.gerrit
    if gerrit and gerrit.branch and gerrit.branch != 'refs/heads/main':
        return []

    publish = []
    skip_pkgs = set()
    errors = []
    for line in input_api.change.FullDescriptionText().splitlines():
        m = _PUBLISH_RE.match(line)
        if m:
            publish.append(m.groups())
            continue
        m = _SKIP_PUBLISH_RE.match(line)
        if m:
            skip_pkgs.add(m.group(1))
            continue
        if _PUBLISH_LIKE_RE.match(line):
            errors.append(
                '"%s" is not a valid PUBLISH= line. It must be exactly '
                'PUBLISH=<package>-v<version> or SKIP_PUBLISH=<package> at '
                'the start of the line.' % line)
    publish_pkgs = set(pkg for pkg, _ in publish)

    # Changing to a release version requires PUBLISH= or SKIP_PUBLISH=. Pure
    # reverts restore an already published version and are exempt.
    is_revert = input_api.change.DescriptionText().lstrip().startswith(
        'Revert "')
    for f in input_api.AffectedFiles(include_deletes=False):
        path = f.LocalPath().replace(os.sep, '/')
        m = _PKG_PUBSPEC_RE.match(path)
        if not m or is_revert:
            continue
        pkg = m.group(1)
        if pkg in publish_pkgs or pkg in skip_pkgs:
            continue
        if _HasPublishTo(f.NewContents()):
            continue
        new_version = _PubspecField(f.NewContents(), 'version')
        if new_version is None or not _IsReleaseVersion(new_version):
            continue
        # Unchanged, unless the package was not publishable before.
        if (new_version == _PubspecField(f.OldContents(), 'version') and
                not _HasPublishTo(f.OldContents())):
            continue
        errors.append(
            '%s has version %s, which will not be published to pub.dev.\n'
            'Add PUBLISH=%s-v%s to the commit message to publish it, or '
            'SKIP_PUBLISH=%s to not publish it.' %
            (path, new_version, pkg, new_version, pkg))

    # Validate PUBLISH= lines.
    root = input_api.change.RepositoryRoot()
    for pkg, version in publish:
        if pkg in skip_pkgs:
            errors.append('PUBLISH=%s-v%s conflicts with SKIP_PUBLISH=%s.' %
                          (pkg, version, pkg))
            continue
        pubspec = _TrackedPubspec(input_api, pkg)
        if pubspec is None:
            errors.append(
                'PUBLISH=%s-v%s: there is no pkg/%s/pubspec.yaml or '
                'third_party/pkg/%s/pubspec.yaml in this repository.' %
                (pkg, version, pkg, pkg))
            continue
        pkg_dir = os.path.dirname(pubspec)
        with open(os.path.join(root, pubspec), encoding='utf-8') as f:
            lines = f.read().splitlines()
        if _HasPublishTo(lines):
            errors.append('PUBLISH=%s-v%s: %s has publish_to.' %
                          (pkg, version, pubspec))
            continue
        if not _IsReleaseVersion(version):
            errors.append(
                'PUBLISH=%s-v%s: versions ending with -wip or -dev are not '
                'published.' % (pkg, version))
            continue
        pubspec_version = _PubspecField(lines, 'version')
        if version != pubspec_version:
            errors.append('PUBLISH=%s-v%s: %s has version %s.' %
                          (pkg, version, pubspec, pubspec_version))
            continue
        changelog = os.path.join(root, pkg_dir, 'CHANGELOG.md')
        if os.path.isfile(changelog):
            with open(changelog, encoding='utf-8') as f:
                lines = f.read().splitlines()
            headings = [
                m.group(1) for m in map(_CHANGELOG_VERSION_RE.match, lines) if m
            ]
            if not headings or headings[0] != version:
                errors.append(
                    'PUBLISH=%s-v%s: the first version in %s/CHANGELOG.md '
                    'is %s, expected %s.' %
                    (pkg, version, pkg_dir, headings[0] if headings else None,
                     version))

    return [output_api.PresubmitError(e) for e in errors]


def _CommonChecks(input_api, output_api):
    results = []
    results.extend(_CheckValidHostsInDEPS(input_api, output_api))
    results.extend(_CheckHasTestField(input_api, output_api))
    results.extend(_CheckPackagePublish(input_api, output_api))
    results.extend(_CheckDartFormat(input_api, output_api))
    results.extend(_CheckStatusFiles(input_api, output_api))
    results.extend(_CheckLayering(input_api, output_api))
    results.extend(_CheckClangTidy(input_api, output_api))
    results.extend(_CheckClangFormat(input_api, output_api))
    results.extend(_CheckTestMatrixValid(input_api, output_api))
    results.extend(
        input_api.canned_checks.CheckPatchFormatted(input_api, output_api))
    results.extend(_CheckCopyrightYear(input_api, output_api))
    results.extend(_CheckAnalyzerFiles(input_api, output_api))
    results.extend(_CheckDevCompilerSync(input_api, output_api))
    results.extend(_CheckDartApiWinCSync(input_api, output_api))
    results.extend(_CheckStressTestListEntriesExist(input_api, output_api))
    return results


def CheckChangeOnCommit(input_api, output_api):
    return _CommonChecks(input_api, output_api)


def CheckChangeOnUpload(input_api, output_api):
    return _CommonChecks(input_api, output_api)
