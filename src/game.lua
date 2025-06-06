local State = {
  ATTACHED = 0,
  PLAYING = 1,
}

local function init(std, game)
  game.bar_width = game.width / 15
  game.bar_height = game.height / 80
  game.bar_pos_y = game.height - (game.height / 10)
  game.bar_pos_x = game.width / 2 - game.bar_width / 2
  game.bar = {
    pos_x = game.bar_pos_x,
    pos_y = game.bar_pos_y,
    width = game.bar_width,
    height = game.bar_height
  }

  game.ball_size = game.height / 80
  game.ball_pos_x = game.bar_pos_x + game.bar_width / 2 - game.ball_size / 2
  game.ball_pos_y = game.bar_pos_y - game.bar_height
  game.ball_state = State.ATTACHED
  game.ball_speed = game.ball_size / 10
  game.ball_y_velocity = 0
  game.ball_x_velocity = 0
  game.ball = {
    pos_x = game.ball_pos_x,
    pos_y = game.ball_pos_y,
    width = game.ball_size,
    height = game.ball_size,
    state = game.ball_state,
    speed = game.ball_speed,
    y_velocity = game.ball_y_velocity,
    x_velocity = game.ball_x_velocity
  }

  game.padding = game.height / 100
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

local make_rect = function(x, y, w, h)
  return {
    pos_x = x,
    pos_y = y,
    width = w,
    height = h
  }
end

local Collision = {
  NO = 0,
  BAR = 1,
  TOP = 2,
  LEFT = 3,
  RIGHT = 4,
}

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
  -- TODO bottom
  -- TODO targets
  game.ball.pos_y = next_y
  return Collision.NO
end

local function horizontal_collision(game)
  local next_x = game.ball.pos_x + game.ball.x_velocity
  if next_x < 0 then
    game.ball.x_velocity = -1 * game.ball.x_velocity
    return Collision.LEFT
  end
  if next_x > game.width then
    game.ball.x_velocity = -1 * game.ball.x_velocity
    return Collision.RIGHT
  end
  if overlaps(make_rect(next_x, game.ball.pos_y, game.ball.width, game.ball.height), game.bar) then
    game.ball.x_velocity = -1 * game.ball.x_velocity
    return Collision.BAR
  end
  -- TODO targets
  game.ball.pos_x = next_x
  return Collision.NO
end



local handle_collision = function(game)
  vertical_collision(game)
  horizontal_collision(game)
end

local function start(std, game)
  if std.key.press.left then
    game.ball.x_velocity = -game.ball.speed
  elseif std.key.press.right then
    game.ball.x_velocity = game.ball.speed
  end

  game.ball.state = State.PLAYING
  game.ball.y_velocity = -game.ball.speed
end

-- angle factor
local function loop(std, game)
  game.bar.pos_x = std.math.clamp(game.bar.pos_x + (std.key.axis.x * 4), game.padding,
    game.width - game.bar.width - game.padding)

  if game.ball.state == State.ATTACHED then
    game.ball.pos_x = game.bar.pos_x + game.bar.width / 2 - game.ball.width / 2
    if std.key.press.a then
      start(std, game)
    end
  else
    handle_collision(game)
  end
end

local function draw_bar(std, game)
  std.draw.color(std.color.white)
  std.draw.rect(0, game.bar.pos_x, game.bar.pos_y, game.bar.width, game.bar.height)
end

local function draw_ball(std, game)
  std.draw.color(std.color.red)
  std.draw.rect(0, game.ball.pos_x, game.ball.pos_y, game.ball.width, game.ball.height)
end

local Name = {
  [0] = 'Attached',
  [1] = 'Playing',
}

local function draw(std, game)
  std.draw.clear(std.color.black)
  draw_bar(std, game)
  draw_ball(std, game)

  std.draw.color(std.color.green)
  std.text.put(0, 0, Name[game.ball.state], 1)
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
