import gleam/int
import gleam/list
import gleam/string

//
// General

pub type UniqueId =
  String

//
// Primitive

pub type Primitive {
  PrimitiveVoid
  PrimitiveBoolean
  PrimitiveSignedInteger(Int)
  PrimitiveUnsignedInteger(Int)
}

pub fn primitive_satisfies(s: Primitive, o: Primitive) -> Bool {
  s == o
}

pub fn primitive_debug(s: Primitive) -> String {
  case s {
    PrimitiveVoid -> "void"
    PrimitiveBoolean -> "bool"
    PrimitiveSignedInteger(bits) -> "i" <> int.to_string(bits)
    PrimitiveUnsignedInteger(bits) -> "u" <> int.to_string(bits)
  }
}

//
// Function

pub type FunctionArgument {
  FunctionArgument(name: String, typ: ValueType)
}

pub fn function_argument_satisfies(
  s: FunctionArgument,
  o: FunctionArgument,
) -> Bool {
  case s, o {
    FunctionArgument(_, contravariant_s), FunctionArgument(_, contravariant_o) ->
      value_type_satisfies(contravariant_o, contravariant_s)
  }
}

pub fn function_argument_debug(s: FunctionArgument) -> String {
  case s {
    FunctionArgument(name, typ) -> name <> ": " <> value_type_debug(typ)
  }
}

pub type Function {
  Function(arguments: List(FunctionArgument), return: ValueType)
}

pub fn function_satisfies(s: Function, o: Function) -> Bool {
  case s, o {
    Function(args_s, ret_s), Function(args_o, ret_o) ->
      value_type_satisfies(ret_s, ret_o)
      // don't allow arity mismatch
      && list.length(args_s) == list.length(args_o)
      && list.zip(args_s, args_o)
      |> list.all(fn(p) { function_argument_satisfies(p.0, p.1) })
  }
}

pub fn function_debug(s: Function) -> String {
  case s {
    Function(args, ret) ->
      "fn("
      <> args
      |> list.map(function_argument_debug)
      |> string.join(", ")
      <> "): "
      <> value_type_debug(ret)
  }
}

//
// Trait

pub type Trait {
  Trait(id: UniqueId, extends: List(Trait))
}

pub fn trait_debug(s: Trait) -> String {
  case s {
    Trait(id, extends) ->
      "trait "
      <> id
      <> case extends {
        [] -> ""
        _ ->
          " extends "
          <> extends
          |> list.map(fn(s) { s.id })
          |> string.join(", ")
      }
  }
}

pub fn trait_satisfies(subject: Trait, other: Trait) -> Bool {
  subject == other
  || subject.extends
  |> list.contains(other)
  || subject.extends
  |> list.any(trait_satisfies(_, other))
}

//
// Struct

pub type StructField {
  StructField(name: String, typ: ValueType)
}

pub fn struct_field_debug(s: StructField) -> String {
  case s {
    StructField(name, typ) -> name <> ": " <> value_type_debug(typ)
  }
}

pub type Struct {
  StructNamed(id: UniqueId, fields: List(StructField))
  StructTuple(id: UniqueId, data: List(ValueType))
}

pub fn struct_satisfies(subject: Struct, other: Struct) -> Bool {
  subject == other
}

pub fn struct_debug(s: Struct) -> String {
  case s {
    StructNamed(id, fields) ->
      "struct "
      <> id
      <> " {"
      <> fields
      |> list.map(struct_field_debug)
      |> list.map(fn(s) { " " <> s })
      |> string.join(";")
      <> " }"

    StructTuple(id, data) ->
      "struct "
      <> id
      <> "("
      <> data
      |> list.map(value_type_debug)
      |> string.join(", ")
      <> ")"
  }
}

//
// Enum

pub type EnumVariant {
  EnumVariantUnit(name: String)
  EnumVariantPayload(name: String, struct: Struct)
}

pub fn enum_variant_debug(s: EnumVariant) -> String {
  case s {
    EnumVariantUnit(name) -> name
    EnumVariantPayload(name, struct) ->
      case struct {
        StructNamed(_, fields) ->
          name
          <> " {"
          <> fields
          |> list.map(struct_field_debug)
          |> list.map(fn(s) { " " <> s })
          |> string.join(";")
          <> " }"
        StructTuple(_, data) ->
          name
          <> "("
          <> data
          |> list.map(value_type_debug)
          |> string.join(", ")
          <> ")"
      }
  }
}

pub type Enum {
  Enum(id: UniqueId, variants: List(EnumVariant))
}

pub fn enum_satisfies(subject: Enum, other: Enum) -> Bool {
  subject == other
}

pub fn enum_debug(s: Enum) {
  case s {
    Enum(id, variants) ->
      "enum "
      <> id
      <> " {"
      <> variants
      |> list.map(enum_variant_debug)
      |> list.map(fn(s) { " " <> s })
      |> string.join(";")
      <> " }"
  }
}

//
// Type

pub type ValueType {
  ValueTypeNever
  ValueTypePrimitive(Primitive)
  ValueTypeFunction(Function)
  ValueTypeTrait(Trait)
  ValueTypeStruct(Struct)
  ValueTypeEnum(Enum)
}

fn value_type_debug(s: ValueType) -> String {
  case s {
    ValueTypeNever -> "never"
    ValueTypePrimitive(p) -> primitive_debug(p)
    ValueTypeTrait(t) -> trait_debug(t)
    ValueTypeFunction(f) -> function_debug(f)
    ValueTypeStruct(s) -> struct_debug(s)
    ValueTypeEnum(e) -> enum_debug(e)
  }
}

pub fn value_type_satisfies(subject: ValueType, other: ValueType) -> Bool {
  case subject, other {
    _, _ if subject == other -> True

    ValueTypeNever, _ -> True

    ValueTypePrimitive(s), ValueTypePrimitive(t) -> primitive_satisfies(s, t)
    ValueTypeFunction(s), ValueTypeFunction(t) -> function_satisfies(s, t)
    ValueTypeTrait(s), ValueTypeTrait(t) -> trait_satisfies(s, t)
    ValueTypeStruct(s), ValueTypeStruct(t) -> struct_satisfies(s, t)
    ValueTypeEnum(s), ValueTypeEnum(t) -> enum_satisfies(s, t)

    _, _ -> False
  }
}
