#
# API function goes here, to be called by the
# skill-actions:
#
const CURL = "/$(Snips.getAppDir())/Skill/kodi.sh"
const TEMPLATES = "$(Snips.getAppDir())/Skill/Templates"
const JSON = "kodiresult.json"

function kodiOn(mode; wait = true)

    if mode == "gpio"
        kodiGPIOOn()
        wait && wait4kodi()
    elseif mode == "local"
        kodiLaunch()
        wait && wait4kodi()
    else
        Snips.publishSay(:error_on_mode)
    end
end

function kodiOff(mode)

    if mode == "gpio"
        kodiGPIOOff()

    elseif mode == "local"
        kodiExit()
    end
end


"""
wait until kodi is up
"""
function wait4kodi()

    waitMax = 30
    while (! kodiIsOn(mode= :tryApiCall)) && (waitMax > 0)
        sleep(1)
        waitMax -= 1
    end

    if waitMax < 1
        return false
    else
        if Snips.isConfigValid(INI_WAIT, regex = r"^[0-9]+$") &&
            (st = Base.tryparse(Int, Snips.getConfig(INI_WAIT))) != nothing
            sleep(st)
        else
            sleep(20)
        end
    end
    return true
end


"""
Switch on kodi if it runs on a separate device.
"""
function kodiGPIOOn()

    # do nothing, if already on:
    #
    if kodiIsOn()
        Snips.printDebug("Kodi is already on")
        return true
    end

    # kodi powers TV up and grabs the hdmi/AV input:
    #
    Snips.setGPIO(Snips.getConfig(INI_GPIO), :on)
    wait4kodi()
    tvTVAV()
    return true
end


function kodiLaunch()

    tvSusi()
    sleep(2)
    if !kodiIsOn( mode = :tryApiCall)
        kodiCmd("launch", errorMsg = :error_kodicmd)
    end
    return true
end



function kodiGPIOOff()

    if kodiIsOn()
        kodiCmd("shutdown")
        sleep(2)
    end
    Snips.setGPIO(Snips.getConfig(INI_GPIO), :off)

    tvOff()
 end


function kodiExit()

    if kodiIsOn( mode = :tryApiCall)
        kodiCmd("exit")
    end

    tvOff()
end



