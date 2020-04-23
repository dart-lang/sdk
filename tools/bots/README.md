# tools/bots

This folder contains scripts and configuration files used by Dart's continuous
integration and testing infrastructure.

## Test matrix

The file `test_matrix.json` defines the test configurations run by Dart's CI
infrastructure. Changes to the test matrix affect all builds that include them.

### Structure

The test matrix is a JSON document and consists of the `"filesets"` object, the
`"configurations"` list, and the `"builder_configurations"` list as well as a
`"global"` values object and a `"branches"` list.

### Filesets

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

### Configurations

The configurations describe all named configurations that the CI infrastructure
supports. It consists of a list of configuration descriptions.

Each configuration description defines one or more configuration names using a
simple template syntax, where a group `(a|b|c)` means taking each of the
options for a different configuration name. The set of all configuration names
is the result of picking each combination of group options.

The configuration name implicitly defines the options of the configuration
(system, architecture, compiler, etc.), but additional options can be given in
an `options` field.

```json
"configurations": {
  "unittest-(linux|win|mac)": {
    "options": {
      "compiler": "dartk",
      "mode": "release",
}},
```


### Builder Configurations

The builder configurations describes all test configurations a specific builder
must execute. Each builder configuration is an object that specifies which
builders it applies to, defines the build steps for the builders, and some
additional metadata. Only one builder configuration can apply to a builder.

```json
"builder_configurations": [
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

Inside arguments, the following variables will be expanded to values extracted
from the builder name:
- `${mode}`: the mode in which to run the tests; e.g., `release`, `debug`
- `${arch}`: architecture to run the tests on; e.g., `ia32`, `x64`
- `$[system}`: the system on which to run the tests; e.g., `win`, `linux`, `mac`
- `${runtime}`: the runtime to use to run the tests; e.g., `vm`, `chrome`, `d8`

```json
"steps": [
  {
    "name": "build it",
    "script": "tools/build.py",
    "arguments": ["--a-flag", "target", "another_target"]
  },
  {
    "name": "test it",
    "arguments": ["-nconfiguration-${system}"]
  }
]
```

A step that uses the script `tools/test.py` either explicitely or by default is
called a "test step". Test steps must include the `-n` command line argument to
select one of the named configurations defined in the `configurations` section.

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

## Builders

### Builder name parsing
The builder names are split by '-' and each part is then examined if it is an
option. Options can be runtimes (e.g. "chrome"), architectures (e.g. x64) and
operating system families (e.g. win). For each valid option, additional
arguments are passed to the `tools/build.py` script.

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
