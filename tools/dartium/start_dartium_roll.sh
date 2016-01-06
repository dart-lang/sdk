#!/usr/bin/env bash

set -e

# Requirements:
#    sudo apt-get install xclip


# e.g. 1908 ROLL
# ./start_dartium_roll.sh --verbose --directory ~/dartium-roll --old-branch 1847 --old-revision 251904 --new-branch 1908 --new-revision 259084 --chrome --pre-roll
# ./start_dartium_roll.sh --verbose --directory ~/dartium-roll --old-branch 1847 --old-revision 251904 --new-branch 1908 --new-revision 259084 --chrome --roll
# ./start_dartium_roll.sh --verbose --directory ~/dartium-roll --old-branch 1847 --old-revision 251904 --new-branch 1908 --new-revision 259084 --chrome --info
# ./start_dartium_roll.sh --verbose --directory ~/dartium-roll --old-branch 1847 --old-revision 167304 --new-branch 1908 --new-revision 169907 --blink --pre-roll
# ./start_dartium_roll.sh --verbose --directory ~/dartium-roll --old-branch 1847 --old-revision 167304 --new-branch 1908 --new-revision 169907 --blink --roll
# ./start_dartium_roll.sh --verbose --directory ~/dartium-roll --old-branch 1847 --old-revision 167304 --new-branch 1908 --new-revision 169907 --blink --info

# e.g., 1916 ROLL
# ~/./start_dartium_roll.sh --verbose --directory /media/TB/dartium-1916 --old-branch 1908 --old-revision 259084 --new-branch 1916 --new-revision 260298 --chrome --pre-roll

# ~/./start_dartium_roll.sh --verbose --directory /media/TB/dartium-1916 --old-branch 1908 --old-revision 169907 --new-branch 1916 --new-revision 170313 --blink --pre-roll

E_INVALID_ARG=128

function usage {
  echo "Usage: $0 [--options]"
  echo "Options:"
  echo "  --[no-]verbose:           display information about each step"
  echo "  --directory base:         base directory of local git repository"
  echo "                            (e.g., ~/dartium-roll implies directory"
  echo "                            ~/dartium-roll/src and"
  echo "                            ~/dartium-roll/src/third_party/WebKit)**"
  echo "  --chrome:                 for the Chrome branch (not with --blink)**"
  echo "  --blink:                  for the Blink branch (not with --chrome)**"
  echo "  --old-branch name:        name of previous true branch (e.g., use 1847"
  echo "                            for version 34.0.1847.92) *"
  echo "  --old-revision revision:  revision of base trunk for $OLD version *"
  echo "  --new-branch name:        name of new true branch to create *"
  echo "  --new-revision revision:  revision of base trunk for new branch *"
  echo "  --pre-roll:               display commands to prepare for the roll"
  echo "  --roll:                   display Git commands to execute for creating"
  echo "                            branches for the roll"
  echo "  --info:                   display hashes for $BASE and $LAST on each"
  echo "                            branch (stripped$OLD, trunkdata$OLD, and"
  echo "                            trunkdata$NEW)"
  echo "  --help:                   this message"
  echo
  echo "* - required"
  echo
  echo "*  Script will prompt interactively if options not given."
  echo "** Argument must be specified."
  echo
  exit 1
}


function verbose_message {
  if [ "$do_verbose" = 1 ]; then
    if [ "${1}" = "" ]; then
      echo
    else
      echo -e "...${1}..."
    fi
  fi
}


