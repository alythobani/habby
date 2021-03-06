module Init exposing (init)

import Api
import Array
import Browser.Dom as Dom
import Browser.Navigation as Navigation
import DefaultServices.Keyboard as Keyboard
import Dict
import Flags exposing (Flags)
import Model exposing (Model)
import Models.Graph as Graph
import Models.Habit as Habit
import Models.KeyboardShortcut as KeyboardShortcut
import Models.Login as Login
import Models.YmdDate as YmdDate
import Msg exposing (Msg(..))
import RemoteData
import Task
import Time
import TimeZone
import Url


init : Flags -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init { apiBaseUrl, currentTime } url key =
    let
        currentPosix : Time.Posix
        currentPosix =
            currentTime |> Time.millisToPosix
    in
    ( { key = key
      , url = url

      -- Authentication
      , user = Nothing
      , loginPageFields = Login.initLoginPageFields

      -- Time / Date
      , currentPosix = currentPosix
      , currentTimeZone = Nothing
      , selectedYmd = Nothing
      , actualYmd = Nothing
      , openTopPanelDateDropdown = False
      , chooseDateDialogChosenYmd = Nothing

      --
      , apiBaseUrl = apiBaseUrl

      -- Top right corner
      , darkModeOn = True
      , openUserActionsDropdown = False

      -- User-Inputted Habit Amounts
      , editingHabitAmountDict = Dict.empty

      -- Remote Data
      , allHabitData = RemoteData.NotAsked
      , allHabits = RemoteData.NotAsked
      , archivedHabits = RemoteData.NotAsked
      , allFrequencyStats = RemoteData.NotAsked
      , allHabitDayNotes = RemoteData.NotAsked

      -- Add Habit
      , addHabit = Habit.initAddHabitData

      -- Habit Actions Dropdowns
      , habitActionsDropdown = Nothing

      -- Keyboard
      , keysDown = Keyboard.init
      , keyboardShortcutsList = KeyboardShortcut.loginFormShortcuts
      , showAvailableKeyboardShortcutsScreen = False

      -- Set Habit Data Shortcut
      , setHabitDataShortcutHabitNameFilterText = ""
      , setHabitDataShortcutFilteredHabits = Array.empty
      , setHabitDataShortcutSelectedHabitIndex = 0

      -- Set Habit Data Shortcut Amount Screen
      , setHabitDataShortcutAmountScreenHabit = Nothing
      , setHabitDataShortcutAmountScreenInputInt = Nothing

      -- Edit Goal Habit Selection
      , editGoalHabitSelectionFilterText = ""
      , editGoalHabitSelectionFilteredHabits = Array.empty
      , editGoalHabitSelectionSelectedHabitIndex = 0

      -- Edit goal
      , editGoalDialogHabit = Nothing
      , editGoalDialogHabitCurrentFcrWithIndex = Nothing
      , editGoalConfirmationMessage = Nothing
      , editGoalNewFrequenciesList = Nothing
      , editGoal = Habit.initEditGoalData

      -- Edit Info Habit Selection
      , editInfoHabitSelectionFilterText = ""
      , editInfoHabitSelectionFilteredHabits = Array.empty
      , editInfoHabitSelectionSelectedHabitIndex = 0

      -- Edit Info
      , editInfoDialogHabit = Nothing
      , editInfo = Habit.initEditInfoData

      -- Error messages
      , errorMessage = Nothing

      -- Full screen dialogs
      , activeDialogScreen = Nothing

      -- Add note habit selection
      , addNoteHabitSelectionFilterText = ""
      , addNoteHabitSelectionFilteredHabits = Array.empty
      , addNoteHabitSelectionSelectedHabitIndex = 0

      -- Add note
      , addNoteDialogHabit = Nothing
      , addNoteDialogInput = ""

      -- Suspend Or Resume Habit Selection
      , suspendOrResumeHabitSelectionFilterText = ""
      , suspendOrResumeHabitSelectionFilteredHabits = Array.empty
      , suspendOrResumeHabitSelectionSelectedHabitIndex = 0

      -- Suspend Or Resume Confirmation Dialog
      , suspendOrResumeHabit = Nothing
      , suspendOrResumeHabitConfirmationMessage = ""
      , suspendOrResumeHabitNewSuspensions = Nothing

      -- Graph Habit Selection
      , graphHabitSelectionFilterText = ""
      , graphHabitSelectionFilteredHabits = Array.empty
      , graphHabitSelectionSelectedHabitIndex = 0

      -- Graph Dialog
      , graphHabit = Nothing
      , graphNumDaysToShow = Graph.LastMonth
      , graphGoalIntervals = RemoteData.NotAsked
      , graphIntervalsData = RemoteData.NotAsked
      , graphHoveredPoint = Nothing

      -- Archive Habits
      , archiveHabitSelectionFilterText = ""
      , archiveHabitSelectionFilteredHabits = Array.empty
      , archiveHabitSelectionSelectedHabitIndex = 0

      -- Unarchive Habits
      , unarchiveHabitSelectionFilterText = ""
      , unarchiveHabitSelectionFilteredHabits = Array.empty
      , unarchiveHabitSelectionSelectedHabitIndex = 0
      }
    , Cmd.batch
        [ Task.attempt OnInitialTimeZoneRetrieval TimeZone.getZone
        , Dom.focus "login-form-username-input" |> Task.attempt (always NoOp)
        ]
    )
