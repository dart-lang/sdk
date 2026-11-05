# Requirements
* Limited size.
* Reliable: no corruption, no phantom values, no leaks.
* Fast put and get without performance cliffs.
* Support for multiple processes.

# Overview

The file is a sequence of 1 KiB pages, in fixed order:

```text
page 0       header                      format, commit ID, free page count, selector slot,
                                         data reclamation clock hand
page 1       selector 0                  \  one of these two is the committed one,
page 2       selector 1                  /  chosen by the `selectorSlot` field of the header
page 3       allocation bitmap, copy 0   512 chunks
page 515     allocation bitmap, copy 1   512 chunks
page 1027    hash table, copy 0          4096 buckets
page 5123    hash table, copy 1          4096 buckets
page 9219    data area                   all remaining pages
```

| Region | Pages | Contents |
| --- | --- | --- |
| Header | 1 | Format, commit ID, free page count, selector slot, data reclamation clock hand |
| Selectors | 2 | Which copy of each allocation bitmap chunk and hash table bucket is committed |
| Allocation bitmap | 2 x 512 | One bit per data page; the bit is set when the page is allocated |
| Hash table | 2 x 4096 | Buckets of 128 entries; each entry is a 32-bit key hash and a 32-bit page reference |
| Data area | the rest | Value headers with inline values, continuation pages, overflow metadata pages |

The page indices above are for the maximum configuration of `2^22` pages;
the region sizes scale with the file size, their order does not.

# General data structure
We support files with size up to 4GiB, let's talk as if this is the size.
File size: 2^32 bytes.

We want to have some structure in these files, so we split the file into 2^10 = 1024 = 1KiB size **file pages**.
This is a classical database approach.
So, we have 2^32 / 2^10 = 2^22 pages.

## Storage
We use `class Storage` as an interface for reading and writing.
We use `_MemoryStorage` in tests and `FileStorage` in production.

## _BufferPool
We use **_BufferPool** to read and write pages, with caching; and separate flush invocation to write pages into the storage. This raises the abstraction level from raw file offsets.

# Data pages
Some of the file pages are the SingleFileByteStore metadata.
Most of the file pages are **data pages**.
Data pages store values associated with keys.
When we store a value, we need to allocate data pages.
When a key / value pair is evicted, we need to free its data pages.
To track whether the page is used or free, we use **allocation bitmap**.

In the allocation bitmap we have 1 bit per data page.
This is `8` pages per allocation bitmap byte.
So, we need `2^22 / 2^3 = 2^19 bytes` of allocation bitmap.
The allocation bitmap, as any other data, lives in pages.
So, we need `2^19 / 2^10 = 2^9 = 512` allocation bitmap pages.
We call these allocation bitmap pages as **chunks**.

# Hash table
We support up to `2^19 = 524,288` keys.
For comparison, on the computer used for the analyzer development we have about `300,000` files in the analysis driver cache.
We will discuss as if we have exactly `2^19` keys.

We store hash table **entries** as pairs `(hash, firstPage + 1): (uint32, uint32)`.
So, we use `8 = 2^3` bytes per entry.
We can put `2^10 / 2^3 = 2^7 = 128` entries per page.
`(0, 0)` represents an empty hash table slot.

We call hash table pages as **buckets**.
We need `2^19 / 2^7 = 2^12 = 4096` hash table pages.

We use "**bucketized open addressing** with bounded linear probing", not "open addressing with linear probing". Because in stress testing the whole open addressing showed accumulation of long chains of conflicts and tombstones, and expensive IO for probing.

# Key lookup
We hash the key and find the **home entry index** in the *whole* hash table from `0` to `2^19 - 1`.
We convert it into the hash table bucket and the slot in this bucket.

Then we probe entries from this slot, with wrapping around inside the bucket, but not leaving it. This limits the probe count to `128`.

If we find an empty entry that has `0` as the encoded page reference, there is no such entry.
We still return the slot in the bucket, this is where the new entry should be put.

If the hash matches, we read the **value header** from the first value page, and compare full keys.

If there is no such key, and no empty entry, this means that the bucket is full, and if we try to write into it, we need to evict at least one entry, actually we do 16.
# Get value by key
We look up the key and get back the home entry index and, if found, the value header.

