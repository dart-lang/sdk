# Garbage Collection

The Dart VM has a generational garbage collector with two generations. The new generation is collected by a stop-the-world semispace [scavenger](https://github.com/dart-lang/sdk/blob/master/runtime/vm/heap/scavenger.h). The old generation is collected by concurrent-[mark](https://github.com/dart-lang/sdk/blob/master/runtime/vm/heap/marker.h)-concurrent-[sweep](https://github.com/dart-lang/sdk/blob/master/runtime/vm/heap/sweeper.h) or by concurrent-mark-parallel-[compact](https://github.com/dart-lang/sdk/blob/master/runtime/vm/heap/compactor.h).

## Object representation

Object pointers refer either to immediate objects or heap objects, distinguished by a tag in the low bits of the pointer. The Dart VM has only one kind of immediate object, Smis (small integers), whose pointers have a tag of 0. Heap objects have a pointer tag of 1. The upper bits of a Smi pointer are its value, and the upper bits of a heap object pointer are the most signficant bits of its address (the least significant bit is always 0 because heap objects always have greater than 2-byte alignment).

A tag of 0 allows many operations to be performed on Smis without untagging and retagging. It also allows hiding aligned addresses to the C heap from the GC.

A tag of 1 has no penalty on heap object access because removing the tag can be folded into the offset used by load and store instructions.

Heap objects are always allocated in double-word increments. Objects in old-space are kept at double-word alignment, and objects in new-space are kept offset from double-word alignment. This allows checking an object's age without comparing to a boundry address, avoiding restrictions on heap placement and avoiding loading the boundry from thread-local storage. Additionally, the scavenger can quickly skip over both immediates and old objects with a single branch.

| Pointer    | Referent                                |
| ---        | ---                                     |
| 0x00000002 | Small integer 1                         |
| 0xFFFFFFFE | Small integer -1                        |
| 0x00A00001 | Heap object at 0x00A00000, in old-space |
| 0x00B00005 | Heap object at 0x00B00004, in new-space |

Heap objects have a single-word header, which encodes the object's class, size, and some status flags.

On 64-bit architectures, the header of heap objects also contains a 32-bit identity hash field. On 32-bit architectures, the identity hash for heap objects is kept in a side table.

## Scavenge

See [Cheney's algorithm](https://en.wikipedia.org/wiki/Cheney's_algorithm).

## Parallel Scavenge

FLAG_scavenger_tasks (default 2) workers are started on separate threads. Each worker competes to process parts of the root set (including the remembered set). When a worker copies an object to to-space, it allocates from a worker-local bump allocation region. The same worker will process the copied object. When a worker promotes an object to old-space, it allocates from a worker-local freelist, which uses bump allocation for large free blocks. The promoted object is added to a work list that implements work stealing, so some other worker may process the promoted object. After the object is evacuated, the worker using a compare-and-swap to install the forwarding pointer into the from-space object's header. If it loses the race, it un-allocates the to-space or old-space object it just allocated, and uses the winner's object to update the pointer it was processing. Workers run until all of the work set have been processed, and every worker have processed its to-space objects and local part of the promoted work list.

## Mark-Sweep

All objects have a bit in their header called the mark bit. At the start of a collection cycle, all objects have this bit clear.

During the marking phase, the collector visits each of the root pointers. If the target object is an old-space object and its mark bit is clear, the mark bit is set and the target added to the marking stack (grey set). The collector then removes and visits objects in the marking stack, marking more old-space objects and adding them to the marking stack, until the marking stack is empty. At this point, all reachable objects have their mark bits set and all unreachable objects have their mark bits clear.

During the sweeping phase, the collector visits each old-space object. If the mark bit is clear, the object's memory is added to a [free list](https://github.com/dart-lang/sdk/blob/master/runtime/vm/heap/freelist.h) to be used for future allocations. Otherwise the object's mark bit is cleared. If every object on some page is unreachable, the page is released to the OS.

Note that because we do not mark new-space objects, we treat every object in new-space as a root during old-space collections. This property makes new-space and old-space collections more independent, and in particular allows a scavenge to run at the same time as concurrent marking.

## Mark-Compact

The Dart VM includes a sliding compactor. The forwarding table is compactly represented by dividing the heap into blocks and for each block recording its target address and the bitvector for each surviving double-word. The table is accessed in constant time by keeping heap pages aligned so the page header of any object can be accessed by masking the object.

## Safepoints

Any thread or task that can allocate, read or write to the heap is called a "mutator" (because it can mutate the object graph).

Some phases of GC require that the heap is not being used by a mutator; we call these "[safepoint](https://github.com/dart-lang/sdk/blob/master/runtime/vm/heap/safepoint.h) operations". Examples of safepoint operations include marking roots at the beginning of concurrent marking and the entirety of a scavenge.

To perform these operations, all mutators need to temporarily stop accessing the heap; we say that these mutators have reached a "safepoint". A mutator that has reached a safepoint will not resume accessing the heap (leave the safepoint) until the safepoint operation is complete. In addition to not accessing the heap, a mutator at a safepoint must not hold any pointers into the heap unless these pointers can be visited by the GC. For code in the VM runtime, this last property means holding only handles and no RawObject pointers. Examples of places that might enter a safepoint include allocations, stack overflow checks, and transitions between compiled code and the runtime and native code.

Note that a mutator can be at a safepoint without being suspended. It might be performing a long task that doesn't access the heap. It will, however, need to wait for any safepoint operation to complete in order to leave its safepoint and resume accessing the heap.

Because a safepoint operation excludes excution of Dart code, it is sometimes used for non-GC tasks that requires only this property. For example, when a background compilation has completed and wants to install its result, it uses a safepoint operation to ensure no Dart execution sees the intermediate states during installation.

## Concurrent Marking

To reduce the time the mutator is paused for old-space GCs, we allow the mutator to continue running during most of the marking work. 

### Barrier

With the mutator and marker running concurrently, the mutator could write a pointer to an object that has not been marked (TARGET) into an object that has already been marked and visited (SOURCE), leading to incorrect collection of TARGET. To prevent this, the write barrier checks if a store creates a pointer from an old-space object to an old-space object that is not marked, and marks the target object for such stores. We ignore pointers from new-space objects because we treat new-space objects as roots and will revisit them to finalize marking. We ignore the marking state of the source object to avoid expensive memory barriers required to ensure reordering of accesses to the header and slots can't lead skipped marking, and on the assumption that objects accessed during marking are likely to remain live when marking finishes.

The barrier is equivalent to

```c++
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

```c++
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

Operations on headers and slots use [relaxed ordering](https://en.cppreference.com/w/cpp/atomic/memory_order) and do not provide synchronization.

The concurrent marker starts with an acquire-release operation, so all writes by the mutator up to the time that marking starts are visible to the marker.

For old-space objects created before marking started, in each slot the marker can see either its value at the time marking started or any subsequent value sorted in the slot. Any slot that contained a pointer continues to continue a valid pointer for the object's lifetime, so no matter which value the marker sees, it won't interpret a non-pointer as a pointer. (The one interesting case here is array truncation, where some slot in the array will become the header of a filler object. We ensure this is safe for concurrent marking by ensuring the header for the filler object looks like a Smi.) If the marker sees an old value, we may lose some precision and retain a dead object, but we remain correct because the new value has been marked by the mutator.

For old-space objects created after marking started, the marker may see uninitialized values because operations on slots are not synchronized. To prevent this, during marking we allocate old-space objects black (marked) so the marker will not visit them.

New-space objects and roots are only visited during a safepoint, and safepoints establish synchronization.

When the mutator's mark block becomes full, it transfered to the marker by an acquire-release operation, so the marker will see the stores into the block.

## Write barrier elimination

Whenever there is a store into the heap, ```container.slot = value```, we need to check if the store creates references that the GC needs to be informed about.

The generational write barrier, needed by the scavenger, checks if

* `container` is old and not in the remembered set, and
* `value` is new

When this occurs, we must insert `container` into the remembered set.

The incremental marking write barrier, needed by the marker, checks if

* `container` is old, and
* `value` is old and not marked, and
* marking is in progress

When this occurs, we must insert `value` into the marking worklist.

We can eliminate these checks when the compiler can prove these cases cannot happen, or are compensated for by the runtime. The compiler can prove this when

* `value` is a constant. Constants are always old, and they will be marked via the constant pools even if we fail to mark them via `container`.
* `value` has the static type bool. All possible values of the bool type (null, false, true) are constants.
* `value` is known to be a Smi. Smis are not heap objects.
* `container` is the same object as `value`. The GC never needs to retain an additional object if it sees a self-reference, so ignoring a self-reference cannot cause us to free a reachable object.
* `container` is known to be a new object or known to be an old object that is in the remembered set and is marked if marking is in progress.

We can know that `container` meets the last property if `container` is the result of an allocation (instead of a heap load), and there is no instruction that can trigger a GC between the allocation and the store. This is because the allocation stubs ensure the result of AllocateObject is either a new-space object (common case, bump pointer allocation succeeds), or has been pre-emptively added to the remembered set and marking worklist (uncommon case, entered runtime to allocate object, possibly triggering GC).

```
container <- AllocateObject
<intructions that do not trigger GC>
StoreInstanceField(container, value, NoBarrier)
```

We can further eliminate barriers when `container` is the result of an allocation, and there is no instruction that can create an additional Dart frame between the allocation and the store. This is because after a GC, any old-space objects in the frames below an exit frame will be pre-emptively added to the remembered set and marking worklist (Thread::RestoreWriteBarrierInvariant).

```
container <- AllocateObject
<instructions that cannot directly call Dart functions>
StoreInstanceField(container, value, NoBarrier)
```
