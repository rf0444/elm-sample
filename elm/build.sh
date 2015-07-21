#!/bin/sh
elm make --output ../server/src/main/webapp/static/js/elm/counter.js src/Main/Counter.elm
elm make --output ../server/src/main/webapp/static/js/elm/chat.js src/Main/Chat.elm
