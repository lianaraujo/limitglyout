local State = {
  ATTACHED = 0,
  PLAYING = 1,
  DEAD = 2,
}

local StateName = {
  [0] = 'Attached',
  [1] = 'Playing',
  [2] = 'Dead',
}

local make_rect = function(x, y, w, h)
  return {
    pos_x = x,
    pos_y = y,
    width = w,
    height = h
  }
end

local init_bar = function(game)
  game.bar_width = game.width / 15
  game.bar_height = game.height / 80
  game.bar_pos_y = game.height - (game.height / 10)
  game.bar_pos_x = game.width / 2 - game.bar_width / 2
  game.bar_speed = 4
  game.bar = {
    pos_x = game.bar_pos_x,
    pos_y = game.bar_pos_y,
    width = game.bar_width,
    height = game.bar_height,
    speed = game.bar_speed
  }
end

local init_ball = function(game)
  game.ball_size = game.height / 80
  game.ball_pos_x = game.bar_pos_x + game.bar_width / 2 - game.ball_size / 2
  game.ball_pos_y = game.bar_pos_y - game.bar_height - 1
  game.ball_speed = game.ball_size / 7
  game.ball_y_velocity = 0
  game.ball_x_velocity = 0
  game.ball = {
    pos_x = game.ball_pos_x,
    pos_y = game.ball_pos_y,
    width = game.ball_size,
    height = game.ball_size,
    speed = game.ball_speed,
    y_velocity = game.ball_y_velocity,
    x_velocity = game.ball_x_velocity
  }
end

local init_targets = function(std, game)
  game.targets = {}
  local cols = 11
  local rows = 20
  local col_padding_x = 10
  local row_padding_y = 10
  local target_heigth = 10
  local target_width = 100
  local grid_width = cols * target_width + (cols - 1) * col_padding_x
  local target_grid_x = game.width / 2 - grid_width / 2
  local target_grid_y = 50

  for col = 0, cols - 1 do
    for row = 0, rows - 1 do
      local pos_x = target_grid_x + (target_width + col_padding_x) * col
      local pos_y = target_grid_y + (target_heigth + row_padding_y) * row
      table.insert(game.targets, {
        pos_x = pos_x,
        pos_y = pos_y,
        width = target_width,
        height = target_heigth,
        dead = false,
        -- map colors
        color = row
      })
    end
  end
end

local function init(std, game)
  game.state = State.ATTACHED
  game.padding = game.height / 100
  game.grid_x = 80
  game.grid_y = 24
  init_bar(game)
  init_ball(game)
  init_targets(std, game)
end

local function sides(rect)
  return {
    left = rect.pos_x,
    right = rect.pos_x + rect.width,
    top = rect.pos_y,
    bottom = rect.pos_y + rect.height
  }
end

local function overlaps(rect1, rect2)
  local s1 = sides(rect1)
  local s2 = sides(rect2)

  return not (s1.right < s2.left or s2.right < s1.left or s1.bottom < s2.top or s2.bottom < s1.top)
end


local Collision = {
  NO = 0,
  BAR = 1,
  TOP = 2,
  LEFT = 3,
  RIGHT = 4,
  BOTTOM = 5,
  TARGET = 6,
}


local CollisionEffect = {
  [Collision.BOTTOM] = function(_, game)
    game.state = State.DEAD
    game.ball.x_velocity = 0
    game.ball.y_velocity = 0
  end,
  [Collision.BAR] = function(std, game)
    local hit_position = (game.ball.pos_x + game.ball.width / 2 - game.bar.pos_x) / game.bar.width
    local angle_factor = math.max(-1, math.min(1, (hit_position - 0.5) * 2))

    local max_angle = math.rad(60)
    local bounce_angle = angle_factor * max_angle

    game.ball.x_velocity = math.sin(bounce_angle) * game.ball.speed
    game.ball.y_velocity = -math.cos(bounce_angle) * game.ball.speed
  end,
}

local function target_collision(game, target_index)
  local target = game.targets[target_index]
  if target.dead then
    return
  end
  game.ball.speed = game.ball.speed + 0.06
  game.bar.speed = game.bar.speed + 0.01
  target.dead = true
end

local handle_collision = function(std, game, collision_type)
  if collision_type >= Collision.TARGET then
    target_collision(game, collision_type - Collision.TARGET)
  else
    local func = CollisionEffect[collision_type]
    if func then
      func(std, game)
    end
  end
end

local function vertical_collision(game)
  local next_y = game.ball.pos_y + game.ball.y_velocity
  if next_y < 0 then
    game.ball.y_velocity = -1 * game.ball.y_velocity
    return Collision.TOP
  end
  if overlaps(make_rect(game.ball.pos_x, next_y, game.ball.width, game.ball.height), game.bar) then
    game.ball.y_velocity = -1 * game.ball.y_velocity
    return Collision.BAR
  end
  if next_y + game.ball.height > game.height then
    game.ball.y_velocity = -1 * game.ball.y_velocity
    return Collision.BOTTOM
  end
  for i, target in pairs(game.targets) do
    if not target.dead and overlaps(make_rect(game.ball.pos_x, next_y, game.ball.width, game.ball.height), target) then
      game.ball.y_velocity = -1 * game.ball.y_velocity
      return Collision.TARGET + i
    end
  end
  game.ball.pos_y = next_y
  return Collision.NO
