-- Import the "WezTerm" API using a protected call.
local weztermStatus, wezterm = pcall(require, "wezterm")

-- Check if the module was imported successfully.
-- If not, stop processing the configuration.
-- This usually means that there was some error while installing "WezTerm".
if not weztermStatus then
  return
else

  -- Define a few variables for later use.
  local isMacOS = ( ( wezterm.target_triple == "x86_64-apple-darwin" ) or ( wezterm.target_triple == "aarch64-apple-darwin" ) )
  local isUnix = ( not ( wezterm.target_triple == "x86_64-pc-windows-msvc" ) )
  local isWindows = ( not isUnix )

  -- Launch menu and default program --
  ---------------------------------------

  -- The launch menu is a customizable list of arbitary programs that can be launched from within "WezTerm".
  -- We will inspect the host system for a few popular programs and add them to the launch menu if they are installed.

  -- While populating the launch menu, we will also select the default terminal program on Windows systems.
  -- On Unix-like systems, the default terminal program is controlled by the environment variable "SHELL".
  -- On Windows systems, the default terminal program is usually "Command Prompt", but we will choose "PowerShell 7" or "PowerShell 5" if installed.

  -- Initialize an empty table "launchMenuEntries".
  -- This table will be populated with programs and will be used in the configuration later.
  local launchMenuEntries = {}

  -- Initialize a list of popular programs to populate the launch menu with.
  -- The below table will be evaluated in order. The program (if installed) that appears first in the below table will appear first in the launch menu.
  local popularProgramsOrdered = {
    { label = "PowerShell 7", binary = "pwsh", args = "-NoLogo" },
    { label = "PowerShell 5", binary = "powershell", args = "-NoLogo" },
    { label = "Command Prompt", binary = "cmd" },
    { label = "Bash", binary = "bash" },
    { label = "Zsh", binary = "zsh" },
    { label = "Fish", binary = "fish" },
    { label = "Python", binary = "python" },
    { label = "Python 2", binary = "python2" },
    { label = "Python 3", binary = "python3" }
  }

  -- Iterate over the above table in order.
  for _, program in ipairs(popularProgramsOrdered) do
    -- Windows systems.
    if isWindows then
      -- Check if the program is installed.
      if wezterm.run_child_process { "where.exe", "/Q", program["binary"] } then
        -- Add it to the "launchMenuEntries" table.
        table.insert(launchMenuEntries, { label = program["label"], args = { program["binary"], program["args"] } })
        -- Check if the "defaultShellProgram" variable is not nil.
        -- This is done so that the default terminal program is not set again and again.
        if not defaultShellProgram then
          -- Check if the program being iterated over is one of "PowerShell 7", "PowerShell 5" or "Command Prompt".
          -- Between "PowerShell 7", "PowerShell 5" and "Command Prompt", the program that appears first in the table "popularProgramsOrdered", will become the default terminal program.
          if ( ( program["binary"] == "pwsh" ) or ( program["binary"] == "powershell" ) or ( program["binary"] == "cmd" ) ) then
            -- Set the variable "defaultShellProgram".
            defaultShellProgram = { program["binary"], program["args"] }
          end
        end
      end
    -- Other i.e. Unix-like systems.
    else
      -- Check if the program is installed.
      if wezterm.run_child_process { "which", program["binary"] } then
        -- Add it to the "launchMenuEntries" table.
        table.insert(launchMenuEntries, { label = program["label"], args = { program["binary"], program["args"] } })
      end
    end
  end

  -- Modifier key --
  ------------------
  -- A platform specific key that is used to trigger various keyboard actions.
  local modifierKey = nil

  -- On MacOS, use the "Command" key.
  if ( isMacOS ) then
    modifierKey = "CMD"
  -- On other systems (Windows and GNU/Linux), use the "Alt/Meta" key.
  else
    modifierKey = "ALT"
  end

  -- Combine this "modifierKey" with "Shift".
  -- This is mainly to avoid conflicts with OS keybindings/shortcuts.
  modifierKey = modifierKey .. "|SHIFT"


  -- Initialize an empty configuration structure using the built-in function "config_builder()".
  local config = wezterm.config_builder()


  config = {
    -- General --
    -------------
    check_for_updates_interval_seconds = 604800,
    default_cwd = os.getenv("HOME"),
    disable_default_key_bindings = true,
    disable_default_mouse_bindings = true,
    scrollback_lines = 100000,
    default_prog = defaultShellProgram,
    launch_menu = launchMenuEntries,

    -- Appearance --
    ----------------
    warn_about_missing_glyphs = false,
    default_cursor_style = "BlinkingBlock",
    hide_mouse_cursor_when_typing = true,
    use_fancy_tab_bar = false,

    -- Tabs --
    ----------
    mouse_wheel_scrolls_tabs = false,

    -- Windows & Panes --
    ---------------------
    window_close_confirmation = "NeverPrompt",
    pane_focus_follows_mouse = true,
    adjust_window_size_when_changing_font_size = false,

    -- Mouse bindings --
    --------------------
    mouse_bindings = {
      -- Scrolling --
      ---------------
      -- [ mouse wheel up ] -> scroll up the terminal view.
      { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = "NONE", action = wezterm.action.ScrollByCurrentEventWheelDelta },

      -- [ mouse wheel down ] -> scroll down the terminal view.
      { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = "NONE", action = wezterm.action.ScrollByCurrentEventWheelDelta },

      -- Paste --
      -----------
      -- [ middle-click ] -> paste from clipboard.
      { event = { Down = { streak = 1, button = "Middle" } }, mods = "NONE", action = wezterm.action.PasteFrom "Clipboard" },

      -- Text selection and copying --
      --------------------------------
      -- [ 3 x left-click + drag ] -> select and copy text by drawing rectangular blocks.
      { event = { Down = { streak = 3, button = "Left" } }, mods = "NONE", action = wezterm.action.SelectTextAtMouseCursor("Block") },
      { event = { Drag = { streak = 3, button = "Left" } }, mods = "NONE", action = wezterm.action.ExtendSelectionToMouseCursor("Block") },
      { event = { Up = { streak = 3, button = "Left" } }, mods = "NONE", action = wezterm.action.Multiple { wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"), wezterm.action.ClearSelection } },

      -- [ 2 x left-click + drag ] -> select and copy text word by word.
      { event = { Down = { streak = 2, button = "Left" } }, mods = "NONE", action = wezterm.action.SelectTextAtMouseCursor("Word") },
      { event = { Drag = { streak = 2, button = "Left" } }, mods = "NONE", action = wezterm.action.ExtendSelectionToMouseCursor("Word") },
      { event = { Up = { streak = 2, button = "Left" } }, mods = "NONE", action = wezterm.action.Multiple { wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"), wezterm.action.ClearSelection } },

      -- [ left-click + drag ] -> select and copy text following the cursor.
      { event = { Down = { streak = 1, button = "Left" } }, mods = "NONE", action = wezterm.action.SelectTextAtMouseCursor("Cell") },
      { event = { Drag = { streak = 1, button = "Left" } }, mods = "NONE", action = wezterm.action.ExtendSelectionToMouseCursor("Cell") },
      { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = wezterm.action.Multiple { wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"), wezterm.action.ClearSelection } },

      -- Opening URLs --
      ------------------
      -- [ modifierKey + left-click ] -> open URL under cursor.
      { event = { Down = { streak = 1, button = "Left" } }, mods = modifierKey, action = wezterm.action.OpenLinkAtMouseCursor }

    },

    -- Keybindings --
    -----------------
    keys = {
      -- Overlays --
      --------------
      -- [ modifierKey + d ] -> show debug overlay.
      { key = "d", mods = modifierKey, action = wezterm.action.ShowDebugOverlay },

      -- [ modifierKey + p ] -> show command palette.
      { key = "p", mods = modifierKey, action = wezterm.action.ActivateCommandPalette },

      -- [ modifierKey + m ] -> show launcher menu.
      { key = "m", mods = modifierKey, action = wezterm.action.ShowLauncherArgs { flags = "LAUNCH_MENU_ITEMS", title = "Launch Menu" } },

      -- [ modifierKey + f ] -> show search overlay.
      { key = "f", mods = modifierKey, action = wezterm.action.Search("CurrentSelectionOrEmptyString") },

      -- Tab/pane management --
      -------------------------
      -- [ modifierKey + s ] -> prompt a menu presenting pane split options.
      {
        key = "s",
        mods = modifierKey,
        action = wezterm.action.InputSelector {
          action = wezterm.action_callback(
            function(window, pane, id, label)
              if ( id ~= nil ) and ( label ~= nil ) then
                pane:split { direction = id }
              end
            end
          ),
          description = "Select the direction to split the pane [ Enter = accept, Esc = cancel, / = filter ]",
          title = "Select the direction to split the pane",
          choices = {
            { label = " " .. wezterm.nerdfonts.fa_angle_left .. " " .. wezterm.nerdfonts.cod_split_horizontal .. " " .. "Left", id = "Left" },
            { label = " " .. wezterm.nerdfonts.cod_split_vertical .. " " .. wezterm.nerdfonts.fa_angle_down .. " " .. "Down", id = "Bottom" },
            { label = " " .. wezterm.nerdfonts.fa_angle_up .. " " .. wezterm.nerdfonts.cod_split_vertical .. " " .. "Up", id = "Top" },
            { label = " " .. wezterm.nerdfonts.cod_split_horizontal .. " " .. wezterm.nerdfonts.fa_angle_right .. " " .. "Right", id = "Left" },
          }
        }
      },

      -- [ modifierKey + right-arrow ] -> expand current pane towards the right.
      { key = "RightArrow", mods = modifierKey, action = wezterm.action.AdjustPaneSize { "Right", 2 } },

      -- [ modifierKey + left-arrow ] -> expand current pane towards the left.
      { key = "LeftArrow", mods = modifierKey, action = wezterm.action.AdjustPaneSize { "Left", 2 } },

      -- [ modifierKey + up-arrow ] -> expand current pane towards the top.
      { key = "UpArrow", mods = modifierKey, action = wezterm.action.AdjustPaneSize { "Up", 2 } },

      -- [ modifierKey + down-arrow ] -> expand current pane towards the bottom.
      { key = "DownArrow", mods = modifierKey, action = wezterm.action.AdjustPaneSize { "Down", 2 } },

      -- [ modifierKey + t ] -> create a new tab.
      { key = "t", mods = modifierKey, action = wezterm.action.SpawnTab "CurrentPaneDomain" },

      -- [ modifierKey + w ] -> close the current pane, tab and window, in that order.
      { key = "w", mods = modifierKey, action = wezterm.action.CloseCurrentPane { confirm = false } },

      -- [ modifierKey + return ] -> rename current tab.
      {
        key = "Enter",
        mods = modifierKey,
        action = wezterm.action.PromptInputLine {
          description = "Enter a new name for the current tab",
          action = wezterm.action_callback(
            function(window, pane, tabNewName)
              if ( tabNewName ~= nil ) then
                window:active_tab():set_title(tabNewName)
              end
            end
          )
        }
      },

      -- Tab/pane navigation --
      --------------------
      -- [ modifierKey + n ] -> go to the next tab.
      { key = "n", mods = modifierKey, action = wezterm.action.ActivateTabRelative(1) },

      -- [ modifierKey + b ] -> go to the previous tab.
      { key = "b", mods = modifierKey , action = wezterm.action.ActivateTabRelative(-1) },

      -- Copy --
      ----------
      -- [ modifierKey + c ] -> copy selection to clipboard and primary selection buffer.
      { key = "c", mods = modifierKey, action = wezterm.action.CopyTo "ClipboardAndPrimarySelection" },

      -- [ CMD + c ] -> copy selection to clipboard and primary selection buffer.
      { key = "c", mods = "CMD", action = wezterm.action.CopyTo "ClipboardAndPrimarySelection" },

      -- [ CTRL + c ] -> if some text is selected, copy selection to clipboard and primary selection buffer.
      -- Otherwise, send "CTRL + c" (usually interpreted as a terminate signal) to the terminal.
      {
        key = "c",
        mods = "CTRL",
        action = wezterm.action_callback(
          function(window, pane)
            -- Check if any text is selected.
            local isTextSelected = window:get_selection_text_for_pane(pane) ~= ''
            if isTextSelected then
              -- If some text is selected copy it to the clipboard and primary selection buffer.
              window:perform_action(wezterm.action.CopyTo "ClipboardAndPrimarySelection", pane)
            else
              -- Otherwise, send the keys pressed to the terminal.
              window:perform_action(wezterm.action.SendKey { key = "c", mods = "CTRL" }, pane)
            end
          end
        )
      },

      -- Paste --
      -----------
      -- [ modifierKey + v ] -> paste from clipboard.
      { key = "v", mods = modifierKey, action = wezterm.action.PasteFrom "Clipboard" },

      -- [ CTRL + v ] -> paste from clipboard.
      { key = "v", mods = "CTRL", action = wezterm.action.PasteFrom "Clipboard" },

      -- [ CMD + v ] -> paste from clipboard.
      { key = "v", mods = "CMD", action = wezterm.action.PasteFrom "Clipboard" },

      -- Adjust font size --
      ----------------------
      -- [ modifierKey + = ] -> increase font size.
      { key = "=", mods = modifierKey, action = wezterm.action.IncreaseFontSize },

      -- [ modifierKey + - ] -> decrease font size.
      { key = "-", mods = modifierKey, action = wezterm.action.DecreaseFontSize },

      -- [ modifierKey + 0 ] -> reset font size.
      { key = "0", mods = modifierKey, action = wezterm.action.ResetFontSize },

      -- Scrollback --
      ----------------
      -- [ modifierKey + backspace ] -> clear scrollback and viewport, then redraw the prompt.
      { key = "Backspace", mods = modifierKey, action = wezterm.action.Multiple { wezterm.action.ClearScrollback "ScrollbackAndViewport", wezterm.action.SendKey { key = "L", mods = "CTRL" } } }

    }
  }

  -- Export the above defined "config" table
  return config

end