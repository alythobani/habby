module Init exposing (init)

import Api
import Array
import DefaultServices.Keyboard as Keyboard
import Dict
import Flags exposing (Flags)
import Model exposing (Model)
import Models.Habit as Habit
import Models.YmdDate as YmdDate
import Msg exposing (Msg(..))
import RemoteData
import Task
import Time
import TimeZone
import Url


init : Flags -> Url.Url -> ( Model, Cmd Msg )
init { apiBaseUrl, currentTime } url =
    let
        currentPosix : Time.Posix
        currentPosix =
            currentTime |> Time.millisToPosix
    in
    ( { currentPosix = currentPosix
      , currentTimeZone = Nothing
      , ymd = Nothing
      , apiBaseUrl = apiBaseUrl
      , darkModeOn = True
      , editingTodayHabitAmount = Dict.empty
      , editingHistoryHabitAmount = Dict.empty
      , allHabitData = RemoteData.Loading
      , allHabits = RemoteData.Loading
      , allFrequencyStats = RemoteData.Loading
      , addHabit = Habit.initAddHabitData
      , openTodayViewer = True
      , openHistoryViewer = False
      , historyViewerDateInput = ""
      , historyViewerSelectedDate = Nothing
      , historyViewerFrequencyStats = RemoteData.NotAsked
      , todayViewerHabitActionsDropdowns = Dict.empty
      , historyViewerHabitActionsDropdowns = Dict.empty
      , showSetHabitDataShortcut = False
      , keysDown = Keyboard.init
      , setHabitDataShortcutHabitNameFilterText = ""
      , setHabitDataShortcutFilteredHabits = Array.empty
      , setHabitDataShortcutSelectedHabitIndex = 0
      , showSetHabitDataShortcutAmountForm = False
      , setHabitDataShortcutInputtedAmount = Nothing
      , showEditGoalDialog = False
      , editGoalDialogHabit = Nothing
      , editGoal = Habit.initEditGoalData
      , errorMessage = Nothing
      , showErrorMessage = False
      }
    , Task.attempt OnTimeZoneRetrieval TimeZone.getZone
    )
