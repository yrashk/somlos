defmodule Somlos.Migration do
  
  defmacro __using__(_) do
    quote do
      import Somlos.Migration
      Module.register_attribute __MODULE__, :step

      def appup(origin_vsn, target_vsn, instructions) do
        {to_char_list(target_vsn), 
          [{to_char_list(origin_vsn), instructions[:upgrade]}],
          [{to_char_list(origin_vsn), instructions[:downgrade]}]
        }
      end

      def instructions_from_file(file) when is_binary(file) do
        {:ok,{_,[{:attributes, attrs}]}} = :beam_lib.chunks(binary_to_atom(file), [:attributes])
        instructions(attrs)
      end

      def instructions_from_module(module) when is_atom(module) do        
        instructions(module.__info__(:attributes))
      end

      def instructions_from_remote(node, 
                                   module // __MODULE__) when is_atom(node) 
                                                         and is_atom(module) do

        instructions(:rpc.call(node, module, :__info__, [:attributes]))
      end                                                         

      def instructions, do: instructions([])
      def instructions(origin_attrs) do              
        target_attrs = __info__(:attributes)
        # Remove attributes of no interest
        origin_steps = lc {:step, [v]} inlist origin_attrs, do: v
        target_steps = lc {:step, [v]} inlist target_attrs, do: v
        # Figure out which way to go
        cond do
          length(origin_steps) > length(target_steps) -> downgrade(origin_steps, target_steps)        
          length(origin_steps) < length(target_steps) -> upgrade(origin_steps, target_steps)          
          (origin_steps -- target_steps) == [] -> :up_to_date
          true -> {:mismatch, origin_steps -- target_steps}
        end
      end

      defp upgrade(origin, target) do
        steps = target -- origin
        if (length(steps) == length(target) - length(origin)) do
          sort_steps(lc {_name, {_, forward}, {_, reverse}} inlist steps do
            {forward, reverse}
          end)
        else
          {:mismatch, steps}
        end
      end

      defp downgrade(origin, target) do
        steps = Enum.reverse(origin -- target)
        if (length(steps) == length(origin) - length(target)) do          
          sort_steps(lc {_name, {_, forward}, {_, reverse}} inlist steps do
            {reverse, forward}
          end)
        else
          {:mismatch, steps}
        end
      end

      defp sort_steps(steps) do
        [upgrade: (lc {step, _} inlist steps, do: step),
         downgrade: (lc {_, step} inlist steps, do: step),
        ]
      end
    end
  end

  defmacro step(name, forward, opts // []) do
    name = binary_to_atom(to_binary(name))
    reverse = opts[:reverse] || quote do: Somlos.Step.reverse(unquote(forward))

    quote do
      @step {unquote(name), 
             {unquote(forward), Somlos.Step.instruction(unquote(forward))},
             {unquote(reverse), Somlos.Step.instruction(unquote(reverse))}}
    end
  end
end