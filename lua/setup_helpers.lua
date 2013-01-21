-- generic setup of lua helpers
helper = wesnoth.require "lua/helper.lua"
W = helper.set_wml_action_metatable {}

V = {}
helper.set_wml_var_metatable(V)
wesnoth.dofile "~add-ons/Sandbox/lua/sandbox_helpers.lua"
wesnoth.dofile "~add-ons/Sandbox/lua/pickle.lua"
_ = helper.textdomain "sandbox"

-- S will be used to store variables in that can be
-- directly accessed from translatable strings, e.g.
-- S.foo = "bar"
-- str = _ "a {foo}"
S = {}

wesnoth.dofile "~add-ons/Sandbox/lua/time.lua"