# Does the file src/.git/config contains the added lines pointing to the chrome
# remote dart$OLD and dart$NEW branches for src/ (e.g, dart1847 and dart1908):
#
#     [svn-remote "dart$OLD"]
#             url = svn://svn.chromium.org/chrome/branches/dart/$OLD/src
#             fetch = :refs/remotes/dart1847
#     [svn-remote "dart$NEW"]
#             url = svn://svn.chromium.org/chrome/branches/dart/$NEW/src
#             fetch = :refs/remotes/dart1908
#
# and does the file src/third_party/WebKit/.git/config contains the added lines
# for blink:
#
#     [svn-remote "dart$OLD"]
#             url = svn://svn.chromium.org/blink/branches/dart/$OLD/src
#             fetch = :refs/remotes/dart1847
#     [svn-remote "dart$NEW"]
#             url = svn://svn.chromium.org/blink/branches/dart/$NEW/src
#             fetch = :refs/remotes/dart1908
#
function validate_remotes {
  verbose_message "Validating Remotes"

  if [ "$do_which" = "chrome" ]; then
    # Ensure remote for old Dartium release exist (e.g., remotes/dart1847)
    remote_dart_last=$(git branch -a | grep "remotes/dart${do_old_branch}")
    # Ensure remote for new Dartium release exist (e.g., remotes/dart1908)
    remote_dart_new=$(git branch -a | grep "remotes/dart${do_new_branch}")
    if [ "$remote_dart_last" = "" ]; then
      $(display_error "missing old remotes/dart${do_old_branch}")
      exit -1
    fi
    if [ "$remote_dart_new" = "" ]; then
      $(display_error "missing new remotes/dart${do_new_branch}")
      exit -1
    fi
  elif [ "$do_which" = "blink" ]; then
    # Ensure remote for old Dartium release exist (e.g., remotes/dart1847)
    remote_dart_last=$(git branch -a | grep "remotes/blink-svn/${do_old_branch}")
    # Ensure remote for new Dartium release exist (e.g., remotes/dart1908)
    remote_dart_new=$(git branch -a | grep "remotes/blink-svn/multivm-${do_new_branch}")

    if [ "$remote_dart_last" = "" ]; then
      $(display_error "missing old remotes/blink-svn/${do_old_branch}")
      exit -1
    fi
    if [ "$remote_dart_new" = "" ]; then
      $(display_error "missing new remotes/blink-svn/multivm-${do_new_branch}")
      exit -1
    fi
  else
    $(display_error "--chrome or --blink must be specified")
    exit -1
  fi
}

function stripped_exist {
  local branch_name=$(git branch --no-color --list $(stripped_name) | sed 's/^[ \t\*]*//')
  echo $branch_name
}

# Does the branch trunkdart$OLD or trunkdart$NEW exist where $OLD is previous
# branch (e.g. 1847) and $NEW is new branch to roll (e.g., 1908)
# $(trunk_exist ${do_old_branch})  or  $(trunk_exist ${do_new_branch})
# Strip out the spaces and * (implies current branch) then return the branch name.
function trunk_exist {
  local branch_name=$(git branch --list --no-color trunkdart${1} | sed 's/^[ \t\*]*//' | tail -n 1)
  echo $branch_name
}

function validate_repository {
  verbose_message "Validating Repository"

  strip_branch=${stripped_name}

  # Validate that branches exist.
  stripped_found=${stripped_exist}
  old_branch_found=$(trunk_exist ${do_old_branch})
  new_branch_found=$(trunk_exist ${do_new_branch})

  if [ "$stripped_found" != "" ]; then
    $(display_error "branch ${strip_branch} already exist")
    exit -1
  fi

  if [ "$old_branch_found" != "" ]; then
    $(display_error "branch trunkdart${do_old_branch} already exist")
    exit -1
  fi

  if [ "$new_branch_found" != "" ]; then
    $(display_error "branch trunkdart${do_new_branch} already exist")
    exit -1
 fi
}

function display_error() {
  echo -e "\n\e[1;31mERROR: ${1}\e[0m\n" >&2
  exit 1
}


# Given a revision number $1 return the trunk's hash code for that revision.
function hash_trunk_revision {
  # Chrome trunk hash code for [NewChromeCommit]
  hash_trunk=$(git log master --grep=src@${1} --pretty=format:'%H' -n 1)
}


# Return the last revision for a branch.  Used by new trunk roll for the
# DEPS file for the last revision to use during build.
function last_revision() {
  echo $(git svn log ${1} --oneline -1 | cut -d '|' -f1 | sed "s/r//")
}


# Return the branch for strippedOOOO use bash line:
#    $(stripped_name)
function stripped_name {
  echo "stripped${do_old_branch}"
}


# Give a branch name return the trunk release for that branch.
function trunkdart_name {
  echo "trunkdart${1}"
}


# Compute the hash codes for the previous branch hash_base is the first commit
# and hash_last is final commit.
function hash_codes_base_last {
  # Get the first commit for previous Dartium roll on chrome branch.
  hash_base=$(git rev-list ${1} --pretty=format:'%H' | tail -n 1)

  # Get the last commit for previous Dartium roll on chrome branch.
  hash_last=$(git log ${1} --pretty=format:'%H' -1)
}


# Compute the hash codes for the previous branch hash_base is the first commit
# and hash_last is final commit.
function hash_codes_base2_last2 {
  # Get the last commit for previous Dartium roll on chrome branch.
  hash_last2=$(git log ${1} --pretty=format:'%H' -1)

  local search
  if [ "$do_which" = "chrome" ]; then
    search="chrome/trunk/src@${do_old_revision}"
  else
    search="blink/branches/dart/multivm-${do_new_revision}@${do_old_revision}"
  fi

  # Get the first commit for previous Dartium roll on chrome branch.
  hash_base2=$(git log ${1} --grep=@${do_old_revision} --pretty=format:'%H' | tail -1)
}


