# Running Benchmarks

There are two entry points for running benchmarks:
* **main.dart** - a general Dart application for running performance benchmarks
* **local_runner.dart** - an example Dart application
which sets up the local environment
and then calls main.dart to run performance benchmarks

## local_runner.dart

This Dart application is one example for running performance benchmarks.
When run, this application 1) extracts a branch from a git repository
into a temporary directory, and 2) creates a symlink to the out or xcodebuild
directory for proper package-root package resolution.
The required command line arguments are
* **gitDir** = a path to the git repository containing the initial target source
* **branch** = the branch containing the initial target source
* **inputFile** = the instrumentation or log file

Once setup is complete, this applications calls main.dart

## main.dart

This Dart application reads an instrumentation or local log file produced by
analysis server, "replays" that interaction with the analysis server,
compares the notifications and responses with what was recorded in the log,
and produces a report. It assumes that the environment for playback has
already been setup.
The required command line arguments are
*  **-i, --input             <filePath>**
The input file specifying how this client should interact with the server.
If the input file name is "stdin", then the instructions are read from stdin.
*  **-m, --map               <oldSrcPath>,<newSrcPath>**
This option defines a mapping from the original source directory <oldSrcPath>
when the instrumentation or log file was generated
to the target source directory <newSrcPath> used during performance testing.
Multiple mappings can be specified.
WARNING: The contents of the target directory will be modified
*  **-t, --tmpSrcDir         <dirPath>**
The temporary directory containing source used during performance measurement.
WARNING: The contents of the target directory will be modified
*  **--newTaskModel**       enable the use of the new task model
*  **-d, --diagnosticPort** localhost port on which server
                            will provide diagnostic web pages
*  **-v, --verbose**        Verbose logging
*  **--vv**                 Extra verbose logging
*  **-h, --help**           Print this help information
