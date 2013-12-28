
---------------------------------------------------------------------------------------------------
-- Prelude          :   Info, Todo, ...
---------------------------------------------------------------------------------------------------
-- Sky's xmonad config
-- Author: Markus Dangl <markus@q1cc.net>

{- TODO:
 -      Kill child processes on exit (or restart triggered by mod+Q)
 -
 - Cool app starting feature (Matrix stuff?)
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-GridSelect.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-Submap.html
 -
 - Topics & Automagic windows
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-DynamicWorkspaces.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-TopicSpace.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-XPropManage.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-SpawnOn.html
 -
 - Interesting stuff:
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-CycleWS.html
 -      or better: http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-Plane.html
 -      or even: http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-WorkspaceCursors.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-FloatKeys.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-Search.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-WindowMenu.html
 -
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-Script.html
 -          Useless but inspires a dynamically loaded ("scripted") xmonad config
 -
 - Panels / Bars:
 -      https://wiki.archlinux.org/index.php/PyPanel
 -      http://stalonetray.sourceforge.net/manpage.html
 -      https://wiki.archlinux.org/index.php/Stalonetray
 -
 - Eyecandy:
 -      https://wiki.archlinux.org/index.php/Compton
 -      https://wiki.archlinux.org/index.php/Category:Eye_candy
 -      https://wiki.archlinux.org/index.php/Redshift
 -
 - More cool haskell stuff:
 -      http://hackage.haskell.org/package/ztail
 -
 - Tips:
 -      http://www.haskell.org/haskellwiki/Xmonad/Frequently_asked_questions
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Doc-Extending.html
 - 
 - More configs:
 -      http://www.haskell.org/haskellwiki/Xmonad/Config_archive
 -}

---------------------------------------------------------------------------------------------------
-- Chapter 0        :   Imports
---------------------------------------------------------------------------------------------------

import System.IO
import System.Directory (getHomeDirectory)

import qualified Data.Map as M
import qualified Data.Monoid
import Data.Monoid (mconcat)

-- Big yays please
import XMonad

-- We need to import some modules just to write proper type signatures
import XMonad.Layout.LayoutModifier (ModifiedLayout)
import XMonad.Hooks.ManageDocks (AvoidStruts)

-- Our base config
import XMonad.Config.Desktop (desktopConfig)

-- A bit of gnomishness (maybe remove that later)
import XMonad.Config.Gnome (gnomeRegister)

-- Bits and pieces
import XMonad.Hooks.EwmhDesktops (fullscreenEventHook)
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.DynamicLog
import qualified XMonad.StackSet as W
import XMonad.Actions.WindowMenu (windowMenu)   -- inspires a more sophisticated menu

-- Topic spaces
import XMonad.Actions.TopicSpace
    ( (>*>)     -- TODO: i don't like fish
    , Topic, TopicConfig
    , defaultTopicConfig, defaultTopic, defaultTopicAction
    , topicActions, currentTopicAction, checkTopicConfig
    )

-- Spawn programs (xmobar, trayer)
import XMonad.Util.Run(spawnPipe,safeSpawn)
-- import XMonad.Util.EZConfig(additionalKeys)

-- Window handling
import XMonad.Actions.NoBorders
import qualified XMonad.Actions.FlexibleResize as Flex
import XMonad.Layout.NoBorders

---------------------------------------------------------------------------------------------------
-- Chapter I        :   Configuration
---------------------------------------------------------------------------------------------------

-- Simple settings - following the style in
-- http://hackage.haskell.org/package/xmonad-0.11/docs/src/XMonad-Config.html

-- | Workspaces enumerated by name
--myWorkspaces :: [WorkspaceId]
--myWorkspaces = map show [1 .. 9 :: Int]

-- | Topics instead of workspaces
myTopics :: [Topic]
myTopics =
    [   "main"
    ,   "browser"
    ,   "3"
    ,   "4"
    ,   "5"
    ,   "6"
    ,   "7"
    ,   "8"
    ,   "communication"
    ,   "system"
    ]

-- | The modkey you want to use.
myModKey        :: KeyMask
myModKey        = mod4Mask

