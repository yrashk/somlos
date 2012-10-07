defrecord Somlos.Module.Load, module: nil, depends_on: [], pre_purge: :brutal_purge,
                              post_purge: :brutal_purge

defimpl Somlos.Step, for: Somlos.Module.Load do
  def instruction(Somlos.Module.Load[module: module,
                                       pre_purge: pre_purge,
                                       post_purge: post_purge,
                                       depends_on: depends_on]) do
    {:load_module, module, pre_purge, post_purge, depends_on}
  end

  def reverse(update), do: update
end

defrecord Somlos.Module.Add, module: nil
defrecord Somlos.Module.Delete, module: nil

defimpl Somlos.Step, for: Somlos.Module.Add do
  def instruction(Somlos.Module.Add[module: module]) do
    {:add_module, module}
  end

  def reverse(Somlos.Module.Add[module: module]), do: Somlos.Module.Delete.new(module: module)
end

defimpl Somlos.Step, for: Somlos.Module.Delete do
  def instruction(Somlos.Module.Delete[module: module]) do
    {:delete_module, module}
  end

  def reverse(Somlos.Module.Delete[module: module]), do: Somlos.Module.Add.new(module: module)
end