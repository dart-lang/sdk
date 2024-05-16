> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

Since Dart is an open-source project we rely on a number of other open-source projects, as tools
for building and testing, and as libraries compiled into the Dart SDK. Please follow these guidelines when working with third-party dependencies in both source and binary form.

# Third-party source dependencies

> [!IMPORTANT]
> New dependencies need explicit approval from Dart leadership before being added to the Dart SDK `DEPS` file unless they are [Dart core packages](https://pub.dev/publishers/dart.dev/packages) (Googlers see go/dart-sdk-deps-block for background information). To get approval, file an issue in the Dart SDK repo. 

When adding new third party source dependencies please be very careful. Make sure that the license for the software is compatible with our license - a large set of licenses are more restrictive when you actually link in the source instead of just using the tools.
For example, a compiler's license might allow using it to compile our binary, but could be too restrictive to allow using its source code as part of the source code for a Dart SDK tool.
You must add a README.google if you check in third-party code, and note any local changes that have been applied to the code (see below for a template). Please cc dart-engprod@google.com on any third-party additions. 

If you need to discuss license issues to make sure that a license is compatible please reach out to the legal team at google or talk with dart-engprod@google.com who can guide you to the right
person. Please refrain from speculating about licenses or make assumptions about what you may and may not do. If in doubt you should ask. If you are not a Google employee, contact a Dart team member who is.

We have a few rules to make sure that we can continue to build older versions of the SDK even if people delete or rewrite the history of repositories containing our third-party dependencies. There are two options for using repositories not hosted under https://github.com/dart-lang/ or https://github.com/google/:

1. Move it to the dart-lang org, or fork it there. Moving is better than forking since it avoids fragmented versions. If you do fork, please state in the README that this is used for pulling in as a DEPS, don't make local changes, and be sure to not publish to pub from the dart-lang fork.

2. Get the github repo mirrored on the dart.googlesource.com git server, and pull the dependency from there. This is the same way we do normal dependencies from dart-lang (see below), with one important exception:
**For security reasons, all code pulled in to build the Dart SDK must be reviewed by Google employees, no matter where it comes from.** This means that you, or a Google employee, need to do an initial review of all code up to and including the commit you put in the DEPS file for all external packages.

All external packages must be pinned to a fixed commit (revision) in the DEPS file. If you update the DEPS to pin a newer version, you need to do another review of the changes between the two revisions. You can upload the review (of the changes in the dependency, not just the change in the DEPS file) to https://dart-review.googlesource.com for easy reviewing, and upstream any fixes in this dependency, before pinning the new version of the dependency.

For all dependencies on GitHub, we need a mirror. File a GitHub issue labeled `area-infrastructure` (https://dartbug.com) requesting a mirror. The mirrors go to `https://dart.googlesource.com/external/github.com/<org>/<repo>.git`. Once the mirror is set up, you can commit your changes to the DEPS file pointing at the github mirror.

While you wait for the mirror to get set up, you can add the dependency to the DEPS file pointing directly to `http://github.com/<org>/<repo>.git`. This will let you develop against the dependency locally, but don't commit this.

# Rolling dependencies

Generally, in order to roll a dependency, you edit the SDK's [DEPS](https://github.com/dart-lang/sdk/blob/main/DEPS) file to reference the new commit for the particular package. You then run `gclient sync -D` to bring that commit into your local checkout, and follow the normal contribution process to contribute that change to the SDK (ala `git checkout -b roll_dep_foo; git add DEPS; git commit -m "[deps] update foo dep"; git cl upload`).

We also have two tools in the SDK that can help you roll deps:

## Rolling a specific dependency

To roll a specific dependency, you can use the `tools/manage_deps.dart` script. From the SDK top level directory, run:

```
dart tools/manage_deps.dart bump third_party/pkg/package_config
```

That will update the DEPS file to the latest commit for the `package_config` dep and optionally create a CL for that change.

## Rolling all package dependencies

In order to roll all Dart packages referenced in the DEPS file to their latest versions, run:

```
dart tools/rev_sdk_deps.dart
```

That will modify the DEPS file in-place, updating all the Dart packages deps to their latest versions. You can then create a CL of the changes via the normal contribution process.

# Third-party binaries and binary data in general

We occasionally need add binary versions of tools to make our testing/build/distribution infrastructure easier to maintain. These can be tools derived from our own source code (like fixed stable versions of the Dart standalone binary), or can be open source tools (like the standalone Firefox binary). Please be absolutely sure that the binary is compatible with our license. If your binary is not needed for building/distributing the core dart tool-chain you should consider other options (e.g., lazily fetching the files from the source or from Google Cloud Storage). In any case, always be vigilant about the license and please cc dart-engprod@google.com on any third party additions.

# Where do they go

We put third party binaries on Google Cloud Storage and fetch them using a DEPS hook. We pin the DEPS entries to the hashes of specific versions, and we never delete old entries from the bucket where they are located, since that would destroy our ability to do old builds. This allows us to only have a single location holding the binaries for bleeding edge, dev branch, and stable releases.

Binary data is preferably added as a go/cipd package. Please note that only a select set of people have access to uploading CIPD package. If you feel that you need access or help please contact dart-engprod@google.com

# README.google templates

When adding third party dependencies you must always add a README.google file describing what you put in, which license, which revision if applicable, the repository/page where you obtained the source/binary and any local modifications. You should also always make sure that there is a LICENSE file with the actual license. The following is a verbatim copy of the README.google for the firefox javascript shell, you can use that as a template.

```
Name: Firefox command line javascript shell.
Short Name: js-shell
URL: http://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/15.0.1-candidates/build1/
Version: 15.0.1
Date: September 5th 2012
License: MPL, http://www.mozilla.org/MPL

Description:
This directory contains the firefox js-shell binaries for Windows, Mac and
Linux. The files was fetched from:
http://ftp.mozilla.org/pub/mozilla.org/firefox/candidates/15.0.1-candidates/
on September 28th 2012.
The binaries are used for testing dart code compiled to javascript.
```
