
class PointerLockJS implements PointerLock native "*PointerLock" {

  bool get isLocked() native "return this.isLocked;";

  void lock(ElementJS target, [VoidCallback successCallback = null, VoidCallback failureCallback = null]) native;

  void unlock() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