-- | Width of the window border in pixels.
myBorderWidth :: Dimension
myBorderWidth = 1

-- | Border colors for unfocused and focused windows, respectively.
myNormalBorderColor, myFocusedBorderColor :: String
myNormalBorderColor  = "#555555"        -- darkish grey
myFocusedBorderColor = "#5555ff"        -- grayish light blue

-- | The preferred terminal program (Used in various places)
myTerminal :: String
myTerminal = "urxvt"

-- | Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False                 -- generally doesn't work well

-- | Whether a mouse click select the focus or is just passed to the window
myClickJustFocuses :: Bool
myClickJustFocuses = True                   -- okay with me

-- Base configuration to use
baseConfig :: XConfig (ModifiedLayout AvoidStruts (Choose Tall (Choose (Mirror Tall) Full)) )   -- come again?
baseConfig = desktopConfig

-- | Which browser do u like to launch
myBrowser :: String
myBrowser = "chromium"

---------------------------------------------------------------------------------------------------

myTopicConfig :: TopicConfig
myTopicConfig = defaultTopicConfig
    {   defaultTopic = "main"
    ,   defaultTopicAction = const $ spawnShell >*> 3       -- !?!
--    ,   topicDirs = M.fromList $
--        [   ("example",     "Dev/example" )
--        ,   ("documents",   "Dokumente" )
--        ]
--
    , topicActions = M.fromList $
        [   ("main",    spawnShellIn "~")           -- see if that works
        ,   ("browser", spawn $ myBrowser)
        --,   ("communication",   mailAction)
        ]
    }

-- Custom actions

spawnShell :: X ()
spawnShell = spawn $ myTerminal

spawnShellIn :: String -> X ()
spawnShellIn dir = spawn $ myTerminal ++ "urxvt '(cd ''" ++ dir ++ "'' && " ++ myTerminal ++ " )'"

myKeys :: XConfig t -> M.Map (KeyMask, KeySym) (X ())
myKeys (XConfig { modMask = modm }) = M.fromList $
    -- Grab any windows key event
    [ ((0, xK_Super_L), return ())
    -- Logout via gnome-session-quit
    -- , ((modm .|. shiftMask, xK_q), spawn "gnome-session-quit")  -- FIXME: check for gnome-session
    -- Swap the focused window and the master window (swapped with the launch terminal key)
    , ((modm .|. shiftMask, xK_Return), windows W.swapMaster)
    -- Launch a terminal (swapped with focused to master key)
    , ((modm, xK_Return), spawnShell)
    -- Toggle the border of the currently focused window 
    , ((modm, xK_g), withFocused toggleBorder)
    -- launch gmrun on mod+r
    , ((modm, xK_r), spawn "gmrun")
    -- WindowMenu
    , ((modm, xK_o), windowMenu)
    -- Topic
    , ((modm, xK_a), currentTopicAction myTopicConfig)
    ]


-- | The available layouts.  Note that each layout is separated by |||, which
-- denotes layout choice.
layout = tiled ||| Mirror tiled ||| Full
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = Tall nmaster delta ratio

     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = 1/2

     -- Percent of screen to increment by when resizing panes
     delta   = 3/100

myMouse :: XConfig t -> M.Map (KeyMask, Button) (Window -> X ())
myMouse (XConfig { modMask = modm }) = M.fromList $
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    -- , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))
    -- Swap with the master window instead
    , ((modm, button2), (\w -> focus w >> windows W.swapMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    --, ((modm, button3), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster))
    -- Use FlexibleResize instead
    , ((modm, button3), (\w -> focus w >> Flex.mouseResizeWindow w ))

    -- button 4 & 5 = mousewheel
    ]

myStartupHook :: X ()
myStartupHook = do
    gnomeRegister   -- FIXME: Doku: What for?
    -- ewmhDesktopsStartup -- FIXME: Doku: What for?

-- Now that's one fucked up type signature...
myLayoutHook
  :: ModifiedLayout
       AvoidStruts (Choose Tall (Choose (Mirror Tall) Full)) Window
     -> ModifiedLayout
          SmartBorder
          (ModifiedLayout
             AvoidStruts (Choose Tall (Choose (Mirror Tall) Full)))
          Window