function tvTVAV()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["TV", "wait1", "AV", "return"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end

function tvOn()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["susi", "wait20", "TV"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end

function tvSusi()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["susi"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end

function tvOff()

    trigger = Dict(:room => Snips.getSiteId(),
                   :device => Snips.getConfig(INI_TV),
                   :commands => ["TV", "standby"],
                   :delay => 0.5
                   )

    Snips.publishSystemTrigger("ADoSnipsTVViera", trigger)
end


#
# KODI commands:
#
#
"""
    kodiIsOn()

Return true if kodi result has OK printed in the first line
"""
function kodiIsOn(;mode = :ping)

    if mode == :ping
        return Snips.ping(Snips.getConfig(INI_IP))
    else
        if kodiCmd("getVolume", errorMsg = "")
            return checkKodiStatus()
        else
            return false
        end
    end
end


"""
try to ge a Dict() from KODI.
    item is one of:
    :tvshows, :movies, :recordings, :pictures, :episodes
"""
function kodiGetList(item::Symbol; arg = nothing)

    # find kodi.sh command:
    #
    if item == :tvshows
        cmd = "getTVshows"
    elseif item == :movies
        cmd = "getMovies"
    elseif item == :recordings
        cmd = "getRecordings"
        item = :files
    elseif item == :pictures
        cmd = "getPictureFiles"
        item = :files
    elseif item == :episodes
        cmd = "getEpisodes"
    end

    # try every sec, max 10 times:
    #
    i = 30
    success = false
    items = []
    while !success && i > 0
        if arg == nothing
            success = kodiCmd(cmd)
        else
            success = kodiCmd(cmd, arg)
        end
        i -= 1
        sleep(1)
    end
    if success
        items = parseKodiResult(item)
    end
    return items
end



function kodiGetTVshows()

    return kodiGetList(:tvshows)
end

function kodiGetMovies()

    return kodiGetList(:movies)
end


""""
    kodiGetRrecordings()

recieve a Dict with recordings  with fields:
:type: :movie/:episode:/:unknown,
:path, :name, :episode, :season
"""
function kodiGetRrecordings(share)

    otrs = getKodiOTRFiles(share)
    if length(otrs) > 0
        otrs = parseOTRname.(otrs)
    else
        otrs = []
    end

    return otrs
end


"""
    kodiGetEpisodes(tvShow)

Return a Dict() with episodes of a tv show from KODI.
* keys are Symbols
* if error, an empty Dict() is returned
"""
function kodiGetEpisodes(tvShow)

    return kodiGetList(:episodes, arg = tvShow[:tvshowid])
end

"""
getKodiOTRFiles(share)

Return a Dict() with files
and fields: :file (=path), :label (=filename)
* if error, an empty Dict() is returned
"""
function getKodiOTRFiles(path)

    return kodiGetList(:recordings, arg = path)
end


"""
Return the directory of "path" as list of Dicts.
Each dict has the fields:
* file - path/name
* filetype - e.g. directory
* label - file name
* type
"""
function kodiGetPictureFiles(path)

    return kodiGetList(:pictures, arg = path)
end


function kodiPlayEpisode(episode)

    kodiCmd("playEpisode", episode[:episodeid])
end

function kodiPlayFile(recording)

    kodiCmd("playRec", recording[:file])
end

function kodiPlayMovie(movie)

    kodiCmd("playMovie", movie[:movieid])
end


function kodiPlayPictures(slideShow)

    kodiCmd("playPictures", slideShow[:file])
end

function kodiWindowPictures(path)

    kodiCmd("openPictureWindow", path)
end
#


#
# low-level:
#
#
"""
    kodiCmd(cmd, args...)

Send a Command to Kodi (with optional args).
"""
function kodiCmd(cmd, args...; errorMsg = :error_kodicmd)

    ip = Snips.getConfig(INI_IP)
    port = Snips.getConfig(INI_PORT)

    curl = `$CURL $ip $port $TEMPLATES $cmd $args`
    Snips.printDebug("KODI command: $curl")

    if !Snips.tryrun(curl, errorMsg = errorMsg)
        return false
    else
        return checkKodiStatus()
    end
end



"""
check, if the call to kodi.sh was successful
by reading the file kodi.status
"""
function checkKodiStatus()

    return occursin("OK", strip(read(`head -1 kodi.status`, String)))
end


#
# Basic KODI helper functions:
#
#

"""
    parseKodiResult(field)

Return a Dict() with media of type from KODI.
* field is a Symbol
* media is one of :movies, :tvshows, :episodes, :episodedetails
* keys are Symbols
* if error, an empty Dict() is returned
"""
function parseKodiResult(field)

    media = Dict()
    raw = Snips.tryParseJSONfile(JSON)

    if haskey(raw, :result) &&
           raw[:result] isa Dict &&
               haskey(raw[:result], field)

        media = raw[:result][field]
    end
    return media
end


function upperOccursin(needle, haystack)

    return occursin(uppercase(needle), uppercase(haystack))
end

"""
    parseOTRnames(otr)

Extract movie name, and episode from OTR filename
and adds the fields :type (:movie, :episode, :unknown),
:title, :season, :episode
to the dict.

## Arguments:
* rec : Dict with filename in field :label
"""
function parseOTRname(otr)

    # make clean filename:
    otr[:filename] = replace(otr[:file], r"^.*/"is => "")
    # test if tv show:
    m = match(r"(^.*)_S([0-9]{2})E([0-9]{2})_([0-9]{2}\.[0-9]{2}\.[0-9]{2})_[0-9]{2}-[0-9]{2}_.*"is,
              otr[:filename])
    if m != nothing
        otr[:title] = replace(m.captures[1], "_"=>" ")
        otr[:season] = m.captures[2]
        otr[:episode] = m.captures[3]
        otr[:date] = m.captures[4]
        otr[:type] = :episode
    end
    if m == nothing
        m = match(r"(^.*)_([0-9]{2}\.[0-9]{2}\.[0-9]{2})_[0-9]{2}-[0-9]{2}_.*"is,
                 otr[:filename])
        if m != nothing
            otr[:title] = replace(m.captures[1], "_"=>" ")
            otr[:date] = m.captures[2]
            otr[:season] = "00"
            otr[:episode] = "00"
            otr[:type] = :movie
        end
    end
    if m == nothing
        otr[:title] = replace(otr[:filename], "_"=>" ")
        otr[:season] = "00"
        otr[:episode] = "00"
        otr[:date] = "00.00.00"
        otr[:type] = :unknown
    end

    return otr
end
