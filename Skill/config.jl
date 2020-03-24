# DO NOT CHANGE THE FOLLOWING LINES UNLESS YOU KNOW
# WHAT YOU ARE DOING!
# set CONTINUE_WO_HOTWORD to true to be able to chain
# commands without need of a hotword in between:
#
const CONTINUE_WO_HOTWORD = false
const DEVELOPER_NAME = "andreasdominik"
Snips.setDeveloperName(DEVELOPER_NAME)
Snips.setModule(@__MODULE__)
#
# language settings:
# Snips.LANG in QnD(Snips) is defined from susi.toml or set
# to "en" if no susi.toml found.
# This will override LANG by config.ini if a key "language"
# is defined locally:
#
if Snips.isConfigValid(:language)
    Snips.setLanguage(Snips.getConfig(:language))
end
# or LANG can be set manually here:
# Snips.setLanguage("fr")
#
# set a local const with LANG:
#
const LANG = Snips.getLanguage()
#
# END OF DO-NOT-CHANGE.


# Slots:
# Name of slots to be extracted from intents:
#
const SLOT_ROOM = "room"
const SLOT_DEVICE = "device"
const SLOT_ON_OFF = "on_or_off"

const SLOT_MOVIENAME = "movieName"

# picture keywords:
#
const SLOT_YEAR = "year"
const SLOT_KEYWORDS = "keyword"
const SLOT_KEYWORDS2 = "keyword2"
const SLOT_SIZE = "size"
const SLOT_EVENT = "event"
const SLOT_SEASON = "season"

# name of entry in config.ini:
#
const INI_IP = "ip"
const INI_PORT = "port"
const INI_TV = "tv"
const INI_ON_MODE = "on_mode"  # one of "gpio" or "none" or "local"
const INI_GPIO = "gpio"
const INI_SHARE = "recordings"
const INI_PICTURES = "pictures"
const INI_WAIT = "boot_wait"


#
# link between actions and intents:
# intent is linked to action{Funktion}
# the action is only matched, if
#   * intentname matches and
#   * if the siteId matches, if site is  defined in config.ini
#     (such as: "switch TV in room abc").
#
Snips.registerIntentAction("ADoSnipsOnOff", switchOnOffActions)
Snips.registerIntentAction("playVideo", playVideoAction)
Snips.registerIntentAction("playPictures", playSlideshowAction)
