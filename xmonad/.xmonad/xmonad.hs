
---------------------------------------------------------------------------------------------------
-- Prelude          :   Info, Todo, ...
---------------------------------------------------------------------------------------------------
-- Sky's xmonad config
-- Author: Markus Dangl <markus@q1cc.net>

-- i sincerely hope
--      YOU FUCKING SPEAK HASKELL!
--                  Have fun!

{- TODO:
 -      Kill child processes on exit (or restart triggered by mod+Q)
 -      Be able to reset workspace (master size, layout) using a hotkey
 -      Use a better bar that integrates notifications & tray
 -      Set up different layouts on different workspaces by default (e.g. Full on 5 for browser)
 -      Create a hotkey that autolaunches my default apps on various workspaces
 -          (Don't do that on startup, i want xmonad to start FAST)
 -          (This will need a proper SpawnOn configuration)
 -      
 - Cool app starting feature (Matrix stuff?)
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-GridSelect.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-Submap.html
 -
 - Topics & Automagic windows
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-DynamicWorkspaces.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-XPropManage.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-SpawnOn.html
 -
 - Interesting stuff:
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-FloatKeys.html
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-Search.html
 -
 -      http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-Script.html
 -          Useless but inspires a dynamically loaded ("scripted") xmonad config
 -      http://hackage.haskell.org/package/xmonad-eval
 -
 - Panels / Bars:
 -      https://wiki.archlinux.org/index.php/PyPanel
 -      http://stalonetray.sourceforge.net/manpage.html
 -      https://wiki.archlinux.org/index.php/Stalonetray
 -      http://hackage.haskell.org/package/taffybar or https://github.com/travitch/taffybar
 -          nice idea: https://github.com/koterpillar/tianbar
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
import System.Exit (exitWith, ExitCode (..))

import qualified Data.Map as M
import qualified Data.Monoid
import Data.Monoid (mempty, mappend, mconcat)

-- Big yays please
import XMonad

-- We need to import some modules just to write proper type signatures
import XMonad.Layout.LayoutModifier (ModifiedLayout)

-- Our base config
import XMonad.Config.Desktop (desktopConfig)

-- A bit of gnomishness (maybe remove that later)
import XMonad.Config.Gnome (gnomeRegister)

-- Bits and pieces
import XMonad.Hooks.EwmhDesktops (ewmhDesktopsEventHook, fullscreenEventHook)
import XMonad.Hooks.ManageDocks (AvoidStruts, ToggleStruts (..), manageDocks)
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.DynamicLog
import qualified XMonad.StackSet as W

-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-WindowMenu.html
import XMonad.Actions.WindowMenu (windowMenu)   -- inspires a more sophisticated menu

-- Let's try this
-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-Plane.html
import XMonad.Actions.Plane

-- Spawn programs (xmobar, trayer)
import XMonad.Util.Run(spawnPipe,safeSpawn,safeSpawnProg)
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
myWorkspaces :: [WorkspaceId]
myWorkspaces = map show [1 .. 9 :: Int]

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

-- | The preferred terminal program (By default on mod+return)
myTerminal      :: String
myTerminal      = "urxvt"

-- | Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False                 -- generally doesn't work well

-- | Whether a mouse click select the focus or is just passed to the window
myClickJustFocuses :: Bool
myClickJustFocuses = True                   -- okay with me

-- Base configuration to use
baseConfig :: XConfig (ModifiedLayout AvoidStruts (Choose Tall (Choose (Mirror Tall) Full)) )   -- come again?
baseConfig = desktopConfig

---------------------------------------------------------------------------------------------------

numPadKeys =
    [ xK_KP_End,  xK_KP_Down,  xK_KP_Page_Down -- 1, 2, 3
    , xK_KP_Left, xK_KP_Begin, xK_KP_Right     -- 4, 5, 6
    , xK_KP_Home, xK_KP_Up,    xK_KP_Page_Up   -- 7, 8, 9
    , xK_KP_Insert] -- 0


-- For reference
baseKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
baseKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    -- launching and killing programs
    [ ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf) -- %! Launch terminal
    , ((modMask,               xK_p     ), spawn "dmenu_run") -- %! Launch dmenu
    , ((modMask .|. shiftMask, xK_p     ), spawn "gmrun") -- %! Launch gmrun
    , ((modMask .|. shiftMask, xK_c     ), kill) -- %! Close the focused window

    , ((modMask,               xK_space ), sendMessage NextLayout) -- %! Rotate through the available layout algorithms
    , ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf) -- %!  Reset the layouts on the current workspace to default

    , ((modMask,               xK_n     ), refresh) -- %! Resize viewed windows to the correct size

    -- move focus up or down the window stack
    , ((modMask,               xK_Tab   ), windows W.focusDown) -- %! Move focus to the next window
    , ((modMask .|. shiftMask, xK_Tab   ), windows W.focusUp  ) -- %! Move focus to the previous window
    , ((modMask,               xK_j     ), windows W.focusDown) -- %! Move focus to the next window
    , ((modMask,               xK_k     ), windows W.focusUp  ) -- %! Move focus to the previous window
    , ((modMask,               xK_m     ), windows W.focusMaster  ) -- %! Move focus to the master window

    -- modifying the window order
    , ((modMask,               xK_Return), windows W.swapMaster) -- %! Swap the focused window and the master window
    , ((modMask .|. shiftMask, xK_j     ), windows W.swapDown  ) -- %! Swap the focused window with the next window
    , ((modMask .|. shiftMask, xK_k     ), windows W.swapUp    ) -- %! Swap the focused window with the previous window

    -- resizing the master/slave ratio
    , ((modMask,               xK_h     ), sendMessage Shrink) -- %! Shrink the master area
    , ((modMask,               xK_l     ), sendMessage Expand) -- %! Expand the master area

    -- floating layer support
    , ((modMask,               xK_t     ), withFocused $ windows . W.sink) -- %! Push window back into tiling

    -- increase or decrease number of windows in the master area
    , ((modMask              , xK_comma ), sendMessage (IncMasterN 1)) -- %! Increment the number of windows in the master area
    , ((modMask              , xK_period), sendMessage (IncMasterN (-1))) -- %! Deincrement the number of windows in the master area

    -- quit, or restart
    , ((modMask .|. shiftMask, xK_q     ), io (exitWith ExitSuccess)) -- %! Quit xmonad
    , ((modMask              , xK_q     ), spawn "if type xmonad; then xmonad --recompile && xmonad --restart; else xmessage xmonad not in \\$PATH: \"$PATH\"; fi") -- %! Restart xmonad

{- -- Module `XMonad.Config' does not export `help' -- Yeah, fuck you, too.
    , ((modMask .|. shiftMask, xK_slash ), spawn ("echo \"" ++ help ++ "\" | xmessage -file -")) -- %! Run xmessage with a summary of the default keybindings (useful for beginners)
    -- repeat the binding for non-American layout keyboards
    , ((modMask              , xK_question), spawn ("echo \"" ++ help ++ "\" | xmessage -file -"))
-}
    ]
    ++
    -- mod-[1..9] %! Switch to workspace N
    -- mod-shift-[1..9] %! Move client to workspace N
    [((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
    -- mod-{w,e,r} %! Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r} %! Move client to screen 1, 2, or 3
    [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig { modMask = modm, terminal = terminal }) = mconcat $
    -- mconcat is a left-biased map join, we want it to be right biased
    reverse
    [ baseKeys conf
    , M.fromList $  -- Custom keys
        -- Grab any windows key event
        [ ((0, xK_Super_L), return ())
        -- Swap the focused window and the master window
        , ((modm .|. shiftMask, xK_Return), windows W.swapMaster)
        -- Launch a terminal
        , ((modm, xK_Return), spawn terminal)
        -- Toggle the border of the currently focused window 
        , ((modm, xK_g), withFocused toggleBorder)
        -- Toggle struts on the current workspace (from XMonad.Config.Desktop)
        , ((modm, xK_b), sendMessage ToggleStruts)
        -- launch gmrun on mod+r
        , ((modm, xK_r), spawn "gmrun")
        -- WindowMenu
        , ((modm, xK_o ), windowMenu)
        ]
    , M.fromList $  -- Workspace switching with numpad
        [ ((m .|. modm, k), windows $ f i)
        | (i, k) <- zip myWorkspaces numPadKeys
        , (m, f) <-
            [ (0        ,   W.greedyView)
            , (shiftMask,   W.shift)
            ]
        ]
    --, planeKeys modm (Lines 3) Circular
    , M.fromList $  -- Custom planeKeys o.O
        [ ((m .|. modm, k), function (Lines 3) Circular direction)
        | (k, direction) <- zip
            [ xK_Left,  xK_Right,   xK_Up,  xK_Down ]
            [ ToLeft,   ToRight,    ToDown, ToUp    ]   -- yes i know it's weird. i like it.
        , (m, function) <-
            [ (0        ,   planeMove)
            , (shiftMask,   planeShift)
            ]
        ]
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
    gnomeRegister       -- Announce XMonad to gnome-session (if that's running at all), reducing startup time
    --ewmhDesktopsStartup -- Announce EWMH support to the X server (needed for e.g. multi-monitor windows)
                        -- This is already included in baseConfig = desktopConfig

-- Now that's one fucked up type signature...
myLayoutHook
  :: ModifiedLayout
       AvoidStruts (Choose Tall (Choose (Mirror Tall) Full)) Window
     -> ModifiedLayout
          SmartBorder
          (ModifiedLayout
             AvoidStruts (Choose Tall (Choose (Mirror Tall) Full)))
          Window
myLayoutHook = 
    --avoidStruts . -- Already included in baseConfig = desktopConfig
    smartBorders    -- Hides border when unneccesary (e.g. in fullscreen)

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
    `mappend` ewmhDesktopsEventHook -- Already included in baseConfig = desktopConfig

myLogHook :: RuntimeConfig -> X ()
myLogHook rtcfg = mempty
--myLogHook rtcfg = dynamicLogWithPP xmobarPP         -- Purpose: xmobar
--    { ppOutput = hPutStrLn (barProc rtcfg)          --     Desktops
--    , ppTitle = xmobarColor "green" "" . shorten 80 --     Window title
--    }
--    -- `mappend` ewmhDesktopsLogHook      -- Already included in baseConfig = desktopConfig

---------------------------------------------------------------------------------------------------
-- I like to have all settings explicitly enumerated here
-- If i upgrade XMonad and there are any new settings i'd like to get a compile error here
-- Some variables are only available at runtime, i put those in a special "RuntimeConfig" record
myConfig rtcfg = XConfig
    { XMonad.borderWidth        = myBorderWidth         -- no merge
    , XMonad.workspaces         = myWorkspaces          -- no merge
    , XMonad.layoutHook         = myLayoutHook          $   XMonad.layoutHook           baseConfig
    , XMonad.terminal           = myTerminal            -- no merge
    , XMonad.normalBorderColor  = myNormalBorderColor   -- no merge
    , XMonad.focusedBorderColor = myFocusedBorderColor  -- no merge
    , XMonad.modMask            = myModKey              -- no merge
    , XMonad.keys               = myKeys                {- <+> XMonad.keys              baseConfig -}
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

-- -- TODO: Move config stuff from here to previous "chapter"
-- 
-- spawnTray :: IO ()
-- spawnTray = safeSpawn "trayer"                          -- Purpose: trayer
--     [   "--edge", "top"
--     ,   "--align", "right"
--     ,   "--width", "10"
--     ,   "--height", "18"
--     ,   "--transparent", "true"
--     ,   "--tint", "0x000000"
--     ,   "--SetDockType", "true"
--     ,   "--SetPartialStrut", "true"
--     ,   "--expand", "true"
--     ]

---------------------------------------------------------------------------------------------------
-- Chapter ZZ       :   Main - Assemble and Launch!
---------------------------------------------------------------------------------------------------

data RuntimeConfig = RuntimeConfig
    {   --barProc     :: !Handle
    }


main :: IO ()
main = do
    xmDir <- getXMonadDir
    -- barCmd <- return $ "xmobar " ++ xmDir ++ "/xmobar.config"
    -- safeSpawn "xmessage" [ barCmd ]
    -- barProc <- spawnPipe barCmd
    safeSpawnProg "taffybar" 
    rtcfg <- return RuntimeConfig
        {   --barProc = barProc
        }
    -- spawnTray
    xmonad (myConfig rtcfg)

