# Dart

## An approachable, portable, and productive language for high-quality apps on any platform

## Quick Start
Install Dart by following the [installation guide](https://dart.dev/get-dart).

Then, run your first Dart program:
```bash
dart create hello_world
cd hello_world
dart run
```

## Example Projects
- [Flutter](https://flutter.dev): Build beautiful mobile and web apps with a single codebase.
- [Aqueduct](https://github.com/stablekernel/aqueduct): A server-side framework for building HTTP APIs in Dart.
- [Stagehand](https://github.com/dart-lang/stagehand): A Dart project scaffolding generator.

### Contributing to Dart

We welcome contributions from the community to help improve Dart. Here’s how you can get started:

#### 1. Filing Issues
If you encounter a bug or have a feature request, the easiest way to contribute is by [filing an issue](https://github.com/dart-lang/sdk/issues/new). Be sure to provide as much detail as possible, including steps to reproduce the issue and any relevant logs or screenshots.

#### 2. Contributing Code
To contribute patches to Dart, follow these steps:

##### Step 1: Fork the Repository
Fork the Dart SDK repository by clicking the "Fork" button on the [Dart GitHub page](https://github.com/dart-lang/sdk). This will create a copy of the repository under your GitHub account.

##### Step 2: Clone the Repository
Clone your forked repository to your local machine:
```bash
git clone https://github.com/your-username/sdk.git
cd sdk
```

##### Step 3: Set Up the Development Environment
Follow these steps to prepare your machine for building Dart:

Install necessary dependencies based on your operating system. For example:

MacOS: `brew install ninja`
Linux: `sudo apt-get install ninja-build`
Windows: Follow the [Windows Build Instructions](https://github.com/dart-lang/sdk/blob/main/docs/windows.md)
Install the Dart dependencies:

```bash
./tools/build.py --help
./tools/build.py
```
Make sure your environment is configured to use Dart:

```bash
dart --version
```
More details on setting up the environment can be found in our Building Dart documentation.

##### Step 4: Create a New Branch
Before you start coding, create a new branch:

```bash
git checkout -b your-feature-branch
```
##### Step 5: Make Your Changes
Implement your feature or fix. Ensure your code adheres to Dart's coding style guidelines.

##### Step 6: Write Tests
All code contributions must include appropriate unit tests to ensure the feature or bug fix works as expected. Refer to our Testing Guide for details on how to write tests for Dart.

##### Step 7: Commit and Push Your Changes
Once you're satisfied with your changes, commit your work:

```bash
git add .
git commit -m "Add feature: [short description]"
git push origin your-feature-branch
```
##### Step 8: Create a Pull Request
Go to the Dart GitHub repository and submit a pull request (PR) from your feature branch. Make sure to:

Reference any issues your PR addresses (e.g., Fixes #123).
Provide a detailed description of the changes you made.
Follow our pull request guidelines.
Your code will be reviewed, and feedback will be provided. Once all requested changes are made and tests pass, your PR will be merged!

Dart is:

  * **Approachable**:
  Develop with a strongly typed programming language that is consistent,
  concise, and offers modern language features like null safety and patterns.

  * **Portable**:
  Compile to ARM, x64, or RISC-V machine code for mobile, desktop, and backend.
  Compile to JavaScript or WebAssembly for the web.

  * **Productive**:
  Make changes iteratively: use hot reload to see the result instantly in your running app.
  Diagnose app issues using [DevTools](https://dart.dev/tools/dart-devtools).

Dart's flexible compiler technology lets you run Dart code in different ways,
depending on your target platform and goals:

  * **Dart Native**: For programs targeting devices (mobile, desktop, server, and more),
  Dart Native includes both a Dart VM with JIT (just-in-time) compilation and an
  AOT (ahead-of-time) compiler for producing machine code.

  * **Dart Web**: For programs targeting the web, Dart Web includes both a development time
  compiler (dartdevc) and a production time compiler (dart2js).  

![Dart platforms illustration](docs/assets/Dart-platforms.svg)

## License & patents

Dart is free and open source.

See [LICENSE][license] and [PATENT_GRANT][patent_grant].

## Using Dart

Visit [dart.dev][website] to learn more about the
[language][lang], [tools][tools], and to find
[codelabs][codelabs].

Browse [pub.dev][pubsite] for more packages and libraries contributed
by the community and the Dart team.

Our API reference documentation is published at [api.dart.dev](https://api.dart.dev),
based on the stable release. (We also publish docs from our 
[beta](https://api.dart.dev/beta) and [dev](https://api.dart.dev/dev) channels,
as well as from the [primary development branch](https://api.dart.dev/be)).

## Building Dart

If you want to build Dart yourself, here is a guide to
[getting the source, preparing your machine to build the SDK, and building][building].

There are more documents in our repo at [docs](https://github.com/dart-lang/sdk/tree/main/docs).

## Contributing to Dart

The easiest way to contribute to Dart is to [file issues][dartbug].

You can also contribute patches, as described in [Contributing][contrib].

## Roadmap

Future plans for Dart are included in the combined Dart and Flutter
[roadmap][roadmap] on the Flutter wiki.

[building]: https://github.com/dart-lang/sdk/blob/main/docs/Building.md
[codelabs]: https://dart.dev/codelabs
[contrib]: https://github.com/dart-lang/sdk/blob/main/CONTRIBUTING.md
[dartbug]: http://dartbug.com
[lang]: https://dart.dev/guides/language/language-tour
[license]: https://github.com/dart-lang/sdk/blob/main/LICENSE
[patent_grant]: https://github.com/dart-lang/sdk/blob/main/PATENT_GRANT
[pubsite]: https://pub.dev
[repo]: https://github.com/dart-lang/sdk
[roadmap]: https://github.com/flutter/flutter/wiki/Roadmap
[tools]: https://dart.dev/tools
[website]: https://dart.dev
