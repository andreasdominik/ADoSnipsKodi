# ADoSnipsKodi

Snips.AI kill to control a kodi/libreelec device.

This is a skill for the SnipsHermesQnD framework to control an kodi/libreelec device.

Language is German but the app-code is written using the multi-language tools of the framework (with English already implemented) and can be adapted (within some minutes) to any language by adding the "sentences" and intents to the database in a new language.

Please see the documentation of the framework for details:
[QnD Documentation](https://andreasdominik.github.io/ADoSnipsQnD/dev)

# Julia

This skill is (like the entire SnipsHermesQnD framework) written in the
modern programming language Julia (because Julia is faster
then Python and coding is much much easier and much more straight forward).
However "Pythonians" often need some time to get familiar with Julia.

If you are ready for the step forward, start here: https://julialang.org/


# Skill
## Actions
The skill includes intents (in German) to
- power-on/power-off a libreelec device via a GPIO-controlled switch
  or run kodi on the local machine
- play a movie (from the Kodi movie library)
- play a tv-show (from the Kodi tv-show library)
- play a recording (from a directory with recordings)
- play a slide show (from a directory with pictuers).

### Power-on/off

is implemented using the ON/OFF-intent of the framework.

### Play video

There is one intent for playing videos. The title is extracted form the command and
used as query for the tv-show database, the recordings and the movies (in
this order).
If an unseen video is found, it is played.

### Play recording

If the `config.ini` includes an entry `recordings=` pointing to a valid
directory (see section config.ini for details), the video files in the
directory are parsed to extract a movie or tv-show name and season/episode numbers.

### Play slide show

If the `config.ini` includes an entry `pictures=` pointing to a valid
directory (see section config.ini for details), the directory
is parsed for slide shows.

Each slide show must be located in a separate directory following the following
conventions:
- directory name has the form `2016-holyday-Hawaii-long-Oahu` and
  consists of a minus-separated (`-`) list of items
- first item is the year
- all other items will be interpreted as keywords
- whitespace in keywords is replaced by `_` (such as `2007-birthday-party-my_dad`)
- the combination of year and keywords must be unique.

The app will extract year and keywords from the command and try to find the
matching slide show (for the example above the command
`"Please show me the long slide show of our holyday on Hawaii in 2016"` should work).


## Configuration `config.ini`

The following entries are read from the `config.ini`:

##### language=de
Default language is `de`. English is already implemented in the action code;
however English intents are missing.
New languages can be implemneted by just adding the necessary phrases
to the language database. To implement, add all translations to the
file `languages.jl` and make a merge request in the Githup project (or
just send me the translations and I will include them).

In addition the intents `ADoSnipsPlayPictures` and `ADoSnipsPlayVideo` must be
translated into the target language.

##### ip=kodi.home.me
IP-address or DNS name of the device running kodi. Make sure that
in Kodi the web-server and remote control via IP are activated.

##### port=8080
Port for the kodi/jsonrpc interface as configured in Kodi.

##### tv=maintv
ID of the tv as configured in the tv skill. Currently only Panasonic
Viera is supported. A system trigger is used to control the tv set with the
respective skill.

However, if libreelec is installed on a RPi and connected to a tv via HDMI,
normally the tv will power up and down (triggered via HDMI/CEC) without the need
of controlling it from Snips. Therefore the skill might work with any tv set.

##### on_mode=gpio
This line is necessary even though only power on via GPIO is implemented yet.

##### gpio=21
Number of the GPIO to switch on or off the Kodi device.


##### recordings=/storage/recordings/
Directory with the recordings. If no recordings are wanted, this entry
must be deleted.
The path to the directory can be any valid path specification for Kodi; i.e.
- a local absolute path: `/storage/recordings/`
- a file share: `smb://nas.home.me/recordings/`

##### pictures=/storage/pictures
Directory with the slide shows.
See `recordings` for path details.
