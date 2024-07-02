> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

There are several ways to contribute code in GitHub, for example

1. Forking and creating pull request from a forked repo (https://help.github.com/articles/fork-a-repo)
1. Branching within the main repo, and doing pull requests from one branch to another.
1. Working on a local branch, creating a code review using Gerrit, push directly into main (this article).

## Step 1: get the source

[Checkout the source](Building.md#source)

Tip: if you want to get automatic backups of an NFS directory, but take advantage of fast git performance on a local directory, you can use the instructions above in an NFS directory and use a mirror in a local directory with git-new-workdir.

Then work from the local directory. Files uncommitted are not backed up, but every commit you make is automatically backed up. The script 'git-new-workdir' is described in more detail here: http://nuclearsquid.com/writings/git-new-workdir/.
 
## Step 2: verify that git-cl is configured correctly.
 
There is a `codereview.settings` file in the repo to configure things automatically, but it never hurts to check:

    > cat codereview.settings
    # This file is used by gcl to get repository specific information.
    GERRIT_HOST: True
    CODE_REVIEW_SERVER: https://dart-review.googlesource.com
    VIEW_VC: https://dart.googlesource.com/sdk/+
    CC_LIST: reviews@dartlang.org

## Step 3: Create a branch for your new changes

Pick a branch name not existing locally nor in the remote repo, we recommend that you use your username as a prefix to make things simpler.

    > cd sdk                          # the repo created above
    > git checkout -b uname_example   # new branch

## Step 4: Do your changes and commit them locally in git

    > echo "file contents" > awesome_example.txt
    > git add awesome_example.txt
    > git commit -a -m "An awesome commit, for an awesome example."

## Step 5: Upload CL using 'git cl' (installed with gcl)

    > git cl upload origin/main
    > git cl web

Then click on the `Start Review` button to send email to the reviewers from the Gerrit website.

## Step 6: Make code review changes and publish new versions of your code

    > echo "better file contents" > awesome_example.txt
    > git commit -a -m "An awesomer commit"
    > git cl upload origin/main

## Step 7: Sync up to latest changes

If new changes have been made to the repo, you need sync up to the new changes before submitting your code. You can do this in two ways:

There are two ways to sync up:
  * merging

        > git pull origin main
        > git cl upload origin/main

  * rebasing

        > git pull --rebase origin main
          (which is similar to first pull and merge in main, and then rebase:
            > git checkout main
            > git pull
            > git rebase main uname_example)
        > git cl upload origin/main

## Step 8: Submit your changes

    > git cl land origin/main

This command will close the issue in Gerrit and submit your code directly on main.

## Step 9: Clean up the mess

After submitting, you can delete your local branch so that the repo is clean and tidy :)
 
    > git checkout main
    > git branch -D uname_example    # delete local branch

## Step 10: Goto step 3
