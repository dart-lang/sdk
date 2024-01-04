@DefaultAsset('someAssetId')
library;

import 'dart:ffi';

@Native<Pointer<Void> Function()>()
external Pointer<Void> malloc();

@Native<Pointer<Void> Function()>(assetId: 'anotherAsset')
external Pointer<Void> mallocInAsset();

@Native()
external final Pointer<Void> ptr;

@Native(assetId: 'anotherAsset')
external final Pointer<Void> ptrInAsset;

void main() {
  print(malloc());
  print(mallocInAsset());
  print(ptr);
}