# Pad right/left up to 80 spaces.
#   Parameter $1 string to pad.
#   Parameter $2 is max length to post-pad with spaces.
#   Parameter $3 if specified padd to the right otherwise pad to the right.
#   Returns string right padded with spaces.
function space_pad() {
  local spaces=$(printf '%0.1s' " "{1..80})
  local spaces_pad=${spaces:0:$2}
  local padding=$(printf "%s" "${spaces_pad:${#1}}")

  if [[ "$3" = "" ]]; then
    # Pad to the right [default].
    echo "${1}${padding}"
  else
    # Pad to the left.
    echo "${padding}${1}"
  fi
}


# Format the line '|  URL:  <url>   |'.
#   Paramter $1 - url to format
#   Returns the formatted and space padded line for display_hashes.
function display_url() {
  # Line length is 65, skipped # 9 characters at beginning '|  URL:  '
  # and last character '|'. Up to 55 characters of padding.
  local format_url=$(space_pad $1 55)
  local valid_url=$(valid_branch_url $1)
  if [[ "$valid_url" = "" ]]; then
    # Error format padding is same as above remote_url 55;
    local format_err=$(space_pad "WARNING ON TRUNK - FIX IMMEDIATELY" 55)
    # Output in red, the problem, both lines the URL and the warning message.
    echo -e "|  URL:  \e[1;31m${format_url}\e[0m|\n|        \e[1;31m${format_err}\e[0m|"
  else
    # URL looks good.
    echo "|  URL:  ${format_url}|"
  fi
}


function display_hashes {
  if [ "$do_info_hashes" = 1 ]; then
    local format_which=$(space_pad $do_which 6 1)
    stripped_branch=$(stripped_name)
    # stripped$OLD found
    stripped_found=$(stripped_exist)
    if [ "$stripped_found" != "" ]; then
      hash_codes_base_last ${stripped_branch}
      hash_trunk_revision ${do_old_revision}
      # Display the first/last commit hash for stripped$OLD branch and the
      # trunk hash for $OLD@do_last_revsion.
      echo "================================================================="
      local format_branch=$(space_pad $stripped_branch 32 1)
      echo "|  \$OLD: ${format_which} dart${do_old_branch}@${do_old_revision}${format_branch} |"
      local remote_url=$(url_branch $stripped_branch)

# TODO(terry): Testing failure below remove before checkin
#      local remote_url=$(url_branch "master")

      echo "$(display_url $remote_url)"
      echo "|---------------------------------------------------------------|"
      local format_hash=$(space_pad $hash_base 51)
      echo "|  \$BASE  | ${format_hash} |"
      echo "|---------------------------------------------------------------|"
      format_hash=$(space_pad $hash_last 51)
      echo "|  \$LAST  | ${format_hash} |"
      echo "================================================================="
      echo
    else
      echo "${stripped_branch} not found"
      echo
    fi

    # trunkdart$OLD found
    branch_trunkdart_old=$(trunkdart_name ${do_old_branch})
    old_branch_found=$(trunk_exist ${do_old_branch})
    if [ "$old_branch_found" != "" ]; then
      hash_codes_base2_last2 ${branch_trunkdart_old}
      hash_trunk_revision ${do_old_revision}
      # Display the first/last commit hash for trunkdart$OLD branch and the
      # trunk hash for $OLD@do_last_revsion.
      echo "================================================================="
      local format_branch=$(space_pad $branch_trunkdart_old 32 1)
      echo "|  \$OLD  ${format_which} dart${do_old_branch}@${do_old_revision}${format_branch} |"
      local remote_url=$(url_branch $branch_trunkdart_old)
      echo "$(display_url $remote_url)"
      echo "|---------------------------------------------------------------|"
      local format_base2=$(space_pad $hash_base2 51)
      echo "|  \$BASE2 | ${format_base2} |"
      echo "|---------------------------------------------------------------|"
      local format_last2=$(space_pad $hash_last2 51)
      echo "|  \$LAST2 | ${format_last2} |"
      echo "================================================================="
      echo
    else
      echo "${branch_trunkdart_old} not found"
      echo
    fi

    # trunkdart$NEW found
    branch_trunkdart_new=$(trunkdart_name ${do_new_branch})
    new_branch_found=$(trunk_exist ${do_new_branch})
    if [ "$new_branch_found" != "" ]; then
      hash_trunk_revision ${do_new_revision}
      # Display the trunk hash for $NEW@do_new_revsion.
      echo "================================================================="
      local format_branch=$(space_pad $branch_trunkdart_new 32 1)
      echo "|  \$NEW  ${format_which} dart${do_new_branch}@${do_new_revision}${format_branch} |"
      local remote_url=$(url_branch $branch_trunkdart_new)
      echo "$(display_url $remote_url)"
      echo "|---------------------------------------------------------------|"
      local revision=$(last_revision $branch_trunkdart_new)
      local format_revision=$(space_pad $revision 43)
      echo "|  last revision  | ${format_revision} |"
      echo "================================================================="
      echo
    else
      echo "${branch_trunkdart_new} not found"
      echo
    fi
  fi
}


