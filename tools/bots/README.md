# tools/bots
This folder contains scripts and configuration files used by Dart's continuous
integration and testing infrastructure.

## Test matrix
The file `test_matrix.json` defines the test configurations run by Dart's CI
infrastructure. Changes to the test matrix affect all builds that include them.

### Structure
The test matrix is a JSON document and consists of the `"filesets"` object and
the `"configurations"` array.

The file sets define files and/or directories that need to be present for a test
configuration at runtime. Any directory specified will be included along with
its subdirectories recursively. Directory names must have a `/` at the end. All
paths are relative to the SDK checkout's root directory.

```json
"filesets": {
  "a_fileset_name": [
    "a/directory/",
    "a/file"
  ],
  "another_fileset_name": [
    "another/directory/",
    "another/file"
  ]
}
```

The builder configurations describe all test configurations a specific builder
must execute. Each builder configuration is an object that specifies which
builders it applies to, defines the build steps for the builders, and some
additional metadata. Only one builder configuration can apply to a builder.

```json
"configurations": [
  {
    "builders": [
      "a-builder",
      "another-builder"
    ],
    "meta": {
      "description": "Description of this configuration."
    },
    "steps": [
    ]
  }
]
```

Each step is an object and must have a name. A step may also specify a script to
run instead of the default script: `tools/test.py`. Additional arguments may be
specified. These arguments will be passed to the script.

```json
"steps": [
  {
    "name": "build it",
    "script": "tools/build.py",
    "arguments": ["--a-flag", "target", "another_target"]
  },
  {
    "name": "test it",
  }
]
```

A step using the default script may also be sharded across many machines using
the `"shards"` parameter. If a step is sharded, it must specify a `"fileset"`.
Only the files and directories defined by the file set will be available to the
script when it's running on a shard.

```json
{
  "name": "shard the tests",
  "shards": 10,
  "fileset": "a_fileset_name"
}
```

### Builder name parsing
The builder names are split by '-' and each part is then examined if it is an
option. Options can be runtimes (e.g. "chrome"), architectures (e.g. x64) and
operating system families (e.g. win). For each valid option, additional
arguments are passed to the `tools/test.py` and `tools/build.py` scripts.

### Adding a new builder
To add a builder:

1. Decide on a name.
2. Add the builder name to a new or existing configuration.
3. File an issue labelled "area-infrastructure" to get your builder activated.

### Testing a new or modified builder
Builders can be tested using a tool called `led` that is included in
depot_tools. Replace buildername and CL number with the correct values and run:

```bash
led get-builder luci.dart.ci:<builder name> | \
led edit-cr-cl 'https://dart-review.googlesource.com/c/<cl number>' | \
led launch
```

### Adding a builder to the commit queue
For now, file an issue labeled "area-infrastructure" to get your builder added
to the commit queue.

## Glossary

### Builder
A builder has a name and defines the steps the need to be run when it is
executed by a bot. In general, a builder defines how to build and test software.

### Bot
A physical or virtual machine (or even a docker container) that executes all
commands it receives. Often, these commands are the steps defined by a builder.

### Sharding
Sharded steps copy all files in a file set to as many bots as specified and
runs the same command on all of the shards. Each shard has a shard number. The
shard number and the total number of shards are passed as arguments to the
command. The command is then responsible for running a subset of its work on
each shard based on these arguments.
