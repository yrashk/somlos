defrecord Somlos.Application.Add, name: nil, type: :permanent
defrecord Somlos.Application.Remove, name: nil, type: :permanent
defrecord Somlos.Application.Restart, name: nil

defimpl Somlos.Step, for: Somlos.Application.Add do
  def instruction(Somlos.Application.Add[name: name, type: type]) do
    {:add_application, name, type}
  end

  def reverse(Somlos.Application.Add[name: name, type: type]) do
    # The reason why we keep the application type
    # is so that if removal is reversed, the type is preserved
    Somlos.Application.Remove.new(name: name, type: type)
  end
end

defimpl Somlos.Step, for: Somlos.Application.Remove do
  def instruction(Somlos.Application.Remove[name: name]) do
    {:remove_application, name}
  end

  def reverse(Somlos.Application.Remove[name: name, type: type]) do
    Somlos.Application.Add.new(name: name, type: type)
  end
end

defimpl Somlos.Step, for: Somlos.Application.Restart do
  def instruction(Somlos.Application.Restart[name: name]) do
    {:restart_application, name}
  end

  def reverse(restart), do: restart
end