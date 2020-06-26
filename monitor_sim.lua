local monitor_refresh_rate = 60
local vsync = false

local function round(v)
  return math.floor(v + 0.5)
end

-- //these are functions so you can add randomness to them if you want to simulate "a slow frame every now and then" and stuff
local function game_update_time()
  return .00001
end

local function game_render_time()
  return .005
end

local function game_display_time()
  return .000001
end

local function busy_time()
  return .000001
end

-- System time at 0 helps find rounding issues when the system timer is "in sync" with the game timer
-- randomizing it is "more accurate"
math.randomseed(os.time())

local system_time = 0 -- randrange(rng) * 10000

local timing_fuzziness = 1 / 60 * .005
local function fuzzy()
  return (math.random() * timing_fuzziness * 2) - timing_fuzziness
end

-- Measurements
local frame_updates = 0
local total_updates = 0
local last_vsync = 0
local missed_updates = 0
local double_updates = 0

local function simulate_update()
  system_time = system_time + math.max(0.0, game_update_time() + fuzzy() * .01)
  total_updates = total_updates + 1
  frame_updates = frame_updates + 1
end

local function simulate_render()
  system_time = system_time + math.max(0.0, game_render_time() + fuzzy() * .01)
end

local function simulate_display()
  if vsync then
    system_time = system_time + math.max(
      0.0,
      (math.ceil(system_time * monitor_refresh_rate) / monitor_refresh_rate) - system_time + fuzzy()
    )
  else
    system_time = system_time + math.max(0.0, game_display_time() + fuzzy())
  end


  local current_vsync = round(system_time * monitor_refresh_rate)
  if last_vsync ~= current_vsync then
    local i = last_vsync
    while i < current_vsync - 1 do
      i = i + 1
      io.write(0)
      missed_updates = missed_updates + 1
    end
    io.write(frame_updates)
    if frame_updates > 1 then
      double_updates = double_updates + 1
    end
    last_vsync = current_vsync

    frame_updates = 0
  end
end

local function simulate_busy()
  system_time = system_time + math.max(0.0, busy_time() + fuzzy() * .00001)
end

-- this is where you test your game loop
local prev_frame_time = system_time
last_vsync = round(system_time * monitor_refresh_rate)
local first_vsync = last_vsync

local accumulator = 0

while total_updates < 10000 do
  local current_frame_time = system_time
  local delta_frame_time = current_frame_time - prev_frame_time
  accumulator = accumulator + delta_frame_time
  prev_frame_time = current_frame_time

  while accumulator >= 1 / 60 do
    simulate_update()
    accumulator = accumulator - (1 / 60)
  end

  simulate_render()
  simulate_display()
  simulate_busy()
end

print('\n')
print("        TOTAL UPDATES: " .. total_updates)
print("         TOTAL VSYNCS: " .. last_vsync - first_vsync)
print(" TOTAL DOUBLE UPDATES: " .. double_updates)
print("TOTAL SKIPPED RENDERS: " .. missed_updates)
print("  GAME TIME: " .. total_updates * 1 / 60)
print("SYSTEM TIME: " .. (last_vsync - first_vsync) / monitor_refresh_rate)