function switch_branch() {
  $(git checkout ${1} --quiet)
  local curr_branch=$(git name-rev --name-only HEAD)
  if [[ "$curr_branch" != "$1" ]]; then
    $(display_error "Unable to switch to branch $1 - pending commits/add?")
    exit -1
  fi
  echo $curr_branch
}


# Check that the branch is not pointing to either blink or chrome trunk.
# These branches should be pointing to either:
#     svn://svn.chromium.org/chrome/branches/dart/NNNN
#     svn://svn.chromium.org/blink/branches/dart/NNNN
#
# $1 parameter - branch-name to make current branch and check repository
#                name.
function check_branch() {
  local old_branch=$(git name-rev --name-only HEAD)
  local curr_branch=$(switch_branch $1)
  local trunk_url;

  if [ "$do_which" = "chrome" ]; then
    # Chrome
    trunk_url='Committing to svn://svn.chromium.org/chrome/trunk/src ...'
  elif [ "$do_which" = "blink" ]; then
    # Blink
    trunk_url='Committing to svn://svn.chromium.org/blink/trunk ...'
  else
    $(display_error "Neither blink or chrome specified")
    exit -1
  fi

  local remote_commit=$(git svn dcommit --dry-run | head -1 | grep "${trunk_url}")

  curr_branch=$(switch_branch $old_branch)
  if [[ "$curr_branch" != "$old_branch" ]]; then
    $(display_error "Unable to switch back to original branch ${old_branch}")
    exit -1
  fi

  if [[ "$remote_commit" != "" ]]; then
    $(display_error "Branch ${1} is NOT pointing to the Dart branch repository but pointing to trunk.")
    exit -1
  fi

  echo "Local branch '${1}' is based on the remote branch/dart repository."
}


# Given an URL of a remote repository passed as parameter $1 (e.g., from
# url_branch function) return the URL passed in if valid or return empty
# string "".
function valid_branch_url() {
  # Compute what the remote repository should be:
  #    svn://svn.chromium.org/${do_which}/branches/dart/${do_old_branch}/src
  #    e.g., svn://svn.chromium.org/chrome/branches/dart/1847/src
  # or blink:
  #    svn://svn.chromium.org/blink/branches/dart/${do_old_branch}
  #    e.g., svn://svn.chromium.org/blink/branches/dart/1847
  local src_dir=""
  if [[ "$do_which" = "chrome" ]]; then
    src_dir="/src"
  fi
  local old_remote="svn://svn.chromium.org/${do_which}/branches/dart/${do_old_branch}${src_dir}"
  local new_remote="svn://svn.chromium.org/${do_which}/branches/dart/${do_new_branch}${src_dir}"

  echo $(echo "$1" | grep -e "${old_remote}" -e "${new_remote}")
}


# Returns the remote repository URL associated with a branch.
# Parameter $1 is the branch name.
function url_branch() {
  local old_branch=$(git name-rev --name-only HEAD)
  local curr_branch=$(switch_branch $1)

  local remote_commit=$(git svn dcommit --dry-run | head -1 | sed 's/Committing to //' | sed 's/ ...//')

  curr_branch=$(switch_branch $old_branch)

  echo "${remote_commit}"
}


# Ensure that any created branches (stripped$OLD, trunkdart$OLD and
# trunkdart$NEW) are not pointing to either the blink or chrome trunks.
function validate_branches() {
  # stripped branch
  local stripped_found=$(stripped_exist)
  if [ "$stripped_found" != "" ]; then
    local branch_name=$(stripped_name)
    local check_result=$(check_branch ${branch_name})
    printf "%s\n" "$check_result"
  fi

  # trunkdart$OLD
  local branch_trunkdart_old=$(trunkdart_name ${do_old_branch})
  local old_branch_found=$(trunk_exist ${do_old_branch})
  if [ "$old_branch_found" != "" ]; then
    local check_result=$(check_branch $branch_trunkdart_old)
    printf "%s\n" "$check_result"
  fi

  # trunkdart$NEW
  local branch_trunkdart_new=$(trunkdart_name ${do_new_branch})
  local new_branch_found=$(trunk_exist ${do_new_branch})
  if [ "$new_branch_found" != "" ]; then
    local check_result=$(check_branch $branch_trunkdart_new)
    printf "%s\n" "$check_result"
  fi
}


