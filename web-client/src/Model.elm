module Model exposing (..)

import Models.ApiError as ApiError
import Models.Habit as Habit
import Models.HabitData as HabitData
import Models.YmdDate as YmdDate
import RemoteData


type alias Model =
    { ymd : YmdDate.YmdDate
    , apiBaseUrl : String
    , allHabits : RemoteData.RemoteData ApiError.ApiError (List Habit.Habit)
    , allHabitData : RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
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
    }
