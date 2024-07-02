#!/usr/bin/env python3
# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This program executes Dart programs on RBE using rewrapper by parsing the
# source code to locate the input files, and recognizes the command line options
# of well known programs to determine the output files.

# New executions during the Dart SDK build needs to be supported here in order
# to speed up the build with RBE. See the argument parser below.

import json
import os
import re
import subprocess
import sys


# Run a command, swallowing the output unless there is an error.
def run_command(command, strategy):
    try:
        subprocess.check_output(command, stderr=subprocess.STDOUT)
        return 0
    except subprocess.CalledProcessError as e:
        print(e.output.decode("utf-8"))
        if strategy == 'remote':
            joined = ' '.join(command)
            print(f'''Failed to run command remotely: {joined}

If you're seeing this error on a bot and it doesn't happen locally, then you may
need to teach the script build/rbe/rewrapper_dart.py what the appropriate input
and outputs files of the command are. You can see the list of used inputs and
outputs in the rewrapper invocation above. To reproduce this error locally, try
forcing a remote build by setting the RBE_exec_strategy=remote environment
variable.
''')
        sys.exit(1)
    except OSError as e:
        print(e.strerror)
        sys.exit(1)


# Loads the package config file.
def load_package_config(exec_root):
    path = os.path.join(exec_root, '.dart_tool', 'package_config.json')
    with open(path, 'r') as file:
        return json.load(file)


# Resolves a Dart import URI using the package config.
def resolve_uri(uri, exec_root, package_config, whole_dir=False):
    if uri.startswith('package:'):
        match = re.search(r'package:([^/]*)/(.*)', uri)
        package_name = match.groups()[0]
        relative = match.groups()[1]
        package_data = next(pkg for pkg in package_config['packages']
                            if pkg['name'] == package_name)
        package_root = package_data['rootUri']
        package_root = package_root[3:]  # Remove leading ../
        package_uri = package_data['packageUri']
        if whole_dir:
            uri = package_root + '/' + package_uri
        else:
            uri = package_root + '/' + package_uri + relative
    return uri


# Lists the imports of a Dart file uri using the package config and a rough
# parser that recognizes fairly traditional imports. This is designed to be much
# faster than actually invoking the front end.
def list_imports(uri, exec_root, package_config):
    if uri.startswith('dart:'):
        return set()
    path = os.path.join(exec_root, resolve_uri(uri, exec_root, package_config))
    file = open(path, 'r')
    imports = set()
    for line in file.readlines():
        tokens = [token for token in re.split(r'\s+', line) if token != '']
        if not tokens or tokens[0] in [
                '//', '///', '/*', '*/', '#!', 'library', 'show'
        ]:
            continue
        # Imports must happen before definitions.
        if tokens[0] in ['const', 'class', 'enum']:
            break
        if 2 <= len(tokens
                   ) and tokens[0] == 'if' and tokens[1] == '(dart.library.io)':
            tokens = ['import'] + tokens[2:]
        if tokens[0] not in ['import', 'export', 'part']:
            continue
        if len(tokens) < 2:
            raise Exception(f'Bad import statement: {path}: {line}')
        if tokens[0] == 'part' and tokens[1] == 'of':
            continue
        token = tokens[1].replace('"', '').replace("'", '').replace(';', '')
        if token.startswith('dart:'):
            continue
        if not ':' in token:
            dirname = os.path.dirname(uri)
            while token.startswith('..'):
                token = token[3:]
                dirname = os.path.dirname(dirname)
            token = dirname + '/' + token
        imports.add(token)
    file.close()
    return imports


# Transitively compute the set of dart files needed to execute the specified
# entry point using the package config.
def find_inputs(uris, exec_root, package_config):
    inputs = set(uris)
    unexplored = set(uris)
    while unexplored:
        uri = unexplored.pop()
        imports = list_imports(uri, exec_root, package_config)
        for uri in imports:
            if not uri in inputs:
                inputs.add(uri)
                unexplored.add(uri)
    return inputs


