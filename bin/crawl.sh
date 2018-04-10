#!/bin/bash
# WARNING: Currently adapted only for OS X (using "open" to launch game)

set -e
[ -e save_script/xicesky.cs ] && cp save_script/xicesky.cs saves/xicesky.cs
cd "/Users/markus/Library/Application Support/Dungeon Crawl Stone Soup"
open -W -a "Dungeon Crawl Stone Soup - Tiles"
cd "/Users/markus/Library/Application Support/Dungeon Crawl Stone Soup"
[ -e saves/xicesky.cs ] && cp saves/xicesky.cs save_script/xicesky.cs

