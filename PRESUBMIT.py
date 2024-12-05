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
import importlib.machinery
import os
import os.path
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
        return []

    # Check for formatting errors in bulk first. This is orders of magnitude
    # faster than checking file-by-file on large changes with hundreds of files.
    if not hasFormatErrors(filenames=[f.AbsoluteLocalPath() for f in files]):
        return []

    print("Formatting errors found, comparing against old versions.")
    unformatted_files = []
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
                print("WARNING: %s has existing and possibly new %s issues" %
                      (git_file.LocalPath(), identification))
            else:
                unformatted_files.append(filename)

    return unformatted_files


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
        print('WARNING: dart not found: %s' % (dart))
        return []

    dartFixes = [
        '--fix-named-default-separator',
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
        ] + dartFixes + [
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

    unformatted_files = _CheckFormat(input_api, "dart format", ".dart", windows,
                                     HasFormatErrors, [])

    if unformatted_files:
        lineSep = " \\\n"
        if windows:
            lineSep = " ^\n"
        return [
            output_api.PresubmitError(
                'File output does not match dart format.\n'
                'Fix these issues with:\n'
                '%s format %s%s%s' % (dart, ' '.join(dartFixes), lineSep,
                                      lineSep.join(unformatted_files)))
        ]

    return []


def _CheckStatusFiles(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    utils = load_source('utils', os.path.join(local_root, 'tools', 'utils.py'))

    dart = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dart')
    lint = os.path.join(local_root, 'pkg', 'status_file', 'bin', 'lint.dart')

    windows = utils.GuessOS() == 'win32'
    if windows:
        dart += '.exe'

    if not os.path.isfile(dart):
        print('WARNING: dart not found: %s' % dart)
        return []

    if not os.path.isfile(lint):
        print('WARNING: Status file linter not found: %s' % lint)
        return []

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
    unformatted_files = _CheckFormat(input_api, "status file", ".status",
                                     windows, HasFormatErrors, exclude_folders)

    if unformatted_files:
        normalize = os.path.join(local_root, 'pkg', 'status_file', 'bin',
                                 'normalize.dart')
        lineSep = " \\\n"
        if windows:
            lineSep = " ^\n"
        return [
            output_api.PresubmitError(
                'Status files are not normalized.\n'
                'Fix these issues with:\n'
                '%s %s -w%s%s' % (dart, normalize, lineSep,
                                  lineSep.join(unformatted_files)))
        ]

    return []


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


def _CheckClangTidy(input_api, output_api):
    """Run clang-tidy on VM changes."""

    # Only run clang-tidy on linux x64.
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        return []

    # Run only for modified .cc or .h files.
    files = []
    for f in input_api.AffectedFiles():
        path = f.LocalPath()
        if is_cpp_file(path) and os.path.isfile(path): files.append(path)

    if not files:
        return []

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

    # Only run clang-format on linux x64.
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        return []

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
        if is_cpp_file(path) and os.path.isfile(path):
            files.append(path)

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
        'buildtools/linux-x64/clang/bin/clang-format',
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
        "pkg/analyzer/lib/src/error/error_code_values.g.dart",
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

    # Verify the linter's `example/all.yaml` file.
    if any(f.LocalPath().startswith('pkg/linter/lib/src/rules')
           for f in input_api.AffectedFiles()):
        args = [
            "tools/sdks/dart-sdk/bin/dart",
            "pkg/linter/tool/checks/check_all_yaml.dart",
        ]
        stdout = input_api.subprocess.check_output(args).strip()
        if not stdout:
            return []

        return [
            output_api.PresubmitError(
                "The check_all_yaml linter tool revealed issues:",
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
    # * Verify that `machine.json` is not outdated, when any
    #   `pkg/linter/lib/src/rules` file is modified.
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


def _CheckNoNewObservatoryServiceTests(input_api, output_api):
    """Ensures that no new tests are added to the Observatory test suite."""
    files = []

    for f in input_api.AffectedFiles(include_deletes=False):
        path = f.LocalPath()
        if is_dart_file(path) and path.startswith(
                "runtime/observatory/tests/service/") and f.Action(
                ) == 'A' and os.path.isfile(path):
            files.append(path)

    if not files:
        return []

    return [
        output_api.PresubmitError(
            'New VM service tests should be added to pkg/vm_service/test, ' +
            'not runtime/observatory/tests/service:\n' + '\n'.join(files))
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


def _CommonChecks(input_api, output_api):
    results = []
    results.extend(_CheckValidHostsInDEPS(input_api, output_api))
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
    results.extend(_CheckNoNewObservatoryServiceTests(input_api, output_api))
    results.extend(_CheckDevCompilerSync(input_api, output_api))
    return results


def CheckChangeOnCommit(input_api, output_api):
    return _CommonChecks(input_api, output_api)


def CheckChangeOnUpload(input_api, output_api):
    return _CommonChecks(input_api, output_api)
