# frozen_string_literal: true

# Defines a named use case for one test and removes it — constant and registration —
# afterwards. `Class.new(base)` fires `inherited` before the constant is named, so the
# registration the kernel does for `class Foo < Rita::Command` is done here by hand.
module TemporaryUseCases
  def define_use_case(name, base, &body)
    *modules, last = name.split("::")
    parent = modules.inject(Object) do |mod, const|
      mod.const_defined?(const, false) ? mod.const_get(const) : mod.const_set(const, Module.new)
    end
    klass = Class.new(base)
    parent.const_set(last, klass)
    Rita.registry.register(klass)
    klass.class_eval(&body) if body
    (@temporary_use_cases ||= []) << [ parent, last, klass ]
    klass
  end

  def teardown
    super
    (@temporary_use_cases || []).reverse_each do |parent, last, klass|
      Rita.registry.unregister(klass)
      parent.send(:remove_const, last)
    end
  end
end
