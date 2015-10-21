# Dart-ApiX

The goal of Dart-ApiX is to ease the process of embedding Dart in applications. The Dart VM is delivered in the form of a shared library. A set of embedding API extesions is provided.

## API Extensions

## Getting Source

Dart-ApiX is developed on top of official standalone Dart VM. Therefore you need [depot_tools](http://www.chromium.org/developers/how-tos/install-depot-tools).

One time setup

```
gclient config https://github.com/stakira/dart-apix.git@origin/stable --name=dart-apix --unmanaged
```

Source checkout

```
gclient sync
```

For more details refer to [this](https://github.com/dart-lang/sdk/wiki/Getting-The-Source)

## Building

#### Building on Windows with Visual Studio 2013

```
set gyp_msvs_version=2013
gclient runhooks
./tools/build.py --mode release --arch ia32
```

For more details refer to [this](https://github.com/dart-lang/sdk/wiki/Building)
