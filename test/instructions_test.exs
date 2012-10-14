Code.require_file "../test_helper.exs", __FILE__

defmodule M1 do
  use Somlos.Migration

  step "Add module :crypto", Somlos.Module.Load.new(module: :crypto)
end

defmodule M2 do
  use Somlos.Migration

  step "Add module :crypto", Somlos.Module.Load.new(module: :crypto)
  step "Remove module :crypto", Somlos.Module.Delete.new(module: :crypto)

end

defmodule M3 do
  use Somlos.Migration

  step "Add module :crypto", Somlos.Module.Load.new(module: :crypto)
  step "Remove module :crypto", Somlos.Module.Delete.new(module: :crypto)

  always "Load module Somlos", Somlos.Module.Load.new(module: Somlos)
  always "Load module Somlos.Step", Somlos.Module.Load.new(module: Somlos.Step)

end

defmodule Somlos.Test.Instructions do
  use ExUnit.Case

  test "up to date" do
    assert M2.instructions_from_module(M2) == :up_to_date
  end

  test "upgrade" do
    instructions =  M2.instructions_from_module(M1)
    assert instructions[:upgrade] == [Somlos.Step.instruction(Somlos.Module.Delete.new(module: :crypto))]
    assert instructions[:downgrade] == [Somlos.Step.instruction(Somlos.Step.reverse(Somlos.Module.Delete.new(module: :crypto)))]
  end

  test "downgrade" do
    instructions =  M1.instructions_from_module(M2)
    assert instructions[:downgrade] == [Somlos.Step.instruction(Somlos.Module.Delete.new(module: :crypto))]
    assert instructions[:upgrade] == [Somlos.Step.instruction(Somlos.Step.reverse(Somlos.Module.Delete.new(module: :crypto)))]
  end

  test "always instruction" do
    instructions =  M3.instructions_from_module(M1)
    assert instructions[:upgrade] == 
           [Somlos.Step.instruction(Somlos.Module.Delete.new(module: :crypto)),
            Somlos.Step.instruction(Somlos.Module.Load.new(module: Somlos)),
            Somlos.Step.instruction(Somlos.Module.Load.new(module: Somlos.Step))]

    assert instructions[:downgrade] == 
           [
            Somlos.Step.instruction(Somlos.Step.reverse(Somlos.Module.Load.new(module: Somlos.Step))),           
            Somlos.Step.instruction(Somlos.Step.reverse(Somlos.Module.Load.new(module: Somlos))),
            Somlos.Step.instruction(Somlos.Step.reverse(Somlos.Module.Delete.new(module: :crypto)))
           ]
  end
  
end
