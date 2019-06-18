module Msg exposing (Msg(..))

import Api
import Browser
import Browser.Dom as Dom
import DefaultServices.Keyboard as Keyboard
import Models.ApiError exposing (ApiError)
import Models.Habit as Habit
import Models.HabitData as HabitData
import Models.HabitDayNote as HabitDayNote
import Models.YmdDate as YmdDate
import Time
import TimeZone
import Url


type Msg
    = NoOp
    | OnInitialTimeZoneRetrieval (Result TimeZone.Error ( String, Time.Zone ))
    | OnUrlChange Url.Url
    | OnUrlRequest Browser.UrlRequest
      -- Time / Date
    | TickMinute Time.Posix
    | OnTimeZoneRetrieval (Result TimeZone.Error ( String, Time.Zone ))
      -- Top Panel Date
    | ToggleTopPanelDateDropdown
    | SetSelectedDateToXDaysFromToday Int
    | OnChooseCustomDateClick
    | SetSelectedDateToCustomDate
      -- All Habit Data
    | OnGetAllRemoteDataFailure ApiError
    | OnGetAllRemoteDataSuccess Api.AllRemoteData
      -- Add Habit
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
    | AddHabit Habit.CreateHabit
    | OnAddHabitFailure ApiError
    | OnAddHabitSuccess Habit.Habit
      -- Set Habit Data
    | OnHabitAmountInput String String
    | SetHabitData YmdDate.YmdDate String (Maybe Int)
    | OnSetHabitDataFailure ApiError
    | OnSetHabitDataSuccess HabitData.HabitData
      -- Frequency Statistics
    | OnGetFrequencyStatsFailure ApiError
    | OnGetFrequencyStatsSuccess Api.QueriedFrequencyStats
      -- Habit Actions Dropdowns
    | ToggleHabitActionsDropdown String
      -- Dark Mode
    | OnToggleDarkMode
      -- Keyboard
    | KeyboardMsg Keyboard.Msg
      -- Dom
    | FocusResult (Result Dom.Error ())
      -- Set Habit Data Shortcut
    | OnSetHabitDataShortcutInput String
    | OnSetHabitDataShortcutSelectNextHabit
    | OnSetHabitDataShortcutSelectPreviousHabit
    | OnToggleShowSetHabitDataShortcutAmountForm
    | OnSetHabitDataShortcutAmountFormInput String
    | OnSetHabitDataShortcutAmountFormSubmit YmdDate.YmdDate String (Maybe Int)
      -- Edit goal
    | OnEditGoalClick String
    | CloseEditGoalDialog
    | OnEditGoalSelectFrequencyKind Habit.FrequencyKind
    | OnEditGoalTimesPerWeekInput String
    | OnEditGoalSpecificDayMondayInput String
    | OnEditGoalSpecificDayTuesdayInput String
    | OnEditGoalSpecificDayWednesdayInput String
    | OnEditGoalSpecificDayThursdayInput String
    | OnEditGoalSpecificDayFridayInput String
    | OnEditGoalSpecificDaySaturdayInput String
    | OnEditGoalSpecificDaySundayInput String
    | OnEditGoalTimesInput String
    | OnEditGoalDaysInput String
    | OnEditGoalFailure ApiError
    | OnEditGoalSuccess Habit.Habit
    | OnEditGoalSubmitClick String (List Habit.FrequencyChangeRecord) String
      -- Suspending Habits
    | OnResumeOrSuspendHabitClick String Bool (List Habit.SuspendedInterval)
    | OnResumeOrSuspendHabitFailure ApiError
    | OnResumeOrSuspendHabitSuccess Habit.Habit
      -- Error messages
    | OpenErrorMessageDialogScreen
      -- Full screen dialogs
    | OnExitDialogScreen
    | OpenSetHabitDataShortcutDialogScreen
    | OnExitSetHabitDataShortcutAmountFormInput
      -- Add Note Habit Selection
    | OpenAddNoteHabitSelectionDialogScreen
    | OnAddNoteHabitSelectionFilterTextInput String
    | OnAddNoteHabitSelectionScreenSelectNextHabit
    | OnAddNoteHabitSelectionScreenSelectPreviousHabit
      -- Add Note Dialog
    | OpenAddNoteDialog Habit.Habit
    | OnAddNoteDialogInput String
    | OnAddNoteKeydown Keyboard.Key YmdDate.YmdDate String
    | OnAddNoteKeyup Keyboard.Key
    | OnAddNoteSubmitClick YmdDate.YmdDate String String
    | OnAddNoteFailure ApiError
    | OnAddNoteSuccess HabitDayNote.HabitDayNote
