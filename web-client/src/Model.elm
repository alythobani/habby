module Model exposing (Model)

import Array
import Dict
import Dropdown
import Keyboard.Extra as KK
import Material
import Models.ApiError as ApiError
import Models.FrequencyStats as FrequencyStats
import Models.Habit as Habit
import Models.HabitData as HabitData
import Models.YmdDate as YmdDate
import RemoteData


type alias Model =
    { ymd : YmdDate.YmdDate
    , apiBaseUrl : String
    , darkModeOn : Bool
    , editingTodayHabitAmount : Dict.Dict String Int
    , editingHistoryHabitAmount : Dict.Dict String (Dict.Dict String Int)
    , allHabits : RemoteData.RemoteData ApiError.ApiError (List Habit.Habit)
    , allHabitData : RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
    , allFrequencyStats : RemoteData.RemoteData ApiError.ApiError (List FrequencyStats.FrequencyStats)
    , addHabit :
        { openView : Bool
        , kind : Habit.HabitKind
        , name : String
        , description : String
        , goodHabitTime : Habit.HabitTime
        , unitNameSingular : String
        , unitNamePlural : String
        , frequencyKind : Habit.FrequencyKind
        , timesPerWeek : Maybe Int
        , mondayTimes : Maybe Int
        , tuesdayTimes : Maybe Int
        , wednesdayTimes : Maybe Int
        , thursdayTimes : Maybe Int
        , fridayTimes : Maybe Int
        , saturdayTimes : Maybe Int
        , sundayTimes : Maybe Int
        , times : Maybe Int
        , days : Maybe Int
        }
    , openTodayViewer : Bool
    , openHistoryViewer : Bool
    , historyViewerDateInput : String
    , historyViewerSelectedDate : Maybe YmdDate.YmdDate
    , historyViewerFrequencyStats : RemoteData.RemoteData ApiError.ApiError (List FrequencyStats.FrequencyStats)
    , todayViewerHabitActionsDropdowns : Dict.Dict String Dropdown.State
    , historyViewerHabitActionsDropdowns : Dict.Dict String Dropdown.State
    , mdl : Material.Model
    , showSetHabitDataShortcut : Bool
    , keysDown : KK.Model
    , setHabitDataShortcutHabitNameFilterText : String
    , setHabitDataShortcutFilteredHabits : Array.Array Habit.Habit
    , setHabitDataShortcutSelectedHabit : Maybe Habit.Habit
    }
