-------------------------------------------------------------
-- Mana Support Library                                    --
--                                                         --
-- Functions which are called by the game engine and       --
-- helper functions useful for writing other scripts.      --
--                                                         --
----------------------------------------------------------------------------------
--  Copyright 2008 The Mana World Development Team                              --
--                                                                              --
--  This file is part of The Mana Server.                                       --
--                                                                              --
--  The Mana Server is free software; you can redistribute  it and/or modify it --
--  under the terms of the GNU General  Public License as published by the Free --
--  Software Foundation; either version 2 of the License, or any later version. --
----------------------------------------------------------------------------------

require "scripts/lua/libmana-constants"

-- A table that provides access to persistent variables of the current map
map = setmetatable({}, {
    __index = function(_, key)
        return getvar_map(key)
    end,
    __newindex = function(_, key, value)
        setvar_map(key, value)
    end,
})

-- A table that provides access to persistent global world variables
world = setmetatable({}, {
    __index = function(_, key)
        return getvar_world(key)
    end,
    __newindex = function(_, key, value)
        setvar_world(key, value)
    end,
})

-- Some convenient shortcuts for the different log levels
function ERROR(...) log(LOG_ERROR, table.concat({...}, " ")) end
function WARN(...)  log(LOG_WARN,  table.concat({...}, " ")) end
function INFO(...)  log(LOG_INFO,  table.concat({...}, " ")) end
function DEBUG(...) log(LOG_DEBUG, table.concat({...}, " ")) end

-- Array containing the function registered by atinit.
local init_fun = {}

-- Set of scheduled jobs. The key is the mapid or 0 for no map.
-- The value is an array with 3 elements:
-- 0: the UNIX timestamp when it is executed
-- 1: the function which is executed
-- 2: nil when it is a one-time job. Repetition interval is seconds when it is
--    a repeated job.
local scheduler_jobs = {}

