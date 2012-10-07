# Somlos

(Sömlös, Swedish for Seamless)

Somlos is a tiny DSL and a convenince helper for describing Erlang/OTP application upgrades.
It is capable of generating instructions and appups from beam files, other modules and (soon) remote running nodes.

The primary task that Somlos targets to solve is that maintaining individual appups for 
every release is complicated. 

It ain't a magic tool that solves release upgrades. Upgrades are still a hard thing to develop and test, so Somlos only tries to remove some unnecessary obstacles to achieving zen of seamless upgrades.

All application's developer has to do is to write a 'migration' module:

```elixir
defmodule Example.Migration do
  use Somlos.Migration

  step "Add module AnotherModule", Somlos.Module.Add.new(module: AnotherModule)
  step "Update Example.Server", Somlos.Update.new(module: Example.Server)

end
```

Important note: once deployed, step names should not change and steps should not be reordered. If that happens, you're screwed.

## Status

Somlos is a quick experiment so far and only supports high-level appup instructions. It will soon get low level instructions support as well.

Not much documentation yet. Look into tests for some minimal examples.