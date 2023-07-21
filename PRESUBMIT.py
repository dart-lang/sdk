#!/usr/bin/env python3
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Top-level presubmit script for Dart.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import datetime
import imp
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


def _CheckFormat(input_api,
                 identification,
                 extension,
                 windows,
                 hasFormatErrors: Callable[[str, str], bool],
                 should_skip=lambda path: False):
    local_root = input_api.change.RepositoryRoot()
    upstream = input_api.change._upstream
    unformatted_files = []
    for git_file in input_api.AffectedTextFiles():
        if git_file.LocalPath().startswith("pkg/front_end/testcases/"):
            continue
        if git_file.LocalPath().startswith("pkg/front_end/parser_testcases/"):
            continue
        if should_skip(git_file.LocalPath()):
            continue
        filename = git_file.AbsoluteLocalPath()
        if filename.endswith(extension) and hasFormatErrors(filename=filename):
            old_version_has_errors = False
            try:
                path = git_file.LocalPath()
                if windows:
                    # Git expects a linux style path.
                    path = path.replace(os.sep, '/')
                old_contents = scm.GIT.Capture(['show', upstream + ':' + path],
                                               cwd=local_root,
                                               strip_out=False)
                if hasFormatErrors(contents=old_contents):
                    old_version_has_errors = True
            except subprocess.CalledProcessError as e:
                old_version_has_errors = False

            if old_version_has_errors:
                print("WARNING: %s has existing and possibly new %s issues" %
                      (git_file.LocalPath(), identification))
            else:
                unformatted_files.append(filename)

    return unformatted_files


def _CheckDartFormat(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    utils = imp.load_source('utils',
                            os.path.join(local_root, 'tools', 'utils.py'))

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

    def HasFormatErrors(filename: str = None, contents: str = None):
        # Don't look for formatting errors in multitests. Since those are very
        # sensitive to whitespace, many cannot be reformatted without breaking
        # them.
        if filename and filename.endswith('_test.dart'):
            with open(filename) as f:
                contents = f.read()
                if '//#' in contents:
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
        else:
            args.append(filename)
            process = subprocess.run(args)

        # Check for exit code 1 explicitly to distinguish it from a syntax error
        # in the file (exit code 65). The repo contains many Dart files that are
        # known to have syntax errors for testing purposes and which can't be
        # parsed and formatted. Don't treat those as errors.
        return process.returncode == 1

    unformatted_files = _CheckFormat(input_api, "dart format", ".dart", windows,
                                     HasFormatErrors)

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
    utils = imp.load_source('utils',
                            os.path.join(local_root, 'tools', 'utils.py'))

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

    def HasFormatErrors(filename=None, contents=None):
        args = [dart, lint] + (['-t'] if contents else [filename])
        process = subprocess.run(args, input=contents, text=True)
        return process.returncode != 0

    def should_skip(path):
        return (path.startswith("pkg/status_file/test/data/") or
                path.startswith("pkg/front_end/"))

    unformatted_files = _CheckFormat(input_api, "status file", ".status",
                                     windows, HasFormatErrors, should_skip)

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
    compiler_layering_check = imp.load_source(
        'compiler_layering_check',
        os.path.join(local_root, 'runtime', 'tools',
                     'compiler_layering_check.py'))
    errors = compiler_layering_check.DoCheck(local_root)
    embedder_layering_check = imp.load_source(
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
            with open(path) as f:
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


def _CommonChecks(input_api, output_api):
    results = []
    results.extend(_CheckValidHostsInDEPS(input_api, output_api))
    results.extend(_CheckDartFormat(input_api, output_api))
    results.extend(_CheckStatusFiles(input_api, output_api))
    results.extend(_CheckLayering(input_api, output_api))
    results.extend(_CheckClangTidy(input_api, output_api))
    results.extend(_CheckTestMatrixValid(input_api, output_api))
    results.extend(
        input_api.canned_checks.CheckPatchFormatted(input_api, output_api))
    results.extend(_CheckCopyrightYear(input_api, output_api))
    return results


def CheckChangeOnCommit(input_api, output_api):
    return _CommonChecks(input_api, output_api)


def CheckChangeOnUpload(input_api, output_api):
    return _CommonChecks(input_api, output_api)
