

"""
    switchOnOffActions(topic, payload)

Switch on KODI with GPIO
"""
function switchOnOffActions(topic, payload)

    # log:
    #
    println("[ADoSnipsKodi]: action switchOnOffActions() started.")

    # ignore, if not responsible (other device):
    #
    device = Snips.extractSlotValue(payload, SLOT_DEVICE)
    if device == nothing || !( device in ["KODI"])
        return false
    end


    # ROOMs are not yet supported -> only ONE Fire  in assistent possible.
    #
    # room = Snips.extractSlotValue(payload, SLOT_ROOM)
    # if room == nothing
    #     room = Snips.getSiteId()
    # end

    onOrOff = Snips.extractSlotValue(payload, SLOT_ON_OFF)
    if onOrOff == nothing || !(onOrOff in ["ON", "OFF"])
        Snips.publishEndSession(:dunno)
        return true
    end

    println(">>> $onOrOff, $device")

    # check ini vals:
    #
    if !Snips.isConfigValid(INI_IP) ||
       !Snips.isConfigValid(INI_PORT, regex = r"[0-9]+") ||
       !Snips.isConfigValid(INI_GPIO, regex = r"[0-9]+") ||
       !Snips.isConfigValid(INI_TV)

       Snips.publishEndSession(:noip)
       return true
    end

    if onOrOff == "OFF"
        Snips.publishEndSession(:switchoff)
        kodiOff()
    else
        Snips.publishEndSession(:switchon)
        kodiOn()
    end
    return false
end


"""
    playVideoAction(topic, payload)

Play a video
* from TV Show database
* from OTR recordings
* from Movie database
"""
function playVideoAction(topic, payload)

    # log:
    #
    println("[ADoSnipsKodi]: action playVideoAction() started.")

    # ignore, if not responsible (other device):
    #
    videoName = Snips.extractSlotValue(payload, SLOT_MOVIENAME)
    if !Snips.isValidOrEnd(videoName, errorMsg = :error_name)
        kodiOn()
        return true
    end

    # ROOMs are not yet supported -> only ONE Fire  in assistent possible.
    #
    # room = Snips.extractSlotValue(payload, SLOT_ROOM)
    # if room == nothing
    #     room = Snips.getSiteId()
    # end

    println(">>> Movie Name: $videoName")

    # check ini vals:
    #
    if !Snips.isConfigValid(INI_IP) ||
       !Snips.isConfigValid(INI_PORT, regex = r"[0-9]+") ||
       !Snips.isConfigValid(INI_GPIO, regex = r"[0-9]+") ||
       !Snips.isConfigValid(INI_TV)

       Snips.publishEndSession(:noip)
       return true
    end

     if ! kodiIsOn()
         kodiOn()
     end

    matchedVideo = nothing
    # 1st: check tv shows in DB
    #
    Snips.publishSay("$(Snips.langText(:i_search_show)) $videoName", wait = false)
    tvShows = kodiGetTVshows()
    tvShow = extractTVshow(videoName, tvShows)

    if tvShow != nothing
        episodes = kodiGetEpisodes(tvShow)
        if length(episodes) > 0
            matchedVideo = unseenEpisode(episodes)

            numVideos = length(episodes)
            numUnseen = countUnseen(episodes)

            Snips.publishSay(
                 """$(Snips.langText(:found)): $numVideos $(Snips.langText(:episodes)).
                 $(Snips.langText(:new)): $numUnseen.""")
        end
    end

    if matchedVideo != nothing
        Snips.publishEndSession(
            """$(Snips.langText(:i_play)) $(matchedVideo[:showtitle])
               $(Snips.langText(:episode)) $(matchedVideo[:episode]) aus der
               $(Snips.langText(:season)) $(matchedVideo[:season]).
               $(Snips.langText(:title_is)) $(matchedVideo[:title])""")
        kodiPlayEpisode(matchedVideo)
        return false
    end


    # 2nd: check OTR-recordings:
    #
    if Snips.isConfigValid(INI_SHARE)

        Snips.publishSay("""$(Snips.langText(:i_search_rec)) $videoName.
                $(Snips.langText(:be_patient))""", wait = false)

        recs = kodiGetRrecordings(Snips.getConfig(INI_SHARE))
        episodes = extractOTR(videoName, recs)
        println(episodes)
        if length(episodes) > 0
            matchedVideo = oldestOTR(episodes)

            numVideos = length(episodes)
            # numUnseen = countUnseen(episodes)

            Snips.publishSay(
                 """$(Snips.langText(:found)): $numVideos $(Snips.langText(:recordings)).""")
                 # $(Snips.langText(:new)): $numUnseen.""")
        end

        if matchedVideo != nothing
            Snips.publishEndSession(
                """$(Snips.langText(:i_play_new_otr)) $(matchedVideo[:title])""")
            kodiPlayFile(matchedVideo)
            return false
        end
    end

    # 3rd: look for movies:
    #
    Snips.publishSay("$(Snips.langText(:i_search_movie)) $videoName", wait = false)
    movies = kodiGetMovies()
    matchedVideos = matchMovie(videoName, movies)

    numVideos = length(matchedVideos)
    if numVideos > 1
        Snips.publishEndSession(
            """$(Snips.langText(:found)) $(numVideos).
            $(Snips.langText(:diy))""")
        return true

    elseif numVideos == 1
        matchedVideo = matchedVideos[1]
        Snips.publishEndSession(
            """$(Snips.langText(:i_play)) $(matchedVideo[:title])""")
        kodiPlayMovie(matchedVideo)
        return false
    end


    Snips.publishSay(:error_name)
    Snips.publishEndSession(:diy)
    return true
end