-- checks for jobs which have to be executed, executes them and reschedules
-- them when they are repeated jobs.
local function check_schedule(mapid)
  local current_time = os.time()
  local jobs

  jobs = scheduler_jobs[mapid or 0]

  if not jobs then return end

  while #jobs ~= 0 and current_time >= jobs[#jobs][0] do
    -- retreive the job and remove it from the schedule
    local job = jobs[#jobs]
    table.remove(jobs)
    -- reschedule the job when it is a repeated job
    if job[2] then
        schedule_every(job[2], job[1])
    end
    -- execute the job
    job[1]()
  end
end

-- Registered as the function to call every tick.
local function update()
    check_schedule()
end

-- Registered as function to call every map tick.
-- Checks for scheduled function calls
local function mapupdate(mapid)
    check_schedule(mapid)
end

-- Registers a function so that it is executed during map initialization.
function atinit(f)
  local map_id = get_map_id()
  init_fun[map_id] = init_fun[map_id] or {}
  table.insert(init_fun[map_id], f)
end

-- Called by the game for creating NPCs embedded into maps.
-- Delays the creation until map initialization is performed.
-- Note: Assumes that the "npc_handler" global field contains the NPC handler.
local function create_npc_delayed(name, id, gender, x, y)
  -- Bind the name to a local variable first, as it will be reused.
  local h = npc_handler
  atinit(function() npc_create(name, id, gender, x, y, h) end)
  npc_handler = nil
end

-- Called during map initialization, for each map.
-- Executes all the functions registered by atinit.
local function map_initialize()
  local functions = init_fun[get_map_id()]
  if not functions then return end
  for i,f in ipairs(functions) do
    f()
  end
  init_fun[get_map_id()] = nil
end


-- SCHEDULER

-- compare function used to sort the scheduler_jobs table.
-- the jobs which come first are at the end of the table.
local function job_cmp(job1, job2)
  return (job1[0] > job2[0])
end

-- schedules a function call to be executed once in n seconds
function schedule_in(seconds, funct)
  local job = {}
  job[0] = os.time() + seconds
  job[1] = funct
  job[2] = nil
  local map_id = get_map_id() or 0 -- if no map context
  scheduler_jobs[map_id] = scheduler_jobs[map_id] or {}
  table.insert(scheduler_jobs[map_id], job)
  table.sort(scheduler_jobs[map_id], job_cmp)
end

-- schedules a function call to be executed at regular intervals of n seconds
function schedule_every(seconds, funct)
  local job = {}
  job[0] = os.time() + seconds
  job[1] = funct
  job[2] = seconds
  local map_id = get_map_id() or 0 -- if no map context
  scheduler_jobs[map_id] = scheduler_jobs[map_id] or {}
  table.insert(scheduler_jobs[map_id], job)
  table.sort(scheduler_jobs[map_id], job_cmp)
end

-- schedules a function call to be executed at a given date
function schedule_per_date(my_year, my_month, my_day, my_hour, my_minute, funct)
  local job = {}
  job[0] = os.time{year = my_year, month = my_month, day = my_day,
                   hour = my_hour, min = my_minute}
  job[1] = funct
  job[2] = nil
  local map_id = get_map_id() or 0 -- if no map context
  scheduler_jobs[map_id] = scheduler_jobs[map_id] or {}
  table.insert(scheduler_jobs[map_id], job)
  table.sort(scheduler_jobs[map_id], job_cmp)
end

-- MAP/WORLD VARIABLES NOTIFICATIONS
local onmapvar_functs = {}
local onworldvar_functs = {}

local function on_mapvar_callback(key, value)
  local functs = onmapvar_functs[key]
  local mapid = get_map_id()
  for func, map in pairs(functs) do
    if map == mapid then
      func(key, value)
    end
  end
end

local function on_worldvar_callback(key, value)
  local functs = onworldvar_functs[key]
  for func, _ in pairs(functs) do
    func(key, value)
  end
end

function on_mapvar_changed(key, funct)
  if not onmapvar_functs[key] then
    onmapvar_functs[key] = {}
    on_mapvar_changed(key, on_mapvar_callback)
  end
  onmapvar_functs[key][funct] = get_map_id()
end

function on_worldvar_changed(key, funct)
  if not onworldvar_functs[key] then
    onworldvar_functs[key] = {}
    on_worldvar_changed(key, on_worldvar_callback)
  end
  onworldvar_functs[key][funct] = true
end

function remove_mapvar_listener(key, funct)
  onmapvar_functs[key][funct] = nil
end

function remove_worldvar_listener(key, funct)
  onworldvar_functs[key][funct] = nil
end

-- DEATH NOTIFICATIONS
local ondeath_functs = {}
local onremove_functs = {}

-- requests the gameserver to notify the script engine when the being
-- dies and adds a script function to be executed in this case.
function on_death(being, funct)
  if ondeath_functs[being] == nil then
    ondeath_functs[being] = {}
  end
  table.insert(ondeath_functs[being], funct)
  being_register(being)
end

-- requests the gameserver to notify the script engine when the being
-- dies and adds a script function to be executed in this case.
function on_remove(being, funct)
  if onremove_functs[being] == nil then
    onremove_functs[being] = {}
  end
  table.insert(onremove_functs[being], funct)
  being_register(being)
end

-- Registered as callback for when a registered being dies.
local function death_notification(being)
  if type(ondeath_functs[being]) == "table" then
    for i,funct in pairs(ondeath_functs[being]) do
      funct()
    end
    ondeath_functs[being] = nil
  end
end

-- Registered as callback for when a registered being is removed.
local function remove_notification(being)
  if type(onremove_functs[being]) == "table" then
    for i,funct in pairs(onremove_functs[being]) do
      funct()
    end
    onremove_functs[being] = nil
    ondeath_functs[being] = nil
  end
end


-- Below are some convenience methods added to the engine API
chr_money_change = function(ch, amount)
  being_set_base_attribute(
                            ch,
                            ATTR_GP,
                            being_get_base_attribute(ch, ATTR_GP) + amount)
end

chr_money = function(ch)
  return being_get_base_attribute(ch, ATTR_GP)
end

-- Register callbacks
on_update(update)
on_mapupdate(mapupdate)

on_create_npc_delayed(create_npc_delayed)
on_map_initialize(map_initialize)

on_being_death(death_notification)
on_being_remove(remove_notification)