function display_roll_commands() {
  if [ "$roll_branches" = 1 ]; then
    if [ "$do_which" = "chrome" ]; then
      roll_chrome_commands
    elif [ "$do_which" = "blink" ]; then
      roll_blink_commands
    fi
  fi
}


# Show commands to create SVN branch folder and remote repository for new roll.
function display_remote_repository_creation() {
# TODO(terry): Use the diretory passed in instead of hard-coded dartium-NNNN
# TODO(terry): Should execute each command with a Y or N and command runs.
# TODO(terry): Echo output from commands especially clone and rebase using "OUTPUT=$(git cl rebase); echo $OUTPUT"
# TODO(terry): Add ability to copy to clipboard programmatically us 'echo "hi" | xclip -selection clipboard'
#              copies hi to clipboard.
  echo "Do the following pre-roll setup"
  if [ "$do_which" = "chrome" ]; then
    echo "  mkdir dartium-${do_new_branch}"
    echo "  cd dartium-${do_new_branch}"
    echo "  svn mkdir -m \"Preparing Chrome 35/${do_new_branch} branch\" "\
         "svn://svn.chromium.org/chrome/branches/dart/${do_new_branch}"
    echo "  svn cp -m \"Branching for ${do_new_branch} @${do_new_revision}\" "\
         "svn://svn.chromium.org/chrome/trunk/src@${do_new_revision} "\
         "svn://svn.chromium.org/chrome/branches/dart/${do_new_branch}/src"
    echo "  git svn clone -r241107 svn://svn.chromium.org/chrome/trunk/src src"
    echo
    echo "  cd src"
    echo "  git cl rebase"
    echo
    echo "-----After rebase finishes-----"
    echo
    echo " 1. Add the below lines to src/.git/config"
    echo
    echo "[svn-remote \"dart${do_old_branch}\"]"
    echo "      url = svn://svn.chromium.org/chrome/branches/dart/${do_old_branch}/src"
    echo "      fetch = :refs/remotes/dart${do_old_branch}"
    echo "[svn-remote \"dart${do_new_branch}\"]"
    echo "      url = svn://svn.chromium.org/chrome/branches/dart/${do_new_branch}/src"
    echo "      fetch = :refs/remotes/dart${do_new_branch}"
    echo
    echo " 2. Get the code"
    echo
    echo "    cd src"
    echo "    git svn fetch dart${do_old_branch} && git svn fetch dart${do_new_branch}"
  elif [ "$do_which" = "blink" ]; then
    echo "  Directory dartium-${do_new_branch} exists."
    echo "  cd dartium-${do_new_branch}"
    echo "  svn cp -m \"Branching ${do_new_branch} @${do_new_revision}\" "\
         "svn://svn.chromium.org/blink/trunk@${do_new_revision} "\
         "svn://svn.chromium.org/blink/branches/dart/${do_new_branch}"

    echo "  git svn clone --trunk=trunk --branches=branches/dart"\
         " --prefix=blink-svn/ -r165883:HEAD " \
         "svn://svn.chromium.org/blink src/third_party/WebKit"
    echo
    echo "  cd src/third_party/WebKit"
    echo "  git cl rebase"
    echo
    echo "-----After rebase finishes-----"
    echo
    echo " 1. Add the below lines to src/third_party/WebKit/.git/config"
    echo
    echo "[svn-remote \"dart${do_old_branch}\"]"
    echo "      url = svn://svn.chromium.org/blink/branches/dart/${do_old_branch}"
    echo "      fetch = :refs/remotes/dart${do_old_branch}"
    echo "[svn-remote \"dart${do_new_branch}\"]"
    echo "      url = svn://svn.chromium.org/blink/branches/dart/${do_new_branch}"
    echo "      fetch = :refs/remotes/dart${do_new_branch}"
    echo
    echo " 2. Get the code"
    echo
    echo "    cd src/third_party/WebKit"
    #TODO(terry): Should the fetch be remotes/blink-svn/multivm-${do_new_branch}
    echo "    git svn fetch dart${do_old_branch} && git svn fetch dart${do_new_branch}"
  fi
}

