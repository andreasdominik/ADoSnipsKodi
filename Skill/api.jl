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

    if kodiCmd("getTVshows")
        tvShows = parseKodiResult(:tvshows)
    end
    return tvShows
end


""""
    kodiGetOTRrecordings()

recieve a Dict with recordings  with fields:
:type: :movie/:episode:/:unknown,
:path, :name, :episode, :season
"""
function kodiGetOTRrecordings()

    otrs = getKodiOTRFiles()
    otrs = parseOTRname.(otrs)

    return otrs
end

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
function getKodiOTRFiles()

    Returns a Dict() with files
    and fields: :file (=path), :label (=filename)
    * if error, an empty Dict() is returned
"""
function getKodiOTRFiles()

    files = Dict()
    if kodiCmd("getOTR")
        recordings = parseKodiResult(:files)
    end
    return recordings
end



#
# Basic KODI helper functions:
#
#
"""
extractTVshow(text, tvShows; reverse = true)

    checks, if one of the TV show titles in tvShows
    is includes in text.
    And returns the matched TV show (as Dict)

    # Arguments:
    * text : voice recording
    * tvShows : List of Dicts from KODI
    * reverse : if true (default), do a reverse serach, if no match
                normal: the title is searched in text
                (title must be a part of the text).
                The longest matched title is returned.
                reverse: the text is searched in the titles
                (text must be a part of the title)
                the match is returned, if exactly one title matched.
"""
function extractTVshow(text, tvShows; reverse = true)

    tvShow = nothing        # the result
    matchedTVShows = []
    for oneShow in tvShows
        upperOccursin(oneShow[:title], text) && push!(matchedTVShows, oneShow)
    end

    # nothing found, do reverse search:
    if length(matchedTVShows) == 0
        if reverse
            for oneShow in tvShows
                upperOccursin(text, oneShow[:title]) && push!(matchedTVShows, oneShow)
            end
            if length(matchedTVShows) == 1
                tvShow = matchedTVShows[1]
            end
        end

    # if one found, go with it:
    elseif length(matchedTVShows) == 1
        tvShow = matchedTVShows[1]

    # if many found, take the longest:
    else    # length(matchedTVShows) > 1
        matchLen = 0
        tvShow = matchedTVShows[1]
        for oneShow in tvShows
            if length(oneShow[]) > matchLen
                matchLen = length(oneShow[:title])
                tvShow = oneShow
            end
        end
    end

    return tvShow
end

"""
extractOTR(text, otrs)

    checks, if one of the titles in otrs
    is includes in text.
    And returns the matched recordings (as Array of Dicts)

    # Arguments:
    * text : voice recording
    * otrs : List of Dicts from KODI
"""
function extractOTR(text, otrs)

    otr = nothing        # the result
    matchedOTRs = []
    for oneOTR in otrs
        upperOccursin(oneOTR[:title], text) && push!(matchedOTRs, oneOTR)
    end

    # nothing found, do reverse search:
    if length(matchedOTRs) == 0
        for oneOTR in otrs
            upperOccursin(text, oneOTR[:title]) && push!(matchedOTRs, oneOTR)
        end
    end
    return matchedOTRs
end




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

extracts movie name, and episode from OTR filename
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
