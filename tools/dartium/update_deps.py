#!/usr/bin/python

# Update Dartium DEPS automatically.

from datetime import datetime, timedelta
import optparse
import os
import re
from subprocess import Popen, PIPE
import sys
from time import strptime

# Instructions:
#
# To run locally:
#  (a) Create and change to a directory to run the updater in:
#      > mkdir /usr/local/google/home/$USER/dartium_deps_updater
#      > cd /usr/local/google/home/$USER/dartium_deps_updater
#
#  (b) Make a 'deps' directory to store temporary files:
#      > mkdir deps
#
#  (c) Checkout dart/tools/dartium (with this script):
#      > svn co https://dart.googlecode.com/svn/branches/bleeding_edge/dart/tools/dartium dartium_tools
#
#  (d) If your home directory is remote, consider redefining it for this shell/script:
#      > cp -R $HOME/.subversion /usr/local/google/home/$USER
#      > export HOME=/usr/local/google/home/$USER
#
#  (e) Test by running (Ctrl-C to quit):
#      > ./dartium_tools/update_deps.py
#      > ./dartium_tools/update_deps.py --target=clank
#      > ./dartium_tools/update_deps.py --target=integration
#
#  (f) Run periodical update:
#      > while true; do ./dartium_tools/update_deps.py --force ; sleep 300 ; done

########################################################################
# Repositories to auto-update
########################################################################

BRANCH_CURRENT="dart/dartium"
BRANCH_NEXT="dart/2454_1"

# (repo_name, deps_dir, repo_branch, prefix, repos, branch)

TARGETS = {
  'dartium': (
    'git@github.com:dart-lang/sdk.git',
    'tools/deps/dartium.deps',
    'origin/master',
    'dartium',
    # TODO(vsm): Reenable 'chromium'
    ['webkit'],
    BRANCH_CURRENT,
    ),
  'integration': (
    # TODO(jacobr): what is the git repo for integration if any?
    'git@github.com:dart-lang/sdk.git',
    'tools/deps/dartium.deps',
    'origin/integration',
    'dartium',
    # TODO(vsm): Reenable 'chromium'
    ['webkit'],
    BRANCH_NEXT,
    ),
}

# Each element in this map represents a repository to update.  Entries
# take the form:
#  (repo_tag: (svn_url, view_url))
#
# The repo_tag must match the DEPS revision entry.  I.e, there must be
# an entry of the form:
#   'dartium_%s_revision' % repo_tag
# to roll forward.
#
# The view_url should be parameterized by revision number.  This is
# used to generated the commit message.
REPOSITORY_INFO = {
    'webkit': (
        'https://src.chromium.org/blink/branches/%s',
        'https://src.chromium.org/viewvc/blink?view=rev&revision=%s'),
    'blink': (
        'https://src.chromium.org/blink/branches/%s',
        'https://src.chromium.org/viewvc/blink?view=rev&revision=%s'),
    'chromium': (
        'https://src.chromium.org/chrome/branches/%s',
        'https://src.chromium.org/viewvc/chrome?view=rev&revision=%s'),
}

REPOSITORIES = REPOSITORY_INFO.keys()

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

def parse_iso_time(s):
  pair = s.rsplit(' ', 1)
  d = datetime.strptime(pair[0], '%Y-%m-%d %H:%M:%S')
  offset = timedelta(hours=int(pair[1][0:3]))
  return d - offset

def parse_git_log(output, repo):
  if len(output) < 4:
    return []
  lst = output.split(os.linesep)
  lst = [s.strip('\'') for s in lst]
  lst = [s.split(',', 3) for s in lst]
  lst = [{'repo': repo,
      'rev': s[0],
      'isotime':s[1],
      'author': s[2],
      'utctime': parse_iso_time(s[1]),
      'info': s[3]} for s in lst]
  return lst