end

local function horizontal_collision(game)
  local next_x = game.ball.pos_x + game.ball.x_velocity
  if next_x + game.ball.width < 0 then
    game.ball.x_velocity = -1 * game.ball.x_velocity
    return Collision.LEFT
  end
  if next_x + game.ball.width > game.width then
    game.ball.x_velocity = -1 * game.ball.x_velocity
    return Collision.RIGHT
  end
  if overlaps(make_rect(next_x, game.ball.pos_y, game.ball.width, game.ball.height), game.bar) then
    game.ball.x_velocity = -1 * game.ball.x_velocity
    return Collision.BAR
  end
  for i, target in pairs(game.targets) do
    if not target.dead and overlaps(make_rect(next_x, game.ball.pos_y, game.ball.width, game.ball.height), target) then
      game.ball.x_velocity = -1 * game.ball.x_velocity
      return Collision.TARGET + i
    end
  end
  game.ball.pos_x = next_x
  return Collision.NO
end

local function start(std, game)
  game.state = State.PLAYING
  local launch_angle = 90

  if std.key.press.left then
    launch_angle = 120
  elseif std.key.press.right then
    launch_angle = 60
  end

  local angle_rad = math.rad(launch_angle)

  game.ball.y_velocity = -math.sin(angle_rad) * game.ball.speed
  game.ball.x_velocity = math.cos(angle_rad) * game.ball.speed
end

local StateHandler = {
  [State.ATTACHED] = function(std, game)
    game.ball.pos_x = game.bar.pos_x + game.bar.width / 2 - game.ball.width / 2
    if std.key.press.a then
      start(std, game)
    end
  end,
  [State.PLAYING] = function(std, game)
    handle_collision(std, game, horizontal_collision(game))
    handle_collision(std, game, vertical_collision(game))
  end,
  [State.DEAD] = function(std, game)
    if std.key.press.b then
      game.state = State.ATTACHED
      game.ball.pos_x = game.bar_pos_x + game.bar_width / 2 - game.ball_size / 2
      game.ball.pos_y = game.bar_pos_y - game.bar_height - 1
    end
  end
}

local function loop(std, game)
  game.bar.pos_x = std.math.clamp(game.bar.pos_x + (std.key.axis.x * game.bar.speed), game.padding,
    game.width - game.bar.width - game.padding)

  StateHandler[game.state](std, game)
end


local function draw_bar(std, game)
  std.draw.color(std.color.white)
  std.draw.rect(0, game.bar.pos_x, game.bar.pos_y, game.bar.width, game.bar.height)
end

local function draw_ball(std, game)
  if game.state ~= State.DEAD then
    std.draw.color(std.color.red)
    std.draw.rect(0, game.ball.pos_x, game.ball.pos_y, game.ball.width, game.ball.height)
  end
end

local function draw_message(std, game, message, color)
  local box_width = 195
  local box_height = 40
  std.draw.color(std.color.black)
  std.draw.rect(0, game.width / 2 - 90, game.height / 2 - 10, box_width, box_height)
  std.draw.color(color)
  std.text.put(game.grid_x / 2 - 3, game.grid_y / 2, message, 1)
end


local function draw_targets(std, game)
  local row_colors = {
    [0] = std.color.magenta,
    [1] = std.color.maroon,
    [2] = std.color.gold,
    [3] = std.color.darkblue,
    [4] = std.color.red,
    [5] = std.color.darkgreen,
    [6] = std.color.violet,
    [7] = std.color.orange,
    [8] = std.color.purple,
    [9] = std.color.skyblue,
  }
  for _, target in pairs(game.targets) do
    if target.dead then goto continue end
    std.draw.color(row_colors[target.color % 10])
    std.draw.rect(0, target.pos_x, target.pos_y, target.width, target.height)
    ::continue::
  end
end

local function draw(std, game)
  std.draw.clear(std.color.black)
  draw_bar(std, game)
  draw_ball(std, game)
  draw_targets(std, game)

  if game.state == State.DEAD then
    draw_message(std, game, 'Press B to restart', std.color.red)
  elseif game.state == State.ATTACHED then
    draw_message(std, game, 'Press A to launch', std.color.green)
  end
  std.draw.color(std.color.green)
  std.text.put(0, 0, StateName[game.state], 1)
  std.text.put(10, 0, game.ball.speed, 1)
  std.text.put(20, 0, game.ball.x_velocity, 1)
  std.text.put(40, 0, game.ball.y_velocity, 1)
  std.text.put(50, 0, game.ball.pos_y, 1)
end

local function exit(std, game)
end

local P = {
  meta = {
    title = 'Glyout',
    author = 'Lian',
    description = 'Breakout in Gly',
    version = '1.0.0'
  },
  callbacks = {
    init = init,
    loop = loop,
    draw = draw,
    exit = exit
  }
}

return P;
