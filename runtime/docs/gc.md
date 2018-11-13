# Garbage Collection

## Object representation

## Scavenge

## Mark-Sweep

## Mark-Compact

## Concurrent Marking

To reduce the time the mutator is paused for old-space GCs, we allow the mutator to continue running during most of the marking work. 

### Barrier

With the mutator and marker running concurrently, the mutator could write a pointer to an object that has not been marked (TARGET) into an object that has already been marked and visited (SOURCE), leading to incorrect collection of TARGET. To prevent this, the write barrier checks if a store creates a pointer from an old-space object to an old-space object that is not marked, and marks the target object for such stores. We ignore pointers from new-space objects because we treat new-space objects as roots and will revisit them to finalize marking. We ignore the marking state of the source object to avoid expensive memory barriers required to ensure reordering of accesses to the header and slots can't lead skipped marking, and on the assumption that objects accessed during marking are likely to remain live when marking finishes.

The barrier is equivalent to

```
StorePoint(RawObject* source, RawObject** slot, RawObject* target) {
  *slot = target;
  if (target->IsSmi()) return;
  if (source->IsOldObject() && !source->IsRemembered() && target->IsNewObject()) {
    source->SetRemembered();
    AddToRememberedSet(source);
  } else if (source->IsOldObject() && target->IsOldObject() && !target->IsMarked() && Thread::Current()->IsMarking()) {
    if (target->TryAcquireMarkBit()) {
      AddToMarkList(target);
    }
  }
}
```

But we combine the generational and incremental checks with a shift-and-mask.

```
enum HeaderBits {
  ...
  kOldAndNotMarkedBit,      // Incremental barrier target.
  kNewBit,                  // Generational barrier target.
  kOldBit,                  // Incremental barrier source.
  kOldAndNotRememberedBit,  // Generational barrier source.
  ...
};

static const intptr_t kGenerationalBarrierMask = 1 << kNewBit;
static const intptr_t kIncrementalBarrierMask = 1 << kOldAndNotMarkedBit;
static const intptr_t kBarrierOverlapShift = 2;
COMPILE_ASSERT(kOldAndNotMarkedBit + kBarrierOverlapShift == kOldBit);
COMPILE_ASSERT(kNewBit + kBarrierOverlapShift == kOldAndNotRememberedBit);

StorePointer(RawObject* source, RawObject** slot, RawObject* target) {
  *slot = target;
  if (target->IsSmi()) return;
  if ((source->header() >> kBarrierOverlapShift) &&
      (target->header()) &&
      Thread::Current()->barrier_mask()) {
    if (target->IsNewObject()) {
      source->SetRemembered();
      AddToRememberedSet(source);
    } else {
      if (target->TryAcquireMarkBit()) {
        AddToMarkList(target);
      }
    }
  }
}

StoreIntoObject(object, value, offset)
  str   value, object#offset
  tbnz  value, kSmiTagShift, done
  lbu   tmp, value#headerOffset
  lbu   tmp2, object#headerOffset
  and   tmp, tmp2 LSR kBarrierOverlapShift
  tst   tmp, BARRIER_MASK
  bz    done
  mov   tmp2, value
  lw    tmp, THR#writeBarrierEntryPointOffset
  blr   tmp
done:

```

### Data races

Operations on headers and slots use (relaxed ordering)[https://en.cppreference.com/w/cpp/atomic/memory_order] and do not provide synchronization.

The concurrent marker starts with an acquire-release operation, so all writes by the mutator up to the time that marking starts are visible to the marker.

For old-space objects created before marking started, in each slot the marker can see either its value at the time marking started or any subsequent value sorted in the slot. Any slot that contained a pointer continues to continue a valid pointer for the object's lifetime, so no matter which value the marker sees, it won't interpret a non-pointer as a pointer. (The one interesting case here is array truncation, where some slot in the array will become the header of a filler object. We ensure this is safe for concurrent marking by ensuring the header for the filler object looks like a Smi.) If the marker sees an old value, we may lose some precision and retain a dead object, but we remain correct because the new value has been marked by the mutator.

For old-space objects created after marking started, the marker may see uninitialized values because operations on slots are not synchronized. To prevent this, during marking we allocate old-space objects black (marked) so the marker will not visit them.

New-space objects and roots are only visited during a safepoint, and safepoints establish synchronization.

When the mutator's mark block becomes full, it transfered to the marker by an acquire-release operation, so the marker will see the stores into the block.
