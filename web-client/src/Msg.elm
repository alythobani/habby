module Msg exposing (..)

import Api
import Models.ApiError exposing (ApiError)
import Models.Habit as Habit
import Navigation
import Time


type Msg
    = OnLocationChange Navigation.Location
    | TickMinute Time.Time
    | OnGetHabitsAndHabitDataFailure ApiError
    | OnGetHabitsAndHabitDataSuccess Api.HabitsAndHabitData
    | OnOpenAddHabit
    | OnCancelAddHabit
    | OnSelectAddHabitKind Habit.HabitKind
    | OnAddHabitNameInput String
    | OnAddHabitDescriptionInput String
    | OnSelectAddGoodHabitTime Habit.HabitTime
    | OnAddHabitUnitNameSingularInput String
    | OnAddHabitUnitNamePluralInput String
    | OnAddHabitSelectFrequencyKind Habit.FrequencyKind
    | OnAddHabitTimesPerWeekInput String
    | OnAddHabitSpecificDayMondayInput String
    | OnAddHabitSpecificDayTuesdayInput String
    | OnAddHabitSpecificDayWednesdayInput String
    | OnAddHabitSpecificDayThursdayInput String
    | OnAddHabitSpecificDayFridayInput String
    | OnAddHabitSpecificDaySaturdayInput String
    | OnAddHabitSpecificDaySundayInput String
    | OnAddHabitTimesInput String
    | OnAddHabitDaysInput String
    | AddHabit
    | OnAddHabitFailure ApiError
    | OnAddHabitSuccess Habit.Habit
