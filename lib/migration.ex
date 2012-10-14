defmodule Somlos.Migration do
  
  defmacro __using__(_) do
    quote do
      import Somlos.Migration
      Module.register_attribute __MODULE__, :step
      Module.register_attribute __MODULE__, :always

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
        always_steps = lc {:always, [v]} inlist target_attrs, do: v        
        # Figure out which way to go
        cond do
          length(origin_steps) > length(target_steps) -> downgrade(origin_steps, target_steps, always_steps)        
          length(origin_steps) < length(target_steps) -> upgrade(origin_steps, target_steps, always_steps)          
          (origin_steps -- target_steps) == [] -> :up_to_date
          true -> {:mismatch, origin_steps -- target_steps}
        end
      end

      defp upgrade(origin, target, always) do
        steps = target -- origin
        always = lc {_name, {_, forward}, {_, reverse}} inlist always, do: {forward, reverse}
        if Enum.empty?(always) do
          always_forward = []
          always_reverse = []
        else 
          [always_forward, always_reverse] = List.unzip always
        end
        if (length(steps) == length(target) - length(origin)) do
          sort_steps(lc {_name, {_, forward}, {_, reverse}} inlist steps do
            {forward, reverse}
          end, always_forward, always_reverse)
        else
          {:mismatch, steps}
        end
      end

      defp downgrade(origin, target, always) do
        steps = Enum.reverse(origin -- target)
        always = lc {_name, {_, forward}, {_, reverse}} inlist always, do: {forward, reverse}
        if Enum.empty?(always) do
          always_forward = []
          always_reverse = []
        else 
          [always_forward, always_reverse] = List.unzip always
        end
        if (length(steps) == length(origin) - length(target)) do          
          sort_steps(lc {_name, {_, forward}, {_, reverse}} inlist steps do
            {reverse, forward}
          end, always_forward, always_reverse)
        else
          {:mismatch, steps}
        end
      end

      defp sort_steps(steps, always_forward, always_reverse) do
        [upgrade: (lc {step, _} inlist steps, do: step) ++ always_forward,
         downgrade: Enum.reverse(always_reverse) ++ (lc {_, step} inlist steps, do: step),
        ]
      end
    end
  end

  defmacro step(name, forward, opts // []), do: __step__(:step, name, forward,opts)
  defmacro always(name, forward, opts // []), do: __step__(:always, name, forward,opts)

  defp __step__(type, name, forward, opts) do
    name = binary_to_atom(to_binary(name))
    reverse = opts[:reverse] || quote do: Somlos.Step.reverse(unquote(forward))

    quote do
      Module.put_attribute __MODULE__, unquote(type),
             {unquote(name), 
             {unquote(forward), Somlos.Step.instruction(unquote(forward))},
             {unquote(reverse), Somlos.Step.instruction(unquote(reverse))}}
    end
  end
end