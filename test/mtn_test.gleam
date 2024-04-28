import gleam/list
import gleeunit
import gleeunit/should
import types

pub fn main() {
  gleeunit.main()
}

pub fn primitive_test() {
  [
    types.primitive_satisfies(types.PrimitiveVoid, types.PrimitiveVoid),
    types.primitive_satisfies(types.PrimitiveBoolean, types.PrimitiveBoolean),
    types.primitive_satisfies(
      types.PrimitiveSignedInteger(32),
      types.PrimitiveSignedInteger(32),
    ),
    types.primitive_satisfies(
      types.PrimitiveUnsignedInteger(64),
      types.PrimitiveUnsignedInteger(64),
    ),
  ]
  |> list.each(should.be_true)

  [
    types.primitive_satisfies(types.PrimitiveVoid, types.PrimitiveBoolean),
    types.primitive_satisfies(types.PrimitiveBoolean, types.PrimitiveVoid),
    types.primitive_satisfies(
      types.PrimitiveSignedInteger(32),
      types.PrimitiveSignedInteger(64),
    ),
  ]
  |> list.each(should.be_false)
}

pub fn trait_test() {
  let white = types.Trait("White", [])
  let the_sun = types.Trait("TheSun", [white])
  let organism = types.Trait("Organism", [])
  let animal = types.Trait("Animal", [organism])
  let white_dog = types.Trait("WhiteDog", [animal, white])
  let human = types.Trait("Human", [animal])
  let white_dog_vs_the_sun =
    types.Trait("WhiteDogVsTheSun", [white_dog, the_sun])

  [
    // Identity
    types.trait_satisfies(white, white),
    types.trait_satisfies(the_sun, the_sun),
    types.trait_satisfies(white_dog, white_dog),
    types.trait_satisfies(human, human),
    types.trait_satisfies(white_dog_vs_the_sun, white_dog_vs_the_sun),
    // Directly extends
    types.trait_satisfies(white_dog, white),
    types.trait_satisfies(the_sun, white),
    types.trait_satisfies(white_dog, animal),
    types.trait_satisfies(human, animal),
    // Indirectly extends
    types.trait_satisfies(white_dog, organism),
    types.trait_satisfies(human, organism),
    // Diamond
    types.trait_satisfies(white_dog_vs_the_sun, white),
  ]
  |> list.each(should.be_true)

  [
    // Unrelated
    types.trait_satisfies(white, organism),
    types.trait_satisfies(organism, white),
    // Directly extended
    types.trait_satisfies(white, white_dog),
    types.trait_satisfies(white, the_sun),
    types.trait_satisfies(animal, white_dog),
    types.trait_satisfies(animal, human),
    // Indirectly extended
    types.trait_satisfies(organism, white_dog),
    types.trait_satisfies(organism, human),
    // Reverse diamond
    types.trait_satisfies(white, white_dog_vs_the_sun),
  ]
  |> list.each(should.be_false)
}

pub fn function_test() {
  let animal = types.Trait("Animal", [])
  let dog = types.Trait("Dog", [animal])

  let void = types.ValueTypePrimitive(types.PrimitiveVoid)
  let bool = types.ValueTypePrimitive(types.PrimitiveBoolean)
  let never = types.ValueTypeNever
  let i32 = types.ValueTypePrimitive(types.PrimitiveSignedInteger(32))
  let animal = types.ValueTypeTrait(animal)
  let dog = types.ValueTypeTrait(dog)

  let none_to_void = types.Function([], void)
  let bool_to_void = types.Function([types.FunctionArgument("arg", bool)], void)
  let none_to_throw = types.Function([], never)

  let add =
    types.Function(
      [types.FunctionArgument("a", i32), types.FunctionArgument("b", i32)],
      i32,
    )

  let dog_constructor = types.Function([], dog)
  let animal_constructor = types.Function([], animal)

  let dog_to_num = types.Function([types.FunctionArgument("dog", dog)], i32)
  let animal_to_num =
    types.Function([types.FunctionArgument("animal", animal)], i32)

  [
    // Identity
    types.function_satisfies(none_to_void, none_to_void),
    types.function_satisfies(none_to_throw, none_to_throw),
    types.function_satisfies(bool_to_void, bool_to_void),
    types.function_satisfies(add, add),
    types.function_satisfies(dog_to_num, dog_to_num),
    types.function_satisfies(animal_to_num, animal_to_num),
    types.function_satisfies(dog_constructor, dog_constructor),
    types.function_satisfies(animal_constructor, animal_constructor),
    // Covariant in return
    types.function_satisfies(dog_constructor, animal_constructor),
    types.function_satisfies(none_to_throw, none_to_void),
    types.function_satisfies(none_to_throw, dog_constructor),
    // Contravariant in arguments
    types.function_satisfies(animal_to_num, dog_to_num),
  ]
  |> list.each(should.be_true)

  [
    // Unrelated
    types.function_satisfies(bool_to_void, none_to_void),
    types.function_satisfies(bool_to_void, dog_constructor),
    types.function_satisfies(none_to_void, dog_constructor),
    types.function_satisfies(bool_to_void, none_to_void),
    // Lower arity
    types.function_satisfies(none_to_void, bool_to_void),
    // Contravariant in return
    types.function_satisfies(animal_constructor, dog_constructor),
    types.function_satisfies(none_to_void, none_to_throw),
    types.function_satisfies(dog_constructor, none_to_throw),
    // Covariant in arguments
    types.function_satisfies(dog_to_num, animal_to_num),
    // Return type erasure
    types.function_satisfies(dog_constructor, none_to_void),
  ]
  |> list.each(should.be_false)
}
