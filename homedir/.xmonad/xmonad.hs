
-- Sky's xmonad config
-- Author: Markus Dangl <markus@q1cc.net>

{- TODO:
 - Kill child processes on exit (or restart triggered by mod+Q)
 -}

import System.IO
import System.Directory (getHomeDirectory)

import XMonad
import XMonad.Config.Desktop
import XMonad.Config.Gnome
import XMonad.Hooks.DynamicLog
-- import XMonad.Hooks.EwmhDesktops
import qualified XMonad.StackSet as W
import XMonad.Util.Run(spawnPipe,safeSpawn)
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Actions.NoBorders

import qualified Data.Map as M

-- Don't use gnomeConfig, it sucks.
baseConfig = desktopConfig { startupHook = startupHook gnomeConfig }

myKeys (XConfig { modMask = modm, terminal = terminal }) = M.fromList $
    -- Logout via gnome-session-quit
    [ ((modm .|. shiftMask, xK_q), spawn "gnome-session-quit")  
    -- Grab any windows key event
    , ((0, xK_Super_L), return ())
    -- Swap the focused window and the master window (swapped with the launch terminal key)
    , ((modm .|. shiftMask, xK_Return), windows W.swapMaster)
    -- Launch a terminal (swapped with focused to master key)
    , ((modm, xK_Return), spawn terminal)
    -- Toggle the border of the currently focused window 
    , ((modm, xK_g), withFocused toggleBorder)
    ]

myLogHook barProc = dynamicLogWithPP xmobarPP
    { ppOutput = hPutStrLn barProc
    , ppTitle = xmobarColor "green" "" . shorten 80
    }

spawnTray = safeSpawn "trayer"
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
        ,   focusFollowsMouse   = True
        ,   borderWidth         = 1
        ,   normalBorderColor   = "#555555"
        ,   focusedBorderColor  = "#5555ff"

        -- bindings
        ,   keys            = myKeys <+> keys baseConfig
    --    ,   mouseBindings   = myMouse <+> mouseBindings baseConfig

        -- hooks
    --    ,   layoutHook      = myLayout ||| layoutHook baseConfig
    --    ,   manageHook      = myManageHook <+> manageHook baseConfig
    --    ,   handleEventHook = myEventHook <+> handleEventHook baseConfig
        ,   logHook         = myLogHook barProc <+> logHook baseConfig
    --    ,   startupHook     = myStartupHook <+> startupHook baseConfig

        }


