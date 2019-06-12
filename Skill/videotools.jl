"""
    extractTVshow(text, tvShows; reverse = true)

Check, if one of the TV show titles in tvShows
is includes in text.
And returns the matched TV show (as Dict)

## Arguments:
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
    unseenEpisode(episodes)

Return the lowest episode with playcount 0
"""
function unseenEpisode(episodes)

    episode = nothing
    sFirst = 10000
    eFirst = 10000
    for e in episodes
        if e[:playcount] == 0
            if e[:season] < sFirst
                sFirst, eFirst = e[:season], e[:episode]
                episode = e
            elseif e[:season] == sFirst && e[:episode] < eFirst
                sFirst, eFirst = e[:season], e[:episode]
                episode = e
            end
        end
    end
    return episode
end


"""
    countUnseen(episodes)

Return the number of episodes with playcount == 0.
Entries without playcount will be reported as unseen.

## Arguments:
episodes: `Dict` of episodes. Each entry should have a
          key `:playcount`.
"""
function countUnseen(episodes)

    unseen = 0
    for episode in episodes

        if haskey(episode, :playcount)
            if episode[:playcount] == 0
                unseen += 1
            end
        else
            unseen += 1
        end
    end
    return unseen
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
    oldestOTR(otrs)

Find oldest recording (== lowest episode number)
or record date.
Returns the selected Dict.
"""
function oldestOTR(otrs)

    f = Dict(:season => "99", :episode => "99", :date => "99.99.99")

    for otr in otrs
        if otr[:season] < f[:season] && (f[:season], f[:episode]) != ("00","00")
            f = otr
        elseif otr[:season] == f[:season] && otr[:episode] < f[:episode] &&
               (f[:season], f[:episode]) != ("00","00")
            f = otr
        elseif (otr[:season], otr[:episode]) == ("00", "00") &&
               otr[:date] < f[:date]
            f = otr
        end

        println("$f")
        println("")
    end

    if length(f) < 1 || f[:season] == "99"
        return nothing
    else
        return f
    end
end


function matchMovie(name, movies)

    matchedMovies = []

    for m in movies
        if occursin(name, m[:title])
            push!(matchedMovies, m)
        end
    end
    return matchedMovies
end
