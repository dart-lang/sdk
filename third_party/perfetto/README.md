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

# Updating Perfetto

After updating Perfetto regenerated `*.pbzero.h` files by running:

```
$ dart third_party/perfetto/compile_perfetto_protos.dart
```
