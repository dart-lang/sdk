# infra/config branch

This branch contains dart project-wide configurations for infra services. For
example, cr-buildbucket.cfg defines builders that run on the dart waterfall and
commit queue.

## Making changes

It is recommended to have a separate checkout for this branch, so switching
to/from this branch does not populate/delete all files in the master branch.

### Initial setup:

```console
mkdir config
cd config
git init
git remote add origin https://dart.googlesource.com/sdk
git fetch origin infra/config
git reset --hard origin/infra/config
git config depot-tools.upstream origin/infra/config
```
Now you can create a new branch to make changes:

```console
git new-branch add-new-builder
# edit cr-buildbucket.cfg
git commit -a

git cl upload
```