
class _PointerLockJs extends _DOMTypeJs implements PointerLock native "*PointerLock" {

  bool get isLocked() native "return this.isLocked;";

  void lock(_ElementJs target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) native;

  void unlock() native;
}