# Rewrite absolute paths in an argument to be relative.
def rewrite_absolute(arg, exec_root, working_directory):
    # The file:// schema does not work with relative paths as they are parsed as
    # the authority by the dart Uri class.
    arg = arg.replace('file:///' + exec_root, '../../')
    arg = arg.replace('file://' + exec_root, '../../')
    # Replace the absolute exec root by a relative path to the exec root.
    arg = arg.replace(exec_root, '../../')
    # Simplify paths going to the exec root and back into the out directory.
    # Carefully ensure the whole path isn't optimized away.
    if arg.endswith(f'../../{working_directory}/'):
        arg = arg.replace(f'../../{working_directory}/', '.')
    else:
        arg = arg.replace(f'../../{working_directory}/', '')
    return arg


# Parse the command line execution to recognize well known programs during the
# Dart SDK build, so the inputs and output files can be determined, and the
# command can be offloaded to RBE.
#
# RBE needs a command to run, a list of input files, and a list of output files,
# and it then executes the command remotely and caches the result. Absolute
# paths must not occur in the command as the remote execution will happen in
# another directory. However, since we currently rely on absolute paths, we work
# around the issue and rewrite the absolute paths accordingly until the problem
# is fixed on our end.
#
# This is a parser that handles nested commands executing each other, taking
# care to know whose options it is currently parsing, and extracting the
# appropriate information from each argument. Every invoked program and option
# during the build needs to be supported here, otherwise the remote command may
# be inaccurate and not have right inputs and outputs. Although maintaining this
# parser takes some effort, it is being paid back in the builders being sped up
# massively on cache hits, as well as speeding up any local developers that
# build code already built by the bots.
#
# To add a new program, recognize the entry point and define its parser method.
# To add a new option, parse the option in the appropriate method and either
# ignore it or recognize any input and output files. All invoked options needs
# be allowlisted here know we didn't accidentally misunderstand the invoked
# command when running it remotely.
class Rewrapper:

    def __init__(self, argv):
        self.dart_subdir = None
        self.depfiles = None
        self.entry_points = set()
        self.exec_root = None
        self.exec_strategy = 'remote'
        self.exec_strategy_explicit = False
        self.extra_paths = set()
        self.outputs = []
        self.no_remote = None
        self.argv = argv
        self.optarg = None
        self.optind = 0
        self.parse()

    @property
    def has_next_arg(self):
        return self.optind + 1 < len(self.argv)

    def next_arg(self):
        self.optind += 1
        return self.argv[self.optind]

    def get_option(self, options):
        arg = self.argv[self.optind]
        for option in options:
            if arg == option:
                self.optind += 1
                self.optarg = self.argv[self.optind]
                return True
            elif option.startswith('--') and arg.startswith(f'{option}='):
                self.optarg = arg[len(f'{option}='):]
                return True
            elif option[0] == '-' and option[1] != '-' and arg.startswith(
                    option):
                self.optarg = arg[len(option):]
                return True
        return False

    def unsupported(self, state, arg):
        raise Exception(f'''Unsupported operand in state {state}: {arg}

You need to recognize the argument/option in the build/rbe/rewrapper_dart.py
script in order to execute this command remotely on RBE. Read the big comments
in the file explaining what this script is and how it works. Follow this stack
trace to find the place to insert the appropriate support.
''')

    def rebase(self, path):
        if path.startswith('package:'):
            return path
        # Handle the use of paths starting with an extra slash.
        if path.startswith('org-dartlang-kernel-service:///'):
            path = os.path.join(self.exec_root,
                                path[len('org-dartlang-kernel-service:///'):])
        if path.startswith('org-dartlang-kernel-service://'):
            path = os.path.join(self.exec_root,
                                path[len('org-dartlang-kernel-service://'):])
        # Handle the use of paths starting with an extra slash.
        if path.startswith('file:////'):
            path = path[len('file:///'):]
        elif path.startswith('file://'):
            path = path[len('file://'):]
        path = os.path.abspath(path)
        if not path.startswith(self.exec_root):
            raise Exception(f"Path isn't inside exec_root: {path}")
        return path[len(self.exec_root):]

    def parse(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if arg == 'rewrapper' or arg.endswith('/rewrapper'):
                return self.parse_rewrapper()
            else:
                self.unsupported('rewrapper_dart', arg)

    def parse_rewrapper(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['--cfg']):
                with open(self.optarg, 'r') as fp:
                    for line in fp.readlines():
                        key, value = fp.split('=')
                        if key == 'exec_root':
                            self.exec_root = value
                        elif key == 'exec_strategy':
                            self.exec_strategy = value
            elif self.get_option(['--exec_root']):
                self.exec_root = os.path.abspath(self.optarg)
                if not self.exec_root.endswith('/'):
                    self.exec_root += '/'
            elif self.get_option(['--exec_strategy']):
                self.exec_strategy = self.optarg
                self.exec_strategy_explicit = True
            elif arg == '--':
                env_exec_strategy = os.environ.get('RBE_exec_strategy')
                if env_exec_strategy and not self.exec_strategy_explicit:
                    self.exec_strategy = env_exec_strategy
            elif arg.startswith('-'):
                pass  # Ignore unknown rewrapper options.
            elif arg.endswith('/dart'):
                self.dart_subdir = os.path.dirname(arg)
                return self.parse_dart()
            elif arg.endswith('/gen_snapshot') or arg.endswith(
                    '/gen_snapshot_product'):
                return self.parse_gen_snapshot()
            else:
                self.unsupported('rewrapper', arg)

    def parse_dart(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['--dfe']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option(['--snapshot']):
                self.outputs.append(self.rebase(self.optarg))
            elif self.get_option(['--depfile']):
                self.depfiles = [self.rebase(self.optarg)]
            elif self.get_option(['--snapshot-depfile']):
                self.depfiles = [self.rebase(self.optarg)]
            elif self.get_option([
                    '--packages', '-D', '--snapshot-kind',
                    '--depfile_output_filename', '--coverage',
                    '--ignore-unrecognized-flags'
            ]):
                pass
            elif arg in ['--deterministic', '--sound-null-safety']:
                pass
            elif arg == 'compile':
                self.extra_paths.add(
                    self.rebase(
                        os.path.join(self.dart_subdir,
                                     'snapshots/dartdev.dart.snapshot')))
                self.extra_paths.add(
                    self.rebase(os.path.join(self.dart_subdir, '../lib')))
                return self.parse_compile()
            elif arg == '../../pkg/compiler/lib/src/dart2js.dart':
                self.entry_points.add(self.rebase(arg))
                return self.parse_dart2js()
            elif arg == 'gen/utils/compiler/dart2js.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_dart2js()
            elif arg == '../../pkg/dev_compiler/bin/dartdevc.dart':
                self.entry_points.add(self.rebase(arg))
                return self.parse_dartdevc()
            elif arg == 'gen/utils/ddc/dartdevc.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_dartdevc()
            elif arg == 'gen/utils/dartanalyzer/dartanalyzer.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_dartanalyzer()
            elif arg == 'gen/utils/analysis_server/analysis_server.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_analysis_server()
            elif arg == '../../pkg/front_end/tool/_fasta/compile_platform.dart':
                self.entry_points.add(self.rebase(arg))
                return self.parse_compile_platform()
            elif arg == '../../utils/compiler/create_snapshot_entry.dart':
                self.entry_points.add(self.rebase(arg))
                self.extra_paths.add('tools/make_version.py')
                # This step is very cheap and python3 isn't in the docker image.
                self.no_remote = True
                return self.parse_create_snapshot_entry()
            elif arg == '../../utils/bazel/kernel_worker.dart':
                self.entry_points.add(self.rebase(arg))
                return self.parse_kernel_worker()
            elif arg == '../../pkg/vm/bin/gen_kernel.dart':
                self.entry_points.add(self.rebase(arg))
                return self.parse_gen_kernel()
            elif arg == 'gen/utils/kernel-service/frontend_server.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_frontend_server()
            elif arg == 'gen/utils/dtd/generate_dtd_snapshot.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_generate_dtd_snapshot()
            elif arg == 'gen/utils/dds/generate_dds_snapshot.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_generate_dds_snapshot()
            elif arg == 'gen/utils/bazel/kernel_worker.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_kernel_worker()
            elif arg == 'gen/utils/dartdev/generate_dartdev_snapshot.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_generate_dartdev_snapshot()
            elif arg == 'gen/utils/gen_kernel/bootstrap_gen_kernel.dill':
                self.extra_paths.add(self.rebase(arg))
                return self.parse_bootstrap_gen_kernel()
            elif arg == 'gen/utils/kernel-service/kernel-service_snapshot.dart.dill':
                self.extra_paths.add(self.rebase(arg))
                self.extra_paths.add(
                    self.rebase(
                        os.path.join(self.dart_subdir,
                                     'vm_platform_strong.dill')))
                return self.parse_kernel_service_snapshot()
            else:
                self.unsupported('dart', arg)

    def parse_compile(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if arg == 'js':
                self.extra_paths.add(
                    self.rebase(
                        os.path.join(self.dart_subdir,
                                     'snapshots/dart2js.dart.snapshot')))
                return self.parse_dart2js()
            else:
                self.unsupported('compile', arg)

    def parse_dart2js(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['-o', '--output']):
                self.outputs.append(self.rebase(self.optarg))
                self.outputs.append(
                    self.rebase(self.optarg.replace('.js', '.js.map')))
            elif self.get_option(['--platform-binaries']):
                self.extra_paths.add(
                    self.rebase(
                        os.path.join(self.optarg, 'dart2js_platform.dill')))
            elif self.get_option([
                    '--invoker', '--packages', '--libraries-spec',
                    '--snapshot-kind', '--depfile_output_filename',
                    '--coverage', '--ignore-unrecognized-flags'
            ]):
                pass
            elif arg in [
                    '--canary',
                    '--enable-asserts',
                    '-m',
                    '--minify',
                    '--no-source-maps',
            ]:
                pass
            elif not arg.startswith('-'):
                self.entry_points.add(self.rebase(arg))
            else:
                self.unsupported('dart2js', arg)

    def parse_dartdevc(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['-o', '--output']):
                self.outputs.append(self.rebase(self.optarg))
                self.outputs.append(
                    self.rebase(self.optarg.replace('.js', '.js.map')))
                self.outputs.append(
                    self.rebase(self.optarg.replace('.js', '.dill')))
            elif self.get_option(['--dart-sdk-summary']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option([
                    '--multi-root-scheme', '--multi-root-output-path',
                    '--modules'
            ]):
                pass
            elif arg in [
                    '--canary', '--no-summarize', '--sound-null-safety',
                    '--no-sound-null-safety'
            ]:
                pass
            elif not arg.startswith('-'):
                if arg.endswith('.dart'):
                    self.entry_points.add(self.rebase(arg))
                else:
                    self.extra_paths.add(self.rebase(arg))
            else:
                self.unsupported('dartdevc', arg)

    def parse_dartanalyzer(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if arg in ['--help']:
                pass
            else:
                self.unsupported('dartanalyzer', arg)

    def parse_analysis_server(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['--sdk']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option(['--train-using']):
                self.extra_paths.add(self.rebase(self.optarg))
                self.entry_points.add(
                    self.rebase(os.path.join(self.optarg, 'compiler_api.dart')))
                # This file isn't referenced from compiler_api.dart.
                self.entry_points.add(
                    self.rebase(
                        os.path.join(self.optarg, 'src/io/mapped_file.dart')))
            else:
                self.unsupported('analysis_server', arg)

    def parse_compile_platform(self):
        compile_platform_args = []
        single_root_scheme = None
        single_root_base = None
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['--single-root-scheme']):
                single_root_scheme = self.optarg
            elif self.get_option(['--single-root-base']):
                single_root_base = self.optarg
                # Remove trailing slash to avoid duplicate slashes later.
                if 1 < len(single_root_base) and single_root_base[-1] == '/':
                    single_root_base = single_root_base[:-1]
            elif self.get_option(['-D', '--target']):
                pass
            elif arg in [
                    '--no-defines',
                    '--nnbd-strong',
                    '--nnbd-weak',
                    '--exclude-source',
            ]:
                pass
            elif not arg.startswith('-'):
                if len(compile_platform_args) == 0:
                    pass  # e.g. dart:core
                elif len(compile_platform_args) == 1:
                    sdk = arg  # sdk via libraries.json
                    if sdk.startswith(f'{single_root_scheme}:///'):
                        sdk = sdk[len(f'{single_root_scheme}:///'):]
                        sdk = os.path.join(single_root_base, sdk)
                    if sdk.endswith('libraries.json'):
                        sdk = os.path.dirname(sdk)
                    self.extra_paths.add(self.rebase(sdk))
                elif len(compile_platform_args) == 2:  # vm_outline_strong dill
                    arg = self.rebase(arg)
                elif len(compile_platform_args) == 3:  # platform dill
                    arg = self.rebase(arg)
                    self.outputs.append(arg)
                elif len(compile_platform_args) == 4:  # outline dill
                    arg = self.rebase(arg)
                    self.outputs.append(arg)
                    if arg != compile_platform_args[2]:
                        self.extra_paths.add(compile_platform_args[2])
                else:
                    self.unsupported('compile_platform', arg)
                compile_platform_args.append(arg)
            else:
                self.unsupported('compile_platform', arg)

    def parse_create_snapshot_entry(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['--output_dir']):
                self.outputs.append(self.rebase(self.optarg))
            elif arg in ['--no-git-hash']:
                pass
            else:
                self.unsupported('create_snapshot_entry', arg)

    def parse_kernel_worker(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['-o', '--output']):
                self.outputs.append(self.rebase(self.optarg))
            elif self.get_option(['--dart-sdk-summary']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option(['--source']):
                self.entry_points.add(self.rebase(self.optarg))
            elif self.get_option(
                ['--packages-file', '--target', '--dart-sdk-summary']):
                pass
            elif arg in [
                    '--summary-only',
                    '--sound-null-safety',
                    '--no-sound-null-safety',
            ]:
                pass
            else:
                self.unsupported('kernel_worker', arg)

    def parse_gen_kernel(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['-o', '--output']):
                self.outputs.append(self.rebase(self.optarg))
            elif self.get_option(['--platform']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option([
                    '--packages', '-D', '--filesystem-root',
                    '--filesystem-scheme'
            ]):
                pass
            elif arg in ['--no-aot', '--no-embed-sources']:
                pass
            elif not arg.startswith('-'):
                self.entry_points.add(self.rebase(arg))
            else:
                self.unsupported('gen_kernel', arg)

    def parse_bootstrap_gen_kernel(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['-o', '--output']):
                self.outputs.append(self.rebase(self.optarg))
            elif self.get_option(['--platform']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option(['--packages', '-D']):
                pass
            elif arg in [
                    '--aot',
                    '--no-aot',
                    '--no-embed-sources',
                    '--no-link-platform',
                    '--enable-asserts',
            ]:
                pass
            elif self.get_option(['--depfile']):
                self.depfiles = [self.rebase(self.optarg)]
            elif not arg.startswith('-'):
                self.entry_points.add(self.rebase(arg))
            else:
                self.unsupported('bootstrap_gen_kernel', arg)

    def parse_kernel_service_snapshot(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['--train']):
                self.entry_points.add(self.rebase(self.optarg))
            else:
                self.unsupported('kernel_service_snapshot', arg)

    def parse_frontend_server(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['--platform']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option(['--sdk-root']):
                pass
            elif arg in ['--train']:
                pass
            elif not arg.startswith('-'):
                self.entry_points.add(self.rebase(arg))
            else:
                self.unsupported('frontend_server', arg)

    def parse_generate_dtd_snapshot(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if arg in ['--train']:
                pass
            else:
                self.unsupported('generate_dtd_snapshot', arg)

    def parse_generate_dds_snapshot(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if arg in ['--help']:
                pass
            else:
                self.unsupported('generate_dds_snapshot', arg)

    def parse_kernel_worker(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if arg in ['--help']:
                pass
            elif self.get_option(['-o', '--output']):
                self.outputs.append(self.rebase(self.optarg))
            elif self.get_option(['--packages-file']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option(['--dart-sdk-summary']):
                self.extra_paths.add(self.rebase(self.optarg))
            elif self.get_option(['--source']):
                self.entry_points.add(self.rebase(self.optarg))
            elif self.get_option(['--target']):
                pass
            elif arg in [
                    '--sound-null-safety', '--no-sound-null-safety',
                    '--summary-only'
            ]:
                pass
            else:
                self.unsupported('kernel_worker', arg)

    def parse_generate_dartdev_snapshot(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if arg in ['--help']:
                pass
            else:
                self.unsupported('generate_dartdev_snapshot', arg)

    def parse_gen_snapshot(self):
        while self.has_next_arg:
            arg = self.next_arg()
            if self.get_option(['-o', '--output']):
                self.outputs.append(self.rebase(self.optarg))
            elif self.get_option([
                    '--vm_snapshot_data',
                    '--vm_snapshot_instructions',
                    '--isolate_snapshot_data',
                    '--isolate_snapshot_instructions',
                    '--elf',
            ]):
                self.outputs.append(self.rebase(self.optarg))
            elif self.get_option([
                    '--snapshot_kind', '--snapshot-kind', '--coverage',
                    '--ignore-unrecognized-flags'
            ]):
                pass
            elif arg in [
                    '--sound-null-safety',
                    '--deterministic',
                    '--enable-asserts',
            ]:
                pass
            elif not arg.startswith('-'):
                self.extra_paths.add(self.rebase(arg))
            else:
                self.unsupported('gen_snapshot', arg)


def main(argv):
    # Like gn_run_binary, run programs relative to the build directory. The
    # command is assumed to invoke rewrapper and end its rewrapper arguments
    # with an -- argument.
    rewrapper_end = 0
    for i in range(len(argv)):
        if argv[i] == '--' and rewrapper_end == 0:
            rewrapper_end = i + 1
            if not '/' in argv[i + 1]:
                argv[i + 1] = './' + argv[i + 1]
            break

    rewrapper = Rewrapper(argv)

    if rewrapper.exec_root == None:
        raise Exception('No rewrapper --exec_root was specified')

    if not rewrapper.outputs:
        raise Exception('No output files were recognized')

    # Run the command directly if it's not supported for remote builds.
    if rewrapper.no_remote:
        run_command(argv[rewrapper_end:], 'local')
        return 0

    # Determine the set of input and output files.
    package_config = load_package_config(rewrapper.exec_root)
    if not rewrapper.depfiles:
        rewrapper.depfiles = [output + '.d' for output in rewrapper.outputs]
    output_files = rewrapper.outputs + rewrapper.depfiles
    inputs = find_inputs(rewrapper.entry_points, rewrapper.exec_root,
                         package_config)
    paths = set(
        resolve_uri(uri, rewrapper.exec_root, package_config, whole_dir=True)
        for uri in inputs)
    paths.add(os.path.join('.dart_tool', 'package_config.json'))
    for path in rewrapper.extra_paths:
        paths.add(path)
    # Ensure the working directory is included if no inputs are inside it.
    working_directory = rewrapper.rebase('.')
    if not any([path.startswith(working_directory) for path in paths]):
        paths.add(rewrapper.rebase('build.ninja.stamp'))
    paths = list(paths)
    paths.sort()

    # Construct the final rewrapped command line.
    command = [argv[1]]
    command.append('--labels=type=tool')
    command.append('--inputs=' + ','.join(paths))
    command.append('--output_files=' + ','.join(output_files))
    # Absolute paths must not be used with RBE, but since the build currently
    # heavily relies on them, work around this issue by rewriting the command
    # to instead use relative paths. The Dart SDK build rules needs to be fixed
    # rather than doing this, but this is an initial step towards that goal
    # which will land in subsequent follow up changes.
    command += argv[2:rewrapper_end] + [
        rewrite_absolute(arg, rewrapper.exec_root, working_directory)
        for arg in argv[rewrapper_end:]
    ]

    # Finally execute the command remotely.
    run_command(command, rewrapper.exec_strategy)

    # Until the depfiles are fixed so they don't contain absoiute paths, we need
    # to rewrite the absoute paths appropriately.
    for depfile in rewrapper.depfiles:
        lines = []
        try:
            with open(os.path.join(rewrapper.exec_root, depfile), 'r') as file:
                lines = file.readlines()
            lines = [
                line.replace('/b/f/w', rewrapper.exec_root) for line in lines
            ]
            with open(os.path.join(rewrapper.exec_root, depfile), 'w') as file:
                file.writelines(lines)
        except FileNotFoundError:
            pass

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
