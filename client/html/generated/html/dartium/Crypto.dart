
class _CryptoImpl extends _DOMTypeBase implements Crypto {
  _CryptoImpl._wrap(ptr) : super._wrap(ptr);

  void getRandomValues(ArrayBufferView array) {
    _ptr.getRandomValues(_unwrap(array));
    return;
  }
}
