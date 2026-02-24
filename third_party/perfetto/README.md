Perfetto sources are in `src/`.

`protos/` contain manually tree-shaken protobuf message definitions used by the
VM as well as `*.pbzero.h` files generated from these definitions.

Note: experiments show that three-shaking protobuf messages does not have
an impact on code size of the VM because protozero generates header only
code for serializing protobuf messages which tree-shakes very well.

This is not the case for Dart code we ship in `pkg/vm_service_protos`:
using pristine message definitions (as given in Perfetto sources) would
require including large amount of generated Dart code into this package,
which will never be used by consumers like DevTools. This code does not
tree-shake by default because each message is strongly connected to all
of its submessages (though our compiler toolchains provide protobuf
aware tree-shaker to reduce the size of the code).

Thus for now we choose to use manually tree-shaken protos.

# Regenerating protos

Perfetto's `protozero_plugin` (protoc plugin) is not distributed a binary
(because it is not intended for use outside of Perfetto), so to
regenerate `*.pbzero.{cc,h}` files we need to build it from source.
This however requires a bunch of dependencies which Dart SDK build does
not currently depend on (specifically Protobuf and Abseil). So instead `protozero_plugin` needs to be built out-of-tree.

This can be done using the following commands:

```
$ git clone https://github.com/google/perfetto
$ cd perfetto
$ git checkout $perfetto_rev_from_DEPS
$ tools/install-build-deps
$ gn args out/linux
$ ninja -C out/linux protoc protozero_plugin
```

Then you can run

```
$ PATH=$PERFETTO_DIR/out/linux:$PATH dart third_party/perfetto/tools/compile_perfetto_protos.dart
```
