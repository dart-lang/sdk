# Pragmas used in the FFI implementation

## Native Assets

This pragma is used for passing native assets to the VM.

```
@pragma('vm:ffi:native-assets', {
  'format-version': [1, 0, 0],
  'native-assets': {
    'linux_x64': {
      'package:foo/foo.dart': ['absolute', '/path/to/libfoo.so']
    }
  }
})
library 'vm:native-assets';
```

Related files:

* [pkg/vm/lib/native_assets/load_and_validate.dart](../../../pkg/vm/lib/native_assets/load_and_validate.dart)
* [pkg/vm/test/native_assets_validator_test.dart](../../../pkg/vm/test/native_assets_validator_test.dart)
* [runtime/lib/ffi_dynamic_library.cc](../../../runtime/lib/ffi_dynamic_library.cc)
* [runtime/vm/ffi/native_assets.cc](../../../runtime/vm/ffi/native_assets.cc)

## Native

The fully expanded version of `@Native` passed to the VM.

```
@pragma(
  'vm:ffi:native',
  Native<IntPtr Function(Pointer<Void>, IntPtr)>(
    symbol: 'MyClass_MyMethod',
    assetId: '<library uri>',
  ),
)
external int _myFunction$FfiNative(Pointer<Void> self, int x);
```

This is passed as a pragma so it is treated consistently with other pragmas.

Related files:

* [runtime/vm/kernel_loader.cc](../../../runtime/vm/kernel_loader.cc)
* [runtime/vm/object.cc](../../../runtime/vm/object.cc)

