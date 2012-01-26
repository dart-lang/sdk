
class PointerLockJs extends DOMTypeJs implements PointerLock native "*PointerLock" {

  bool get isLocked() native "return this.isLocked;";

  void lock(ElementJs target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) native;

  void unlock() native;
}