# Displays each of the 3 steps, of GIT commands, to create the
# branches for a Dartium roll.
#
# Givin the following Dartium roll information:
#   Previous Dartium roll 1847 @251094      ($OLD)
#   New Dartium roll to make 1908 @ 259084  ($NEW)
#
# Three branches will be created a stripped[$OLD], trunkdart[$OLD]
# and trunkdart[$NEW].
#
#  |==============================================|
#  | $OLD       |     1847                        |
#  |----------------------------------------------|
#  | $OLD_REV   |     251094                      |
#  |----------------------------------------------|
#  | $NEW       |     1908                        |
#  |----------------------------------------------|
#  | $NEW_REV   |     259084                      |
#  |==============================================|
#
# stripped$OLD  - Branch with upstream patches stripped out.
# trunkdart$OLD - Branch with all patches for $OLD.
# trunkdart$NEW - Branch of a new Chromium/Blink release with
#                 cherry-picked $OLD commits from trunkdart$OLD.
#
# stripped$OLD, trunkdart$OLD points the SVN remote repository
#
#    svn://svn.chromium.org/chrome/branches/dart/1847/src
#
# trunkdart$NEW points to the SVN remote repository
#    svn://svn.chromium.org/chrome/branches/dart/1908/src
#
# STEP 1.
# -------
# Create the stripped$OLD:
#     > git checkout -b stripped$OLD dart$OLD
#     > git rebase -i $BASE
#
#     e.g., git checkout -b stripped1847 dart1847
#           git rebase -i 3345f6a26911beda2ed352e887549bc514acb4bd
#
# Rebasing with -i will launch an editor, show all commits after $BASE and let
# you interactively remove any upstream commits from trunk.  Upstream commits
# have a format of "Incrementing VERSION to 32.0.1847.78".  Then save and quit
# the editor.
#
# $BASE and $LAST are computed by this script and is returned in the
# 'git rebase -i <hash-code>' command.
#
#      NOTE: How $BASE and $LAST are computed:
#      ---------------------------------------
#      $BASE, first commit in $OLD, is computed by:
#           > git rev-list stripped1847 --pretty=format:'%H' | tail -n 1
#      Return a GIT hash code e.g., 3345f6a26911beda2ed352e887549bc514acb4bd
#
#      $LAST, last commit in $NEW, is computed by:
#           > git log stripped1847 --pretty=format:'%H' -1
#      Return a GIT hash code e.g., 44d12cd4b7e041f8d06f8735f1af08abb66825c4
#
# STEP 2.
# -------
# Create the trunkdart$OLD e.g.,
#     > git checkout -b trunkdart$OLD $BASE
#     > git cherry-pick $BASE..$LAST
#
#     e.g., git checkout -b trunkdart1847
#
# Create branch trunkdart$OLD and reapplies all Dart-related work on $OLD (from
# the stripped branch created in Step1.).  This cherry-pick should not have any
# conflicts as you are rebasing onto exactly the same source code layout.
#
# STEP 3.
# -------
# Create the branch for $NEW (trunkdart$NEW):
#    > git checkout -b trunkdart$NEW dart$NEW
#    > git cherry-pick $BASE2..$LAST2
#
# Important points trunkdart$NEW is attached to the remote SVN repository created
# in pre-steps.
#
#    e.g., git checkout -b trunkdart1908 dart1908
#          git cherry-pick xxxx..xxxx
#
# $BASE2 should be the same as $BASE to validate with:
#
#    > git log trunkdart$OLD --grep=@$OLD_REV --pretty=format:'%H' | tail -1
#
#    e.g., git log trunkdart1847 --grep=251094 --pretty=format:'%H' | tail -1
#          3345f6a26911beda2ed352e887549bc514acb4bd
#
# $LAST2 is the last commit in $OLD in trunkdart$OLD computed by:
#
#    > git log trunkdart$OLD --pretty=format:'%H' -1
#
#    e.g., > git log trunkdart1847 --pretty=format:'%H' -1
#          2549d8ecd211ee6fed6699d70f319e077b425be4
#
# The we'll cherry-pick commits from $OLD.
#   e.g.,
#   > git cherry-pick 3345f6a26911beda2ed352e887549bc514acb4bd..2549d8ecd211ee6fed6699d70f319e077b425be4
#
# Cherry picking is an iterative process.  Each commit in the $OLD branch is
# applied to the $NEW branch any conflicts will need to fixed.
#
# Fix each file conflict(s) in a particular commit:
#
#   > vim <filename>
#   > git add <filename>
#
# When all file conflicts for a particular commit are done then:
#
#   > git commit -a -m "Merged $OLD"
#
# Continue the original cherry-picking
#   > git cherry-pick --continue
#
#
# ********************************************************************
# *                            IMPORTANT:                            *
# ********************************************************************
#
# When all commits are made to our new trunk (trunkdart$NEW).  Then try an
# initial dcommit with the --dry-run option.
#
#     > git svn dcommit --dry-run
#
#     e.g., git svn dcommit --dry-run
#           Committing to svn://svn.chromium.org/chrome/branches/dart/1908/src ...
#           diff-tree 48e85b5f247696c432d9dbb55c37f88f4df8a06a~1 48e85b5f247696c432d9dbb55c37f88f4df8a06a
#           ...
#
# It is important to check the first line "Committing to " the repository
# should be the new remote SVN e.g., svn://svn.chromium.org/chrome/branches/dart/1908/src ...
#
# IT SHOULD NOT BE "svn://svn.chromium.org/chrome/trunk/src ..." this will
# dcommit the changes to the chrome trunk and break the chromium build.
#
function roll_chrome_commands() {
  stripped_found=$(stripped_exist)
  old_branch_found=$(trunk_exist ${do_old_branch})
  new_branch_found=$(trunk_exist ${do_new_branch})

  echo
  echo "================================================"
  echo "|             git commands to run:             |"
  echo "================================================"

  remoteOld=dart${do_old_branch}
  strip_branch=$(stripped_name)

  if [ "$stripped_found" = "" ]; then
    echo "------------------ Step 1. ---------------------"
    echo

    # Git command to create stripped old branch.
    echo "git checkout -b ${strip_branch} ${remoteOld}"

    # Get hashes for base for do_old_branch.
    hash_codes_base_last ${remoteOld}

    echo "git rebase -i ${hash_base}"
    echo
  elif [ "$old_branch_found" = "" ]; then
    echo "------------------ Step 2. ---------------------"
    echo

    # Get hashes for base, last and base hash from trunk for the last branch.
    hash_codes_base_last ${strip_branch}

    # Git command to create old branch with only changes from base to last
    # commits for that branch.  Checkout based on stripped$OLD first commit
    # $BASE.
    branch_trunkdart_old=$(trunkdart_name ${do_old_branch})
    echo "git checkout -b ${branch_trunkdart_old} ${hash_base}"

    echo "git cherry-pick ${hash_base}..${hash_last}"
    echo
  elif [ "$new_branch_found" = "" ]; then
    echo "------------------ Step 3. ---------------------"
    echo

    # Git command to create new branch to roll.
    branch_trunkdart_new=$(trunkdart_name ${do_new_branch})

    # get base and last commit hashes of the trunkdart$OLD
    hash_codes_base2_last2 ${branch_trunkdart_old}

    echo "git checkout -b ${branch_trunkdart_new} ${remoteOld}"

    echo "git cherry-pick ${hash_base2}..${hash_last2}"
    echo
  else
    echo "===== Nothing to do - Roll setup complete. ====="
  fi

  echo "================================================"
}


