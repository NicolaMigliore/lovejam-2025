
-- Load libraries
Camera = require 'libs.hump.camera'
GameState = require 'libs.hump.gamestate'
Timer = require 'libs.hump.timer'
Vector = require 'libs.hump.vector'
Object = require 'libs.classic'
Husl = require 'libs.husl'
Inspect = require 'libs.inspect'
Lume = require 'libs.lume'
Gamera = require 'libs.gamera'
BF = require 'libs.breezefield-master'
Flux = require 'libs.flux'
Json = require 'libs.json'
Anim8 = require 'libs.anim8'
Utils = require 'libs.utils'
ECSWorld = require 'src.ECSWorld'

-- Initialize LUIS
local initLuis = require "luis.init"
-- Direct this to your widgets folder.
Luis = initLuis("luis/widgets")
-- register flux in luis, some widgets need it for animations
Luis.flux = require("luis.3rdparty.flux")

-- Register game states
GAME_STATES = {
    title = require 'src.scenes.title',
    dungeonPlanner = require 'src.scenes.dungeonPlanner',
    level1 = require 'src.scenes.level-1'
}

GAME_SETTINGS = {
    playMusic = true
}