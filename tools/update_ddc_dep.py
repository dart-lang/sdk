#!/usr/bin/python

# Update ddc dep automatically.

import optparse
import os
import re
from subprocess import Popen, PIPE
import sys

# Instructions:
#
# To run locally:
#  (a) Create and change to a directory to run the updater in:
#  mkdir /usr/local/google/home/$USER/ddc_deps_updater
#
#  (b) Test by running (Ctrl-C to quit):
#      > ./update_ddc_deps.py
#
#  (c) Run periodical update:
#      > while true; do ./update_ddc_deps.py --force ; sleep 300 ; done

########################################################################
# Actions
########################################################################

def write_file(filename, content):
  f = open(filename, "w")
  f.write(content)
  f.close()

def run_cmd(cmd):
  print "\n[%s]\n$ %s" % (os.getcwd(), " ".join(cmd))
  pipe = Popen(cmd, stdout=PIPE, stderr=PIPE)
  output = pipe.communicate()
  if pipe.returncode == 0:
    return output[0]
  else:
    print output[1]
    print "FAILED. RET_CODE=%d" % pipe.returncode
    sys.exit(pipe.returncode)

def main():
  option_parser = optparse.OptionParser()
  option_parser.add_option(
      '',
      '--force',
      help="Push DEPS update to server without prompting",
      action="store_true",
      dest="force")
  options, args = option_parser.parse_args()

  target = 'ddc'
  repo = 'dev_compiler'
  repo_name = 'git@github.com:dart-lang/sdk.git'
  ddc_repo_name = 'git@github.com:dart-lang/%s.git' % (repo)
  repo_branch = 'origin/master'
  repo_branch_parts = repo_branch.split('/')

  root_dir = "/usr/local/google/home/%s/ddc_deps_updater" % (os.environ["USER"])
  src_dir = "%s/sdk" % (root_dir)
  ddc_dir = "%s/%s" % (root_dir, repo)
  deps_file = src_dir + '/DEPS'

  os.putenv("GIT_PAGER", "")

  if not os.path.exists(src_dir):
    print run_cmd(['git', 'clone', repo_name])

  if not os.path.exists(ddc_dir):
    print run_cmd(['git', 'clone', ddc_repo_name])

  os.chdir(ddc_dir)
  run_cmd(['git', 'fetch'])

  os.chdir(src_dir)
  run_cmd(['git', 'fetch'])
  run_cmd(['git', 'stash'])
  run_cmd(['git', 'checkout', '-B', repo_branch_parts[1], repo_branch])

  # parse DEPS
  deps = run_cmd(['cat', deps_file])
  rev_num = {}
  revision = '%s_rev":\s*"@(.+)"' % (repo)
  rev_num = re.search(revision, deps).group(1)

  # update repos
  all_revs = []
  os.chdir(ddc_dir)

  output = run_cmd(["git", "log",  "--pretty=%H", "%s..HEAD" % (rev_num),
      "origin/master"])
  commits = output.split('\n')
  if not commits or len(commits[0]) < 10:
    print "DEPS is up-to-date."
    sys.exit(0)

  revision = commits[0]

  history = run_cmd(["git", "log",  "--format=short", "%s..HEAD" % (rev_num),
      "origin/master"])

  print "Pending DEPS update: %s" % (revision)

  # make the next DEPS update
  os.chdir(src_dir)
  run_cmd(['rm', deps_file])

  pattern = re.compile('%s_rev":\s*"@(.+)"' % (repo))
  new_deps = pattern.sub('%s_rev": "@%s"' % (repo, revision), deps)
  write_file(deps_file, new_deps)

  commit_log = 'DEPS AutoUpdate: %s\n\n' % (repo)
  commit_log += history

  write_file('commit_log.txt', commit_log)
  run_cmd(['git', 'add', deps_file])

  print run_cmd(['git', 'diff', 'HEAD'])
  print
  print "Commit log:"
  print "---------------------------------------------"
  print commit_log
  print "---------------------------------------------"

  if not options.force:
    print "Ready to push; press Enter to continue or Control-C to abort..."
    sys.stdin.readline()
  print run_cmd(['git', 'commit', '-F', 'commit_log.txt'])
  print run_cmd(['git', 'push', repo_branch_parts[0], repo_branch_parts[1]])
  print "Done."


if '__main__' == __name__:
  main()