function roll_blink_commands() {
  stripped_found=$(stripped_exist)
  old_branch_found=$(trunk_exist ${do_old_branch})
  new_branch_found=$(trunk_exist ${do_new_branch})

  echo
  echo "================================================"
  echo "|             git commands to run:             |"
  echo "================================================"

  remoteOld=dart${do_old_branch}
  strip_branch=$(stripped_name)

  if [ "$stripped_found" = "" ]; then
    echo "------------------ Step 1. ---------------------"
    echo

    # Git command to create stripped old branch.
    echo "git checkout -b ${strip_branch} ${remoteOld}"

    # Get hashes for base dir do_old_branch.
    hash_codes_base_last ${remoteOld}

    eho "git rebase -i ${hash_base}"
    echo
  elif [ "$old_branch_found" = "" ]; then
    echo "------------------ Step 2. ---------------------"
    echo

    # Get hashes for base, last and base hash from trunk for the last branch.
    hash_codes_base_last ${strip_branch}

    # Git command to create old branch with only changes from base to last
    # commits for that branch.  Checkout based on stripped$OLD first commit
    # $BASE.
    branch_trunkdart_old=$(trunkdart_name ${do_old_branch})
    echo "git checkout -b ${branch_trunkdart_old} ${hash_base}"

    echo "git cherry-pick ${hash_base}..${hash_last}"
    echo
  elif [ "$new_branch_found" = "" ]; then
    echo "------------------ Step 3. ---------------------"
    echo


    # Git command to create new branch to roll.
    branch_trunkdart_new=$(trunkdart_name ${do_new_branch})

    # get base and last commit hashes of the trunkdart$OLD
    hash_codes_base2_last2 ${branch_trunkdart_old}

    echo "git checkout -b ${branch_trunkdart_new} ${remoteOld}"

    echo "git cherry-pick ${hash_base2}..${hash_last2}"
    echo
  else
    echo "===== Nothing to do - Roll setup complete. ====="
  fi

  echo "================================================"
}