def parse_svn_log(output, repo):
  lst = output.split(os.linesep)
  lst = [s.strip('\'') for s in lst]
  output = '_LINESEP_'.join(lst)
  lst = output.split('------------------------------------------------------------------------')
  lst = [s.replace('_LINESEP_', '\n') for s in lst]
  lst = [s.strip('\n') for s in lst]
  lst = [s.strip(' ') for s in lst]
  lst = [s for s in lst if len(s) > 0]
  pattern = re.compile(' \| (\d+) line(s|)')
  lst = [pattern.sub(' | ', s) for s in lst]
  lst = [s.split(' | ', 3) for s in lst]
  lst = [{'repo': repo,
      'rev': s[0].replace('r', ''),
      'author': s[1],
      'isotime':s[2][0:25],
      'utctime': parse_iso_time(s[2][0:25]),
      'info': s[3].split('\n')[2]} for s in lst]
  return lst

def commit_url(repo, rev):
  numrev = rev.replace('r', '')
  if repo in REPOSITORIES:
    (_, view_url) = REPOSITORY_INFO[repo]
    return view_url % numrev
  else:
    raise Exception('Unknown repo');

def find_max(revs):
  max_time = None
  max_position = None
  for i, rev in enumerate(revs):
    if rev == []:
      continue
    if max_time is None or rev[0]['utctime'] > max_time:
      max_time = rev[0]['utctime']
      max_position = i
  return max_position

def merge_revs(revs):
  position = find_max(revs)
  if position is None:
    return []
  item = revs[position][0]
  revs[position] = revs[position][1:]
  return [item] + merge_revs(revs)

def main():
  option_parser = optparse.OptionParser()
  option_parser.add_option('', '--target', help="Update one of [dartium|integration]", action="store", dest="target", default="dartium")
  option_parser.add_option('', '--force', help="Push DEPS update to server without prompting", action="store_true", dest="force")
  options, args = option_parser.parse_args()

  target = options.target
  if not target in TARGETS.keys():
    print "Error: invalid target"
    print "Choose one of " + str(TARGETS)
  (repo_name, deps_dir, repo_branch, prefix, repos, branch) = TARGETS[target]
  deps_file = deps_dir + '/DEPS'
  repo_branch_parts = repo_branch.split('/')

  src_dir = "/usr/local/google/home/%s/dartium_deps_updater/deps/%s" % (os.environ["USER"], target)
  os.putenv("GIT_PAGER", "")

  if not os.path.exists(src_dir):
    print run_cmd(['git', 'clone', repo_name, src_dir])

  os.chdir(src_dir)
  deps = run_cmd(['git', 'fetch'])
  deps = run_cmd(['git', 'stash'])
  deps = run_cmd(['git', 'checkout', '-B', repo_branch_parts[1], repo_branch])

  # parse DEPS
  deps = run_cmd(['cat', deps_file])
  rev_num = {}
  for repo in repos:
    revision = '%s_%s_revision":\s*"(.+)"' % (prefix, repo)
    rev_num[repo] = re.search(revision, deps).group(1)

  # update repos
  all_revs = []
  for repo in repos:
    (svn_url, _) = REPOSITORY_INFO[repo]
    output = run_cmd(["svn", "log",  "-r", "HEAD:%s" % rev_num[repo], svn_url % branch])
    revs = parse_svn_log(output, repo)
    if revs and revs[-1]['rev'] == rev_num[repo]:
      revs.pop()
    all_revs.append(revs)

  pending_updates = merge_revs(all_revs)
  pending_updates.reverse()

  print
  print "Current DEPS revisions:"
  for repo in repos:
    print '  %s_%s_revision=%s' % (prefix, repo, rev_num[repo])

  if len(pending_updates) == 0:
    print "DEPS is up-to-date."
    sys.exit(0)
  else:
    print "Pending DEPS updates:"
    for s in pending_updates:
      print "  %s to %s (%s) %s" % (s['repo'], s['rev'], s['isotime'], s['info'])

  # make the next DEPS update
  os.chdir(src_dir)
  run_cmd(['rm', deps_file])
  s = pending_updates[0]

  pattern = re.compile(prefix + '_' + s['repo'] + '_revision":\s*"(.+)"')
  new_deps = pattern.sub(prefix + '_' + s['repo'] + '_revision": "' + s['rev'] + '"', deps)
  write_file(deps_file, new_deps)

  commit_log = 'DEPS AutoUpdate: %s to %s (%s) %s\n' % (s['repo'], s['rev'], s['isotime'], s['author'])
  commit_log += s['info'] + '\n' + commit_url(s['repo'], s['rev'])

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
