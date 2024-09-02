--- SPDX-License-Identifier: LGPL-2.1-only
--- see LICENSE file

local newproxy = newproxy
local getmetatable, setmetatable = getmetatable, setmetatable
local type = type
local rawget, rawset = rawget, rawset
local assert = assert

local isSupportedGc = not newproxy
local debug = (not isSupportedGc) and require 'debug'

local cachingIgnores = {
	new = true,
	final = true,
}

--- Origin of all objects.
------
--- The most recommended coding convention in our framework is to define only one class in one file.
--- Of course, it is not a must.
--- Here is the template file, copy and use it.
--[[
local Object = require 'Object'

---@class Class: Object
---@field mustneed  any
---@field optional? any
local Class = Object:new()

function Class:new (o)
	o = self:super(o)

	if not o:typeof(o) then
		assert(o.mustneed)
		o.optional = o.optional or 42
	end

	return o
end

return Class
--]]
---@class Object
---@field final? fun(self: self)
local Object = {}

local function cache (self, this, index)
	if not index then
		return this
	end

	if not rawget(this, index) then
		if not cachingIgnores[index] then
			return cache(self, rawset(this, index, rawget(self, index)), next(self, index))
		end
	end

	return cache(self, this, next(self, index))
end


--- To quickly access fields in the base class, copy them.
---@param this Object
function Object:cache (this)
	if this then
		cache(self, this, next(self, nil))
	end

	if getmetatable(self) then
		getmetatable(self):cache(this or self)
	end
end

---@return nil
local function propagateFinalization (self, base)
	if base then
		if rawget(base, 'final') then
			rawget(base, 'final')(self)
		end

		return propagateFinalization(self, getmetatable(base))
	end
end

--- Automatically invokes the finalizer defined in the inheritance chain.
--- ## function Object:final ()
--- self must be an `Object`
---
--- When the inheritance chain contains finalizers, there is considerable performance degradation when an instance is finalized. (or GC-ed.)
--- Therefore, careful consideration is important when defining finalizers.
---@private
---@param self Object | userdata
function Object:__gc ()
	self = (type(self) == 'userdata') and getmetatable(self) or self ---@cast self Object

	-- Finalizer only invokes on an instance.
	if not self:typeof(self) then
		return propagateFinalization(self, getmetatable(self))
	end
end

local function sealed (_, _) error("Attempt to instantiate a sealed object.") end

--- Called when there is no value in the hash table. If the type is cyclic, it can also cause an infinite recursive.
--- It is used internally, it shall not be redefined, so it is not documented.
---@private
---@param index any
---@return any
function Object:__index (index)
	if self then
		local value = rawget(self, index)
		if value then
			return value
		end

		return Object.__index(getmetatable(self), index)
	end
end

--- Front-end function that fires the constructor chain
--- Because defining a class using annotations is like writing the constructor's parameters, this method should not have any annotations. All information is included in the class definition.
function Object:new (o)
	o = self:super(o, true)

	if not o:typeof(o) then
		--- Your custom constructor here, this is example.
		_ = _
	end

	return o
end

local function cons (self, o, gc)
	if not o then
		o = {
			__gc = gc and Object.__gc,
			new = Object.new,
			__index = Object.__index,
		}
		return setmetatable(o, self)
	end

	return o
end

local function tails (self, o)
	if self then
		return rawget(self, 'new')(self, tails(getmetatable(self), o))
	end

	return o
end

local function inherit (self, o)
 	if self.final and not isSupportedGc then
 		o = rawset(rawset(o, debug.setmetatable(newproxy(false), o), not nil), '__gc', Object.__gc)
 	end

	return setmetatable(cons(self, o), self)
end


--- This method is used to define a constructor; therefore, it should not be called arbitrarily.
--- The correct way to call this method is to call directly from the newly defined constructor.
--- Invoking this method outside of the class's constructor definition is an undefined-behavior.
---
--- If the inheritance chain is too long and takes too long to initialize the object, you can try to 'Constructor chain reconstruction'.
--- Tips: To enable this feature, pass the `true` value to the second parameter of `super` method.
---
--- ***Note*** this feature allows you to use it under the condition that you know everything about all super types.
--- If there's anything you don't know at all, We recommend you not to use it because it's an unsafe feature.
---
--- The following code is an example using constructor chain reconstruction.
--[[
local Object = require 'Object'

---@class First: Object
---@field x number
local First = Object:new()

function First:new (o)
	o = self:super(o)

	if not o:typeof(o) then
		assert(o.x)
	end

	return o
end

---@class Second: First
---@field y number
local Second = First:new()

function Second:new (o)
	o = self:super(o)

	if not o:typeof(o) then
		assert(o.y)
	end

	return o
end

---@class Third: Second
---@field z number
local Third = Second:new()

function Third:new (o)
	o = self:super(o)

	-- You can do all the required initializations in `First` and `Second` in one place.
	if not o:typeof(o) then
		assert(o.x and o.y and o.z)
	end

	return o
end

local third = Third:new{x = 1, y = 2, z = 3,}
--]]
--- when using this feature, Dramatic performance improvements can be achieved with longer inheritance chains.
--- but it is more important not to create such a long inheritance chain in the first place.
---@protected
---@generic T: Object
---@param self T
---@param o any
---@param recons? boolean
---@return T
---@nodiscard
function Object:super (o, recons)
	-- If Datatype
	if not o then
		return setmetatable(cons(self, nil, true), self)
	-- If Instance
	elseif not getmetatable(o) then
		assert(rawget(self, 'new'), "Attempt to instantiate an instance.")

		o = inherit(self, o)

		if not recons then
			return tails(getmetatable(self), o)
		end
	end

	return o
end

--- Seal the instance.
------
--- so that it is no longer derived.
---@return self
---@nodiscard
function Object:sealed () return rawset(self, 'new', sealed) end

--- Find out which type the object belongs to.
------
--- It can be used as follows.
---* Examine which type inherits a particular type: SomeType:typeof(Object) -- is SomeType inherit Object?
---* Instance check: print(Type:typeof(Type), Instance:typeof(Instance)) -- it prints "true, false"
--- Distinguish which objects are datatypes(classes) or instances.
--- local Object = require 'Object'
---
--- local objA = Object:new() -- is datatype
--- local objB = Object:new{} -- is instance
---
--- local function printKind (t)
---     if t:typeof(t) then
---         print("datatype")
---     else
---         print("instance")
---     end
--- end
---
--- printKind(objA) -- "datatype"
--- printKind(objB) -- "instance"
---@param that any
---@return boolean | nil
function Object:typeof (that)
	that = that or self

	if self then
		if rawget(self, 'new') then
			if self == that and rawget(that, 'new') then
				return true
			else
				return self.typeof(getmetatable(self), that)
			end
		end

		return false
	end

	return nil
end

return Object
