#!/bin/bash
#
# curl JSON to KODI for API remote control
#
IP=$1
PORT=$2
TEMPLATES=$3
CMD=$4

if [[ $# -gt 4 ]] ; then
  PARAM=$5
fi
if [[ $# -gt 5 ]] ; then
  PARAM2="$6"
fi

#cd /tmp
JSON="kodidata.json"

case "$CMD" in
  shutdown)
    cp "${TEMPLATES}/shutdown.json" $JSON
    ;;
  getVolume)
  cp "${TEMPLATES}/getvolume.json" $JSON
  ;;
  getTVshows)
    cp "${TEMPLATES}/gettvshows.json" $JSON
    ;;
  getMovies)
    cp "${TEMPLATES}/getmovies.json" $JSON
    ;;
  getEpisodes)
    TEMPLATE="${TEMPLATES}/getepisodes.json"
    cat $TEMPLATE | sed "s/TV_SHOW_ID/$PARAM/g" > $JSON
    ;;
  getEpisodeDetails)
    TEMPLATE="${TEMPLATES}/getepisodedetails.json"
    cat $TEMPLATE | sed "s/EPISODE_ID/$PARAM/g" > $JSON
    ;;
  getRecordings)
    TEMPLATE="${TEMPLATES}/getrecfiles.json"
    cat $TEMPLATE | sed "s+REC_DIRECTORY+$PARAM+g" > $JSON
    # cp "${TEMPLATES}/getrecfiles.json" $JSON
    ;;
  playListClear)
    cp "${TEMPLATES}/playlistclear.json" $JSON
    ;;
  playListAddFile)
    TEMPLATE="${TEMPLATES}/playlistaddfile.json"
    cat $TEMPLATE | sed "s+FILE_PATH+$PARAM+g" > $JSON
    ;;
  playListPlay)
    cp "${TEMPLATES}/playlistplay.json" $JSON
    ;;
  playEpisode)
    TEMPLATE="${TEMPLATES}/playepisode.json"
    cat $TEMPLATE | sed "s/EPISODE_ID/$PARAM/g" > $JSON
    ;;
  playMovie)
    TEMPLATE="${TEMPLATES}/playmovie.json"
    cat $TEMPLATE | sed "s/MOVIE_ID/$PARAM/g" > $JSON
    ;;
  playListPlay)
    cp "${TEMPLATES}/playlistplay.json" $JSON
    ;;
  openHomeWindow)
    cp "${TEMPLATES}/windowopenhome.json" $JSON
    ;;
  openMovieWindow)
    cp "${TEMPLATES}/windowopenmovies.json" $JSON
    ;;
  openTVShowWindow)
    cp "${TEMPLATES}/windowopentvshows.json" $JSON
    ;;
  openTVShowWindowName)
    TEMPLATE="${TEMPLATES}/windowopentvshowname.json"
    cat $TEMPLATE | sed "s/TV_SHOW_ID/$PARAM/g" > $JSON
    ;;
  openOTRWindow)
    cp "${TEMPLATES}/windowopenotr.json" $JSON
    ;;
  openFilesWindow)
    TEMPLATE="${TEMPLATES}/windowopenfiles.json"
    cat $TEMPLATE | sed "s/FILES_TYPE/$PARAM/g" \
                  | sed "s*FILES_DIR*$PARAM2*g"> $JSON
    ;;
  toggleMute)
    cp "${TEMPLATES}/togglemute.json" $JSON
    ;;
  *)
    echo "Command \"$CMD\" is not supported!"
    echo " "
    exit 1
    ;;
esac

cat $JSON

curl ${IP}:${PORT}/jsonrpc --data @${JSON} \
     --header 'content-type: application/json;' \
     -o kodiresult.json

cat kodiresult.json

# evaluate curl result:
RESULT=$?
if [[ $RESULT -eq 0 ]] ; then
  echo "OK"                                         > kodi.status
  echo ""                                          >> kodi.status
  echo "KODI answered to REST interface at $date"  >> kodi.status
else
  echo "Problem"                                    > kodi.status
  echo ""                                          >> kodi.status
  echo "KODI did NOT answer to REST interface at $date"  >> kodi.status
fi

exit 0
# eof.