# checkout strippedOOOO and trunkdartNNNN
create_branches=0

do_info_hashes=0

base_dir=""

# Display the pre-roll commands; if specified nothing else is displayed.
do_pre_roll=0

# which branch chrome or blink
do_which=""

# Display detail information about all major steps
do_verbose=0

# $OLD branch
do_old_branch=""
do_old_revision=""

# $NEW branch
do_new_branch=""
do_new_revision=""

curr_switch=""
for var in "$@"
do
  case "$var" in
  --help)
    usage
    exit
    ;;
  --verbose)
    do_verbose=1
    curr_switch=""
    ;;
  --no-verbose)
    do_verbose=0
    curr_switch=""
    ;;
  --chrome)
    if [ "$do_which" != "" ]; then
      $(display_error "--chrome can not be specified with --blink")
      exit $E_INVALID_ARG
    fi
    do_which="chrome"
    curr_switch=""
    ;;
  --blink)
    if [ "$do_which" != "" ]; then
      $(display_error "--blink can not be specified with --chrome")
      exit $E_INVALID_ARG
    fi
    do_which="blink"
    curr_switch=""
    ;;
  --pre-roll)
    do_pre_roll=1
    curr_switch=""
    ;;
  --roll)
    roll_branches=1
    curr_switch=""
    ;;
  --info)
    do_info_hashes=1
    curr_switch=""
    ;;
  --directory)
    curr_switch="base-directory"   # takes an argument.
    ;;
  --old-branch)
    curr_switch="old-branch"       # takes an argument.
    ;;
  --new-branch)
    curr_switch="new-branch"       # takes an argument.
    ;;
  --old-revision)
    curr_switch="old-revision"     # takes an argument.
    ;;
  --new-revision)
    curr_switch="new-revision"     # takes an argument.
    ;;
  *)
    prefix=${var:0:2}
    if [ "$prefix" = "--" ]; then
      $(display_error "unexpected switch ${var}")
      exit $E_INVALID_ARG
    fi
    case "$curr_switch" in
      base-directory)
        base_dir="${var}"
        ;;
      old-branch)
        do_old_branch="${var}"
        ;;
      old-revision)
        do_old_revision="${var}"
        ;;
      new-branch)
        do_new_branch="${var}"
        ;;
      new-revision)
        do_new_revision="${var}"
        ;;
      *)
        if [ "$curr_switch" != "" ]; then
          $(display_error "unexpected paramter for ${curr_switch}")
          exit $E_INVALID_ARG
        else
          $(display_error "unexpected switch ${var}")
          exit $E_INVALID_ARG
        fi
        ;;
    esac
    curr_switch=""
    ;;
  esac
done

# Insure that everything is known otherwise prompt information.
if [ "$base_dir" = "" ]; then
  echo "--directory switch must be specified."
  exit $E_INVALID_ARG
fi

if [ "$do_which" == "" ]; then
  echo "--chrome or --blink switch must be specified."
  exit $E_INVALID_ARG
fi

if [ "$do_old_branch" = "" ]; then
  echo "Enter LAST ${do_which} true branch (e.g., Chrome version 34.0.1847.92 true branch is 1847)"
  read do_old_branch
fi

if [ "$do_old_revision" = "" ]; then
  echo "Enter LAST ${do_which} base trunk revision #"
  read do_old_revision
fi

if [ "$do_new_branch" = "" ]; then
  echo "Enter NEW ${do_which} true branch (e.g., Chrome version 35.0.1908.4 true branch is 1908)"
  read do_new_branch
fi

if [ "$do_new_revision" = "" ]; then
  echo "Enter NEW ${do_which} base trunk revision #"
  read do_new_revision
fi

echo
echo "Rolling new branch ${do_new_branch}@${do_new_revision}"

verbose_message
verbose_message "Previous branch ${do_old_branch}@${do_old_revision}"
verbose_message "New branch ${do_new_branch}@${do_new_revision}"
verbose_message

if [[ "$do_pre_roll" = "1" ]]; then
  display_remote_repository_creation
  exit 1
fi

pushd . > /dev/null

if [ "$base_dir" != "" ]; then
  cd ${base_dir}
fi

cd src

if [ "$do_which" = "blink" ]; then
  cd third_party/WebKit
fi

# Disable ^C and ^Z while running script.
trap '' INT
trap '' TSTP

validate_remotes

display_roll_commands

display_hashes

# Insure that all local branches for the roll are NOT based on the chrome or
# blink trunks.
validate_branches

# Re-enable ^C and ^Z.
trap - INT
trap - TSTP

popd > /dev/null