myLayoutHook = smartBorders     -- Hides border when unneccesary (e.g. in fullscreen)

-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-ManageHelpers.html
-- http://www.haskell.org/haskellwiki/Xmonad/Frequently_asked_questions#Prevent_new_windows_from_stealing_focus
-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-XPropManage.html
myManageHook :: Query (Data.Monoid.Endo WindowSet)
myManageHook = mconcat
    [ isFullscreen --> doFullFloat  -- Automatically fullscreen windows that want to fullscreen
--    , className =? "Gimp"      --> doFloat    -- Example
    ]

myEventHook :: Event -> X Data.Monoid.All
myEventHook = fullscreenEventHook   -- Purpose: Applications can request fullscreen (Chrome)
                                    --  this is not included in the desktopConfig / emwh defaults
myLogHook :: RuntimeConfig -> X ()
myLogHook rtcfg = dynamicLogWithPP xmobarPP         -- Purpose: xmobar
    { ppOutput = hPutStrLn (barProc rtcfg)          --     Desktops
    , ppTitle = xmobarColor "green" "" . shorten 80 --     Window title
    }

---------------------------------------------------------------------------------------------------
-- I like to have all settings explicitly enumerated here
-- If i upgrade XMonad and there are any new settings i'd like to get a compile error here
-- Some variables are only available at runtime, i put those in a special "RuntimeConfig" record
myConfig rtcfg = XConfig
    { XMonad.borderWidth        = myBorderWidth         -- no merge
--    , XMonad.workspaces         = myWorkspaces          -- no merge
    , XMonad.workspaces         = myTopics
    , XMonad.layoutHook         = myLayoutHook          $   XMonad.layoutHook           baseConfig
    , XMonad.terminal           = myTerminal            -- no merge
    , XMonad.normalBorderColor  = myNormalBorderColor   -- no merge
    , XMonad.focusedBorderColor = myFocusedBorderColor  -- no merge
    , XMonad.modMask            = myModKey              -- no merge
    , XMonad.keys               = myKeys                <+> XMonad.keys                 baseConfig
    , XMonad.logHook            = myLogHook rtcfg       <+> XMonad.logHook              baseConfig
    , XMonad.startupHook        = myStartupHook         <+> XMonad.startupHook          baseConfig
    , XMonad.mouseBindings      = myMouse               <+> XMonad.mouseBindings        baseConfig
    , XMonad.manageHook         = myManageHook          <+> XMonad.manageHook           baseConfig
    , XMonad.handleEventHook    = myEventHook           <+> XMonad.handleEventHook      baseConfig
    , XMonad.focusFollowsMouse  = myFocusFollowsMouse   -- no merge
    , XMonad.clickJustFocuses   = myClickJustFocuses    -- no merge
    }

---------------------------------------------------------------------------------------------------
-- Chapter II       :   External Programs
---------------------------------------------------------------------------------------------------

-- TODO: Move config stuff from here to previous "chapter"

spawnTray :: IO ()
spawnTray = safeSpawn "trayer"                          -- Purpose: trayer
    [   "--edge", "top"
    ,   "--align", "right"
    ,   "--width", "10"
    ,   "--height", "18"
    ,   "--transparent", "true"
    ,   "--tint", "0x000000"
    ,   "--SetDockType", "true"
    ,   "--SetPartialStrut", "true"
    ,   "--expand", "true"
    ]

---------------------------------------------------------------------------------------------------
-- Chapter ZZ       :   Main - Assemble and Launch!
---------------------------------------------------------------------------------------------------

data RuntimeConfig = RuntimeConfig
    {   barProc     :: !Handle
    }

main :: IO ()
main = do
    checkTopicConfig myTopics myTopicConfig
    xmDir <- getXMonadDir
    barCmd <- return $ "xmobar " ++ xmDir ++ "/xmobar.config"
    -- safeSpawn "xmessage" [ barCmd ]
    barProc <- spawnPipe barCmd
    rtcfg <- return RuntimeConfig
        {   barProc = barProc
        }
    spawnTray
    xmonad (myConfig rtcfg)

