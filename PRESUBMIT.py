# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Top-level presubmit script for Dart.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""

import imp
import os
import os.path
import scm
import subprocess
import tempfile
import platform

def is_cpp_file(path):
    return path.endswith('.cc') or path.endswith('.h')

def _CheckFormat(input_api,
                 identification,
                 extension,
                 windows,
                 hasFormatErrors,
                 should_skip=lambda path: False):
    local_root = input_api.change.RepositoryRoot()
    upstream = input_api.change._upstream
    unformatted_files = []
    for git_file in input_api.AffectedTextFiles():
        if git_file.LocalPath().startswith("pkg/front_end/testcases/"):
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


def _CheckBuildStatus(input_api, output_api):
    results = []
    status_check = input_api.canned_checks.CheckTreeIsOpen(
        input_api,
        output_api,
        json_url='http://dart-status.appspot.com/current?format=json')
    results.extend(status_check)
    return results


def _CheckDartFormat(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    upstream = input_api.change._upstream
    utils = imp.load_source('utils',
                            os.path.join(local_root, 'tools', 'utils.py'))

    prebuilt_dartfmt = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dartfmt')

    windows = utils.GuessOS() == 'win32'
    if windows:
        prebuilt_dartfmt += '.bat'

    if not os.path.isfile(prebuilt_dartfmt):
        print('WARNING: dartfmt not found: %s' % (prebuilt_dartfmt))
        return []

    def HasFormatErrors(filename=None, contents=None):
        # Don't look for formatting errors in multitests. Since those are very
        # sensitive to whitespace, many cannot be formatted with dartfmt without
        # breaking them.
        if filename and filename.endswith('_test.dart'):
            with open(filename) as f:
                contents = f.read()
                if '//#' in contents:
                    return False

        args = [prebuilt_dartfmt, '--set-exit-if-changed']
        if not contents:
            args += [filename, '-n']

        process = subprocess.Popen(
            args, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        process.communicate(input=contents)

        # Check for exit code 1 explicitly to distinguish it from a syntax error
        # in the file (exit code 65). The repo contains many Dart files that are
        # known to have syntax errors for testing purposes and which can't be
        # parsed and formatted. Don't treat those as errors.
        return process.returncode == 1

    unformatted_files = _CheckFormat(input_api, "dartfmt", ".dart", windows,
                                     HasFormatErrors)

    if unformatted_files:
        lineSep = " \\\n"
        if windows:
            lineSep = " ^\n"
        return [
            output_api.PresubmitError(
                'File output does not match dartfmt.\n'
                'Fix these issues with:\n'
                '%s -w%s%s' % (prebuilt_dartfmt, lineSep,
                               lineSep.join(unformatted_files)))
        ]

    return []


def _CheckStatusFiles(input_api, output_api):
    local_root = input_api.change.RepositoryRoot()
    upstream = input_api.change._upstream
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
        process = subprocess.Popen(
            args, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        process.communicate(input=contents)
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
    except input_api.subprocess.CalledProcessError, error:
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
    layering_check = imp.load_source(
        'layering_check',
        os.path.join(local_root, 'runtime', 'tools', 'layering_check.py'))
    errors = layering_check.DoCheck(local_root)
    if errors:
        return [
            output_api.PresubmitError(
                'Layering check violation for C++ sources.',
                long_text='\n'.join(errors))
        ]
    else:
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
        if is_cpp_file(path): files.append(path)

    args = [
        './buildtools/linux-x64/clang/bin/clang-tidy',
        '-checks=readability-implicit-bool-conversion',
    ]
    args.extend(files)
    args.append('--')
    args.extend([
        '-I.',
        '-Iruntime',
        '-Iruntime/include',
        '-Ithird_party/tcmalloc/gperftools/src ',
        '-DTARGET_ARCH_X64',
        '-DDEBUG',
        '-DTARGET_OS_LINUX',
    ])
    stdout = input_api.subprocess.check_output(args).strip()
    if not stdout:
        return []

    return [
        output_api.PresubmitError(
            'The `clang-tidy` linter revealed issues:',
            long_text=stdout)
    ]

def CheckChangeOnCommit(input_api, output_api):
    return (_CheckValidHostsInDEPS(input_api, output_api) + _CheckBuildStatus(
        input_api, output_api) + _CheckDartFormat(input_api, output_api) +
            _CheckStatusFiles(input_api, output_api) + _CheckLayering(
                input_api, output_api) + _CheckClangTidy(
                input_api, output_api))


def CheckChangeOnUpload(input_api, output_api):
    return (_CheckValidHostsInDEPS(input_api, output_api) + _CheckDartFormat(
        input_api, output_api) + _CheckStatusFiles(input_api, output_api) +
            _CheckLayering(input_api, output_api) + _CheckClangTidy(
                input_api, output_api))
