#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""Tool for automating creation of a Dart bundle."""

import optparse
import os
from os import path
import shutil
import subprocess
import sys

import utils


class BundleMaker(object):
  """Main class for building a Dart bundle."""

  def __init__(self, top_dir=None, dest=None, verbose=False, skip_build=False):
    self._top_dir = top_dir
    self._dest = dest
    self._verbose = verbose
    self._skip_build = skip_build
    self._os = utils.GuessOS()
    self._release_build_root = utils.GetBuildRoot(self._os, mode='release',
                                                  arch='ia32')
    self._debug_build_root = utils.GetBuildRoot(self._os, mode='debug',
                                                arch='ia32')
    self._dartc_build_root = utils.GetBuildRoot(self._os, mode='release',
                                                arch='ia32')

  @staticmethod
  def BuildOptions():
    """Make an option parser with the options supported by this tool.

    Returns:
      A newly created OptionParser.
    """
    op = optparse.OptionParser('usage: %prog [options]')
    op.add_option('-d', '--dest')
    op.add_option('-v', '--verbose', default=False, action='store_true')
    op.add_option('--skip-build', default=False, action='store_true')
    return op

  @staticmethod
  def CheckOptions(op, top_dir, cmd_line_args):
    """Check the command line arguments.

    Args:
      op: An OptionParser (see BuildOptions).
      top_dir: The top-level source directory.
      cmd_line_args: The command line arguments.

    Returns:
      A dict with the analyzed options and other values. The dict
      includes these keys:
        dest: The destition directory for storing the bundle.
        verbose: Whether the tool should be verbose.
        top_dir: Same as top_dir argument.
        skip_build: Whether the tool should skip the build steps.
    """
    (options, args) = op.parse_args(args=cmd_line_args)
    if args:
      # Terminate program.
      op.error('extra arguments on command line')
    dest = options.dest
    if not dest:
      dest = path.normpath(path.join(top_dir, 'new_bundle'))
      print 'Bundle is saved to %r' % dest
    if not path.exists(dest):
      os.makedirs(dest)
    elif not path.isdir(dest):
      # Terminate program.
      op.error('%s: is not a directory' % dest)
    return {
        'dest': dest,
        'verbose': options.verbose,
        'top_dir': top_dir,
        'skip_build': options.skip_build,
        }

  def _PrintConfiguration(self):
    for member in [m for m in dir(self) if not m.startswith('_')]:
      value = getattr(self, member)
      if not callable(value):
        print '%s = %r' % (member, value)

  def _GetTool(self, name):
    return self._GetLocation('tools', name)

  def _GetLocation(self, *arguments):
    location = path.join(self._top_dir, *arguments)
    if not path.exists(location):
      raise utils.Error('%s: does not exist' % location)
    return location

  def _InvokeTool(self, project, name, *arguments):
    location = self._GetLocation(project)
    tool = path.relpath(self._GetTool(name), location)
    command_array = [tool]
    for argument in arguments:
      command_array.append(str(argument))
    stdout = subprocess.PIPE
    if self._verbose:
      print 'Invoking', ' '.join(command_array)
      print 'in', location
      stdout = None  # In verbose mode we want to see the output from the tool.
    proc = subprocess.Popen(command_array,
                            cwd=location,
                            stdout=stdout,
                            stderr=subprocess.STDOUT)
    stdout = proc.communicate()[0]
    exit_code = proc.wait()
    if exit_code != 0:
      sys.stderr.write(stdout)
      raise utils.Error('%s returned %s' % (name, exit_code))
    elif self._verbose:
      print name, 'returned', exit_code

  def _GetReleaseOutput(self, project, name):
    return self._GetLocation(project, self._release_build_root, name)

  def _GetDebugOutput(self, project, name):
    return self._GetLocation(project, self._debug_build_root, name)

  def _GetDartcOutput(self, project, name):
    return self._GetLocation(project, self._dartc_build_root, name)

  def _GetNativeDest(self, mode, name):
    return path.join('native', self._os, utils.GetBuildConf(mode, 'ia32'), name)

  def _EnsureExists(self, artifact):
    if not path.exists(artifact):
      raise utils.Error('%s: does not exist' % artifact)

  def _BuildArtifacts(self):
    if not self._skip_build:
      self._InvokeTool('runtime', 'build.py', '--arch=ia32',
                       '--mode=release,debug')
      self._InvokeTool('compiler', 'build.py', '--arch=ia32', '--mode=release')
      self._InvokeTool('language', 'build.py', '--arch=ia32', '--mode=release')

    release_vm = self._GetReleaseOutput('runtime', 'dart_bin')
    self._EnsureExists(release_vm)
    release_vm_dest = self._GetNativeDest('release', 'dart_bin')

    debug_vm = self._GetDebugOutput('runtime', 'dart_bin')
    self._EnsureExists(debug_vm)
    debug_vm_dest = self._GetNativeDest('debug', 'dart_bin')

    dartc_bundle = self._GetDartcOutput('compiler', 'compiler')
    self._EnsureExists(dartc_bundle)
    return (
        (self._GetLocation('bundle', 'bin', 'dart'), 'dart', False),
        (release_vm, release_vm_dest, True),
        (debug_vm, debug_vm_dest, True),
        (dartc_bundle, 'compiler', False),
        (self._GetLocation('bundle', 'samples'), 'samples', False),
        (self._GetLocation('bundle', 'README'), 'README.txt', False),
        (self._GetReleaseOutput('language', 'guide'), 'guide', False),
        )

  def _CopyCorelib(self):
    def ReadSources(sources, *paths):
      p = path.join(*paths)
      return [self._GetLocation(p, s) for s in sources if s.endswith('.dart')]
    gypi = self._GetLocation('corelib', 'src', 'corelib_sources.gypi')
    sources = []
    with open(gypi, 'r') as f:
      text = f.read()
      sources.extend(ReadSources(eval(text)['sources'], 'corelib', 'src'))
    gypi = self._GetLocation('runtime', 'lib', 'lib_sources.gypi')
    with open(gypi, 'r') as f:
      text = f.read()
      sources.extend(ReadSources(eval(text)['sources'], 'runtime', 'lib'))
    dest = path.join(self._dest, 'lib', 'core')
    if not path.exists(dest):
      os.makedirs(dest)
    for source in sources:
      if self._verbose:
        print 'Copying', source, 'to', dest
      shutil.copy2(source, dest)

  def MakeBundle(self):
    """Build and install all the components of a bundle.

    Returns:
      0 if the bundle was created successfully.
    """
    if self._verbose:
      self._PrintConfiguration()
    for artifact, reldest, strip in self._BuildArtifacts():
      dest = path.join(self._dest, reldest)
      if not path.exists(path.dirname(dest)):
        os.makedirs(path.dirname(dest))
      if self._verbose:
        print 'Copying', artifact, 'to', dest
      if path.isdir(artifact):
        assert not strip
        if path.exists(dest):
          shutil.rmtree(dest)
        shutil.copytree(artifact, dest)
      else:
        if strip:
          os.system('strip -o %s %s' % (dest, artifact))
        else:
          shutil.copy2(artifact, dest)
    self._CopyCorelib()
    os.system('chmod -R a+rX %s' % self._dest)
    return 0


def main():
  top_dir = path.normpath(path.join(path.dirname(sys.argv[0]), os.pardir))
  cmd_line_args = sys.argv[1:]
  try:
    op = BundleMaker.BuildOptions()
    options = BundleMaker.CheckOptions(op, top_dir, cmd_line_args)
  except utils.Error:
    return 1
  sys.exit(BundleMaker(**options).MakeBundle())


if __name__ == '__main__':
  main()
