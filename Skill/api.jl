#
# API function goes here, to be called by the
# skill-actions:
#
const CURL = "/$(Snips.getAppDir())/Skill/kodi.sh"
const TEMPLATES = "$(Snips.getAppDir())/Skill/Templates"
const JSON = "kodiresult.json"

function kodiOn()

    # tvOn()
    # sleep(1)

    # kodi powers TV up and grabs the hdmi/AV input:
    #
    Snips.setGPIO(Snips.getConfig(INI_GPIO), :on)
    sleep(20)
    tvTVAV()
end


function kodiOff()

     kodiCmd("shutdown")
     sleep(10)
     Snips.setGPIO(Snips.getConfig(INI_GPIO), :off)

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
function kodiIsOn()

    if kodiCmd("getVolume", errorMsg = "")
        return strip(read(`head -1 kodi.status`, String)) == "OK"
    else
        return false
    end
end


function kodiGetTVshows()

    tvShows = []
    if kodiCmd("getTVshows")
        tvShows = parseKodiResult(:tvshows)
    end
    return tvShows
end

function kodiGetMovies()

    movies = []
    if kodiCmd("getMovies")
        movies = parseKodiResult(:movies)
    end
    return movies
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

    episodes = Dict()
    if kodiCmd("getEpisodes", tvShow[:tvshowid])
        episodes = parseKodiResult(:episodes)
    end
    return episodes
end


function kodiPlayEpisode(episode)

    kodiCmd("playEpisode", episode[:episodeid])
end

function kodiPlayFile(recording)

    kodiCmd("playListClear")
    kodiCmd("playListAddFile", recording[:file])
    kodiCmd("playListPlay")
end

function kodiPlayMovie(movie)

    kodiCmd("playListClear")
    kodiCmd("playListAdd", movie[:movieid])
    kodiCmd("playListPlay")
end


#


#
# low-level:
#
#
"""
    runKodiCmd(cmd, args...)

Send a Command to Kodi (with optional args).
"""
function kodiCmd(cmd, args...; errorMsg = :error_kodicmd)

    ip = Snips.getConfig(INI_IP)
    port = Snips.getConfig(INI_PORT)

    curl = `$CURL $ip $port $TEMPLATES $cmd $args`
    println("Command: $cmd")
    return  Snips.tryrun(curl, errorMsg = errorMsg)
end


"""
    getKodiOTRFiles(share)

Return a Dict() with files
and fields: :file (=path), :label (=filename)
* if error, an empty Dict() is returned
"""
function getKodiOTRFiles(share)

    files = Dict()
    if kodiCmd("getRecordings", share)
        recordings = parseKodiResult(:files)
    end
    return recordings
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
