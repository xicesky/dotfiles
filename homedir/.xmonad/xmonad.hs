
---------------------------------------------------------------------------------------------------
-- Prelude          :   Info, Todo, ...
---------------------------------------------------------------------------------------------------
-- Sky's xmonad config
-- Author: Markus Dangl <markus@q1cc.net>

{- TODO:
 - Kill child processes on exit (or restart triggered by mod+Q)
 - Cool app starting feature (Matrix stuff?)
 - Automagically put windows on thematic workspaces?
 - Lock windows to the workspace they were started on
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

baseConfig :: XConfig (ModifiedLayout AvoidStruts (Choose Tall (Choose (Mirror Tall) Full)) )   -- come again?
baseConfig = desktopConfig -- { startupHook = startupHook gnomeConfig } -- startupHook below

myKeys :: XConfig t -> M.Map (KeyMask, KeySym) (X ())
myKeys (XConfig { modMask = modm, terminal = terminal }) = M.fromList $
    -- Grab any windows key event
    [ ((0, xK_Super_L), return ())
    -- Logout via gnome-session-quit
    -- , ((modm .|. shiftMask, xK_q), spawn "gnome-session-quit")  -- FIXME: check for gnome-session
    -- Swap the focused window and the master window (swapped with the launch terminal key)
    , ((modm .|. shiftMask, xK_Return), windows W.swapMaster)
    -- Launch a terminal (swapped with focused to master key)
    , ((modm, xK_Return), spawn terminal)
    -- Toggle the border of the currently focused window 
    , ((modm, xK_g), withFocused toggleBorder)
    -- launch gmrun on mod+r
    , ((modm, xK_r), spawn "gmrun")
    ]

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
myLayoutHook = smartBorders     -- FIXME: Doku: What for?

myManageHook :: Query (Data.Monoid.Endo WindowSet)
myManageHook = mconcat
    [ isFullscreen --> doFullFloat  -- FIXME: Doku: What for?
    ]

myEventHook :: Event -> X Data.Monoid.All
myEventHook = fullscreenEventHook   -- Purpose: Applications can request fullscreen (Chrome)
                                    --  this is not included in the desktopConfig / emwh defaults

myLogHook :: Handle -> X ()
myLogHook barProc = dynamicLogWithPP xmobarPP           -- Purpose: xmobar
    { ppOutput = hPutStrLn barProc                      --     Desktops
    , ppTitle = xmobarColor "green" "" . shorten 80     --     Window title
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

main :: IO ()
main = do
    xmDir <- getXMonadDir
    barCmd <- return $ "xmobar " ++ xmDir ++ "/xmobar.config"
    -- safeSpawn "xmessage" [ barCmd ]
    barProc <- spawnPipe barCmd
    spawnTray
    xmonad $ baseConfig
        {   modMask     = mod4Mask      -- Yay for the super key.
        ,   terminal    = "urxvt"       -- The best terminal.

        -- basics
        ,   focusFollowsMouse   = False
        ,   borderWidth         = 1
        ,   normalBorderColor   = "#555555"
        ,   focusedBorderColor  = "#5555ff"

        -- bindings
        ,   keys            = myKeys <+> keys baseConfig
        ,   mouseBindings   = myMouse <+> mouseBindings baseConfig

        -- hooks
        ,   startupHook     = myStartupHook <+> startupHook baseConfig
        ,   layoutHook      = myLayoutHook $ layoutHook baseConfig
        ,   manageHook      = myManageHook <+> manageHook baseConfig
        ,   handleEventHook = myEventHook <+> handleEventHook baseConfig
        ,   logHook         = myLogHook barProc <+> logHook baseConfig

        }