The value header has the key, the length of the value, the checksum of the value, and the list of **continuation pages** (data pages) that contain the value itself.

As an optimization for small values, the first value page (with the value header) has also the first portion of the value. We call it **inline value**.

We allocate big enough Uint8List, read inline value and continuation pages.
At the end we check that the checksum matches, so there was no damage to the file.

# Put value for the key
For better performance, SingleFileByteStore does not write each key / value pair immediately.

We accumulate up to the limit of the number of entries, or the total size of values, and then write as a batch inside `flush`.

## Actual writing: flush
We can only write values, new or replacements, into available data pages, so that if there is an interruption (like process killed), we don’t leave the store in an inconsistent state.

So, we ensure that we have enough new data page capacity, evicting old values if necessary.
If we need to evict old values to free data pages, we commit that eviction in a separate `_WriteTransaction` before writing accumulated key / value pairs in another `_WriteTransaction`.
This ensures that the freed pages are no longer referenced by the committed state before we reuse them, preserving consistency if a crash occurs.

The file lock (see "Support for multiple processes" below) is _not_ released between the two transactions, so another writer cannot take the freed pages between eviction and insertion.

# Reliability
This is one of the core requirements for `SingleFileByteStore`.

It is a cache, so it can lose values.
This is expensive, but if this happens rarely, not too bad.

But it must not produce incorrect values.
If we ask the value for a key, the answer should be either **a value** that was put previously, or "no value".
It is not acceptable to return values that were partially updated because of **torn writes**.

We also should not leave the hash table in an inconsistent state. Each entry in the hash table should be either empty, or point at a complete value.

In the allocation bitmap, we should not **use after free** - mark data pages as free if there is still a key / value pair in the hash table that uses these data pages.

In the allocation bitmap, we should not **leak data pages** - we should not erase an entry from the hash table, and leave the allocation bitmap not updated.

So, a naive approach with updating the hash table and the allocation bitmap does not work. If we update one or another first, we risk either use after free, or leak.

We need **transactions**. The committed state of the system stays intact, changes are done in separate file pages, everything is ephemeral until the very last step when we say "this is the new committed state".

## Header slot
See `class _Header` and its `int selectorSlot`.
It can be either `0` or `1`, which selects either one committed state of the system, or another.
The state of the system is either `copy 0` or `copy 1` of selectors.

## Naive reliable approach
We could implement a transaction by copying the whole committed bitmap, and the whole committed hash table; and then updating these copies. But this is too expensive. We would have each time to copy 4096 hash table pages + 512 pages of allocation bitmap. This is about 4.5MiB data. Too slow.

But the basic idea is correct: we should have **2 copies** of both the allocation bitmap and the hash table.
We just don’t want to rewrite them completely every time.

## Chunk / bucket selectors
But we never change all hash table buckets, and we never allocate or deallocate all data pages. If `maxPendingEntryCount` is something like `128`, we will update at max `128` hash table pages. This is much better than the full `4096` pages.

So, instead of having two complete independent copies of the allocation bitmap and hash table, let's say that for each allocation **bitmap chunk** and hash **table bucket** (both are just other names of file pages) we have two copies: committed copy and **shadow copy**.

When we write inside the `_WriteTransaction`, we only write into the shadow copies.

Now we need a mechanism to know for each bitmap chunk or table bucket, which one to read: **copy 0**, or **copy 1**? Which one is committed? This decision is per chunk / bucket, because they update at different moments.

So, we add another layer: **selectors**.
We have 2 selectors: **selector 0**, and **selector 1**.
The `_Header.selectorSlot` field decides which one is the committed state.

Each selector lives on its own file page.
The selector is two bitmaps: one for selecting allocation bitmap chunks, and one for selecting hash table buckets.

We have `2^9 = 512` chunks of the allocation bitmap. We need `2^9 / 2^3 = 2^6 = 64` bytes in the selector.

We have 4096 buckets of the hash table. We need `2^12 / 2^3 = 2^9 = 512` bytes.

These `64 + 512` bytes fit one `1024` byte file page.

