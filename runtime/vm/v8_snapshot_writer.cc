// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/v8_snapshot_writer.h"

#include "vm/dart.h"
#include "vm/os.h"

namespace dart {

const V8SnapshotProfileWriter::ObjectId
    V8SnapshotProfileWriter::kArtificialRootId{IdSpace::kArtificial, 0};

#if defined(DART_PRECOMPILER)

V8SnapshotProfileWriter::V8SnapshotProfileWriter(Zone* zone)
    : zone_(zone),
      nodes_(zone_),
      node_types_(zone_),
      edge_types_(zone_),
      strings_(zone_),
      roots_(zone_) {
  intptr_t idx = edge_types_.Add("context");
  ASSERT_EQUAL(idx, static_cast<intptr_t>(Edge::Type::kContext));
  idx = edge_types_.Add("element");
  ASSERT_EQUAL(idx, static_cast<intptr_t>(Edge::Type::kElement));
  idx = edge_types_.Add("property");
  ASSERT_EQUAL(idx, static_cast<intptr_t>(Edge::Type::kProperty));
  idx = edge_types_.Add("internal");
  ASSERT_EQUAL(idx, static_cast<intptr_t>(Edge::Type::kInternal));

  SetObjectTypeAndName(kArtificialRootId, "ArtificialRoot",
                       "<artificial root>");
}

void V8SnapshotProfileWriter::SetObjectTypeAndName(const ObjectId& object_id,
                                                   const char* type,
                                                   const char* name) {
  ASSERT(type != nullptr);
  NodeInfo* info = EnsureId(object_id);
  const intptr_t type_index = node_types_.Add(type);
  if (info->type != kInvalidString && info->type != type_index) {
    FATAL("Attempting to assign mismatching type %s to node %s", type,
          info->ToCString(this, zone_));
  }
  info->type = type_index;
  // Don't overwrite any existing name.
  if (info->name == kInvalidString) {
    info->name = strings_.Add(name);
  }
}

void V8SnapshotProfileWriter::AttributeBytesTo(const ObjectId& object_id,
                                               size_t num_bytes) {
  EnsureId(object_id)->self_size += num_bytes;
}

void V8SnapshotProfileWriter::AttributeReferenceTo(
    const ObjectId& from_object_id,
    const Reference& reference,
    const ObjectId& to_object_id) {
  ASSERT(reference.IsElement() ? reference.offset >= 0
                               : reference.name != nullptr);
  EnsureId(to_object_id);
  const Edge edge(this, reference);
  EnsureId(from_object_id)->AddEdge(edge, to_object_id);
}

void V8SnapshotProfileWriter::AttributeDroppedReferenceTo(
    const ObjectId& from_object_id,
    const Reference& reference,
    const ObjectId& to_object_id,
    const ObjectId& replacement_object_id) {
  ASSERT(to_object_id.IsArtificial());
  ASSERT(!replacement_object_id.IsArtificial());
  ASSERT(reference.IsElement() ? reference.offset >= 0
                               : reference.name != nullptr);

  // The target node is added normally.
  AttributeReferenceTo(from_object_id, reference, to_object_id);

  EnsureId(replacement_object_id);
  // Put the replacement node at an invalid offset or name that can still be
  // associated with the real one. For offsets, this is the negative offset.
  // For names, it's the name prefixed with ":replacement_".
  Reference replacement_reference =
      reference.IsElement() ? Reference::Element(-reference.offset)
                            : Reference::Property(OS::SCreate(
                                  zone_, ":replacement_%s", reference.name));
  const Edge replacement_edge(this, replacement_reference);
  EnsureId(from_object_id)->AddEdge(replacement_edge, replacement_object_id);
}

bool V8SnapshotProfileWriter::HasId(const ObjectId& object_id) {
  return nodes_.HasKey(object_id);
}

V8SnapshotProfileWriter::NodeInfo* V8SnapshotProfileWriter::EnsureId(
    const ObjectId& object_id) {
  if (!HasId(object_id)) {
    nodes_.Insert(NodeInfo(this, object_id));
  }
  return nodes_.Lookup(object_id);
}

const char* V8SnapshotProfileWriter::NodeInfo::ToCString(
    V8SnapshotProfileWriter* profile_writer,
    Zone* zone) const {
  JSONWriter writer;
  WriteDebug(profile_writer, &writer);
  return OS::SCreate(zone, "%s", writer.buffer()->buffer());
}

void V8SnapshotProfileWriter::NodeInfo::Write(
    V8SnapshotProfileWriter* profile_writer,
    JSONWriter* writer) const {
  ASSERT(id.space() != IdSpace::kInvalid);
  if (type == kInvalidString) {
    FATAL("No type given for node %s", id.ToCString(profile_writer->zone_));
  }
  writer->PrintValue(type);
  if (name != kInvalidString) {
    writer->PrintValue(name);
  } else {
    ASSERT(profile_writer != nullptr);
    // If we don't already have a name for the node, we lazily create a default
    // one. This is safe since the strings table is written out after the nodes.
    const intptr_t name = profile_writer->strings_.AddFormatted(
        "Unnamed [%s] (nil)", profile_writer->node_types_.At(type));
    writer->PrintValue(name);
  }
  id.Write(writer);
  writer->PrintValue(self_size);
  writer->PrintValue64(edges->Length());
}

void V8SnapshotProfileWriter::NodeInfo::WriteDebug(
    V8SnapshotProfileWriter* profile_writer,
    JSONWriter* writer) const {
  writer->OpenObject();
  if (type != kInvalidString) {
    writer->PrintProperty("type", profile_writer->node_types_.At(type));
  }
  if (name != kInvalidString) {
    writer->PrintProperty("name", profile_writer->strings_.At(name));
  }
  id.WriteDebug(writer, "id");
  writer->PrintProperty("self_size", self_size);
  edges->WriteDebug(profile_writer, writer, "edges");
  writer->CloseObject();
}

const char* V8SnapshotProfileWriter::ObjectId::ToCString(Zone* zone) const {
  JSONWriter writer;
  WriteDebug(&writer);
  return OS::SCreate(zone, "%s", writer.buffer()->buffer());
}

void V8SnapshotProfileWriter::ObjectId::Write(JSONWriter* writer,
                                              const char* property) const {
  if (property != nullptr) {
    writer->PrintProperty64(property, encoded_);
  } else {
    writer->PrintValue64(encoded_);
  }
}

void V8SnapshotProfileWriter::ObjectId::WriteDebug(JSONWriter* writer,
                                                   const char* property) const {
  writer->OpenObject(property);
  writer->PrintProperty("space", IdSpaceToCString(space()));
  writer->PrintProperty64("nonce", nonce());
  writer->CloseObject();
}

const char* V8SnapshotProfileWriter::ObjectId::IdSpaceToCString(IdSpace space) {
  switch (space) {
    case IdSpace::kInvalid:
      return "Invalid";
    case IdSpace::kSnapshot:
      return "Snapshot";
    case IdSpace::kVmText:
      return "VmText";
    case IdSpace::kIsolateText:
      return "IsolateText";
    case IdSpace::kVmData:
      return "VmData";
    case IdSpace::kIsolateData:
      return "IsolateData";
    case IdSpace::kArtificial:
      return "Artificial";
    default:
      UNREACHABLE();
  }
}

const char* V8SnapshotProfileWriter::EdgeMap::ToCString(
    V8SnapshotProfileWriter* profile_writer,
    Zone* zone) const {
  JSONWriter writer;
  WriteDebug(profile_writer, &writer);
  return OS::SCreate(zone, "%s", writer.buffer()->buffer());
}

void V8SnapshotProfileWriter::EdgeMap::WriteDebug(
    V8SnapshotProfileWriter* profile_writer,
    JSONWriter* writer,
    const char* property) const {
  writer->OpenArray(property);
  auto edge_it = GetIterator();
  while (auto const pair = edge_it.Next()) {
    pair->edge.WriteDebug(profile_writer, writer, pair->target);
  }
  writer->CloseArray();
}

void V8SnapshotProfileWriter::Edge::Write(
    V8SnapshotProfileWriter* profile_writer,
    JSONWriter* writer,
    const ObjectId& target_id) const {
  ASSERT(type != Type::kInvalid);
  writer->PrintValue64(static_cast<intptr_t>(type));
  writer->PrintValue64(name_or_offset);
  auto const target = profile_writer->nodes_.LookupValue(target_id);
  writer->PrintValue64(target.offset());
}

void V8SnapshotProfileWriter::Edge::WriteDebug(
    V8SnapshotProfileWriter* profile_writer,
    JSONWriter* writer,
    const ObjectId& target_id) const {
  writer->OpenObject();
  if (type != Type::kInvalid) {
    writer->PrintProperty(
        "type", profile_writer->edge_types_.At(static_cast<intptr_t>(type)));
  }
  if (type == Type::kProperty) {
    writer->PrintProperty("name", profile_writer->strings_.At(name_or_offset));
  } else {
    writer->PrintProperty64("offset", name_or_offset);
  }
  auto const target = profile_writer->nodes_.LookupValue(target_id);
  target.id.WriteDebug(writer, "target");
  writer->CloseObject();
}

void V8SnapshotProfileWriter::AddRoot(const ObjectId& object_id,
                                      const char* name) {
  // HeapSnapshotWorker.HeapSnapshot.calculateDistances (from HeapSnapshot.js)
  // assumes that the root does not have more than one edge to any other node
  // (most likely an oversight).
  if (roots_.HasKey(object_id)) return;
  roots_.Insert(object_id);

  auto const str_index = strings_.Add(name);
  auto const root = nodes_.Lookup(kArtificialRootId);
  ASSERT(root != nullptr);
  root->AddEdge(str_index != kInvalidString
                    ? Edge(this, Edge::Type::kProperty, str_index)
                    : Edge(this, Edge::Type::kInternal, root->edges->Length()),
                object_id);
}

intptr_t V8SnapshotProfileWriter::StringsTable::Add(const char* str) {
  if (str == nullptr) return kInvalidString;
  if (auto const kv = index_map_.Lookup(str)) {
    return kv->value;
  }
  const char* new_str = OS::SCreate(zone_, "%s", str);
  const intptr_t index = strings_.length();
  strings_.Add(new_str);
  index_map_.Insert({new_str, index});
  return index;
}

intptr_t V8SnapshotProfileWriter::StringsTable::AddFormatted(const char* fmt,
                                                             ...) {
  va_list args;
  va_start(args, fmt);
  const char* str = OS::VSCreate(zone_, fmt, args);
  va_end(args);
  if (auto const kv = index_map_.Lookup(str)) {
    return kv->value;
  }
  const intptr_t index = strings_.length();
  strings_.Add(str);
  index_map_.Insert({str, index});
  return index;
}

const char* V8SnapshotProfileWriter::StringsTable::At(intptr_t index) const {
  if (index > strings_.length()) return nullptr;
  return strings_[index];
}

void V8SnapshotProfileWriter::StringsTable::Write(JSONWriter* writer,
                                                  const char* property) const {
  writer->OpenArray(property);
  for (auto const str : strings_) {
    writer->PrintValue(str);
    writer->PrintNewline();
  }
  writer->CloseArray();
}

void V8SnapshotProfileWriter::Write(JSONWriter* writer) {
  writer->OpenObject();

  writer->OpenObject("snapshot");
  {
    writer->OpenObject("meta");

    {
      writer->OpenArray("node_fields");
      writer->PrintValue("type");
      writer->PrintValue("name");
      writer->PrintValue("id");
      writer->PrintValue("self_size");
      writer->PrintValue("edge_count");
      writer->CloseArray();
    }

    {
      writer->OpenArray("node_types");
      node_types_.Write(writer);
      writer->CloseArray();
    }

    {
      writer->OpenArray("edge_fields");
      writer->PrintValue("type");
      writer->PrintValue("name_or_index");
      writer->PrintValue("to_node");
      writer->CloseArray();
    }

    {
      writer->OpenArray("edge_types");
      edge_types_.Write(writer);
      writer->CloseArray();
    }

    writer->CloseObject();

    writer->PrintProperty64("node_count", nodes_.Size());
    {
      intptr_t edge_count = 0;
      auto nodes_it = nodes_.GetIterator();
      while (auto const info = nodes_it.Next()) {
        // All nodes should have an edge map, though it may be empty.
        ASSERT(info->edges != nullptr);
        edge_count += info->edges->Length();
      }
      writer->PrintProperty64("edge_count", edge_count);
    }
  }
  writer->CloseObject();

  {
    writer->OpenArray("nodes");
    //  Always write the information for the artificial root first.
    auto const root = nodes_.Lookup(kArtificialRootId);
    ASSERT(root != nullptr);
    intptr_t offset = 0;
    root->set_offset(offset);
    root->Write(this, writer);
    offset += kNumNodeFields;
    auto nodes_it = nodes_.GetIterator();
    for (auto entry = nodes_it.Next(); entry != nullptr;
         entry = nodes_it.Next()) {
      if (entry->id == kArtificialRootId) continue;
      entry->set_offset(offset);
      entry->Write(this, writer);
      offset += kNumNodeFields;
    }
    writer->CloseArray();
  }

  {
    auto write_edges = [&](const NodeInfo& info) {
      auto edges_it = info.edges->GetIterator();
      while (auto const pair = edges_it.Next()) {
        pair->edge.Write(this, writer, pair->target);
      }
    };
    writer->OpenArray("edges");
    //  Always write the information for the artificial root first.
    auto const root = nodes_.Lookup(kArtificialRootId);
    ASSERT(root != nullptr);
    write_edges(*root);
    auto nodes_it = nodes_.GetIterator();
    while (auto const entry = nodes_it.Next()) {
      if (entry->id == kArtificialRootId) continue;
      write_edges(*entry);
    }
    writer->CloseArray();
  }

  // Must happen after any calls to WriteNodeInfo, as those calls may add more
  // strings.
  strings_.Write(writer, "strings");

  writer->CloseObject();
}

void V8SnapshotProfileWriter::Write(const char* filename) {
  JSONWriter json;
  Write(&json);

  auto file_open = Dart::file_open_callback();
  auto file_write = Dart::file_write_callback();
  auto file_close = Dart::file_close_callback();
  if ((file_open == nullptr) || (file_write == nullptr) ||
      (file_close == nullptr)) {
    OS::PrintErr("warning: Could not access file callbacks.");
    return;
  }

  auto file = file_open(filename, /*write=*/true);
  if (file == nullptr) {
    OS::PrintErr("warning: Failed to write snapshot profile: %s\n", filename);
  } else {
    char* output = nullptr;
    intptr_t output_length = 0;
    json.Steal(&output, &output_length);
    file_write(output, output_length, file);
    free(output);
    file_close(file);
  }
}

#endif

}  // namespace dart
