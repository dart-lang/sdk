#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import optparse
import os
import platform
import subprocess
import sys

"""A script used to revert one or a sequence of consecutive CLs, for svn and
git-svn users.
"""

def parse_args():
  parser = optparse.OptionParser()
  parser.add_option('--revisions', '-r', dest='rev_range', action='store',
                    default=None, help='The revision number(s) of the commits '
                    'you wish to undo. An individual number, or a range (8-10, '
                    '8..10, or 8:10).')
  args, _ = parser.parse_args()
  revision_range = args.rev_range
  if revision_range is None:
    maybe_fail('You must specify at least one revision number to revert.')
  if revision_range.find('-') > -1 or revision_range.find(':') > -1 or \
      revision_range.find('..') > -1:
    # We have a range of commits to revert.
    split = revision_range.split('-')
    if len(split) == 1:
      split = revision_range.split(':')
    if len(split) == 1:
      split = revision_range.split('..')
    start = int(split[0])
    end = int(split[1])
    if start > end:
      temp = start
      start = end
      end = temp
    if start != end:
      maybe_fail('Warning: Are you sure you want to revert a range of '
                 'revisions? If you just want to revert one CL, only specify '
                 'one revision number.', user_input=True)
  else:
    start = end = int(revision_range)
  return start, end

def maybe_fail(msg, user_input=False):
  """Determine if we have encountered a condition upon which our script cannot
  continue, and abort if so.
  Args:
    - msg: The error or user prompt message to print.
    - user_input: True if we require user confirmation to continue. We assume
                  that the user must enter y to proceed.
  """
  if user_input:
    force = raw_input(msg + ' (y/N) ')
    if force != 'y':
      sys.exit(0)
  else:
    print msg
    sys.exit(1)

def has_new_code(is_git):
  """Tests if there are any newer versions of files on the server.
  Args:
    - is_git: True if we are working in a git repository.
  """
  os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
  if not is_git:
    results, _ = run_cmd(['svn', 'st'])
  else:
    results, _ = run_cmd(['git', 'status'])
  for line in results.split('\n'):
    if not is_git and (not line.strip().startswith('?') and line != ''):
      return True
    elif is_git and ('Changes to be committed' in line or 
        'Changes not staged for commit:' in line):
      return True
  if is_git:
    p = subprocess.Popen(['git', 'log', '-1'], stdout=subprocess.PIPE,
                         shell=(platform.system()=='Windows'))
    output, _ = p.communicate()
    if find_git_info(output) is None:
      return True
  return False

def run_cmd(cmd_list, suppress_output=False, std_in=''):
  """Run the specified command and print out any output to stdout."""
  print ' '.join(cmd_list)
  p = subprocess.Popen(cmd_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       stdin=subprocess.PIPE,
                       shell=(platform.system()=='Windows'))
  output, stderr = p.communicate(std_in)
  if output and not suppress_output:
    print output
  if stderr and not suppress_output:
    print stderr
  return output, stderr

def runs_git():
  """Returns True if we're standing in an svn-git repository."""
  p = subprocess.Popen(['svn', 'info'], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE,
                       shell=(platform.system()=='Windows'))
  output, err = p.communicate()
  if err is not None and 'is not a working copy' in err:
    p = subprocess.Popen(['git', 'status'], stdout=subprocess.PIPE,
                         shell=(platform.system()=='Windows'))
    output, _ = p.communicate()
    if 'fatal: Not a git repository' in output:
      maybe_fail('Error: not running git or svn.')
    else:
      return True
  return False

def find_git_info(git_log, rev_num=None):
  """Determine the latest svn revision number if rev_num = None, or find the 
  git commit_id that corresponds to a particular svn revision number.
  """
  for line in git_log.split('\n'):
    tokens = line.split()
    if len(tokens) == 2 and tokens[0] == 'commit':
      current_commit_id = tokens[1]
    elif len(tokens) > 0 and tokens[0] == 'git-svn-id:':
      revision_number = int(tokens[1].split('@')[1])
      if revision_number == rev_num:
        return current_commit_id
      if rev_num is None:
        return revision_number

def revert(start, end, is_git):
  """Revert the sequence of CLs.
  Args:
    - start: The first CL to revert.
    - end: The last CL to revert.
    - is_git: True if we are in a git-svn checkout.
  """
  if not is_git:
    _, err = run_cmd(['svn', 'merge', '-r', '%d:%d' % (end, start-1), '.'],
                     std_in='p')
    if 'Conflict discovered' in err:
      maybe_fail('Please fix the above conflicts before submitting. Then create'
             ' a CL and submit your changes to complete the revert.')

  else:
    # If we're running git, we have to use the log feature to find the commit
    # id(s) that correspond to the particular revision number(s).
    output, _ = run_cmd(['git', 'log', '-1'], suppress_output=True)
    current_revision = find_git_info(output)
    distance = (current_revision-start) + 1
    output, _ = run_cmd(['git', 'log', '-%d' % distance], suppress_output=True)
    reverts = [start]
    commit_msg = '"Reverting %d"' % start
    if end != start:
      reverts = range(start, end + 1)
      reverts.reverse()
      commit_msg = '%s-%d"' % (commit_msg[:-1], end)
    for the_revert in reverts:
      git_commit_id = find_git_info(output, the_revert)
      if git_commit_id is None:
        maybe_fail('Error: Revision number not found. Is this earlier than your'
                   ' git checkout history?')
      _, err = run_cmd(['git', 'revert', '-n', git_commit_id])
      if 'error: could not revert' in err or 'unmerged' in err:
        command_sequence = ''
        for a_revert in reverts:
          git_commit_id = find_git_info(output, a_revert)
          command_sequence += 'git revert -n %s\n' % git_commit_id
        maybe_fail('There are conflicts while reverting. Please resolve these '
                   'after manually running:\n' + command_sequence + 'and then '
                   'create a CL and submit to complete the revert.')
    run_cmd(['git', 'commit', '-m', commit_msg])

def main():
  revisions = parse_args()
  git_user = runs_git()
  if has_new_code(git_user):
    maybe_fail('WARNING: This checkout has local modifications!! This could '
         'result in a CL that is not just a revert and/or you could lose your'
         ' local changes! Are you **SURE** you want to continue? ',
       user_input=True)
  if git_user:
    run_cmd(['git', 'cl', 'rebase'])
  run_cmd(['gclient', 'sync'])
  revert(revisions[0], revisions[1], git_user)
  print ('Now, create a CL and submit! The buildbots and your teammates thank '
         'you!')

if __name__ == '__main__':
  main()
