defrecord Somlos.Update, module: nil, supervisor: false,
                                module_type: :dynamic,
                                change: :soft, pre_purge: :brutal_purge,
                                post_purge: :brutal_purge,
                                depends_on: [],
                                timeout: :default

defimpl Somlos.Step, for: Somlos.Update do
  def instruction(Somlos.Update[module: module, supervisor: true]) do
    {:update, module, :supervisor}
  end
  def instruction(Somlos.Update[module: module,
                                       module_type: module_type,
                                       change: change,
                                       pre_purge: pre_purge,
                                       post_purge: post_purge,
                                       depends_on: depends_on,
                                       timeout: timeout]) do
    {:update, module, module_type, timeout, change, pre_purge, post_purge, depends_on}
  end

  def reverse(update), do: update
end