## Writing
Inside `_WriteTransaction`, when we need to update the allocation bitmap chunk, or a hash table bucket, we check if we already have the updated copy of this page in this transaction. If yes, we update it, otherwise we read the committed version, update and put it into the set of **working pages** (or maybe call it dirty pages?).

At **commit** we go over `_workingAllocationBitmapChunks` and `_workingTablePages`, write them into shadow locations in the storage, and flip corresponding `_selectors` bits. The `_selectors` is initialized from the committed state in the constructor of the transaction.

Then we write the updated `_selectors` into the **shadow location**.

Then we flush all the written data to the storage, so that it is reliably in the file.
This data includes: data pages, hash table pages, selector page.

It is still OK for the process to crash, being killed, etc.
None of the committed data is affected.

And then we flip the `selectorSlot` bit in the header, write to the `0` page and flush.
This is an atomic operation, it either succeeds or fails.
This concludes the transaction.

But just in case, if writing 1024 bytes still somehow becomes a **torn write**, we have a checksum in the header too.

# Extras
Advanced details.

## Continuation data pages
See [statistics](https://share.jotbird.com/sunny-steady-mirage) from my machine.
Values often (estimate 30% for me) fit inline on the first value page, after the header.

But when they don’t fit, the header has the list of **continuation pages** - additional data only pages. These contain only value pieces, without any additional information like pointers to the next page, which allows bulk reading if multiple pages are continuous.

Depending on the length of the key in the value header, we can fit indices for `227` to `251` continuation pages: `(1024 - 16 - keyLength) ~/ 4`, for key lengths from `100` down to `1` byte. This supports up to approximately `251KiB` values. But this is not enough for some large values, e.g. summaries for large library cycles.

So, each `_ValueHeader` has optional `firstOverflowMetadataPageIndex`, which is the head of the linked list of serialized `_OverflowMetadata` objects, with additional data pages. Because this is a linked list, the length of the value that we can represent is limited only by the number of data pages.

## Full hash table bucket eviction
If we try to put a new entry into a hash table bucket, and there is no empty slot for it, we need to evict at least one entry. In practice we evict 16 at once, to amortize the cost. We select entries, read their value headers (but not the value itself), collect data pages, and put them into the `_WriteTransaction._pagesToFree`. We mark corresponding entries as empty. This leaves holes in the hash table bucket, temporarily violating the invariant. So, before the commit we rebuild the bucket - rehash survived entries into possible new slots, closer to their ideal locations. This all can be done inside a single bucket, greatly reducing the complexity and IO cost in comparison to a full open addressing table.

## CLOCK eviction
See "**clock eviction algorithm**" in our favorite search engine.

We have two of them.

Both use `_clockBits` - a bitmap with as many bits as the number of entries in the hash table.
So, `2^19 / 2^3 = 2^16 = 65536` bytes.
When the bit is `1`, the value was `put` or `get` recently.
When the bit is `0` and the clock hand reaches it, it will be evicted.

The first is `_Header.dataReclamationClockHand`. It goes through the **whole** hash table. Because it is stored in the header, it is committed with each transaction, so the sweep continues where it stopped after a restart, and across cooperating processes. When we need to allocate data pages to new values, and `_Header.freePageCount` says that we don’t have enough, we go over the hash table and evict entries that were not used recently. Each affected hash table bucket is rebuilt after eviction is done.

The second set is per hash table bucket clock hands. It is stored in `_bucketClockHands` and uses the same `_clockBits` to evict when the bucket is full, and we need to insert a new key. This is **full bucket eviction**.

**No tombstones**. When keys are evicted, we just rebuild this one bucket. Fast and simple.

## Support for multiple processes
Reading and writing is done with exclusive file locking.
While theoretically it is possible to have multiple readers at once, with shared file lock; and use exclusive file locking only for writing, I think this is a complication that is not necessary. We have only 1-2-3 processes at once.

## Commit ID
Each new `get(key)` starts with taking the file lock, reading the header, selectors, and then reading the value. We do this often, so reusing already read and cached inside `_BufferPool` pages is helpful. But there could be a write. To know if there was, we store `CommitID` into the header. If it is the same, we can use cached pages. Otherwise, we discard the cache, and read from the storage.
